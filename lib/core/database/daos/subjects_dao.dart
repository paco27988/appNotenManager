import 'package:drift/drift.dart';
import '../app_database.dart';

part 'subjects_dao.g.dart';

@DriftAccessor(tables: [Subjects])
class SubjectsDao extends DatabaseAccessor<AppDatabase>
    with _$SubjectsDaoMixin {
  SubjectsDao(super.db);

  Stream<List<Subject>> watchAll() => select(subjects).watch();

  Future<List<Subject>> getAll() => select(subjects).get();

  Future<Subject?> getById(int id) =>
      (select(subjects)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> create(SubjectsCompanion entry) => into(subjects).insert(entry);

  Future<bool> update_(SubjectsCompanion entry) =>
      update(subjects).replace(entry);

  Future<int> deleteById(int id) =>
      (delete(subjects)..where((t) => t.id.equals(id))).go();
}
