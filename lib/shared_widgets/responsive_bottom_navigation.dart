// lib/shared_widgets/responsive_bottom_navigation.dart

import 'package:flutter/material.dart';
import 'responsive_wrapper.dart';

class ResponsiveBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<ResponsiveBottomNavigationBarItem> items;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final BottomNavigationBarType? type;

  const ResponsiveBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.type,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final isTablet = context.isTablet;

    // On desktop, show a rail navigation instead
    if (isDesktop) {
      return _buildNavigationRail(context);
    }

    // On tablet and mobile, show bottom navigation
    final theme = Theme.of(context);
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: type ?? theme.bottomNavigationBarTheme.type ?? BottomNavigationBarType.fixed,
      selectedItemColor: selectedItemColor ?? theme.bottomNavigationBarTheme.selectedItemColor ?? theme.colorScheme.primary,
      unselectedItemColor: unselectedItemColor ?? theme.bottomNavigationBarTheme.unselectedItemColor ?? theme.colorScheme.onSurfaceVariant,
      backgroundColor: theme.bottomNavigationBarTheme.backgroundColor ?? theme.colorScheme.surface,
      selectedFontSize: isTablet ? 14.0 : 12.0,
      unselectedFontSize: isTablet ? 12.0 : 10.0,
      iconSize: isTablet ? 26.0 : 24.0,
      items: items
          .map(
            (item) => BottomNavigationBarItem(
              icon: Semantics(
                label: item.semanticLabel ?? item.label,
                child: _buildIconWithBadge(context, item.icon, item.badgeCount, item.badgeColor, item.badgeTextColor),
              ),
              activeIcon: Semantics(
                label: '${item.semanticLabel ?? item.label} (active)',
                child: _buildIconWithBadge(context, item.activeIcon ?? item.icon, item.badgeCount, item.badgeColor, item.badgeTextColor),
              ),
              label: item.label,
              tooltip: item.tooltip,
            ),
          )
          .toList(),
    );
  }

  /// Icon'un üstüne badge ekleyen helper metod
  Widget _buildIconWithBadge(
    BuildContext context,
    Widget icon,
    int? badgeCount,
    Color? badgeColor,
    Color? badgeTextColor,
  ) {
    if (badgeCount == null || badgeCount <= 0) {
      return icon;
    }

    final theme = Theme.of(context);
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -6,
          top: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor ?? theme.colorScheme.error,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 16,
            ),
            child: Text(
              badgeCount > 99 ? '99+' : badgeCount.toString(),
              style: TextStyle(
                color: badgeTextColor ?? Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationRail(BuildContext context) {
    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      destinations: items
          .map(
            (item) => NavigationRailDestination(
              icon: Semantics(
                label: item.semanticLabel ?? item.label,
                child: _buildIconWithBadge(context, item.icon, item.badgeCount, item.badgeColor, item.badgeTextColor),
              ),
              selectedIcon: Semantics(
                label: '${item.semanticLabel ?? item.label} (active)',
                child: _buildIconWithBadge(context, item.activeIcon ?? item.icon, item.badgeCount, item.badgeColor, item.badgeTextColor),
              ),
              label: Text(item.label),
            ),
          )
          .toList(),
      labelType: NavigationRailLabelType.all,
      useIndicator: true,
    );
  }
}

class ResponsiveBottomNavigationBarItem {
  final Widget icon;
  final Widget? activeIcon;
  final String label;
  final String? tooltip;
  final String? semanticLabel;
  final int? badgeCount; // Badge sayısı
  final Color? badgeColor; // Badge rengi
  final Color? badgeTextColor; // Badge metin rengi

  const ResponsiveBottomNavigationBarItem({
    required this.icon,
    required this.label,
    this.activeIcon,
    this.tooltip,
    this.semanticLabel,
    this.badgeCount,
    this.badgeColor,
    this.badgeTextColor,
  });
}
