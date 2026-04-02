// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/language_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'firebase_options.dart';
import 'core/services/app_lifecycle_manager.dart';
import 'features/conversations/presentation/providers/firebase_chat_providers.dart';
import 'core/config/dev_config.dart';
import 'core/services/app_prefs.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'features/auth/presentation/screens/register_account_screen.dart';
import 'features/auth/presentation/screens/register_identity_screen.dart';
import 'features/auth/presentation/screens/register_agreements_screen.dart';
import 'core/navigation/custom_page_route.dart';
import 'core/navigation/route_observer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Static variables to track logging state and reduce repeated debug prints
String? _lastLoggedUserId;
bool _hasShownLoginRedirect = false;
bool _hasShownHomeRedirect = false;
bool _hasShownLoading = false;
bool _hasShownError = false;
bool _hasShownGuestRedirect = false;

/// Background initialization tasks to avoid blocking the UI
void _runBackgroundInitialization() {
  // Run these tasks asynchronously without waiting
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Execute after a delay to ensure UI is fully rendered
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        // DEBUG: Create admin user if not exists
        await _createAdminUserIfNotExists();
      } catch (e) {
        debugPrint('❌ Admin user creation failed: $e');
      }
      
      // Add more delay between operations to prevent blocking
      await Future.delayed(const Duration(milliseconds: 100));
      
      try {
        // DEBUG: Create usernameIndex for existing users
        await _createUsernameIndexForExistingUsers();
      } catch (e) {
        debugPrint('❌ UsernameIndex creation failed: $e');
      }
      
      // Add more delay between operations
      await Future.delayed(const Duration(milliseconds: 100));
      
      try {
        // DEBUG: Create username for test user if missing
        await _createUsernameForTestUser();
      } catch (e) {
        debugPrint('❌ Test user username creation failed: $e');
      }
    });
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('❌ Firebase initialization failed: $e');
    // Don't exit on Firebase init failure, continue with app
  }

  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('✅ .env yüklendi');
  } catch (e) {
    debugPrint('⚠️ .env yüklenemedi: $e');
  }

  // Configure development emulators
  try {
    DevConfig.configureEmulators();
  } catch (e) {
    debugPrint('❌ Emulator configuration failed: $e');
    // Continue without emulators
  }

  // Init local prefs (for onboarding flag)
  try {
    await AppPrefs.init();
  } catch (e) {
    debugPrint('❌ AppPrefs init failed: $e');
    // Continue without prefs
  }
  
  // Initialize SharedPreferences for providers
  final sharedPreferences = await SharedPreferences.getInstance();
  
  // Development: Reset onboarding if requested or in debug mode with special flag
  const resetOnboarding = String.fromEnvironment('RESET_ONBOARDING', defaultValue: '');
  if (resetOnboarding.toLowerCase() == 'true') {
    await AppPrefs.resetOnboarding();
    await AppPrefs.clearGuestMode();
    debugPrint('🔄 Onboarding and guest mode reset for development');
  }
  
  // Güvenlik: Eğer kullanıcı oturum açmışsa guest modunu temizle, aksi halde koru
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    await AppPrefs.clearGuestMode();
    debugPrint('🔒 Guest mode cleared for authenticated session (${currentUser.uid})');
  }
  
  // DEBUG: Run background initialization tasks without blocking UI
  _runBackgroundInitialization();
  
  // Debug: Force reset onboarding and auth for testing
  // COMMENTED OUT: This was causing users to be automatically signed out in debug mode
  // which prevented authenticated users from accessing the messages section
  /*
  if (kDebugMode) {
    // Clear Hive box completely for testing
    final box = Hive.box('app_prefs');
    await box.clear();
    debugPrint('🔄 Debug: All preferences cleared for testing');
    
    // Sign out user for testing
    await FirebaseAuth.instance.signOut();
    debugPrint('🔄 Debug: User signed out for testing');
    
    // Re-initialize AppPrefs
    await AppPrefs.init();
  }
  */

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MyApp(),
    ),
  );
}

