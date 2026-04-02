/* eslint-disable max-len, quotes, camelcase, object-curly-spacing, import/no-duplicates, @typescript-eslint/no-explicit-any, comma-dangle */
import * as functionsV1 from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import express from 'express';
import cors from 'cors';
import { Request, Response } from 'express';
import * as crypto from 'crypto';
import authMiddleware from './middleware/authMiddleware';

interface AuthenticatedRequest extends Request {
  user: admin.auth.DecodedIdToken;
}

admin.initializeApp();
const db = admin.firestore();

const app = express();
app.use(cors());
app.use(express.json());

// PayTR credentials: prefer environment variables, fall back to functions config
const PAYTR_MERCHANT_ID = process.env.PAYTR_MERCHANT_ID || functionsV1.config().paytr?.merchant_id;
const PAYTR_MERCHANT_KEY = process.env.PAYTR_MERCHANT_KEY || functionsV1.config().paytr?.merchant_key;
const PAYTR_MERCHANT_SALT = process.env.PAYTR_MERCHANT_SALT || functionsV1.config().paytr?.merchant_salt;

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
      hash: receivedHash,
      failed_reason_code,
      failed_reason_msg,
      test_mode,
      payment_type,
      currency,
    } = req.body || {};

    if (!merchant_oid || !status || !total_amount || !receivedHash) {
      return res.status(200).send('OK');
    }

    const hashStr = `${merchant_oid}${PAYTR_MERCHANT_SALT}${status}${total_amount}`;
    const calculatedHash = crypto.createHmac('sha256', PAYTR_MERCHANT_KEY as string).update(hashStr).digest('base64');
    if (receivedHash !== calculatedHash) {
      console.error('PayTR callback hash mismatch', { received: receivedHash, calculated: calculatedHash, merchant_oid });
      return res.status(200).send('OK');
    }

    // Get checkout session by document ID (merchant_oid equals session doc id)
    const sessionRef = db.collection('checkout_sessions').doc(String(merchant_oid));
    const sessionSnap = await sessionRef.get();
    if (!sessionSnap.exists) {
      console.warn('Checkout session not found for PayTR callback:', merchant_oid);
      return res.status(200).send('OK');
    }
    const checkoutSession = sessionSnap.data() as any;

    if (status === 'success') {
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
        metadata: { ...checkoutSession.metadata, paytr_transaction_id: merchant_oid, payment_type, test_mode }
      };

      const batch = db.batch();
      batch.set(db.collection('orders').doc(orderId), order);
      batch.update(sessionRef, { status: 'completed', orderId, paymentStatus: 'successful', updatedAt: admin.firestore.FieldValue.serverTimestamp(), paytrTransactionId: merchant_oid });
      batch.update(db.collection('tickets').doc(checkoutSession.ticketId), { status: 'sold', soldAt: admin.firestore.FieldValue.serverTimestamp(), soldTo: checkoutSession.buyerId, updatedAt: admin.firestore.FieldValue.serverTimestamp() });
      await batch.commit();
      console.log('PayTR payment successful, order created:', { orderId, merchant_oid, amount: total_amount });
    } else {
      await sessionRef.update({ status: 'failed', paymentStatus: 'failed', failedReason: failed_reason_msg || 'Payment failed', failedReasonCode: failed_reason_code, updatedAt: admin.firestore.FieldValue.serverTimestamp(), paytrTransactionId: merchant_oid });
      console.log('PayTR payment failed:', { merchant_oid, reason: failed_reason_msg, code: failed_reason_code });
    }

    return res.status(200).send('OK');
  } catch (e: any) {
    console.error('PayTR callback error:', e?.message || e);
    return res.status(200).send('OK');
  }
});

export const api = functionsV1.runWith({ memory: '512MB', timeoutSeconds: 60 }).https.onRequest(app);

// ========== PUSH NOTIFICATION FUNCTIONS ==========

/**
 * Notification Service Class
 */
