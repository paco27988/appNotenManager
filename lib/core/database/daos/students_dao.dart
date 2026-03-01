import 'package:drift/drift.dart';
import '../app_database.dart';

part 'students_dao.g.dart';

@DriftAccessor(tables: [Students])
class StudentsDao extends DatabaseAccessor<AppDatabase>
    with _$StudentsDaoMixin {
  StudentsDao(super.db);

  Stream<List<Student>> watchByClass(int classId) =>
      (select(students)..where((t) => t.classId.equals(classId))).watch();

  Future<List<Student>> getByClass(int classId) =>
      (select(students)..where((t) => t.classId.equals(classId))).get();

  Future<Student?> getById(int id) =>
      (select(students)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> create(StudentsCompanion entry) => into(students).insert(entry);

  Future<bool> update_(StudentsCompanion entry) =>
      update(students).replace(entry);

  Future<int> deleteById(int id) =>
      (delete(students)..where((t) => t.id.equals(id))).go();

  Future<int> deleteByClass(int classId) =>
      (delete(students)..where((t) => t.classId.equals(classId))).go();
}
