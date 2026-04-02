# Firestore Database Schema

This document outlines the Firestore collections and their structure for the StubStreet application.

## Collections Overview

### 1. Users Collection (`users`)
- **Collection Path**: `/users/{userId}`
- **Purpose**: Store user profile information and metadata

#### Fields:
```javascript
{
  "email": "string",               // User's email address
  "firstName": "string",           // User's first name
  "lastName": "string",            // User's last name
  "phoneNumber": "string?",        // User's phone number (optional)
  "profileImageUrl": "string?",    // URL to profile image (optional)
  "role": "string",                // Enum: buyer, seller, admin
  "status": "string",              // Enum: active, suspended, deleted
  "createdAt": "timestamp",        // Account creation date
  "updatedAt": "timestamp",        // Last update date
  "stripeCustomerId": "string?",   // Stripe customer ID for payments (NEW FIELD)
  "isVerified": "boolean",         // Email/phone verification status
  "rating": "number",              // User rating (0.0 - 5.0)
  "totalSales": "number",          // Total number of sales
  "totalPurchases": "number"       // Total number of purchases
}
```

#### Indexes:
- `email` (ascending)
- `role` (ascending)
- `status` (ascending)
- `createdAt` (descending)

### 2. Tickets Collection (`tickets`) - UPDATED
- **Collection Path**: `/tickets/{ticketId}`
- **Purpose**: Store ticket listings

#### New/Updated Fields:
```javascript
{
  // ... existing fields ...
  "lockUntil": "timestamp?",       // Lock expiration for purchase reservations (NEW FIELD)
  // ... rest of existing fields remain the same ...
}
```

### 3. Conversations Collection (`conversations`) - NEW
- **Collection Path**: `/conversations/{conversationId}`
- **Purpose**: Store conversation metadata between users

#### Fields:
```javascript
{
  "ticketId": "string",             // Related ticket ID
  "buyerId": "string",              // Buyer user ID
  "sellerId": "string",             // Seller user ID
  "buyerName": "string",            // Buyer display name
  "sellerName": "string",           // Seller display name
  "type": "string",                 // Enum: ticketInquiry, general, support, dispute
  "status": "string",               // Enum: active, closed, archived
  "createdAt": "timestamp",         // Conversation creation date
  "updatedAt": "timestamp",         // Last update date
  "lastMessageId": "string?",       // Last message ID
  "lastMessageContent": "string?",  // Preview of last message
  "lastMessageAt": "timestamp?",    // Last message timestamp
  "lastMessageSenderId": "string?", // Last message sender ID
  "unreadCountBuyer": "number",     // Unread messages count for buyer
  "unreadCountSeller": "number",    // Unread messages count for seller
  "isDeletedByBuyer": "boolean",    // Soft delete flag for buyer
  "isDeletedBySeller": "boolean",   // Soft delete flag for seller
  "metadata": "map?"                // Additional metadata
}
```

#### Indexes:
- `ticketId` (ascending)
- `buyerId` (ascending)
- `sellerId` (ascending)
- `lastMessageAt` (descending)
- Composite: `buyerId, lastMessageAt` (ascending, descending)
- Composite: `sellerId, lastMessageAt` (ascending, descending)

### 4. Messages Collection (`messages`) - ENHANCED
- **Collection Path**: `/messages/{messageId}`
- **Purpose**: Store individual messages within conversations

#### Fields:
```javascript
{
  "id": "string",                    // Auto-generated message ID
  "conversationId": "string",        // Parent conversation ID
  "senderId": "string",              // Message sender ID
  "receiverId": "string",            // Message receiver ID
  "senderName": "string",            // Sender display name
  "receiverName": "string",          // Receiver display name
  "type": "string",                  // Enum: text, image, video, audio, file, system, offer, reminder, location
  "status": "string",                // Enum: sent, delivered, read, failed, deleted
  "content": "string",               // Message content
  "mediaUrls": "array<string>",      // URLs to media files (images, videos, audio)
  "attachments": "array<object>",    // File attachments with metadata
  "createdAt": "timestamp",          // Message creation timestamp
  "updatedAt": "timestamp?",         // Last edit timestamp
  "readAt": "timestamp?",            // Message read timestamp
  "deliveredAt": "timestamp?",       // Message delivered timestamp
  "isEdited": "boolean",             // Edit flag
  "isDeleted": "boolean",            // Soft delete flag
  "replyToMessageId": "string?",     // Reply reference ID
  "reactions": "map<string, array<string>>", // Emoji reactions: {emoji: [userIds]}
  "metadata": "map?",                // Additional metadata (thread info, system data)
  "priority": "string",              // Enum: low, normal, high, urgent
  "ttl": "number?",                  // Time-to-live in seconds (for disappearing messages)
  "editHistory": "array<object>?"    // Edit history for auditing
}
```