/// Admin kullanıcısı oluşturur (eğer yoksa)
Future<void> _createAdminUserIfNotExists() async {
  try {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;
    
    // Admin email ile giriş yapmayı dene
    try {
      final signInResult = await auth.signInWithEmailAndPassword(
        email: 'admin@biletsokagi.com',
        password: '123456',
      );
      
      if (signInResult.user != null) {
        debugPrint('✅ Admin kullanıcısı zaten mevcut ve giriş başarılı');
        return;
      }
    } catch (e) {
      // Kullanıcı yoksa oluştur
      debugPrint('🔍 Admin kullanıcısı bulunamadı, oluşturuluyor...');
    }
    
    // Admin kullanıcısını oluştur
    final userCredential = await auth.createUserWithEmailAndPassword(
      email: 'admin@biletsokagi.com',
      password: '123456',
    );
    
    final user = userCredential.user!;
    debugPrint('✅ Admin kullanıcısı oluşturuldu: ${user.uid}');
    
    // Display name'i güncelle
    await user.updateDisplayName('Admin');
    await user.reload();
    
    // Users koleksiyonuna admin verilerini ekle
    await firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': 'admin@biletsokagi.com',
      'displayName': 'Admin',
      'firstName': 'Admin',
      'lastName': 'User',
      'username': 'admin',
      'phoneNumber': '+905551234567',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isVerified': true,
      'rating': 5.0,
      'totalSales': 0,
      'totalPurchases': 0,
      'followersCount': 0,
      'followingCount': 0,
      'role': 'admin',
      'status': 'active',
      'isAdmin': true,
    });
    
    debugPrint('✅ Admin kullanıcı verileri Firestore\'a eklendi');
    
    // UsernameIndex'e admin kullanıcısını ekle
    await firestore.collection('usernameIndex').doc('admin').set({
      'username': 'admin',
      'email': 'admin@biletsokagi.com',
      'uid': user.uid,
      'role': 'admin',
      'status': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    debugPrint('✅ Admin kullanıcısı UsernameIndex\'e eklendi');
    debugPrint('📧 Admin Email: admin@biletsokagi.com');
    debugPrint('🔑 Admin Şifre: 123456');
    debugPrint('👤 Admin Kullanıcı adı: admin');
    
  } catch (e) {
    debugPrint('❌ Admin kullanıcısı oluşturulurken hata: $e');
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tema ve dil durumunu dinle
    final themeMode = ref.watch(themeNotifierProvider);
    final locale = ref.watch(languageNotifierProvider);
    
    // AppLifecycleManager'ı başlat
    ref.read(appLifecycleManagerProvider);
    
    // AuthStatusHandler'ı başlat
    ref.read(authStatusHandlerProvider);

    // Tüm named route'lar için ortak builder haritası
    final routeBuilders = <String, WidgetBuilder>{
      '/': (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final tabIndex = args?['tabIndex'] as int?;
        
        return Builder(
          builder: (context) {
            final seenOnboarding = AppPrefs.getOnboardingCompleted();
            
            // Onboarding sadece bir kez gösterilmeli
            if (!seenOnboarding) {
              return const OnboardingScreen();
            }
            
            // After onboarding, check auth state
            return Consumer(
              builder: (context, ref, child) {
                final authState = ref.watch(authStateChangesProvider);
                final isGuest = AppPrefs.getIsGuestUser();
                
                return authState.when(
                  data: (user) {
                    // Only log when user actually changes to reduce noise
                    if (user?.uid != _lastLoggedUserId) {
                      debugPrint('🔐 Auth check after onboarding - User: ${user?.uid}, Guest: $isGuest');
                      _lastLoggedUserId = user?.uid;
                    }
                    
                    // SECURITY: Only authenticated users can access the app
                    if (user == null) {
                      if (isGuest) {
                        if (!_hasShownGuestRedirect) {
                          debugPrint('👤 Guest mode aktif - HomeScreen misafir modunda açılıyor');
                          _hasShownGuestRedirect = true;
                        }
                        return HomeScreen(
                          initialTabIndex: tabIndex,
                          isGuestMode: true,
                        );
                      }
                      if (!_hasShownLoginRedirect) {
                        debugPrint('➡️ No user authenticated - Redirecting to LoginScreen');
                        _hasShownLoginRedirect = true;
                      }
                      return const LoginScreen();
                    }
                    
                    // If user is authenticated -> Home
                    if (!_hasShownHomeRedirect) {
                      debugPrint('➡️ User authenticated - Redirecting to HomeScreen (uid: ${user.uid})');
                      _hasShownHomeRedirect = true;
                    }
                    return PopScope(
                      canPop: false,
                      onPopInvokedWithResult: (didPop, result) {
                        // Kök ekranda geri (fiziksel veya swipe) ile uygulamadan çıkışı engelle
                        // Kullanıcıyı yanlışlıkla kapatmamak için canPop: false
                      },
                      child: HomeScreen(
                        initialTabIndex: tabIndex,
                        isGuestMode: false,  // No guest mode allowed
                      ),
                    );
                  },
                  loading: () {
                    if (!_hasShownLoading) {
                      debugPrint('⏳ Auth state loading...');
                      _hasShownLoading = true;
                    }
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  },
                  error: (error, stack) {
                    if (!_hasShownError) {
                      debugPrint('❌ Auth error: $error');
                      _hasShownError = true;
                    }
                    // SECURITY: On auth error, always go to login
                    return const LoginScreen();
                  },
                );
              },
            );
          },
        );
      },
      '/home': (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final tabIndex = args?['tabIndex'] as int?;
        final isGuestFromArgs = args?['isGuestMode'] as bool?;
        final isGuestPrefs = AppPrefs.getIsGuestUser();
        return HomeScreen(
          initialTabIndex: tabIndex,
          isGuestMode: isGuestFromArgs ?? isGuestPrefs,
        );
      },
      '/login': (context) => const LoginScreen(),
      '/register/account': (context) => const RegisterAccountScreen(),
      '/register/identity': (context) => const RegisterIdentityScreen(),
      '/register/agreements': (context) => const RegisterAgreementsScreen(),
    };

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // --- Dil Ayarları (Improved) ---
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'), // Turkish
        Locale('en', 'US'), // English
      ],
      locale: locale, // Use provider's locale
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        // Provider locale has priority over device locale
        return supportedLocales.contains(locale) ? locale : supportedLocales.first;
      },
      onGenerateTitle: (context) {
        return AppLocalizations.of(context)?.appTitle ?? 'StubStreet';
      },

      // ===============================================================
      // ====                TEMA YÖNETİMİ EKLENDİ                  ====
      // ===============================================================
      // `ThemeData`'yı doğrudan yazmak yerine, oluşturduğumuz AppTheme sınıfından çağırıyoruz.
      // Swipe-back navigation support dahil edildi
      theme: AppTheme.lightTheme.copyWith(
        pageTransitionsTheme: const CustomPageTransitionsTheme(),
      ),
      // Karanlık tema için de aynı şekilde.
      darkTheme: AppTheme.darkTheme.copyWith(
        pageTransitionsTheme: const CustomPageTransitionsTheme(),
      ),
      // Hangi temanın aktif olacağını provider'dan gelen değere göre belirliyoruz.
      // Bu değer (ThemeMode.light, ThemeMode.dark, veya ThemeMode.system) olabilir.
      themeMode: themeMode,
      
      // Navigation observer for tracking route changes
      navigatorObservers: [
        SwipeBackRouteObserver(),
      ],
      // ===============================================================

      // --- Static Routes Definition ---
      routes: routeBuilders,
      // Tüm named route'lar için CustomPageRoute ile swipe-back sarmalayıcı uygula
      onGenerateRoute: (settings) {
        final builder = routeBuilders[settings.name];
        if (builder != null) {
          return CustomPageRoute(
            builder: builder,
            settings: settings,
          );
        }
        return null;
      },
      // --- Initial Route ---
      initialRoute: '/',
    );
  }
}

