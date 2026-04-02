// lib/core/widgets/loading_spinner.dart

import 'package:flutter/material.dart';

/// Yeniden kullanılabilir yükleme göstergesi widget'ı
/// 
/// Bu widget standart loading göstergesi sağlar ve 
/// farklı boyutlarda kullanılabilir.
class LoadingSpinner extends StatelessWidget {
  final double? size;
  final Color? color;
  final double strokeWidth;

  const LoadingSpinner({
    super.key,
    this.size,
    this.color,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    Widget spinner = CircularProgressIndicator(
      strokeWidth: strokeWidth,
      valueColor: color != null 
          ? AlwaysStoppedAnimation<Color>(color!)
          : null,
    );

    if (size != null) {
      spinner = SizedBox(
        width: size,
        height: size,
        child: spinner,
      );
    }

    return spinner;
  }
}