#### Attachments Object Structure:
```javascript
{
  "id": "string",                    // Attachment ID
  "name": "string",                  // Original filename
  "type": "string",                  // MIME type
  "size": "number",                  // File size in bytes
  "url": "string",                   // Storage URL
  "thumbnailUrl": "string?",         // Thumbnail URL for images/videos
  "duration": "number?",             // Duration for audio/video in seconds
  "metadata": "map?"                 // Additional file metadata
}
```

#### Indexes:
- `conversationId` (ascending)
- `createdAt` (ascending)
- Composite: `conversationId, createdAt` (ascending, ascending)
- `senderId` (ascending)
- `receiverId` (ascending)

### 5. Orders Collection (`orders`) - NEW
- **Collection Path**: `/orders/{orderId}`
- **Purpose**: Store ticket purchase/sale orders

#### Fields:
```javascript
{
  "ticketId": "string",             // Related ticket ID
  "buyerId": "string",              // Buyer user ID
  "sellerId": "string",             // Seller user ID
  "buyerName": "string",            // Buyer display name
  "sellerName": "string",           // Seller display name
  "buyerEmail": "string",           // Buyer email
  "sellerEmail": "string",          // Seller email
  "status": "string",               // Enum: pending, confirmed, processing, shipped, delivered, cancelled, refunded, disputed
  "type": "string",                 // Enum: purchase, sale, transfer
  "deliveryMethod": "string",       // Enum: digital, mail, pickup, meetup
  "ticketPrice": "number",          // Ticket price
  "serviceFee": "number",           // Platform service fee
  "totalAmount": "number",          // Total amount
  "currency": "string",             // Currency code (e.g., "TRY")
  "createdAt": "timestamp",         // Order creation date
  "updatedAt": "timestamp",         // Last update date
  "confirmedAt": "timestamp?",      // Order confirmation date
  "shippedAt": "timestamp?",        // Shipping date
  "deliveredAt": "timestamp?",      // Delivery date
  "cancelledAt": "timestamp?",      // Cancellation date
  "cancellationReason": "string?",  // Cancellation reason
  "trackingNumber": "string?",      // Shipping tracking number
  "deliveryAddress": "string?",     // Delivery address
  "meetupLocation": "string?",      // Meetup location
  "meetupDateTime": "timestamp?",   // Meetup date and time
  "notes": "string?",               // Additional notes
  "attachments": "array<string>",   // URLs to attached files
  "metadata": "map?"                // Additional metadata
}
```

#### Indexes:
- `ticketId` (ascending)
- `buyerId` (ascending)
- `sellerId` (ascending)
- `status` (ascending)
- `createdAt` (descending)
- Composite: `buyerId, createdAt` (ascending, descending)
- Composite: `sellerId, createdAt` (ascending, descending)
- Composite: `status, createdAt` (ascending, descending)

### 6. UserProfiles Collection (`userProfiles`) - NEW
- **Collection Path**: `/userProfiles/{userId}`
- **Purpose**: Store extended user profile information

