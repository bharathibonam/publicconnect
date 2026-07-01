import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import 'package:flutter_demo_app/main.dart';
import 'package:flutter_demo_app/services/app_state.dart';
import 'package:flutter_demo_app/themes/theme_provider.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('hive_test');
    Hive.init(tempDir.path);
    await Hive.openBox('app_settings');
    await Hive.openBox('local_complaints');
    await Hive.openBox('local_notifications');
    await Hive.openBox('local_broadcasts');
    await Hive.openBox('theme_settings'); // open theme_settings box too
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('Public Connect login screen smoke test', (WidgetTester tester) async {
    // Set a larger viewport size to prevent overflow in the test environment
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppState()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const MyApp(),
      ),
    );

    // Allow any microtasks / initialization timers to run
    await tester.pumpAndSettle();

    // Verify that our Welcome Screen details are rendered.
    expect(find.text('SMART'), findsOneWidget);
    expect(find.text('GOVERNANCE'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('తెలుగు'), findsOneWidget);
  });
}

