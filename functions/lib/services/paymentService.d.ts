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
export declare class PaymentService {
    static initPayment(req: PaymentRequest): Promise<any>;
    static getPayment(paymentId: string): Promise<any>;
    static getUserPayments(userId: string): Promise<any[]>;
    static updatePaymentStatus(paymentId: string, status: string, additionalData?: any): Promise<void>;
    static handleWebhook(provider: string, req: Request): Promise<void>;
}
