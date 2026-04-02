// Quick local generator for PayTR init params (no emulator needed)
// Usage:
//   set -a; . functions/.env; set +a; 
//   node functions/scripts/paytr_init_local.js '{"email":"info@biletsokagi.com","amount":"100.00","currency":"TL","orderId":"T123","customerIp":"127.0.0.1","basket":[["Konser Bileti","100.00",1]],"okUrl":"https://example.com/ok","failUrl":"https://example.com/fail","installmentCount":"0","testMode":"1","paymentType":"card","non3d":"0","clientLang":"tr","userName":"Test","userAddress":"Adres","userPhone":"05555555555"}'

const crypto = require('crypto');

const PAYTR_MERCHANT_ID = process.env.PAYTR_MERCHANT_ID;
const PAYTR_MERCHANT_KEY = process.env.PAYTR_MERCHANT_KEY;
const PAYTR_MERCHANT_SALT = process.env.PAYTR_MERCHANT_SALT;

if (!PAYTR_MERCHANT_ID || !PAYTR_MERCHANT_KEY || !PAYTR_MERCHANT_SALT) {
  console.error('Missing PAYTR envs: PAYTR_MERCHANT_ID/KEY/SALT');
  process.exit(1);
}

let payload = {};
try {
  payload = JSON.parse(process.argv[2] || '{}');
} catch (e) {
  console.error('Invalid JSON payload:', e.message);
  process.exit(1);
}

const email = payload.email;
const amount = String(payload.amount);
const currency = payload.currency || 'TL';
const orderId = String(payload.orderId);
const customerIp = payload.customerIp || '';
const basket = payload.basket || [];
const okUrl = payload.okUrl;
const failUrl = payload.failUrl;
const installmentCount = payload.installmentCount || '0';
const testMode = payload.testMode || '1';
const paymentType = payload.paymentType || 'card';
const non3d = payload.non3d || '0';
const clientLang = payload.clientLang || 'tr';
const userName = payload.userName || '';
const userAddress = payload.userAddress || '';
const userPhone = payload.userPhone || '';

if (!email || !amount || !orderId || !okUrl || !failUrl) {
  console.error('Missing required fields (email, amount, orderId, okUrl, failUrl)');
  process.exit(1);
}

const merchant_oid = orderId;
const user_ip = customerIp;
const payment_amount = amount;

const hashStr = `${PAYTR_MERCHANT_ID}${user_ip}${merchant_oid}${email}${payment_amount}${paymentType}${installmentCount}${currency}${testMode}${non3d}`;
const paytrTokenRaw = `${hashStr}${PAYTR_MERCHANT_SALT}`;
const token = crypto.createHmac('sha256', PAYTR_MERCHANT_KEY).update(paytrTokenRaw).digest('base64');

const result = {
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
};

console.log(JSON.stringify({ success: true, data: result }, null, 2));


