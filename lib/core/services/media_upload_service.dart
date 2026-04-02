// lib/core/services/media_upload_service.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime/mime.dart';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';

/// Media upload service with progress tracking and secure uploads
class MediaUploadService {
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;
  final ImagePicker _imagePicker;

  MediaUploadService({
    FirebaseStorage? storage,
    FirebaseAuth? auth,
    ImagePicker? imagePicker,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _imagePicker = imagePicker ?? ImagePicker();

  /// Upload file with progress tracking
  Future<MediaUploadResult> uploadFile({
    required File file,
    required String path,
    required MediaUploadType type,
    Map<String, String>? metadata,
    Function(double)? onProgress,
    Function(String)? onStatusUpdate,
  }) async {
    try {
      // Validate user authentication
      final user = _auth.currentUser;
      if (user == null) {
        throw MediaUploadException('User not authenticated', 'AUTH_ERROR');
      }

      // Validate file
      final validation = await _validateFile(file, type);
      if (!validation.isValid) {
        throw MediaUploadException(
          validation.errorMessage!,
          'VALIDATION_ERROR',
        );
      }

      onStatusUpdate?.call('Dosya yükleniyor...');

      // Create storage reference with security path
      final secureRef = _createSecureReference(path, user.uid);
      
      // Prepare metadata
      final fileMetadata = SettableMetadata(
        contentType: _getMimeType(file.path),
        customMetadata: {
          'userId': user.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
          'type': type.toString(),
          ...?metadata,
        },
      );

      // Start upload
      final uploadTask = secureRef.putFile(file, fileMetadata);

      // Track progress
      final progressController = StreamController<double>();
      final subscription = uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress?.call(progress);
        progressController.add(progress);
      });

      try {
        // Wait for upload completion
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        onStatusUpdate?.call('Yükleme tamamlandı');

        return MediaUploadResult.success(
          downloadUrl: downloadUrl,
          path: snapshot.ref.fullPath,
          fileName: file.path.split('/').last,
          fileSize: await file.length(),
          mimeType: _getMimeType(file.path),
          metadata: fileMetadata.customMetadata,
        );
      } finally {
        subscription.cancel();
        progressController.close();
      }
    } catch (e) {
      onStatusUpdate?.call('Yükleme hatası: ${e.toString()}');
      
      if (e is MediaUploadException) {
        rethrow;
      }
      
      throw MediaUploadException(
        'Upload failed: ${e.toString()}',
        'UPLOAD_ERROR',
      );
    }
  }

  /// Upload image with compression and thumbnail generation
  Future<MediaUploadResult> uploadImageWithProcessing({
    required File imageFile,
    required String userId,
    required String folder,
    ImageProcessingOptions? options,
    Function(double)? onProgress,
    Function(String)? onStatusUpdate,
  }) async {
    try {
      onStatusUpdate?.call('Resim işleniyor...');

      // Compress image locally first
      final compressedFile = await _compressImage(
        imageFile,
        options ?? ImageProcessingOptions(),
      );

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = imageFile.path.split('.').last;
      final fileName = 'img_${timestamp}_${_generateHash(compressedFile.path)}.$fileExtension';
      final path = '$folder/$userId/$fileName';

      // Upload compressed image
      final result = await uploadFile(
        file: compressedFile,
        path: path,
        type: MediaUploadType.image,
        metadata: {
          'originalFileName': imageFile.path.split('/').last,
          'compressed': 'true',
          'quality': options?.quality.toString() ?? '85',
        },
        onProgress: onProgress,
        onStatusUpdate: onStatusUpdate,
      );

      // Clean up compressed file
      if (compressedFile.path != imageFile.path) {
        try {
          await compressedFile.delete();
        } catch (e) {
          debugPrint('Failed to delete compressed file: $e');
        }
      }

      return result;
    } catch (e) {
      throw MediaUploadException(
        'Image upload failed: ${e.toString()}',
        'IMAGE_UPLOAD_ERROR',
      );
    }
  }

