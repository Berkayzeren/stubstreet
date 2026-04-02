// lib/features/tickets/data/services/ticket_lock_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/ticket.dart';

/// Service for managing ticket locks during checkout process
class TicketLockService {
  final FirebaseFirestore _firestore;

  TicketLockService(this._firestore);

  CollectionReference get _ticketsCollection =>
      _firestore.collection('tickets');

  /// Lock timeout duration (15 minutes)
  static const Duration lockTimeout = Duration(minutes: 15);

  /// Attempts to lock a ticket for purchase
  /// Returns true if lock was successful, false if ticket is already locked/sold
  Future<bool> lockTicket(String ticketId, String buyerId) async {
    try {
      return await _firestore.runTransaction<bool>((transaction) async {
        final ticketDoc = _ticketsCollection.doc(ticketId);
        final ticketSnapshot = await transaction.get(ticketDoc);

        if (!ticketSnapshot.exists) {
          throw Exception('Ticket not found');
        }

        final ticket = Ticket.fromFirestore(ticketSnapshot);
        final now = DateTime.now();

        // Check if ticket is available and not already locked
        if (ticket.status != TicketStatus.available) {
          return false; // Already sold or reserved
        }

        // Check if ticket is already locked by someone else
        if (ticket.lockUntil != null &&
            ticket.lockUntil!.isAfter(now) &&
            ticket.buyerId != buyerId) {
          return false; // Already locked by another user
        }

        // Lock the ticket
        final lockUntil = now.add(lockTimeout);
        transaction.update(ticketDoc, {
          'status': TicketStatus.reserved.name,
          'buyerId': buyerId,
          'lockUntil': Timestamp.fromDate(lockUntil),
        });

        return true;
      });
    } catch (e) {
      throw Exception('Failed to lock ticket: $e');
    }
  }

  /// Releases a lock on a ticket
  Future<void> releaseLock(String ticketId, String buyerId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final ticketDoc = _ticketsCollection.doc(ticketId);
        final ticketSnapshot = await transaction.get(ticketDoc);

        if (!ticketSnapshot.exists) {
          throw Exception('Ticket not found');
        }

        final ticket = Ticket.fromFirestore(ticketSnapshot);

        // Only release lock if this user has the lock
        if (ticket.buyerId == buyerId &&
            ticket.status == TicketStatus.reserved) {
          transaction.update(ticketDoc, {
            'status': TicketStatus.available.name,
            'buyerId': FieldValue.delete(),
            'lockUntil': FieldValue.delete(),
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to release lock: $e');
    }
  }

  /// Extends a lock on a ticket (if user owns the lock)
  Future<bool> extendLock(String ticketId, String buyerId) async {
    try {
      return await _firestore.runTransaction<bool>((transaction) async {
        final ticketDoc = _ticketsCollection.doc(ticketId);
        final ticketSnapshot = await transaction.get(ticketDoc);

        if (!ticketSnapshot.exists) {
          return false;
        }

        final ticket = Ticket.fromFirestore(ticketSnapshot);

        // Check if this user owns the lock
        if (ticket.buyerId != buyerId ||
            ticket.status != TicketStatus.reserved) {
          return false;
        }

        // Extend the lock
        final newLockUntil = DateTime.now().add(lockTimeout);
        transaction.update(ticketDoc, {
          'lockUntil': Timestamp.fromDate(newLockUntil),
        });

        return true;
      });
    } catch (e) {
      throw Exception('Failed to extend lock: $e');
    }
  }

  /// Check if a ticket is locked and by whom
  Future<TicketLockStatus> checkLockStatus(String ticketId) async {
    try {
      final ticketDoc = await _ticketsCollection.doc(ticketId).get();

      if (!ticketDoc.exists) {
        throw Exception('Ticket not found');
      }

      final ticket = Ticket.fromFirestore(ticketDoc);
      final now = DateTime.now();

      if (ticket.status == TicketStatus.sold) {
        return TicketLockStatus.sold;
      }

      if (ticket.status == TicketStatus.reserved &&
          ticket.lockUntil != null &&
          ticket.lockUntil!.isAfter(now)) {
        return TicketLockStatus.locked(ticket.buyerId!, ticket.lockUntil!);
      }

      // If lock has expired, clean it up
      if (ticket.status == TicketStatus.reserved &&
          ticket.lockUntil != null &&
          ticket.lockUntil!.isBefore(now)) {
        await _cleanupExpiredLock(ticketId);
        return TicketLockStatus.available;
      }

      return TicketLockStatus.available;
    } catch (e) {
      throw Exception('Failed to check lock status: $e');
    }
  }

  /// Cleans up expired locks
  Future<void> _cleanupExpiredLock(String ticketId) async {
    try {
      await _ticketsCollection.doc(ticketId).update({
        'status': TicketStatus.available.name,
        'buyerId': FieldValue.delete(),
        'lockUntil': FieldValue.delete(),
      });
    } catch (e) {
      // Ignore cleanup errors
    }
  }

  /// Periodic cleanup of expired locks (call this from a background service)
  Future<void> cleanupExpiredLocks() async {
    try {
      final now = DateTime.now();
      final expiredLocksQuery = await _ticketsCollection
          .where('status', isEqualTo: TicketStatus.reserved.name)
          .where('lockUntil', isLessThan: Timestamp.fromDate(now))
          .get();

      final batch = _firestore.batch();

      for (final doc in expiredLocksQuery.docs) {
        batch.update(doc.reference, {
          'status': TicketStatus.available.name,
          'buyerId': FieldValue.delete(),
          'lockUntil': FieldValue.delete(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to cleanup expired locks: $e');
    }
  }
}

/// Represents the lock status of a ticket
sealed class TicketLockStatus {
  const TicketLockStatus();

  static const TicketLockStatus available = _Available();
  static const TicketLockStatus sold = _Sold();
  static TicketLockStatus locked(String buyerId, DateTime until) =>
      _Locked(buyerId, until);
}

class _Available extends TicketLockStatus {
  const _Available();
}

class _Sold extends TicketLockStatus {
  const _Sold();
}

class _Locked extends TicketLockStatus {
  final String buyerId;
  final DateTime until;

  const _Locked(this.buyerId, this.until);

  bool get isExpired => DateTime.now().isAfter(until);
  Duration get remainingTime => until.difference(DateTime.now());
}
