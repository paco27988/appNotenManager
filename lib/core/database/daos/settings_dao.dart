import 'package:drift/drift.dart';
import '../app_database.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [SemesterSettings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  // Get global setting (subjectId == null)
  Future<SemesterSetting?> getGlobal() =>
      (select(semesterSettings)..where((t) => t.subjectId.isNull()))
          .getSingleOrNull();

  Stream<SemesterSetting?> watchGlobal() =>
      (select(semesterSettings)..where((t) => t.subjectId.isNull()))
          .watchSingleOrNull();

  Future<SemesterSetting?> getForSubject(int subjectId) =>
      (select(semesterSettings)
            ..where((t) => t.subjectId.equals(subjectId)))
          .getSingleOrNull();

  Stream<SemesterSetting?> watchForSubject(int subjectId) =>
      (select(semesterSettings)
            ..where((t) => t.subjectId.equals(subjectId)))
          .watchSingleOrNull();

  Future<void> upsertGlobal(double first, double second) async {
    final existing = await getGlobal();
    if (existing == null) {
      await into(semesterSettings).insert(
        SemesterSettingsCompanion.insert(
          firstHalfWeight: Value(first),
          secondHalfWeight: Value(second),
        ),
      );
    } else {
      await (update(semesterSettings)..where((t) => t.id.equals(existing.id)))
          .write(
        SemesterSettingsCompanion(
          firstHalfWeight: Value(first),
          secondHalfWeight: Value(second),
        ),
      );
    }
  }

  Future<void> upsertForSubject(
    int subjectId,
    double first,
    double second,
  ) async {
    final existing = await getForSubject(subjectId);
    if (existing == null) {
      await into(semesterSettings).insert(
        SemesterSettingsCompanion.insert(
          subjectId: Value(subjectId),
          firstHalfWeight: Value(first),
          secondHalfWeight: Value(second),
        ),
      );
    } else {
      await (update(semesterSettings)..where((t) => t.id.equals(existing.id)))
          .write(
        SemesterSettingsCompanion(
          firstHalfWeight: Value(first),
          secondHalfWeight: Value(second),
        ),
      );
    }
  }

  Future<List<SemesterSetting>> getAll() => select(semesterSettings).get();

  Future<void> deleteForSubject(int subjectId) async {
    await (delete(semesterSettings)
          ..where((t) => t.subjectId.equals(subjectId)))
        .go();
  }
}
