import 'package:drift/drift.dart';
import '../app_database.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [GradeCategories])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  Stream<List<GradeCategory>> watchAll() => select(gradeCategories).watch();

  Future<List<GradeCategory>> getAll() => select(gradeCategories).get();

  Future<GradeCategory?> getById(int id) =>
      (select(gradeCategories)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> create(GradeCategoriesCompanion entry) =>
      into(gradeCategories).insert(entry);

  Future<bool> update_(GradeCategoriesCompanion entry) =>
      update(gradeCategories).replace(entry);

  Future<int> deleteById(int id) =>
      (delete(gradeCategories)..where((t) => t.id.equals(id))).go();
}
