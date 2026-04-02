# 003_add_orders_collection.md

## Purpose
Create the `orders` collection in Firestore and set up appropriate indexes.

## Steps

1. **Create Collection Path:**
   - Collection: `/orders/{orderId}`

2. **Add Fields:**
    - `ticketId`: string
    - `buyerId`: string
    - `sellerId`: string
    - `buyerName`: string
    - `sellerName`: string
    - `buyerEmail`: string
    - `sellerEmail`: string
    - `status`: string
    - `type`: string
    - `deliveryMethod`: string
    - `ticketPrice`: number
    - `serviceFee`: number
    - `totalAmount`: number
    - `currency`: string
    - `createdAt`: timestamp
    - `updatedAt`: timestamp
    - `confirmedAt`: timestamp?
    - `shippedAt`: timestamp?
    - `deliveredAt`: timestamp?
    - `cancelledAt`: timestamp?
    - `cancellationReason`: string?
    - `trackingNumber`: string?
    - `deliveryAddress`: string?
    - `meetupLocation`: string?
    - `meetupDateTime`: timestamp?
    - `notes`: string?
    - `attachments`: array<string>
    - `metadata`: map?

3. **Indexes:**
    - `ticketId` (ascending)
    - `buyerId` (ascending)
    - `sellerId` (ascending)
    - `status` (ascending)
    - `createdAt` (descending)
    - Composite: `buyerId, createdAt` (ascending, descending)
    - Composite: `sellerId, createdAt` (ascending, descending)
    - Composite: `status, createdAt` (ascending, descending)

4. **Test with Sample Data:**
   - Create mock orders for different scenarios

## Verification
- Ensure data integrity
- Verify indexes with sample queries

## Notes
- Monitor order lifecycle and status transitions