/// Mevcut kullanıcılar için usernameIndex oluşturur
Future<void> _createUsernameIndexForExistingUsers() async {
  try {
    final firestore = FirebaseFirestore.instance;
    
    debugPrint('🔍 Mevcut kullanıcılar için usernameIndex oluşturuluyor...');
    
    // Users koleksiyonundaki tüm kullanıcıları al
    final usersSnapshot = await firestore.collection('users').get();
    debugPrint('📊 ${usersSnapshot.docs.length} kullanıcı bulundu');
    
    // UsernameIndex koleksiyonunu kontrol et
    final usernameIndexSnapshot = await firestore.collection('usernameIndex').get();
    debugPrint('📊 UsernameIndex\'te ${usernameIndexSnapshot.docs.length} kayıt var');
    
    // Eğer usernameIndex boşsa, mevcut kullanıcılar için oluştur
    if (usernameIndexSnapshot.docs.isEmpty) {
      debugPrint('🔧 UsernameIndex boş, mevcut kullanıcılar için oluşturuluyor...');
      
      // Batch write kullanarak performansı artır
      var batch = firestore.batch();
      int batchCount = 0;
      const maxBatchSize = 500; // Firestore batch limit
      
      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final email = userData['email'] as String?;
        final username = userData['username'] as String?;
        final displayName = userData['displayName'] as String?;
        
        if (email != null && username != null && username.isNotEmpty) {
          // Batch'e ekle
          final docRef = firestore.collection('usernameIndex').doc(username);
          batch.set(docRef, {
            'email': email,
            'uid': userDoc.id,
            'displayName': displayName ?? username,
            'createdAt': FieldValue.serverTimestamp(),
          });
          
          batchCount++;
          debugPrint('✅ UsernameIndex eklendi: $username -> $email');
          
          // Batch boyutu limit'e ulaştıysa commit et
          if (batchCount >= maxBatchSize) {
            await batch.commit();
            debugPrint('📦 Batch committed ($batchCount operations)');
            // Yeni batch başlat - batch değişkenini güncelle
            batch = firestore.batch();
            batchCount = 0;
          }
        } else {
          debugPrint('⚠️ Kullanıcı atlandı - Email: $email, Username: $username');
        }
      }
      
      // Kalan batch'i commit et
      if (batchCount > 0) {
        await batch.commit();
        debugPrint('📦 Final batch committed ($batchCount operations)');
      }
      
      debugPrint('🎉 UsernameIndex oluşturma tamamlandı!');
    } else {
      debugPrint('ℹ️ UsernameIndex zaten mevcut, atlanıyor...');
    }
    
  } catch (e) {
    debugPrint('❌ UsernameIndex oluşturma hatası: $e');
  }
}

