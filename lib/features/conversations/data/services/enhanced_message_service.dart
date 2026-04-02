// lib/features/conversations/data/services/enhanced_message_service.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/message.dart';

/// Enhanced message service providing comprehensive chat functionality
/// 
/// This service implements all advanced chat features including:
/// - Message editing with history tracking
/// - Message deletion (both soft and hard delete)
/// - Reply-to-message functionality
/// - File and image attachments
/// - Message reactions
/// - Read receipts and delivery status
/// - Bulk operations for conversation management
class EnhancedMessageService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  // Firestore collection references
  late final CollectionReference _messagesRef;
  late final CollectionReference _conversationsRef;
  late final CollectionReference _attachmentsRef;
  late final CollectionReference _reactionsRef;
  late final CollectionReference _readReceiptsRef;

  EnhancedMessageService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance {
    // Initialize collection references
    _messagesRef = _firestore.collection('messages');
    _conversationsRef = _firestore.collection('conversations');
    _attachmentsRef = _firestore.collection('attachments');
    _reactionsRef = _firestore.collection('reactions');
    _readReceiptsRef = _firestore.collection('readReceipts');
  }

  /// Get current authenticated user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Edit an existing message
  /// 
  /// @param messageId - ID of the message to edit
  /// @param newContent - New message content
  /// @param preserveHistory - Whether to keep edit history (default: true)
  /// 
  /// @returns Updated message object
  /// @throws Exception if user doesn't have permission or message not found
  Future<Message> editMessage({
    required String messageId,
    required String newContent,
    bool preserveHistory = true,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Validate input
    if (newContent.trim().isEmpty) {
      throw Exception('Message content cannot be empty');
    }

    if (newContent.length > 5000) {
      throw Exception('Message too long (max 5000 characters)');
    }

    try {
      // Get the original message
      final messageDoc = await _messagesRef.doc(messageId).get();
      
      if (!messageDoc.exists) {
        throw Exception('Message not found');
      }

      final originalMessage = Message.fromFirestore(messageDoc);
      
      // Check if user has permission to edit (only sender can edit)
      if (originalMessage.senderId != userId) {
        throw Exception('You can only edit your own messages');
      }

      // Check if message is too old to edit (24 hours limit)
      final hoursSinceCreated = DateTime.now().difference(originalMessage.createdAt).inHours;
      if (hoursSinceCreated > 24) {
        throw Exception('Messages older than 24 hours cannot be edited');
      }

      // Prepare update data
      final updateData = <String, dynamic>{
        'content': newContent.trim(),
        'isEdited': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Preserve edit history if requested
      if (preserveHistory) {
        updateData['editHistory'] = FieldValue.arrayUnion([{
          'previousContent': originalMessage.content,
          'editedAt': FieldValue.serverTimestamp(),
          'editedBy': userId,
        }]);
      }

      // Update the message
      await _messagesRef.doc(messageId).update(updateData);

      // Get the updated message
      final updatedDoc = await _messagesRef.doc(messageId).get();
      final updatedMessage = Message.fromFirestore(updatedDoc);

      debugPrint('✅ Message edited successfully: $messageId');
      return updatedMessage;

    } catch (e) {
      debugPrint('❌ Failed to edit message: $e');
      rethrow;
    }
  }

  /// Delete a message (soft delete by default)
  /// 
  /// @param messageId - ID of the message to delete
  /// @param hardDelete - If true, permanently removes the message (default: false)
  /// 
  /// @throws Exception if user doesn't have permission or message not found
  Future<void> deleteMessage({
    required String messageId,
    bool hardDelete = false,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get the message to check permissions
      final messageDoc = await _messagesRef.doc(messageId).get();
      
      if (!messageDoc.exists) {
        throw Exception('Message not found');
      }

      final message = Message.fromFirestore(messageDoc);
      
      // Check if user has permission to delete
      if (message.senderId != userId) {
        throw Exception('You can only delete your own messages');
      }

      if (hardDelete) {
        // Permanently delete the message and its associated data
        final batch = _firestore.batch();
        
        // Delete the message
        batch.delete(_messagesRef.doc(messageId));
        
        // Delete associated reactions
        final reactionsSnapshot = await _reactionsRef
            .where('messageId', isEqualTo: messageId)
            .get();
        for (final doc in reactionsSnapshot.docs) {
          batch.delete(doc.reference);
        }
        
        // Delete associated read receipts
        final readReceiptsSnapshot = await _readReceiptsRef
            .where('messageId', isEqualTo: messageId)
            .get();
        for (final doc in readReceiptsSnapshot.docs) {
          batch.delete(doc.reference);
        }
        
        // Delete attachments from storage
        for (final attachmentUrl in message.attachments) {
          try {
            await _storage.refFromURL(attachmentUrl).delete();
          } catch (e) {
            // Continue if attachment deletion fails
            debugPrint('⚠️ Failed to delete attachment: $attachmentUrl');
          }
        }
        
        await batch.commit();
        debugPrint('✅ Message permanently deleted: $messageId');
        
      } else {
        // Soft delete - mark as deleted but keep in database
        await _messagesRef.doc(messageId).update({
          'isDeleted': true,
          'deletedAt': FieldValue.serverTimestamp(),
          'deletedBy': userId,
          'content': '🗑️ This message was deleted', // Placeholder content
        });
        
        debugPrint('✅ Message soft deleted: $messageId');
      }

    } catch (e) {
      debugPrint('❌ Failed to delete message: $e');
      rethrow;
    }
  }

  /// Delete a message only for the current user (per-user hide)
  /// 
  /// This does not remove or alter the message content for other participants.
  /// It appends the current user's ID to the 'deletedFor' array field of the message
  /// so that client UIs can filter it out for this user.
  Future<void> deleteForCurrentUser({
    required String messageId,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Ensure message exists (optional safety check)
      final messageDoc = await _messagesRef.doc(messageId).get();
      if (!messageDoc.exists) {
        throw Exception('Message not found');
      }

      await _messagesRef.doc(messageId).update({
        'deletedFor': FieldValue.arrayUnion([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Message hidden for user: $messageId -> $userId');
    } catch (e) {
      debugPrint('❌ Failed to hide message for user: $e');
      rethrow;
    }
  }

  /// Send a reply to an existing message
  /// 
  /// @param originalMessageId - ID of the message being replied to
  /// @param replyContent - Content of the reply
  /// @param conversationId - ID of the conversation
  /// @param receiverId - ID of the receiver
  /// @param type - Type of the reply message
  /// 
  /// @returns The newly created reply message
  /// @throws Exception if original message not found or user not authenticated
  Future<Message> replyToMessage({
    required String originalMessageId,
    required String replyContent,
    required String conversationId,
    required String receiverId,
    MessageType type = MessageType.text,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Validate input
    if (replyContent.trim().isEmpty) {
      throw Exception('Reply content cannot be empty');
    }

    try {
      // Verify the original message exists
      final originalMessageDoc = await _messagesRef.doc(originalMessageId).get();
      if (!originalMessageDoc.exists) {
        throw Exception('Original message not found');
      }

      final originalMessage = Message.fromFirestore(originalMessageDoc);

      // Create the reply message
      final replyMessage = Message(
        id: '', // Firestore will generate
        conversationId: conversationId,
        senderId: userId,
        senderName: _auth.currentUser?.displayName ?? 'Unknown User',
        receiverId: receiverId,
        receiverName: originalMessage.senderName, // Reply to original sender
        type: type,
        status: MessageStatus.sent,
        content: replyContent.trim(),
        attachments: [],
        createdAt: DateTime.now(),
        replyToMessageId: originalMessageId,
        metadata: {
          'originalMessage': {
            'id': originalMessage.id,
            'content': originalMessage.content.length > 100 
                ? '${originalMessage.content.substring(0, 100)}...'
                : originalMessage.content,
            'senderName': originalMessage.senderName,
            'type': originalMessage.type.name,
          },
        },
      );

      // Save the reply to Firestore
      final docRef = await _messagesRef.add(replyMessage.toFirestore());
      final savedMessage = replyMessage.copyWith(id: docRef.id);

      // Update conversation metadata
      await _updateConversationLastMessage(conversationId, savedMessage);

      debugPrint('✅ Reply sent successfully: ${docRef.id}');
      return savedMessage;

    } catch (e) {
      debugPrint('❌ Failed to send reply: $e');
      rethrow;
    }
  }

  /// Upload and attach a file to a message
  /// 
  /// @param file - The file to upload
  /// @param conversationId - ID of the conversation
  /// @param fileName - Optional custom file name
  /// 
  /// @returns The download URL of the uploaded file
  /// @throws Exception if upload fails
  Future<String> uploadAttachment({
    required File file,
    required String conversationId,
    String? fileName,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Validate file size (10MB limit)
      const maxSizeBytes = 10 * 1024 * 1024; // 10MB
      final fileSize = await file.length();
      
      if (fileSize > maxSizeBytes) {
        throw Exception('File too large (max 10MB)');
      }

      // Generate unique file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final originalName = fileName ?? file.path.split('/').last;
      final uniqueName = '${userId}_${timestamp}_$originalName';
      
      // Create storage reference
      final storageRef = _storage
          .ref()
          .child('chat_attachments')
          .child(conversationId)
          .child(uniqueName);

      // Upload file with metadata
      final uploadTask = storageRef.putFile(
        file,
        SettableMetadata(
          contentType: _getContentType(originalName),
          customMetadata: {
            'uploadedBy': userId,
            'conversationId': conversationId,
            'originalName': originalName,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for upload completion
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Save attachment metadata to Firestore
      await _attachmentsRef.add({
        'url': downloadUrl,
        'fileName': originalName,
        'fileSize': fileSize,
        'contentType': _getContentType(originalName),
        'uploadedBy': userId,
        'conversationId': conversationId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ File uploaded successfully: $downloadUrl');
      return downloadUrl;

    } catch (e) {
      debugPrint('❌ Failed to upload attachment: $e');
      rethrow;
    }
  }

  /// Add or remove a reaction to/from a message
  /// 
  /// @param messageId - ID of the message to react to
  /// @param emoji - The emoji reaction
  /// @param add - Whether to add (true) or remove (false) the reaction
  /// 
  /// @returns Updated reactions map
  /// @throws Exception if message not found or user not authenticated
  Future<Map<String, List<String>>> toggleReaction({
    required String messageId,
    required String emoji,
    bool add = true,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get the current message
      final messageDoc = await _messagesRef.doc(messageId).get();
      if (!messageDoc.exists) {
        throw Exception('Message not found');
      }

      final message = Message.fromFirestore(messageDoc);
      final currentReactions = Map<String, List<String>>.from(message.reactions);

      // Update reactions
      if (add) {
        // Add reaction
        if (currentReactions.containsKey(emoji)) {
          if (!currentReactions[emoji]!.contains(userId)) {
            currentReactions[emoji]!.add(userId);
          }
        } else {
          currentReactions[emoji] = [userId];
        }
      } else {
        // Remove reaction
        if (currentReactions.containsKey(emoji)) {
          currentReactions[emoji]!.remove(userId);
          if (currentReactions[emoji]!.isEmpty) {
            currentReactions.remove(emoji);
          }
        }
      }

      // Update message in Firestore
      await _messagesRef.doc(messageId).update({
        'reactions': currentReactions,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Reaction ${add ? 'added' : 'removed'}: $emoji on message $messageId');
      return currentReactions;

    } catch (e) {
      debugPrint('❌ Failed to toggle reaction: $e');
      rethrow;
    }
  }

  /// Mark messages as read and create read receipts
  /// 
  /// @param messageIds - List of message IDs to mark as read
  /// @param conversationId - ID of the conversation
  /// 
  /// @throws Exception if user not authenticated
  Future<void> markMessagesAsRead({
    required List<String> messageIds,
    required String conversationId,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final batch = _firestore.batch();
      final timestamp = FieldValue.serverTimestamp();

      for (final messageId in messageIds) {
        // Update message status
        batch.update(_messagesRef.doc(messageId), {
          'status': MessageStatus.read.name,
          'readAt': timestamp,
          'readBy': FieldValue.arrayUnion([userId]),
        });

        // Create read receipt
        final readReceiptRef = _readReceiptsRef.doc();
        batch.set(readReceiptRef, {
          'messageId': messageId,
          'conversationId': conversationId,
          'userId': userId,
          'readAt': timestamp,
        });
      }

      await batch.commit();
      debugPrint('✅ Marked ${messageIds.length} messages as read');

    } catch (e) {
      debugPrint('❌ Failed to mark messages as read: $e');
      rethrow;
    }
  }

  /// Get messages with pagination support
  /// 
  /// @param conversationId - ID of the conversation
  /// @param limit - Number of messages to fetch (default: 20)
  /// @param lastMessageTimestamp - Timestamp of last message for pagination
  /// 
  /// @returns List of messages in chronological order
  Future<List<Message>> getMessages({
    required String conversationId,
    int limit = 20,
    DateTime? lastMessageTimestamp,
  }) async {
    try {
      Query query = _messagesRef
          .where('conversationId', isEqualTo: conversationId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      // Add pagination cursor if provided
      if (lastMessageTimestamp != null) {
        query = query.startAfter([Timestamp.fromDate(lastMessageTimestamp)]);
      }

      final snapshot = await query.get();
      final messages = snapshot.docs
          .map((doc) => Message.fromFirestore(doc))
          .toList()
          .reversed // Reverse to get chronological order
          .toList();

      debugPrint('✅ Fetched ${messages.length} messages for conversation: $conversationId');
      return messages;

    } catch (e) {
      debugPrint('❌ Failed to fetch messages: $e');
      rethrow;
    }
  }

  /// Helper method to determine content type from file extension
  String _getContentType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'txt':
        return 'text/plain';
      case 'mp4':
        return 'video/mp4';
      case 'mp3':
        return 'audio/mpeg';
      default:
        return 'application/octet-stream';
    }
  }

  /// Helper method to update conversation's last message
  Future<void> _updateConversationLastMessage(
    String conversationId,
    Message message,
  ) async {
    try {
      await _conversationsRef.doc(conversationId).update({
        'lastMessage': message.content,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': message.senderId,
        'lastMessageType': message.type.name,
        'lastMessageId': message.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('⚠️ Failed to update conversation last message: $e');
      // Non-critical error
    }
  }
}