class NotificationService {
  static async sendMessageNotification(
    message: any,
    recipientTokens: string[],
    senderName: string
  ): Promise<void> {
    if (!recipientTokens.length) {
      console.log('No FCM tokens found for notification');
      return;
    }

    const payload = {
      notification: {
        title: `Yeni mesaj: ${senderName}`,
        body: message.content.length > 100 
          ? `${message.content.substring(0, 100)}...` 
          : message.content,
        icon: '/icons/message.png',
        sound: 'default',
      },
      data: {
        type: 'message',
        conversationId: message.conversationId,
        messageId: message.id,
        senderId: message.senderId,
        senderName: senderName,
        timestamp: message.createdAt?.toDate?.()?.toISOString() || new Date().toISOString(),
        action: 'open_conversation'
      },
      android: {
        notification: {
          channelId: 'messages',
          priority: 'high' as const,
          defaultSound: true,
          defaultVibrateTimings: true,
        },
        data: {
          click_action: 'FLUTTER_NOTIFICATION_CLICK'
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
            category: 'MESSAGE_CATEGORY'
          }
        }
      }
    };

    try {
      const response = await admin.messaging().sendEachForMulticast({
        tokens: recipientTokens,
        ...payload
      });

      console.log(`Notification sent successfully: ${response.successCount}/${recipientTokens.length}`);
      
      if (response.failureCount > 0) {
        console.log('Failed tokens:', response.responses
          .map((resp, idx) => resp.success ? null : recipientTokens[idx])
          .filter(Boolean)
        );
      }
    } catch (error) {
      console.error('Error sending notification:', error);
    }
  }

  static async sendOrderNotification(
    order: any,
    recipientTokens: string[],
    notificationType: 'order_created' | 'order_updated' | 'payment_received'
  ): Promise<void> {
    if (!recipientTokens.length) return;

    const titles = {
      order_created: 'Yeni Sipariş',
      order_updated: 'Sipariş Güncellendi',
      payment_received: 'Ödeme Alındı'
    };

    const bodies = {
      order_created: `${order.ticketTitle} için yeni sipariş`,
      order_updated: `Sipariş durumu: ${order.status}`,
      payment_received: `${order.totalAmount} ${order.currency} ödeme alındı`
    };

    const payload = {
      notification: {
        title: titles[notificationType],
        body: bodies[notificationType],
        icon: '/icons/order.png',
        sound: 'default',
      },
      data: {
        type: 'order',
        orderId: order.id,
        notificationType,
        amount: order.totalAmount?.toString() || '0',
        currency: order.currency || 'TRY',
        action: 'open_order'
      }
    };

    try {
      await admin.messaging().sendEachForMulticast({
        tokens: recipientTokens,
        ...payload
      });
      console.log(`Order notification sent: ${notificationType}`);
    } catch (error) {
      console.error('Error sending order notification:', error);
    }
  }

  static async getUserFCMTokens(userId: string): Promise<string[]> {
    try {
      const tokensSnapshot = await db
        .collection('users')
        .doc(userId)
        .collection('fcmTokens')
        .get();

      return tokensSnapshot.docs.map(doc => doc.id);
    } catch (error) {
      console.error('Error getting FCM tokens:', error);
      return [];
    }
  }
}

/**
 * Firestore Trigger: New Message Notification
 * Yeni mesaj eklendiğinde otomatik bildirim gönder
 */
export const sendMessageNotification = functionsV1.firestore
  .document('messages/{messageId}')
  .onCreate(async (snapshot, context) => {
    try {
      const message = snapshot.data();
      const messageId = context.params.messageId;

      console.log(`New message created: ${messageId}`);

      // Conversation bilgilerini al
      const conversationDoc = await db
        .collection('conversations')
        .doc(message.conversationId)
        .get();

      if (!conversationDoc.exists) {
        console.log('Conversation not found');
        return;
      }

      const conversation = conversationDoc.data();
      const participants = conversation?.participants || [];

      // Gönderen hariç diğer katılımcılara bildirim gönder
      const recipients = participants.filter((p: string) => p !== message.senderId);

      if (recipients.length === 0) {
        console.log('No recipients for notification');
        return;
      }

      // Gönderen kullanıcının bilgilerini al
      const senderDoc = await db.collection('users').doc(message.senderId).get();
      const senderName = senderDoc.data()?.displayName || 'Kullanıcı';

      // Her alıcı için FCM token'larını al ve bildirim gönder
      for (const recipientId of recipients) {
        const tokens = await NotificationService.getUserFCMTokens(recipientId);
        
        if (tokens.length > 0) {
          await NotificationService.sendMessageNotification(
            { ...message, id: messageId },
            tokens,
            senderName
          );
        }
      }

    } catch (error) {
      console.error('Error in sendMessageNotification trigger:', error);
    }
  });

