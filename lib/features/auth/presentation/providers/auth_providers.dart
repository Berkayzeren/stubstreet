// lib/features/auth/presentation/providers/auth_providers.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user.dart' as domain_user;
import '../../domain/entities/user_profile.dart';

// Bu satır, build_runner'ın bizim için kod üretmesini sağlar.
part 'auth_providers.g.dart';

// 1. Firebase Auth instance'ını sağlayan basit bir provider.
@riverpod
FirebaseAuth firebaseAuth(Ref ref) {
  return FirebaseAuth.instance;
}

// 2. AuthRepository'i sağlayan provider.
@riverpod
AuthRepository authRepository(Ref ref) {
  return FirebaseAuthRepository();
}

// 3. Kullanıcının oturum durumunu anlık olarak dinleyen provider (EN ÖNEMLİSİ).
@riverpod
Stream<domain_user.User?> authStateChanges(Ref ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
}

// 4. Simple auth state provider that reduces rebuilds
// The optimization is handled in the UI layer with logging flags

// 4. Current user provider
@riverpod
Future<domain_user.User?> currentUser(Ref ref) {
  return ref.watch(authRepositoryProvider).currentUser;
}

// 5. User profile provider
@riverpod
Future<UserProfile> userProfile(Ref ref, String userId) {
  return ref.watch(authRepositoryProvider).getUserProfile(userId);
}

// 6. Sign in provider
@riverpod
class SignInNotifier extends _$SignInNotifier {
  @override
  AsyncValue<domain_user.User?> build() {
    return const AsyncValue.data(null);
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await ref.read(authRepositoryProvider).signInWithEmailAndPassword(email, password);
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

// 7. Sign up provider
@riverpod
class SignUpNotifier extends _$SignUpNotifier {
  @override
  AsyncValue<domain_user.User?> build() {
    return const AsyncValue.data(null);
  }

  Future<void> signUp(String email, String password, {
    String? firstName,
    String? lastName,
    String? username,
    String? phoneNumber,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await ref.read(authRepositoryProvider).signUpWithEmailAndPassword(
        email, 
        password,
        firstName: firstName,
        lastName: lastName,
        username: username,
        phoneNumber: phoneNumber,
      );
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

// 8. Profile update provider
@riverpod
class ProfileUpdateNotifier extends _$ProfileUpdateNotifier {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

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
  }) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(authRepositoryProvider).updateProfile(
        displayName: displayName,
        photoURL: photoURL,
        coverImageUrl: coverImageUrl,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        bio: bio,
        interests: interests,
        location: location,
      );
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

// 9. Review submission provider
@riverpod
class ReviewSubmissionNotifier extends _$ReviewSubmissionNotifier {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<void> submitReview({
    required String reviewedUserId,
    required double rating,
    required String comment,
  }) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(authRepositoryProvider).submitReview(
        reviewedUserId: reviewedUserId,
        rating: rating,
        comment: comment,
      );
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

// 10. Username availability checker provider
@riverpod
class UsernameAvailabilityNotifier extends _$UsernameAvailabilityNotifier {
  @override
  AsyncValue<bool?> build() {
    return const AsyncValue.data(null);
  }

  /// Kullanıcı adının kullanılabilirliğini kontrol eder
  /// @param username String - Kontrol edilecek kullanıcı adı
  /// @returns `Future<void>` - State güncellenecek: true=kullanılabilir, false=kullanılamaz, null=kontrol edilmedi
  Future<void> checkUsername(String username) async {
    // Boş veya çok kısa kullanıcı adları için kontrol yapma
    if (username.trim().isEmpty || username.trim().length < 3) {
      state = const AsyncValue.data(null);
      return;
    }
    
    state = const AsyncValue.loading();
    try {
      final isAvailable = await ref.read(authRepositoryProvider).isUsernameAvailable(username);
      state = AsyncValue.data(isAvailable);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}