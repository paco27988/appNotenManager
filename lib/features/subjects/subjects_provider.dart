import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../database_provider.dart';

final subjectsStreamProvider = StreamProvider<List<Subject>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.subjectsDao.watchAll();
});

final subjectsNotifierProvider =
    AsyncNotifierProvider<SubjectsNotifier, List<Subject>>(
  SubjectsNotifier.new,
);

class SubjectsNotifier extends AsyncNotifier<List<Subject>> {
  @override
  Future<List<Subject>> build() async {
    final db = ref.watch(databaseProvider);
    return db.subjectsDao.getAll();
  }

  AppDatabase get _db => ref.read(databaseProvider);

  Future<void> addSubject(String name) async {
    await _db.subjectsDao.create(SubjectsCompanion.insert(name: name));
    ref.invalidateSelf();
  }

  Future<void> updateSubject(int id, String name) async {
    await _db.subjectsDao.update_(
      SubjectsCompanion(id: Value(id), name: Value(name)),
    );
    ref.invalidateSelf();
  }

  Future<void> deleteSubject(int id) async {
    await _db.transaction(() async {
      await _db.gradesDao.deleteBySubject(id);
      await _db.settingsDao.deleteForSubject(id);
      await _db.subjectCategoryOverridesDao.deleteForSubject(id);
      await _db.classesDao.removeAllClassSubjectsForSubject(id);
      await _db.subjectsDao.deleteById(id);
    });
    ref.invalidateSelf();
  }
}
