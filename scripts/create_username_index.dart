// scripts/create_username_index.dart
// Bu script mevcut kullanıcılar için usernameIndex koleksiyonunu oluşturur

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:stubstreet/firebase_options.dart';

Future<void> main() async {
  // Firebase'i initialize et
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  
  print('🔍 Mevcut kullanıcılar kontrol ediliyor...');
  
  // Users koleksiyonundaki tüm kullanıcıları al
  final usersSnapshot = await firestore.collection('users').get();
  print('📊 ${usersSnapshot.docs.length} kullanıcı bulundu');
  
  // UsernameIndex koleksiyonunu kontrol et
  final usernameIndexSnapshot = await firestore.collection('usernameIndex').get();
  print('📊 UsernameIndex\'te ${usernameIndexSnapshot.docs.length} kayıt var');
  
  int createdCount = 0;
  int updatedCount = 0;
  
  for (final userDoc in usersSnapshot.docs) {
    final userData = userDoc.data();
    final username = userData['username'] as String?;
    final email = userData['email'] as String?;
    final uid = userDoc.id;
    
    if (username != null && username.isNotEmpty && email != null) {
      print('👤 Kullanıcı: $username ($email)');
      
      // UsernameIndex'te bu username var mı kontrol et
      final existingIndexDoc = await firestore
          .collection('usernameIndex')
          .doc(username)
          .get();
      
      if (!existingIndexDoc.exists) {
        // UsernameIndex'e ekle
        await firestore.collection('usernameIndex').doc(username).set({
          'username': username,
          'email': email,
          'uid': uid,
          'role': userData['role'] ?? 'buyer',
          'status': userData['status'] ?? 'active',
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('✅ UsernameIndex oluşturuldu: $username -> $email');
        createdCount++;
      } else {
        // Mevcut kaydı güncelle
        await firestore.collection('usernameIndex').doc(username).update({
          'email': email,
          'uid': uid,
          'role': userData['role'] ?? 'buyer',
          'status': userData['status'] ?? 'active',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('🔄 UsernameIndex güncellendi: $username -> $email');
        updatedCount++;
      }
    } else {
      print('⚠️ Kullanıcı eksik bilgi: username=$username, email=$email');
    }
  }
  
  print('\n📊 Özet:');
  print('✅ $createdCount yeni kayıt oluşturuldu');
  print('🔄 $updatedCount kayıt güncellendi');
  
  // Son durumu kontrol et
  final finalUsernameIndexSnapshot = await firestore.collection('usernameIndex').get();
  print('📊 UsernameIndex\'te toplam ${finalUsernameIndexSnapshot.docs.length} kayıt var');
  
  print('\n🎉 UsernameIndex oluşturma işlemi tamamlandı!');
}
