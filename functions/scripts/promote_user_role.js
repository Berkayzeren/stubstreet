/*
  Purpose: Promote a user's role in Firestore (users/{uid}.role) and optionally status.
  Why: In dev/testing we sometimes need to grant seller/admin permissions to a user quickly.

  Usage examples:
    node scripts/promote_user_role.js --uid <UID> --role seller --status active
    node scripts/promote_user_role.js --username <USERNAME> --role admin

  How it works:
  - Initializes Firebase Admin SDK using the service account key in this folder.
  - Resolves a user document either by provided uid or by querying username.
  - Updates the 'role' (and optionally 'status') fields and prints the before/after.
*/

const path = require('path');
const admin = require('firebase-admin');

// Load service account from functions/serviceAccountKey.json
// We keep this local to the functions workspace as it's already present there.
const serviceAccountPath = path.resolve(__dirname, '..', 'serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(require(serviceAccountPath)),
});

const db = admin.firestore();

/**
 * Parse CLI args of the form --key value
 */
function parseArgs(argv) {
  const args = {};
  for (let i = 2; i < argv.length; i++) {
    const key = argv[i];
    if (key.startsWith('--')) {
      const k = key.replace(/^--/, '');
      const v = argv[i + 1] && !argv[i + 1].startsWith('--') ? argv[++i] : true;
      args[k] = v;
    }
  }
  return args;
}

(async () => {
  const { uid, username, role = 'seller', status, all, onlyMissing, onlyBuyer } = parseArgs(process.argv);

  if (!uid && !username && !all) {
    console.error('ERROR: Provide --uid <UID> or --username <USERNAME> or --all');
    process.exit(1);
  }

  try {
    if (all) {
      // Bulk mode: iterate all users and update per filters
      const usersSnap = await db.collection('users').get();
      let updated = 0;
      for (const doc of usersSnap.docs) {
        const data = doc.data() || {};
        const currentRole = data.role;
        const shouldUpdateMissing = onlyMissing ? !currentRole : true;
        const shouldUpdateBuyer = onlyBuyer ? currentRole === 'buyer' : true;
        if (shouldUpdateMissing && shouldUpdateBuyer) {
          const update = { role };
          if (status) update.status = status;
          await doc.ref.update({
            ...update,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          updated++;
        }
      }
      console.log(`✅ Bulk role update complete. Updated ${updated} users.`);
    } else {
      // Single user update by uid or username
      let userRef;
      if (uid) {
        userRef = db.collection('users').doc(uid);
      } else {
        const snap = await db.collection('users').where('username', '==', username).limit(1).get();
        if (snap.empty) {
          console.error(`ERROR: No user found with username: ${username}`);
          process.exit(1);
        }
        userRef = snap.docs[0].ref;
      }

      const beforeSnap = await userRef.get();
      if (!beforeSnap.exists) {
        console.error('ERROR: User document does not exist.');
        process.exit(1);
      }

      const beforeData = beforeSnap.data() || {};
      const update = { role };
      if (status) update.status = status;

      await userRef.update({
        ...update,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      const afterSnap = await userRef.get();
      const afterData = afterSnap.data() || {};

      console.log('✅ Role update successful');
      console.log('User ID:', afterSnap.id);
      console.log('Before -> role:', beforeData.role, 'status:', beforeData.status);
      console.log('After  -> role:', afterData.role, 'status:', afterData.status);
    }
  } catch (err) {
    console.error('❌ Failed to update user role:', err);
    process.exit(1);
  } finally {
    await admin.app().delete().catch(() => {});
  }
})();
