/* eslint-disable max-len, quotes, camelcase, object-curly-spacing, import/no-duplicates, @typescript-eslint/no-explicit-any, comma-dangle */
import * as functionsV1 from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import express from 'express';
import cors from 'cors';
import { Request, Response } from 'express';
import * as crypto from 'crypto';

admin.initializeApp();
const db = admin.firestore();

const app = express();
app.use(cors());
app.use(express.json());

// PayTR credentials: prefer environment variables, fall back to functions config
const PAYTR_MERCHANT_ID = process.env.PAYTR_MERCHANT_ID || functionsV1.config().paytr?.merchant_id;
const PAYTR_MERCHANT_KEY = process.env.PAYTR_MERCHANT_KEY || functionsV1.config().paytr?.merchant_key;
const PAYTR_MERCHANT_SALT = process.env.PAYTR_MERCHANT_SALT || functionsV1.config().paytr?.merchant_salt;

// Health check endpoint
app.get('/health', (req: Request, res: Response) => {
  res.json({ status: 'OK' });
});

// POST /v1/paytr/initialize
app.post('/v1/paytr/initialize', async (req: Request, res: Response) => {
  try {
    if (!PAYTR_MERCHANT_ID || !PAYTR_MERCHANT_KEY || !PAYTR_MERCHANT_SALT) {
      return res.status(500).json({ success: false, error: 'PAYTR credentials missing' });
    }

    const {
      email,
      amount,
      currency = 'TL',
      orderId,
      customerIp,
      basket = [],
      okUrl,
      failUrl,
      installmentCount = '0',
      testMode = '1',
      paymentType = 'card',
      non3d = '0',
      clientLang = 'tr',
      userName = '',
      userAddress = '',
      userPhone = '',
    } = (req.body || {}) as Record<string, any>;

    if (!email || !amount || !orderId || !okUrl || !failUrl) {
      return res.status(400).json({ success: false, error: 'Missing required fields' });
    }

    const merchant_oid = String(orderId);
    const user_ip = (customerIp || req.headers['x-forwarded-for'] || req.socket.remoteAddress || '') as string;
    const payment_amount = String(amount);

    const hashStr = `${PAYTR_MERCHANT_ID}${user_ip}${merchant_oid}${email}${payment_amount}${paymentType}${installmentCount}${currency}${testMode}${non3d}`;
    const paytrTokenRaw = `${hashStr}${PAYTR_MERCHANT_SALT}`;
    const token = crypto.createHmac('sha256', PAYTR_MERCHANT_KEY as string).update(paytrTokenRaw).digest('base64');

    return res.status(200).json({
      success: true,
      data: {
        merchant_id: PAYTR_MERCHANT_ID,
        user_ip,
        merchant_oid,
        email,
        payment_type: paymentType,
        payment_amount,
        currency,
        test_mode: testMode,
        non_3d: non3d,
        merchant_ok_url: okUrl,
        merchant_fail_url: failUrl,
        user_name: userName,
        user_address: userAddress,
        user_phone: userPhone,
        user_basket: JSON.stringify(basket),
        debug_on: 1,
        client_lang: clientLang,
        token,
        installment_count: installmentCount,
      },
    });
  } catch (e: any) {
    console.error('PayTR initialize error:', e?.message || e);
    return res.status(500).json({ success: false, error: e?.message || 'PayTR initialization failed', message: 'Payment initialization failed. Please try again.' });
  }
});

// POST /v1/paytr/callback
app.post('/v1/paytr/callback', async (req: Request, res: Response) => {
  try {
    if (!PAYTR_MERCHANT_ID || !PAYTR_MERCHANT_KEY || !PAYTR_MERCHANT_SALT) {
      return res.status(200).send('OK');
    }

    const {
      merchant_oid,
      status,
      total_amount,
      hash,
      failed_reason_code,
      failed_reason_msg,
      test_mode,
      payment_type,
      currency,
      payment_amount,
    } = req.body;

    // Hash doğrulama
    const hashStr = `${merchant_oid}${PAYTR_MERCHANT_SALT}${status}${total_amount}`;
    const calculatedHash = crypto.createHmac('sha256', PAYTR_MERCHANT_KEY as string).update(hashStr).digest('base64');

    if (hash !== calculatedHash) {
      console.error('PayTR callback hash mismatch');
      return res.status(200).send('OK');
    }

    // Payment durumunu Firestore'a kaydet
    const paymentData = {
      orderId: merchant_oid,
      status,
      totalAmount: total_amount,
      paymentAmount: payment_amount,
      currency,
      paymentType: payment_type,
      testMode: test_mode,
      failedReasonCode: failed_reason_code || null,
      failedReasonMsg: failed_reason_msg || null,
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
      hash,
    };

    await db.collection('payments').doc(merchant_oid).set(paymentData, { merge: true });

    console.log(`PayTR callback processed for order ${merchant_oid}, status: ${status}`);
    return res.status(200).send('OK');
  } catch (e: any) {
    console.error('PayTR callback error:', e?.message || e);
    return res.status(200).send('OK');
  }
});

// Export the Express app as a Cloud Function
export const api = functionsV1.https.onRequest(app);
