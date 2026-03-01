import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../students/students_provider.dart';
import '../../classes/classes_provider.dart';
import '../../grades/grades_provider.dart';
import '../../categories/categories_provider.dart';
import '../../settings/settings_provider.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/grade_calculator.dart';

class StudentDetailScreen extends ConsumerWidget {
  final int studentId;
  final int classId;

  const StudentDetailScreen({
    super.key,
    required this.studentId,
    required this.classId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentByIdProvider(studentId));
    final subjectsAsync = ref.watch(classSubjectsProvider(classId));

    return studentAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => const Scaffold(
          body: Center(child: Text('Ein Fehler ist aufgetreten'))),
      data: (student) {
        if (student == null) {
          return const Scaffold(
              body: Center(child: Text('Schüler nicht gefunden')));
        }
        return Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${student.firstName} ${student.lastName}'),
              const Text(
                'Notenübersicht',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
            ],
          ),
        ),
        body: subjectsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Fehler: $e')),
          data: (subjects) {
            if (subjects.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceVariant,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.menu_book_outlined,
                          size: 36,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 20),
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
                        'Weise der Klasse zuerst Fächer zu.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Fächer zuweisen'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: subjects.length,
              itemBuilder: (ctx, i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SubjectGradeTile(
                  student: student,
                  subject: subjects[i],
                  classId: classId,
                ),
              ),
            );
          },
        ),
      );
      },
    );
  }
}

class _SubjectGradeTile extends ConsumerWidget {
  final Student student;
  final Subject subject;
  final int classId;

  const _SubjectGradeTile({
    required this.student,
    required this.subject,
    required this.classId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = StudentSubjectKey(student.id, subject.id);
    final gradesAsync = ref.watch(gradesByStudentSubjectProvider(key));
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final globalSettingAsync = ref.watch(globalSemesterSettingProvider);
    final subjectSettingAsync =
        ref.watch(subjectSemesterSettingProvider(subject.id));

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(
          '/class/$classId/student/${student.id}/grades/${subject.id}',
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.book,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    subject.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 12),
              gradesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Fehler: $e'),
                data: (grades) => categoriesAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => Text('Fehler: $e'),
                  data: (categories) {
                    final subjectSetting = subjectSettingAsync.valueOrNull;
                    final globalSetting = globalSettingAsync.valueOrNull;
                    final w1 = subjectSetting?.firstHalfWeight ??
                        globalSetting?.firstHalfWeight ??
                        50.0;
                    final w2 = subjectSetting?.secondHalfWeight ??
                        globalSetting?.secondHalfWeight ??
                        50.0;

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
                    final yearly = GradeCalculator.calculateYearlyGrade(
                      hj1,
                      hj2,
                      w1,
                      w2,
                    );

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _GradeChip(
                          label: 'HJ 1',
                          grade: GradeCalculator.formatGradeDetail(hj1),
                        ),
                        _GradeChip(
                          label: 'HJ 2',
                          grade: GradeCalculator.formatGradeDetail(hj2),
                        ),
                        _GradeChip(
                          label: 'Jahres',
                          grade: GradeCalculator.formatGradeDetail(yearly),
                          highlight: true,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeChip extends StatelessWidget {
  final String label;
  final String grade;
  final bool highlight;

  const _GradeChip({
    required this.label,
    required this.grade,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: highlight
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            grade,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: highlight
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : null,
                ),
          ),
        ),
      ],
    );
  }
}
