import { Request } from 'express';

export interface PaymentRequest {
  amount: number | string;
  currency: 'USD' | 'EUR' | 'TRY' | string;
  provider: string;
  userId: string;
  description?: string;
  email?: string;
  metadata?: Record<string, any>;
}

export class PaymentService {
  static async initPayment(req: PaymentRequest): Promise<any> {
    return { id: 'dummy_payment', clientSecret: 'dummy_secret', ...req };
  }

  static async getPayment(paymentId: string): Promise<any> {
    return { id: paymentId, userId: 'dummy_user', status: 'created' };
  }

  static async getUserPayments(userId: string): Promise<any[]> {
    return [{ id: 'p1', userId, status: 'created' }];
  }

  static async updatePaymentStatus(paymentId: string, status: string, additionalData?: any): Promise<void> {
    return;
  }

  static async handleWebhook(provider: string, req: Request): Promise<void> {
    return;
  }
}


