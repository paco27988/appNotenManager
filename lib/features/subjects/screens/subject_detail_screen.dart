import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../categories/categories_provider.dart';
import '../../subjects/subjects_provider.dart';
import '../../subjects/subject_category_overrides_provider.dart';
import '../../../core/database/app_database.dart';

class SubjectDetailScreen extends ConsumerWidget {
  final int subjectId;
  const SubjectDetailScreen({super.key, required this.subjectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsStreamProvider);
    final subject = subjectsAsync.valueOrNull
        ?.where((s) => s.id == subjectId)
        .firstOrNull;

    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final overridesAsync =
        ref.watch(subjectCategoryOverridesProvider(subjectId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Fach: ${subject?.name ?? '…'}'),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            const Center(child: Text('Ein Fehler ist aufgetreten')),
        data: (categories) => overridesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) =>
              const Center(child: Text('Ein Fehler ist aufgetreten')),
          data: (overrides) => _SubjectCategoryBody(
            subjectId: subjectId,
            categories: categories,
            overrides: overrides,
          ),
        ),
      ),
    );
  }
}

class _SubjectCategoryBody extends ConsumerWidget {
  final int subjectId;
  final List<GradeCategory> categories;
  final List<SubjectCategoryOverride> overrides;

  // Cannot be const because of late final _overrideMap field.
  // ignore: prefer_const_constructors_in_immutables
  _SubjectCategoryBody({
    required this.subjectId,
    required this.categories,
    required this.overrides,
  });

  late final _overrideMap = {for (final o in overrides) o.categoryId: o};

  SubjectCategoryOverride? _overrideFor(int categoryId) => _overrideMap[categoryId];

  bool _isActive(int categoryId) =>
      _overrideFor(categoryId)?.isActive ?? true;

  double _weight(GradeCategory cat) =>
      _overrideFor(cat.id)?.weightOverride ?? cat.weightPercent;

  double _totalActiveWeight() {
    double total = 0;
    for (final cat in categories) {
      if (_isActive(cat.id)) total += _weight(cat);
    }
    return total;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier =
        ref.read(subjectCategoryOverridesNotifierProvider(subjectId).notifier);

    final activeCount = categories.where((c) => _isActive(c.id)).length;
    final totalWeight = _totalActiveWeight();
    final weightOk = (totalWeight - 100.0).abs() < 0.5;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Weight sum banner
        Card(
          color: weightOk
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.errorContainer,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  weightOk ? Icons.check_circle : Icons.warning_amber,
                  color: weightOk
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  weightOk
                      ? 'Aktive Gewichtung: ${totalWeight.toStringAsFixed(0)}% ✓'
                      : 'Aktive Gewichtung: ${totalWeight.toStringAsFixed(0)}% (≠ 100%)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: weightOk
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                const Spacer(),
                Text(
                  '$activeCount von ${categories.length} aktiv',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Category cards
        ...categories.map((cat) {
          final active = _isActive(cat.id);
          final weight = _weight(cat);
          return _CategoryOverrideTile(
            category: cat,
            isActive: active,
            weightValue: weight,
            onToggle: (val) => notifier.upsert(cat.id, val, weight),
            onWeightChanged: (val) => notifier.upsert(cat.id, active, val),
          );
        }),

        const SizedBox(height: 8),

        // Reset button – only visible when overrides exist
        if (overrides.isNotEmpty)
          OutlinedButton.icon(
            onPressed: () => notifier.resetForSubject(),
            icon: const Icon(Icons.restore),
            label: const Text('Auf Global zurücksetzen'),
          ),
      ],
    );
  }
}

class _CategoryOverrideTile extends StatefulWidget {
  final GradeCategory category;
  final bool isActive;
  final double weightValue;
  final void Function(bool) onToggle;
  final void Function(double) onWeightChanged;

  const _CategoryOverrideTile({
    required this.category,
    required this.isActive,
    required this.weightValue,
    required this.onToggle,
    required this.onWeightChanged,
  });

  @override
  State<_CategoryOverrideTile> createState() => _CategoryOverrideTileState();
}

class _CategoryOverrideTileState extends State<_CategoryOverrideTile> {
  late double _sliderValue;

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.weightValue.clamp(1.0, 100.0);
  }

  @override
  void didUpdateWidget(_CategoryOverrideTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weightValue != widget.weightValue) {
      _sliderValue = widget.weightValue.clamp(1.0, 100.0);
    }
  }

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
  Widget build(BuildContext context) {
    final color = _hexColor(widget.category.colorHex);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: color.withOpacity(0.2),
                  child: Icon(Icons.label, color: color, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.category.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_sliderValue.toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  label: '${widget.category.name} ${widget.isActive ? "aktiv" : "inaktiv"}',
                  child: Switch(
                    value: widget.isActive,
                    onChanged: widget.onToggle,
                  ),
                ),
              ],
            ),
            if (widget.isActive) ...[
              Slider(
                value: _sliderValue,
                min: 1,
                max: 100,
                divisions: 99,
                label: '${_sliderValue.toStringAsFixed(0)}%',
                onChanged: (v) => setState(() => _sliderValue = v),
                onChangeEnd: widget.onWeightChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
