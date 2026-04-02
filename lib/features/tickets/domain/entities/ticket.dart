// lib/features/tickets/domain/entities/ticket.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum TicketCategory {
  concert,
  sports,
  theater,
  festival,
  comedy,
  museum,
  exhibition,
  workshop,
  cinema,
  party,
  conference,
  other,
}

enum TicketStatus { available, sold, reserved, expired }

class Ticket {
  final String id;
  final String title;
  final String description;
  final String venue;
  final String city;
  final DateTime eventDate;
  final DateTime saleDate;
  final double originalPrice;
  final double sellingPrice;
  final TicketCategory category;
  final TicketStatus status;
  final String sellerId;
  final String sellerName;
  final String? sellerAvatarUrl;
  final List<String> imageUrls;
  final String? buyerId;
  final DateTime? soldDate;
  final bool isVerified;
  final String? seatInfo;
  final String? eventImageUrl;
  final DateTime? lockUntil;
  final double? latitude; // Etkinlik konumu - latitude
  final double? longitude; // Etkinlik konumu - longitude
  final String? locationName; // Konum açıklaması

  const Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.venue,
    required this.city,
    required this.eventDate,
    required this.saleDate,
    required this.originalPrice,
    required this.sellingPrice,
    required this.category,
    required this.status,
    required this.sellerId,
    required this.sellerName,
    this.sellerAvatarUrl,
    required this.imageUrls,
    this.buyerId,
    this.soldDate,
    this.isVerified = false,
    this.seatInfo,
    this.eventImageUrl,
    this.lockUntil,
    this.latitude,
    this.longitude,
    this.locationName,
  });

  Ticket copyWith({
    String? id,
    String? title,
    String? description,
    String? venue,
    String? city,
    DateTime? eventDate,
    DateTime? saleDate,
    double? originalPrice,
    double? sellingPrice,
    TicketCategory? category,
    TicketStatus? status,
    String? sellerId,
    String? sellerName,
    String? sellerAvatarUrl,
    List<String>? imageUrls,
    String? buyerId,
    DateTime? soldDate,
    bool? isVerified,
    String? seatInfo,
    String? eventImageUrl,
    DateTime? lockUntil,
    double? latitude,
    double? longitude,
    String? locationName,
  }) {
    return Ticket(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      venue: venue ?? this.venue,
      city: city ?? this.city,
      eventDate: eventDate ?? this.eventDate,
      saleDate: saleDate ?? this.saleDate,
      originalPrice: originalPrice ?? this.originalPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      category: category ?? this.category,
      status: status ?? this.status,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerAvatarUrl: sellerAvatarUrl ?? this.sellerAvatarUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      buyerId: buyerId ?? this.buyerId,
      soldDate: soldDate ?? this.soldDate,
      isVerified: isVerified ?? this.isVerified,
      seatInfo: seatInfo ?? this.seatInfo,
      eventImageUrl: eventImageUrl ?? this.eventImageUrl,
      lockUntil: lockUntil ?? this.lockUntil,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
    );
  }

  // Firebase'den veri çekmek için
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'venue': venue,
      'city': city,
      'eventDate': Timestamp.fromDate(eventDate),
      'saleDate': Timestamp.fromDate(saleDate),
      'originalPrice': originalPrice,
      'sellingPrice': sellingPrice,
      'category': category.name,
      'status': status.name,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerAvatarUrl': sellerAvatarUrl,
      'imageUrls': imageUrls,
      'buyerId': buyerId,
      'soldDate': soldDate != null ? Timestamp.fromDate(soldDate!) : null,
      'isVerified': isVerified,
      'seatInfo': seatInfo,
      'eventImageUrl': eventImageUrl,
      'lockUntil': lockUntil != null ? Timestamp.fromDate(lockUntil!) : null,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
    };
  }

  // Firebase'den veri okumak için
  factory Ticket.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Document data is null');
      }
      
      return Ticket(
        id: doc.id,
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        venue: data['venue'] ?? data['locationName'] ?? '',
        city: data['city'] ?? 'İstanbul',
        eventDate: data['eventDate'] != null 
            ? (data['eventDate'] as Timestamp).toDate()
            : DateTime.now().add(const Duration(days: 30)),
        saleDate: data['saleDate'] != null 
            ? (data['saleDate'] as Timestamp).toDate()
            : DateTime.now(),
        originalPrice: (data['originalPrice'] ?? data['price'] ?? 0.0).toDouble(),
        sellingPrice: (data['sellingPrice'] ?? data['price'] ?? 0.0).toDouble(),
        category: data['category'] != null 
            ? TicketCategory.values.firstWhere(
                (e) => e.name == data['category'],
                orElse: () => TicketCategory.other,
              )
            : TicketCategory.other,
        status: data['status'] != null 
            ? TicketStatus.values.firstWhere(
                (e) => e.name == data['status'],
                orElse: () => TicketStatus.available,
              )
            : TicketStatus.available,
        sellerId: data['sellerId'] ?? '',
        sellerName: data['sellerName'] ?? '',
        sellerAvatarUrl: data['sellerAvatarUrl'],
        imageUrls: List<String>.from(data['imageUrls'] ?? []),
        buyerId: data['buyerId'],
        soldDate: data['soldDate'] != null
            ? (data['soldDate'] as Timestamp).toDate()
            : null,
        isVerified: data['isVerified'] ?? false,
        seatInfo: data['seatInfo'],
        eventImageUrl: data['eventImageUrl'],
        lockUntil: data['lockUntil'] != null
            ? (data['lockUntil'] as Timestamp).toDate()
            : null,
        latitude: data['latitude']?.toDouble(),
        longitude: data['longitude']?.toDouble(),
        locationName: data['locationName'],
      );
    } catch (e) {
      debugPrint('❌ DEBUG: Ticket.fromFirestore hatası - Doc ID: ${doc.id}, Error: $e');
      rethrow;
    }
  }
}

