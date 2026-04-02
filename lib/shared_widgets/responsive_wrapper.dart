// lib/shared_widgets/responsive_wrapper.dart

import 'package:flutter/material.dart';

/// Responsive breakpoints for the app
class ResponsiveBreakpoints {
  static const double mobile = 0;
  static const double tablet = 768;
  static const double desktop = 1024;
}

/// Device type enumeration
enum DeviceType { mobile, tablet, desktop }

/// Responsive wrapper widget that provides adaptive layouts
class ResponsiveWrapper extends StatelessWidget {
  final Widget? mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? child;

  const ResponsiveWrapper({
    super.key,
    this.mobile,
    this.tablet,
    this.desktop,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= ResponsiveBreakpoints.desktop) {
          return desktop ?? tablet ?? mobile ?? child ?? const SizedBox.shrink();
        } else if (constraints.maxWidth >= ResponsiveBreakpoints.tablet) {
          return tablet ?? mobile ?? child ?? const SizedBox.shrink();
        } else {
          return mobile ?? child ?? const SizedBox.shrink();
        }
      },
    );
  }
}

/// Extension to get device type from BuildContext
extension ResponsiveContext on BuildContext {
  DeviceType get deviceType {
    final width = MediaQuery.sizeOf(this).width;
    if (width >= ResponsiveBreakpoints.desktop) {
      return DeviceType.desktop;
    } else if (width >= ResponsiveBreakpoints.tablet) {
      return DeviceType.tablet;
    } else {
      return DeviceType.mobile;
    }
  }

  bool get isMobile => deviceType == DeviceType.mobile;
  bool get isTablet => deviceType == DeviceType.tablet;
  bool get isDesktop => deviceType == DeviceType.desktop;

  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
}

/// Responsive padding utility
class ResponsivePadding {
  static EdgeInsets responsive(
    BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    final deviceType = context.deviceType;
    double padding;

    switch (deviceType) {
      case DeviceType.desktop:
        padding = desktop ?? tablet ?? mobile ?? 16.0;
        break;
      case DeviceType.tablet:
        padding = tablet ?? mobile ?? 12.0;
        break;
      case DeviceType.mobile:
        padding = mobile ?? 8.0;
        break;
    }

    return EdgeInsets.all(padding);
  }
}

/// Responsive spacing utility
class ResponsiveSpacing {
  static double getSpacing(
    BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    final deviceType = context.deviceType;

    switch (deviceType) {
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile ?? 16.0;
      case DeviceType.tablet:
        return tablet ?? mobile ?? 12.0;
      case DeviceType.mobile:
        return mobile ?? 8.0;
    }
  }
}
