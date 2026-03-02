# LeherApp – Notenverwaltung für Lehrkräfte

Eine Flutter-App zur Verwaltung von Schülernoten, Klassen und Fächern. Entwickelt für Lehrerinnen und Lehrer, die Noten nach Halbjahren, Kategorien und Fächern strukturiert erfassen und auswerten möchten.

---

## Inhaltsverzeichnis

1. [Funktionen](#funktionen)
2. [Voraussetzungen](#voraussetzungen)
3. [Installation](#installation)
4. [App starten](#app-starten)
5. [Tests ausführen](#tests-ausführen)
6. [Projektstruktur](#projektstruktur)
7. [Architektur](#architektur)
8. [Datenbankschema](#datenbankschema)
9. [Notenberechnung](#notenberechnung)
10. [Backup & Restore](#backup--restore)
11. [Release-Build](#release-build)
12. [Häufige Probleme](#häufige-probleme)

---

## Funktionen

| Bereich | Was ist möglich |
|---|---|
| **Klassen** | Anlegen, bearbeiten, löschen (mit Schuljahr) |
| **Schüler** | Hinzufügen, umbenennen, löschen (je Klasse) |
| **Fächer** | Global verwalten, Klassen zuweisen/entfernen |
| **Noten** | Erfassen nach Halbjahr, Kategorie, Datum + optionalem Kommentar |
| **Kategorien** | Frei konfigurierbar (Name, Gewichtung %, Farbe) |
| **Halbjahresgewichtung** | Global oder fachindividuell (HJ1 / HJ2) |
| **Zeugnis** | Tabellarische Übersicht pro Klasse (HJ1 / HJ2 / Jahresschnitt) |
| **Backup** | Export als JSON-Datei, Import mit vollständigem Daten-Restore |

**Standard-Kategorien beim ersten Start:**
- Mündlich – 60 %
- Schriftlich – 30 %
- Referate – 10 %

---

## Voraussetzungen

### Flutter & Dart

| Tool | Mindestversion |
|---|---|
| Flutter | 3.10.3 |
| Dart | 3.0.3 |

Flutter installieren: [flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)

Installation prüfen:
```bash
flutter --version
flutter doctor
```

### Plattformspezifisch

**macOS**
- Xcode 14 oder neuer (aus dem App Store)
- CocoaPods: `sudo gem install cocoapods`

**iOS** (nur auf macOS)
- Xcode + iOS Simulator oder physisches Gerät
- Apple-Entwicklerkonto (für reales Gerät nötig)

**Android**
- Android Studio mit SDK (API 21+)
- Emulator oder physisches Android-Gerät

**Web**
- Chrome-Browser (für `flutter run -d chrome`)

---

## Installation

### 1. Repository klonen

```bash
git clone https://github.com/paco27988/appNotenManager.git
cd appNotenManager
```

### 2. Branch wählen

```bash
# Aktueller Entwicklungsstand
git checkout dev

# Stabiler Stand (sofern vorhanden)
git checkout main
```

### 3. Abhängigkeiten installieren

```bash
flutter pub get
```

### 4. Code-Generierung

Die generierten `*.g.dart`-Dateien sind im Repository enthalten und müssen normalerweise nicht neu erzeugt werden. Nur nach Änderungen am Datenbankschema oder an Riverpod-Providern nötig:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Für kontinuierliche Generierung während der Entwicklung:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

---

## App starten

### Verfügbare Geräte anzeigen

```bash
flutter devices
```

Beispielausgabe:
```
macOS (desktop) • macos  • darwin-arm64  • macOS 14.x
Chrome (web)    • chrome • web-javascript• Google Chrome
```

### Starten

**macOS (empfohlen für Entwicklung)**
```bash
flutter run -d macos
```

**iOS Simulator**
```bash
flutter run -d ios
```

**Android Emulator / Gerät**
```bash
flutter run -d android
```

**Web (Chrome)**
```bash
flutter run -d chrome
```

> **Hinweis:** Der erste Build dauert mehrere Minuten, da native Abhängigkeiten kompiliert werden. Folgebuilds sind deutlich schneller. Hot-Reload ist aktiv.

### Hot-Reload und Hot-Restart

Während `flutter run` aktiv ist:

| Taste | Aktion |
|---|---|
| `r` | Hot-Reload – Codeänderungen übernehmen, App-State bleibt erhalten |
| `R` | Hot-Restart – App neu starten, State wird zurückgesetzt |
| `q` | App beenden |

---

## Tests ausführen

### Unit-Tests

Testet die reine Berechnungslogik (`GradeCalculator`) – kein Gerät nötig:

```bash
flutter test test/widget_test.dart
```

Erwartete Ausgabe:
```
00:01 +7: All tests passed!
```

**Abgedeckte Szenarien (7 Tests):**
- Jahresnotenberechnung mit 50/50 und 60/40 Gewichtung
- Verhalten bei fehlendem Halbjahr (null-Handling)
- `roundToWholeGrade` – Klammerung auf \[1, 6\]
- `formatGradeDetail` und `formatGradeReport` – Ausgabeformat

### Integration-Tests (E2E)

Starten die echte macOS-App und simulieren vollständige Nutzerinteraktionen:

```bash
# Vollständiger Happy-Path (Klasse, Schüler, Noten, Zeugnis, Cleanup)
flutter test integration_test/app_test.dart -d macos --timeout 30m

# Navigations-Smoke-Test (alle Screens erreichbar)
flutter test integration_test/navigation_test.dart -d macos --timeout 30m

# Kategorienverwaltung (CRUD + Standard-Kategorien)
flutter test integration_test/categories_test.dart -d macos --timeout 30m

# Einstellungen (Halbjahresgewichtung, Fächer anlegen/löschen)
flutter test integration_test/settings_test.dart -d macos --timeout 30m
```

> **Hinweis:** Der erste macOS-Build für Integration-Tests kann 10–15 Minuten dauern. Das `--timeout 30m` verhindert einen vorzeitigen Abbruch.

**Was der E2E-Test (`app_test.dart`) testet:**
1. App-Start → HomeScreen sichtbar
2. Einstellungen öffnen → Fach „Mathematik" anlegen
3. Klasse „10a" (Schuljahr 2025/26) erstellen
4. ClassDetail öffnen → Schüler „Max Mustermann" hinzufügen
5. Fach der Klasse zuweisen (Fächer-Tab)
6. Notenübersicht von Max öffnen
7. GradeEntryScreen → Note 2.0 erfassen
8. Zeugnis (HJ1-Modus) aufrufen – Note 2.0 sichtbar
9. Klasse löschen (Cleanup)

### Statische Analyse

```bash
flutter analyze
```

Aktuell: **0 Issues**

---

## Projektstruktur

```
leherApp/
├── lib/
│   ├── main.dart                          # App-Einstiegspunkt, Theme-Konfiguration
│   ├── router/
│   │   └── app_router.dart               # go_router – alle Routen definiert
│   ├── core/
│   │   ├── database/
│   │   │   ├── app_database.dart         # Drift-Schema, DB-Initialisierung
│   │   │   ├── app_database.g.dart       # (generiert, nicht manuell bearbeiten)
│   │   │   └── daos/                     # 6 Data Access Objects
│   │   │       ├── classes_dao.dart
│   │   │       ├── students_dao.dart
│   │   │       ├── subjects_dao.dart
│   │   │       ├── grades_dao.dart
│   │   │       ├── categories_dao.dart
│   │   │       └── settings_dao.dart
│   │   └── utils/
│   │       └── grade_calculator.dart     # Reine Berechnungslogik (ohne Flutter-Deps)
│   └── features/
│       ├── database_provider.dart        # Riverpod-Provider für AppDatabase
│       ├── classes/                      # HomeScreen + ClassDetailScreen
│       ├── students/                     # StudentDetailScreen
│       ├── subjects/                     # subjects_provider (kein eigener Screen)
│       ├── grades/                       # GradeEntryScreen
│       ├── categories/                   # CategoriesScreen
│       ├── settings/                     # SettingsScreen
│       ├── report/                       # ReportScreen (Zeugnis)
│       └── backup/                       # BackupScreen + BackupService
├── test/
│   └── widget_test.dart                  # 7 Unit-Tests
├── integration_test/
│   ├── app_test.dart                     # Vollständiger E2E-Flow
│   ├── navigation_test.dart              # Screen-Navigation
│   ├── categories_test.dart              # Kategorien-CRUD
│   └── settings_test.dart               # Einstellungen-CRUD
├── android/                              # Android-Plattformcode
├── ios/                                  # iOS-Plattformcode
├── macos/                                # macOS-Plattformcode
├── web/                                  # Web-Support
└── pubspec.yaml                          # Abhängigkeiten & Projektkonfiguration
```

### Routen-Übersicht

```
/                                        HomeScreen – Klassenliste
├── /categories                          CategoriesScreen
├── /settings                            SettingsScreen
├── /backup                              BackupScreen
└── /class/:id                           ClassDetailScreen (Tabs: Schüler / Fächer)
    ├── /class/:id/report                ReportScreen (Zeugnis)
    └── /class/:id/student/:sid          StudentDetailScreen
        └── /class/:id/student/:sid/grades/:subjectId   GradeEntryScreen
```

---

## Architektur

### Tech-Stack

| Schicht | Technologie | Zweck |
|---|---|---|
| UI | Flutter Widgets | Darstellung, Material 3 |
| State | Riverpod 2.x | Reaktives State-Management |
| Navigation | go_router 12.x | URL-basiertes Routing |
| Datenbank | Drift 2.14 + SQLite | Lokale Persistenz |
| Code-Gen | build_runner | Drift- und Riverpod-Generierung |

### Datenfluss (Lesen)

```
UI Widget
  └── ref.watch(someStreamProvider)
        └── db.someDao.watchXxx()      ← Drift DAO: reaktiver Stream
              └── SQLite (lokale Datei)
```

### Datenfluss (Schreiben)

```
UI (Button-Tap)
  └── ref.read(notifierProvider.notifier).doSomething()
        └── db.someDao.create / update / delete
              └── ref.invalidate(streamProvider)   ← Stream reagiert automatisch
```

### Wichtige Designentscheidungen

| Entscheidung | Begründung |
|---|---|
| `@DataClassName('SchoolClass')` auf der `Classes`-Tabelle | Verhindert Namenskonflikt mit dem Dart-Typ `Class` |
| Einzelner `testWidgets`-Block pro Integrationstestdatei | Mehrere `app.main()`-Aufrufe erzeugen mehrere Drift-Instanzen → Race Conditions |
| `_AddSubjectDialog` als `StatefulWidget` | `.then(ctrl.dispose)` feuert beim `Navigator.pop`, aber die Ausgangsanimation läuft noch → `dispose()` im Widget-Lifecycle ist sicherer |
| `DefaultTabController` oberhalb von `Scaffold` mit `Builder` | `InheritedWidget` propagiert nur abwärts; der FAB-Context muss innerhalb des `DefaultTabController` liegen |

---

## Datenbankschema

```
Classes  (@DataClassName: SchoolClass)
├── id            INTEGER  PK AUTOINCREMENT
├── name          TEXT     1–100 Zeichen      z.B. "10a"
└── schoolYear    TEXT     1–20 Zeichen       z.B. "2025/26"

Students
├── id            INTEGER  PK AUTOINCREMENT
├── classId       INTEGER  → Classes.id
├── firstName     TEXT     1–100 Zeichen
└── lastName      TEXT     1–100 Zeichen

Subjects
├── id            INTEGER  PK AUTOINCREMENT
└── name          TEXT     1–100 Zeichen      z.B. "Mathematik"

ClassSubjects  (n:m  Klasse ↔ Fach)
├── classId       INTEGER  → Classes.id   ┐ zusammengesetzter
└── subjectId     INTEGER  → Subjects.id  ┘ Primärschlüssel

GradeCategories
├── id            INTEGER  PK AUTOINCREMENT
├── name          TEXT     1–100 Zeichen      z.B. "Mündlich"
├── weightPercent REAL     0–100              z.B. 60.0
├── colorHex      TEXT     Standard: "#2196F3"
└── icon          TEXT     Standard: "label"

Grades
├── id            INTEGER  PK AUTOINCREMENT
├── studentId     INTEGER  → Students.id
├── subjectId     INTEGER  → Subjects.id
├── categoryId    INTEGER  → GradeCategories.id
├── value         REAL     1.0–6.0  (deutsche Notenskala)
├── semester      INTEGER  1 oder 2
├── date          DATETIME
└── comment       TEXT     optional, Standard: ""

SemesterSettings
├── id               INTEGER  PK AUTOINCREMENT
├── subjectId        INTEGER  → Subjects.id   (NULL = globale Einstellung)
├── firstHalfWeight  REAL     Standard: 50.0
└── secondHalfWeight REAL     Standard: 50.0
```

**Speicherort der SQLite-Datei:** `leher_app.sqlite` im App-Dokumentenverzeichnis der jeweiligen Plattform.

---

## Notenberechnung

### Halbjahresnote (HJ1 oder HJ2)

Es werden nur Kategorien berücksichtigt, für die im jeweiligen Halbjahr mindestens eine Note vorhanden ist. Die Gewichte der restlichen Kategorien werden proportional auf die verwendeten Kategorien umverteilt.

```
HJ = Σ (Kategorieschnitt_k × Gewicht_k) / Σ Gewicht_k  (nur genutzte Kategorien)
```

**Beispiel** (HJ1, 3 Kategorien, Referate ohne Noten):

| Kategorie | Gewicht | Noten | Schnitt |
|---|---|---|---|
| Mündlich | 60 % | 2, 3 | 2.5 |
| Schriftlich | 30 % | 1, 2 | 1.5 |
| Referate | 10 % | – | ignoriert |

Effektive Gewichtung: Mündlich 66,7 % / Schriftlich 33,3 %

```
HJ1 = (2.5 × 66.7 + 1.5 × 33.3) / 100 ≈ 2.17
```

### Jahreszeugnisnote

```
Jahr = (HJ1 × W1 + HJ2 × W2) / (W1 + W2)
```

Wenn nur ein Halbjahr Noten enthält, wird ausschließlich dieses verwendet. Standardgewichtung: 50 % / 50 %. Konfigurierbar unter **Einstellungen** global oder pro Fach.

### Darstellung

| Kontext | Format | Beispiel |
|---|---|---|
| Notenübersicht (HJ-Karte) | 1 Dezimalstelle | `2.3` |
| Zeugnis – HJ1 / HJ2 | 1 Dezimalstelle | `2.3` |
| Zeugnis – Jahresschnitt | Ganze Zahl | `2` |
| Keine Noten vorhanden | Strich | `–` |

---

## Backup & Restore

### Export

1. In der App oben rechts das **Backup-Icon** antippen
2. **„Exportieren & Teilen"** antippen
3. Systemeigener Teilen-Dialog öffnet sich (AirDrop, E-Mail, Dateien usw.)
4. Datei speichern

Dateiname: `leher_backup_<Zeitstempel>.json`

### Import

> **Achtung:** Alle vorhandenen Daten werden beim Import vollständig und unwiderruflich überschrieben.

1. Backup → **„JSON-Datei importieren"**
2. Warnhinweis lesen und im Bestätigungsdialog bestätigen
3. Backup-Datei auswählen (max. 10 MB, nur `.json`)
4. Erfolgsmeldung abwarten

### JSON-Format

```json
{
  "version": 1,
  "exportedAt": "2026-03-02T10:00:00.000Z",
  "classes":         [ { "id": 1, "name": "10a", "schoolYear": "2025/26" } ],
  "students":        [ { "id": 1, "classId": 1, "firstName": "Max", "lastName": "Mustermann" } ],
  "subjects":        [ { "id": 1, "name": "Mathematik" } ],
  "classSubjects":   [ { "classId": 1, "subjectId": 1 } ],
  "categories":      [ { "id": 1, "name": "Mündlich", "weightPercent": 60.0, "colorHex": "#4CAF50" } ],
  "grades":          [ { "studentId": 1, "subjectId": 1, "categoryId": 1, "value": 2.0, "semester": 1 } ],
  "semesterSettings":[ { "subjectId": null, "firstHalfWeight": 50.0, "secondHalfWeight": 50.0 } ]
}
```

---

## Release-Build

### macOS

```bash
flutter build macos --release
```

Fertige App:
```
build/macos/Build/Products/Release/leher_app.app
```

### iOS

```bash
flutter build ios --release
```

Anschließend in Xcode (`ios/Runner.xcworkspace`) öffnen und archivieren (erfordert Apple-Entwicklerkonto).

### Android APK

```bash
flutter build apk --release
```

```
build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (für Google Play)

```bash
flutter build appbundle --release
```

### Web

```bash
flutter build web --release
```

```
build/web/
```

---

## Häufige Probleme

### `flutter doctor` meldet fehlende Tools

```bash
# Xcode-Lizenzen akzeptieren (macOS/iOS)
sudo xcodebuild -license accept

# CocoaPods installieren
sudo gem install cocoapods

# Android-Lizenzen akzeptieren
flutter doctor --android-licenses
```

### Build-Fehler nach `flutter pub get`

```bash
# Pub-Cache zurücksetzen
flutter pub cache clean
flutter pub get

# iOS/macOS: Pods neu installieren
cd ios && pod install && cd ..
cd macos && pod install && cd ..
```

### Code-Generierung schlägt fehl

```bash
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### Integration-Test bricht nach 12 Minuten ab

Der erste macOS-Build ist langsam. Explizites Timeout setzen:

```bash
flutter test integration_test/app_test.dart -d macos --timeout 30m
```

### Datenbank zurücksetzen (Entwicklung)

Die SQLite-Datei löschen und App neu starten:

| Plattform | Pfad |
|---|---|
| macOS | `~/Library/Containers/com.example.leherApp/Data/Documents/leher_app.sqlite` |
| iOS Simulator | App deinstallieren und neu installieren |
| Android | Einstellungen → App → Speicher löschen |

---

## Abhängigkeiten

| Paket | Version | Zweck |
|---|---|---|
| `flutter_riverpod` | ^2.4.9 | State-Management |
| `riverpod_annotation` | ^2.3.3 | Riverpod Code-Gen Support |
| `drift` | ^2.13.0 | SQLite ORM |
| `sqlite3_flutter_libs` | ^0.5.0 | Native SQLite-Bindings |
| `go_router` | ^12.0.0 | Navigation |
| `file_picker` | ^6.2.1 | Dateiauswahl (Backup-Import) |
| `share_plus` | ^7.2.1 | Teilen (Backup-Export) |
| `path_provider` | ^2.1.2 | Plattformpfade |
| `intl` | ^0.18.1 | Datum-Formatierung |
| `path` | ^1.8.3 | Pfad-Utilities |
| `build_runner` | ^2.4.8 | Code-Generierung (dev) |
| `drift_dev` | ^2.13.0 | Drift Code-Gen (dev) |
| `riverpod_generator` | ^2.3.9 | Riverpod Code-Gen (dev) |
