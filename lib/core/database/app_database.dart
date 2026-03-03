import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'daos/classes_dao.dart';
import 'daos/students_dao.dart';
import 'daos/subjects_dao.dart';
import 'daos/grades_dao.dart';
import 'daos/categories_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/subject_category_overrides_dao.dart';

part 'app_database.g.dart';

// ─── Tables ───────────────────────────────────────────────────────────────────

@DataClassName('SchoolClass')
class Classes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get schoolYear => text().withLength(min: 1, max: 20)();
}

class Students extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get classId => integer().references(Classes, #id)();
  TextColumn get firstName => text().withLength(min: 1, max: 100)();
  TextColumn get lastName => text().withLength(min: 1, max: 100)();
}

class Subjects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
}

// Many-to-Many: Classes <-> Subjects
class ClassSubjects extends Table {
  IntColumn get classId => integer().references(Classes, #id)();
  IntColumn get subjectId => integer().references(Subjects, #id)();

  @override
  Set<Column> get primaryKey => {classId, subjectId};
}

class GradeCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  RealColumn get weightPercent => real()();
  TextColumn get colorHex => text().withDefault(const Constant('#2196F3'))();
  TextColumn get icon => text().withDefault(const Constant('school'))();
}

class Grades extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get studentId => integer().references(Students, #id)();
  IntColumn get subjectId => integer().references(Subjects, #id)();
  IntColumn get categoryId => integer().references(GradeCategories, #id)();
  RealColumn get value => real()(); // 1.0–6.0
  RealColumn get factor => real().withDefault(const Constant(1.0))(); // Gewichtungsfaktor z.B. 0.5, 1.0, 2.0
  IntColumn get semester => integer()(); // 1 or 2
  DateTimeColumn get date => dateTime()();
  TextColumn get comment => text().withDefault(const Constant(''))();
}

class SemesterSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  // null = global setting
  IntColumn get subjectId => integer().nullable().references(Subjects, #id)();
  RealColumn get firstHalfWeight => real().withDefault(const Constant(50.0))();
  RealColumn get secondHalfWeight => real().withDefault(const Constant(50.0))();
}

class SubjectCategoryOverrides extends Table {
  IntColumn get subjectId => integer().references(Subjects, #id)();
  IntColumn get categoryId => integer().references(GradeCategories, #id)();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  RealColumn get weightOverride => real().nullable()(); // null = use global weight

  @override
  Set<Column> get primaryKey => {subjectId, categoryId};
}

// ─── Database ─────────────────────────────────────────────────────────────────

@DriftDatabase(
  tables: [
    Classes,
    Students,
    Subjects,
    ClassSubjects,
    GradeCategories,
    Grades,
    SemesterSettings,
    SubjectCategoryOverrides,
  ],
  daos: [
    ClassesDao,
    StudentsDao,
    SubjectsDao,
    GradesDao,
    CategoriesDao,
    SettingsDao,
    SubjectCategoryOverridesDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _insertDefaults();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.createTable(subjectCategoryOverrides);
          if (from < 3) {
            await m.addColumn(grades, grades.factor);
          }
        },
      );

  Future<void> _insertDefaults() async {
    // Default categories: Mündlich 60%, Schriftlich 30%, Referate 10%
    await into(gradeCategories).insert(
      GradeCategoriesCompanion.insert(
        name: 'Mündlich',
        weightPercent: 60.0,
        colorHex: const Value('#4CAF50'),
        icon: const Value('record_voice_over'),
      ),
    );
    await into(gradeCategories).insert(
      GradeCategoriesCompanion.insert(
        name: 'Schriftlich',
        weightPercent: 30.0,
        colorHex: const Value('#2196F3'),
        icon: const Value('edit'),
      ),
    );
    await into(gradeCategories).insert(
      GradeCategoriesCompanion.insert(
        name: 'Referate',
        weightPercent: 10.0,
        colorHex: const Value('#FF9800'),
        icon: const Value('presentation'),
      ),
    );

    // Default global semester settings: 50/50
    await into(semesterSettings).insert(
      SemesterSettingsCompanion.insert(
        firstHalfWeight: const Value(50.0),
        secondHalfWeight: const Value(50.0),
      ),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    if (kIsWeb) {
      // Web: in-memory for now (full web support needs more setup)
      return NativeDatabase.memory(setup: (db) {
        db.execute('PRAGMA foreign_keys = ON');
      });
    }
    final dbFolder = await getApplicationSupportDirectory();
    final file = File(p.join(dbFolder.path, 'leher_app.sqlite'));
    return NativeDatabase.createInBackground(file, setup: (db) {
      db.execute('PRAGMA foreign_keys = ON');
    });
  });
}
