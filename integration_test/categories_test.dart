// Kategorie-Tests – LeherApp
//
// Alle Kategorien-Tests in EINEM testWidgets (single app.main() call).
//
// Ausführen:
//   flutter test integration_test/categories_test.dart -d macos

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:leher_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Kategorien – CRUD und Standard-Kategorien', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Kategorien-Screen öffnen
    await tester.tap(find.byTooltip('Kategorien'));
    await tester.pumpAndSettle();
    expect(find.text('Notenkategorien'), findsOneWidget);
    expect(find.textContaining('Gesamtgewichtung'), findsOneWidget);

    // ─── Standard-Kategorien vorhanden ───────────────────────────────────
    expect(find.text('Mündlich'), findsOneWidget);
    expect(find.text('Schriftlich'), findsOneWidget);
    expect(find.text('Referate'), findsOneWidget);

    // ─── Neue Kategorie anlegen ───────────────────────────────────────────
    await tester.tap(find.text('Kategorie'));
    await tester.pumpAndSettle();

    expect(find.text('Neue Kategorie'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Referate E2E');
    await tester.pump();

    await tester.tap(find.text('Erstellen'));
    await tester.pumpAndSettle();

    expect(find.text('Referate E2E'), findsOneWidget);

    // ─── Kategorie bearbeiten ─────────────────────────────────────────────
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(Card, 'Referate E2E'),
        matching: find.byIcon(Icons.more_vert),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bearbeiten'));
    await tester.pumpAndSettle();

    expect(find.text('Kategorie bearbeiten'), findsOneWidget);

    final nameField = find.byType(TextField).first;
    await tester.tap(nameField);
    await tester.enterText(nameField, 'Referate E2E – fertig');
    await tester.pump();

    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(find.text('Referate E2E – fertig'), findsOneWidget);

    // ─── Kategorie löschen ────────────────────────────────────────────────
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(Card, 'Referate E2E – fertig'),
        matching: find.byIcon(Icons.more_vert),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Löschen'));
    await tester.pumpAndSettle();

    expect(find.text('Kategorie löschen'), findsOneWidget);
    await tester.tap(find.text('Löschen').last);
    await tester.pumpAndSettle();

    expect(find.text('Referate E2E – fertig'), findsNothing);

    // Standard-Kategorien immer noch vorhanden
    expect(find.text('Mündlich'), findsOneWidget);
    expect(find.text('Schriftlich'), findsOneWidget);
  });
}
