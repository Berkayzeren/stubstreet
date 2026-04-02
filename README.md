<div align="center">
  <img src="assets/images/logo.png" alt="StubStreet Logo" width="200"/>
</div>

# StubStreet

StubStreet is a secure, user-friendly and transparent online marketplace where you can buy and sell second-hand tickets for everything from concerts and sports to theater and festivals.

## 🚀 Quick Start

### Prerequisites
- Flutter SDK ^3.8.1
- Firebase CLI
- Node.js (for Firebase emulators)
- Git

### Development Setup

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd stubstreet
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Set up Firebase:**
   ```bash
   firebase login
   firebase init
   ```

4. **Start development environment (Windows):**
   ```powershell
   .\scripts\dev_setup.ps1
   ```

5. **Start development environment (Unix/Linux/macOS):**
   ```bash
   ./scripts/dev_setup.sh
   ```

6. **Run the app:**
   ```bash
   flutter run
   ```

## 📱 Platform Support

- ✅ **Android** (API 21+)
- ✅ **iOS** (iOS 11+)
- ✅ **Web** (Responsive design)
- ✅ **Desktop** (Windows, macOS, Linux)

## 🔥 Key Features

- **🔐 Secure Authentication** - Firebase Auth with secure token storage
- **📱 Responsive Design** - Adaptive UI for mobile, tablet, and desktop
- **🎨 Material 3 Design** - Modern, accessible UI components
- **🚀 Real-time Updates** - Firestore integration
- **🔒 Secure Storage** - Encrypted local storage for sensitive data
- **🧪 Comprehensive Testing** - Unit, widget, and integration tests
- **🔄 CI/CD Pipeline** - Automated testing and deployment

## 🛠️ Development Tools

### Build Scripts
- `scripts/build.sh` - Quick build and test runner
- `scripts/dev_setup.ps1` - Windows development environment setup
- `scripts/dev_setup.sh` - Unix development environment setup

### Build Commands
```bash
# Flutter build commands
flutter build apk --release          # Android APK
flutter build ios --release          # iOS build
flutter build web --release          # Web build

# Firebase Functions build
cd functions
npm run build                         # TypeScript to JavaScript
npm run test                          # Run tests
npm run serve                         # Local emulator

# Development build with hot reload
flutter run                           # Development mode
flutter run --release                 # Release mode
```

### Deploy Commands
```bash
# Firebase deployment
firebase deploy                       # Deploy all services
firebase deploy --only functions     # Deploy only functions
firebase deploy --only firestore     # Deploy only Firestore rules
firebase deploy --only hosting       # Deploy only web hosting

# Environment specific deployment
firebase use staging                  # Switch to staging
firebase deploy                       # Deploy to staging

firebase use production               # Switch to production
firebase deploy                       # Deploy to production

# Flutter deployment
flutter build web --release && firebase deploy --only hosting

# Mobile app deployment
flutter build appbundle --release    # Android App Bundle
flutter build ipa --release          # iOS App Store
```

### Testing
```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test/
```

### Code Generation
```bash
# Generate Riverpod providers and JSON serialization
flutter packages pub run build_runner build

# Watch for changes
flutter packages pub run build_runner watch
```

## 🔄 Migration Notes

### From v1.0.0 to v1.1.0

#### ⚠️ Breaking Changes

**Authentication System Overhaul:**
- Migration from basic Firebase Auth to secure token-based authentication
- **Action Required:** Existing users will need to re-authenticate due to enhanced security measures
- New `AuthStateManager` handles token validation and refresh automatically

**Secure Storage Implementation:**
- Added `flutter_secure_storage` for encrypted local storage
- **Action Required:** Clear app data on first launch after update to initialize secure storage
- Sensitive data (tokens, user preferences) now stored securely

**UI Architecture Changes:**
- Migrated to Material 3 design system
- Responsive layouts replace fixed-size components
- **Action Required:** Custom themes may need adjustment for Material 3 compatibility

#### 🔧 Configuration Updates

