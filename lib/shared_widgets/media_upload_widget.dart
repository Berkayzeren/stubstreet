// lib/shared_widgets/media_upload_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/media_upload_service.dart';

class MediaUploadWidget extends ConsumerStatefulWidget {
  final String userId;
  final String folder;
  final MediaUploadType uploadType;
  final Function(MediaUploadResult) onUploadComplete;
  final Function(String)? onUploadError;
  final Widget? child;

  const MediaUploadWidget({
    super.key,
    required this.userId,
    required this.folder,
    required this.uploadType,
    required this.onUploadComplete,
    this.onUploadError,
    this.child,
  });

  @override
  ConsumerState<MediaUploadWidget> createState() => _MediaUploadWidgetState();
}

class _MediaUploadWidgetState extends ConsumerState<MediaUploadWidget> {
  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(mediaUploadProvider);

    return Column(
      children: [
        // Upload button or custom child
        widget.child ?? 
        ElevatedButton.icon(
          onPressed: uploadState.isUploading ? null : () => _pickAndUpload(),
          icon: uploadState.isUploading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload),
          label: Text(
            uploadState.isUploading 
                ? 'Yükleniyor...' 
                : _getUploadButtonText(),
          ),
        ),
        
        // Progress indicator
        if (uploadState.isUploading) ...[
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: uploadState.progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            uploadState.status ?? 'Yükleniyor...',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            '${(uploadState.progress * 100).toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
        
        // Error message
        if (uploadState.error != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    uploadState.error!,
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ),
                IconButton(
                  onPressed: () => ref.read(mediaUploadProvider.notifier).reset(),
                  icon: const Icon(Icons.close),
                  iconSize: 16,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _getUploadButtonText() {
    switch (widget.uploadType) {
      case MediaUploadType.image:
        return 'Resim Yükle';
      case MediaUploadType.video:
        return 'Video Yükle';
      case MediaUploadType.document:
        return 'Belge Yükle';
      case MediaUploadType.audio:
        return 'Ses Yükle';
    }
  }

  Future<void> _pickAndUpload() async {
    final uploadService = ref.read(mediaUploadServiceProvider);

    try {
      if (widget.uploadType == MediaUploadType.image) {
        // For images, use the built-in picker with compression
        final result = await uploadService.pickAndUploadProfileImage(
          userId: widget.userId,
          context: context,
          onProgress: (progress) {
            // Progress is handled by the notifier
          },
          onStatusUpdate: (status) {
            // Status is handled by the notifier
          },
        );
        
        if (result != null) {
          widget.onUploadComplete(result);
        }
        return;
      }

      // For other file types, you'd implement file picker here
      // This is a simplified example
      
    } catch (e) {
      widget.onUploadError?.call(e.toString());
    }
  }
}

// Progress indicator widget for inline use
class MediaUploadProgressIndicator extends ConsumerWidget {
  final double? progress;
  final String? status;
  final bool isUploading;

  const MediaUploadProgressIndicator({
    super.key,
    this.progress,
    this.status,
    this.isUploading = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isUploading) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        if (status != null)
          Text(
            status!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        if (progress != null)
          Text(
            '${(progress! * 100).toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }
}

// Upload result display widget
class MediaUploadResultWidget extends StatelessWidget {
  final MediaUploadResult result;
  final VoidCallback? onRetry;
  final VoidCallback? onClear;

  const MediaUploadResultWidget({
    super.key,
    required this.result,
    this.onRetry,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: result.isSuccess ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: result.isSuccess ? Colors.green[300]! : Colors.red[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.isSuccess ? Icons.check_circle : Icons.error,
                color: result.isSuccess ? Colors.green[700] : Colors.red[700],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.isSuccess ? 'Yükleme başarılı!' : 'Yükleme hatası!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: result.isSuccess ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ),
              if (onClear != null)
                IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                  iconSize: 16,
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (result.isSuccess) ...[
            Text('Dosya: ${result.fileName}'),
            Text('Boyut: ${_formatFileSize(result.fileSize ?? 0)}'),
            if (result.mimeType != null)
              Text('Tür: ${result.mimeType}'),
          ] else ...[
            Text(
              result.errorMessage ?? 'Bilinmeyen hata',
              style: TextStyle(color: Colors.red[700]),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onRetry,
                child: const Text('Tekrar Dene'),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
