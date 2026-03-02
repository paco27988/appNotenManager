// E2E Integration Tests – LeherApp
//
// KOMPLETTER HAPPY-PATH in EINEM einzigen testWidgets-Block.
// Grund: Mehrere testWidgets-Aufrufe mit app.main() erzeugen
// mehrere Drift-DB-Instanzen im selben Prozess → Race conditions.
//
// Ausführen:
//   flutter test integration_test/app_test.dart -d macos

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:leher_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Vollständiger E2E-Flow', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // ─── 1. HomeScreen ────────────────────────────────────────────────────
    expect(find.text('Meine Klassen'), findsOneWidget);
    expect(find.byTooltip('Kategorien'), findsOneWidget);
    expect(find.byTooltip('Einstellungen'), findsOneWidget);
    expect(find.byTooltip('Backup'), findsOneWidget);

    // ─── 2. Einstellungen → Fach "Mathematik" anlegen ────────────────────
    await tester.tap(find.byTooltip('Einstellungen'));
    await tester.pumpAndSettle();
    expect(find.text('Einstellungen'), findsWidgets);
    expect(find.text('Globale Halbjahres-Gewichtung'), findsOneWidget);

    await tester.ensureVisible(find.text('Fach hinzufügen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fach hinzufügen'));
    await tester.pumpAndSettle();

    expect(find.text('Neues Fach'), findsOneWidget);
    // Im Dialog: der einzige TextField ist für den Fachnamen
    await tester.enterText(find.byType(TextField).last, 'Mathematik');
    await tester.pump();
    await tester.tap(find.text('Erstellen'));
    await tester.pumpAndSettle();

    // Fach erscheint in der Liste (unter "Fächer verwalten")
    expect(find.text('Mathematik'), findsAtLeastNWidgets(1));

    // Zurück zur HomeScreen
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Meine Klassen'), findsOneWidget);

    // ─── 3. Klasse "10a" anlegen ──────────────────────────────────────────
    await tester.tap(find.text('Neue Klasse'));
    await tester.pumpAndSettle();

    // Dialog: Klassenname + Schuljahr
    final nameField = find.byType(TextField).first;
    await tester.tap(nameField);
    await tester.enterText(nameField, '10a');
    await tester.pump();

    final yearField = find.byType(TextField).last;
    await tester.tap(yearField);
    await tester.enterText(yearField, '2025/26');
    await tester.pump();

    await tester.tap(find.text('Erstellen'));
    await tester.pumpAndSettle();

    expect(find.text('10a'), findsOneWidget);
    expect(find.text('Schuljahr 2025/26'), findsOneWidget);

    // ─── 4. ClassDetail öffnen ────────────────────────────────────────────
    await tester.tap(find.text('10a'));
    await tester.pumpAndSettle();

    // Schüler-Tab ist aktiv (default)
    expect(find.text('Schüler'), findsWidgets); // Tab + FAB

    // ─── 5. Schüler "Max Mustermann" hinzufügen ───────────────────────────
    // FAB hat Icon Icons.person_add → eindeutig
    await tester.tap(find.byIcon(Icons.person_add));
    await tester.pumpAndSettle();

    expect(find.text('Neuer Schüler'), findsOneWidget);

    final firstField = find.byType(TextField).first;
    await tester.tap(firstField);
    await tester.enterText(firstField, 'Max');
    await tester.pump();

    final lastField = find.byType(TextField).last;
    await tester.tap(lastField);
    await tester.enterText(lastField, 'Mustermann');
    await tester.pump();

    await tester.tap(find.text('Hinzufügen'));
    await tester.pumpAndSettle();

    // Format: "Nachname, Vorname"
    expect(find.text('Mustermann, Max'), findsOneWidget);

    // ─── 6. Fächer-Tab: Mathematik zuweisen ──────────────────────────────
    await tester.tap(find.text('Fächer'));
    await tester.pumpAndSettle();

    // FAB "Fach zuweisen" (eindeutiger Text, kein Konflikt)
    await tester.tap(find.text('Fach zuweisen'));
    await tester.pumpAndSettle();

    expect(find.text('Fach zuweisen'), findsWidgets); // Dialog-Titel
    expect(find.text('Mathematik'), findsOneWidget);

    // CheckboxListTile für Mathematik antippen
    await tester.tap(find.text('Mathematik'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fertig'));
    await tester.pumpAndSettle();

    // Mathematik erscheint im Fächer-Tab
    expect(find.text('Mathematik'), findsOneWidget);

    // ─── 7. Notenübersicht von Max Mustermann öffnen ──────────────────────
    await tester.tap(find.text('Schüler'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mustermann, Max'));
    await tester.pumpAndSettle();

    // StudentDetailScreen
    expect(find.text('Notenübersicht'), findsOneWidget);
    expect(find.text('Mathematik'), findsOneWidget);
    // Keine Noten → "–" in HJ1, HJ2, Jahres-Chips
    expect(find.text('–'), findsWidgets);

    // ─── 8. GradeEntryScreen: Mathematik-Tile antippen ────────────────────
    await tester.tap(find.text('Mathematik'));
    await tester.pumpAndSettle();

    expect(find.text('Halbjahr 1'), findsWidgets);

    // ─── 9. Note 2.0 hinzufügen ───────────────────────────────────────────
    await tester.tap(find.text('Note hinzufügen'));
    await tester.pumpAndSettle();

    expect(find.text('Note hinzufügen'), findsWidgets); // Dialog-Titel

    // Grade via ChoiceChip setzen (keine TextField für Notenwert!)
    await tester.tap(find.widgetWithText(ChoiceChip, '2'));
    await tester.pumpAndSettle();

    // Speichern → Button-Text ist 'Hinzufügen' beim Erstellen
    await tester.tap(find.text('Hinzufügen'));
    await tester.pumpAndSettle();

    // Note erscheint als '2.0' im GradeTile CircleAvatar
    expect(find.text('2.0'), findsAtLeastNWidgets(1));

    // ─── 10. Zurück → Zeugnis anzeigen ───────────────────────────────────
    // Zurück zu ClassDetail (zwei Ebenen: GradeEntry → StudentDetail → ClassDetail)
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Zeugnis-Icon in der AppBar antippen
    await tester.tap(find.byTooltip('Zeugnis'));
    await tester.pumpAndSettle();

    // ReportScreen
    expect(find.text('Zeugnis: 10a'), findsOneWidget);
    expect(find.text('Schüler'), findsOneWidget); // Tabellen-Header

    // HJ 1 Modus
    await tester.tap(find.text('HJ 1'));
    await tester.pumpAndSettle();
    expect(find.text('2.0'), findsAtLeastNWidgets(1));

    // Zurück zur HomeScreen
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    // ─── 11. Cleanup: Klasse "10a" löschen ───────────────────────────────
    expect(find.text('10a'), findsAtLeastNWidgets(1));

    // Popup-Menü der "10a"-Karte öffnen
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(Card, '10a'),
        matching: find.byIcon(Icons.more_vert),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Löschen'));
    await tester.pumpAndSettle();

    // Bestätigungsdialog
    expect(find.textContaining('löschen'), findsWidgets);
    await tester.tap(find.text('Löschen').last);
    await tester.pumpAndSettle();

    // Klasse ist weg
    expect(find.text('10a'), findsNothing);
  });
}
