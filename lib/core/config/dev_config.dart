// lib/core/config/dev_config.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb, kDebugMode, debugPrint;

class DevConfig {
  /// Controls whether the app should connect to local Firebase emulators
  /// instead of real Firebase services.
  ///
  /// Why: In development we sometimes want to test against local emulators
  /// to avoid touching production data and to enable full offline testing.
  /// However, for normal development or QA against real backends, we should
  /// not enable emulators to match production-like behavior.
  ///
  /// How: We read a compile-time flag provided via `--dart-define` so that
  /// each developer or CI job can choose the mode without editing source code.
  /// Example usage:
  ///   flutter run --dart-define=USE_EMULATOR=true
  ///
  /// @returns bool - true to use emulators, false to use real services
  static const bool useEmulator = bool.fromEnvironment(
    'USE_EMULATOR',
    defaultValue: false,
  );
  // Host cihazına göre doğru emülatör host adresi
  static String get emulatorHost {
    if (kIsWeb) return 'localhost';
    // Android cihazı için bilgisayarın IP adresini kullan
    if (defaultTargetPlatform == TargetPlatform.android) return '192.168.1.102'; // Bilgisayarın IP adresi
    // iOS simülatörü/macOS/web için localhost uygundur
    return 'localhost';
  }
  static const int firestorePort = 8080;
  static const int authPort = 9099;
  static const int storagePort = 9199;

  /// Configure Firebase SDKs to talk to local emulators.
  ///
  /// Why: When `useEmulator` is true, we need to point Auth/Firestore/Storage
  /// to the emulator host/ports, otherwise the SDKs will call real services.
  /// This function is a no-op when `useEmulator` is false so production-like
  /// runs have zero overhead.
  static void configureEmulators() {
    if (useEmulator) {
      // Configure Firestore emulator
      FirebaseFirestore.instance.useFirestoreEmulator(
        emulatorHost,
        firestorePort,
      );

      // Configure Auth emulator
      FirebaseAuth.instance.useAuthEmulator(emulatorHost, authPort);

      // Configure Storage emulator
      FirebaseStorage.instance.useStorageEmulator(emulatorHost, storagePort);

      if (kDebugMode) {
        debugPrint('🚀 Firebase emulators configured for development');
        debugPrint('   - Firestore: $emulatorHost:$firestorePort');
        debugPrint('   - Auth: $emulatorHost:$authPort');
        debugPrint('   - Storage: $emulatorHost:$storagePort');
      }
    }
  }

  static Map<String, dynamic> get mockSocketConfig => {
    'enabled': false, // Disable real Socket.IO in development
    'fallbackToPolling': true,
    'reconnection': false,
  };
}
