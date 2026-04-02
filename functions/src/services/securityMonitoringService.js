const admin = require('firebase-admin');
const functions = require('firebase-functions/v1');

class SecurityMonitoringService {
  constructor() {
    this.db = admin.firestore();
    this.auth = admin.auth();
    
    // Güvenlik olayları için eşik değerleri
    this.thresholds = {
      failedLogins: { count: 5, window: 10 * 60 * 1000 }, // 10 dakika
      rateLimitHits: { count: 10, window: 5 * 60 * 1000 }, // 5 dakika
      suspiciousIPs: { count: 3, window: 60 * 60 * 1000 }, // 1 saat
      botDetections: { count: 5, window: 15 * 60 * 1000 }, // 15 dakika
      apiKeyFailures: { count: 3, window: 30 * 60 * 1000 }, // 30 dakika
    };
    
    // Alert seviyeleri
    this.alertLevels = {
      INFO: 'info',
      WARNING: 'warning',
      CRITICAL: 'critical',
      EMERGENCY: 'emergency'
    };
  }

  /**
   * Güvenlik olayını logla
   */
  async logSecurityEvent(eventData) {
    try {
      const event = {
        id: this.generateEventId(),
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        type: eventData.type,
        severity: eventData.severity || this.alertLevels.INFO,
        source: eventData.source || 'system',
        ip: eventData.ip,
        userId: eventData.userId,
        userAgent: eventData.userAgent,
        details: eventData.details || {},
        metadata: {
          ...eventData.metadata,
          processed: false,
          alertSent: false
        }
      };

      // Firestore'a kaydet
      await this.db.collection('securityLogs').add(event);

      // Kritik olayları hemen işle
      if (event.severity === this.alertLevels.CRITICAL || 
          event.severity === this.alertLevels.EMERGENCY) {
        await this.processSecurityEvent(event);
      }

      return event.id;
    } catch (error) {
      functions.logger.error('Security event logging failed:', error);
      throw error;
    }
  }

  /**
   * Güvenlik olayını işle ve gerekirse alarm gönder
   */
  async processSecurityEvent(event) {
    try {
      // Anomali tespiti
      const isAnomaly = await this.detectAnomaly(event);
      
      if (isAnomaly) {
        // Otomatik aksiyon al
        await this.takeAutomaticAction(event);
        
        // Alert gönder
        await this.sendSecurityAlert(event);
      }

      // Event'i işlenmiş olarak işaretle
      await this.db.collection('securityLogs').doc(event.id).update({
        'metadata.processed': true,
        'metadata.processedAt': admin.firestore.FieldValue.serverTimestamp()
      });
    } catch (error) {
      functions.logger.error('Security event processing failed:', error);
    }
  }

  /**
   * Anomali tespiti
   */
  async detectAnomaly(event) {
    const now = Date.now();
    
    // Event tipine göre anomali kontrolü
    switch (event.type) {
      case 'FAILED_LOGIN':
        return await this.checkThreshold(
          event.userId || event.ip,
          'failedLogins',
          this.thresholds.failedLogins
        );
        
      case 'RATE_LIMIT_EXCEEDED':
        return await this.checkThreshold(
          event.ip,
          'rateLimitHits',
          this.thresholds.rateLimitHits
        );
        
      case 'BOT_DETECTED':
        return await this.checkThreshold(
          event.ip,
          'botDetections',
          this.thresholds.botDetections
        );
        
      case 'INVALID_API_KEY':
        return await this.checkThreshold(
          event.ip,
          'apiKeyFailures',
          this.thresholds.apiKeyFailures
        );
        
      case 'SUSPICIOUS_ACTIVITY':
        return true; // Her zaman anomali olarak işle
        
      default:
        return false;
    }
  }

  /**
   * Eşik değer kontrolü
   */
  async checkThreshold(identifier, eventType, threshold) {
    const recentEvents = await this.db.collection('securityLogs')
      .where('type', '==', eventType)
      .where('timestamp', '>', new Date(Date.now() - threshold.window))
      .where(identifier.includes('@') ? 'userId' : 'ip', '==', identifier)
      .get();
    
    return recentEvents.size >= threshold.count;
  }

