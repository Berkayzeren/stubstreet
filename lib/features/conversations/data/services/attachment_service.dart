import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';

class AttachmentService {
  static const List<String> _supportedImageTypes = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
  ];

  static const List<String> _supportedFileTypes = [
    'application/pdf',
    'text/plain',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  ];

  static const int _maxFileSize = 10 * 1024 * 1024; // 10MB
  static const int _maxImageSize = 5 * 1024 * 1024; // 5MB

  final ImagePicker _imagePicker;
  final FirebaseStorage _storage;

  AttachmentService({
    required ImagePicker imagePicker,
    required FirebaseStorage storage,
  })  : _imagePicker = imagePicker,
        _storage = storage;

  /// Pick image from camera
  Future<AttachmentResult?> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return null;

      final file = File(image.path);
      final validation = await _validateFile(file, isImage: true);
      
      if (!validation.isValid) {
        return AttachmentResult.error(validation.errorMessage!);
      }

      return AttachmentResult.success(
        file: file,
        type: AttachmentType.image,
        fileName: image.name,
        mimeType: _getMimeType(image.path),
      );
    } catch (e) {
      return AttachmentResult.error('Failed to pick image from camera: $e');
    }
  }

  /// Pick image from gallery
  Future<AttachmentResult?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return null;

      final file = File(image.path);
      final validation = await _validateFile(file, isImage: true);
      
      if (!validation.isValid) {
        return AttachmentResult.error(validation.errorMessage!);
      }

      return AttachmentResult.success(
        file: file,
        type: AttachmentType.image,
        fileName: image.name,
        mimeType: _getMimeType(image.path),
      );
    } catch (e) {
      return AttachmentResult.error('Failed to pick image from gallery: $e');
    }
  }

  /// Pick file from device
  Future<AttachmentResult?> pickFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
      );

      if (result == null || result.files.isEmpty) return null;

      final platformFile = result.files.first;
      final file = File(platformFile.path!);
      
      final validation = await _validateFile(file, isImage: false);
      
      if (!validation.isValid) {
        return AttachmentResult.error(validation.errorMessage!);
      }

      return AttachmentResult.success(
        file: file,
        type: AttachmentType.file,
        fileName: platformFile.name,
        mimeType: _getMimeType(platformFile.path!),
      );
    } catch (e) {
      return AttachmentResult.error('Failed to pick file: $e');
    }
  }

  /// Upload attachment to Firebase Storage
  Future<AttachmentUploadResult> uploadAttachment({
    required File file,
    required String conversationId,
    required String messageId,
    required AttachmentType type,
    String? fileName,
    Function(double)? onProgress,
  }) async {
    try {
      final String folder = type == AttachmentType.image ? 'images' : 'files';
      final String extension = fileName?.split('.').last ?? 'unknown';
      final String storagePath = 'messages/$conversationId/$folder/${messageId}_${DateTime.now().millisecondsSinceEpoch}.$extension';

      final Reference ref = _storage.ref().child(storagePath);
      final UploadTask uploadTask = ref.putFile(file);

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress?.call(progress);
      });

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return AttachmentUploadResult.success(
        url: downloadUrl,
        fileName: fileName ?? 'attachment',
        fileSize: await file.length(),
        mimeType: _getMimeType(file.path),
      );
    } catch (e) {
      return AttachmentUploadResult.error('Failed to upload attachment: $e');
    }
  }

  /// Delete attachment from Firebase Storage
  Future<bool> deleteAttachment(String downloadUrl) async {
    try {
      final Reference ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      return true;
    } catch (e) {
      debugPrint('Failed to delete attachment: $e');
      return false;
    }
  }

  /// Validate file size and type
  Future<ValidationResult> _validateFile(File file, {required bool isImage}) async {
    try {
      // Check file size
      final fileSize = await file.length();
      final maxSize = isImage ? _maxImageSize : _maxFileSize;
      
      if (fileSize > maxSize) {
        final maxSizeMB = maxSize / (1024 * 1024);
        return ValidationResult(
          isValid: false,
          errorMessage: 'File size exceeds ${maxSizeMB.toInt()}MB limit',
        );
      }

      // Check file type
      final mimeType = _getMimeType(file.path);
      final supportedTypes = isImage ? _supportedImageTypes : _supportedFileTypes;
      
      if (mimeType == null || !supportedTypes.contains(mimeType)) {
        return ValidationResult(
          isValid: false,
          errorMessage: 'File type not supported',
        );
      }

      return ValidationResult(isValid: true);
    } catch (e) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Failed to validate file: $e',
      );
    }
  }

  /// Get MIME type from file path
  String? _getMimeType(String filePath) {
    return lookupMimeType(filePath);
  }

  /// Get formatted file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Get temporary directory for caching
  Future<Directory> getTempDirectory() async {
    return await getTemporaryDirectory();
  }
}

enum AttachmentType {
  image,
  file,
}

class AttachmentResult {
  final bool isSuccess;
  final File? file;
  final AttachmentType? type;
  final String? fileName;
  final String? mimeType;
  final String? errorMessage;

  AttachmentResult._({
    required this.isSuccess,
    this.file,
    this.type,
    this.fileName,
    this.mimeType,
    this.errorMessage,
  });

  factory AttachmentResult.success({
    required File file,
    required AttachmentType type,
    required String fileName,
    required String? mimeType,
  }) {
    return AttachmentResult._(
      isSuccess: true,
      file: file,
      type: type,
      fileName: fileName,
      mimeType: mimeType,
    );
  }

  factory AttachmentResult.error(String errorMessage) {
    return AttachmentResult._(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }
}

class AttachmentUploadResult {
  final bool isSuccess;
  final String? url;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;
  final String? errorMessage;

  AttachmentUploadResult._({
    required this.isSuccess,
    this.url,
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.errorMessage,
  });

  factory AttachmentUploadResult.success({
    required String url,
    required String fileName,
    required int fileSize,
    required String? mimeType,
  }) {
    return AttachmentUploadResult._(
      isSuccess: true,
      url: url,
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mimeType,
    );
  }

  factory AttachmentUploadResult.error(String errorMessage) {
    return AttachmentUploadResult._(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }
}

class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  ValidationResult({
    required this.isValid,
    this.errorMessage,
  });
}