#### Fields:
```javascript
{
  "userId": "string",                // User ID (matches auth UID)
  "avatarUrl": "string?",            // Profile picture URL
  "coverUrl": "string?",             // Cover/banner image URL
  "bio": "string?",                  // User biography
  "tags": "array<string>",           // User interests/tags
  "stats": {
    "totalMessages": "number",       // Total messages sent
    "totalConversations": "number",  // Total conversations
    "averageResponseTime": "number", // Average response time in minutes
    "rating": "number",              // User rating (0.0-5.0)
    "totalSales": "number",          // Total ticket sales
    "totalPurchases": "number",      // Total ticket purchases
    "joinedAt": "timestamp",         // Account creation date
    "lastActive": "timestamp"        // Last activity timestamp
  },
  "preferences": {
    "language": "string",            // Preferred language
    "timezone": "string",            // User timezone
    "theme": "string",               // UI theme preference
    "autoTranslate": "boolean",      // Auto-translate messages
    "showOnlineStatus": "boolean",   // Show online status to others
    "allowDirectMessages": "boolean" // Allow DMs from non-contacts
  },
  "privacySettings": {
    "profileVisibility": "string",   // Enum: public, friends, private
    "showEmail": "boolean",          // Show email in profile
    "showPhone": "boolean",          // Show phone in profile
    "showLastSeen": "boolean",       // Show last seen timestamp
    "blockList": "array<string>"     // Blocked user IDs
  },
  "socialLinks": {
    "website": "string?",            // Personal website
    "instagram": "string?",          // Instagram handle
    "twitter": "string?",            // Twitter handle
    "linkedin": "string?"            // LinkedIn profile
  },
  "location": "string?",             // User location (city, country)
  "isOnline": "boolean",             // Current online status
  "lastSeenAt": "timestamp",         // Last seen timestamp
  "deviceTokens": "array<string>",   // FCM device tokens for push notifications
  "metadata": "map?"                 // Additional user metadata
}
```

#### Indexes:
- `isOnline` (ascending)
- `lastSeenAt` (descending)
- Composite: `isOnline, lastSeenAt` (ascending, descending)

### 7. ReadReceipts Collection (`readReceipts`) - NEW
- **Collection Path**: `/readReceipts/{receiptId}`
- **Purpose**: Store message read receipts

#### Fields:
```javascript
{
  "receiptId": "string",             // Auto-generated receipt ID
  "messageId": "string",             // Reference to message
  "userId": "string",                // User who read the message
  "conversationId": "string",        // Parent conversation
  "readAt": "timestamp",             // When message was read
  "createdAt": "timestamp",          // Receipt creation time
  "metadata": "map?"                 // Additional metadata
}
```

#### Indexes:
- `messageId` (ascending)
- `conversationId` (ascending)
- `userId` (ascending)
- Composite: `messageId, readAt` (ascending, descending)
- Composite: `conversationId, readAt` (ascending, descending)
- Composite: `userId, readAt` (ascending, descending)

### 8. PushNotifications Collection (`pushNotifications`) - NEW
- **Collection Path**: `/pushNotifications/{notificationId}`
- **Purpose**: Store push notification history

#### Fields:
```javascript
{
  "notificationId": "string",        // Auto-generated notification ID
  "userId": "string",                // Target user ID
  "messageId": "string?",            // Related message ID
  "conversationId": "string?",       // Related conversation ID
  "type": "string",                  // Enum: message, mention, reaction, system
  "title": "string",                 // Notification title
  "body": "string",                  // Notification body
  "data": {
    "conversationId": "string",      // Deep link data
    "messageId": "string",           // Deep link data
    "senderId": "string",            // Sender information
    "senderName": "string",          // Sender name
    "action": "string",              // Action type
    "priority": "string"             // Notification priority
  },
  "status": "string",                // Enum: pending, sent, delivered, failed
  "createdAt": "timestamp",          // Notification creation time
  "sentAt": "timestamp?",            // When notification was sent
  "deliveredAt": "timestamp?",       // When notification was delivered
  "readAt": "timestamp?",            // When notification was read
  "deviceTokens": "array<string>",   // Target device tokens
  "metadata": "map?"                 // Additional metadata
}
```

#### Indexes:
- `userId` (ascending)
- `createdAt` (descending)
- `status` (ascending)
- Composite: `userId, createdAt` (ascending, descending)
- Composite: `userId, status, createdAt` (ascending, ascending, descending)
- Composite: `conversationId, createdAt` (ascending, descending)

