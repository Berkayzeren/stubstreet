// lib/features/auth/domain/entities/user.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { buyer, seller, admin }

enum UserStatus { active, suspended, deleted }

class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String username; // Unique username for display and mentions
  final String? phoneNumber;
  final String? profileImageUrl;
  final UserRole role;
  final UserStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVerified;
  final double rating;
  final int totalSales;
  final int totalPurchases;

  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.username,
    this.phoneNumber,
    this.profileImageUrl,
    this.role = UserRole.buyer,
    this.status = UserStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.isVerified = false,
    this.rating = 0.0,
    this.totalSales = 0,
    this.totalPurchases = 0,
  });

  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? username,
    String? phoneNumber,
    String? profileImageUrl,
    UserRole? role,
    UserStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
    double? rating,
    int? totalSales,
    int? totalPurchases,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
      rating: rating ?? this.rating,
      totalSales: totalSales ?? this.totalSales,
      totalPurchases: totalPurchases ?? this.totalPurchases,
    );
  }

  String get fullName => '$firstName $lastName';
  String get displayName => username; // Use username for display instead of full name
  String get uid => id; // Firebase compat
  bool get emailVerified => isVerified; // Firebase compat

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'role': role.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isVerified': isVerified,
      'rating': rating,
      'totalSales': totalSales,
      'totalPurchases': totalPurchases,
    };
  }

  // Create from Firestore document
  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      username: data['username'] ?? data['firstName'] ?? 'user', // Fallback to firstName if username not found
      phoneNumber: data['phoneNumber'],
      profileImageUrl: data['profileImageUrl'],
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
      isVerified: data['isVerified'] ?? false,
      rating: (data['rating'] ?? 0.0).toDouble(),
      totalSales: data['totalSales'] ?? 0,
      totalPurchases: data['totalPurchases'] ?? 0,
    );
  }
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.buyer:
        return 'Alıcı';
      case UserRole.seller:
        return 'Satıcı';
      case UserRole.admin:
        return 'Yönetici';
    }
  }
}

extension UserStatusExtension on UserStatus {
  String get displayName {
    switch (this) {
      case UserStatus.active:
        return 'Aktif';
      case UserStatus.suspended:
        return 'Askıya Alındı';
      case UserStatus.deleted:
        return 'Silindi';
    }
  }
}
