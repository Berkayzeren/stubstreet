// lib/core/services/authorization_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/tickets/domain/entities/ticket.dart';
import '../../features/orders/domain/entities/order.dart' as order_entity;
import '../../features/conversations/domain/entities/conversation.dart';

/// Service for handling authorization and access control
class AuthorizationService {
  final FirebaseFirestore _firestore;

  AuthorizationService(this._firestore);

  /// Check if user can modify a ticket
  bool canModifyTicket(User user, Ticket ticket) {
    // Only seller can modify their own tickets
    return user.id == ticket.sellerId;
  }

  /// Check if user can view a ticket
  bool canViewTicket(User user, Ticket ticket) {
    // All authenticated users can view tickets
    return true;
  }

  /// Check if user can purchase a ticket
  bool canPurchaseTicket(User user, Ticket ticket) {
    // User cannot buy their own ticket
    if (user.id == ticket.sellerId) {
      return false;
    }

    // Ticket must be available
    return ticket.status == TicketStatus.available ||
        (ticket.status == TicketStatus.reserved && ticket.buyerId == user.id);
  }

  /// Check if user can access an order
  bool canAccessOrder(User user, order_entity.Order order) {
    // Only buyer or seller can access the order
    return user.id == order.buyerId || user.id == order.sellerId;
  }

  /// Check if user can cancel an order
  bool canCancelOrder(User user, order_entity.Order order) {
    // Buyer can cancel pending orders
    // Seller can cancel pending/confirmed orders
    if (user.id == order.buyerId &&
        order.status == order_entity.OrderStatus.pending) {
      return true;
    }

    if (user.id == order.sellerId && order.canBeCancelled) {
      return true;
    }

    return false;
  }

  /// Check if user can initiate a refund
  bool canInitiateRefund(User user, order_entity.Order order) {
    // Only buyer can initiate refunds for confirmed/delivered orders
    return user.id == order.buyerId &&
        (order.status == order_entity.OrderStatus.confirmed ||
            order.status == order_entity.OrderStatus.delivered);
  }

  /// Check if user can process a refund
  bool canProcessRefund(User user, order_entity.Order order) {
    // Only seller can process refunds for confirmed/delivered orders
    return user.id == order.sellerId &&
        (order.status == order_entity.OrderStatus.confirmed ||
            order.status == order_entity.OrderStatus.delivered);
  }

  /// Check if user can access a conversation
  bool canAccessConversation(User user, Conversation conversation) {
    // Only participants can access the conversation
    return user.id == conversation.buyerId || user.id == conversation.sellerId;
  }

  /// Check if user can send messages in a conversation
  bool canSendMessage(User user, Conversation conversation) {
    // Only participants can send messages
    return canAccessConversation(user, conversation) &&
        conversation.status == ConversationStatus.active;
  }

  /// Check if user can read messages in a conversation
  bool canReadMessages(User user, Conversation conversation) {
    // Only participants can read messages
    return canAccessConversation(user, conversation);
  }

  /// Check if user can update delivery status
  bool canUpdateDeliveryStatus(User user, order_entity.Order order) {
    // Only seller can update delivery status
    return user.id == order.sellerId &&
        (order.status == order_entity.OrderStatus.confirmed ||
            order.status == order_entity.OrderStatus.processing ||
            order.status == order_entity.OrderStatus.shipped);
  }

  /// Check if user is admin
  bool isAdmin(User user) {
    return user.role == UserRole.admin;
  }

  /// Check if user can handle disputes (admin only)
  bool canHandleDisputes(User user) {
    return isAdmin(user);
  }

  /// Check if user can access admin features
  bool canAccessAdminFeatures(User user) {
    return isAdmin(user);
  }

  /// Check if user can view financial reports
  bool canViewFinancialReports(User user) {
    return isAdmin(user);
  }

  /// Get user role-based permissions
  UserPermissions getUserPermissions(User user) {
    // Authorization policy update:
    // In this application, every authenticated user is allowed to act as both a buyer and a seller.
    // Rationale:
    // - Product requirement states all users should be able to create (sell) and purchase (buy) tickets.
    // - We therefore decouple selling/buying capabilities from the single `role` enum and grant both.
    // - Admin-only capabilities remain protected by explicit admin checks.
    // Why not remove the role entirely?
    // - We keep role for admin/operational controls and legacy UI display, but business permissions below
    //   intentionally allow both buyer and seller actions to all authenticated users.
    return UserPermissions(
      // All authenticated users can create tickets (sell)
      canCreateTickets: true,
      // All authenticated users can purchase tickets (buy)
      canPurchaseTickets: true,
      // Admin-only features remain gated by admin role
      canAccessAdminPanel: user.role == UserRole.admin,
      canHandleDisputes: user.role == UserRole.admin,
      canViewAllOrders: user.role == UserRole.admin,
      canViewFinancialReports: user.role == UserRole.admin,
      canModerateConversations: user.role == UserRole.admin,
    );
  }

  /// Validate business rules for ticket creation
  Future<ValidationResult> validateTicketCreation(
    User user,
    Ticket ticket,
  ) async {
    final errors = <String>[];

    // Check user permissions
    if (!getUserPermissions(user).canCreateTickets) {
      errors.add('User does not have permission to create tickets');
    }

    // Check if user is trying to create ticket for themselves
    if (user.id != ticket.sellerId) {
      errors.add('User can only create tickets for themselves');
    }

    // Validate ticket data
    if (ticket.sellingPrice <= 0) {
      errors.add('Selling price must be greater than 0');
    }

    if (ticket.eventDate.isBefore(DateTime.now())) {
      errors.add('Event date must be in the future');
    }

    // Check for spam/duplicate tickets
    final recentTickets = await _firestore
        .collection('tickets')
        .where('sellerId', isEqualTo: user.id)
        .where('title', isEqualTo: ticket.title)
        .where('eventDate', isEqualTo: Timestamp.fromDate(ticket.eventDate))
        .get();

    if (recentTickets.docs.isNotEmpty) {
      errors.add('Similar ticket already exists');
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Validate business rules for order creation
  ValidationResult validateOrderCreation(
    User buyer,
    User seller,
    Ticket ticket,
    double amount,
  ) {
    final errors = <String>[];

    // Check user permissions
    if (!getUserPermissions(buyer).canPurchaseTickets) {
      errors.add('Buyer does not have permission to purchase tickets');
    }

    // Check if buyer is trying to buy their own ticket
    if (buyer.id == seller.id) {
      errors.add('Cannot purchase your own ticket');
    }

    // Check ticket availability
    if (ticket.status != TicketStatus.available &&
        !(ticket.status == TicketStatus.reserved &&
            ticket.buyerId == buyer.id)) {
      errors.add('Ticket is not available for purchase');
    }

    // Validate amount
    if (amount != ticket.sellingPrice) {
      errors.add('Payment amount does not match ticket price');
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }
}

/// User permissions based on role
class UserPermissions {
  final bool canCreateTickets;
  final bool canPurchaseTickets;
  final bool canAccessAdminPanel;
  final bool canHandleDisputes;
  final bool canViewAllOrders;
  final bool canViewFinancialReports;
  final bool canModerateConversations;

  const UserPermissions({
    required this.canCreateTickets,
    required this.canPurchaseTickets,
    required this.canAccessAdminPanel,
    required this.canHandleDisputes,
    required this.canViewAllOrders,
    required this.canViewFinancialReports,
    required this.canModerateConversations,
  });
}

/// Validation result for business rule checks
class ValidationResult {
  final bool isValid;
  final List<String> errors;

  const ValidationResult({required this.isValid, required this.errors});
}
