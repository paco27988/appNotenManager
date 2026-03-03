import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/database/app_database.dart';

class BackupService {
  final AppDatabase db;

  BackupService(this.db);

  // ─── Export ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _collectData() async {
    return {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'classes': (await db.classesDao.getAll())
          .map((c) => {'id': c.id, 'name': c.name, 'schoolYear': c.schoolYear})
          .toList(),
      'students': await _getAllStudents(),
      'subjects': (await db.subjectsDao.getAll())
          .map((s) => {'id': s.id, 'name': s.name})
          .toList(),
      'classSubjects': await _getClassSubjects(),
      'categories': (await db.categoriesDao.getAll())
          .map(
            (c) => {
              'id': c.id,
              'name': c.name,
              'weightPercent': c.weightPercent,
              'colorHex': c.colorHex,
              'icon': c.icon,
            },
          )
          .toList(),
      'grades': (await db.gradesDao.getAll())
          .map(
            (g) => {
              'id': g.id,
              'studentId': g.studentId,
              'subjectId': g.subjectId,
              'categoryId': g.categoryId,
              'value': g.value,
              'factor': g.factor,
              'semester': g.semester,
              'date': g.date.toIso8601String(),
              'comment': g.comment,
            },
          )
          .toList(),
      'semesterSettings': (await db.settingsDao.getAll())
          .map(
            (s) => {
              'id': s.id,
              'subjectId': s.subjectId,
              'firstHalfWeight': s.firstHalfWeight,
              'secondHalfWeight': s.secondHalfWeight,
            },
          )
          .toList(),
      'subjectCategoryOverrides':
          (await db.subjectCategoryOverridesDao.getAll())
              .map(
                (o) => {
                  'subjectId': o.subjectId,
                  'categoryId': o.categoryId,
                  'isActive': o.isActive,
                  'weightOverride': o.weightOverride,
                },
              )
              .toList(),
    };
  }

  Future<List<Map<String, dynamic>>> _getAllStudents() async {
    final classes = await db.classesDao.getAll();
    final List<Map<String, dynamic>> result = [];
    for (final c in classes) {
      final students = await db.studentsDao.getByClass(c.id);
      for (final s in students) {
        result.add({
          'id': s.id,
          'classId': s.classId,
          'firstName': s.firstName,
          'lastName': s.lastName,
        });
      }
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> _getClassSubjects() async {
    final classes = await db.classesDao.getAll();
    final List<Map<String, dynamic>> result = [];
    for (final c in classes) {
      final subjects = await db.classesDao.getSubjectsForClass(c.id);
      for (final s in subjects) {
        result.add({'classId': c.id, 'subjectId': s.id});
      }
    }
    return result;
  }

  @visibleForTesting
  Future<Map<String, dynamic>> exportData() => _collectData();

  @visibleForTesting
  Future<void> importData(Map<String, dynamic> data) => _importData(data);

  Future<void> exportAndShare() async {
    final data = await _collectData();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    final fileName =
        'leher_backup_${DateTime.now().millisecondsSinceEpoch}.json';

    if (kIsWeb) {
      await Share.share(jsonStr, subject: fileName);
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(jsonStr);
    try {
      await Share.shareXFiles([XFile(file.path)], subject: fileName);
    } finally {
      if (await file.exists()) await file.delete();
    }
  }

  // ─── Import ───────────────────────────────────────────────────────────────

  Future<String> importFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return 'Abgebrochen';

    final file = result.files.first;

    // File size guard: max 10 MB
    if ((file.size) > 10 * 1024 * 1024) {
      return 'Fehler: Datei zu groß (max. 10 MB)';
    }

    final bytes = file.bytes;
    if (bytes == null) return 'Fehler: Datei konnte nicht gelesen werden';

    try {
      final jsonStr = utf8.decode(bytes);
      final data = jsonDecode(jsonStr);
      if (data is! Map<String, dynamic>) {
        return 'Fehler: Ungültiges Backup-Format';
      }
      _validateBackupData(data);
      await _importData(data);
      return 'Import erfolgreich';
    } on FormatException {
      return 'Fehler: Ungültiges Backup-Format';
    } catch (_) {
      return 'Fehler: Import fehlgeschlagen';
    }
  }

  @visibleForTesting
  void validateBackupData(Map<String, dynamic> data) =>
      _validateBackupData(data);

  void _validateBackupData(Map<String, dynamic> data) {
    final version = data['version'];
    if (version is! int || version < 1 || version > 1) {
      throw const FormatException('Nicht unterstützte Backup-Version');
    }

    _requireList(data, 'categories');
    _requireList(data, 'classes');
    _requireList(data, 'subjects');
    _requireList(data, 'students');
    _requireList(data, 'classSubjects');
    _requireList(data, 'grades');
    _requireList(data, 'semesterSettings');
    // subjectCategoryOverrides is optional for backwards compatibility
    if (data.containsKey('subjectCategoryOverrides')) {
      _requireList(data, 'subjectCategoryOverrides');
    }

    for (final c in data['categories'] as List) {
      _requireFields(c, ['id', 'name', 'weightPercent'], 'categories');
      if (c['id'] is! int) {
        throw const FormatException('Ungültige Kategorie-ID (muss Integer sein)');
      }
      final name = c['name'];
      if (name is! String || name.isEmpty || name.length > 100) {
        throw const FormatException('Ungültiger Kategoriename (max. 100 Zeichen)');
      }
      if (c['weightPercent'] is! num) {
        throw const FormatException('Ungültige Gewichtung in Kategorie (muss Zahl sein)');
      }
      final w = (c['weightPercent'] as num).toDouble();
      if (w < 0 || w > 100) {
        throw const FormatException('Ungültige Gewichtung in Kategorie (0–100%)');
      }
      final colorHex = c['colorHex'];
      if (colorHex != null &&
          (colorHex is! String ||
              !RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(colorHex))) {
        throw const FormatException('Ungültiges colorHex-Format (erwartet: #RRGGBB)');
      }
      final icon = c['icon'];
      if (icon != null &&
          (icon is! String ||
              icon.isEmpty ||
              icon.length > 50 ||
              !RegExp(r'^[a-z0-9_]+$').hasMatch(icon))) {
        throw const FormatException('Ungültiges Icon-Format (nur a-z, 0-9, _)');
      }
    }
    for (final c in data['classes'] as List) {
      _requireFields(c, ['id', 'name', 'schoolYear'], 'classes');
      if (c['id'] is! int) {
        throw const FormatException('Ungültige Klassen-ID (muss Integer sein)');
      }
      final name = c['name'];
      if (name is! String || name.isEmpty || name.length > 100) {
        throw const FormatException('Ungültiger Klassenname (max. 100 Zeichen)');
      }
      final schoolYear = c['schoolYear'];
      if (schoolYear is! String || schoolYear.isEmpty || schoolYear.length > 20) {
        throw const FormatException('Ungültiges Schuljahr (max. 20 Zeichen)');
      }
    }
    for (final s in data['subjects'] as List) {
      _requireFields(s, ['id', 'name'], 'subjects');
      if (s['id'] is! int) {
        throw const FormatException('Ungültige Fach-ID (muss Integer sein)');
      }
      final name = s['name'];
      if (name is! String || name.isEmpty || name.length > 100) {
        throw const FormatException('Ungültiger Fachname (max. 100 Zeichen)');
      }
    }
    for (final s in data['students'] as List) {
      _requireFields(s, ['id', 'classId', 'firstName', 'lastName'], 'students');
      if (s['id'] is! int) {
        throw const FormatException('Ungültige Schüler-ID (muss Integer sein)');
      }
      if (s['classId'] is! int) {
        throw const FormatException('Ungültige classId in students (muss Integer sein)');
      }
      final firstName = s['firstName'];
      final lastName = s['lastName'];
      if (firstName is! String || firstName.isEmpty || firstName.length > 100) {
        throw const FormatException('Ungültiger Vorname (max. 100 Zeichen)');
      }
      if (lastName is! String || lastName.isEmpty || lastName.length > 100) {
        throw const FormatException('Ungültiger Nachname (max. 100 Zeichen)');
      }
    }
    for (final cs in data['classSubjects'] as List) {
      _requireFields(cs, ['classId', 'subjectId'], 'classSubjects');
      if (cs['classId'] is! int) {
        throw const FormatException('Ungültige classId in classSubjects (muss Integer sein)');
      }
      if (cs['subjectId'] is! int) {
        throw const FormatException('Ungültige subjectId in classSubjects (muss Integer sein)');
      }
    }
    for (final g in data['grades'] as List) {
      _requireFields(
          g, ['id', 'studentId', 'subjectId', 'categoryId', 'value', 'semester', 'date'],
          'grades');
      if (g['id'] is! int) {
        throw const FormatException('Ungültige Noten-ID (muss Integer sein)');
      }
      if (g['studentId'] is! int) {
        throw const FormatException('Ungültige studentId in grades (muss Integer sein)');
      }
      if (g['subjectId'] is! int) {
        throw const FormatException('Ungültige subjectId in grades (muss Integer sein)');
      }
      if (g['categoryId'] is! int) {
        throw const FormatException('Ungültige categoryId in grades (muss Integer sein)');
      }
      if (g['value'] is! num) {
        throw const FormatException('Ungültiger Notenwert (muss Zahl sein)');
      }
      final v = (g['value'] as num).toDouble();
      if (v < 0.67 || v > 6.0) {
        throw const FormatException('Ungültiger Notenwert (1+ bis 6)');
      }
      final factor = g['factor'];
      if (factor != null) {
        if (factor is! num) {
          throw const FormatException('Ungültiger Faktor (muss Zahl sein)');
        }
        final f = factor.toDouble();
        if (f < 0.1 || f > 10) {
          throw const FormatException('Ungültiger Faktor (0,1–10)');
        }
      }
      if (g['semester'] is! int) {
        throw const FormatException('Ungültiges Halbjahr (muss Integer sein)');
      }
      final sem = g['semester'] as int;
      if (sem != 1 && sem != 2) {
        throw const FormatException('Ungültiges Halbjahr (1 oder 2)');
      }
      try {
        DateTime.parse(g['date'] as String);
      } catch (_) {
        throw const FormatException('Ungültiges Datum in Noten');
      }
      final comment = g['comment'];
      if (comment != null && comment is String && comment.length > 500) {
        throw const FormatException('Kommentar zu lang (max. 500 Zeichen)');
      }
    }
    for (final s in data['semesterSettings'] as List) {
      _requireFields(s, ['id', 'firstHalfWeight', 'secondHalfWeight'], 'semesterSettings');
      if (s['id'] is! int) {
        throw const FormatException('Ungültige SemesterSettings-ID (muss Integer sein)');
      }
      if (s['firstHalfWeight'] is! num) {
        throw const FormatException('Ungültige firstHalfWeight (muss Zahl sein)');
      }
      if (s['secondHalfWeight'] is! num) {
        throw const FormatException('Ungültige secondHalfWeight (muss Zahl sein)');
      }
      final subjectId = s['subjectId'];
      if (subjectId != null && subjectId is! int) {
        throw const FormatException(
            'subjectId in semesterSettings muss Integer oder null sein');
      }
      final w1 = (s['firstHalfWeight'] as num).toDouble();
      final w2 = (s['secondHalfWeight'] as num).toDouble();
      if (w1 < 0 || w1 > 100 || w2 < 0 || w2 > 100) {
        throw const FormatException('Ungültige Halbjahresgewichtung (0–100)');
      }
    }
    for (final o in (data['subjectCategoryOverrides'] as List? ?? [])) {
      _requireFields(
          o, ['subjectId', 'categoryId', 'isActive'], 'subjectCategoryOverrides');
      if (o['subjectId'] is! int) {
        throw const FormatException('Ungültige subjectId in subjectCategoryOverrides (muss Integer sein)');
      }
      if (o['categoryId'] is! int) {
        throw const FormatException('Ungültige categoryId in subjectCategoryOverrides (muss Integer sein)');
      }
      if (o['isActive'] is! bool) {
        throw const FormatException('isActive muss ein Boolean sein');
      }
      final wo = o['weightOverride'];
      if (wo != null) {
        if (wo is! num) {
          throw const FormatException(
              'Ungültige Gewichtsüberschreibung (muss Zahl sein)');
        }
        final w = wo.toDouble();
        if (w < 0 || w > 100) {
          throw const FormatException(
              'Ungültige Gewichtsüberschreibung (0–100)');
        }
      }
    }
  }

  void _requireList(Map<String, dynamic> data, String key) {
    if (data[key] is! List) {
      throw FormatException('Fehlende oder ungültige Sektion: $key');
    }
  }

  void _requireFields(dynamic item, List<String> fields, String section) {
    if (item is! Map) throw FormatException('Ungültiger Eintrag in $section');
    for (final f in fields) {
      if (!item.containsKey(f)) {
        throw FormatException('Fehlendes Feld "$f" in $section');
      }
    }
  }

  Future<void> _importData(Map<String, dynamic> data) async {
    await db.transaction(() async {
      // Delete in reverse dependency order
      await db.delete(db.grades).go();
      await db.delete(db.semesterSettings).go();
      await db.delete(db.subjectCategoryOverrides).go();
      await db.delete(db.classSubjects).go();
      await db.delete(db.students).go();
      await db.delete(db.classes).go();
      await db.delete(db.subjects).go();
      await db.delete(db.gradeCategories).go();

      // Import categories (with explicit IDs to preserve FK references)
      for (final c in (data['categories'] as List)) {
        await db.into(db.gradeCategories).insert(
              GradeCategoriesCompanion(
                id: Value(c['id'] as int),
                name: Value(c['name'] as String),
                weightPercent:
                    Value((c['weightPercent'] as num).toDouble()),
                colorHex: Value(c['colorHex'] as String? ?? '#2196F3'),
                icon: Value(c['icon'] as String? ?? 'label'),
              ),
            );
      }

      // Import classes (with explicit IDs)
      for (final c in (data['classes'] as List)) {
        await db.into(db.classes).insert(
              ClassesCompanion(
                id: Value(c['id'] as int),
                name: Value(c['name'] as String),
                schoolYear: Value(c['schoolYear'] as String),
              ),
            );
      }

      // Import subjects (with explicit IDs)
      for (final s in (data['subjects'] as List)) {
        await db.into(db.subjects).insert(
              SubjectsCompanion(
                id: Value(s['id'] as int),
                name: Value(s['name'] as String),
              ),
            );
      }

      // Import students (with explicit IDs)
      for (final s in (data['students'] as List)) {
        await db.into(db.students).insert(
              StudentsCompanion(
                id: Value(s['id'] as int),
                classId: Value(s['classId'] as int),
                firstName: Value(s['firstName'] as String),
                lastName: Value(s['lastName'] as String),
              ),
            );
      }

      // Import class-subject links
      for (final cs in (data['classSubjects'] as List)) {
        await db.into(db.classSubjects).insertOnConflictUpdate(
              ClassSubjectsCompanion.insert(
                classId: cs['classId'] as int,
                subjectId: cs['subjectId'] as int,
              ),
            );
      }

      // Import grades (with explicit IDs)
      for (final g in (data['grades'] as List)) {
        await db.into(db.grades).insert(
              GradesCompanion(
                id: Value(g['id'] as int),
                studentId: Value(g['studentId'] as int),
                subjectId: Value(g['subjectId'] as int),
                categoryId: Value(g['categoryId'] as int),
                value: Value((g['value'] as num).toDouble()),
                factor: Value(g['factor'] != null
                    ? (g['factor'] as num).toDouble()
                    : 1.0),
                semester: Value(g['semester'] as int),
                date: Value(DateTime.parse(g['date'] as String)),
                comment: Value(g['comment'] as String? ?? ''),
              ),
            );
      }

      // Import semester settings (with explicit IDs)
      for (final s in (data['semesterSettings'] as List)) {
        await db.into(db.semesterSettings).insert(
              SemesterSettingsCompanion(
                id: Value(s['id'] as int),
                subjectId: Value(s['subjectId'] as int?),
                firstHalfWeight:
                    Value((s['firstHalfWeight'] as num).toDouble()),
                secondHalfWeight:
                    Value((s['secondHalfWeight'] as num).toDouble()),
              ),
            );
      }

      // Import subject category overrides (optional field for backwards compat)
      for (final o in (data['subjectCategoryOverrides'] as List? ?? [])) {
        await db.into(db.subjectCategoryOverrides).insertOnConflictUpdate(
              SubjectCategoryOverridesCompanion(
                subjectId: Value(o['subjectId'] as int),
                categoryId: Value(o['categoryId'] as int),
                isActive: Value(o['isActive'] as bool),
                weightOverride: Value(
                  o['weightOverride'] != null
                      ? (o['weightOverride'] as num).toDouble()
                      : null,
                ),
              ),
            );
      }
    });
  }
}
