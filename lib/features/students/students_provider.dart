import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../database_provider.dart';

final studentsByClassProvider =
    StreamProvider.family<List<Student>, int>((ref, classId) {
  final db = ref.watch(databaseProvider);
  return db.studentsDao.watchByClass(classId);
});

final studentByIdProvider =
    StreamProvider.family<Student?, int>((ref, id) {
  final db = ref.watch(databaseProvider);
  return db.studentsDao.watchById(id);
});

final studentsNotifierProvider =
    AsyncNotifierProvider<StudentsNotifier, void>(StudentsNotifier.new);

class StudentsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  AppDatabase get _db => ref.read(databaseProvider);

  Future<void> addStudent(
    int classId,
    String firstName,
    String lastName,
  ) async {
    await _db.studentsDao.create(
      StudentsCompanion.insert(
        classId: classId,
        firstName: firstName,
        lastName: lastName,
      ),
    );
  }

  Future<void> updateStudent(
    int id,
    int classId,
    String firstName,
    String lastName,
  ) async {
    await _db.studentsDao.update_(
      StudentsCompanion(
        id: Value(id),
        classId: Value(classId),
        firstName: Value(firstName),
        lastName: Value(lastName),
      ),
    );
  }

  Future<void> deleteStudent(int id, int classId) async {
    await _db.transaction(() async {
      await _db.gradesDao.deleteByStudent(id);
      await _db.studentsDao.deleteById(id);
    });
  }
}
