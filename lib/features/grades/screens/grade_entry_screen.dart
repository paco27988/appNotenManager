import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../grades/grades_provider.dart';
import '../../categories/categories_provider.dart';
import '../../students/students_provider.dart';
import '../../subjects/subjects_provider.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/grade_calculator.dart';

class GradeEntryScreen extends ConsumerStatefulWidget {
  final int studentId;
  final int subjectId;
  final int? classId;

  const GradeEntryScreen({
    super.key,
    required this.studentId,
    required this.subjectId,
    this.classId,
  });

  @override
  ConsumerState<GradeEntryScreen> createState() => _GradeEntryScreenState();
}

class _GradeEntryScreenState extends ConsumerState<GradeEntryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentSemester = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentSemester = _tabController.index + 1);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentAsync = ref.watch(studentByIdProvider(widget.studentId));
    final subjectAsync =
        ref.watch(subjectsStreamProvider).whenData<Subject?>((subs) {
      try {
        return subs.firstWhere((s) => s.id == widget.subjectId);
      } catch (_) {
        return null;
      }
    });

    final key = StudentSubjectKey(widget.studentId, widget.subjectId);
    final gradesAsync = ref.watch(gradesByStudentSubjectProvider(key));
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    final studentName = studentAsync.valueOrNull != null
        ? '${studentAsync.value!.firstName} ${studentAsync.value!.lastName}'
        : 'Schüler';
    final subjectName = subjectAsync.valueOrNull?.name ?? 'Fach';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subjectName),
            Text(
              studentName,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Halbjahr 1'),
            Tab(text: 'Halbjahr 2'),
          ],
        ),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (categories) => gradesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Fehler: $e')),
          data: (allGrades) => TabBarView(
            controller: _tabController,
            children: [1, 2].map((semester) {
              final semGrades =
                  allGrades.where((g) => g.semester == semester).toList();
              final avg = GradeCalculator.calculateSemesterGrade(
                allGrades,
                categories,
                semester,
              );
              return _SemesterGradeView(
                studentId: widget.studentId,
                subjectId: widget.subjectId,
                semester: semester,
                grades: semGrades,
                categories: categories,
                semesterAverage: avg,
              );
            }).toList(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGradeDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Note hinzufügen'),
      ),
    );
  }

  void _showAddGradeDialog(BuildContext context) {
    final categoriesAsync = ref.read(categoriesStreamProvider);
    final categories = categoriesAsync.valueOrNull ?? [];
    showDialog(
      context: context,
      builder: (_) => _GradeDialog(
        studentId: widget.studentId,
        subjectId: widget.subjectId,
        initialSemester: _currentSemester,
        categories: categories,
      ),
    );
  }
}

class _SemesterGradeView extends ConsumerWidget {
  final int studentId;
  final int subjectId;
  final int semester;
  final List<Grade> grades;
  final List<GradeCategory> categories;
  final double? semesterAverage;

  const _SemesterGradeView({
    required this.studentId,
    required this.subjectId,
    required this.semester,
    required this.grades,
    required this.categories,
    required this.semesterAverage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<int, List<Grade>> byCat = {};
    for (final g in grades) {
      byCat.putIfAbsent(g.categoryId, () => []).add(g);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Summary card
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halbjahres-Durchschnitt',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer
                                  .withOpacity(0.7),
                            ),
                      ),
                      Text(
                        'Halbjahr $semester',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  GradeCalculator.formatGradeDetail(semesterAverage),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Grades by category
        ...categories.map((cat) {
          final catGrades = byCat[cat.id] ?? [];
          final catAvg = catGrades.isEmpty
              ? null
              : catGrades.map((g) => g.value).reduce((a, b) => a + b) /
                  catGrades.length;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _CategorySection(
              category: cat,
              grades: catGrades,
              categoryAverage: catAvg,
              studentId: studentId,
              subjectId: subjectId,
              semester: semester,
            ),
          );
        }),
      ],
    );
  }
}

class _CategorySection extends ConsumerWidget {
  final GradeCategory category;
  final List<Grade> grades;
  final double? categoryAverage;
  final int studentId;
  final int subjectId;
  final int semester;

  const _CategorySection({
    required this.category,
    required this.grades,
    required this.categoryAverage,
    required this.studentId,
    required this.subjectId,
    required this.semester,
  });

