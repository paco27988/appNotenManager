import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../classes/classes_provider.dart';
import '../../students/students_provider.dart';
import '../../grades/grades_provider.dart';
import '../../subjects/subject_category_overrides_provider.dart';
import '../../settings/settings_provider.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/grade_calculator.dart';

class ReportScreen extends ConsumerStatefulWidget {
  final int classId;
  const ReportScreen({super.key, required this.classId});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  // 0 = HJ1, 1 = HJ2, 2 = Gesamtjahr
  int _mode = 2;

  void _shareReport(
    BuildContext context,
    List<Student> students,
    List<Subject> subjects,
    Map<int, List<Grade>> gradesByStudent,
    Map<int, List<GradeCategory>> categoriesBySubject,
    Map<int, SemesterSetting?> subjectSettings,
    SemesterSetting? globalSetting,
  ) {
    final buf = StringBuffer();
    final modeName = _mode == 0 ? 'Halbjahr 1' : _mode == 1 ? 'Halbjahr 2' : 'Gesamtjahr';
    buf.writeln('Zeugnis – $modeName');
    buf.writeln('');

    // Header row
    buf.write('Schüler'.padRight(25));
    for (final s in subjects) {
      buf.write(s.name.padRight(12));
    }
    buf.writeln();
    buf.writeln('-' * (25 + subjects.length * 12));

    for (final student in students) {
      buf.write('${student.lastName}, ${student.firstName}'.padRight(25));
      final grades = gradesByStudent[student.id] ?? [];
      for (final subject in subjects) {
        final cats = categoriesBySubject[subject.id] ?? [];
        final subjectSetting = subjectSettings[subject.id];
        final w1 = subjectSetting?.firstHalfWeight ?? globalSetting?.firstHalfWeight ?? 50.0;
        final w2 = subjectSetting?.secondHalfWeight ?? globalSetting?.secondHalfWeight ?? 50.0;
        final subjectGrades = grades.where((g) => g.subjectId == subject.id).toList();

        double? grade;
        if (_mode == 0) {
          grade = GradeCalculator.calculateSemesterGrade(subjectGrades, cats, 1);
        } else if (_mode == 1) {
          grade = GradeCalculator.calculateSemesterGrade(subjectGrades, cats, 2);
        } else {
          final hj1 = GradeCalculator.calculateSemesterGrade(subjectGrades, cats, 1);
          final hj2 = GradeCalculator.calculateSemesterGrade(subjectGrades, cats, 2);
          grade = GradeCalculator.calculateYearlyGrade(hj1, hj2, w1, w2);
        }

        final display = _mode == 2
            ? GradeCalculator.formatGradeReport(grade)
            : GradeCalculator.formatGradeDetail(grade);
        buf.write(display.padRight(12));
      }
      buf.writeln();
    }

    final text = buf.toString();
    Share.share(text, subject: 'Zeugnis – $modeName');
  }

