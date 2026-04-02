// lib/core/animations/index.dart

/// Stub Street Animation System
/// 
/// Bu dosya tüm animasyon bileşenlerini tek bir yerden export eder.
/// Projede animasyon kullanmak için sadece bu dosyayı import etmeniz yeterlidir.
/// 
/// Kullanım:
/// ```dart
/// import 'package:stubstreet/core/animations/index.dart';
/// ```
library;


// Core animations
export 'app_animations.dart';
export 'feedback_animations.dart';
export 'enhanced_loading.dart';
export 'chat_animations.dart';

// Specialized animations
export 'page_transitions.dart';
export 'notification_animations.dart';
export 'gallery_animations.dart';

// Shared widget animations (if exists)
export '../../shared_widgets/animated_fab.dart';
