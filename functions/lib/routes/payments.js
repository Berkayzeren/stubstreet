"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const express_validator_1 = require("express-validator");
const admin = __importStar(require("firebase-admin"));
const paymentService_1 = require("../services/paymentService");
const authMiddleware_1 = __importDefault(require("../middleware/authMiddleware"));
const responseHelper_1 = require("../utils/responseHelper");
// Helper function to send response
function sendResponse(res, status, message, data, errors) {
    if (status >= 200 && status < 300) {
        return (0, responseHelper_1.successResponse)(res, data, message, status);
    }
    else {
        return (0, responseHelper_1.errorResponse)(res, message, status, errors);
    }
}
const router = (0, express_1.Router)();
// Validation middleware
const validatePaymentRequest = [
    (0, express_validator_1.body)('amount')
        .isFloat({ min: 0.01 })
        .withMessage('Amount must be a positive number'),
    (0, express_validator_1.body)('currency')
        .isIn(['USD', 'EUR', 'TRY'])
        .withMessage('Currency must be USD, EUR, or TRY'),
    (0, express_validator_1.body)('provider')
        .isIn(['paytr'])
        .withMessage('Provider must be paytr'),
    (0, express_validator_1.body)('description')
        .optional()
        .isString()
        .withMessage('Description must be a string'),
    (0, express_validator_1.body)('email')
        .optional()
        .isEmail()
        .withMessage('Email must be valid'),
];
// Initialize payment
router.post('/initialize', authMiddleware_1.default, validatePaymentRequest, async (req, res) => {
    var _a;
    try {
        const errors = (0, express_validator_1.validationResult)(req);
        if (!errors.isEmpty()) {
            return sendResponse(res, 400, 'Validation failed', null, errors.array());
        }
        const { amount, currency, provider, description, email, metadata } = req.body;
        const userId = (_a = req.user) === null || _a === void 0 ? void 0 : _a.uid;
        if (!userId) {
            return sendResponse(res, 401, 'User not authenticated');
        }
        const paymentRequest = {
            amount,
            currency,
            provider,
            userId,
            description,
            email,
            metadata,
        };
        const result = await paymentService_1.PaymentService.initPayment(paymentRequest);
        sendResponse(res, 200, 'Payment initialized successfully', result);
    }
    catch (error) {
        console.error('Payment initialization error:', error);
        sendResponse(res, 500, 'Failed to initialize payment', null, error.message);
    }
});
// Get payment by ID
router.get('/:paymentId', authMiddleware_1.default, async (req, res) => {
    var _a;
    try {
        const { paymentId } = req.params;
        const userId = (_a = req.user) === null || _a === void 0 ? void 0 : _a.uid;
        if (!userId) {
            return sendResponse(res, 401, 'User not authenticated');
        }
        const payment = await paymentService_1.PaymentService.getPayment(paymentId);
        // Check if the payment belongs to the authenticated user
        if (payment.userId !== userId) {
            return sendResponse(res, 403, 'Access denied');
        }
        sendResponse(res, 200, 'Payment retrieved successfully', payment);
    }
    catch (error) {
        console.error('Get payment error:', error);
        if (error.message === 'Payment not found') {
            sendResponse(res, 404, 'Payment not found');
        }
        else {
            sendResponse(res, 500, 'Failed to retrieve payment', null, error.message);
        }
    }
});
// Get user payments
router.get('/user/payments', authMiddleware_1.default, async (req, res) => {
    var _a;
    try {
        const userId = (_a = req.user) === null || _a === void 0 ? void 0 : _a.uid;
        if (!userId) {
            return sendResponse(res, 401, 'User not authenticated');
        }
        const payments = await paymentService_1.PaymentService.getUserPayments(userId);
        sendResponse(res, 200, 'User payments retrieved successfully', payments);
    }
    catch (error) {
        console.error('Get user payments error:', error);
        sendResponse(res, 500, 'Failed to retrieve user payments', null, error.message);
    }
});
// Update payment status (admin only)
router.patch('/:paymentId/status', authMiddleware_1.default, async (req, res) => {
    var _a, _b;
    try {
        const { paymentId } = req.params;
        const { status, additionalData } = req.body;
        const userId = (_a = req.user) === null || _a === void 0 ? void 0 : _a.uid;
        if (!userId) {
            return sendResponse(res, 401, 'User not authenticated');
        }
        // Check if user is admin (you can implement your own admin check logic)
        const userRecord = await admin.auth().getUser(userId);
        if (!((_b = userRecord.customClaims) === null || _b === void 0 ? void 0 : _b.admin)) {
            return sendResponse(res, 403, 'Admin access required');
        }
        await paymentService_1.PaymentService.updatePaymentStatus(paymentId, status, additionalData);
        sendResponse(res, 200, 'Payment status updated successfully');
    }
    catch (error) {
        console.error('Update payment status error:', error);
        sendResponse(res, 500, 'Failed to update payment status', null, error.message);
    }
});
// PayTR webhook endpoint will be added here when needed
exports.default = router;
//# sourceMappingURL=payments.js.map