  /**
   * Otomatik güvenlik aksiyonu
   */
  async takeAutomaticAction(event) {
    switch (event.type) {
      case 'FAILED_LOGIN':
        if (event.userId) {
          // Hesabı geçici olarak kilitle
          await this.lockUserAccount(event.userId, 30); // 30 dakika
        }
        break;
        
      case 'RATE_LIMIT_EXCEEDED':
      case 'BOT_DETECTED':
        // IP'yi blacklist'e ekle
        await this.blacklistIP(event.ip, 60); // 60 dakika
        break;
        
      case 'INVALID_API_KEY':
        // API key'i devre dışı bırak
        if (event.details.apiKey) {
          await this.revokeApiKey(event.details.apiKey);
        }
        break;
        
      case 'SUSPICIOUS_ACTIVITY':
        // Detaylı loglama ve manuel inceleme için işaretle
        await this.flagForReview(event);
        break;
    }
  }

  /**
   * Güvenlik alarmı gönder
   */
  async sendSecurityAlert(event) {
    const alert = {
      id: event.id,
      timestamp: new Date().toISOString(),
      severity: event.severity,
      type: event.type,
      summary: this.generateAlertSummary(event),
      details: event.details,
      actions: this.suggestActions(event)
    };

    // Email gönder (production'da)
    if (process.env.NODE_ENV === 'production') {
      await this.sendEmailAlert(alert);
    }

    // Slack/Discord webhook (varsa)
    if (process.env.SECURITY_WEBHOOK_URL) {
      await this.sendWebhookAlert(alert);
    }

    // Alert'i kaydet
    await this.db.collection('securityAlerts').add({
      ...alert,
      sentAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Event'i güncelle
    await this.db.collection('securityLogs').doc(event.id).update({
      'metadata.alertSent': true,
      'metadata.alertId': alert.id
    });
  }

  /**
   * Kullanıcı hesabını kilitle
   */
  async lockUserAccount(userId, durationMinutes) {
    try {
      // Firebase Auth'da devre dışı bırak
      await this.auth.updateUser(userId, { disabled: true });
      
      // Kilitleme kaydı oluştur
      await this.db.collection('accountLocks').add({
        userId,
        lockedAt: admin.firestore.FieldValue.serverTimestamp(),
        lockedUntil: new Date(Date.now() + durationMinutes * 60 * 1000),
        reason: 'FAILED_LOGIN_ATTEMPTS',
        autoUnlock: true
      });
      
      functions.logger.warn(`User account locked: ${userId}`);
    } catch (error) {
      functions.logger.error('Failed to lock user account:', error);
    }
  }

  /**
   * IP'yi kara listeye ekle
   */
  async blacklistIP(ip, durationMinutes) {
    try {
      await this.db.collection('blacklistedIPs').doc(ip).set({
        ip,
        blacklistedAt: admin.firestore.FieldValue.serverTimestamp(),
        blacklistedUntil: new Date(Date.now() + durationMinutes * 60 * 1000),
        reason: 'AUTOMATED_SECURITY_ACTION',
        autoRemove: true
      });
      
      functions.logger.warn(`IP blacklisted: ${ip}`);
    } catch (error) {
      functions.logger.error('Failed to blacklist IP:', error);
    }
  }

  /**
   * API key'i iptal et
   */
  async revokeApiKey(apiKey) {
    try {
      // API key'in ilk 8 karakteri ile ara
      const keyPrefix = apiKey.substring(0, 8);
      
      const keys = await this.db.collection('apiKeys')
        .where('keyPrefix', '==', keyPrefix)
        .where('status', '==', 'active')
        .get();
      
      for (const doc of keys.docs) {
        await doc.ref.update({
          status: 'revoked',
          revokedAt: admin.firestore.FieldValue.serverTimestamp(),
          revokedReason: 'SECURITY_VIOLATION'
        });
      }
      
      functions.logger.warn(`API key revoked: ${keyPrefix}...`);
    } catch (error) {
      functions.logger.error('Failed to revoke API key:', error);
    }
  }

  /**
   * Manuel inceleme için işaretle
   */
  async flagForReview(event) {
    await this.db.collection('pendingReviews').add({
      eventId: event.id,
      type: 'SECURITY_EVENT',
      priority: 'HIGH',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'pending',
      event: event
    });
  }

  /**
   * Alert özeti oluştur
   */
  generateAlertSummary(event) {
    const summaries = {
      'FAILED_LOGIN': `Multiple failed login attempts detected for ${event.userId || event.ip}`,
      'RATE_LIMIT_EXCEEDED': `Rate limit exceeded multiple times from IP: ${event.ip}`,
      'BOT_DETECTED': `Bot activity detected from IP: ${event.ip}`,
      'INVALID_API_KEY': `Invalid API key used multiple times from IP: ${event.ip}`,
      'SUSPICIOUS_ACTIVITY': `Suspicious activity detected: ${event.details.description || 'Unknown'}`
    };
    
    return summaries[event.type] || `Security event: ${event.type}`;
  }

  /**
   * Önerilen aksiyonlar
   */
  suggestActions(event) {
    const actions = {
      'FAILED_LOGIN': [
        'Review login attempts',
        'Check for credential stuffing attack',
        'Consider implementing CAPTCHA',
        'Verify user identity if needed'
      ],
      'RATE_LIMIT_EXCEEDED': [
        'Monitor IP for continued abuse',
        'Consider permanent IP ban if continues',
        'Check for DDoS patterns',
        'Review rate limit thresholds'
      ],
      'BOT_DETECTED': [
        'Verify bot detection accuracy',
        'Add IP to permanent blocklist if confirmed',
        'Review bot detection rules',
        'Consider implementing stronger CAPTCHA'
      ],
      'INVALID_API_KEY': [
        'Investigate potential API key leak',
        'Rotate affected API keys',
        'Review API key distribution process',
        'Audit API access logs'
      ],
      'SUSPICIOUS_ACTIVITY': [
        'Conduct thorough investigation',
        'Review all user activities',
        'Check for data exfiltration',
        'Consider incident response activation'
      ]
    };
    
    return actions[event.type] || ['Manual review required'];
  }

  /**
   * Email alert gönder
   */
  async sendEmailAlert(alert) {
    // Email gönderme implementasyonu (SendGrid, Mailgun vs.)
    functions.logger.info('Email alert would be sent:', alert.summary);
  }

  /**
   * Webhook alert gönder
   */
  async sendWebhookAlert(alert) {
    try {
      const axios = require('axios');
      
      await axios.post(process.env.SECURITY_WEBHOOK_URL, {
        text: `🚨 Security Alert: ${alert.severity.toUpperCase()}`,
        blocks: [
          {
            type: 'section',
            text: {
              type: 'mrkdwn',
              text: `*${alert.summary}*\n\n*Type:* ${alert.type}\n*Time:* ${alert.timestamp}`
            }
          },
          {
            type: 'section',
            text: {
              type: 'mrkdwn',
              text: `*Suggested Actions:*\n${alert.actions.map(a => `• ${a}`).join('\n')}`
            }
          }
        ]
      });
    } catch (error) {
      functions.logger.error('Failed to send webhook alert:', error);
    }
  }

  /**
   * Event ID oluştur
   */
  generateEventId() {
    return `SEC-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }

  /**
   * Periyodik temizlik
   */
  async cleanupOldLogs(daysToKeep = 90) {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - daysToKeep);
    
    const oldLogs = await this.db.collection('securityLogs')
      .where('timestamp', '<', cutoffDate)
      .limit(500) // Batch işlem için
      .get();
    
    const batch = this.db.batch();
    oldLogs.forEach(doc => {
      batch.delete(doc.ref);
    });
    
    await batch.commit();
    
    functions.logger.info(`Cleaned up ${oldLogs.size} old security logs`);
  }
}

module.exports = SecurityMonitoringService;

