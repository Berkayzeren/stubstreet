// Firestore mock utilities
const mockFirestore = {
  collection: jest.fn(),
  doc: jest.fn(),
  runTransaction: jest.fn(),
  batch: jest.fn(),
  FieldValue: {
    serverTimestamp: jest.fn(() => new Date()),
    arrayUnion: jest.fn((value) => ({ _methodName: 'arrayUnion', _elements: [value] })),
    arrayRemove: jest.fn((value) => ({ _methodName: 'arrayRemove', _elements: [value] })),
    increment: jest.fn((value) => ({ _methodName: 'increment', _operand: value })),
    delete: jest.fn(() => ({ _methodName: 'delete' }))
  }
};

// Mock document snapshot
const createMockDocSnapshot = (data, exists = true, id = 'test-doc-id') => ({
  exists,
  id,
  data: jest.fn(() => data),
  ref: {
    id,
    collection: jest.fn(),
    parent: jest.fn(),
    path: `collections/test/${id}`
  }
});

// Mock query snapshot
const createMockQuerySnapshot = (docs = []) => ({
  docs: docs.map(doc => createMockDocSnapshot(doc.data, true, doc.id)),
  size: docs.length,
  empty: docs.length === 0,
  forEach: jest.fn((callback) => docs.forEach(callback))
});

// Mock document reference
const createMockDocRef = (id = 'test-doc-id') => ({
  id,
  get: jest.fn(),
  set: jest.fn(),
  update: jest.fn(),
  delete: jest.fn(),
  collection: jest.fn(),
  parent: jest.fn(),
  path: `collections/test/${id}`
});

// Mock collection reference
const createMockCollectionRef = () => ({
  add: jest.fn(),
  doc: jest.fn(() => createMockDocRef()),
  where: jest.fn(() => createMockQuery()),
  orderBy: jest.fn(() => createMockQuery()),
  limit: jest.fn(() => createMockQuery()),
  startAfter: jest.fn(() => createMockQuery()),
  get: jest.fn()
});

// Mock query
const createMockQuery = () => ({
  where: jest.fn(() => createMockQuery()),
  orderBy: jest.fn(() => createMockQuery()),
  limit: jest.fn(() => createMockQuery()),
  startAfter: jest.fn(() => createMockQuery()),
  get: jest.fn()
});

// Mock auth
const mockAuth = {
  verifyIdToken: jest.fn(),
  createCustomToken: jest.fn(),
  getUser: jest.fn(),
  createUser: jest.fn(),
  updateUser: jest.fn(),
  deleteUser: jest.fn(),
  listUsers: jest.fn()
};

// Mock Firebase Admin
const mockAdmin = {
  firestore: jest.fn(() => mockFirestore),
  auth: jest.fn(() => mockAuth),
  storage: jest.fn(() => ({
    bucket: jest.fn(() => ({
      file: jest.fn(() => ({
        exists: jest.fn(() => Promise.resolve([true])),
        delete: jest.fn(() => Promise.resolve()),
        download: jest.fn(() => Promise.resolve([Buffer.from('test')])),
        save: jest.fn(() => Promise.resolve()),
        getSignedUrl: jest.fn(() => Promise.resolve(['https://test-url.com']))
      }))
    }))
  })),
  initializeApp: jest.fn(),
  FieldValue: mockFirestore.FieldValue
};

module.exports = {
  mockFirestore,
  mockAuth,
  mockAdmin,
  createMockDocSnapshot,
  createMockQuerySnapshot,
  createMockDocRef,
  createMockCollectionRef,
  createMockQuery
};
