// lib/features/auth/domain/entities/user_profile.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'user.dart';

class UserProfile {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String username; // Add username field
  final String? phoneNumber;
  final String? profileImageUrl;
  final String? coverImageUrl;
  final String? bio;
  final List<String> interests;
  final UserRole role;
  final UserStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? stripeCustomerId;
  final String? stripeAccountId;
  final bool isVerified;
  final double rating;
  final int totalSales;
  final int totalPurchases;
  final int followersCount;
  final int followingCount;
  final bool isFollowing;
  final List<String> socialLinks;
  final String? location;
  final List<UserReview> reviews;

  const UserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.username,
    this.phoneNumber,
    this.profileImageUrl,
    this.coverImageUrl,
    this.bio,
    this.interests = const [],
    this.role = UserRole.buyer,
    this.status = UserStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.stripeCustomerId,
    this.stripeAccountId,
    this.isVerified = false,
    this.rating = 0.0,
    this.totalSales = 0,
    this.totalPurchases = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.isFollowing = false,
    this.socialLinks = const [],
    this.location,
    this.reviews = const [],
  });

  UserProfile copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? username,
    String? phoneNumber,
    String? profileImageUrl,
    String? coverImageUrl,
    String? bio,
    List<String>? interests,
    UserRole? role,
    UserStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? stripeCustomerId,
    String? stripeAccountId,
    bool? isVerified,
    double? rating,
    int? totalSales,
    int? totalPurchases,
    int? followersCount,
    int? followingCount,
    bool? isFollowing,
    List<String>? socialLinks,
    String? location,
    List<UserReview>? reviews,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      stripeAccountId: stripeAccountId ?? this.stripeAccountId,
      isVerified: isVerified ?? this.isVerified,
      rating: rating ?? this.rating,
      totalSales: totalSales ?? this.totalSales,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      isFollowing: isFollowing ?? this.isFollowing,
      socialLinks: socialLinks ?? this.socialLinks,
      location: location ?? this.location,
      reviews: reviews ?? this.reviews,
    );
  }

  String get fullName => '$firstName $lastName';
  String get displayName => fullName;

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'coverImageUrl': coverImageUrl,
      'bio': bio,
      'interests': interests,
      'role': role.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'stripeCustomerId': stripeCustomerId,
      'stripeAccountId': stripeAccountId,
      'isVerified': isVerified,
      'rating': rating,
      'totalSales': totalSales,
      'totalPurchases': totalPurchases,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'socialLinks': socialLinks,
      'location': location,
    };
  }

  // Create from Firestore document
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      id: doc.id,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      username: data['username'] ?? data['email']?.split('@')[0] ?? 'user',
      phoneNumber: data['phoneNumber'],
      profileImageUrl: data['profileImageUrl'],
      coverImageUrl: data['coverImageUrl'],
      bio: data['bio'],
      interests: List<String>.from(data['interests'] ?? []),
      role: UserRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => UserRole.buyer,
      ),
      status: UserStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => UserStatus.active,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      stripeCustomerId: data['stripeCustomerId'],
      stripeAccountId: data['stripeAccountId'],
      isVerified: data['isVerified'] ?? false,
      rating: (data['rating'] ?? 0.0).toDouble(),
      totalSales: data['totalSales'] ?? 0,
      totalPurchases: data['totalPurchases'] ?? 0,
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      socialLinks: List<String>.from(data['socialLinks'] ?? []),
      location: data['location'],
    );
  }

  // Convert from User entity
  factory UserProfile.fromUser(User user) {
    return UserProfile(
      id: user.id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      username: user.username,
      phoneNumber: user.phoneNumber,
      profileImageUrl: user.profileImageUrl,
      role: user.role,
      status: user.status,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      isVerified: user.isVerified,
      rating: user.rating,
      totalSales: user.totalSales,
      totalPurchases: user.totalPurchases,
    );
  }

  // Convert from Firebase User
  factory UserProfile.fromFirebaseUser(firebase_auth.User firebaseUser) {
    return UserProfile(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      firstName: firebaseUser.displayName?.split(' ').first ?? '',
      lastName: firebaseUser.displayName?.split(' ').skip(1).join(' ') ?? '',
      username: firebaseUser.email?.split('@')[0] ?? 'user',
      phoneNumber: firebaseUser.phoneNumber,
      profileImageUrl: firebaseUser.photoURL,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      updatedAt: firebaseUser.metadata.lastSignInTime ?? DateTime.now(),
      isVerified: firebaseUser.emailVerified,
      rating: 0.0, // Yeni kullanıcı
      reviews: [], // Henüz değerlendirme yok
    );
  }
}

class UserReview {
  final String id;
  final String reviewerId;
  final String reviewerName;
  final String reviewerAvatar;
  final double rating;
  final String comment;
  final DateTime createdAt;

  const UserReview({
    required this.id,
    required this.reviewerId,
    required this.reviewerName,
    required this.reviewerAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory UserReview.fromFirestore(DocumentSnapshot doc) {
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
  }
}
