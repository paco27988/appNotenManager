import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../database_provider.dart';

// ─── Read providers ───────────────────────────────────────────────────────────

final classesStreamProvider = StreamProvider<List<SchoolClass>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.classesDao.watchAll();
});

final classByIdProvider =
    StreamProvider.family<SchoolClass?, int>((ref, id) {
  final db = ref.watch(databaseProvider);
  return db.classesDao.watchById(id);
});

final classSubjectsProvider =
    StreamProvider.family<List<Subject>, int>((ref, classId) {
  final db = ref.watch(databaseProvider);
  return db.classesDao.watchSubjectsForClass(classId);
});

// ─── Notifier ─────────────────────────────────────────────────────────────────

final classesNotifierProvider =
    AsyncNotifierProvider<ClassesNotifier, List<SchoolClass>>(
  ClassesNotifier.new,
);

class ClassesNotifier extends AsyncNotifier<List<SchoolClass>> {
  @override
  Future<List<SchoolClass>> build() async {
    final db = ref.watch(databaseProvider);
    return db.classesDao.getAll();
  }

  AppDatabase get _db => ref.read(databaseProvider);

  Future<void> addClass(String name, String schoolYear) async {
    await _db.classesDao.create(
      ClassesCompanion.insert(name: name, schoolYear: schoolYear),
    );
    ref.invalidateSelf();
  }

  Future<void> updateClass(int id, String name, String schoolYear) async {
    await _db.classesDao.update_(
      ClassesCompanion(
        id: Value(id),
        name: Value(name),
        schoolYear: Value(schoolYear),
      ),
    );
    ref.invalidateSelf();
  }

  Future<void> deleteClass(int id) async {
    await _db.transaction(() async {
      final students = await _db.studentsDao.getByClass(id);
      for (final s in students) {
        await _db.gradesDao.deleteByStudent(s.id);
      }
      await _db.studentsDao.deleteByClass(id);
      final subs = await _db.classesDao.getSubjectsForClass(id);
      for (final sub in subs) {
        await _db.classesDao.removeSubject(id, sub.id);
      }
      await _db.classesDao.deleteById(id);
    });
    ref.invalidateSelf();
  }

  Future<void> assignSubject(int classId, int subjectId) async {
    await _db.classesDao.assignSubject(classId, subjectId);
  }

  Future<void> removeSubject(int classId, int subjectId) async {
    await _db.classesDao.removeSubject(classId, subjectId);
  }
}
