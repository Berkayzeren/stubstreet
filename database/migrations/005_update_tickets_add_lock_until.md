# 005_update_tickets_add_lock_until.md

## Purpose
Add the `lockUntil` field to the existing `tickets` collection.

## Steps

1. **Update Existing Documents:**
   - Add `lockUntil`: timestamp? field to existing ticket documents
   - Default value: null (no lock)

2. **Migration Strategy:**
   - **Option A - Gradual Migration:** Add field to new tickets, backfill existing tickets as needed
   - **Option B - Batch Update:** Update all existing documents at once

3. **Recommended Approach (Option A):**
   ```javascript
   // For new tickets, include lockUntil in toFirestore()
   // For existing tickets, update only when lockUntil functionality is used
   ```

4. **Index Considerations:**
   - Consider adding index on `lockUntil` if frequent queries on locked tickets are needed

5. **Update Application Code:**
   - Ensure Ticket entity includes lockUntil field
   - Update toFirestore() and fromFirestore() methods
   - Add business logic for ticket locking/unlocking

## Verification
- Test ticket creation with lockUntil field
- Test ticket locking/unlocking functionality
- Verify existing tickets are not affected

## Business Logic
- Lock tickets during purchase process
- Automatically unlock tickets after expiration
- Prevent multiple simultaneous purchases