**Firebase Configuration:**
- Updated `firebase.json` with emulator support
- Added development environment emulator settings
- **Action Required:** Run `firebase init` to update local configuration

**Build Configuration:**
- Android: Updated to target API 34, minimum API 21
- iOS: Added App Store Connect configuration
- **Action Required:** Update development certificates for iOS builds

**Dependencies:**
- Added: `flutter_secure_storage`, `flutter_riverpod`, `riverpod_annotation`
- Updated: All Firebase dependencies to latest versions
- **Action Required:** Run `flutter pub get` after pulling changes

#### 📚 New Development Workflow

**Local Development:**
- Firebase emulators now used for local development
- Automated setup scripts for consistent development environment
- **Action Required:** Install Firebase CLI and Node.js for emulator support

**Testing:**
- Comprehensive test suite with mocks and integration tests
- Coverage reporting enabled
- **Action Required:** Review test files for any custom test modifications

**CI/CD Pipeline:**
- GitHub Actions workflow for automated testing and deployment
- Firebase App Distribution for beta releases
- TestFlight integration for iOS releases
- **Action Required:** Configure repository secrets for Firebase and App Store Connect

## 🏗️ Architecture

### State Management
- **Riverpod** for dependency injection and state management
- **Provider pattern** for service layer architecture
- **Repository pattern** for data access layer

### Project Structure
```
lib/
├── core/           # Core utilities and constants
├── features/       # Feature-based modules
├── services/       # Business logic and API services
├── widgets/        # Reusable UI components
└── main.dart       # Application entry point

test/
├── unit/          # Unit tests
├── widget/        # Widget tests
└── integration/   # Integration tests

scripts/           # Build and development scripts
.github/           # CI/CD workflows
```

## 🔧 Configuration

### Environment Variables
Create a `.env` file in the root directory:
```
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_API_KEY=your-api-key

# Firebase Functions Environment Variables
FIREBASE_FUNCTION_URL=https://us-central1-your-project.cloudfunctions.net
FIREBASE_REGION=us-central1
SOCKET_IO_URL=https://your-socket-server.com

# Stripe Payment Configuration
STRIPE_PUBLISHABLE_KEY=pk_test_xxxxx
STRIPE_SECRET_KEY=sk_test_xxxxx
STRIPE_WEBHOOK_SECRET=whsec_xxxxx


# Image Processing
MAX_FILE_SIZE=10485760  # 10MB
ALLOWED_IMAGE_TYPES=jpg,jpeg,png,gif,webp
THUMB_MAX_WIDTH=200
THUMB_MAX_HEIGHT=200
MEDIUM_MAX_WIDTH=800
MEDIUM_MAX_HEIGHT=600

# Rate Limiting
RATE_LIMIT_WINDOW=900000  # 15 minutes
RATE_LIMIT_MAX_REQUESTS=100
```

### Firebase Setup
1. Create a Firebase project
2. Enable Authentication, Firestore, and Storage
3. Download configuration files:
   - `google-services.json` (Android) → `android/app/`
   - `GoogleService-Info.plist` (iOS) → `ios/Runner/`
4. Configure web app settings

## 🚀 Deployment

### Firebase Configuration Requirements

Bu deployment'ı tamamlamak için Firebase Console'da şu işlemleri yapmanız gerekir:

#### 1. Firebase Project Upgrade
- Project'inizi **Blaze (Pay-as-you-go)** planına yükseltmeniz gerekir
- Cloud Functions ve diğer servisler için gerekli
- URL: `https://console.firebase.google.com/project/device-streaming-70d2d53c/usage/details`

#### 2. Firebase Services Activation
Firebase Console'dan şu servisleri aktif etmeniz gerekir:

**Authentication:**
- Email/Password provider'ı aktif edin
- Authorized domains listesine deployment domain'inizi ekleyin

**Firestore Database:**
- Firestore Database'i aktif edin
- `firestore.rules` dosyası otomatik olarak deploy edilecek
- `firestore.indexes.json` dosyası otomatik olarak deploy edilecek

