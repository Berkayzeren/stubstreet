// lib/core/providers/admin_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin kullanıcı kontrolü için provider
final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  return AdminNotifier();
});

class AdminState {
  final bool isAdmin;
  final bool isLoading;
  final String? error;

  const AdminState({
    this.isAdmin = false,
    this.isLoading = false,
    this.error,
  });

  AdminState copyWith({
    bool? isAdmin,
    bool? isLoading,
    String? error,
  }) {
    return AdminState(
      isAdmin: isAdmin ?? this.isAdmin,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AdminNotifier extends StateNotifier<AdminState> {
  // Admin kullanıcı ID'leri - güvenlik için burada tanımlanmış
  static const List<String> _adminUserIds = [
    'Fu9NlPlGXjQROCW96fZUUTLueUf2', // admin@biletsokagi.com
    // Buraya başka admin kullanıcı ID'leri eklenebilir
  ];

  // Admin email adresleri - alternatif kontrol için
  static const List<String> _adminEmails = [
    'admin@biletsokagi.com',
    // Buraya başka admin email'leri eklenebilir
  ];

  AdminNotifier() : super(const AdminState()) {
    _checkAdminStatus();
    
    // Auth state değişikliklerini dinle
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _checkAdminStatus();
    });
  }

  /// Mevcut kullanıcının admin olup olmadığını kontrol et
  Future<void> _checkAdminStatus() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        state = state.copyWith(isAdmin: false, isLoading: false);
        return;
      }

      // 1. UID kontrolü (en hızlı)
      if (_adminUserIds.contains(user.uid)) {
        state = state.copyWith(isAdmin: true, isLoading: false);
        return;
      }

      // 2. Email kontrolü
      if (user.email != null && _adminEmails.contains(user.email!.toLowerCase())) {
        state = state.copyWith(isAdmin: true, isLoading: false);
        return;
      }

      // 3. Firestore'dan admin rolü kontrolü (opsiyonel)
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final isAdmin = userData['isAdmin'] == true || 
                       userData['role'] == 'admin' ||
                       userData['roles']?.contains('admin') == true;
        
        state = state.copyWith(isAdmin: isAdmin, isLoading: false);
      } else {
        state = state.copyWith(isAdmin: false, isLoading: false);
      }

    } catch (e) {
      state = state.copyWith(
        isAdmin: false, 
        isLoading: false, 
        error: 'Admin kontrolü başarısız: $e'
      );
    }
  }

  /// Manuel admin kontrolü
  Future<void> checkAdminStatus() async {
    await _checkAdminStatus();
  }

  /// Kullanıcıyı admin yap (sadece mevcut adminler yapabilir)
  Future<bool> makeUserAdmin(String userId) async {
    if (!state.isAdmin) {
      state = state.copyWith(error: 'Bu işlem için admin yetkisi gerekli');
      return false;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'isAdmin': true,
        'role': 'admin',
        'adminGrantedBy': FirebaseAuth.instance.currentUser?.uid,
        'adminGrantedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Admin yetkisi verilemedi: $e');
      return false;
    }
  }

  /// Kullanıcının admin yetkisini kaldır
  Future<bool> removeAdminAccess(String userId) async {
    if (!state.isAdmin) {
      state = state.copyWith(error: 'Bu işlem için admin yetkisi gerekli');
      return false;
    }

    // Kendini admin'likten çıkaramaz
    if (userId == FirebaseAuth.instance.currentUser?.uid) {
      state = state.copyWith(error: 'Kendi admin yetkinizi kaldıramazsınız');
      return false;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'isAdmin': false,
        'role': 'user',
        'adminRemovedBy': FirebaseAuth.instance.currentUser?.uid,
        'adminRemovedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Admin yetkisi kaldırılamadı: $e');
      return false;
    }
  }
}

/// Sadece admin kontrolü için basit provider
final isAdminProvider = Provider<bool>((ref) {
  final adminState = ref.watch(adminProvider);
  return adminState.isAdmin;
});

/// Admin loading durumu provider
final isAdminLoadingProvider = Provider<bool>((ref) {
  final adminState = ref.watch(adminProvider);
  return adminState.isLoading;
});
