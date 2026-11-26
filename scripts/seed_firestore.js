/**
 * SaveSmart — Firestore seed script
 *
 * Creates one admin user, one regular user, two goals with transactions,
 * two tips, and one open feedback document so you can test the app and
 * admin dashboard without signing up manually.
 *
 * Usage:
 *   npm install firebase-admin
 *   node scripts/seed_firestore.js
 *
 * Requirements:
 *   Set GOOGLE_APPLICATION_CREDENTIALS to your Firebase service account key.
 *   Download it from: Firebase console → Project settings → Service accounts
 *   → Generate new private key → save as serviceAccountKey.json
 *
 *   export GOOGLE_APPLICATION_CREDENTIALS="./serviceAccountKey.json"
 */

const admin = require('firebase-admin');

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

const db = admin.firestore();

// ── Helper ────────────────────────────────────────────────────────────────────
const ts = (date) => admin.firestore.Timestamp.fromDate(new Date(date));
const now = () => admin.firestore.FieldValue.serverTimestamp();

async function seed() {
  console.log('🌱  Starting seed...');

  // ── Users ─────────────────────────────────────────────────────────────────
  // NOTE: These UIDs are placeholders. After you register in the app,
  // update these to real UIDs from Firebase Auth console.
  const regularUid  = 'REPLACE_WITH_REAL_USER_UID';
  const adminUid    = 'REPLACE_WITH_REAL_ADMIN_UID';

  await db.collection('users').doc(regularUid).set({
    name:      'Abebe Kebede',
    email:     'abebe@example.com',
    currency:  'ETB',
    language:  'am',
    role:      'user',
    status:    'active',
    createdAt: ts('2024-01-15'),
    fcmToken:  null,
  });
  console.log('  ✓ Regular user created');

  await db.collection('users').doc(adminUid).set({
    name:      'Admin User',
    email:     'admin@savesmart.et',
    currency:  'ETB',
    language:  'en',
    role:      'admin',
    status:    'active',
    createdAt: ts('2024-01-01'),
    fcmToken:  null,
  });
  console.log('  ✓ Admin user created');

  // ── Goals ─────────────────────────────────────────────────────────────────
  const goal1Id = 'goal_laptop_01';
  await db.collection('users').doc(regularUid)
    .collection('goals').doc(goal1Id).set({
      userId:            regularUid,
      title:             'Buy a Laptop',
      category:          'laptop',
      targetAmount:      25000,
      currentAmount:     8500,
      deadline:          ts('2025-06-30'),
      status:            'active',
      createdAt:         ts('2024-11-01'),
      streak:            3,
      lastSavedAt:       ts('2024-11-20'),
      achievedMilestones:[25],
      colorHex:          '#1565C0',
    });
  console.log('  ✓ Goal 1 created (laptop)');

  const goal2Id = 'goal_emergency_01';
  await db.collection('users').doc(regularUid)
    .collection('goals').doc(goal2Id).set({
      userId:            regularUid,
      title:             'Emergency Fund',
      category:          'emergency_fund',
      targetAmount:      10000,
      currentAmount:     10000,
      deadline:          ts('2024-12-31'),
      status:            'completed',
      createdAt:         ts('2024-06-01'),
      streak:            12,
      lastSavedAt:       ts('2024-11-15'),
      achievedMilestones:[25, 50, 75, 100],
      colorHex:          null,
    });
  console.log('  ✓ Goal 2 created (emergency fund — completed)');

  // ── Transactions for Goal 1 ───────────────────────────────────────────────
  const txRef1 = db.collection('users').doc(regularUid)
    .collection('goals').doc(goal1Id)
    .collection('transactions');

  const transactions = [
    { goalId: goal1Id, amount: 2000, date: ts('2024-11-01'), savedIn: 'Bank',          note: 'First deposit',       createdAt: ts('2024-11-01') },
    { goalId: goal1Id, amount: 1500, date: ts('2024-11-08'), savedIn: 'Cash at home',  note: null,                  createdAt: ts('2024-11-08') },
    { goalId: goal1Id, amount: 2000, date: ts('2024-11-15'), savedIn: 'Mobile wallet', note: 'Salary bonus',        createdAt: ts('2024-11-15') },
    { goalId: goal1Id, amount: 1500, date: ts('2024-11-20'), savedIn: 'Bank',          note: 'Weekly contribution', createdAt: ts('2024-11-20') },
    { goalId: goal1Id, amount: 1500, date: ts('2024-11-05'), savedIn: 'Savings group', note: 'Iqub contribution',   createdAt: ts('2024-11-05') },
  ];

  for (let i = 0; i < transactions.length; i++) {
    await txRef1.doc(`tx_laptop_0${i + 1}`).set(transactions[i]);
  }
  console.log('  ✓ Transactions created for Goal 1');

  // ── Tips ──────────────────────────────────────────────────────────────────
  await db.collection('tips').doc('tip_01').set({
    message:   'Save first, spend what is left. Even 50 ETB a week becomes 2,600 ETB in a year.',
    createdAt: ts('2024-11-20'),
    createdBy: adminUid,
  });

  await db.collection('tips').doc('tip_02').set({
    message:   'Use an Iqub (savings group) with trusted friends to save larger amounts faster.',
    createdAt: ts('2024-11-15'),
    createdBy: adminUid,
  });
  console.log('  ✓ Tips created');

  // ── Feedback ──────────────────────────────────────────────────────────────
  await db.collection('feedback').doc('feedback_01').set({
    userId:    regularUid,
    message:   'The app is very helpful! Could you add Tigrinya language support?',
    status:    'open',
    reply:     null,
    createdAt: ts('2024-11-18'),
  });
  console.log('  ✓ Feedback created');

  // ── Categories (synced with app defaults) ─────────────────────────────────
  const categories = [
    { name: 'School Fees',    id: 'school_fees'    },
    { name: 'Phone',          id: 'phone'          },
    { name: 'Laptop',         id: 'laptop'         },
    { name: 'Emergency Fund', id: 'emergency_fund' },
    { name: 'Business',       id: 'business'       },
    { name: 'Wedding',        id: 'wedding'        },
    { name: 'Other',          id: 'other'          },
  ];
  for (const cat of categories) {
    await db.collection('categories').doc(cat.id).set({ name: cat.name });
  }
  console.log('  ✓ Categories seeded');

  console.log('\n✅  Seed complete!');
  console.log('\n⚠️   Remember to replace REPLACE_WITH_REAL_USER_UID and');
  console.log('    REPLACE_WITH_REAL_ADMIN_UID with actual Firebase Auth UIDs.');
  process.exit(0);
}

seed().catch((err) => {
  console.error('❌  Seed failed:', err);
  process.exit(1);
});
