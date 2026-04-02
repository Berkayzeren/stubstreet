const request = require('supertest');
const express = require('express');
const { mockAdmin, mockFirestore } = require('../mocks/firestore');

// Firebase admin mock'u
jest.mock('firebase-admin', () => mockAdmin);

const app = express();
app.use(express.json());

// Example test endpoints
app.get('/v1/conversations', (req, res) => {
  return res.status(200).json({ success: true, data: [{ id: 'conv1' }], message: 'Conversations başarıyla getirildi' });
});

app.post('/v1/conversations', (req, res) => {
  const { participants } = req.body;
  if (!participants || participants.length < 2) {
    return res.status(422).json({ success: false, error: 'Participants array gerekli' });
  }
  return res.status(201).json({ success: true, data: { id: 'new-conversation-id' }, message: 'Conversation başarıyla oluşturuldu' });
});

// Test scenarios
describe('Conversations API Endpoints', () => {
  describe('GET /v1/conversations', () => {
    test('Should fetch user conversations successfully', async () => {
      const response = await request(app)
        .get('/v1/conversations')
        .expect(200);

      expect(response.body.success).toBe(true);
    });
  });

  describe('POST /v1/conversations', () => {
    test('Should create new conversation successfully', async () => {
      const response = await request(app)
        .post('/v1/conversations')
        .send({ participants: ['user1', 'user2'] })
        .expect(201);

      expect(response.body.success).toBe(true);
    });

    test('Should fail validation on participants', async () => {
      const response = await request(app)
        .post('/v1/conversations')
        .send({ participants: ['user1'] })
        .expect(422);

      expect(response.body.success).toBe(false);
    });
  });
});
