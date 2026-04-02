// lib/features/tickets/data/repositories/ticket_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/repositories/ticket_repository.dart';

class TicketRepositoryImpl implements TicketRepository {
  final FirebaseFirestore _firestore;

  TicketRepositoryImpl(this._firestore);

  CollectionReference get _ticketsCollection =>
      _firestore.collection('tickets');

  @override
  Stream<List<Ticket>> getTickets() {
    return _ticketsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Ticket.fromFirestore(doc)).toList(),
        );
  }

  // GetAllTickets method for FutureProvider
  Future<List<Ticket>> getAllTickets() async {
    try {
      debugPrint('🔍 DEBUG: Biletler yükleniyor...');
      
      // Önce tüm biletleri al ve manuel filtreleme yap
      // (whereIn + orderBy composite index sorunu için)
      final allSnapshot = await _ticketsCollection.get();
      debugPrint('🔍 DEBUG: Toplam ${allSnapshot.docs.length} bilet bulundu');
      
      // Status dağılımını göster
      final statusCounts = <String, int>{};
      final availableTickets = <QueryDocumentSnapshot>[];
      
      for (final doc in allSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] ?? 'no_status';
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
        
        // Sadece available olanları topla
        if (status == 'available') {
          availableTickets.add(doc);
        }
      }
      
      // Debug: Status dağılımını göster
      debugPrint('📊 DEBUG: Status dağılımı:');
      statusCounts.forEach((status, ticketCount) {
        debugPrint('   - Status "$status": $ticketCount bilet');
      });
      
      debugPrint('🎯 DEBUG: ${availableTickets.length} adet "available" bilet bulundu');
      
      // Available biletleri tarihe göre sırala
      availableTickets.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        
        // createdAt alanı yoksa saleDate'i kullan
        final aTime = aData['createdAt'] ?? aData['saleDate'];
        final bTime = bData['createdAt'] ?? bData['saleDate'];
        
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        
        // Timestamp ise karşılaştır
        if (aTime is Timestamp && bTime is Timestamp) {
          return bTime.compareTo(aTime); // Descending
        }
        return 0;
      });
      
      // Available biletleri Ticket nesnesine dönüştür
      final tickets = <Ticket>[];
      for (final doc in availableTickets) {
        try {
          final ticket = Ticket.fromFirestore(doc);
          tickets.add(ticket);
          
          // Debug: Her biletin detayları
          final data = doc.data() as Map<String, dynamic>;
          debugPrint('📋 DEBUG: Bilet ${doc.id}:');
          debugPrint('   - Title: ${data['title']}');
          debugPrint('   - Status: ${data['status']}');
          debugPrint('   - CreatedAt: ${data['createdAt']}');
          debugPrint('   - SellerId: ${data['sellerId']}');
        } catch (e) {
          debugPrint('❌ DEBUG: Bilet yükleme hatası - Doc ID: ${doc.id}, Error: $e');
          // Hatalı biletleri atla, diğerlerini yükle
        }
      }
      
      debugPrint('✅ DEBUG: ${tickets.length} bilet başarıyla yüklendi');
      return tickets;
    } catch (e) {
      debugPrint('❌ DEBUG: getAllTickets hatası: $e');
      rethrow;
    }
  }

  @override
  Stream<List<Ticket>> getTicketsByCategory(TicketCategory category) {
    return _ticketsCollection
        .where('category', isEqualTo: category.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Ticket.fromFirestore(doc)).toList(),
        );
  }

  @override
  Stream<List<Ticket>> getTicketsByUser(String userId) {
    return _ticketsCollection
        .where('sellerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Ticket.fromFirestore(doc)).toList(),
        );
  }

  // GetTicketsBySeller method for FutureProvider
  Future<List<Ticket>> getTicketsBySeller(String userId) async {
    try {
      debugPrint('🔍 DEBUG: getTicketsBySeller çağrıldı - userId: $userId');
      
      final snapshot = await _ticketsCollection
          .where('sellerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      debugPrint('📊 DEBUG: ${snapshot.docs.length} bilet bulundu (sellerId: $userId)');
      
      return snapshot.docs.map((doc) => Ticket.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('❌ DEBUG: getTicketsBySeller hatası: $e');
      rethrow;
    }
  }

  @override
  Future<Ticket?> getTicketById(String ticketId) async {
    try {
      final doc = await _ticketsCollection.doc(ticketId).get();
      if (doc.exists) {
        return Ticket.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Bilet bulunamadı: $e');
    }
  }

  @override
  Future<String> addTicket(Ticket ticket) async {
    try {
      final data = ticket.toFirestore();
      data['createdAt'] = FieldValue.serverTimestamp();

      final docRef = await _ticketsCollection.add(data);

      // Firestore serverTimestamp alanlarının geri dönüşte hemen okunabilmesi için dokümanı yeniden fetch et
      // Böylece orderBy(createdAt) gibi sorgularda yeni bilet listenin en üstünde görünür
      await docRef.update({'createdAt': FieldValue.serverTimestamp()});
      return docRef.id;
    } catch (e) {
      throw Exception('Bilet eklenirken hata oluştu: $e');
    }
  }

  // CreateTicket method for TicketFormNotifier
  Future<void> createTicket(Ticket ticket) async {
    try {
      await _ticketsCollection.doc(ticket.id).set(ticket.toFirestore());
    } catch (e) {
      throw Exception('Bilet oluşturulurken hata oluştu: $e');
    }
  }

  @override
  Future<void> updateTicket(Ticket ticket) async {
    try {
      await _ticketsCollection.doc(ticket.id).update(ticket.toFirestore());
    } catch (e) {
      throw Exception('Bilet güncellenirken hata oluştu: $e');
    }
  }

  @override
  Future<void> deleteTicket(String ticketId) async {
    try {
      // Delete the ticket document
      await _ticketsCollection.doc(ticketId).delete();
      
      // Clean up related data
      await _cleanupRelatedData(ticketId);
    } catch (e) {
      throw Exception('Bilet silinirken hata oluştu: $e');
    }
  }

  /// Clean up data related to a deleted ticket
  Future<void> _cleanupRelatedData(String ticketId) async {
    try {
      // Clean up likes for this ticket
      final likesQuery = await _firestore
          .collection('likes')
          .where('ticketId', isEqualTo: ticketId)
          .get();
      
      final batch = _firestore.batch();
      for (final likeDoc in likesQuery.docs) {
        batch.delete(likeDoc.reference);
      }
      
      // Clean up favorites for this ticket
      final favoritesQuery = await _firestore
          .collection('favorites')
          .where('ticketId', isEqualTo: ticketId)
          .get();
      
      for (final favoriteDoc in favoritesQuery.docs) {
        batch.delete(favoriteDoc.reference);
      }
      
      // Clean up conversations related to this ticket
      final conversationsQuery = await _firestore
          .collection('conversations')
          .where('ticketId', isEqualTo: ticketId)
          .get();
      
      for (final conversationDoc in conversationsQuery.docs) {
        // Mark conversation as closed due to ticket deletion
        batch.update(conversationDoc.reference, {
          'status': 'closed',
          'closedReason': 'ticket_deleted',
          'closedAt': FieldValue.serverTimestamp(),
        });
      }
      
      // Clean up orders related to this ticket
      final ordersQuery = await _firestore
          .collection('orders')
          .where('ticketId', isEqualTo: ticketId)
          .get();
      
      for (final orderDoc in ordersQuery.docs) {
        // Mark order as cancelled due to ticket deletion
        batch.update(orderDoc.reference, {
          'status': 'cancelled',
          'cancelledReason': 'ticket_deleted',
          'cancelledAt': FieldValue.serverTimestamp(),
        });
      }
      
      // Clean up notifications related to this ticket
      final notificationsQuery = await _firestore
          .collection('notifications')
          .where('ticketId', isEqualTo: ticketId)
          .get();
      
      for (final notificationDoc in notificationsQuery.docs) {
        batch.delete(notificationDoc.reference);
      }
      
      // Commit all cleanup operations
      await batch.commit();
      
      debugPrint('✅ Cleaned up related data for ticket: $ticketId');
    } catch (e) {
      debugPrint('⚠️ Error cleaning up related data for ticket $ticketId: $e');
      // Don't throw here as the main ticket deletion was successful
    }
  }

  @override
  Future<void> purchaseTicket(String ticketId, String buyerId) async {
    try {
      await _ticketsCollection.doc(ticketId).update({
        'status': TicketStatus.sold.name,
        'buyerId': buyerId,
        'soldDate': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Bilet satın alınırken hata oluştu: $e');
    }
  }

  @override
  Future<List<Ticket>> searchTickets(String query) async {
    try {
      final queryLower = query.toLowerCase();

      // Başlık ve açıklama alanlarında arama
      final titleQuery = await _ticketsCollection
          .where('status', isEqualTo: 'available')
          .get();

      final results = titleQuery.docs
          .map((doc) => Ticket.fromFirestore(doc))
          .where(
            (ticket) =>
                ticket.title.toLowerCase().contains(queryLower) ||
                ticket.description.toLowerCase().contains(queryLower) ||
                ticket.venue.toLowerCase().contains(queryLower) ||
                ticket.city.toLowerCase().contains(queryLower),
          )
          .toList();

      return results;
    } catch (e) {
      throw Exception('Arama yapılırken hata oluştu: $e');
    }
  }

  @override
  Future<List<Ticket>> getFilteredTickets({
    TicketCategory? category,
    String? city,
    double? minPrice,
    double? maxPrice,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _ticketsCollection;

      if (category != null) {
        query = query.where('category', isEqualTo: category.name);
      }

      if (city != null && city.isNotEmpty) {
        query = query.where('city', isEqualTo: city);
      }

      if (minPrice != null) {
        query = query.where('sellingPrice', isGreaterThanOrEqualTo: minPrice);
      }

      if (maxPrice != null) {
        query = query.where('sellingPrice', isLessThanOrEqualTo: maxPrice);
      }

      if (startDate != null) {
        query = query.where(
          'eventDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }

      if (endDate != null) {
        query = query.where(
          'eventDate',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => Ticket.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Filtreleme yapılırken hata oluştu: $e');
    }
  }
}
