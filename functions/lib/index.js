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
var _a, _b, _c;
Object.defineProperty(exports, "__esModule", { value: true });
exports.api = void 0;
/* eslint-disable max-len, quotes, camelcase, object-curly-spacing, import/no-duplicates, @typescript-eslint/no-explicit-any, comma-dangle */
const functionsV1 = __importStar(require("firebase-functions/v1"));
const admin = __importStar(require("firebase-admin"));
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const crypto = __importStar(require("crypto"));
// Security middleware imports
const { rateLimiter } = require('../middleware/rateLimiter');
const { securityHeaders, advancedSecurityHeaders } = require('../middleware/securityHeaders');
const { botProtection } = require('../middleware/botProtection');
const authMiddleware = require('../middleware/authMiddleware');
admin.initializeApp();
const db = admin.firestore();
const app = (0, express_1.default)();
// CORS configuration
const corsOptions = {
    origin: (origin, callback) => {
        const allowedOrigins = [
            'https://biletsokagi.com',
            'https://www.biletsokagi.com',
            'https://biletsokagi.web.app',
            'https://biletsokagi.firebaseapp.com'
        ];
        // Development ortamında localhost'a izin ver
        if (process.env.NODE_ENV === 'development') {
            allowedOrigins.push('http://localhost:3000', 'http://localhost:8080');
        }
        if (!origin || allowedOrigins.includes(origin)) {
            callback(null, true);
        }
        else {
            callback(new Error('Not allowed by CORS'));
        }
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'X-ReCaptcha-Token', 'X-API-Key']
};
app.use((0, cors_1.default)(corsOptions));
app.use(express_1.default.json());
// Global security middleware
app.use(securityHeaders);
app.use(advancedSecurityHeaders());
// Bot protection for all routes
app.use(botProtection({
    enableCaptcha: true,
    captchaThreshold: 0.5,
    blockKnownBots: true,
    logSuspiciousActivity: true
}));
// Global rate limiting
app.use(rateLimiter('default'));
// PayTR credentials: prefer environment variables, fall back to functions config
const PAYTR_MERCHANT_ID = process.env.PAYTR_MERCHANT_ID || ((_a = functionsV1.config().paytr) === null || _a === void 0 ? void 0 : _a.merchant_id);
const PAYTR_MERCHANT_KEY = process.env.PAYTR_MERCHANT_KEY || ((_b = functionsV1.config().paytr) === null || _b === void 0 ? void 0 : _b.merchant_key);
const PAYTR_MERCHANT_SALT = process.env.PAYTR_MERCHANT_SALT || ((_c = functionsV1.config().paytr) === null || _c === void 0 ? void 0 : _c.merchant_salt);
// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'OK' });
});
// POST /v1/paytr/initialize
app.post('/v1/paytr/initialize', authMiddleware, // Authentication gerekli
rateLimiter('payment'), // Payment rate limiting
async (req, res) => {
    var _a;
    try {
        if (!PAYTR_MERCHANT_ID || !PAYTR_MERCHANT_KEY || !PAYTR_MERCHANT_SALT) {
            return res.status(500).json({ success: false, error: 'PAYTR credentials missing' });
        }
        const { email, amount, currency = 'TL', orderId, customerIp, basket = [], okUrl, failUrl, installmentCount = '0', testMode = '1', paymentType = 'card', non3d = '0', clientLang = 'tr', userName = '', userAddress = 'Türkiye', userPhone = '05308266698', debugOn = '1', maxInstallment = '0', noInstallment, } = (req.body || {});
        // Zorunlu alanları kontrol et
        if (!email || !amount || !orderId || !okUrl || !failUrl) {
            return res.status(400).json({
                success: false,
                error: 'Missing required fields',
                details: {
                    email: !!email,
                    amount: !!amount,
                    orderId: !!orderId,
                    okUrl: !!okUrl,
                    failUrl: !!failUrl
                }
            });
        }
        // PayTR için kritik alanları kontrol et
        if (!userName || userName.toString().trim().length < 2) {
            return res.status(400).json({
                success: false,
                error: 'userName minimum 2 karakter olmalı',
                received: userName
            });
        }
        if (!userAddress || userAddress.toString().trim().length < 5) {
            return res.status(400).json({
                success: false,
                error: 'userAddress minimum 5 karakter olmalı',
                received: userAddress
            });
        }
        if (!userPhone || userPhone.toString().trim().length < 10) {
            return res.status(400).json({
                success: false,
                error: 'userPhone minimum 10 karakter olmalı',
                received: userPhone
            });
        }
        const merchant_oid = String(orderId);
        // IP adresini tespit et: X-Forwarded-For (ilk IP) > socket > body
        const forwardedFor = (_a = req.headers['x-forwarded-for']) === null || _a === void 0 ? void 0 : _a.split(',')[0].trim();
        const socketIp = (req.socket.remoteAddress || '').toString();
        const user_ip = String(forwardedFor || socketIp || customerIp || '127.0.0.1');
        // payment_amount: PayTR örneklerine göre ondalık nokta ile (örn: "100.99") gönderilmeli
        const normalizeAmount = (val) => {
            const s = String(val);
            if (/^\d+$/.test(s)) {
                const num = Number(s) / 100; // kuruş -> TL
                return num.toFixed(2);
            }
            if (/^\d+\.\d{1,2}$/.test(s)) {
                return Number(s).toFixed(2);
            }
            const cleaned = s.replace(/[^0-9.]/g, '');
            const n = Number(cleaned);
            return Number.isFinite(n) ? n.toFixed(2) : '0.00';
        };
        const payment_amount = normalizeAmount(amount);
        // paytr_token oluştur
        const hashStr = `${PAYTR_MERCHANT_ID}${user_ip}${merchant_oid}${email}${payment_amount}${paymentType}${installmentCount}${currency}${testMode}${non3d}`;
        const paytrTokenRaw = `${hashStr}${PAYTR_MERCHANT_SALT}`;
        const paytrToken = crypto.createHmac('sha256', PAYTR_MERCHANT_KEY).update(paytrTokenRaw).digest('base64');
        // Türkçe karakterleri temizle
        const cleanTurkishChars = (text) => {
            return text
                .replace(/ğ/g, 'g')
                .replace(/Ğ/g, 'G')
                .replace(/ü/g, 'u')
                .replace(/Ü/g, 'U')
                .replace(/ş/g, 's')
                .replace(/Ş/g, 'S')
                .replace(/ı/g, 'i')
                .replace(/İ/g, 'I')
                .replace(/ö/g, 'o')
                .replace(/Ö/g, 'O')
                .replace(/ç/g, 'c')
                .replace(/Ç/g, 'C');
        };
        // Sepet öğelerini ASCII'ye indir ve sayısal alanları normalize et
        const sanitizeBasket = (basketInput) => {
            if (!Array.isArray(basketInput))
                return [];
            return basketInput.map((item) => {
                var _a, _b, _c;
                const arr = Array.isArray(item) ? item : [];
                const name = cleanTurkishChars(String((_a = arr[0]) !== null && _a !== void 0 ? _a : 'Item')).replace(/[^\x20-\x7E]/g, '');
                const priceRaw = String((_b = arr[1]) !== null && _b !== void 0 ? _b : '0');
                const priceClean = priceRaw.replace(',', '.').replace(/[^0-9.]/g, '');
                const priceNum = Number(priceClean);
                const price = Number.isFinite(priceNum) ? priceNum.toFixed(2) : '0.00';
                const qty = String((_c = arr[2]) !== null && _c !== void 0 ? _c : '1').replace(/[^0-9]/g, '') || '1';
                return [name, price, qty];
            });
        };
        const sanitizedBasket = sanitizeBasket(basket || []);
        const userBasketJson = JSON.stringify(sanitizedBasket);
        // no_installment: Taksit tamamen kapalıysa '1', aksi halde '0'
        const noInstallmentCalculated = String(noInstallment !== undefined
            ? (String(noInstallment) === '1' ? '1' : '0')
            : ((String(installmentCount) === '0' && String(maxInstallment) === '0') ? '1' : '0'));
        // PayTR için gerekli parametreleri hazırla (tüm alanlar string olmalı)
        const paytrData = {
            merchant_id: String(PAYTR_MERCHANT_ID),
            user_ip: String(user_ip),
            merchant_oid: String(merchant_oid),
            email: String(email),
            payment_type: String(paymentType),
            payment_amount: String(payment_amount),
            currency: String(currency),
            test_mode: String(testMode),
            non_3d: String(non3d),
            merchant_ok_url: String(okUrl),
            merchant_fail_url: String(failUrl),
            user_name: cleanTurkishChars(String(userName).trim()) || cleanTurkishChars(String(email).split('@')[0]),
            user_address: cleanTurkishChars(String(userAddress).trim()) || 'Istanbul, Turkey',
            user_phone: String(userPhone).trim() || '05555555555',
            // PayTR 1. ADIM örneklerine göre JSON string gönder
            user_basket: userBasketJson,
            debug_on: String(debugOn === '1' ? '1' : '0'),
            client_lang: String(clientLang),
            paytr_token: String(paytrToken),
            installment_count: String(installmentCount),
            max_installment: String(maxInstallment),
            no_installment: noInstallmentCalculated,
        };
        console.log('🔍 PayTR Request Data:', Object.assign(Object.assign({}, paytrData), { paytr_token: '[HIDDEN]', user_basket_json: sanitizedBasket, timestamp: new Date().toISOString(), validation: {
                hasEmail: !!email,
                hasAmount: !!amount,
                hasOrderId: !!orderId,
                hasUserName: !!userName && userName.toString().trim().length >= 2,
                hasUserAddress: !!userAddress && userAddress.toString().trim().length >= 5,
                hasUserPhone: !!userPhone && userPhone.toString().trim().length >= 10,
                hasOkUrl: !!okUrl,
                hasFailUrl: !!failUrl,
                noInstallment: noInstallmentCalculated
            } }));
        return res.status(200).json({
            success: true,
            data: paytrData,
        });
    }
    catch (e) {
        console.error('PayTR initialize error:', (e === null || e === void 0 ? void 0 : e.message) || e);
        return res.status(500).json({ success: false, error: (e === null || e === void 0 ? void 0 : e.message) || 'PayTR initialization failed', message: 'Payment initialization failed. Please try again.' });
    }
});
// POST /v1/paytr/callback
app.post('/v1/paytr/callback', async (req, res) => {
    try {
        if (!PAYTR_MERCHANT_ID || !PAYTR_MERCHANT_KEY || !PAYTR_MERCHANT_SALT) {
            return res.status(200).send('OK');
        }
        const { merchant_oid, status, total_amount, hash, failed_reason_code, failed_reason_msg, test_mode, payment_type, currency, payment_amount, } = req.body;
        // Hash doğrulama
        const hashStr = `${merchant_oid}${PAYTR_MERCHANT_SALT}${status}${total_amount}`;
        const calculatedHash = crypto.createHmac('sha256', PAYTR_MERCHANT_KEY).update(hashStr).digest('base64');
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
        // Checkout session'ı bul (merchant_oid = checkoutSessionId)
        const sessionRef = db.collection('checkout_sessions').doc(merchant_oid);
        const sessionSnap = await sessionRef.get();
        if (!sessionSnap.exists) {
            console.warn(`PayTR callback: checkout session not found: ${merchant_oid}`);
            console.log(`PayTR callback processed for session ${merchant_oid}, status: ${status}`);
            return res.status(200).send('OK');
        }
        const checkoutSession = sessionSnap.data();
        if (status === 'success') {
            // Order oluştur ve session'ı güncelle
            const orderId = db.collection('orders').doc().id;
            const order = {
                id: orderId,
                buyerId: checkoutSession.buyerId,
                sellerId: checkoutSession.sellerId,
                ticketId: checkoutSession.ticketId,
                buyerName: checkoutSession.buyerEmail,
                sellerName: checkoutSession.sellerEmail,
                buyerEmail: checkoutSession.buyerEmail,
                sellerEmail: checkoutSession.sellerEmail,
                ticketPrice: checkoutSession.ticketPrice,
                serviceFee: checkoutSession.serviceFee,
                totalAmount: parseFloat(total_amount),
                currency: currency || checkoutSession.currency,
                status: 'confirmed',
                type: 'purchase',
                deliveryMethod: checkoutSession.deliveryMethod,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                notes: `Order created via PayTR payment - Transaction: ${merchant_oid}`,
                attachments: [],
                metadata: Object.assign(Object.assign({}, (checkoutSession.metadata || {})), { paytr_transaction_id: merchant_oid, payment_type,
                    test_mode }),
            };
            const batch = db.batch();
            batch.set(db.collection('orders').doc(orderId), order);
            batch.update(sessionRef, {
                status: 'completed',
                orderId,
                paymentStatus: 'successful',
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                paytrTransactionId: merchant_oid,
            });
            // Ticket'ı satıldı olarak işaretle (best-effort)
            if (checkoutSession.ticketId) {
                batch.update(db.collection('tickets').doc(checkoutSession.ticketId), {
                    status: 'sold',
                    soldAt: admin.firestore.FieldValue.serverTimestamp(),
                    soldTo: checkoutSession.buyerId,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            }
            await batch.commit();
            console.log('PayTR payment successful, order created:', { orderId, merchant_oid, amount: total_amount });
        }
        else if (status === 'failed') {
            await sessionRef.update({
                status: 'failed',
                paymentStatus: 'failed',
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                failReason: failed_reason_msg || null,
                failCode: failed_reason_code || null,
            });
            console.log('PayTR payment failed:', { merchant_oid, failed_reason_code, failed_reason_msg });
        }
        else if (status === 'wait_callback') {
            // İşlem kontrol aşamasında: şimdilik sadece logla
            console.log('PayTR payment pending (wait_callback):', { merchant_oid });
        }
        console.log(`PayTR callback processed for session ${merchant_oid}, status: ${status}`);
        return res.status(200).send('OK');
    }
    catch (e) {
        console.error('PayTR callback error:', (e === null || e === void 0 ? void 0 : e.message) || e);
        return res.status(200).send('OK');
    }
});
// Export the Express app as a Cloud Function
exports.api = functionsV1.https.onRequest(app);
//# sourceMappingURL=index.js.map