// lib/features/auth/domain/repositories/auth_repository.dart

import '../entities/user.dart';
import '../entities/user_profile.dart';

abstract class AuthRepository {
  // Authentication state stream
  Stream<User?> get authStateChanges;
  
  // Current user
  Future<User?> get currentUser;

  // Sign in with email and password
  Future<User> signInWithEmailAndPassword(String email, String password);

  // Sign up with email and password
  Future<User> signUpWithEmailAndPassword(
    String email, 
    String password, {
    String? firstName,
    String? lastName,
    String? username,
    String? phoneNumber,
  });

  // Sign out
  Future<void> signOut();

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email);

  // Send email verification
  Future<void> sendEmailVerification();

  // Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
    String? coverImageUrl,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? bio,
    List<String>? interests,
    String? location,
  });

  // Get user profile
  Future<UserProfile> getUserProfile(String userId);

  // Submit review
  Future<void> submitReview({
    required String reviewedUserId,
    required double rating,
    required String comment,
  });

  // Token management
  Future<void> refreshToken();
  Future<bool> isTokenValid();
  
  // Username availability check
  Future<bool> isUsernameAvailable(String username);
}