### 9. NotificationSettings Collection (`notificationSettings`) - NEW
- **Collection Path**: `/notificationSettings/{userId}`
- **Purpose**: Store user notification preferences

#### Fields:
```javascript
{
  "userId": "string",                // User ID
  "messageNotifications": "boolean", // Enable message notifications
  "emailNotifications": "boolean",   // Enable email notifications
  "pushNotifications": "boolean",    // Enable push notifications
  "preferences": {
    "sound": "string",               // Notification sound
    "vibration": "boolean",          // Vibration setting
    "showPreview": "boolean",        // Show message content in notification
    "groupNotifications": "boolean", // Group similar notifications
    "quietHours": {
      "enabled": "boolean",          // Enable quiet hours
      "startTime": "string",         // Start time (HH:MM)
      "endTime": "string",           // End time (HH:MM)
      "timezone": "string"           // Timezone
    }
  },
  "mutedConversations": "array<string>", // Muted conversation IDs
  "mutedUsers": "array<string>",     // Muted user IDs
  "updatedAt": "timestamp",          // Last update time
  "metadata": "map?"                 // Additional settings
}
```

#### Indexes:
- `userId` (ascending)
- `updatedAt` (descending)

### 10. Payments Collection (`payments`) - UPDATED
- **Collection Path**: `/payments/{paymentId}`
- **Purpose**: Store payment transactions

#### Fields:
```javascript
{
  "orderId": "string",              // Related order ID
  "payerId": "string",              // Payer user ID
  "payeeId": "string",              // Payee user ID
  "paymentMethod": "string",        // Payment method (stripe, paypal, etc.)
  "amount": "number",               // Payment amount
  "createdAt": "timestamp",         // Payment creation date
  "updatedAt": "timestamp?",        // Last update date
  "completedAt": "timestamp?",      // Payment completion date
  "refundedAt": "timestamp?",       // Refund date
  "refundReason": "string?",        // Refund reason
  "currency": "string",             // Currency code
  "status": "string",               // Enum: pending, successful, failed, refunded, disputed
  "metadata": "map?",               // Payment gateway metadata
  "attachments": "array<string>"    // URLs to receipts/documents
}
```

#### Indexes:
- `orderId` (ascending)
- `payerId` (ascending)
- `payeeId` (ascending)
- `status` (ascending)
- `createdAt` (descending)
- Composite: `payerId, createdAt` (ascending, descending)
- Composite: `payeeId, createdAt` (ascending, descending)

## Security Rules

### Authentication Requirements:
- All collections require authentication
- Users can only access their own data or public data
- Admin users have elevated permissions

### Basic Rules Structure:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own profile
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null; // Allow reading other profiles
    }
    
    // Tickets are publicly readable, but only owners can write
    match /tickets/{ticketId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == resource.data.sellerId;
    }
    
    // Conversations accessible by participants only
    match /conversations/{conversationId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == resource.data.buyerId || request.auth.uid == resource.data.sellerId);
    }
    
    // Messages accessible by conversation participants
    match /messages/{messageId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == resource.data.senderId || request.auth.uid == resource.data.receiverId);
    }
    
    // Orders accessible by buyer/seller
    match /orders/{orderId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == resource.data.buyerId || request.auth.uid == resource.data.sellerId);
    }
    
    // Payments accessible by payer/payee
    match /payments/{paymentId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == resource.data.payerId || request.auth.uid == resource.data.payeeId);
    }
  }
}
```

## Migration Strategy

### Phase 1: Add New Collections
1. Deploy new entity classes
2. Create Firestore indexes for new collections
3. Test with sample data

### Phase 2: Update Existing Collections
1. Update Ticket entity with `lockUntil` field
2. Create User entity and migrate Firebase Auth users to Firestore
3. Add `stripeCustomerId` field during user profile updates

### Phase 3: Data Migration
1. Create migration scripts for existing data
2. Validate data integrity
3. Update application code to use new schema

### Phase 4: Deploy Security Rules
1. Update Firestore security rules
2. Test access patterns
3. Monitor for security violations

## Migration Scripts

See individual migration files in the `/database/migrations/` directory for specific migration procedures.
