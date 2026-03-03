import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../grades/grades_provider.dart';
import '../../subjects/subject_category_overrides_provider.dart';
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
    final categoriesAsync =
        ref.watch(effectiveCategoriesProvider(widget.subjectId));

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
        error: (e, _) => const Center(child: Text('Ein Fehler ist aufgetreten')),
        data: (categories) => gradesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => const Center(child: Text('Ein Fehler ist aufgetreten')),
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
    final categoriesAsync = ref.read(effectiveCategoriesProvider(widget.subjectId));
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
          final catAvg = GradeCalculator.categoryAverage(catGrades);
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
    final hasWeightedGrades = grades.any((g) => g.factor != 1.0);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        initiallyExpanded: hasWeightedGrades,
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(Icons.label, color: color, size: 20),
        ),
        title: Text(category.name),
        subtitle: Text(
          '${category.weightPercent.toStringAsFixed(0)}% Gewichtung'
          '${categoryAverage != null ? " · gew. Ø ${GradeCalculator.formatGradeDetail(categoryAverage)}" : ""}',
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
          GradeCalculator.formatGradeEntry(grade.value),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      title: Text(
        '${grade.date.day.toString().padLeft(2, '0')}.${grade.date.month.toString().padLeft(2, '0')}.${grade.date.year}',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      subtitle: _buildSubtitle(context, cs),
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

  String _factorLabel(double f) {
    if (f == 0.5) return '×0,5 (halb)';
    if (f == 1.0) return '×1 (normal)';
    if (f == 1.5) return '×1,5';
    if (f == 2.0) return '×2 (doppelt)';
    if (f == 3.0) return '×3 (dreifach)';
    return '×${f % 1 == 0 ? f.toStringAsFixed(0) : f.toStringAsFixed(1).replaceAll('.', ',')}';
  }

  Widget? _buildSubtitle(BuildContext context, ColorScheme cs) {
    final isWeighted = grade.factor != 1.0;
    final factorWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: isWeighted
            ? cs.tertiaryContainer
            : cs.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _factorLabel(grade.factor),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isWeighted
                  ? cs.onTertiaryContainer
                  : cs.onSurface.withOpacity(0.35),
              fontWeight: isWeighted ? FontWeight.bold : FontWeight.normal,
            ),
      ),
    );

    if (grade.comment.isEmpty) return factorWidget;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        factorWidget,
        const SizedBox(height: 2),
        Text(
          grade.comment,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: cs.onSurface.withOpacity(0.6)),
        ),
      ],
    );
  }

  Color _gradeColor(double grade, BuildContext context) {
    if (grade <= 2.33) return const Color(0xFF2E7D32); // green[800]   1+ – 2-
    if (grade <= 4.33) return const Color(0xFFE65100); // orange[900]  3+ – 4-
    return const Color(0xFFC62828);                    // red[900]     5+ – 6
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final cats =
        ref.read(effectiveCategoriesProvider(subjectId)).valueOrNull ?? [];
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
      'Note ${GradeCalculator.formatGradeEntry(grade.value)} '
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
  late double _factor;
  late int _semester;
  late int? _categoryId;
  late DateTime _date;
  late TextEditingController _commentCtrl;
  bool _loading = false;

  static const _commonFactors = [0.5, 1.0, 1.5, 2.0, 3.0];

  @override
  void initState() {
    super.initState();
    _value = widget.existingGrade?.value ?? 3.0;
    _factor = widget.existingGrade?.factor ?? 1.0;
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
    final noteColor = _gradeColorForValue(_value);
    return AlertDialog(
      title: Text(isEdit ? 'Note bearbeiten' : 'Note hinzufügen'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Notenauswahl ──────────────────────────────────────
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: noteColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  GradeCalculator.formatGradeEntry(_value),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: noteColor,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildGradeChips(context),
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 8),
            // ── 2. Kategorie ─────────────────────────────────────────
            if (widget.categories.isNotEmpty) ...[
              Text('Kategorie',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              DropdownButtonFormField<int>(
                value: _categoryId,
                items: widget.categories
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(
                            '${c.name} (${c.weightPercent.toStringAsFixed(0)}%)'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _categoryId = v),
                decoration:
                    const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
            ],
            // ── 3. Halbjahr ──────────────────────────────────────────
            Text('Halbjahr', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('HJ 1')),
                ButtonSegment(value: 2, label: Text('HJ 2')),
              ],
              selected: {_semester},
              onSelectionChanged: (s) =>
                  setState(() => _semester = s.first),
            ),
            const SizedBox(height: 12),
            // ── 4. Datum ─────────────────────────────────────────────
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
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const Divider(),
            const SizedBox(height: 6),
            // ── 5. Gewichtungsfaktor (erweitert) ─────────────────────
            Row(
              children: [
                Text('Gewichtung dieser Note',
                    style: Theme.of(context).textTheme.labelLarge),
                Tooltip(
                  message:
                      'Bestimmt, wie stark diese Note innerhalb der\n'
                      'Kategorie zählt. ×2 = zählt doppelt, ×0,5 = zählt halb.',
                  triggerMode: TooltipTriggerMode.tap,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(Icons.info_outline,
                        size: 16,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.45)),
                  ),
                ),
              ],
            ),
            Text(
              'Zählt diese Note stärker oder schwächer?',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.55),
                  ),
            ),
            const SizedBox(height: 6),
            Theme(
              data: Theme.of(context).copyWith(
                chipTheme: Theme.of(context).chipTheme.copyWith(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                    ),
              ),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _commonFactors.map((f) {
                  final label = switch (f) {
                    0.5 => '×0,5 · halb',
                    1.0 => '×1 · normal',
                    1.5 => '×1,5',
                    2.0 => '×2 · doppelt',
                    3.0 => '×3 · dreifach',
                    _ => '×${f.toStringAsFixed(1).replaceAll('.', ',')}',
                  };
                  return ChoiceChip(
                    label: Text(label),
                    selected: _factor == f,
                    onSelected: (_) => setState(() => _factor = f),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            // ── 6. Kommentar ─────────────────────────────────────────
            TextField(
              controller: _commentCtrl,
              decoration: const InputDecoration(
                labelText: 'Kommentar (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              maxLength: 500,
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
                    final notifier =
                        ref.read(gradesNotifierProvider.notifier);
                    if (isEdit) {
                      await notifier.updateGrade(
                        widget.existingGrade!.id,
                        studentId: widget.studentId,
                        subjectId: widget.subjectId,
                        categoryId: _categoryId!,
                        value: _value,
                        factor: _factor,
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
                        factor: _factor,
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

  /// Grouped grade chip grid: one row per grade family (1+/1/1-, 2+/2/2-, …)
  Widget _buildGradeChips(BuildContext context) {
    const steps = GradeCalculator.gradeSteps;
    final rows = <List<(double, String)>>[];
    for (var i = 0; i < steps.length; i += 3) {
      rows.add(steps.sublist(i, (i + 3).clamp(0, steps.length)));
    }
    return Column(
      children: rows.asMap().entries.map((entry) {
        final row = entry.value;
        return Padding(
          padding: EdgeInsets.only(top: entry.key == 0 ? 0 : 3),
          child: Row(
            children: [
              ...row.map((step) {
                final (value, label) = step;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: ChoiceChip(
                      label: Center(
                        child: Text(label,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                      selected: (_value - value).abs() < 0.02,
                      onSelected: (_) => setState(() => _value = value),
                    ),
                  ),
                );
              }),
              // Pad last row (grade "6") with empty slots for alignment
              if (row.length < 3)
                ...List.generate(
                  3 - row.length,
                  (_) => const Expanded(child: SizedBox()),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// WCAG AA-compliant color for a grade value (white text, min 4.5:1 contrast).
  Color _gradeColorForValue(double value) {
    if (value <= 2.33) return const Color(0xFF2E7D32); // green[800]
    if (value <= 4.33) return const Color(0xFFE65100); // deepOrange[900]
    return const Color(0xFFC62828); // red[900]
  }
}