/**
 * Firestore Trigger: Order Status Change Notification
 * Sipariş durumu değiştiğinde bildirim gönder
 */
export const sendOrderStatusNotification = functionsV1.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    try {
      const before = change.before.data();
      const after = change.after.data();
      const orderId = context.params.orderId;

      // Status değişmişse bildirim gönder
      if (before.status !== after.status) {
        console.log(`Order status changed: ${before.status} -> ${after.status}`);

        // Satıcı ve alıcıya bildirim gönder
        const buyerTokens = await NotificationService.getUserFCMTokens(after.buyerId);
        const sellerTokens = await NotificationService.getUserFCMTokens(after.sellerId);

        if (buyerTokens.length > 0) {
          await NotificationService.sendOrderNotification(
            { ...after, id: orderId },
            buyerTokens,
            'order_updated'
          );
        }

        if (sellerTokens.length > 0) {
          await NotificationService.sendOrderNotification(
            { ...after, id: orderId },
            sellerTokens,
            'order_updated'
          );
        }
      }

    } catch (error) {
      console.error('Error in sendOrderStatusNotification trigger:', error);
    }
  });

// Admin kullanıcı ID'leri
const ADMIN_USER_IDS = [
  'Fu9NlPlGXjQROCW96fZUUTLueUf2', // admin@biletsokagi.com
];

// Admin kontrolü middleware
async function checkAdminAccess(req: Request, res: Response, next: any): Promise<any> {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        error: 'Authorization token required'
      });
    }

    const token = authHeader.split('Bearer ')[1];
    const decodedToken = await admin.auth().verifyIdToken(token);
    
    // Admin kontrolü
    if (!ADMIN_USER_IDS.includes(decodedToken.uid)) {
      // Firestore'dan admin rolü kontrolü
      const userDoc = await db.collection('users').doc(decodedToken.uid).get();
      const userData = userDoc.data();
      
      if (!userData?.isAdmin && userData?.role !== 'admin') {
        return res.status(403).json({
          success: false,
          error: 'Admin access required'
        });
      }
    }

    (req as any).user = decodedToken;
    return next();
  } catch (error) {
    console.error('Admin access check failed:', error);
    return res.status(401).json({
      success: false,
      error: 'Invalid or expired token'
    });
  }
}

/**
 * HTTP Function: Manual Notification Sending
 * Admin panelinden manuel bildirim gönderme
 */
