const { createServer } = require('http');
const { Server } = require('socket.io');
const Client = require('socket.io-client');
const { mockAdmin } = require('../mocks/firestore');

// Mock Firebase admin
jest.mock('firebase-admin', () => mockAdmin);

describe('WebSocket Event Akışı', () => {
  let io, server, clientSocket;

  beforeAll((done) => {
    server = createServer();
    io = new Server(server);
    
    // Mock auth middleware
    io.use(async (socket, next) => {
      const token = socket.handshake.auth.token;
      if (token === 'valid-token') {
        socket.user = { uid: 'test-user-id' };
        next();
      } else {
        next(new Error('Authentication error'));
      }
    });

    server.listen(() => {
      const port = server.address().port;
      clientSocket = new Client(`http://localhost:${port}`, {
        auth: {
          token: 'valid-token'
        }
      });
      
      io.on('connection', (socket) => {
        // Socket event handlers
        socket.on('joinConversation', (conversationId) => {
          socket.join(conversationId);
          socket.emit('joined', { conversationId });
        });

        socket.on('message', (data) => {
          socket.to(data.conversationId).emit('message', data);
        });
      });
      
      clientSocket.on('connect', done);
    });
  });

  afterAll(() => {
    server.close();
    clientSocket.close();
  });

  describe('Bağlantı Durumu', () => {
    test('Client başarıyla bağlanmalı', (done) => {
      expect(clientSocket.connected).toBe(true);
      done();
    });

    test('Geçersiz token ile bağlantı reddedilmeli', (done) => {
      const invalidClient = new Client(`http://localhost:${server.address().port}`, {
        auth: {
          token: 'invalid-token'
        }
      });

      invalidClient.on('connect_error', (error) => {
        expect(error.message).toBe('Authentication error');
        invalidClient.close();
        done();
      });
    });
  });

  describe('Conversation Event\'leri', () => {
    test('joinConversation event', (done) => {
      clientSocket.on('joined', (data) => {
        expect(data.conversationId).toBe('test-conversation-id');
        done();
      });

      clientSocket.emit('joinConversation', 'test-conversation-id');
    });
  });
});
