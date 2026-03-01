import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../database_provider.dart';

class StudentSubjectKey {
  final int studentId;
  final int subjectId;
  const StudentSubjectKey(this.studentId, this.subjectId);

  @override
  bool operator ==(Object other) =>
      other is StudentSubjectKey &&
      other.studentId == studentId &&
      other.subjectId == subjectId;

  @override
  int get hashCode => Object.hash(studentId, subjectId);
}

final gradesByStudentSubjectProvider =
    StreamProvider.family<List<Grade>, StudentSubjectKey>((ref, key) {
  final db = ref.watch(databaseProvider);
  return db.gradesDao.watchByStudentSubject(key.studentId, key.subjectId);
});

final gradesNotifierProvider =
    AsyncNotifierProvider<GradesNotifier, void>(GradesNotifier.new);

class GradesNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  AppDatabase get _db => ref.read(databaseProvider);

  Future<void> addGrade({
    required int studentId,
    required int subjectId,
    required int categoryId,
    required double value,
    required int semester,
    required DateTime date,
    String comment = '',
  }) async {
    final safeValue = value.clamp(1.0, 6.0);
    final safeSemester = semester.clamp(1, 2);
    await _db.gradesDao.create(
      GradesCompanion.insert(
        studentId: studentId,
        subjectId: subjectId,
        categoryId: categoryId,
        value: safeValue,
        semester: safeSemester,
        date: date,
        comment: Value(comment),
      ),
    );
    ref.invalidate(
      gradesByStudentSubjectProvider(
        StudentSubjectKey(studentId, subjectId),
      ),
    );
  }

  Future<void> updateGrade(
    int id, {
    required int studentId,
    required int subjectId,
    required int categoryId,
    required double value,
    required int semester,
    required DateTime date,
    String comment = '',
  }) async {
    final safeValue = value.clamp(1.0, 6.0);
    final safeSemester = semester.clamp(1, 2);
    await _db.gradesDao.update_(
      GradesCompanion(
        id: Value(id),
        studentId: Value(studentId),
        subjectId: Value(subjectId),
        categoryId: Value(categoryId),
        value: Value(safeValue),
        semester: Value(safeSemester),
        date: Value(date),
        comment: Value(comment),
      ),
    );
    ref.invalidate(
      gradesByStudentSubjectProvider(
        StudentSubjectKey(studentId, subjectId),
      ),
    );
  }

  Future<void> deleteGrade(int id, int studentId, int subjectId) async {
    await _db.gradesDao.deleteById(id);
    ref.invalidate(
      gradesByStudentSubjectProvider(
        StudentSubjectKey(studentId, subjectId),
      ),
    );
  }
}
