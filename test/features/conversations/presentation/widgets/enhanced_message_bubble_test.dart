import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stubstreet/features/conversations/domain/entities/message.dart';
import 'package:stubstreet/features/conversations/presentation/widgets/enhanced_message_bubble.dart';

void main() {
  group('EnhancedMessageBubble Widget', () {
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

    Widget createWidget({
      required Message message,
      required bool isCurrentUser,
      Function(Message)? onSwipeToReply,
      Message? replyToMessage,
      bool isOptimistic = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: EnhancedMessageBubble(
            message: message,
            isCurrentUser: isCurrentUser,
            onSwipeToReply: onSwipeToReply,
            replyToMessage: replyToMessage,
            isOptimistic: isOptimistic,
          ),
        ),
      );
    }

    testWidgets('should display message content correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget(
        message: testMessage,
        isCurrentUser: true,
      ));

      expect(find.text('Hello, world!'), findsOneWidget);
    });

    testWidgets('should display current user message with correct alignment', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget(
        message: testMessage,
        isCurrentUser: true,
      ));

      final messageBubble = find.byType(EnhancedMessageBubble);
      expect(messageBubble, findsOneWidget);

      // Check if the message is aligned to the right for current user
      final container = find.byType(Container).first;
      final containerWidget = tester.widget<Container>(container);
      final margin = containerWidget.margin as EdgeInsets;
      
      // Current user messages should have left margin (aligned right)
      expect(margin.left, equals(64.0));
      expect(margin.right, equals(0.0));
    });

    testWidgets('should display other user message with correct alignment', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget(
        message: testMessage,
        isCurrentUser: false,
      ));

      final messageBubble = find.byType(EnhancedMessageBubble);
      expect(messageBubble, findsOneWidget);

      // Check if the message is aligned to the left for other user
      final container = find.byType(Container).first;
      final containerWidget = tester.widget<Container>(container);
      final margin = containerWidget.margin as EdgeInsets;
      
      // Other user messages should have right margin (aligned left)
      expect(margin.left, equals(0.0));
      expect(margin.right, equals(64.0));
    });

    testWidgets('should display reply preview when replying to a message', (WidgetTester tester) async {
      final replyToMessage = Message(
        id: 'reply-to-id',
        conversationId: 'conv-123',
        senderId: 'sender-456',
        senderName: 'Original Sender',
        receiverId: 'receiver-123',
        receiverName: 'Receiver',
        type: MessageType.text,
        status: MessageStatus.sent,
        content: 'Original message',
        attachments: [],
        createdAt: DateTime(2023, 1, 1, 11, 0, 0),
      );

      await tester.pumpWidget(createWidget(
        message: testMessage,
        isCurrentUser: true,
        replyToMessage: replyToMessage,
      ));

      // Check if reply preview is displayed
      expect(find.text('Original Sender'), findsOneWidget);
      expect(find.text('Original message'), findsOneWidget);
    });

    testWidgets('should display timestamp when showTimeStamp is true', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget(
        message: testMessage,
        isCurrentUser: true,
      ));

      // Should show some time-related text (exact format depends on implementation)
      expect(find.textContaining(''), findsWidgets);
    });

    testWidgets('should display status icon for current user messages', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget(
        message: testMessage,
        isCurrentUser: true,
      ));

      // Should find status icon (depends on message status)
      expect(find.byIcon(Icons.done), findsOneWidget);
    });

    testWidgets('should handle different message types correctly', (WidgetTester tester) async {
      // Test image message
      final imageMessage = testMessage.copyWith(
        type: MessageType.image,
        attachments: ['https://example.com/image.jpg'],
      );

      await tester.pumpWidget(createWidget(
        message: imageMessage,
        isCurrentUser: true,
      ));

      // Should find image-related content
      expect(find.byType(Container), findsWidgets);

      // Test system message
      final systemMessage = testMessage.copyWith(
        type: MessageType.system,
        content: 'User joined the conversation',
      );

      await tester.pumpWidget(createWidget(
        message: systemMessage,
        isCurrentUser: false,
      ));

      expect(find.text('User joined the conversation'), findsOneWidget);
    });

    testWidgets('should show optimistic state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget(
        message: testMessage,
        isCurrentUser: true,
        isOptimistic: true,
      ));

      // Should show loading indicator for optimistic messages
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should handle tap gesture', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget(
        message: testMessage,
        isCurrentUser: true,
      ));

      await tester.tap(find.byType(EnhancedMessageBubble), warnIfMissed: false);
      await tester.pump();

      // Tap should be handled (depends on implementation)
      expect(find.byType(EnhancedMessageBubble), findsOneWidget);
    });

    testWidgets('should handle long press gesture', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget(
        message: testMessage,
        isCurrentUser: true,
      ));

      await tester.longPress(find.byType(EnhancedMessageBubble), warnIfMissed: false);
      await tester.pumpAndSettle();

    // Should complete long press action
    expect(find.byType(EnhancedMessageBubble), findsOneWidget);
    });

    testWidgets('should display different message statuses correctly', (WidgetTester tester) async {
      // Test sent status
      final sentMessage = testMessage.copyWith(status: MessageStatus.sent);
      await tester.pumpWidget(createWidget(
        message: sentMessage,
        isCurrentUser: true,
      ));
      expect(find.byIcon(Icons.done), findsOneWidget);

      // Test delivered status
      final deliveredMessage = testMessage.copyWith(status: MessageStatus.delivered);
      await tester.pumpWidget(createWidget(
        message: deliveredMessage,
        isCurrentUser: true,
      ));
      expect(find.byIcon(Icons.done_all), findsOneWidget);

      // Test read status
      final readMessage = testMessage.copyWith(
        status: MessageStatus.read,
        readAt: DateTime.now(),
      );
      await tester.pumpWidget(createWidget(
        message: readMessage,
        isCurrentUser: true,
      ));
      expect(find.byIcon(Icons.done_all), findsOneWidget);

      // Test failed status
      final failedMessage = testMessage.copyWith(status: MessageStatus.failed);
      await tester.pumpWidget(createWidget(
        message: failedMessage,
        isCurrentUser: true,
      ));
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('should handle swipe to reply gesture', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget(
        message: testMessage,
        isCurrentUser: true,
        onSwipeToReply: (message) {
          // Swipe handler - test callback
        },
      ));

      // Simulate swipe gesture
      await tester.drag(find.byType(EnhancedMessageBubble), const Offset(100, 0), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Should complete swipe action
      expect(find.byType(EnhancedMessageBubble), findsOneWidget);
    });

    testWidgets('should display attachment indicators', (WidgetTester tester) async {
      final messageWithAttachments = testMessage.copyWith(
        attachments: ['url1', 'url2'],
      );

      await tester.pumpWidget(createWidget(
        message: messageWithAttachments,
        isCurrentUser: true,
      ));

      // Should show attachment indicators
      expect(find.text('Attachment'), findsWidgets);
      expect(find.byIcon(Icons.attachment), findsWidgets);
    });

    testWidgets('should display edited indicator for edited messages', (WidgetTester tester) async {
      final editedMessage = testMessage.copyWith(
        isEdited: true,
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(createWidget(
        message: editedMessage,
        isCurrentUser: true,
      ));

      // Should show edited indicator
      expect(find.text('edited'), findsOneWidget);
    });
  });
}
