// lib/features/tickets/domain/repositories/ticket_repository.dart

import '../entities/ticket.dart';

abstract class TicketRepository {
  // Tüm biletleri getir
  Stream<List<Ticket>> getTickets();

  // Kategoriye göre biletleri getir
  Stream<List<Ticket>> getTicketsByCategory(TicketCategory category);

  // Kullanıcının biletlerini getir
  Stream<List<Ticket>> getTicketsByUser(String userId);

  // Bilet detayını getir
  Future<Ticket?> getTicketById(String ticketId);

  // Bilet ekle
  Future<String> addTicket(Ticket ticket);

  // Bilet güncelle
  Future<void> updateTicket(Ticket ticket);

  // Bilet sil
  Future<void> deleteTicket(String ticketId);

  // Bilet satın al
  Future<void> purchaseTicket(String ticketId, String buyerId);

  // Bilet ara
  Future<List<Ticket>> searchTickets(String query);

  // Filtrelenmiş biletleri getir
  Future<List<Ticket>> getFilteredTickets({
    TicketCategory? category,
    String? city,
    double? minPrice,
    double? maxPrice,
    DateTime? startDate,
    DateTime? endDate,
  });
}
