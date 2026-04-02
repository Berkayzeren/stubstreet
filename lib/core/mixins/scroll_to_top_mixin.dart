// lib/core/mixins/scroll_to_top_mixin.dart

import 'package:flutter/material.dart';

/// Mixin that provides scroll-to-top functionality for pages
/// 
/// Bu mixin sayfaların açıldığında otomatik olarak en üste scroll yapmasını sağlar
mixin ScrollToTopMixin<T extends StatefulWidget> on State<T> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    // Sayfa açıldığında en üste scroll yap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// ScrollController'ı döndürür
  ScrollController get scrollController => _scrollController;

  /// Manuel olarak en üste scroll yapmak için kullanılabilir
  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
}
