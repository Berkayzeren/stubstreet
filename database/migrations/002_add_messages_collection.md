# 002_add_messages_collection.md

## Purpose
Create the `messages` collection in Firestore and set up appropriate indexes.

## Steps

1. **Create Collection Path:**
   - Collection: `/messages/{messageId}`

2. **Add Fields:**
    - `conversationId`: string
    - `senderId`: string
    - `senderName`: string
    - `receiverId`: string
    - `receiverName`: string
    - `type`: string
    - `status`: string
    - `content`: string
    - `attachments`: array<string>
    - `createdAt`: timestamp
    - `updatedAt`: timestamp?
    - `readAt`: timestamp?
    - `isEdited`: boolean
    - `isDeleted`: boolean
    - `replyToMessageId`: string?
    - `metadata`: map?

3. **Indexes:**
    - `conversationId` (ascending)
    - `createdAt` (ascending)
    - Composite: `conversationId, createdAt` (ascending, ascending)
    - `senderId` (ascending)
    - `receiverId` (ascending)

4. **Test with Sample Data:**
   - Insert mock messages linked to conversations

## Verification
- Ensure data integrity
- Verify indexes with sample queries

## Notes
- Consider implementing pagination for large message lists
