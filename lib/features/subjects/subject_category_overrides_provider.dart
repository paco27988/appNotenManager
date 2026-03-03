import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/utils/grade_calculator.dart';
import '../database_provider.dart';
import '../categories/categories_provider.dart';

// Watches raw overrides for a specific subject
final subjectCategoryOverridesProvider =
    StreamProvider.family<List<SubjectCategoryOverride>, int>(
        (ref, subjectId) {
  final db = ref.watch(databaseProvider);
  return db.subjectCategoryOverridesDao.watchForSubject(subjectId);
});

// Derived provider: effective categories for a subject (drop-in for categoriesStreamProvider)
final effectiveCategoriesProvider =
    Provider.family<AsyncValue<List<GradeCategory>>, int>((ref, subjectId) {
  final categoriesAsync = ref.watch(categoriesStreamProvider);
  final overridesAsync = ref.watch(subjectCategoryOverridesProvider(subjectId));
  return overridesAsync.when(
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
    data: (overrides) => categoriesAsync.whenData(
      (cats) => GradeCalculator.applySubjectOverrides(cats, overrides),
    ),
  );
});

// Notifier for mutations
final subjectCategoryOverridesNotifierProvider = AsyncNotifierProvider.family<
    SubjectCategoryOverridesNotifier, void, int>(
  SubjectCategoryOverridesNotifier.new,
);

class SubjectCategoryOverridesNotifier
    extends FamilyAsyncNotifier<void, int> {
  @override
  Future<void> build(int arg) async {}

  AppDatabase get _db => ref.read(databaseProvider);

  Future<void> upsert(
    int categoryId,
    bool isActive,
    double? weightOverride,
  ) async {
    await _db.subjectCategoryOverridesDao.upsert(
      arg,
      categoryId,
      isActive,
      weightOverride,
    );
  }

  Future<void> resetForSubject() async {
    await _db.subjectCategoryOverridesDao.deleteForSubject(arg);
  }
}
