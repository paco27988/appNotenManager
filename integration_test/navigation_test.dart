// Navigations-Tests – LeherApp
//
// Alle Navigation-Tests in EINEM testWidgets (single app.main() call).
//
// Ausführen:
//   flutter test integration_test/navigation_test.dart -d macos

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:leher_app/main.dart' as app;

// Hilfsfunktion: AppBar-Back-Navigation
Future<void> goBack(WidgetTester tester) async {
  final back = find.byType(BackButton);
  if (back.evaluate().isNotEmpty) {
    await tester.tap(back.first);
  } else {
    await tester.pageBack();
  }
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Navigation zu allen Screens und zurück', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    expect(find.text('Meine Klassen'), findsOneWidget);

    // ─── Einstellungen ────────────────────────────────────────────────────
    await tester.tap(find.byTooltip('Einstellungen'));
    await tester.pumpAndSettle();
    expect(find.text('Einstellungen'), findsWidgets);
    expect(find.text('Globale Halbjahres-Gewichtung'), findsOneWidget);

    await goBack(tester);
    expect(find.text('Meine Klassen'), findsOneWidget);

    // ─── Kategorien ───────────────────────────────────────────────────────
    await tester.tap(find.byTooltip('Kategorien'));
    await tester.pumpAndSettle();
    expect(find.text('Notenkategorien'), findsOneWidget);
    // Gewichtungs-Banner immer sichtbar
    expect(find.textContaining('Gesamtgewichtung'), findsOneWidget);

    await goBack(tester);
    expect(find.text('Meine Klassen'), findsOneWidget);

    // ─── Backup ───────────────────────────────────────────────────────────
    await tester.tap(find.byTooltip('Backup'));
    await tester.pumpAndSettle();
    expect(find.text('Datensicherung'), findsOneWidget);

    await goBack(tester);
    expect(find.text('Meine Klassen'), findsOneWidget);

    // ─── Einstellungen: Slider vorhanden ──────────────────────────────────
    await tester.tap(find.byTooltip('Einstellungen'));
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsAtLeastNWidgets(1));
    expect(find.textContaining('HJ 1:'), findsOneWidget);
    expect(find.textContaining('HJ 2:'), findsOneWidget);

    await goBack(tester);
    expect(find.text('Meine Klassen'), findsOneWidget);
  });
}
