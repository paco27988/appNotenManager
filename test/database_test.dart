import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leher_app/core/database/app_database.dart';
import 'package:leher_app/features/backup/backup_service.dart';

AppDatabase _createDb() =>
    AppDatabase.forTesting(NativeDatabase.memory(setup: (db) {
      db.execute('PRAGMA foreign_keys = ON');
    }));

void main() {
  late AppDatabase db;

  setUp(() {
    db = _createDb();
  });

  tearDown(() => db.close());

  // ── Cascade: deleteCategory deletes grades ────────────────────────────────

  test('deleteCategory cascades to grades (K-1 regression)', () async {
    // Insert a category
    final catId = await db.into(db.gradeCategories).insert(
          GradeCategoriesCompanion.insert(
            name: 'Test',
            weightPercent: 100.0,
          ),
        );

    // Insert a class, subject, student needed for grade FK
    final classId = await db.into(db.classes).insert(
          ClassesCompanion.insert(name: '9a', schoolYear: '2024/25'),
        );
    final subjectId = await db.into(db.subjects).insert(
          SubjectsCompanion.insert(name: 'Mathe'),
        );
    final studentId = await db.into(db.students).insert(
          StudentsCompanion.insert(
            classId: classId,
            firstName: 'Max',
            lastName: 'Muster',
          ),
        );

    // Insert a grade in that category
    await db.into(db.grades).insert(
          GradesCompanion.insert(
            studentId: studentId,
            subjectId: subjectId,
            categoryId: catId,
            value: 3.0,
            semester: 1,
            date: DateTime(2024, 3, 1),
          ),
        );

    // Verify grade exists
    final gradesBefore = await db.gradesDao.getAll();
    expect(gradesBefore.length, 1);

    // Delete category via notifier transaction
    await db.transaction(() async {
      await db.gradesDao.deleteByCategory(catId);
      await db.subjectCategoryOverridesDao.deleteForCategory(catId);
      await db.categoriesDao.deleteById(catId);
    });

    // Grade must be gone
    final gradesAfter = await db.gradesDao.getAll();
    expect(gradesAfter, isEmpty);
  });

  // ── Cascade: deleteStudent deletes grades ─────────────────────────────────

  test('deleteStudent cascades to grades (K-2 regression)', () async {
    // Setup
    final classId = await db.into(db.classes).insert(
          ClassesCompanion.insert(name: '9a', schoolYear: '2024/25'),
        );
    final subjectId = await db.into(db.subjects).insert(
          SubjectsCompanion.insert(name: 'Mathe'),
        );
    final catId = await db.into(db.gradeCategories).insert(
          GradeCategoriesCompanion.insert(
            name: 'Mündlich',
            weightPercent: 100.0,
          ),
        );
    final studentId = await db.into(db.students).insert(
          StudentsCompanion.insert(
            classId: classId,
            firstName: 'Max',
            lastName: 'Muster',
          ),
        );
    await db.into(db.grades).insert(
          GradesCompanion.insert(
            studentId: studentId,
            subjectId: subjectId,
            categoryId: catId,
            value: 2.0,
            semester: 1,
            date: DateTime(2024, 3, 1),
          ),
        );

    final gradesBefore = await db.gradesDao.getAll();
    expect(gradesBefore.length, 1);

    // Delete student via transaction (as in fixed students_provider)
    await db.transaction(() async {
      await db.gradesDao.deleteByStudent(studentId);
      await db.studentsDao.deleteById(studentId);
    });

    final gradesAfter = await db.gradesDao.getAll();
    expect(gradesAfter, isEmpty);
    final students = await db.studentsDao.getByClass(classId);
    expect(students, isEmpty);
  });

  // ── Cascade: deleteSubject deletes grades + settings + overrides ──────────

  test('deleteSubject cascades to grades, settings, overrides, classSubjects',
      () async {
    final classId = await db.into(db.classes).insert(
          ClassesCompanion.insert(name: '9a', schoolYear: '2024/25'),
        );
    final subjectId = await db.into(db.subjects).insert(
          SubjectsCompanion.insert(name: 'Mathe'),
        );
    final catId = await db.into(db.gradeCategories).insert(
          GradeCategoriesCompanion.insert(
            name: 'Mündlich',
            weightPercent: 100.0,
          ),
        );
    final studentId = await db.into(db.students).insert(
          StudentsCompanion.insert(
            classId: classId,
            firstName: 'Max',
            lastName: 'Muster',
          ),
        );

    // Grade
    await db.into(db.grades).insert(
          GradesCompanion.insert(
            studentId: studentId,
            subjectId: subjectId,
            categoryId: catId,
            value: 2.0,
            semester: 1,
            date: DateTime(2024, 3, 1),
          ),
        );

    // Class-subject link
    await db.classesDao.assignSubject(classId, subjectId);

    // Semester settings for subject
    await db.settingsDao.upsertForSubject(subjectId, 50.0, 50.0);

    // Delete subject with full cascade
    await db.transaction(() async {
      await db.gradesDao.deleteBySubject(subjectId);
      await db.settingsDao.deleteForSubject(subjectId);
      await db.subjectCategoryOverridesDao.deleteForSubject(subjectId);
      await db.classesDao.removeAllClassSubjectsForSubject(subjectId);
      await db.subjectsDao.deleteById(subjectId);
    });

    expect(await db.gradesDao.getAll(), isEmpty);
    expect(await db.subjectsDao.getAll(), isEmpty);
    final remaining = await db.classesDao.getSubjectsForClass(classId);
    expect(remaining, isEmpty);
  });

  // ── Cascade: deleteClass deletes grades ──────────────────────────────────

  test('deleteClass cascades to students and grades (K-1 regression)', () async {
    final catId = await db.into(db.gradeCategories).insert(
          GradeCategoriesCompanion.insert(
            name: 'Mündlich',
            weightPercent: 60.0,
          ),
        );
    final classId = await db.into(db.classes).insert(
          ClassesCompanion.insert(name: '10b', schoolYear: '2024/25'),
        );
    final subjectId = await db.into(db.subjects).insert(
          SubjectsCompanion.insert(name: 'Deutsch'),
        );
    final studentId = await db.into(db.students).insert(
          StudentsCompanion.insert(
            classId: classId,
            firstName: 'Lisa',
            lastName: 'Müller',
          ),
        );
    await db.into(db.grades).insert(
          GradesCompanion.insert(
            studentId: studentId,
            subjectId: subjectId,
            categoryId: catId,
            value: 2.0,
            semester: 1,
            date: DateTime(2024, 3, 1),
          ),
        );
    await db.classesDao.assignSubject(classId, subjectId);

    // Cascade delete: grades → students → classSubjects → class
    await db.transaction(() async {
      final students = await db.studentsDao.getByClass(classId);
      for (final s in students) {
        await db.gradesDao.deleteByStudent(s.id);
      }
      await db.studentsDao.deleteByClass(classId);
      final subs = await db.classesDao.getSubjectsForClass(classId);
      for (final sub in subs) {
        await db.classesDao.removeSubject(classId, sub.id);
      }
      await db.classesDao.deleteById(classId);
    });

    expect(await db.gradesDao.getAll(), isEmpty);
    expect(await db.studentsDao.getByClass(classId), isEmpty);
    expect(await db.classesDao.getSubjectsForClass(classId), isEmpty);
    expect(await db.classesDao.getById(classId), equals(null));
  });

  // ── T3: SettingsDao.upsertForSubject idempotency ──────────────────────────

  test('upsertForSubject is idempotent: second call updates, does not insert', () async {
    final subjectId = await db.into(db.subjects).insert(
      SubjectsCompanion.insert(name: 'Mathe'),
    );
    await db.settingsDao.upsertForSubject(subjectId, 60.0, 40.0);
    await db.settingsDao.upsertForSubject(subjectId, 70.0, 30.0);
    final all = await db.settingsDao.getAll();
    final subjectRows = all.where((s) => s.subjectId == subjectId).toList();
    expect(subjectRows.length, 1);
    expect(subjectRows.first.firstHalfWeight, closeTo(70.0, 0.001));
    expect(subjectRows.first.secondHalfWeight, closeTo(30.0, 0.001));
  });

  // ── T4: Backup round-trip with non-empty subjectCategoryOverrides ─────────

  test('Backup round-trip preserves subjectCategoryOverrides', () async {
    final defaultCats = await db.categoriesDao.getAll();
    final catId = defaultCats.first.id;
    final subjectId = await db.into(db.subjects).insert(
      SubjectsCompanion.insert(name: 'Physik'),
    );
    await db.subjectCategoryOverridesDao.upsert(subjectId, catId, false, 75.0);

    final service = BackupService(db);
    final data = await service.exportData();
    final overridesInPayload = data['subjectCategoryOverrides'] as List<dynamic>;
    expect(overridesInPayload.length, 1);
    expect(overridesInPayload.first['isActive'], isFalse);

    await service.importData(data);
    final overridesAfter = await db.subjectCategoryOverridesDao.getAll();
    expect(overridesAfter.length, 1);
    expect(overridesAfter.first.isActive, isFalse);
    expect(overridesAfter.first.weightOverride, closeTo(75.0, 0.001));
  });

  // ── T5: importData with absent subjectCategoryOverrides key ──────────────

  test('importData succeeds when subjectCategoryOverrides key is absent', () async {
    final data = {
      'version': 1,
      'exportedAt': '2024-01-01T00:00:00.000',
      'categories': <dynamic>[],
      'classes': <dynamic>[],
      'subjects': <dynamic>[],
      'students': <dynamic>[],
      'classSubjects': <dynamic>[],
      'grades': <dynamic>[],
      'semesterSettings': <dynamic>[],
    };
    await expectLater(BackupService(db).importData(data), completes);
  });

  // ── T6: deleteClass cascade with multiple subjects ────────────────────────

  test('deleteClass cascade removes all classSubjects when multiple subjects assigned', () async {
    final classId = await db.into(db.classes).insert(
      ClassesCompanion.insert(name: '11c', schoolYear: '2024/25'),
    );
    final sub1 = await db.into(db.subjects).insert(SubjectsCompanion.insert(name: 'Mathe'));
    final sub2 = await db.into(db.subjects).insert(SubjectsCompanion.insert(name: 'Deutsch'));
    await db.classesDao.assignSubject(classId, sub1);
    await db.classesDao.assignSubject(classId, sub2);

    await db.transaction(() async {
      final students = await db.studentsDao.getByClass(classId);
      for (final s in students) {
        await db.gradesDao.deleteByStudent(s.id);
      }
      await db.studentsDao.deleteByClass(classId);
      final subs = await db.classesDao.getSubjectsForClass(classId);
      for (final sub in subs) {
        await db.classesDao.removeSubject(classId, sub.id);
      }
      await db.classesDao.deleteById(classId);
    });

    expect(await db.classesDao.getSubjectsForClass(classId), isEmpty);
    expect(await db.classesDao.getById(classId), equals(null));
  });

  // ── T7: SubjectCategoryOverridesDao.upsert idempotency ───────────────────

  test('subjectCategoryOverrides upsert is idempotent', () async {
    final subjectId = await db.into(db.subjects).insert(SubjectsCompanion.insert(name: 'Bio'));
    final defaultCats = await db.categoriesDao.getAll();
    final catId = defaultCats.first.id;

    await db.subjectCategoryOverridesDao.upsert(subjectId, catId, true, 60.0);
    await db.subjectCategoryOverridesDao.upsert(subjectId, catId, false, 80.0);
    final all = await db.subjectCategoryOverridesDao.getAll();
    final rows = all.where((r) => r.subjectId == subjectId && r.categoryId == catId).toList();
    expect(rows.length, 1);
    expect(rows.first.isActive, isFalse);
    expect(rows.first.weightOverride, closeTo(80.0, 0.001));
  });

  // ── FK Enforcement ────────────────────────────────────────────────────────

  test('FK enforcement: grade with invalid studentId throws', () async {
    final subjectId = await db.into(db.subjects).insert(
          SubjectsCompanion.insert(name: 'Mathe'),
        );
    final catId = await db.into(db.gradeCategories).insert(
          GradeCategoriesCompanion.insert(
            name: 'Mündlich',
            weightPercent: 100.0,
          ),
        );

    await expectLater(
      db.into(db.grades).insert(
            GradesCompanion.insert(
              studentId: 9999, // non-existent
              subjectId: subjectId,
              categoryId: catId,
              value: 3.0,
              semester: 1,
              date: DateTime(2024, 3, 1),
            ),
          ),
      throwsA(anything),
    );
  });

  // ── Backup Round-Trip ─────────────────────────────────────────────────────

  test('Full backup round-trip: export → import → data matches', () async {
    // _insertDefaults() already created 3 categories (Mündlich, Schriftlich, Referate).
    // Use the first default category instead of inserting a duplicate.
    final defaultCats = await db.categoriesDao.getAll();
    final catId = defaultCats.first.id; // id=1 = 'Mündlich'

    final classId = await db.into(db.classes).insert(
          ClassesCompanion.insert(name: '9a', schoolYear: '2024/25'),
        );
    final subjectId = await db.into(db.subjects).insert(
          SubjectsCompanion.insert(name: 'Mathe'),
        );
    final studentId = await db.into(db.students).insert(
          StudentsCompanion.insert(
            classId: classId,
            firstName: 'Anna',
            lastName: 'Müller',
          ),
        );
    await db.into(db.grades).insert(
          GradesCompanion.insert(
            studentId: studentId,
            subjectId: subjectId,
            categoryId: catId,
            value: 2.0,
            semester: 1,
            date: DateTime(2024, 3, 15),
            comment: const Value('Gut'),
          ),
        );

    // Export → importData wipes DB and re-imports in one transaction
    final service = BackupService(db);
    final data = await service.exportData();
    await service.importData(data);

    // All 3 default categories are preserved through the round-trip
    final categories = await db.categoriesDao.getAll();
    expect(categories.length, 3);
    expect(categories.any((c) => c.name == 'Mündlich'), isTrue);

    final classes = await db.classesDao.getAll();
    expect(classes.length, 1);
    expect(classes.first.name, '9a');

    final grades = await db.gradesDao.getAll();
    expect(grades.length, 1);
    expect(grades.first.value, closeTo(2.0, 0.001));
    expect(grades.first.comment, 'Gut');
  });
}
