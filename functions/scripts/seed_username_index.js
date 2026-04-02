/*
  Purpose: Seed the public usernameIndex collection from the private users collection.

  Why:
  - The client cannot read /users before authentication due to Firestore security rules.
  - For username-based login, we need a public (read-only) mapping username -> {email, uid, role, status}.
  - This script runs with Admin SDK and creates/updates usernameIndex documents for each user.

  What it does:
  - Iterates over all /users docs
  - Builds a set of candidate handles per user:
    * data.username (if exists)
    * email local-part (left of @)
    * firstName (sanitized)
    * displayName (sanitized words without spaces)
  - For each handle, writes /usernameIndex/{handle} with minimal fields used in pre-auth login

  How to run:
    node scripts/seed_username_index.js

  Notes:
  - Idempotent: uses set(..., { merge: true }) so re-running updates timestamps but preserves fields.
  - Sanitization: lowercases and keeps [a-z0-9_]. Non-matching handles are skipped.
*/

const path = require('path');
const admin = require('firebase-admin');

// Initialize Admin SDK using local service account
// We keep this file locally and DO NOT commit to VCS; only for developer ops.
const serviceAccountPath = path.resolve(__dirname, '../serviceAccountKey.json');
try {
  // eslint-disable-next-line import/no-dynamic-require, global-require
  const serviceAccount = require(serviceAccountPath);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
} catch (err) {
  console.error('Failed to load serviceAccountKey.json. Place it under functions/serviceAccountKey.json');
  process.exit(1);
}

const db = admin.firestore();

/**
 * Sanitize an arbitrary string into a handle suitable for login
 * @param {string|undefined|null} raw
 * @returns {string|null} lowercased handle [a-z0-9_], or null if invalid/too short
 */
function toHandle(raw) {
  if (!raw || typeof raw !== 'string') return null;
  const trimmed = raw.trim().toLowerCase();
  if (!trimmed) return null;
  // Replace spaces with underscore, drop non-alphanumerics except underscore
  const normalized = trimmed
    .replace(/\s+/g, '_')
    .replace(/[^a-z0-9_]/g, '');
  if (normalized.length < 3) return null;
  return normalized;
}

/**
 * Extract local part from an email address
 * @param {string|undefined|null} email
 * @returns {string|null}
 */
function emailLocal(email) {
  if (!email || typeof email !== 'string' || !email.includes('@')) return null;
  return toHandle(email.split('@')[0]);
}

(async () => {
  try {
    console.log('Seeding usernameIndex from users...');
    const usersSnap = await db.collection('users').get();
    console.log(`Found ${usersSnap.size} user documents.`);

    let writes = 0;
    for (const userDoc of usersSnap.docs) {
      const data = userDoc.data() || {};
      const uid = userDoc.id;
      const email = data.email || null;
      const role = data.role || 'buyer';
      const status = data.status || 'active';
      const username = toHandle(data.username);
      const firstName = toHandle(data.firstName);
      const displayName = toHandle(data.displayName);
      const emailPart = emailLocal(email);

      // Build a unique set of candidate handles for this user
      const candidates = new Set([username, emailPart, firstName, displayName].filter(Boolean));
      if (candidates.size === 0) {
        continue; // Nothing to index for this user
      }

      // Write all candidate handles to usernameIndex
      for (const handle of candidates) {
        await db.collection('usernameIndex').doc(handle).set({
          username: handle,
          email: email,
          uid: uid,
          role: role,
          status: status,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        writes += 1;
      }
    }

    console.log(`Done. Wrote/updated ${writes} usernameIndex mappings.`);
    process.exit(0);
  } catch (err) {
    console.error('Seeding failed:', err);
    process.exit(1);
  }
})();
