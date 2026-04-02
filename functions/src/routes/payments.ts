import { Request, Response, Router } from 'express';
import { body, validationResult } from 'express-validator';
import * as admin from 'firebase-admin';
import { PaymentService, PaymentRequest } from '../services/paymentService';
import authMiddleware from '../middleware/authMiddleware';
import { errorResponse, successResponse } from '../utils/responseHelper';

// Extend Request type to include user property
interface AuthenticatedRequest extends Request {
  user?: admin.auth.DecodedIdToken;
}

// Helper function to send response
function sendResponse(res: Response, status: number, message: string, data?: any, errors?: any) {
  if (status >= 200 && status < 300) {
    return successResponse(res, data, message, status);
  } else {
    return errorResponse(res, message, status, errors);
  }
}

const router = Router();

// Validation middleware
const validatePaymentRequest = [
  body('amount')
    .isFloat({ min: 0.01 })
    .withMessage('Amount must be a positive number'),
  body('currency')
    .isIn(['USD', 'EUR', 'TRY'])
    .withMessage('Currency must be USD, EUR, or TRY'),
  body('provider')
    .isIn(['paytr'])
    .withMessage('Provider must be paytr'),
  body('description')
    .optional()
    .isString()
    .withMessage('Description must be a string'),
  body('email')
    .optional()
    .isEmail()
    .withMessage('Email must be valid'),
];

// Initialize payment
router.post('/initialize', authMiddleware, validatePaymentRequest, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return sendResponse(res, 400, 'Validation failed', null, errors.array());
    }

    const { amount, currency, provider, description, email, metadata } = req.body;
    const userId = req.user?.uid;

    if (!userId) {
      return sendResponse(res, 401, 'User not authenticated');
    }

    const paymentRequest: PaymentRequest = {
      amount,
      currency,
      provider,
      userId,
      description,
      email,
      metadata,
    };

    const result = await PaymentService.initPayment(paymentRequest);
    
    sendResponse(res, 200, 'Payment initialized successfully', result);
  } catch (error) {
    console.error('Payment initialization error:', error);
    sendResponse(res, 500, 'Failed to initialize payment', null, error.message);
  }
});

// Get payment by ID
router.get('/:paymentId', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { paymentId } = req.params;
    const userId = req.user?.uid;

    if (!userId) {
      return sendResponse(res, 401, 'User not authenticated');
    }

    const payment = await PaymentService.getPayment(paymentId);
    
    // Check if the payment belongs to the authenticated user
    if (payment.userId !== userId) {
      return sendResponse(res, 403, 'Access denied');
    }

    sendResponse(res, 200, 'Payment retrieved successfully', payment);
  } catch (error) {
    console.error('Get payment error:', error);
    if (error.message === 'Payment not found') {
      sendResponse(res, 404, 'Payment not found');
    } else {
      sendResponse(res, 500, 'Failed to retrieve payment', null, error.message);
    }
  }
});

// Get user payments
router.get('/user/payments', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user?.uid;

    if (!userId) {
      return sendResponse(res, 401, 'User not authenticated');
    }

    const payments = await PaymentService.getUserPayments(userId);
    
    sendResponse(res, 200, 'User payments retrieved successfully', payments);
  } catch (error) {
    console.error('Get user payments error:', error);
    sendResponse(res, 500, 'Failed to retrieve user payments', null, error.message);
  }
});

// Update payment status (admin only)
router.patch('/:paymentId/status', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { paymentId } = req.params;
    const { status, additionalData } = req.body;
    const userId = req.user?.uid;

    if (!userId) {
      return sendResponse(res, 401, 'User not authenticated');
    }

    // Check if user is admin (you can implement your own admin check logic)
    const userRecord = await admin.auth().getUser(userId);
    if (!userRecord.customClaims?.admin) {
      return sendResponse(res, 403, 'Admin access required');
    }

    await PaymentService.updatePaymentStatus(paymentId, status, additionalData);
    
    sendResponse(res, 200, 'Payment status updated successfully');
  } catch (error) {
    console.error('Update payment status error:', error);
    sendResponse(res, 500, 'Failed to update payment status', null, error.message);
  }
});

// PayTR webhook endpoint will be added here when needed



export default router;