/// Test kullanıcısı için kullanıcı adı oluşturur
Future<void> _createUsernameForTestUser() async {
  try {
    final firestore = FirebaseFirestore.instance;
    final currentUser = FirebaseAuth.instance.currentUser;
    
    // Sadece test kullanıcısı giriş yaptığında çalıştır
    if (currentUser?.uid != 'hxmDvQYOrKT04UF8Y5cEX1rRxzg1') {
      debugPrint('ℹ️ Test kullanıcısı giriş yapmamış, atlanıyor...');
      return;
    }
    
    debugPrint('🔍 Test kullanıcısı için kullanıcı adı kontrol ediliyor...');
    
    // Test kullanıcısının verilerini al
    final testUserDoc = await firestore.collection('users').doc('hxmDvQYOrKT04UF8Y5cEX1rRxzg1').get();
    
    if (testUserDoc.exists) {
      final userData = testUserDoc.data() as Map<String, dynamic>;
      String? username = (userData['username'] as String?)?.trim();

      if (username == null || username.isEmpty) {
        debugPrint('🔧 Test kullanıcısı için kullanıcı adı oluşturuluyor...');

        username = 'testuser';
        // Test kullanıcısı için kullanıcı adı oluştur
        await firestore.collection('users').doc('hxmDvQYOrKT04UF8Y5cEX1rRxzg1').update({
          'username': username,
          'displayName': userData['displayName'] ?? 'Test User',
        });
      } else {
        debugPrint('ℹ️ Test kullanıcısının kullanıcı adı zaten mevcut: $username');
      }

      // UsernameIndex kaydını garanti altına al
      final indexRef = firestore.collection('usernameIndex').doc(username);
      final indexDoc = await indexRef.get();
      if (!indexDoc.exists) {
        debugPrint('🔧 Eksik usernameIndex kaydı oluşturuluyor: $username');
        await indexRef.set({
          'username': username,
          'email': userData['email'] ?? 'test@test.com',
          'uid': 'hxmDvQYOrKT04UF8Y5cEX1rRxzg1',
          'displayName': userData['displayName'] ?? 'Test User',
          'role': userData['role'] ?? 'buyer',
          'status': userData['status'] ?? 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ UsernameIndex kaydı oluşturuldu: $username');
      } else {
        debugPrint('ℹ️ UsernameIndex kaydı zaten mevcut: $username');
      }
    } else {
      debugPrint('⚠️ Test kullanıcısı bulunamadı');
    }
    
  } catch (e) {
    // Permission denied hatası bekleniyor - admin kullanıcısı başka kullanıcı için username oluşturamaz
    debugPrint('ℹ️ Test kullanıcısı kullanıcı adı oluşturma atlandı (beklenen durum): $e');
  }
}
