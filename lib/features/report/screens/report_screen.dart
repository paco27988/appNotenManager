import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../classes/classes_provider.dart';
import '../../students/students_provider.dart';
import '../../grades/grades_provider.dart';
import '../../categories/categories_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final classAsync = ref.watch(classByIdProvider(widget.classId));
    final studentsAsync = ref.watch(studentsByClassProvider(widget.classId));
    final subjectsAsync = ref.watch(classSubjectsProvider(widget.classId));
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: classAsync.maybeWhen(
          data: (c) => Text('Zeugnis: ${c?.name ?? ''}'),
          orElse: () => const Text('Zeugnis'),
        ),
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
              error: (e, _) => Center(child: Text('Fehler: $e')),
              data: (students) => subjectsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Fehler: $e')),
                data: (subjects) => categoriesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Fehler: $e')),
                  data: (categories) {
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
                      categories: categories,
                      mode: _mode,
                      classId: widget.classId,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportTable extends ConsumerWidget {
  final List<Student> students;
  final List<Subject> subjects;
  final List<GradeCategory> categories;
  final int mode; // 0=HJ1, 1=HJ2, 2=Yearly
  final int classId;

  const _ReportTable({
    required this.students,
    required this.subjects,
    required this.categories,
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
                          categories: categories,
                          mode: mode,
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
  final List<GradeCategory> categories;
  final int mode;

  const _GradeCell({
    required this.studentId,
    required this.subjectId,
    required this.categories,
    required this.mode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = StudentSubjectKey(studentId, subjectId);
    final gradesAsync = ref.watch(gradesByStudentSubjectProvider(key));
    final globalSettingAsync = ref.watch(globalSemesterSettingProvider);
    final subjectSettingAsync =
        ref.watch(subjectSemesterSettingProvider(subjectId));

    return gradesAsync.when(
      loading: () => const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 1),
      ),
      error: (e, _) => const Text('!'),
      data: (grades) {
        final subjectSetting = subjectSettingAsync.valueOrNull;
        final globalSetting = globalSettingAsync.valueOrNull;
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
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: gradeColor?.withOpacity(0.12),
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
    if (grade <= 2.5) return const Color(0xFF2E7D32); // green[800] – sufficient contrast
    if (grade <= 4.0) return const Color(0xFFE65100); // deepOrange[900] – sufficient contrast
    return Theme.of(context).colorScheme.error;
  }
}
