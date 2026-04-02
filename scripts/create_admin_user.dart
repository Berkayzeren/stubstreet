// scripts/create_admin_user.dart
// Bu script admin kullanıcısı oluşturur

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stubstreet/firebase_options.dart';

Future<void> main() async {
  // Firebase'i initialize et
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  
  print('🔍 Admin kullanıcısı oluşturuluyor...');
  
  try {
    // Admin kullanıcısını oluştur
    final userCredential = await auth.createUserWithEmailAndPassword(
      email: 'admin@biletsokagi.com',
      password: '123456',
    );
    
    final user = userCredential.user!;
    print('✅ Admin kullanıcısı oluşturuldu: ${user.uid}');
    
    // Display name'i güncelle
    await user.updateDisplayName('Admin');
    await user.reload();
    
    // Users koleksiyonuna admin verilerini ekle
    await firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': 'admin@biletsokagi.com',
      'displayName': 'Admin',
      'firstName': 'Admin',
      'lastName': 'User',
      'username': 'admin',
      'phoneNumber': '+905551234567',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isVerified': true,
      'rating': 5.0,
      'totalSales': 0,
      'totalPurchases': 0,
      'followersCount': 0,
      'followingCount': 0,
      'role': 'admin',  // Admin rolü
      'status': 'active',
      'isAdmin': true,  // Admin flag'i
    });
    
    print('✅ Admin kullanıcı verileri Firestore\'a eklendi');
    
    // UsernameIndex'e admin kullanıcısını ekle
    await firestore.collection('usernameIndex').doc('admin').set({
      'username': 'admin',
      'email': 'admin@biletsokagi.com',
      'uid': user.uid,
      'role': 'admin',
      'status': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    print('✅ Admin kullanıcısı UsernameIndex\'e eklendi');
    
    // Admin kullanıcısını test et
    print('🔍 Admin kullanıcısı test ediliyor...');
    await auth.signOut();
    
    final signInResult = await auth.signInWithEmailAndPassword(
      email: 'admin@biletsokagi.com',
      password: '123456',
    );
    
    if (signInResult.user != null) {
      print('✅ Admin kullanıcısı ile giriş başarılı');
      print('👤 Admin bilgileri:');
      print('   - UID: ${signInResult.user!.uid}');
      print('   - Email: ${signInResult.user!.email}');
      print('   - Display Name: ${signInResult.user!.displayName}');
    } else {
      print('❌ Admin kullanıcısı ile giriş başarısız');
    }
    
    print('\n🎉 Admin kullanıcısı başarıyla oluşturuldu!');
    print('📧 Email: admin@biletsokagi.com');
    print('🔑 Şifre: 123456');
    print('👤 Kullanıcı adı: admin');
    
  } catch (e) {
    print('❌ Admin kullanıcısı oluşturulurken hata: $e');
    
    // Eğer kullanıcı zaten varsa, bilgilerini güncelle
    if (e.toString().contains('email-already-in-use')) {
      print('🔍 Admin kullanıcısı zaten mevcut, bilgileri güncelleniyor...');
      
      try {
        final signInResult = await auth.signInWithEmailAndPassword(
          email: 'admin@biletsokagi.com',
          password: '123456',
        );
        
        if (signInResult.user != null) {
          final user = signInResult.user!;
          
          // Display name'i güncelle
          await user.updateDisplayName('Admin');
          await user.reload();
          
          // Users koleksiyonunu güncelle
          await firestore.collection('users').doc(user.uid).update({
            'displayName': 'Admin',
            'firstName': 'Admin',
            'lastName': 'User',
            'username': 'admin',
            'phoneNumber': '+905551234567',
            'updatedAt': FieldValue.serverTimestamp(),
            'role': 'admin',
            'status': 'active',
            'isAdmin': true,
          });
          
          // UsernameIndex'i güncelle
          await firestore.collection('usernameIndex').doc('admin').set({
            'username': 'admin',
            'email': 'admin@biletsokagi.com',
            'uid': user.uid,
            'role': 'admin',
            'status': 'active',
            'updatedAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          });
          
          print('✅ Admin kullanıcısı bilgileri güncellendi');
          print('📧 Email: admin@biletsokagi.com');
          print('🔑 Şifre: 123456');
          print('👤 Kullanıcı adı: admin');
        }
      } catch (updateError) {
        print('❌ Admin kullanıcısı güncellenirken hata: $updateError');
      }
    }
  }
}
