import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../database_provider.dart';

final categoriesStreamProvider = StreamProvider<List<GradeCategory>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.categoriesDao.watchAll();
});

final categoriesNotifierProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<GradeCategory>>(
  CategoriesNotifier.new,
);

class CategoriesNotifier extends AsyncNotifier<List<GradeCategory>> {
  @override
  Future<List<GradeCategory>> build() async {
    final db = ref.watch(databaseProvider);
    return db.categoriesDao.getAll();
  }

  AppDatabase get _db => ref.read(databaseProvider);

  Future<void> addCategory(
    String name,
    double weightPercent,
    String colorHex,
    String icon,
  ) async {
    await _db.categoriesDao.create(
      GradeCategoriesCompanion.insert(
        name: name,
        weightPercent: weightPercent,
        colorHex: Value(colorHex),
        icon: Value(icon),
      ),
    );
    ref.invalidateSelf();
    ref.invalidate(categoriesStreamProvider);
  }

  Future<void> updateCategory(
    int id,
    String name,
    double weightPercent,
    String colorHex,
    String icon,
  ) async {
    await _db.categoriesDao.update_(
      GradeCategoriesCompanion(
        id: Value(id),
        name: Value(name),
        weightPercent: Value(weightPercent),
        colorHex: Value(colorHex),
        icon: Value(icon),
      ),
    );
    ref.invalidateSelf();
    ref.invalidate(categoriesStreamProvider);
  }

  Future<void> deleteCategory(int id) async {
    await _db.categoriesDao.deleteById(id);
    ref.invalidateSelf();
    ref.invalidate(categoriesStreamProvider);
  }

  /// Total weight of all categories – must equal 100 for correct calculation.
  Future<double> getTotalWeight() async {
    final cats = await _db.categoriesDao.getAll();
    double total = 0.0;
    for (final c in cats) {
      total += c.weightPercent;
    }
    return total;
  }
}