  /// Pick and upload profile image
  Future<MediaUploadResult?> pickAndUploadProfileImage({
    required String userId,
    required BuildContext context,
    Function(double)? onProgress,
    Function(String)? onStatusUpdate,
  }) async {
    try {
      // Check permissions
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        throw MediaUploadException(
          'Kamera/Fotoğraf izinleri gerekli',
          'PERMISSION_ERROR',
        );
      }

      // Show image source dialog - check if context is still valid
      if (!context.mounted) return null;
      final source = await _showImageSourceDialog(context);
      if (source == null) return null;

      // Pick image
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      // Crop image
      final croppedFile = await _cropImage(
        pickedFile.path,
        isProfilePicture: true,
      );

      if (croppedFile == null) return null;

      // Upload image
      return await uploadImageWithProcessing(
        imageFile: File(croppedFile.path),
        userId: userId,
        folder: 'profile_images',
        options: ImageProcessingOptions(
          quality: 90,
          maxWidth: 512,
          maxHeight: 512,
        ),
        onProgress: onProgress,
        onStatusUpdate: onStatusUpdate,
      );
    } catch (e) {
      if (e is MediaUploadException) {
        rethrow;
      }
      throw MediaUploadException(
        'Profile image upload failed: ${e.toString()}',
        'PROFILE_UPLOAD_ERROR',
      );
    }
  }

  /// Delete file from storage
  Future<bool> deleteFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      return true;
    } catch (e) {
      debugPrint('Failed to delete file: $e');
      return false;
    }
  }

  /// Get presigned URL for secure upload
  Future<String> getPresignedUploadUrl({
    required String path,
    required String contentType,
    Duration? expiration,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw MediaUploadException('User not authenticated', 'AUTH_ERROR');
      }

      final secureRef = _createSecureReference(path, user.uid);
      
      // Note: Firebase Storage doesn't support presigned URLs like AWS S3
      // Instead, we use Firebase Auth tokens for security
      // This is a placeholder for custom implementation if needed
      
      return secureRef.fullPath;
    } catch (e) {
      throw MediaUploadException(
        'Failed to generate presigned URL: ${e.toString()}',
        'PRESIGNED_URL_ERROR',
      );
    }
  }

  // Private methods
  Reference _createSecureReference(String path, String userId) {
    // Ensure path is secure and user-specific
    final securePath = path.startsWith('users/$userId/') 
        ? path 
        : 'users/$userId/$path';
    
    return _storage.ref().child(securePath);
  }

  Future<bool> _requestPermissions() async {
    // On web, permissions are handled differently
    if (kIsWeb) {
      return true; // Web handles permissions through browser
    }
    
    try {
      final cameraPermission = await Permission.camera.request();
      final photosPermission = await Permission.photos.request();
      
      return cameraPermission.isGranted && photosPermission.isGranted;
    } catch (e) {
      // If permission request fails, return false
      debugPrint('Permission request failed: $e');
      return false;
    }
  }

  Future<ImageSource?> _showImageSourceDialog(BuildContext context) async {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resim Kaynağı Seç'),
        content: const Text('Resminizi nasıl eklemek istiyorsunuz?'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Kamera'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: const Text('Galeri'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  Future<CroppedFile?> _cropImage(
    String imagePath, {
    required bool isProfilePicture,
  }) async {
    try {
      return await ImageCropper().cropImage(
        sourcePath: imagePath,
        aspectRatio: isProfilePicture
            ? const CropAspectRatio(ratioX: 1, ratioY: 1)
            : const CropAspectRatio(ratioX: 16, ratioY: 9),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: isProfilePicture ? 'Profil Resmini Kırp' : 'Kapak Resmini Kırp',
            toolbarColor: Colors.deepPurple,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: isProfilePicture
                ? CropAspectRatioPreset.square
                : CropAspectRatioPreset.ratio16x9,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: isProfilePicture ? 'Profil Resmini Kırp' : 'Kapak Resmini Kırp',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 85,
      );
    } catch (e) {
      debugPrint('Error cropping image: $e');
      return null;
    }
  }

  Future<File> _compressImage(
    File imageFile,
    ImageProcessingOptions options,
  ) async {
    try {
      // Read image bytes
      final bytes = await imageFile.readAsBytes();
      
      // Decode image
      final image = img.decodeImage(bytes);
      if (image == null) {
        throw MediaUploadException('Failed to decode image', 'DECODE_ERROR');
      }

      // Resize image if needed
      img.Image resizedImage = image;
      if (options.maxWidth != null || options.maxHeight != null) {
        resizedImage = img.copyResize(
          image,
          width: options.maxWidth,
          height: options.maxHeight,
          interpolation: img.Interpolation.linear,
        );
      }

      // Compress image
      final compressedBytes = img.encodeJpg(resizedImage, quality: options.quality);
      
      // Create temporary file
      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = File('${tempDir.path}/compressed_$timestamp.jpg');
      
      // Write compressed bytes to file
      await tempFile.writeAsBytes(compressedBytes);
      
      return tempFile;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      // Return original file if compression fails
      return imageFile;
    }
  }

  Future<FileValidationResult> _validateFile(File file, MediaUploadType type) async {
    try {
      final fileSize = await file.length();
      final mimeType = _getMimeType(file.path);

      // Check file size limits
      final maxSize = _getMaxFileSize(type);
      if (fileSize > maxSize) {
        return FileValidationResult(
          isValid: false,
          errorMessage: 'Dosya boyutu ${_formatFileSize(maxSize)} limitini aşıyor',
        );
      }

      // Check file type
      final allowedTypes = _getAllowedMimeTypes(type);
      if (mimeType == null || !allowedTypes.contains(mimeType)) {
        return FileValidationResult(
          isValid: false,
          errorMessage: 'Desteklenmeyen dosya türü',
        );
      }

      return FileValidationResult(isValid: true);
    } catch (e) {
      return FileValidationResult(
        isValid: false,
        errorMessage: 'Dosya doğrulama hatası: ${e.toString()}',
      );
    }
  }

  String? _getMimeType(String filePath) {
    return lookupMimeType(filePath);
  }

  int _getMaxFileSize(MediaUploadType type) {
    switch (type) {
      case MediaUploadType.image:
        return 5 * 1024 * 1024; // 5MB
      case MediaUploadType.video:
        return 50 * 1024 * 1024; // 50MB
      case MediaUploadType.document:
        return 10 * 1024 * 1024; // 10MB
      case MediaUploadType.audio:
        return 25 * 1024 * 1024; // 25MB
    }
  }

  List<String> _getAllowedMimeTypes(MediaUploadType type) {
    switch (type) {
      case MediaUploadType.image:
        return ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
      case MediaUploadType.video:
        return ['video/mp4', 'video/mov', 'video/avi'];
      case MediaUploadType.document:
        return ['application/pdf', 'text/plain', 'application/msword'];
      case MediaUploadType.audio:
        return ['audio/mpeg', 'audio/wav', 'audio/ogg'];
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _generateHash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 8);
  }
}

