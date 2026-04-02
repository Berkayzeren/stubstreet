# 006_add_users_collection.md

## Purpose
Create the `users` collection in Firestore and migrate user data from Firebase Auth.

## Steps

1. **Create Collection Path:**
   - Collection: `/users/{userId}`
   - Use Firebase Auth UID as document ID

2. **Add Fields:**
    - `email`: string
    - `firstName`: string
    - `lastName`: string
    - `phoneNumber`: string?
    - `profileImageUrl`: string?
    - `role`: string (default: "buyer")
    - `status`: string (default: "active")
    - `createdAt`: timestamp
    - `updatedAt`: timestamp
    - `stripeCustomerId`: string?
    - `isVerified`: boolean (default: false)
    - `rating`: number (default: 0.0)
    - `totalSales`: number (default: 0)
    - `totalPurchases`: number (default: 0)

3. **Migration Strategy:**
   - **Phase 1:** Create user documents for new registrations
   - **Phase 2:** Backfill existing Firebase Auth users
   - **Phase 3:** Update application to use Firestore user data

4. **Migration Script:**
   ```javascript
   // Pseudocode for migrating existing Firebase Auth users
   async function migrateExistingUsers() {
     const authUsers = await admin.auth().listUsers();
     
     for (const user of authUsers.users) {
       const userData = {
         email: user.email,
         firstName: extractFirstName(user.displayName),
         lastName: extractLastName(user.displayName),
         phoneNumber: user.phoneNumber,
         profileImageUrl: user.photoURL,
         role: 'buyer',
         status: 'active',
         createdAt: new Date(user.metadata.creationTime),
         updatedAt: new Date(),
         stripeCustomerId: null,
         isVerified: user.emailVerified,
         rating: 0.0,
         totalSales: 0,
         totalPurchases: 0
       };
       
       await firestore.collection('users').doc(user.uid).set(userData);
     }
   }
   ```

5. **Indexes:**
    - `email` (ascending)
    - `role` (ascending)
    - `status` (ascending)
    - `createdAt` (descending)

6. **Update Authentication Flow:**
   - On user registration, create user document in Firestore
   - On login, ensure user document exists
   - Update user profile updates to modify Firestore document

## Verification
- Ensure all Firebase Auth users have corresponding Firestore documents
- Test user registration and login flows
- Verify data consistency

## Notes
- Maintain Firebase Auth as primary authentication mechanism
- Use Firestore for extended user profile data