// Kategori uzantıları
extension TicketCategoryExtension on TicketCategory {
  String get displayName {
    switch (this) {
      case TicketCategory.concert:
        return 'Konser';
      case TicketCategory.sports:
        return 'Spor';
      case TicketCategory.theater:
        return 'Tiyatro';
      case TicketCategory.festival:
        return 'Festival';
      case TicketCategory.comedy:
        return 'Komedi';
      case TicketCategory.museum:
        return 'Müze';
      case TicketCategory.exhibition:
        return 'Sergi';
      case TicketCategory.workshop:
        return 'Atölye';
      case TicketCategory.cinema:
        return 'Sinema';
      case TicketCategory.party:
        return 'Parti';
      case TicketCategory.conference:
        return 'Konferans';
      case TicketCategory.other:
        return 'Diğer';
    }
  }

  String get icon {
    switch (this) {
      case TicketCategory.concert:
        return '🎵';
      case TicketCategory.sports:
        return '⚽';
      case TicketCategory.theater:
        return '🎭';
      case TicketCategory.festival:
        return '🎪';
      case TicketCategory.comedy:
        return '😄';
      case TicketCategory.museum:
        return '🏛️';
      case TicketCategory.exhibition:
        return '🖼️';
      case TicketCategory.workshop:
        return '🛠️';
      case TicketCategory.cinema:
        return '🎬';
      case TicketCategory.party:
        return '🎉';
      case TicketCategory.conference:
        return '🎤';
      case TicketCategory.other:
        return '🎫';
    }
  }
}

extension TicketStatusExtension on TicketStatus {
  String get displayName {
    switch (this) {
      case TicketStatus.available:
        return 'Satışta';
      case TicketStatus.sold:
        return 'Satıldı';
      case TicketStatus.reserved:
        return 'Rezerve';
      case TicketStatus.expired:
        return 'Süresi Doldu';
    }
  }
}