**Cloud Storage:**
- Cloud Storage'ı aktif edin
- `storage.rules` dosyası varsa deploy edilecek

**Cloud Functions:**
- Cloud Functions API'sini aktif edin
- Cloud Build API'sini aktif edin
- Artifact Registry API'sini aktif edin

#### 3. Environment Variables (Functions)
Cloud Functions için environment variables'ları ayarlayın:
```bash
firebase functions:config:set \
  api.rate_limit_window=900000 \
  api.rate_limit_max_requests=100 \
  storage.max_file_size=10485760 \
  storage.allowed_image_types="jpg,jpeg,png,gif,webp" \
  image.thumb_max_width=200 \
  image.thumb_max_height=200 \
  image.medium_max_width=800 \
  image.medium_max_height=600
```

#### 4. Deployment Commands

**Complete Deployment:**
```bash
# Tüm Firebase servislerini deploy et
firebase deploy
```

**Selective Deployment:**
```bash
# Sadece Functions deploy et
firebase deploy --only functions

# Sadece Firestore rules deploy et
firebase deploy --only firestore:rules

# Sadece Firestore indexes deploy et
firebase deploy --only firestore:indexes

# Sadece Storage rules deploy et
firebase deploy --only storage
```

### Automated Deployment
Deployment is handled automatically through GitHub Actions:
- **Pull Request:** Runs tests and builds
- **Development branch:** Deploys to Firebase App Distribution
- **Main branch:** Deploys to production (App Store/Google Play)

### Manual Deployment
```bash
# Build for release
flutter build apk --release
flutter build ios --release
flutter build web --release

# Deploy to Firebase Hosting (web)
firebase deploy --only hosting
```

### Post-Deployment Verification

1. **Test API Endpoints:**
   ```bash
   curl -X GET "https://us-central1-your-project.cloudfunctions.net/api/v1/conversations" \
   -H "Authorization: Bearer YOUR_FIREBASE_TOKEN"
   ```

2. **Test WebSocket Connection:**
   ```javascript
   const socket = io('https://us-central1-your-project.cloudfunctions.net', {
     auth: { token: 'YOUR_FIREBASE_TOKEN' }
   });
   ```

3. **Check Firestore Rules:**
   - Firebase Console'da Firestore > Rules sekmesinden rules'ların deploy edildiğini kontrol edin

4. **Check Indexes:**
   - Firebase Console'da Firestore > Indexes sekmesinden index'lerin oluşturulduğunu kontrol edin

## 📖 Documentation

- [API Documentation](docs/api.md)
- [Payment Setup Guide](docs/PAYMENT_SETUP_GUIDE.md)
- [UI/UX Guidelines](docs/ui_guidelines.md)
- [Security Guidelines](docs/security.md)
- [Testing Guidelines](docs/testing.md)
- [CI/CD Pipeline Setup](docs/CI_PIPELINE_SETUP.md)

### 📮 Postman Collection

API'leri test etmek için Postman koleksiyonu mevcuttur:

1. **Koleksiyon Dosyası**: `docs/postman/StubStreet_Payments_API.postman_collection.json`
2. **Kurulum**:
   - Postman'ı açın
   - "Import" butonuna tıklayın
   - Koleksiyon dosyasını seçin
   - Environment variables'ları ayarlayın:
     - `base_url`: API base URL'i
     - `firebase_token`: Firebase Auth token'ı
     - `user_id`: Test user ID'si

3. **Koleksiyon İçeriği**:
   - **Payments**: Ödeme başlatma, sorgulama, kullanıcı ödemeleri
   - **Webhooks**: Stripe ve İyzico webhook testleri
   - **Test Scenarios**: Başarılı/başarısız ödeme senaryoları

4. **Kullanım**:
   ```bash
   # Environment variables ayarlayın
   base_url: https://us-central1-your-project.cloudfunctions.net/api
   firebase_token: your_firebase_auth_token
   user_id: your_test_user_id
   
   # Request'leri çalıştırın
   - Initialize Stripe Payment
   - Initialize İyzico Payment
   - Get Payment Details
   - Test webhook endpoints
   ```

