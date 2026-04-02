import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stubstreet/main.dart';

void main() {
  testWidgets('App should load without errors', (WidgetTester tester) async {
    // Build our app with ProviderScope and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    // Verify that the app loads (either login screen or home screen)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
