// lib/features/auth/data/repositories/firebase_auth_repository.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user.dart' as domain;
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/services/firebase_service.dart';
import 'package:flutter/foundation.dart'; // Added for debugPrint

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Stream<domain.User?> get authStateChanges {
    return _firebaseService.authStateChanges.asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      
      // Get user document from Firestore
      final userDoc = await _firebaseService.getUserDocument(firebaseUser.uid);
      
      if (userDoc.exists) {
        return _mapFirebaseUserToDomain(firebaseUser, userDoc.data() as Map<String, dynamic>);
      } else {
        // Create user document if it doesn't exist
        await _firebaseService.createUserDocument(firebaseUser);
        return _mapFirebaseUserToDomain(firebaseUser, {});
      }
    });
  }

  @override
  Future<domain.User?> get currentUser async {
    final firebaseUser = _firebaseService.currentUser;
    if (firebaseUser == null) return null;
    
    final userDoc = await _firebaseService.getUserDocument(firebaseUser.uid);
    final userData = userDoc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    
    return _mapFirebaseUserToDomain(firebaseUser, userData);
  }

  @override
  Future<domain.User> signInWithEmailAndPassword(String emailOrUsername, String password) async {
    try {
      debugPrint('🔍 DEBUG: signInWithEmailAndPassword çağrıldı - Email/Username: $emailOrUsername');
      String email = emailOrUsername;
      // String? intendedRole;   // If user signs in with username, we capture role from the matched user doc
      // String? intendedStatus; // Likewise, capture status to keep behavior identical to email-based sign-in
      
      // Eğer @ içermiyorsa username'dir, email'i bul
      if (!emailOrUsername.contains('@')) {
        debugPrint('🔍 DEBUG: Kullanıcı adı ile giriş denemesi - Username: $emailOrUsername');
        
        // Önce usernameIndex'te ara
        final indexDoc = await _firebaseService.firestore
            .collection('usernameIndex')
            .doc(emailOrUsername)
            .get();
            
        if (!indexDoc.exists) {
          debugPrint('❌ DEBUG: Kullanıcı adı dizininde kullanıcı bulunamadı: $emailOrUsername');
          
          // Kullanıcının users koleksiyonunda olup olmadığını kontrol et
          debugPrint('🔍 DEBUG: Users koleksiyonundan username aranıyor: $emailOrUsername');
          final usersQuery = await _firebaseService.firestore
              .collection('users')
              .where('username', isEqualTo: emailOrUsername)
              .get();
              
          if (usersQuery.docs.isNotEmpty) {
            final userDoc = usersQuery.docs.first;
            final userData = userDoc.data();
            final userEmail = userData['email'] as String?;
            
            if (userEmail != null) {
              debugPrint('✅ DEBUG: Users koleksiyonunda kullanıcı bulundu, email: $userEmail');
              email = userEmail;
              
              // UsernameIndex'i oluştur (eksik kayıt tamamlaması)
              await _firebaseService.firestore
                  .collection('usernameIndex')
                  .doc(emailOrUsername)
                  .set({
                    'username': emailOrUsername,
                    'email': userEmail,
                    'uid': userDoc.id,
                    'role': userData['role'] ?? 'buyer',
                    'status': userData['status'] ?? 'active',
                    'updatedAt': FieldValue.serverTimestamp(),
                    'createdAt': FieldValue.serverTimestamp(),
                  });
              debugPrint('✅ DEBUG: Eksik UsernameIndex kaydı oluşturuldu: $emailOrUsername -> $userEmail');
            } else {
              throw Exception('Kullanıcı adı bulunamadı veya yetkisiz: Lütfen e-posta ile giriş yapın ve tekrar deneyin.');
            }
          } else {
            throw Exception('Kullanıcı adı bulunamadı veya yetkisiz: Lütfen e-posta ile giriş yapın ve tekrar deneyin.');
          }
        } else {
          final indexData = indexDoc.data() as Map<String, dynamic>;
          final resolvedEmail = indexData['email'] as String?;
          if (resolvedEmail == null || resolvedEmail.isEmpty) {
            debugPrint('❌ DEBUG: Kullanıcı adı için e-posta bulunamadı - Username: $emailOrUsername');
            throw Exception('Kullanıcı adı için e-posta bulunamadı');
          }
          email = resolvedEmail;
          debugPrint('✅ DEBUG: Kullanıcı adı email\'e çözüldü: $email');
        }
      }
      
      final credential = await _firebaseService.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('✅ DEBUG: Firebase kimlik doğrulaması başarılı - UID: ${credential.user?.uid}');

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Giriş başarısız: Kullanıcı bilgisi alınamadı.');
      }
      
      // Kullanıcı verilerini Firestore'dan çek
      final userDoc = await _firebaseService.firestore.collection('users').doc(firebaseUser.uid).get();
      if (!userDoc.exists) {
        // Bu durum oluşmamalı eğer doğru registration akışı varsa,
        // ama yine de güvenlik için kontrol edelim.
        debugPrint('❌ DEBUG: Firestore users koleksiyonunda kullanıcı dokümanı bulunamadı: ${firebaseUser.uid}');
        throw Exception('Kullanıcı profil bilgileri bulunamadı.');
      }
      final userData = userDoc.data() as Map<String, dynamic>;
      
      await _ensureUsernameIndex(firebaseUser, userData);

      debugPrint('✅ DEBUG: Firestore kullanıcı verileri çekildi - UID: ${firebaseUser.uid}');
      return _mapFirebaseUserToDomain(firebaseUser, userData);
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ DEBUG: FirebaseAuthException: Kod: ${e.code}, Mesaj: ${e.message}');
      throw Exception(_getFirebaseAuthErrorMessage(e.code));
    } catch (e) {
      debugPrint('❌ DEBUG: Genel giriş hatası: $e');
      throw Exception('Giriş sırasında bir hata oluştu: $e');
    }
  }

  /// Username benzersizlik kontrolü yapar
  /// @param username String - Kontrol edilecek kullanıcı adı
  /// @returns `Future<bool>` - true ise kullanılabilir, false ise zaten var
  Future<bool> _isUsernameAvailable(String username) async {
    try {
      // Username index'de bu kullanıcı adının zaten kullanılıp kullanılmadığını kontrol et
      final indexDoc = await _firebaseService.firestore
          .collection('usernameIndex')
          .doc(username.toLowerCase()) // Büyük/küçük harf duyarsız karşılaştırma için lowercase kullan
          .get();
      
      return !indexDoc.exists; // Döküman yoksa kullanılabilir
    } catch (e) {
      // Hata durumunda güvenli tarafta kal ve kullanılamaz olarak değerlendir
      return false;
    }
  }
  
  /// Benzersiz username üretir, eğer istenen username kullanılmıyorsa onu döndürür
  /// @param preferredUsername String? - Tercih edilen kullanıcı adı
  /// @param fallbackName String? - Alternatif olarak kullanılabilecek isim
  /// @param email String - Email adresinin @ öncesi kısmı fallback olarak kullanılabilir
  /// @returns `Future<String>` - Benzersiz kullanıcı adı
  Future<String> _generateUniqueUsername(String? preferredUsername, String? fallbackName, String email) async {
    // İlk olarak tercih edilen username'i kontrol et
    if (preferredUsername != null && preferredUsername.trim().isNotEmpty) {
      final cleanUsername = preferredUsername.trim().toLowerCase();
      if (await _isUsernameAvailable(cleanUsername)) {
        return cleanUsername;
      }
      // Tercih edilen username kullanılmıyorsa sayı ekleyerek dene
      for (int i = 1; i <= 999; i++) {
        final candidateUsername = '${cleanUsername}_$i';
        if (await _isUsernameAvailable(candidateUsername)) {
          return candidateUsername;
        }
      }
    }
    
    // Fallback name ile dene (firstName)
    if (fallbackName != null && fallbackName.trim().isNotEmpty) {
      final cleanFallback = fallbackName.trim().toLowerCase();
      if (await _isUsernameAvailable(cleanFallback)) {
        return cleanFallback;
      }
      // Fallback name kullanılmıyorsa sayı ekleyerek dene
      for (int i = 1; i <= 999; i++) {
        final candidateUsername = '${cleanFallback}_$i';
        if (await _isUsernameAvailable(candidateUsername)) {
          return candidateUsername;
        }
      }
    }
    
    // Email'in @ öncesi kısmı ile dene
    final emailPrefix = email.split('@').first.toLowerCase();
    if (await _isUsernameAvailable(emailPrefix)) {
      return emailPrefix;
    }
    
    // Email prefix kullanılmıyorsa sayı ekleyerek dene
    for (int i = 1; i <= 999; i++) {
      final candidateUsername = '${emailPrefix}_$i';
      if (await _isUsernameAvailable(candidateUsername)) {
        return candidateUsername;
      }
    }
    
    // Son çare olarak random benzersiz username oluştur
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'user_$timestamp';
  }

  @override
  Future<domain.User> signUpWithEmailAndPassword(String email, String password, {
    String? firstName,
    String? lastName,
    String? username,
    String? phoneNumber,
  }) async {
    try {
      // Önce kullanıcı adının benzersiz olduğundan emin ol
      final uniqueUsername = await _generateUniqueUsername(username, firstName, email);
      
      final credential = await _firebaseService.auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final firebaseUser = credential.user!;
      
      // Create user document with additional data - benzersiz username kullan
      await _firebaseService.createUserDocument(firebaseUser, {
        'firstName': firstName ?? '',
        'lastName': lastName ?? '',
        'username': uniqueUsername, // Artık benzersiz olduğundan emin olduğumuz username
        'phoneNumber': phoneNumber,
      });
      
      // Username index'e güvenli şekilde ekle
      // Firestore transaction kullanarak race condition'ları önle
      await _firebaseService.firestore.runTransaction((transaction) async {
        final indexRef = _firebaseService.firestore
            .collection('usernameIndex')
            .doc(uniqueUsername);
        
        // İkinci kez kontrol et (transaction içinde)
        final indexDoc = await transaction.get(indexRef);
        if (indexDoc.exists) {
          throw Exception('Username çakışması tespit edildi: $uniqueUsername');
        }
        
        // Güvenli şekilde oluştur
        transaction.set(indexRef, {
          'username': uniqueUsername,
          'email': firebaseUser.email,
          'uid': firebaseUser.uid,
          'role': 'buyer',   // default role mirrors createUserDocument
          'status': 'active',
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      // Update display name if provided
      if (firstName != null && lastName != null) {
        await firebaseUser.updateDisplayName('$firstName $lastName');
      }
      
      // Get user document
      final userDoc = await _firebaseService.getUserDocument(firebaseUser.uid);
      final userData = userDoc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
      
      return _mapFirebaseUserToDomain(firebaseUser, userData);
    } catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseService.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseService.auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _firebaseService.currentUser;
    if (user != null && !user.emailVerified) {
      try {
        await user.sendEmailVerification();
      } catch (e) {
        throw _mapFirebaseException(e);
      }
    }
  }

  @override
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
    final user = _firebaseService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Firebase Auth profil alanlarını ayrı ayrı güncelle
      // Neden: firebase_auth ^5.x sürümünde birleşik updateProfile API'si kaldırıldı.
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      // Update Firestore document
      final updateData = <String, dynamic>{};
      
      if (displayName != null) updateData['displayName'] = displayName;
      if (photoURL != null) updateData['photoURL'] = photoURL;
      if (coverImageUrl != null) updateData['coverImageUrl'] = coverImageUrl;
      if (firstName != null) updateData['firstName'] = firstName;
      if (lastName != null) updateData['lastName'] = lastName;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (bio != null) updateData['bio'] = bio;
      if (interests != null) updateData['interests'] = interests;
      if (location != null) updateData['location'] = location;

      if (updateData.isNotEmpty) {
        await _firebaseService.updateUserDocument(user.uid, updateData);
      }
    } catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  @override
  Future<UserProfile> getUserProfile(String userId) async {
    try {
      final userDoc = await _firebaseService.getUserDocument(userId);
      
      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      
      // Get user reviews
      final reviewsQuery = await _firebaseService.reviews
          .where('reviewedUserId', isEqualTo: userId)
          .get();

      final reviews = reviewsQuery.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return UserReview(
          id: doc.id,
          reviewerId: data['reviewerId'] ?? '',
          reviewerName: data['reviewerName'] ?? '',
          reviewerAvatar: data['reviewerAvatar'] ?? '',
          rating: (data['rating'] ?? 0.0).toDouble(),
          comment: data['comment'] ?? '',
          createdAt: (data['createdAt'] as Timestamp).toDate(),
        );
      }).toList();
      
      // Sort reviews by date (newest first)
      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Calculate average rating
      final totalRating = reviews.fold(0.0, (total, review) => total + review.rating);
      final averageRating = reviews.isNotEmpty ? totalRating / reviews.length : 0.0;

      return UserProfile(
        id: userId,
        email: userData['email'] ?? '',
        firstName: userData['firstName'] ?? '',
        lastName: userData['lastName'] ?? '',
        username: userData['username'] ?? userData['email']?.split('@')[0] ?? 'user',
        phoneNumber: userData['phoneNumber'],
        profileImageUrl: userData['photoURL'],
        coverImageUrl: userData['coverImageUrl'],
        bio: userData['bio'],
        interests: List<String>.from(userData['interests'] ?? []),
        role: domain.UserRole.values.firstWhere(
          (e) => e.name == userData['role'],
          orElse: () => domain.UserRole.buyer,
        ),
        status: domain.UserStatus.values.firstWhere(
          (e) => e.name == userData['status'],
          orElse: () => domain.UserStatus.active,
        ),
        createdAt: (userData['createdAt'] as Timestamp).toDate(),
        updatedAt: (userData['updatedAt'] as Timestamp).toDate(),
        isVerified: userData['isVerified'] ?? false,
        rating: averageRating,
        totalSales: userData['totalSales'] ?? 0,
        totalPurchases: userData['totalPurchases'] ?? 0,
        followersCount: userData['followersCount'] ?? 0,
        followingCount: userData['followingCount'] ?? 0,
        location: userData['location'],
        reviews: reviews,
      );
    } catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  @override
  Future<void> submitReview({
    required String reviewedUserId,
    required double rating,
    required String comment,
  }) async {
    final currentUser = _firebaseService.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      // Check if user has already reviewed this user
      final existingReview = await _firebaseService.reviews
          .where('reviewerId', isEqualTo: currentUser.uid)
          .where('reviewedUserId', isEqualTo: reviewedUserId)
          .get();

      if (existingReview.docs.isNotEmpty) {
        // Update existing review
        await _firebaseService.reviews.doc(existingReview.docs.first.id).update({
          'rating': rating,
          'comment': comment,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new review
        await _firebaseService.reviews.add({
          'reviewerId': currentUser.uid,
          'reviewerName': currentUser.displayName ?? 'Anonymous',
          'reviewerAvatar': currentUser.photoURL ?? '',
          'reviewedUserId': reviewedUserId,
          'rating': rating,
          'comment': comment,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  @override
  Future<void> refreshToken() async {
    final user = _firebaseService.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    try {
      // Force refresh the token
      await user.getIdToken(true);
    } catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  @override
  Future<bool> isTokenValid() async {
    final user = _firebaseService.currentUser;
    if (user == null) return false;
    
    try {
      // Try to get the token and check if it's valid
      final token = await user.getIdToken(false);
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    // Public wrapper for the private method, with additional input validation
    if (username.trim().isEmpty) return false;
    return await _isUsernameAvailable(username.trim().toLowerCase());
  }

  domain.User _mapFirebaseUserToDomain(User firebaseUser, Map<String, dynamic> userData) {
    return domain.User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      firstName: userData['firstName'] ?? '',
      lastName: userData['lastName'] ?? '',
      username: userData['username'] ?? userData['firstName'] ?? 'user',
      phoneNumber: userData['phoneNumber'],
      profileImageUrl: userData['photoURL'],
      role: domain.UserRole.values.firstWhere(
        (e) => e.name == userData['role'],
        orElse: () => domain.UserRole.buyer,
      ),
      status: domain.UserStatus.values.firstWhere(
        (e) => e.name == userData['status'],
        orElse: () => domain.UserStatus.active,
      ),
      createdAt: userData['createdAt'] != null 
          ? (userData['createdAt'] as Timestamp).toDate()
          : firebaseUser.metadata.creationTime ?? DateTime.now(),
      updatedAt: userData['updatedAt'] != null
          ? (userData['updatedAt'] as Timestamp).toDate()
          : firebaseUser.metadata.lastSignInTime ?? DateTime.now(),
      isVerified: firebaseUser.emailVerified,
      rating: (userData['rating'] ?? 0.0).toDouble(),
      totalSales: userData['totalSales'] ?? 0,
      totalPurchases: userData['totalPurchases'] ?? 0,
    );
  }

  Exception _mapFirebaseException(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return Exception('Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı');
        case 'wrong-password':
          return Exception('Geçersiz şifre');
        case 'email-already-in-use':
          return Exception('Bu e-posta adresi zaten kullanımda');
        case 'weak-password':
          return Exception('Şifre çok zayıf');
        case 'invalid-email':
          return Exception('Geçersiz e-posta adresi');
        case 'user-disabled':
          return Exception('Bu hesap devre dışı bırakılmış');
        case 'too-many-requests':
          return Exception('Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin');
        default:
          return Exception('Bir hata oluştu: ${error.message}');
      }
    }
    
    // Custom error handling for username conflicts
    final errorMessage = error.toString();
    if (errorMessage.contains('Username çakışması tespit edildi')) {
      return Exception('Bu kullanıcı adı zaten kullanımda. Sistem otomatik olarak benzersiz bir alternatif oluşturmaya çalışacak.');
    }
    
    return Exception('Bilinmeyen hata: $error');
  }

  String _getFirebaseAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Geçersiz şifre.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda.';
      case 'weak-password':
        return 'Şifre çok zayıf.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış.';
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin.';
      default:
        return 'Bir hata oluştu: ${code.replaceAll('-', ' ')}';
    }
  }

  Future<void> _ensureUsernameIndex(User firebaseUser, Map<String, dynamic> userData) async {
    try {
      String? username = _sanitizeUsername(userData['username'] as String?);

      if (username == null || username.isEmpty) {
        username = _deriveUsername(firebaseUser, userData);
        if (username == null) {
          debugPrint('⚠️ DEBUG: Username türetilemedi, usernameIndex atlanıyor');
          return;
        }

        await _firebaseService.firestore.collection('users').doc(firebaseUser.uid).set({
          'username': username,
          'displayName': userData['displayName'] ?? username,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('✅ DEBUG: Kullanıcı için eksik username güncellendi: $username');
      }

      final indexRef = _firebaseService.firestore.collection('usernameIndex').doc(username);
      final indexDoc = await indexRef.get();

      final payload = {
        'username': username,
        'email': firebaseUser.email,
        'uid': firebaseUser.uid,
        'displayName': userData['displayName'] ?? username,
        'role': userData['role'] ?? 'buyer',
        'status': userData['status'] ?? 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (indexDoc.exists) {
        // merge ile güncelle
        await indexRef.set(payload, SetOptions(merge: true));
        return;
      }

      await indexRef.set({
        ...payload,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ DEBUG: UsernameIndex kaydı oluşturuldu (login sonrası): $username');
    } catch (e) {
      debugPrint('⚠️ DEBUG: UsernameIndex kaydı oluşturulamadı: $e');
    }
  }

  String? _sanitizeUsername(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim().toLowerCase();
    if (trimmed.isEmpty) return null;
    final sanitized = trimmed.replaceAll(RegExp(r'[^a-z0-9_]+'), '_');
    return sanitized.isEmpty ? null : sanitized;
  }

  String? _deriveUsername(User firebaseUser, Map<String, dynamic> userData) {
    final email = firebaseUser.email;
    if (email != null && email.contains('@')) {
      final local = email.split('@').first;
      final handle = _sanitizeUsername(local);
      if (handle != null && handle.length >= 3) {
        return handle;
      }
    }

    final displayName = userData['displayName'] as String?;
    final nameHandle = _sanitizeUsername(displayName);
    if (nameHandle != null && nameHandle.length >= 3) {
      return nameHandle;
    }

    return _sanitizeUsername(firebaseUser.uid.substring(0, 6));
  }
}