  @override
  Widget build(BuildContext context) {
    final classAsync = ref.watch(classByIdProvider(widget.classId));
    final studentsAsync = ref.watch(studentsByClassProvider(widget.classId));
    final subjectsAsync = ref.watch(classSubjectsProvider(widget.classId));

    return Scaffold(
      appBar: AppBar(
        title: classAsync.maybeWhen(
          data: (c) => Text('Zeugnis: ${c?.name ?? ''}'),
          orElse: () => const Text('Zeugnis'),
        ),
        actions: [
          studentsAsync.maybeWhen(
            data: (students) => subjectsAsync.maybeWhen(
              data: (subjects) => _ShareButton(
                classId: widget.classId,
                mode: _mode,
                students: students,
                subjects: subjects,
                onShare: _shareReport,
              ),
              orElse: () => const SizedBox.shrink(),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Mode selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('HJ 1')),
                ButtonSegment(value: 1, label: Text('HJ 2')),
                ButtonSegment(value: 2, label: Text('Gesamtjahr')),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
          ),
          Expanded(
            child: studentsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => const Center(child: Text('Ein Fehler ist aufgetreten')),
              data: (students) => subjectsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => const Center(child: Text('Ein Fehler ist aufgetreten')),
                data: (subjects) {
                  if (students.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 48,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Keine Schüler in dieser Klasse',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final sorted = [...students]..sort(
                      (a, b) => '${a.lastName} ${a.firstName}'
                          .compareTo('${b.lastName} ${b.firstName}'),
                    );
                  return _ReportTable(
                    students: sorted,
                    subjects: subjects,
                    mode: _mode,
                    classId: widget.classId,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Share button that gathers all needed data from providers.
class _ShareButton extends ConsumerWidget {
  final int classId;
  final int mode;
  final List<Student> students;
  final List<Subject> subjects;
  final Function(
    BuildContext,
    List<Student>,
    List<Subject>,
    Map<int, List<Grade>>,
    Map<int, List<GradeCategory>>,
    Map<int, SemesterSetting?>,
    SemesterSetting?,
  ) onShare;

  const _ShareButton({
    required this.classId,
    required this.mode,
    required this.students,
    required this.subjects,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch all per-student grade streams
    final Map<int, List<Grade>> gradesByStudent = {};
    for (final student in students) {
      final gradesAsync = ref.watch(gradesByStudentProvider(student.id));
      gradesByStudent[student.id] = gradesAsync.valueOrNull ?? [];
    }

    // Watch per-subject category and setting providers
    final Map<int, List<GradeCategory>> categoriesBySubject = {};
    final Map<int, SemesterSetting?> subjectSettings = {};
    for (final subject in subjects) {
      categoriesBySubject[subject.id] =
          ref.watch(effectiveCategoriesProvider(subject.id)).valueOrNull ?? [];
      subjectSettings[subject.id] =
          ref.watch(subjectSemesterSettingProvider(subject.id)).valueOrNull;
    }
    final globalSetting = ref.watch(globalSemesterSettingProvider).valueOrNull;

    return IconButton(
      icon: const Icon(Icons.share),
      tooltip: 'Zeugnis teilen',
      onPressed: () => onShare(
        context,
        students,
        subjects,
        gradesByStudent,
        categoriesBySubject,
        subjectSettings,
        globalSetting,
      ),
    );
  }
}

class _ReportTable extends ConsumerWidget {
  final List<Student> students;
  final List<Subject> subjects;
  final int mode; // 0=HJ1, 1=HJ2, 2=Yearly
  final int classId;

  const _ReportTable({
    required this.students,
    required this.subjects,
    required this.mode,
    required this.classId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (subjects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.menu_book_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'Keine Fächer zugewiesen',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Weise der Klasse Fächer zu, um das Zeugnis zu sehen.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Watch per-subject providers once at table level — O(subjects) subscriptions
    final Map<int, List<GradeCategory>> categoriesBySubject = {};
    final Map<int, SemesterSetting?> subjectSettings = {};
    for (final subject in subjects) {
      categoriesBySubject[subject.id] =
          ref.watch(effectiveCategoriesProvider(subject.id)).valueOrNull ?? [];
      subjectSettings[subject.id] =
          ref.watch(subjectSemesterSettingProvider(subject.id)).valueOrNull;
    }
    final globalSetting = ref.watch(globalSemesterSettingProvider).valueOrNull;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(
            Theme.of(context).colorScheme.primaryContainer,
          ),
          columns: [
            const DataColumn(label: Text('Schüler')),
            ...subjects.map((s) => DataColumn(label: Text(s.name))),
          ],
          rows: students
              .map(
                (student) => DataRow(
                  cells: [
                    DataCell(
                      Text('${student.lastName}, ${student.firstName}'),
                    ),
                    ...subjects.map(
                      (subject) => DataCell(
                        _GradeCell(
                          studentId: student.id,
                          subjectId: subject.id,
                          mode: mode,
                          categories: categoriesBySubject[subject.id] ?? [],
                          subjectSetting: subjectSettings[subject.id],
                          globalSetting: globalSetting,
                        ),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _GradeCell extends ConsumerWidget {
  final int studentId;
  final int subjectId;
  final int mode;
  final List<GradeCategory> categories;
  final SemesterSetting? subjectSetting;
  final SemesterSetting? globalSetting;

  const _GradeCell({
    required this.studentId,
    required this.subjectId,
    required this.mode,
    required this.categories,
    required this.subjectSetting,
    required this.globalSetting,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // One subscription per student row — O(students) subscriptions
    final gradesAsync = ref.watch(gradesByStudentProvider(studentId));

    return gradesAsync.when(
      loading: () => const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 1),
      ),
      error: (e, _) => Tooltip(
        message: 'Fehler beim Laden',
        child: Icon(
          Icons.error_outline,
          size: 14,
          color: Theme.of(context).colorScheme.error,
        ),
      ),
      data: (allStudentGrades) {
        // Filter grades for this subject
        final grades = allStudentGrades
            .where((g) => g.subjectId == subjectId)
            .toList();

        final w1 = subjectSetting?.firstHalfWeight ??
            globalSetting?.firstHalfWeight ??
            50.0;
        final w2 = subjectSetting?.secondHalfWeight ??
            globalSetting?.secondHalfWeight ??
            50.0;

        double? grade;
        if (mode == 0) {
          grade = GradeCalculator.calculateSemesterGrade(
            grades,
            categories,
            1,
          );
        } else if (mode == 1) {
          grade = GradeCalculator.calculateSemesterGrade(
            grades,
            categories,
            2,
          );
        } else {
          final hj1 = GradeCalculator.calculateSemesterGrade(
            grades,
            categories,
            1,
          );
          final hj2 = GradeCalculator.calculateSemesterGrade(
            grades,
            categories,
            2,
          );
          grade = GradeCalculator.calculateYearlyGrade(hj1, hj2, w1, w2);
        }

        final display = mode == 2
            ? GradeCalculator.formatGradeReport(grade)
            : GradeCalculator.formatGradeDetail(grade);

        final gradeColor = _gradeColor(grade, context);
        // U12: Non-color indicator for failing grades (WCAG 1.4.1)
        final isFailing = grade != null && grade >= 4.67;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isFailing
                ? Theme.of(context).colorScheme.errorContainer.withOpacity(0.3)
                : gradeColor?.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            display,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: gradeColor,
            ),
          ),
        );
      },
    );
  }

  Color? _gradeColor(double? grade, BuildContext context) {
    if (grade == null) return Theme.of(context).colorScheme.onSurface.withOpacity(0.4);
    if (grade <= 2.33) return const Color(0xFF2E7D32); // green[800] – 1+ through 2-
    if (grade <= 4.33) return const Color(0xFFE65100); // deepOrange[900] – 3+ through 4-
    return Theme.of(context).colorScheme.error;
  }
}
