const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');

// Firebase emulator environment variables
process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST = 'localhost:9099';
process.env.FIREBASE_STORAGE_EMULATOR_HOST = 'localhost:9199';

// Payment provider sandbox keys
process.env.DOMAIN = 'http://localhost:3000';

// Initialize Firebase Admin for testing
const testApp = initializeApp({
  projectId: 'stubstreet-test'
});

// Global test variables
global.testApp = testApp;
global.testDb = getFirestore(testApp);
global.testAuth = getAuth(testApp);

// Payment provider mocks removed - using placeholder implementation


// Mock Firebase Functions
jest.mock('firebase-functions', () => ({
  runWith: jest.fn(() => ({
    https: {
      onRequest: jest.fn((app) => app),
    },
  })),
  config: jest.fn(() => ({
  })),
  logger: {
    info: jest.fn(),
    error: jest.fn(),
    warn: jest.fn(),
  },
}));

// Mock Socket.IO
jest.mock('socket.io', () => ({
  Server: jest.fn(() => ({
    use: jest.fn(),
    on: jest.fn(),
    to: jest.fn(() => ({
      emit: jest.fn(),
    })),
    emit: jest.fn(),
  })),
}));

// Global test helpers
global.testHelpers = {
  createMockUser: () => ({
    uid: 'test-user-id',
    email: 'test@example.com',
    name: 'Test User',
  }),
  
  createMockPaymentRequest: () => ({
    amount: 100,
    currency: 'USD',
    provider: 'placeholder',
    userId: 'test-user-id',
    description: 'Test payment',
    email: 'test@example.com',
  }),
  
  createMockPaymentIntent: () => ({
    id: 'pi_test_123',
    client_secret: 'pi_test_123_secret',
    amount: 10000,
    currency: 'usd',
    status: 'requires_payment_method',
    metadata: {
      userId: 'test-user-id',
      paymentId: 'test-payment-id',
    },
  }),
  
  waitFor: (ms) => new Promise(resolve => setTimeout(resolve, ms)),
};

// Jest global setup
beforeAll(async () => {
  console.log('Jest test setup başlatıldı - Firebase emülatörü bağlantısı');
});

afterAll(async () => {
  console.log('Jest test setup tamamlandı');
});

// Her test sonrası temizlik
afterEach(async () => {
  jest.clearAllMocks();
});
