# 004_add_payments_collection.md

## Purpose
Create the `payments` collection in Firestore and set up appropriate indexes.

## Steps

1. **Create Collection Path:**
   - Collection: `/payments/{paymentId}`

2. **Add Fields:**
    - `orderId`: string
    - `payerId`: string
    - `payeeId`: string
    - `paymentMethod`: string
    - `amount`: number
    - `createdAt`: timestamp
    - `updatedAt`: timestamp?
    - `completedAt`: timestamp?
    - `refundedAt`: timestamp?
    - `refundReason`: string?
    - `currency`: string
    - `status`: string
    - `metadata`: map?
    - `attachments`: array<string>

3. **Indexes:**
    - `orderId` (ascending)
    - `payerId` (ascending)
    - `payeeId` (ascending)
    - `status` (ascending)
    - `createdAt` (descending)
    - Composite: `payerId, createdAt` (ascending, descending)
    - Composite: `payeeId, createdAt` (ascending, descending)

4. **Test with Sample Data:**
   - Create mock payment records linked to orders

## Verification
- Ensure data integrity
- Verify indexes with sample queries

## Notes
- Secure payment data appropriately
- Consider PCI compliance requirements