app.post('/v1/notifications/send', checkAdminAccess, async (req: Request, res: Response) => {
  try {
    const {
      userIds,
      title,
      body,
      data = {},
      type = 'general'
    } = req.body;

    if (!userIds || !Array.isArray(userIds) || !title || !body) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: userIds, title, body'
      });
    }

    let totalSent = 0;
    let totalFailed = 0;

    // Her kullanıcı için bildirim gönder
    for (const userId of userIds) {
      const tokens = await NotificationService.getUserFCMTokens(userId);
      
      if (tokens.length > 0) {
        const payload = {
          notification: { title, body },
          data: { type, ...data }
        };

        try {
          const response = await admin.messaging().sendEachForMulticast({
            tokens,
            ...payload
          });
          
          totalSent += response.successCount;
          totalFailed += response.failureCount;
        } catch (error) {
          console.error(`Error sending to user ${userId}:`, error);
          totalFailed += tokens.length;
        }
      }
    }

    return res.status(200).json({
      success: true,
      data: {
        totalSent,
        totalFailed,
        totalUsers: userIds.length
      }
    });

  } catch (error) {
    console.error('Error in manual notification sending:', error);
    return res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

/**
 * HTTP Function: Get User Notification Settings
 * Kullanıcı bildirim ayarlarını getir
 */
app.get('/v1/notifications/settings/:userId', checkAdminAccess, async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;

    const settingsDoc = await db
      .collection('notificationSettings')
      .doc(userId)
      .get();

    const settings = settingsDoc.exists ? settingsDoc.data() : {
      pushNotifications: true,
      emailNotifications: true,
      messageNotifications: true,
      orderNotifications: true
    };

    return res.status(200).json({
      success: true,
      data: settings
    });

  } catch (error) {
    console.error('Error getting notification settings:', error);
    return res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

/**
 * HTTP Function: Update User Notification Settings
 * Kullanıcı bildirim ayarlarını güncelle
 */
app.post('/v1/notifications/settings/:userId', checkAdminAccess, async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;
    const settings = req.body;

    await db
      .collection('notificationSettings')
      .doc(userId)
      .set({
        ...settings,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });

    return res.status(200).json({
      success: true,
      message: 'Notification settings updated'
    });

  } catch (error) {
    console.error('Error updating notification settings:', error);
    return res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// Removed unused v2 sample imports

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// ==================== KULLANICI MODERASYON API'LERİ ====================

// Kullanıcı raporlama API'si
app.post('/v1/users/report', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { reportedUserId, reason, customReason, messageId } = req.body;
    const reporterUserId = (req as any).user.uid;

    if (!reportedUserId || !reason) {
      return res.status(400).json({
        success: false,
        error: 'reportedUserId ve reason gerekli'
      });
    }

    // Kendi kendini raporlamayı engelle
    if (reporterUserId === reportedUserId) {
      return res.status(400).json({
        success: false,
        error: 'Kendinizi raporlayamazsınız'
      });
    }

    // Rapor verilerini hazırla
    const reportData = {
      reporterId: reporterUserId,
      reportedUserId,
      reason,
      customReason: customReason || null,
      messageId: messageId || null,
      status: 'pending', // pending, reviewed, resolved, dismissed
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      reviewedBy: null,
      reviewedAt: null,
      resolution: null,
    };

    // Raporu Firestore'a kaydet
    const reportRef = await db.collection('userReports').add(reportData);

    // Raporlanan kullanıcının istatistiklerini güncelle
    const reportedUserRef = db.collection('users').doc(reportedUserId);
    await reportedUserRef.update({
      'moderationStats.reportCount': admin.firestore.FieldValue.increment(1),
      'moderationStats.lastReportedAt': admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`🚨 Kullanıcı raporlandı: ${reportedUserId} tarafından ${reporterUserId} (Rapor ID: ${reportRef.id})`);

    res.status(200).json({
      success: true,
      reportId: reportRef.id,
      message: 'Rapor başarıyla gönderildi'
    });

  } catch (error) {
    console.error('Kullanıcı raporlama hatası:', error);
    res.status(500).json({
      success: false,
      error: 'Rapor gönderilirken hata oluştu'
    });
  }
});

// Kullanıcı engelleme API'si
app.post('/v1/users/block', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { blockedUserId } = req.body;
    const blockerUserId = (req as any).user.uid;

    if (!blockedUserId) {
      return res.status(400).json({
        success: false,
        error: 'blockedUserId gerekli'
      });
    }

    // Kendi kendini engellemeyi engelle
    if (blockerUserId === blockedUserId) {
      return res.status(400).json({
        success: false,
        error: 'Kendinizi engelleyemezsiniz'
      });
    }

    // Engelleme verilerini hazırla
    const blockData = {
      blockerId: blockerUserId,
      blockedUserId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      isActive: true,
    };

    // Çift engellemeyi kontrol et
    const existingBlock = await db.collection('userBlocks')
      .where('blockerId', '==', blockerUserId)
      .where('blockedUserId', '==', blockedUserId)
      .where('isActive', '==', true)
      .limit(1)
      .get();

    if (!existingBlock.empty) {
      return res.status(400).json({
        success: false,
        error: 'Bu kullanıcı zaten engellenmiş'
      });
    }

    // Engellemeyi Firestore'a kaydet
    const blockRef = await db.collection('userBlocks').add(blockData);

    // Engellenen kullanıcının istatistiklerini güncelle
    const blockedUserRef = db.collection('users').doc(blockedUserId);
    await blockedUserRef.update({
      'moderationStats.blockCount': admin.firestore.FieldValue.increment(1),
      'moderationStats.lastBlockedAt': admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Engelleyen kullanıcının engelleme listesini güncelle
    const blockerUserRef = db.collection('users').doc(blockerUserId);
    await blockerUserRef.update({
      'blockedUsers': admin.firestore.FieldValue.arrayUnion(blockedUserId),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`🚫 Kullanıcı engellendi: ${blockedUserId} tarafından ${blockerUserId} (Engelleme ID: ${blockRef.id})`);

    res.status(200).json({
      success: true,
      blockId: blockRef.id,
      message: 'Kullanıcı başarıyla engellendi'
    });

  } catch (error) {
    console.error('Kullanıcı engelleme hatası:', error);
    res.status(500).json({
      success: false,
      error: 'Kullanıcı engellenirken hata oluştu'
    });
  }
});

// Kullanıcı engelleme kaldırma API'si
app.delete('/v1/users/block/:blockedUserId', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { blockedUserId } = req.params;
    const blockerUserId = (req as any).user.uid;

    if (!blockedUserId) {
      return res.status(400).json({
        success: false,
        error: 'blockedUserId gerekli'
      });
    }

    // Aktif engellemeyi bul
    const blockQuery = await db.collection('userBlocks')
      .where('blockerId', '==', blockerUserId)
      .where('blockedUserId', '==', blockedUserId)
      .where('isActive', '==', true)
      .limit(1)
      .get();

    if (blockQuery.empty) {
      return res.status(404).json({
        success: false,
        error: 'Aktif engelleme bulunamadı'
      });
    }

    // Engellemeyi pasif yap
    const blockDoc = blockQuery.docs[0];
    await blockDoc.ref.update({
      isActive: false,
      unblockAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Engelleyen kullanıcının engelleme listesinden çıkar
    const blockerUserRef = db.collection('users').doc(blockerUserId);
    await blockerUserRef.update({
      'blockedUsers': admin.firestore.FieldValue.arrayRemove(blockedUserId),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`✅ Kullanıcı engeli kaldırıldı: ${blockedUserId} tarafından ${blockerUserId}`);

    res.status(200).json({
      success: true,
      message: 'Kullanıcı engeli başarıyla kaldırıldı'
    });

  } catch (error) {
    console.error('Kullanıcı engeli kaldırma hatası:', error);
    res.status(500).json({
      success: false,
      error: 'Kullanıcı engeli kaldırılırken hata oluştu'
    });
  }
});

// Engellenmiş kullanıcıları listeleme API'si
app.get('/v1/users/blocked', authMiddleware, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.uid;

    // Kullanıcının engellediği kişileri getir
    const blocksQuery = await db.collection('userBlocks')
      .where('blockerId', '==', userId)
      .where('isActive', '==', true)
      .orderBy('createdAt', 'desc')
      .get();

    const blockedUsers = [];
    for (const doc of blocksQuery.docs) {
      const blockData = doc.data();
      
      // Engellenen kullanıcının temel bilgilerini getir
      const userDoc = await db.collection('users').doc(blockData.blockedUserId).get();
      if (userDoc.exists) {
        const userData = userDoc.data();
        blockedUsers.push({
          blockId: doc.id,
          userId: blockData.blockedUserId,
          username: userData?.username || 'Bilinmeyen',
          displayName: userData?.displayName || userData?.firstName || 'Bilinmeyen',
          profileImageUrl: userData?.profileImageUrl || null,
          blockedAt: blockData.createdAt,
        });
      }
    }

    res.status(200).json({
      success: true,
      blockedUsers,
      count: blockedUsers.length
    });

  } catch (error) {
    console.error('Engellenmiş kullanıcıları listeleme hatası:', error);
    res.status(500).json({
      success: false,
      error: 'Engellenmiş kullanıcılar listelenirken hata oluştu'
    });
  }
});

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
// setGlobalOptions removed (using v1 runWith above)

// helloWorld sample removed
