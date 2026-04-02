const request = require('supertest');
const express = require('express');
const paymentRoutes = require('../../src/routes/payments');
const { PaymentService } = require('../../src/services/paymentService');

// Mock PaymentService
jest.mock('../../src/services/paymentService');

// Mock authMiddleware
jest.mock('../../src/middleware/authMiddleware', () => {
  return (req, res, next) => {
    req.user = global.testHelpers.createMockUser();
    next();
  };
});

describe('Payment Routes', () => {
  let app;
  let mockPaymentService;

  beforeEach(() => {
    // Express app setup
    app = express();
    app.use(express.json());
    app.use('/api/payments', paymentRoutes);

    // Mock PaymentService methods
    mockPaymentService = {
      initPayment: jest.fn(),
      getPayment: jest.fn(),
      getUserPayments: jest.fn(),
      updatePaymentStatus: jest.fn(),
      handleWebhook: jest.fn(),
    };

    // Apply mocks to PaymentService
    PaymentService.initPayment = mockPaymentService.initPayment;
    PaymentService.getPayment = mockPaymentService.getPayment;
    PaymentService.getUserPayments = mockPaymentService.getUserPayments;
    PaymentService.updatePaymentStatus = mockPaymentService.updatePaymentStatus;
    PaymentService.handleWebhook = mockPaymentService.handleWebhook;
  });

  describe('POST /api/payments/initialize', () => {
    it('should initialize payment successfully', async () => {
      const paymentRequest = {
        amount: 100,
        currency: 'USD',
        provider: 'placeholder',
        description: 'Test payment',
        email: 'test@example.com',
      };

      const mockResponse = {
        paymentId: 'test-payment-id',
        status: 'requires_payment_method',
        clientSecret: 'pi_test_123_secret',
      };

      mockPaymentService.initPayment.mockResolvedValue(mockResponse);

      const response = await request(app)
        .post('/api/payments/initialize')
        .send(paymentRequest)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toEqual(mockResponse);
      expect(mockPaymentService.initPayment).toHaveBeenCalledWith(
        expect.objectContaining({
          ...paymentRequest,
          userId: 'test-user-id',
        })
      );
    });

    it('should return validation error for invalid amount', async () => {
      const paymentRequest = {
        amount: -10, // Invalid amount
        currency: 'USD',
        provider: 'placeholder',
      };

      const response = await request(app)
        .post('/api/payments/initialize')
        .send(paymentRequest)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toBe('Validation failed');
      expect(mockPaymentService.initPayment).not.toHaveBeenCalled();
    });

    it('should return validation error for invalid currency', async () => {
      const paymentRequest = {
        amount: 100,
        currency: 'INVALID', // Invalid currency
        provider: 'placeholder',
      };

      const response = await request(app)
        .post('/api/payments/initialize')
        .send(paymentRequest)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toBe('Validation failed');
      expect(mockPaymentService.initPayment).not.toHaveBeenCalled();
    });

    it('should return validation error for invalid provider', async () => {
      const paymentRequest = {
        amount: 100,
        currency: 'USD',
        provider: 'invalid-provider', // Invalid provider
      };

      const response = await request(app)
        .post('/api/payments/initialize')
        .send(paymentRequest)
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toBe('Validation failed');
      expect(mockPaymentService.initPayment).not.toHaveBeenCalled();
    });

    it('should handle payment service error', async () => {
      const paymentRequest = {
        amount: 100,
        currency: 'USD',
        provider: 'placeholder',
      };

      mockPaymentService.initPayment.mockRejectedValue(new Error('Payment service error'));

      const response = await request(app)
        .post('/api/payments/initialize')
        .send(paymentRequest)
        .expect(500);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toBe('Failed to initialize payment');
      expect(mockPaymentService.initPayment).toHaveBeenCalled();
    });
  });

  describe('GET /api/payments/:paymentId', () => {
    it('should get payment successfully', async () => {
      const paymentId = 'test-payment-id';
      const mockPayment = {
        paymentId,
        amount: 100,
        currency: 'USD',
        status: 'completed',
        userId: 'test-user-id',
      };

      mockPaymentService.getPayment.mockResolvedValue(mockPayment);

      const response = await request(app)
        .get(`/api/payments/${paymentId}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toEqual(mockPayment);
      expect(mockPaymentService.getPayment).toHaveBeenCalledWith(paymentId);
    });

    it('should return 403 for unauthorized access', async () => {
      const paymentId = 'test-payment-id';
      const mockPayment = {
        paymentId,
        amount: 100,
        currency: 'USD',
        status: 'completed',
        userId: 'different-user-id', // Different user
      };

      mockPaymentService.getPayment.mockResolvedValue(mockPayment);

      const response = await request(app)
        .get(`/api/payments/${paymentId}`)
        .expect(403);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toBe('Access denied');
    });

    it('should return 404 for non-existent payment', async () => {
      const paymentId = 'non-existent-payment';

      mockPaymentService.getPayment.mockRejectedValue(new Error('Payment not found'));

      const response = await request(app)
        .get(`/api/payments/${paymentId}`)
        .expect(404);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toBe('Payment not found');
    });

    it('should handle service error', async () => {
      const paymentId = 'test-payment-id';

      mockPaymentService.getPayment.mockRejectedValue(new Error('Database error'));

      const response = await request(app)
        .get(`/api/payments/${paymentId}`)
        .expect(500);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toBe('Failed to retrieve payment');
    });
  });

  describe('GET /api/payments/user/payments', () => {
    it('should get user payments successfully', async () => {
      const mockPayments = [
        { id: 'payment-1', amount: 100, status: 'completed' },
        { id: 'payment-2', amount: 200, status: 'pending' },
      ];

      mockPaymentService.getUserPayments.mockResolvedValue(mockPayments);

      const response = await request(app)
        .get('/api/payments/user/payments')
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toEqual(mockPayments);
      expect(mockPaymentService.getUserPayments).toHaveBeenCalledWith('test-user-id');
    });

    it('should handle service error', async () => {
      mockPaymentService.getUserPayments.mockRejectedValue(new Error('Database error'));

      const response = await request(app)
        .get('/api/payments/user/payments')
        .expect(500);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toBe('Failed to retrieve user payments');
    });
  });

  describe('PATCH /api/payments/:paymentId/status', () => {
    // Mock admin user
    const mockAdminAuthMiddleware = (req, res, next) => {
      req.user = {
        ...global.testHelpers.createMockUser(),
        customClaims: { admin: true },
      };
      next();
    };

    beforeEach(() => {
      // Mock admin auth for admin routes
      jest.doMock('../../src/middleware/authMiddleware', () => mockAdminAuthMiddleware);
      
      // Mock Firebase Admin Auth
      const mockGetUser = jest.fn().mockResolvedValue({
        customClaims: { admin: true },
      });
      
      require('firebase-admin').auth = jest.fn(() => ({
        getUser: mockGetUser,
      }));
    });

    it('should update payment status successfully (admin)', async () => {
      const paymentId = 'test-payment-id';
      const updateData = {
        status: 'completed',
        additionalData: { completedAt: new Date() },
      };

      // Mock Firebase Admin Auth for admin check
      const mockAdmin = require('firebase-admin');
      mockAdmin.auth().getUser.mockResolvedValue({
        customClaims: { admin: true },
      });

      mockPaymentService.updatePaymentStatus.mockResolvedValue();

      const response = await request(app)
        .patch(`/api/payments/${paymentId}/status`)
        .send(updateData)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.message).toBe('Payment status updated successfully');
      expect(mockPaymentService.updatePaymentStatus).toHaveBeenCalledWith(
        paymentId,
        updateData.status,
        updateData.additionalData
      );
    });

    it('should return 403 for non-admin user', async () => {
      const paymentId = 'test-payment-id';
      const updateData = {
        status: 'completed',
      };

      // Mock Firebase Admin Auth for non-admin check
      const mockAdmin = require('firebase-admin');
      mockAdmin.auth().getUser.mockResolvedValue({
        customClaims: {},
      });

      const response = await request(app)
        .patch(`/api/payments/${paymentId}/status`)
        .send(updateData)
        .expect(403);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toBe('Admin access required');
      expect(mockPaymentService.updatePaymentStatus).not.toHaveBeenCalled();
    });

    it('should handle service error', async () => {
      const paymentId = 'test-payment-id';
      const updateData = {
        status: 'completed',
      };

      // Mock Firebase Admin Auth for admin check
      const mockAdmin = require('firebase-admin');
      mockAdmin.auth().getUser.mockResolvedValue({
        customClaims: { admin: true },
      });

      mockPaymentService.updatePaymentStatus.mockRejectedValue(new Error('Update failed'));

      const response = await request(app)
        .patch(`/api/payments/${paymentId}/status`)
        .send(updateData)
        .expect(500);

      expect(response.body.success).toBe(false);
      expect(response.body.message).toBe('Failed to update payment status');
    });
  });

  describe('POST /api/payments/webhook', () => {
    it('should handle payment webhook successfully', async () => {
      const webhookData = {
        type: 'payment_intent.succeeded',
        data: {
          object: {
            id: 'pi_test_123',
            metadata: { paymentId: 'test-payment-id' },
          },
        },
      };

      mockPaymentService.handleWebhook.mockResolvedValue();

      const response = await request(app)
        .post('/api/payments/webhook')
        .send(webhookData)
        .expect(200);

      expect(response.text).toBe('Webhook handled successfully');
      expect(mockPaymentService.handleWebhook).toHaveBeenCalledWith(
        'placeholder',
        expect.objectContaining({ body: webhookData })
      );
    });

    it('should handle webhook error', async () => {
      const webhookData = {
        type: 'payment_intent.succeeded',
        data: {
          object: {
            id: 'pi_test_123',
            metadata: { paymentId: 'test-payment-id' },
          },
        },
      };

      mockPaymentService.handleWebhook.mockRejectedValue(new Error('Webhook error'));

      const response = await request(app)
        .post('/api/payments/webhook')
        .send(webhookData)
        .expect(400);

      expect(response.text).toBe('Webhook failed');
    });
  });


});
