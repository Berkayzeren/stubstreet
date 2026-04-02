// lib/features/tickets/presentation/providers/ticket_providers.dart

import 'package:flutter/foundation.dart';  // For debugPrint function and Uint8List
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_storage/firebase_storage.dart';
import '../../domain/entities/ticket.dart';
import '../../data/repositories/ticket_repository_impl.dart';
import '../../data/services/like_service.dart';
import '../../../orders/data/repositories/order_repository_impl.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

// Repository provider
final ticketRepositoryProvider = Provider<TicketRepositoryImpl>((ref) {
  return TicketRepositoryImpl(FirebaseFirestore.instance);
});

// Like service provider
final likeServiceProvider = Provider<LikeService>((ref) {
  return LikeService();
});

final orderRepositoryProvider = Provider<OrderRepositoryImpl>((ref) {
  return OrderRepositoryImpl(FirebaseFirestore.instance);
});

// All tickets provider - Real-time stream for automatic updates
final ticketsProvider = StreamProvider<List<Ticket>>((ref) {
  final repository = ref.watch(ticketRepositoryProvider);
  return repository.getTickets();
});

// Tickets by category provider
final ticketsByCategoryProvider = FutureProvider.family<List<Ticket>, TicketCategory>((ref, category) async {
  final repository = ref.watch(ticketRepositoryProvider);
  // Use the existing method from repository
  final tickets = await repository.getAllTickets();
  return tickets.where((ticket) => ticket.category == category).toList();
});

// User tickets provider
final userTicketsProvider = FutureProvider.family<List<Ticket>, String>((ref, userId) async {
  final repository = ref.watch(ticketRepositoryProvider);
  return repository.getTicketsBySeller(userId);
});

// Ticket detail provider
final ticketDetailProvider = FutureProvider.family<Ticket, String>((ref, ticketId) async {
  final repository = ref.watch(ticketRepositoryProvider);
  final ticket = await repository.getTicketById(ticketId);
  if (ticket == null) {
    throw Exception('Ticket not found');
  }
  return ticket;
});

// Search results provider
final searchResultsProvider = StateNotifierProvider<SearchNotifier, List<Ticket>>((ref) {
  return SearchNotifier(ref);
});

class SearchNotifier extends StateNotifier<List<Ticket>> {
  final Ref ref;
  
  SearchNotifier(this.ref) : super([]);

  /// Arama işlevi: Repository üzerinden basit metin araması yapar
  /// @param query String - Kullanıcının arama metni
  /// @returns `Future<void>` - State güncellenir; UI otomatik rebuild olur
  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = [];
      return;
    }

    // Provider üzerinden repository'yi al - daha tutarlı ve test edilebilir
    final repository = ref.read(ticketRepositoryProvider);
    final results = await repository.searchTickets(trimmed);
    state = results;
  }

  void clearResults() {
    state = [];
  }
}

// Like count provider
final likeCountProvider = StreamProvider.family<int, String>((ref, ticketId) {
  final service = ref.watch(likeServiceProvider);
  return service.watchLikeCount(ticketId);
});

// Is liked by user provider - with better caching
final isLikedByUserProvider = StreamProvider.family<bool, String>((ref, ticketId) {
  final user = ref.watch(authStateChangesProvider).value;
  final service = ref.watch(likeServiceProvider);
  if (user == null) {
    return Stream<bool>.value(false);
  }
  return service.watchIsLikedByUser(ticketId, user.uid);
});

// Like toggle provider
final likeToggleProvider = StateNotifierProvider<LikeToggleNotifier, AsyncValue<void>>((ref) {
  return LikeToggleNotifier(ref);
});

class LikeToggleNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  
  LikeToggleNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> toggleLike(String ticketId, String userId) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(likeServiceProvider);
      final isCurrentlyLiked = await service.isLikedByUser(ticketId, userId);
      
      // Update cache immediately for better UX
      ref.read(likeStateCacheProvider.notifier).setLikeState(ticketId, !isCurrentlyLiked);
      
      await service.toggleLike(ticketId, userId);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      // Revert cache on error
      final service = ref.read(likeServiceProvider);
      final isCurrentlyLiked = await service.isLikedByUser(ticketId, userId);
      ref.read(likeStateCacheProvider.notifier).setLikeState(ticketId, isCurrentlyLiked);
      
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

