# 001_add_conversations_collection.md

## Purpose
Create the `conversations` collection in Firestore and set up appropriate indexes.

## Steps

1. **Create Collection Path:**
   - Collection: `/conversations/{conversationId}`

2. **Add Fields:**
    - `ticketId`: string
    - `buyerId`: string
    - `sellerId`: string
    - `buyerName`: string
    - `sellerName`: string
    - `type`: string
    - `status`: string
    - `createdAt`: timestamp
    - `updatedAt`: timestamp
    - `lastMessageId`: string?
    - `lastMessageContent`: string?
    - `lastMessageAt`: timestamp?
    - `lastMessageSenderId`: string?
    - `unreadCountBuyer`: number
    - `unreadCountSeller`: number
    - `isDeletedByBuyer`: boolean
    - `isDeletedBySeller`: boolean
    - `metadata`: map?

3. **Indexes:**
    - `ticketId` (ascending)
    - `buyerId` (ascending)
    - `sellerId` (ascending)
    - `lastMessageAt` (descending)

4. **Test with Sample Data:**
   - Insert mock data to ensure structure and functionality

## Verification
- Ensure data integrity
- Verify indexes with sample queries

## Notes
- Monitor performance and adjust indexes as needed
