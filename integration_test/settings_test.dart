// Einstellungen-Tests – LeherApp
//
// Alle Settings-Tests in EINEM testWidgets (single app.main() call).
//
// Ausführen:
//   flutter test integration_test/settings_test.dart -d macos

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:leher_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Einstellungen – Screen-Inhalt, Slider und Fächer-CRUD', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Zu Einstellungen navigieren
    await tester.tap(find.byTooltip('Einstellungen'));
    await tester.pumpAndSettle();

    // ─── Screen-Struktur ──────────────────────────────────────────────────
    expect(find.text('Einstellungen'), findsWidgets);
    expect(find.text('Globale Halbjahres-Gewichtung'), findsOneWidget);
    expect(find.text('Fach-individuelle Gewichtung'), findsOneWidget);
    expect(find.text('Fächer verwalten'), findsOneWidget);

    // ─── Gewichtungs-Slider ───────────────────────────────────────────────
    expect(find.byType(Slider).first, findsOneWidget);
    expect(find.textContaining('HJ 1:'), findsOneWidget);
    expect(find.textContaining('HJ 2:'), findsOneWidget);

    // ─── Fach anlegen ────────────────────────────────────────────────────
    await tester.ensureVisible(find.text('Fach hinzufügen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fach hinzufügen'));
    await tester.pumpAndSettle();

    expect(find.text('Neues Fach'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Physik E2E');
    await tester.pump();

    await tester.tap(find.text('Erstellen'));
    await tester.pumpAndSettle();

    expect(find.text('Physik E2E'), findsAtLeastNWidgets(1));

    // ─── Fach löschen ────────────────────────────────────────────────────
    final deleteBtn = find.descendant(
      of: find.widgetWithText(Card, 'Physik E2E'),
      matching: find.byIcon(Icons.delete_outline),
    );
    await tester.ensureVisible(deleteBtn);
    await tester.pumpAndSettle();
    await tester.tap(deleteBtn);
    await tester.pumpAndSettle();

    expect(find.text('Fach löschen'), findsOneWidget);
    await tester.tap(find.text('Löschen').last);
    await tester.pumpAndSettle();

    expect(find.text('Physik E2E'), findsNothing);

    // ─── Fach-individuelle Gewichtung: ExpansionTile ──────────────────────
    // Wenn ein Fach vorhanden ist (z.B. Mathematik aus app_test), erscheint ein Tile
    // Wenn keine Fächer: "Noch keine Fächer vorhanden" Text
    final noSubjects = find.text('Noch keine Fächer vorhanden.');
    final hasSubjectTiles = find.byType(ExpansionTile);
    expect(
      noSubjects.evaluate().isNotEmpty || hasSubjectTiles.evaluate().isNotEmpty,
      isTrue,
    );
  });
}
