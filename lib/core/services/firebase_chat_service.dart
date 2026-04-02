import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../features/conversations/domain/entities/conversation.dart';
import '../../features/conversations/domain/entities/message.dart';

/// Firebase tabanlı gerçek zamanlı chat servisi
/// 
/// Bu servis, kullanıcılar arası mesajlaşmayı Firestore ile yönetir.
/// Özellikler:
/// - Gerçek zamanlı mesajlaşma
/// - Kullanıcı durumu takibi (çevrimiçi/çevrimdışı)
/// - Sohbet listesi yönetimi
/// - Mesaj durumu takibi (gönderildi, okundu)
class FirebaseChatService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // Firestore koleksiyon referansları
  late final CollectionReference _conversationsRef;
  late final CollectionReference _messagesRef;
  late final CollectionReference _usersRef;

  FirebaseChatService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance {
    // Koleksiyon referanslarını başlat
    _conversationsRef = _firestore.collection('conversations');
    _messagesRef = _firestore.collection('messages');
    _usersRef = _firestore.collection('users');
  }

  /// Mevcut kullanıcının ID'sini al
  String? get currentUserId => _auth.currentUser?.uid;

  /// Mevcut kullanıcının görünen adını al
  String? get currentUserDisplayName => _auth.currentUser?.displayName;

  /// Mevcut kullanıcının profil fotoğrafı URL'sini al
  String? get currentUserProfilePhoto => _auth.currentUser?.photoURL;

  /// Kullanıcı durumunu çevrimiçi olarak güncelle
  /// 
  /// Bu metod kullanıcı uygulamaya girdiğinde çağrılmalıdır.
  Future<void> setUserOnline() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      await _usersRef.doc(userId).set({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'email': _auth.currentUser?.email,
        'displayName': _auth.currentUser?.displayName,
        'profileImageUrl': _auth.currentUser?.photoURL,
        'lastActivity': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ Kullanıcı çevrimiçi duruma geçti: $userId');
    } catch (e) {
      debugPrint('❌ Kullanıcı çevrimiçi duruma geçirilirken hata: $e');
    }
  }

  /// Kullanıcı durumunu çevrimdışı olarak güncelle
  /// 
  /// Bu metod kullanıcı uygulamadan çıktığında çağrılmalıdır.
  Future<void> setUserOffline() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      await _usersRef.doc(userId).update({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
        'displayName': _auth.currentUser?.displayName,
        'profileImageUrl': _auth.currentUser?.photoURL,
      });

      debugPrint('📴 Kullanıcı çevrimdışı duruma geçti: $userId');
    } catch (e) {
      debugPrint('❌ Kullanıcı çevrimdışı duruma geçirilirken hata: $e');
    }
  }

  /// Belirli bir kullanıcının durumunu dinle (çevrimiçi/çevrimdışı)
  /// 
  /// @param userId - Takip edilecek kullanıcının ID'si
  /// @returns `Stream<Map<String, dynamic>?>` - Kullanıcı durumu bilgileri
  Stream<Map<String, dynamic>?> getUserPresence(String userId) {
    return _usersRef.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      
      final data = doc.data() as Map<String, dynamic>;
      final isOnline = data['isOnline'] ?? false;
      final lastSeen = data['lastSeen'] as Timestamp?;
      final lastActivity = data['lastActivity'] as Timestamp?;
      
      // Akıllı çevrimiçi durumu kontrolü
      bool actuallyOnline = isOnline;
      if (isOnline && lastActivity != null) {
        final now = DateTime.now();
        final lastActivityTime = lastActivity.toDate();
        final timeDifference = now.difference(lastActivityTime);
        
        // 5 dakikadan fazla aktivite yoksa çevrimdışı say
        if (timeDifference.inMinutes > 5) {
          actuallyOnline = false;
          
          // Arka planda durumu güncelle (fire and forget)
          _usersRef.doc(userId).update({
            'isOnline': false,
            'lastSeen': FieldValue.serverTimestamp(),
          }).catchError((e) {
            debugPrint('❌ Otomatik çevrimdışı güncelleme hatası: $e');
          });
        }
      }
      
      return {
        'isOnline': actuallyOnline,
        'lastSeen': lastSeen,
        'lastActivity': lastActivity,
        'username': data['username'] ?? data['displayName'] ?? 'Unknown User',
        'firstName': data['firstName'] ?? '',
        'lastName': data['lastName'] ?? '',
        'profileImageUrl': data['profileImageUrl'],
      };
    });
  }

  Future<void> updateParticipantAvatar(String conversationId, String userId, String? avatarUrl) async {
    await _conversationsRef.doc(conversationId).set({
      'metadata': {
        'avatars': {
          userId: avatarUrl,
        },
      },
    }, SetOptions(merge: true));
  }

  /// İki kullanıcı arasında sohbet oluştur veya mevcut olanı getir
  /// 
  /// @param otherUserId - Karşı taraftaki kullanıcının ID'si
  /// @returns String - Conversation ID
  Future<String> createOrGetConversation(String otherUserId) async {
    final currentUser = currentUserId;
    if (currentUser == null) throw Exception('Kullanıcı giriş yapmamış');

    // Conversation ID'si her zaman aynı sırayla oluştur (lexicographically)
    final participants = [currentUser, otherUserId]..sort();
    final conversationId = '${participants[0]}_${participants[1]}';

    // Kurala uygun, idempotent oluşturma: ön okuma yapmadan merge'li set kullan
    // Not: createdAt ve diğer opsiyonel alanlar güncellenmez; sadece create için gerekli alanlar yazılır
    try {
      await _conversationsRef.doc(conversationId).set({
        'id': conversationId, // Conversation ID field'ını da set et
        'participants': participants,
        'createdBy': currentUser,
        if (!(await _conversationsRef.doc(conversationId).get()).exists)
          'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
        // Eski kurallarla uyumluluk için sabit alanlar
        'buyerId': participants[0],
        'sellerId': participants[1],
      }, SetOptions(merge: true));
      
      debugPrint('✅ DEBUG: Conversation oluşturuldu/güncellendi: $conversationId');
    } catch (e) {
      debugPrint('❌ DEBUG: Conversation oluşturma hatası: $e');
      debugPrint('🔐 DEBUG: Current user: $currentUser, Other user: $otherUserId');
      debugPrint('👥 DEBUG: Participants: $participants');
      rethrow;
    }

    return conversationId;
  }

  /// Mesaj gönder
  /// 
  /// @param conversationId - Sohbet ID'si
  /// @param receiverId - Alıcının ID'si
  /// @param content - Mesaj içeriği
  /// @param type - Mesaj tipi (text, image, etc.)
  Future<void> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    final senderId = currentUserId;
    if (senderId == null) throw Exception('Kullanıcı giriş yapmamış');

    // DEBUG: Auth ve permission bilgilerini logla
    debugPrint('🔐 DEBUG: Auth durumu - Sender ID: $senderId');
    debugPrint('🔐 DEBUG: Receiver ID: $receiverId');
    debugPrint('🔐 DEBUG: Conversation ID: $conversationId');
    
    try {
      // Auth token'ını kontrol et
      final user = _auth.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        debugPrint('🔐 DEBUG: Auth token alındı - uzunluk: ${token?.length ?? 0}');
        
        // Token claims'leri kontrol et
        final tokenResult = await user.getIdTokenResult();
        debugPrint('🔐 DEBUG: Token claims: ${tokenResult.claims}');
      }
    } catch (e) {
      debugPrint('❌ DEBUG: Auth token hatası: $e');
    }

    // Kullanıcı isimlerini al
    String senderName = 'Unknown User';
    String receiverName = 'Unknown User';
    
    try {
      // Sender bilgilerini al
      final senderDoc = await _usersRef.doc(senderId).get();
      if (senderDoc.exists) {
        final senderData = senderDoc.data() as Map<String, dynamic>;
        senderName = senderData['username'] ?? 
                    '${senderData['firstName'] ?? ''} ${senderData['lastName'] ?? ''}'.trim();
        if (senderName.isEmpty) senderName = 'User';
      }
      
      // Receiver bilgilerini al
      final receiverDoc = await _usersRef.doc(receiverId).get();
      if (receiverDoc.exists) {
        final receiverData = receiverDoc.data() as Map<String, dynamic>;
        receiverName = receiverData['username'] ?? 
                      '${receiverData['firstName'] ?? ''} ${receiverData['lastName'] ?? ''}'.trim();
        if (receiverName.isEmpty) receiverName = 'User';
      }
    } catch (e) {
      debugPrint('⚠️ DEBUG: Kullanıcı bilgileri alınamadı: $e');
    }

    final messageId = _messagesRef.doc().id;
    final timestamp = FieldValue.serverTimestamp();

    // DEBUG: Mesaj verilerini logla
    final messageData = {
      'id': messageId,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'content': content,
      'type': type.toString().split('.').last,
      'status': MessageStatus.sent.toString().split('.').last,
      'createdAt': timestamp,
      'isRead': false,
      'deletedFor': <String>[],
    };
    debugPrint('📝 DEBUG: Mesaj verisi: $messageData');

    try {
      // Mesajı Firestore'a kaydet
      await _messagesRef.doc(messageId).set(messageData);
      debugPrint('✅ DEBUG: Mesaj başarıyla kaydedildi - ID: $messageId');
    } catch (e) {
      debugPrint('❌ DEBUG: Mesaj kaydetme hatası: $e');
      rethrow;
    }

    // Conversation'ı güncelle - son mesaj bilgileri
    await _conversationsRef.doc(conversationId).set({
      'lastMessage': content,
      'lastMessageTime': timestamp,
      'lastMessageSenderId': senderId,
      'updatedAt': FieldValue.serverTimestamp(),
      'unreadCount': {
        receiverId: FieldValue.increment(1),
      },
      'metadata': {
        'lastSenderName': senderName,
        'lastReceiverName': receiverName,
      },
    }, SetOptions(merge: true));

    // print('📤 Mesaj gönderildi: $messageId');
  }

  /// Sohbetteki mesajları dinle (gerçek zamanlı)
  /// 
  /// @param conversationId - Sohbet ID'si
  /// @returns `Stream<List<Message>>` - Mesajların gerçek zamanlı stream'i
  Stream<List<Message>> getMessagesStream(String conversationId) {
    debugPrint('👁️ DEBUG: Mesajları dinlemeye başlanıyor - Conversation ID: $conversationId');
    debugPrint('👁️ DEBUG: Current user: $currentUserId');
    
    return _messagesRef
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      debugPrint('👁️ DEBUG: Mesaj snapshot alındı - ${snapshot.docs.length} mesaj');
      
      if (snapshot.docs.isEmpty) {
        debugPrint('⚠️ DEBUG: Hiç mesaj bulunamadı');
      }
      
      final currentId = currentUserId;
      final filteredDocs = snapshot.docs.where((doc) {
        if (currentId == null) return true;
        final data = doc.data() as Map<String, dynamic>;
        final List<dynamic>? deletedFor = data['deletedFor'] as List<dynamic>?;
        if (deletedFor == null) return true;
        return !deletedFor.contains(currentId);
      });

      return filteredDocs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        debugPrint('👁️ DEBUG: Mesaj verisi: ${doc.id} -> $data');
        return MessageFirestore.fromFirestore(data);
      }).toList();
    }).handleError((error) {
      debugPrint('❌ DEBUG: Mesaj stream hatası: $error');
      throw error;
    });
  }

  /// Mevcut kullanıcının tüm sohbetlerini dinle
  /// 
  /// @returns `Stream<List<Conversation>>` - Sohbet listesinin gerçek zamanlı stream'i
  Stream<List<Conversation>> getConversationsStream() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _conversationsRef
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      // Manuel sorting - index sorunu için
      final docs = snapshot.docs.toList();
      docs.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        
        // Safe Timestamp casting with type checks
        final aTime = aData['lastMessageTime'] is Timestamp 
            ? aData['lastMessageTime'] as Timestamp?
            : null;
        final bTime = bData['lastMessageTime'] is Timestamp 
            ? bData['lastMessageTime'] as Timestamp?
            : null;
            
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime); // descending
      });
      // Per-user hide: filter out conversations hidden by current user
      final filteredDocs = docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final List<dynamic>? deletedFor = data['deletedFor'] as List<dynamic>?;
        if (deletedFor == null) return true;
        return !deletedFor.contains(userId);
      }).toList();

      return filteredDocs.map((doc) {
        return Conversation.fromFirestore(doc);
      }).toList();
    });
  }

  /// Mesajları okundu olarak işaretle
  /// 
  /// @param conversationId - Sohbet ID'si
  Future<void> markMessagesAsRead(String conversationId) async {
    final userId = currentUserId;
    debugPrint('🔍 markMessagesAsRead başlatıldı - ConversationId: $conversationId, UserId: $userId');
    if (userId == null) {
      debugPrint('❌ UserId null, işlem iptal edildi');
      return;
    }

    // Bu kullanıcıya gönderilen okunmamış mesajları bul ve güncelle
    final unreadMessages = await _messagesRef
        .where('conversationId', isEqualTo: conversationId)
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    debugPrint('🔍 Okunmamış mesaj sayısı: ${unreadMessages.docs.length}');

    // Batch write ile tüm mesajları okundu olarak işaretle
    final batch = _firestore.batch();
    
    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        // Okundu bilgisi zenginleştirme: durum ve zaman damgası eklenir
        'status': MessageStatus.read.name,
        'readAt': FieldValue.serverTimestamp(),
      });
    }

    // Conversation'daki unread count'u sıfırla
    batch.update(_conversationsRef.doc(conversationId), {
      'unreadCount.$userId': 0,
    });

    await batch.commit();
    debugPrint('✅ Mesajlar okundu olarak işaretlendi: ${unreadMessages.docs.length} mesaj, unreadCount sıfırlandı');
  }

  /// Servis kaynaklarını temizle
  void dispose() {
    // Kullanıcıyı çevrimdışı yap
    setUserOffline();
  }
}

