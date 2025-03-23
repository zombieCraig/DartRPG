// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dart_rpg/main.dart';
import 'package:dart_rpg/providers/settings_provider.dart';
import 'package:dart_rpg/providers/datasworn_provider.dart';
import 'package:dart_rpg/providers/game_provider.dart';

void main() {
  testWidgets('DartRPG app smoke test', (WidgetTester tester) async {
    // This is a simple smoke test to verify that the app can be built without errors.
    // We're not testing any specific functionality here, just that the app can be built.
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => DataswornProvider()),
          ChangeNotifierProvider(create: (_) => GameProvider()),
        ],
        child: const MyApp(),
      ),
    );
    
    // Verify that the app builds without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
