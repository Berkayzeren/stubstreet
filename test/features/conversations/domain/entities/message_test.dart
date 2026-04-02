import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stubstreet/features/conversations/domain/entities/message.dart';

void main() {
  group('Message Entity', () {
    late Message testMessage;

    setUp(() {
      testMessage = Message(
        id: 'test-id',
        conversationId: 'conv-123',
        senderId: 'sender-123',
        senderName: 'John Doe',
        receiverId: 'receiver-456',
        receiverName: 'Jane Smith',
        type: MessageType.text,
        status: MessageStatus.sent,
        content: 'Hello, world!',
        attachments: [],
        createdAt: DateTime(2023, 1, 1, 12, 0, 0),
      );
    });

    test('should create a message with required fields', () {
      expect(testMessage.id, equals('test-id'));
      expect(testMessage.conversationId, equals('conv-123'));
      expect(testMessage.senderId, equals('sender-123'));
      expect(testMessage.senderName, equals('John Doe'));
      expect(testMessage.receiverId, equals('receiver-456'));
      expect(testMessage.receiverName, equals('Jane Smith'));
      expect(testMessage.type, equals(MessageType.text));
      expect(testMessage.status, equals(MessageStatus.sent));
      expect(testMessage.content, equals('Hello, world!'));
      expect(testMessage.attachments, isEmpty);
      expect(testMessage.createdAt, equals(DateTime(2023, 1, 1, 12, 0, 0)));
      expect(testMessage.isEdited, isFalse);
      expect(testMessage.isDeleted, isFalse);
    });

    test('should create a copy with updated fields', () {
      final updatedMessage = testMessage.copyWith(
        content: 'Updated content',
        status: MessageStatus.read,
        isEdited: true,
      );

      expect(updatedMessage.id, equals(testMessage.id));
      expect(updatedMessage.content, equals('Updated content'));
      expect(updatedMessage.status, equals(MessageStatus.read));
      expect(updatedMessage.isEdited, isTrue);
      expect(updatedMessage.senderId, equals(testMessage.senderId));
    });

    test('should return correct boolean properties', () {
      expect(testMessage.isRead, isFalse);
      expect(testMessage.hasAttachments, isFalse);
      expect(testMessage.isReply, isFalse);

      final messageWithAttachments = testMessage.copyWith(
        attachments: ['url1', 'url2'],
      );
      expect(messageWithAttachments.hasAttachments, isTrue);

      final readMessage = testMessage.copyWith(
        readAt: DateTime.now(),
      );
      expect(readMessage.isRead, isTrue);

      final replyMessage = testMessage.copyWith(
        replyToMessageId: 'parent-msg-id',
      );
      expect(replyMessage.isReply, isTrue);
    });

    test('should convert to Firestore format correctly', () {
      final firestoreData = testMessage.toFirestore();

      expect(firestoreData['conversationId'], equals('conv-123'));
      expect(firestoreData['senderId'], equals('sender-123'));
      expect(firestoreData['senderName'], equals('John Doe'));
      expect(firestoreData['receiverId'], equals('receiver-456'));
      expect(firestoreData['receiverName'], equals('Jane Smith'));
      expect(firestoreData['type'], equals('text'));
      expect(firestoreData['status'], equals('sent'));
      expect(firestoreData['content'], equals('Hello, world!'));
      expect(firestoreData['attachments'], isEmpty);
      expect(firestoreData['createdAt'], isA<Timestamp>());
      expect(firestoreData['isEdited'], isFalse);
      expect(firestoreData['isDeleted'], isFalse);
    });

    test('should handle different message types correctly', () {
      final imageMessage = testMessage.copyWith(
        type: MessageType.image,
        attachments: ['image_url'],
      );
      expect(imageMessage.type, equals(MessageType.image));
      expect(imageMessage.hasAttachments, isTrue);

      final systemMessage = testMessage.copyWith(
        type: MessageType.system,
        content: 'User joined the conversation',
      );
      expect(systemMessage.type, equals(MessageType.system));
      expect(systemMessage.content, equals('User joined the conversation'));
    });

    test('should handle message status changes correctly', () {
      final sentMessage = testMessage.copyWith(status: MessageStatus.sent);
      expect(sentMessage.status, equals(MessageStatus.sent));

      final deliveredMessage = testMessage.copyWith(status: MessageStatus.delivered);
      expect(deliveredMessage.status, equals(MessageStatus.delivered));

      final readMessage = testMessage.copyWith(
        status: MessageStatus.read,
        readAt: DateTime.now(),
      );
      expect(readMessage.status, equals(MessageStatus.read));
      expect(readMessage.isRead, isTrue);

      final failedMessage = testMessage.copyWith(status: MessageStatus.failed);
      expect(failedMessage.status, equals(MessageStatus.failed));
    });
  });

  group('MessageType Extension', () {
    test('should return correct display names', () {
      expect(MessageType.text.displayName, equals('Metin'));
      expect(MessageType.image.displayName, equals('Resim'));
      expect(MessageType.file.displayName, equals('Dosya'));
      expect(MessageType.system.displayName, equals('Sistem'));
      expect(MessageType.offer.displayName, equals('Teklif'));
      expect(MessageType.reminder.displayName, equals('Hatırlatma'));
    });

    test('should return correct icons', () {
      expect(MessageType.text.icon, equals('💬'));
      expect(MessageType.image.icon, equals('🖼️'));
      expect(MessageType.file.icon, equals('📎'));
      expect(MessageType.system.icon, equals('⚙️'));
      expect(MessageType.offer.icon, equals('💰'));
      expect(MessageType.reminder.icon, equals('⏰'));
    });
  });

  group('MessageStatus Extension', () {
    test('should return correct display names', () {
      expect(MessageStatus.sent.displayName, equals('Gönderildi'));
      expect(MessageStatus.delivered.displayName, equals('Ulaştı'));
      expect(MessageStatus.read.displayName, equals('Okundu'));
      expect(MessageStatus.failed.displayName, equals('Başarısız'));
    });

    test('should return correct icons', () {
      expect(MessageStatus.sent.icon, equals('✓'));
      expect(MessageStatus.delivered.icon, equals('✓✓'));
      expect(MessageStatus.read.icon, equals('✓✓'));
      expect(MessageStatus.failed.icon, equals('❌'));
    });
  });
}