## 🚀 API Endpoints

### Authentication
Tüm API endpoint'leri Firebase Authentication token gerektirir. Token'ı `Authorization: Bearer <token>` header'ında gönderin.

### Base URL
```
https://us-central1-your-project.cloudfunctions.net/api
```

### Payments API

#### Initialize Payment
```http
POST /v1/payments/init
Authorization: Bearer <firebase_token>
Content-Type: application/json

{
  "amount": 100,
  "currency": "TRY",
  "provider": "stripe"
  "userId": "user123",
  "email": "user@example.com",
  "description": "Test Payment",
  "metadata": {
    "orderId": "order_123",
    "eventId": "event_456"
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "paymentId": "uuid-payment-id",
    "status": "requires_payment_method",
    "clientSecret": "pi_test_xxxxx_secret_xxxxx", // Stripe only
    "data": {
      "paymentIntentId": "pi_test_xxxxx"
    }
  }
}
```

#### Get Payment Details
```http
GET /v1/payments/{paymentId}
Authorization: Bearer <firebase_token>
```

#### Get User Payments
```http
GET /v1/payments/user/{userId}
Authorization: Bearer <firebase_token>
```

#### Webhook Endpoints
```http
POST /v1/webhooks/stripe
Content-Type: application/json
stripe-signature: t=1234567890,v1=signature_hash

```

### Conversations API

#### Get Conversations
```http
GET /v1/conversations?limit=20&cursor=doc_id
Authorization: Bearer <firebase_token>
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "conv_123",
      "participants": ["user1", "user2"],
      "title": "Chat Title",
      "type": "private",
      "lastMessage": null,
      "createdAt": "2024-01-01T00:00:00Z",
      "updatedAt": "2024-01-01T00:00:00Z",
      "isActive": true
    }
  ],
  "message": "Conversations başarıyla getirildi"
}
```

#### Create Conversation
```http
POST /v1/conversations
Authorization: Bearer <firebase_token>
Content-Type: application/json

{
  "participants": ["user1", "user2"],
  "title": "New Chat",
  "type": "private"
}
```

### Messages API

#### Get Messages
```http
GET /v1/conversations/conv_123/messages?limit=10&cursor=doc_id
Authorization: Bearer <firebase_token>
```

#### Send Message
```http
POST /v1/conversations/conv_123/messages
Authorization: Bearer <firebase_token>
Content-Type: application/json

{
  "content": "Hello, world!"
}
```

#### Mark Message as Read
```http
PUT /v1/messages/msg_123/read
Authorization: Bearer <firebase_token>
```

#### Add/Remove Reaction
```http
POST /v1/messages/msg_123/reactions
Authorization: Bearer <firebase_token>
Content-Type: application/json

{
  "emoji": "👍"
}
```

### Image Processing API

#### Get Image Variants
```http
GET /image-variants?imagePath=path/to/image.jpg
```

**Response:**
```json
{
  "original": "path/to/image.jpg",
  "thumbnail": "https://signed-url-for-thumbnail",
  "compressed": "https://signed-url-for-compressed"
}
```

## 🔌 WebSocket Events

### Connection
```javascript
const io = require('socket.io-client');
const socket = io('https://your-socket-server.com', {
  auth: {
    token: 'firebase_auth_token'
  }
});
```

### User Events

#### User Online/Offline
```javascript
// Kullanıcı online olduğunda
socket.on('user:online', (data) => {
  console.log('User came online:', data);
  // { userId: 'user123', timestamp: 1640995200000 }
});

// Kullanıcı offline olduğunda
socket.on('user:offline', (data) => {
  console.log('User went offline:', data);
  // { userId: 'user123', timestamp: 1640995200000 }
});
```

