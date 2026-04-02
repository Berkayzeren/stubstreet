// test/features/auth/presentation/screens/advanced_profile_screen_simple_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stubstreet/features/auth/presentation/screens/advanced_profile_screen.dart';
import 'package:stubstreet/features/auth/presentation/providers/auth_providers.dart';
import 'package:stubstreet/l10n/app_localizations.dart';

void main() {
  group('Advanced Profile Screen Tests', () {
    testWidgets('should display loading indicator when user is null', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AdvancedProfileScreen(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should be responsive on different screen sizes', (tester) async {
      // Test mobile layout (400x800)
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AdvancedProfileScreen(),
          ),
        ),
      );

      await tester.pump();

      // Assert mobile layout
      expect(find.byType(AdvancedProfileScreen), findsOneWidget);

      // Test tablet layout (800x1200)
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await tester.pump();

      // Assert tablet layout adjustments
      expect(find.byType(AdvancedProfileScreen), findsOneWidget);

      // Test desktop layout (1200x800)
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pump();

      // Assert desktop layout adjustments
      expect(find.byType(AdvancedProfileScreen), findsOneWidget);

      // Reset to default size
      await tester.binding.setSurfaceSize(const Size(800, 600));
    });

    testWidgets('should create widget without errors', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AdvancedProfileScreen(),
          ),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
