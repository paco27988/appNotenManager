import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../database_provider.dart';

final globalSemesterSettingProvider =
    StreamProvider<SemesterSetting?>((ref) {
  final db = ref.watch(databaseProvider);
  return db.settingsDao.watchGlobal();
});

final subjectSemesterSettingProvider =
    StreamProvider.family<SemesterSetting?, int>((ref, subjectId) {
  final db = ref.watch(databaseProvider);
  return db.settingsDao.watchForSubject(subjectId);
});

final settingsNotifierProvider =
    AsyncNotifierProvider<SettingsNotifier, void>(SettingsNotifier.new);

class SettingsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  AppDatabase get _db => ref.read(databaseProvider);

  Future<void> updateGlobal(double first, double second) async {
    await _db.settingsDao.upsertGlobal(first, second);
  }

  Future<void> updateForSubject(
    int subjectId,
    double first,
    double second,
  ) async {
    await _db.settingsDao.upsertForSubject(subjectId, first, second);
  }

  Future<void> resetSubjectOverride(int subjectId) async {
    await _db.settingsDao.deleteForSubject(subjectId);
  }
}