extension ConversationHiding on FirebaseChatService {
  /// Hide a conversation in the list only for the current user
  Future<void> hideConversationForCurrentUser(String conversationId) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      await _conversationsRef.doc(conversationId).update({
        'deletedFor': FieldValue.arrayUnion([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Conversation hidden for user: $conversationId -> $userId');
    } catch (e) {
      debugPrint('❌ Failed to hide conversation: $e');
      rethrow;
    }
  }
}

/// Message entity'sine Firestore desteği ekleyen extension
extension MessageFirestore on Message {
  /// Firestore verilerinden Message oluştur
  static Message fromFirestore(Map<String, dynamic> data) {
    return Message(
      id: data['id'] ?? '',
      conversationId: data['conversationId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Unknown',
      receiverId: data['receiverId'] ?? '',
      receiverName: data['receiverName'] ?? 'Unknown',
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => MessageStatus.sent,
      ),
      content: data['content'] ?? '',
      // Attachments alanını güvenli şekilde map'leriz; yoksa boş liste döner
      attachments: List<String>.from(data['attachments'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Message'ı Firestore formatına çevir
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': status == MessageStatus.read,
    };
  }
}

/// Conversation entity'sine Firestore desteği ekleyen extension
extension ConversationFirestore on Conversation {
  /// Firestore verilerinden Conversation oluştur
  /// 
  /// @param data - Firestore document data
  /// @param documentId - Optional document ID for fallback
  static Conversation fromFirestore(Map<String, dynamic> data, {String? documentId}) {
    final participants = List<String>.from(data['participants'] ?? []);
    
    // Use data['id'] if available, fallback to documentId for backward compatibility
    final conversationId = data['id']?.toString() ?? documentId ?? '';
    
    return Conversation(
      id: conversationId,
      participants: participants,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessage: data['lastMessage'],
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
    );
  }
}