  Color _hexColor(String hex) {
    try {
      return Color(
        int.parse(hex.replaceFirst('#', ''), radix: 16) | 0xFF000000,
      );
    } catch (_) {
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _hexColor(category.colorHex);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(Icons.label, color: color, size: 20),
        ),
        title: Text(category.name),
        subtitle: Text(
          '${category.weightPercent.toStringAsFixed(0)}% Gewichtung'
          '${categoryAverage != null ? " · Ø ${GradeCalculator.formatGradeDetail(categoryAverage)}" : ""}',
        ),
        children: [
          ...grades.map(
            (g) => _GradeTile(
              grade: g,
              studentId: studentId,
              subjectId: subjectId,
            ),
          ),
          if (grades.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Keine Noten in dieser Kategorie',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5),
                        ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _GradeTile extends ConsumerWidget {
  final Grade grade;
  final int studentId;
  final int subjectId;

  const _GradeTile({
    required this.grade,
    required this.studentId,
    required this.subjectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _gradeColor(grade.value, context),
        child: Text(
          grade.value.toStringAsFixed(1),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
      title: Text(
        '${grade.date.day.toString().padLeft(2, '0')}.${grade.date.month.toString().padLeft(2, '0')}.${grade.date.year}',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      subtitle: grade.comment.isNotEmpty
          ? Text(
              grade.comment,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.6),
                  ),
            )
          : null,
      trailing: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, color: cs.onSurface.withOpacity(0.6), size: 20),
        onSelected: (v) {
          if (v == 'edit') _showEditDialog(context, ref);
          if (v == 'delete') _confirmDelete(context, ref);
        },
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: 'edit',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.edit_outlined),
              title: Text('Bearbeiten'),
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error),
              title: Text('Löschen',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error)),
            ),
          ),
        ],
      ),
    );
  }

  Color _gradeColor(double grade, BuildContext context) {
    if (grade <= 2.0) return Colors.green;
    if (grade <= 3.5) return Colors.orange;
    return Colors.red;
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final cats = ref.read(categoriesStreamProvider).valueOrNull ?? [];
    showDialog(
      context: context,
      builder: (_) => _GradeDialog(
        studentId: studentId,
        subjectId: subjectId,
        initialSemester: grade.semester,
        categories: cats,
        existingGrade: grade,
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Note löschen'),
        content: Text(
      'Note ${grade.value.toStringAsFixed(1)} '
      '(${grade.date.day.toString().padLeft(2, '0')}.${grade.date.month.toString().padLeft(2, '0')}.${grade.date.year}) löschen?',
    ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(gradesNotifierProvider.notifier)
                  .deleteGrade(grade.id, studentId, subjectId);
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}

class _GradeDialog extends ConsumerStatefulWidget {
  final int studentId;
  final int subjectId;
  final int initialSemester;
  final List<GradeCategory> categories;
  final Grade? existingGrade;

  const _GradeDialog({
    required this.studentId,
    required this.subjectId,
    required this.initialSemester,
    required this.categories,
    this.existingGrade,
  });

  @override
  ConsumerState<_GradeDialog> createState() => _GradeDialogState();
}

class _GradeDialogState extends ConsumerState<_GradeDialog> {
  late double _value;
  late int _semester;
  late int? _categoryId;
  late DateTime _date;
  late TextEditingController _commentCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _value = widget.existingGrade?.value ?? 3.0;
    _semester = widget.existingGrade?.semester ?? widget.initialSemester;
    _categoryId = widget.existingGrade?.categoryId ??
        (widget.categories.isNotEmpty ? widget.categories.first.id : null);
    _date = widget.existingGrade?.date ?? DateTime.now();
    _commentCtrl =
        TextEditingController(text: widget.existingGrade?.comment ?? '');
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingGrade != null;
    return AlertDialog(
      title: Text(isEdit ? 'Note bearbeiten' : 'Note hinzufügen'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grade value slider
            Text('Note: ${_value.toStringAsFixed(1)}',
                style: Theme.of(context).textTheme.titleMedium),
            Slider(
              value: _value,
              min: 1.0,
              max: 6.0,
              divisions: 10,
              label: _value.toStringAsFixed(1),
              onChanged: (v) => setState(() => _value = v),
            ),
            const SizedBox(height: 8),
            // Quick grade buttons
            Wrap(
              spacing: 6,
              children: [1.0, 2.0, 3.0, 4.0, 5.0, 6.0].map((v) {
                return ChoiceChip(
                  label: Text(v.toStringAsFixed(0)),
                  selected: _value == v,
                  onSelected: (_) => setState(() => _value = v),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // Category
            if (widget.categories.isNotEmpty) ...[
              Text('Kategorie', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              DropdownButtonFormField<int>(
                value: _categoryId,
                items: widget.categories
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child:
                            Text('${c.name} (${c.weightPercent.toStringAsFixed(0)}%)'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _categoryId = v),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
            ],
            // Semester
            Text('Halbjahr', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('HJ 1')),
                ButtonSegment(value: 2, label: Text('HJ 2')),
              ],
              selected: {_semester},
              onSelectionChanged: (s) => setState(() => _semester = s.first),
            ),
            const SizedBox(height: 12),
            // Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Datum: ${_date.day.toString().padLeft(2, '0')}.${_date.month.toString().padLeft(2, '0')}.${_date.year}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            // Comment
            TextField(
              controller: _commentCtrl,
              decoration: const InputDecoration(
                labelText: 'Kommentar (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _loading || _categoryId == null
              ? null
              : () async {
                  setState(() => _loading = true);
                  try {
                    final notifier = ref.read(gradesNotifierProvider.notifier);
                    if (isEdit) {
                      await notifier.updateGrade(
                        widget.existingGrade!.id,
                        studentId: widget.studentId,
                        subjectId: widget.subjectId,
                        categoryId: _categoryId!,
                        value: _value,
                        semester: _semester,
                        date: _date,
                        comment: _commentCtrl.text.trim(),
                      );
                    } else {
                      await notifier.addGrade(
                        studentId: widget.studentId,
                        subjectId: widget.subjectId,
                        categoryId: _categoryId!,
                        value: _value,
                        semester: _semester,
                        date: _date,
                        comment: _commentCtrl.text.trim(),
                      );
                    }
                    if (context.mounted) Navigator.pop(context);
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Fehler: Konnte nicht gespeichert werden')),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
          child: Text(isEdit ? 'Speichern' : 'Hinzufügen'),
        ),
      ],
    );
  }
}
