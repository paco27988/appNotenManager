import 'package:drift/drift.dart';
import '../app_database.dart';

part 'grades_dao.g.dart';

@DriftAccessor(tables: [Grades, Students])
class GradesDao extends DatabaseAccessor<AppDatabase> with _$GradesDaoMixin {
  GradesDao(super.db);

  Stream<List<Grade>> watchByStudent(int studentId) =>
      (select(grades)..where((t) => t.studentId.equals(studentId))).watch();

  Stream<List<Grade>> watchByStudentSubject(int studentId, int subjectId) =>
      (select(grades)
            ..where(
              (t) =>
                  t.studentId.equals(studentId) &
                  t.subjectId.equals(subjectId),
            )
            ..orderBy([(t) => OrderingTerm(expression: t.date)]))
          .watch();

  Future<List<Grade>> getByStudentSubject(int studentId, int subjectId) =>
      (select(grades)
            ..where(
              (t) =>
                  t.studentId.equals(studentId) &
                  t.subjectId.equals(subjectId),
            ))
          .get();

  Future<List<Grade>> getByStudent(int studentId) =>
      (select(grades)..where((t) => t.studentId.equals(studentId))).get();

  Future<List<Grade>> getAll() => select(grades).get();

  Future<int> create(GradesCompanion entry) => into(grades).insert(entry);

  Future<bool> update_(GradesCompanion entry) => update(grades).replace(entry);

  Future<int> deleteById(int id) =>
      (delete(grades)..where((t) => t.id.equals(id))).go();

  Future<int> deleteByStudent(int studentId) =>
      (delete(grades)..where((t) => t.studentId.equals(studentId))).go();

  Future<int> deleteBySubject(int subjectId) =>
      (delete(grades)..where((t) => t.subjectId.equals(subjectId))).go();

  Future<int> deleteByCategory(int categoryId) =>
      (delete(grades)..where((t) => t.categoryId.equals(categoryId))).go();

  Future<int> deleteByStudentSubject(int studentId, int subjectId) =>
      (delete(grades)
            ..where(
              (t) =>
                  t.studentId.equals(studentId) &
                  t.subjectId.equals(subjectId),
            ))
          .go();
}
