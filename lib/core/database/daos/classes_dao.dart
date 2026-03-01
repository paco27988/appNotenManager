import 'package:drift/drift.dart';
import '../app_database.dart';

part 'classes_dao.g.dart';

@DriftAccessor(tables: [Classes, Students, Subjects, ClassSubjects])
class ClassesDao extends DatabaseAccessor<AppDatabase> with _$ClassesDaoMixin {
  ClassesDao(super.db);

  Stream<List<SchoolClass>> watchAll() => select(classes).watch();

  Future<List<SchoolClass>> getAll() => select(classes).get();

  Future<SchoolClass?> getById(int id) =>
      (select(classes)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> create(ClassesCompanion entry) => into(classes).insert(entry);

  Future<bool> update_(ClassesCompanion entry) =>
      update(classes).replace(entry);

  Future<int> deleteById(int id) =>
      (delete(classes)..where((t) => t.id.equals(id))).go();

  // Get subjects assigned to a class
  Future<List<Subject>> getSubjectsForClass(int classId) {
    final query = select(subjects).join([
      innerJoin(
        classSubjects,
        classSubjects.subjectId.equalsExp(subjects.id),
      ),
    ])
      ..where(classSubjects.classId.equals(classId));
    return query.map((row) => row.readTable(subjects)).get();
  }

  Stream<List<Subject>> watchSubjectsForClass(int classId) {
    final query = select(subjects).join([
      innerJoin(
        classSubjects,
        classSubjects.subjectId.equalsExp(subjects.id),
      ),
    ])
      ..where(classSubjects.classId.equals(classId));
    return query.map((row) => row.readTable(subjects)).watch();
  }

  Future<void> assignSubject(int classId, int subjectId) =>
      into(classSubjects).insertOnConflictUpdate(
        ClassSubjectsCompanion.insert(classId: classId, subjectId: subjectId),
      );

  Future<int> removeSubject(int classId, int subjectId) =>
      (delete(classSubjects)
            ..where(
              (t) =>
                  t.classId.equals(classId) & t.subjectId.equals(subjectId),
            ))
          .go();

  Future<int> removeAllClassSubjectsForSubject(int subjectId) =>
      (delete(classSubjects)..where((t) => t.subjectId.equals(subjectId))).go();
}
