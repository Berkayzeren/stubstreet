"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PaymentService = void 0;
class PaymentService {
    static async initPayment(req) {
        return Object.assign({ id: 'dummy_payment', clientSecret: 'dummy_secret' }, req);
    }
    static async getPayment(paymentId) {
        return { id: paymentId, userId: 'dummy_user', status: 'created' };
    }
    static async getUserPayments(userId) {
        return [{ id: 'p1', userId, status: 'created' }];
    }
    static async updatePaymentStatus(paymentId, status, additionalData) {
        return;
    }
    static async handleWebhook(provider, req) {
        return;
    }
}
exports.PaymentService = PaymentService;
//# sourceMappingURL=paymentService.js.map