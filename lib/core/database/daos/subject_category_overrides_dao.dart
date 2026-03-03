import 'package:drift/drift.dart';
import '../app_database.dart';

part 'subject_category_overrides_dao.g.dart';

@DriftAccessor(tables: [SubjectCategoryOverrides])
class SubjectCategoryOverridesDao extends DatabaseAccessor<AppDatabase>
    with _$SubjectCategoryOverridesDaoMixin {
  SubjectCategoryOverridesDao(super.db);

  Stream<List<SubjectCategoryOverride>> watchForSubject(int subjectId) =>
      (select(subjectCategoryOverrides)
            ..where((t) => t.subjectId.equals(subjectId)))
          .watch();

  Future<List<SubjectCategoryOverride>> getForSubject(int subjectId) =>
      (select(subjectCategoryOverrides)
            ..where((t) => t.subjectId.equals(subjectId)))
          .get();

  Future<List<SubjectCategoryOverride>> getAll() =>
      select(subjectCategoryOverrides).get();

  Future<void> upsert(
    int subjectId,
    int categoryId,
    bool isActive,
    double? weightOverride,
  ) =>
      into(subjectCategoryOverrides).insertOnConflictUpdate(
        SubjectCategoryOverridesCompanion(
          subjectId: Value(subjectId),
          categoryId: Value(categoryId),
          isActive: Value(isActive),
          weightOverride: Value(weightOverride),
        ),
      );

  Future<int> deleteForSubject(int subjectId) =>
      (delete(subjectCategoryOverrides)
            ..where((t) => t.subjectId.equals(subjectId)))
          .go();

  Future<int> deleteForCategory(int categoryId) =>
      (delete(subjectCategoryOverrides)
            ..where((t) => t.categoryId.equals(categoryId)))
          .go();
}
