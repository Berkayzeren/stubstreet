// lib/core/services/firebase_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Getters
  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  FirebaseStorage get storage => _storage;

  // Collections
  CollectionReference get users => _firestore.collection('users');
  CollectionReference get tickets => _firestore.collection('tickets');
  CollectionReference get orders => _firestore.collection('orders');
  CollectionReference get conversations => _firestore.collection('conversations');
  CollectionReference get messages => _firestore.collection('messages');
  CollectionReference get reviews => _firestore.collection('reviews');
  CollectionReference get notifications => _firestore.collection('notifications');

  // Current user
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;

  // Authentication state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Create user document
  Future<void> createUserDocument(User user, [Map<String, dynamic>? additionalData]) async {
    final userDoc = users.doc(user.uid);
    final snapshot = await userDoc.get();
    
    if (!snapshot.exists) {
      final userData = {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isVerified': user.emailVerified,
        'rating': 0.0,
        'totalSales': 0,
        'totalPurchases': 0,
        'followersCount': 0,
        'followingCount': 0,
        'role': 'buyer',
        'status': 'active',
        ...?additionalData,
      };
      
      await userDoc.set(userData);
    }
  }

  // Update user document
  Future<void> updateUserDocument(String userId, Map<String, dynamic> data) async {
    await users.doc(userId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get user document
  Future<DocumentSnapshot> getUserDocument(String userId) async {
    return await users.doc(userId).get();
  }

  // Get user stream
  Stream<DocumentSnapshot> getUserStream(String userId) {
    return users.doc(userId).snapshots();
  }

  // Batch operations
  WriteBatch batch() => _firestore.batch();

  // Transaction
  Future<T> runTransaction<T>(TransactionHandler<T> updateFunction) {
    return _firestore.runTransaction(updateFunction);
  }
}
