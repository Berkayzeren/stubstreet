// scripts/update_admin_user.dart
// Bu script mevcut kullanıcıyı admin olarak günceller

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // Şu an kullanılmıyor
import 'package:stubstreet/firebase_options.dart';

Future<void> main() async {
  // Firebase'i initialize et
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // final auth = FirebaseAuth.instance; // Şu an kullanılmıyor
  final firestore = FirebaseFirestore.instance;
  
  print('🔍 Mevcut kullanıcılar kontrol ediliyor...');
  
  // Tüm kullanıcıları listele
  final usersSnapshot = await firestore.collection('users').get();
  print('📊 ${usersSnapshot.docs.length} kullanıcı bulundu');
  
  for (final userDoc in usersSnapshot.docs) {
    final userData = userDoc.data();
    final email = userData['email'] as String?;
    final displayName = userData['displayName'] as String?;
    final role = userData['role'] as String?;
    
    print('👤 Kullanıcı: $email ($displayName) - Rol: $role');
  }
  
  // berkayzeren67@gmail.com kullanıcısını admin olarak güncelle
  final berkayUserQuery = await firestore
      .collection('users')
      .where('email', isEqualTo: 'berkayzeren67@gmail.com')
      .get();
  
  if (berkayUserQuery.docs.isNotEmpty) {
    final userDoc = berkayUserQuery.docs.first;
    final userId = userDoc.id;
    
    print('🔍 berkayzeren67@gmail.com kullanıcısı bulundu: $userId');
    
    // Kullanıcıyı admin olarak güncelle
    await firestore.collection('users').doc(userId).update({
      'role': 'admin',
      'isAdmin': true,
      'username': 'admin',
      'displayName': 'Admin',
      'firstName': 'Admin',
      'lastName': 'User',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    print('✅ Kullanıcı admin olarak güncellendi');
    
    // UsernameIndex'e admin kullanıcısını ekle
    await firestore.collection('usernameIndex').doc('admin').set({
      'username': 'admin',
      'email': 'berkayzeren67@gmail.com',
      'uid': userId,
      'role': 'admin',
      'status': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    print('✅ Admin kullanıcısı UsernameIndex\'e eklendi');
    
    // Şifreyi 123456 olarak güncelle (Firebase Auth'da şifre güncelleme için kullanıcı giriş yapmalı)
    print('🔑 Şifre güncelleme için kullanıcı giriş yapmalı');
    print('📧 Email: berkayzeren67@gmail.com');
    print('👤 Kullanıcı adı: admin');
    print('🔑 Mevcut şifre ile giriş yapın, sonra şifreyi 123456 olarak değiştirin');
    
  } else {
    print('❌ berkayzeren67@gmail.com kullanıcısı bulunamadı');
  }
  
  print('\n🎉 Admin kullanıcısı güncelleme işlemi tamamlandı!');
}
