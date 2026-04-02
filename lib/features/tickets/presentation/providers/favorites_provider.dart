// lib/features/tickets/presentation/providers/favorites_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/ticket.dart';

part 'favorites_provider.g.dart';

/// Favori biletleri yöneten provider
@riverpod
class FavoritesNotifier extends _$FavoritesNotifier {
  @override
  Future<Set<String>> build() async {
    // Kullanıcının favori bilet ID'lerini getir
    final user = ref.watch(authStateChangesProvider).value;
    if (user == null) return {};
    
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final favoritesList = data['favorites'] as List<dynamic>? ?? [];
        return Set<String>.from(favoritesList);
      }
      
      return {};
    } catch (e) {
      // Hata durumunda boş set döndür
      return {};
    }
  }

  /// Bilet'i favorilere ekle/çıkar
  Future<void> toggleFavorite(String ticketId) async {
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return;

    final currentFavorites = await future;
    final newFavorites = Set<String>.from(currentFavorites);
    
    if (newFavorites.contains(ticketId)) {
      newFavorites.remove(ticketId);
    } else {
      newFavorites.add(ticketId);
    }
    
    // State'i güncelle
    state = AsyncValue.data(newFavorites);
    
    // Firebase'e kaydet
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'favorites': newFavorites.toList(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Hata durumunda state'i geri çevir
      state = AsyncValue.data(currentFavorites);
      rethrow;
    }
  }

  /// Bilet favori mi kontrol et
  bool isFavorite(String ticketId) {
    return state.value?.contains(ticketId) ?? false;
  }
}

/// Favorite Tickets Provider - Retrieves user's favorite tickets
/// Fetches the complete ticket details for all tickets marked as favorites by the current user
/// This provider combines the user's favorite ticket IDs with the actual ticket data from Firestore
/// @param ref: Riverpod reference for dependency injection to access favorites and Firestore
/// @returns: List of complete Ticket objects that the user has marked as favorites
@riverpod
Future<List<Ticket>> favoriteTickets(Ref ref) async {
  final favorites = await ref.watch(favoritesNotifierProvider.future);
  if (favorites.isEmpty) return [];
  
  try {
    // Favori ticket ID'leriyle biletleri Firebase'den getir
    final ticketDocs = await Future.wait(
      favorites.map((ticketId) =>
          FirebaseFirestore.instance.collection('tickets').doc(ticketId).get()),
    );
    
    final tickets = ticketDocs
        .where((doc) => doc.exists)
        .map((doc) => Ticket.fromFirestore(doc))
        .toList();
    
    return tickets;
  } catch (e) {
    // Hata durumunda boş liste döndür
    return [];
  }
}