// User liked tickets provider
final userLikedTicketsProvider = FutureProvider.family<List<String>, String>((ref, userId) async {
  final service = ref.watch(likeServiceProvider);
  return service.getUserLikedTickets(userId);
});

final userPurchasedOrdersProvider = FutureProvider.family<List<Order>, String>((ref, userId) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getUserOrders(userId);
});

// Ticket likes count provider (for TicketCard)
final ticketLikesCountProvider = StreamProvider.family<int, String>((ref, ticketId) {
  final service = ref.watch(likeServiceProvider);
  return service.watchLikeCount(ticketId);
});

// Is liked by user for card provider - with better caching
final isLikedByUserForCardProvider = StreamProvider.family<bool, String>((ref, ticketId) {
  final user = ref.watch(authStateChangesProvider).value;
  final service = ref.watch(likeServiceProvider);
  if (user == null) {
    return Stream<bool>.value(false);
  }
  return service.watchIsLikedByUser(ticketId, user.uid);
});

// Like state cache provider - maintains like state across page changes
final likeStateCacheProvider = StateNotifierProvider<LikeStateCacheNotifier, Map<String, bool>>((ref) {
  return LikeStateCacheNotifier();
});

class LikeStateCacheNotifier extends StateNotifier<Map<String, bool>> {
  LikeStateCacheNotifier() : super({});

  void setLikeState(String ticketId, bool isLiked) {
    state = {...state, ticketId: isLiked};
  }

  bool getLikeState(String ticketId) {
    return state[ticketId] ?? false;
  }

  void clearCache() {
    state = {};
  }
}

// Generic like state cache for arbitrary content (events, etc.)
final genericLikeStateCacheProvider = StateNotifierProvider<GenericLikeStateCacheNotifier, Map<String, bool>>((ref) {
  return GenericLikeStateCacheNotifier();
});

class GenericLikeStateCacheNotifier extends StateNotifier<Map<String, bool>> {
  GenericLikeStateCacheNotifier() : super({});

  void setLikeState(String contentId, bool isLiked) {
    state = {...state, contentId: isLiked};
  }

  bool getLikeState(String contentId) {
    return state[contentId] ?? false;
  }

  void clearCache() {
    state = {};
  }
}

// Ticket form provider
final ticketFormProvider = StateNotifierProvider<TicketFormNotifier, AsyncValue<void>>((ref) {
  return TicketFormNotifier(ref);
});

class TicketFormNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  
  TicketFormNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> addTicket(Ticket ticket) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(ticketRepositoryProvider);
      // Firestore'da boş ID ile .doc('') kullanmak hataya yol açar.
      // Bu nedenle .add() kullanan repository.addTicket() ile otomatik ID üretilmesini sağlıyoruz.
      // Böylece bilet belgesi güvenli şekilde oluşturulur ve geri dönen ID istersek ekranda kullanılabilir.
      await repository.addTicket(ticket);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateTicket(Ticket ticket) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(ticketRepositoryProvider);
      await repository.updateTicket(ticket);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> deleteTicket(String ticketId) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(ticketRepositoryProvider);
      await repository.deleteTicket(ticketId);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Firebase Storage'a resim upload eder
  Future<String?> uploadImage(Uint8List imageBytes, String uploadPath) async {
    try {
      // Firebase Storage referansı
      final storageRef = FirebaseStorage.instance.ref().child(uploadPath);
      
      // Metadata ekle (isteğe bağlı)
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': 'ticket_form',
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );
      
      // Upload işlemi
      final uploadTask = storageRef.putData(imageBytes, metadata);
      
      // Upload tamamlanmasını bekle
      final snapshot = await uploadTask;
      
      // Download URL'ini al
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      // Hata durumunda null döndür
      // Using debugPrint instead of print to avoid noisy logs in release and for better throttling
      debugPrint('Firebase Storage upload error: $e');
      return null;
    }
  }
}