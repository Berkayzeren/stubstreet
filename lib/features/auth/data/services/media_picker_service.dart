// lib/features/auth/data/services/media_picker_service.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MediaPickerService {
  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<TaskSnapshot> uploadFile(File file, String path, Function(double) onProgress) async {
    final ref = _storage.ref().child(path);
    final uploadTask = ref.putFile(file);

    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      final progress = snapshot.bytesTransferred / snapshot.totalBytes;
      onProgress(progress);
    });

    return uploadTask;
  }

  Future<String?> pickAndUploadProfileImage({
    required String userId,
    required BuildContext context,
  }) async {
    try {
      // Check permissions
      final permissionStatus = await _requestPermissions();
      if (!permissionStatus) {
        throw Exception('Camera/Photo permissions are required');
      }

      // Show image source selection - check if context is still valid
      if (!context.mounted) return null;
      final ImageSource? source = await _showImageSourceDialog(context);
      if (source == null) return null;

      // Pick image
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      // Upload to Firebase Storage (skip cropping for now)
      final downloadUrl = await _uploadToFirebase(
        File(pickedFile.path),
        'profile_images/$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      return downloadUrl;
    } catch (e) {
      debugPrint('Error picking/uploading profile image: $e');
      rethrow;
    }
  }

  Future<String?> pickAndUploadCoverImage({
    required String userId,
    required BuildContext context,
  }) async {
    try {
      // Check permissions
      final permissionStatus = await _requestPermissions();
      if (!permissionStatus) {
        throw Exception('Camera/Photo permissions are required');
      }

      // Show image source selection - check if context is still valid
      if (!context.mounted) return null;
      final ImageSource? source = await _showImageSourceDialog(context);
      if (source == null) return null;

      // Pick image
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      // Upload to Firebase Storage (skip cropping for now)
      final downloadUrl = await _uploadToFirebase(
        File(pickedFile.path),
        'profile_images/$userId/cover_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      return downloadUrl;
    } catch (e) {
      debugPrint('Error picking/uploading cover image: $e');
      rethrow;
    }
  }

  Future<bool> _requestPermissions() async {
    // On web, permissions are handled differently
    if (kIsWeb) {
      return true; // Web handles permissions through browser
    }
    
    try {
      // Check current permission status first
      final cameraStatus = await Permission.camera.status;
      final photosStatus = await Permission.photos.status;
      final storageStatus = await Permission.storage.status;
      
      debugPrint('Current permissions - Camera: $cameraStatus, Photos: $photosStatus, Storage: $storageStatus');
      
      // If permissions are already granted, return true
      if (cameraStatus.isGranted && (photosStatus.isGranted || storageStatus.isGranted)) {
        debugPrint('Permissions already granted');
        return true;
      }
      
      // Request camera permission if not granted
      PermissionStatus cameraPermission = cameraStatus;
      if (!cameraStatus.isGranted) {
        cameraPermission = await Permission.camera.request();
      }
      
      // Request storage permission - try photos first, then storage
      PermissionStatus storagePermission;
      if (photosStatus.isGranted) {
        storagePermission = photosStatus;
      } else if (storageStatus.isGranted) {
        storagePermission = storageStatus;
      } else {
        try {
          // Try photos permission first (Android 13+)
          storagePermission = await Permission.photos.request();
        } catch (e) {
          // If photos permission fails, try storage permission (Android 12 and below)
          storagePermission = await Permission.storage.request();
        }
      }
      
      // Check if both permissions are granted
      final isGranted = cameraPermission.isGranted && storagePermission.isGranted;
      
      if (!isGranted) {
        debugPrint('Permissions not granted - Camera: ${cameraPermission.isGranted}, Storage: ${storagePermission.isGranted}');
        
        // Show permission explanation dialog
        if (cameraPermission.isDenied || storagePermission.isDenied) {
          _showPermissionExplanationDialog();
        }
      }
      
      return isGranted;
    } catch (e) {
      // If permission request fails, return false
      debugPrint('Permission request failed: $e');
      return false;
    }
  }
  
  void _showPermissionExplanationDialog() {
    // This will be called from the UI context, so we'll handle it there
    debugPrint('Permission explanation needed');
  }

  Future<ImageSource?> _showImageSourceDialog(BuildContext context) async {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: const Text('Choose how you want to add your image'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Camera'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: const Text('Gallery'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Removed cropping functionality for now (web compatibility)

  Future<String> _uploadToFirebase(File file, String path) async {
    try {
      // Create reference
      final ref = _storage.ref().child(path);
      
      // Upload file
      final uploadTask = ref.putFile(file);
      
      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        debugPrint('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });

      // Wait for completion
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading to Firebase: $e');
      rethrow;
    }
  }

  Future<void> deleteImageFromFirebase(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting image from Firebase: $e');
      // Don't rethrow - deletion errors shouldn't block the user
    }
  }
}

// Provider for the media picker service
final mediaPickerServiceProvider = Provider<MediaPickerService>((ref) {
  return MediaPickerService();
});

// State notifier for upload progress
class ImageUploadNotifier extends StateNotifier<ImageUploadState> {
  ImageUploadNotifier() : super(const ImageUploadState());

  void startUpload() {
    state = state.copyWith(isUploading: true, progress: 0.0);
  }

  void updateProgress(double progress) {
    state = state.copyWith(progress: progress);
  }

  void completeUpload(String imageUrl) {
    state = state.copyWith(
      isUploading: false,
      progress: 1.0,
      imageUrl: imageUrl,
    );
  }

  void uploadError(String error) {
    state = state.copyWith(
      isUploading: false,
      error: error,
    );
  }

  void reset() {
    state = const ImageUploadState();
  }
}

class ImageUploadState {
  final bool isUploading;
  final double progress;
  final String? imageUrl;
  final String? error;

  const ImageUploadState({
    this.isUploading = false,
    this.progress = 0.0,
    this.imageUrl,
    this.error,
  });

  ImageUploadState copyWith({
    bool? isUploading,
    double? progress,
    String? imageUrl,
    String? error,
  }) {
    return ImageUploadState(
      isUploading: isUploading ?? this.isUploading,
      progress: progress ?? this.progress,
      imageUrl: imageUrl ?? this.imageUrl,
      error: error ?? this.error,
    );
  }
}

final imageUploadProvider = StateNotifierProvider<ImageUploadNotifier, ImageUploadState>((ref) {
  return ImageUploadNotifier();
});