#### Join/Leave Conversation
```javascript
// Conversation'a katılma
socket.emit('joinConversation', 'conv_123');

// Conversation'dan ayrılma
socket.emit('leaveConversation', 'conv_123');

// Kullanıcı conversation'a katıldığında
socket.on('user:joined', (data) => {
  // { userId: 'user123', conversationId: 'conv_123', timestamp: 1640995200000 }
});

// Kullanıcı conversation'dan ayrıldığında
socket.on('user:left', (data) => {
  // { userId: 'user123', conversationId: 'conv_123', timestamp: 1640995200000 }
});
```

### Conversation Events

#### Conversation Created/Updated/Deleted
```javascript
// Yeni conversation oluşturulduğunda
socket.on('conversation:created', (data) => {
  console.log('New conversation created:', data);
  /*
  {
    conversationId: 'conv_123',
    conversation: { ... },
    createdBy: 'user123',
    timestamp: 1640995200000
  }
  */
});

// Conversation güncellendiğinde
socket.on('conversation:updated', (data) => {
  console.log('Conversation updated:', data);
  /*
  {
    conversationId: 'conv_123',
    conversation: { ... },
    updatedBy: 'user123',
    changes: { title: 'New Title' },
    timestamp: 1640995200000
  }
  */
});

// Conversation silindiğinde
socket.on('conversation:deleted', (data) => {
  console.log('Conversation deleted:', data);
  /*
  {
    conversationId: 'conv_123',
    deletedBy: 'user123',
    timestamp: 1640995200000
  }
  */
});
```

### Message Events

#### Message Created/Updated/Deleted
```javascript
// Yeni mesaj geldiğinde
socket.on('message:created', (data) => {
  console.log('New message:', data);
  /*
  {
    messageId: 'msg_123',
    conversationId: 'conv_123',
    senderId: 'user123',
    content: 'Hello!',
    timestamp: 1640995200000,
    message: { ... }
  }
  */
});

// Mesaj güncellendiğinde
socket.on('message:updated', (data) => {
  console.log('Message updated:', data);
});

// Mesaj silindiğinde
socket.on('message:deleted', (data) => {
  console.log('Message deleted:', data);
});
```

#### Message Read/Reactions
```javascript
// Mesaj okunduğunda
socket.on('message:read', (data) => {
  console.log('Message read:', data);
  /*
  {
    messageId: 'msg_123',
    conversationId: 'conv_123',
    userId: 'user123',
    readReceipt: { ... },
    timestamp: 1640995200000
  }
  */
});

// Mesaj reaksiyonu eklendiğinde/kaldırıldığında
socket.on('message:reaction', (data) => {
  console.log('Message reaction:', data);
  /*
  {
    messageId: 'msg_123',
    conversationId: 'conv_123',
    userId: 'user123',
    emoji: '👍',
    action: 'added' | 'removed',
    timestamp: 1640995200000
  }
  */
});
```

### Typing Events

```javascript
// Typing başladığında
socket.emit('typing:start', { conversationId: 'conv_123' });

// Typing bittiğinde
socket.emit('typing:stop', { conversationId: 'conv_123' });

// Diğer kullanıcı typing başladığında
socket.on('typing:start', (data) => {
  console.log('User started typing:', data);
  /*
  {
    userId: 'user123',
    conversationId: 'conv_123',
    timestamp: 1640995200000
  }
  */
});

// Diğer kullanıcı typing bitirdiğinde
socket.on('typing:stop', (data) => {
  console.log('User stopped typing:', data);
});
```

### Error Handling

```javascript
// Bağlantı hatası
socket.on('error', (error) => {
  console.error('Socket error:', error);
});

// Bağlantı kesildiğinde
socket.on('disconnect', (reason) => {
  console.log('Disconnected:', reason);
});

// Tekrar bağlanmaya çalışırken
socket.on('reconnect_attempt', (attemptNumber) => {
  console.log('Reconnection attempt:', attemptNumber);
});
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support, email support@stubstreet.com or join our Discord community.

---

**Built with ❤️ using Flutter**