// Enums and data classes
enum MediaUploadType {
  image,
  video,
  document,
  audio,
}

class MediaUploadResult {
  final bool isSuccess;
  final String? downloadUrl;
  final String? path;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;
  final Map<String, String>? metadata;
  final String? errorMessage;
  final String? errorCode;

  MediaUploadResult._({
    required this.isSuccess,
    this.downloadUrl,
    this.path,
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.metadata,
    this.errorMessage,
    this.errorCode,
  });

  factory MediaUploadResult.success({
    required String downloadUrl,
    required String path,
    required String fileName,
    required int fileSize,
    required String? mimeType,
    Map<String, String>? metadata,
  }) {
    return MediaUploadResult._(
      isSuccess: true,
      downloadUrl: downloadUrl,
      path: path,
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mimeType,
      metadata: metadata,
    );
  }

  factory MediaUploadResult.error({
    required String errorMessage,
    required String errorCode,
  }) {
    return MediaUploadResult._(
      isSuccess: false,
      errorMessage: errorMessage,
      errorCode: errorCode,
    );
  }
}

class MediaUploadException implements Exception {
  final String message;
  final String code;

  MediaUploadException(this.message, this.code);

  @override
  String toString() => 'MediaUploadException: $message (Code: $code)';
}

class ImageProcessingOptions {
  final int quality;
  final int? maxWidth;
  final int? maxHeight;
  final bool createThumbnail;
  final int? thumbnailSize;

  ImageProcessingOptions({
    this.quality = 85,
    this.maxWidth,
    this.maxHeight,
    this.createThumbnail = true,
    this.thumbnailSize = 150,
  });
}

class FileValidationResult {
  final bool isValid;
  final String? errorMessage;

  FileValidationResult({
    required this.isValid,
    this.errorMessage,
  });
}

// Provider for MediaUploadService
final mediaUploadServiceProvider = Provider<MediaUploadService>((ref) {
  return MediaUploadService();
});

// State management for upload progress
class MediaUploadState {
  final bool isUploading;
  final double progress;
  final String? status;
  final MediaUploadResult? result;
  final String? error;

  const MediaUploadState({
    this.isUploading = false,
    this.progress = 0.0,
    this.status,
    this.result,
    this.error,
  });

  MediaUploadState copyWith({
    bool? isUploading,
    double? progress,
    String? status,
    MediaUploadResult? result,
    String? error,
  }) {
    return MediaUploadState(
      isUploading: isUploading ?? this.isUploading,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      result: result ?? this.result,
      error: error ?? this.error,
    );
  }
}

class MediaUploadNotifier extends StateNotifier<MediaUploadState> {
  final MediaUploadService _uploadService;

  MediaUploadNotifier(this._uploadService) : super(const MediaUploadState());

  Future<void> uploadFile({
    required File file,
    required String path,
    required MediaUploadType type,
    Map<String, String>? metadata,
  }) async {
    state = state.copyWith(
      isUploading: true,
      progress: 0.0,
      status: 'Yükleme başlatılıyor...',
      error: null,
    );

    try {
      final result = await _uploadService.uploadFile(
        file: file,
        path: path,
        type: type,
        metadata: metadata,
        onProgress: (progress) {
          state = state.copyWith(progress: progress);
        },
        onStatusUpdate: (status) {
          state = state.copyWith(status: status);
        },
      );

      state = state.copyWith(
        isUploading: false,
        result: result,
        status: 'Yükleme tamamlandı',
      );
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: e.toString(),
        status: 'Yükleme hatası',
      );
    }
  }

  void reset() {
    state = const MediaUploadState();
  }
}

final mediaUploadProvider = StateNotifierProvider<MediaUploadNotifier, MediaUploadState>((ref) {
  final uploadService = ref.watch(mediaUploadServiceProvider);
  return MediaUploadNotifier(uploadService);
});
