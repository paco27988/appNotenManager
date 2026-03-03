import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../categories_provider.dart';
import '../../../core/database/app_database.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notenkategorien'),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Ein Fehler ist aufgetreten')),
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.label_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Noch keine Kategorien',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tippe auf "+ Neue Kategorie", um zu beginnen.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final totalWeight =
              categories.fold(0.0, (sum, c) => sum + c.weightPercent);
          final isValid = (totalWeight - 100).abs() < 0.01;

          return Column(
            children: [
              // Weight summary banner (only when categories exist and weight is invalid)
              if (!isValid)
                Material(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.warning_amber_outlined,
                          size: 18,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Gesamtgewichtung: ${totalWeight.toStringAsFixed(1)}% – muss 100% ergeben',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Material(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Gesamtgewichtung: ${totalWeight.toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: categories.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _CategoryCard(category: categories[i]),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Neue Kategorie'),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _CategoryDialog(
        onSave: (name, weight, color, icon) async {
          await ref
              .read(categoriesNotifierProvider.notifier)
              .addCategory(name, weight, color, icon);
        },
      ),
    );
  }
}

class _CategoryCard extends ConsumerWidget {
  final GradeCategory category;
  const _CategoryCard({required this.category});

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
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withOpacity(0.2),
                  child: Icon(Icons.label_outline, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${category.weightPercent.toStringAsFixed(0)}% Gewichtung',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: cs.onSurface.withOpacity(0.6)),
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
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: category.weightPercent / 100.0,
                backgroundColor: color.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _CategoryDialog(
        initialName: category.name,
        initialWeight: category.weightPercent,
        initialColor: category.colorHex,
        initialIcon: category.icon,
        onSave: (name, weight, color, icon) async {
          await ref
              .read(categoriesNotifierProvider.notifier)
              .updateCategory(category.id, name, weight, color, icon);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Kategorie löschen'),
        content: Text(
          'Kategorie "${category.name}" und alle zugehörigen Noten löschen?',
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
                  .read(categoriesNotifierProvider.notifier)
                  .deleteCategory(category.id);
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  final String? initialName;
  final double? initialWeight;
  final String? initialColor;
  final String? initialIcon;
  final Future<void> Function(
    String name,
    double weight,
    String color,
    String icon,
  ) onSave;

  const _CategoryDialog({
    this.initialName,
    this.initialWeight,
    this.initialColor,
    this.initialIcon,
    required this.onSave,
  });

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _nameCtrl;
  late double _weight;
  late String _color;
  bool _loading = false;

  final List<(String label, String hex)> _colorOptions = [
    ('Grün', '#4CAF50'),
    ('Blau', '#2196F3'),
    ('Orange', '#FF9800'),
    ('Rot', '#F44336'),
    ('Lila', '#9C27B0'),
    ('Türkis', '#00BCD4'),
    ('Rosa', '#E91E63'),
    ('Grau', '#607D8B'),
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
    _weight = widget.initialWeight ?? 20.0;
    _color = widget.initialColor ?? '#2196F3';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialName != null;
    return AlertDialog(
      title: Text(isEdit ? 'Kategorie bearbeiten' : 'Neue Kategorie'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'z.B. Referate',
              ),
              autofocus: true,
              maxLength: 100,
            ),
            const SizedBox(height: 16),
            Text(
              'Gewichtung: ${_weight.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Slider(
              value: _weight,
              min: 1,
              max: 100,
              divisions: 99,
              label: '${_weight.toStringAsFixed(0)}%',
              onChanged: (v) => setState(() => _weight = v),
            ),
            const SizedBox(height: 12),
            Text('Farbe', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colorOptions.map((opt) {
                final color = Color(
                  int.parse(opt.$2.replaceFirst('#', ''), radix: 16) |
                      0xFF000000,
                );
                final isSelected = _color == opt.$2;
                return Tooltip(
                  message: opt.$1,
                  child: GestureDetector(
                    onTap: () => setState(() => _color = opt.$2),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: Theme.of(context).colorScheme.outline,
                                width: 3,
                              )
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.4),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  ),
                );
              }).toList(),
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
          onPressed: _loading
              ? null
              : () async {
                  final name = _nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  setState(() => _loading = true);
                  try {
                    await widget.onSave(name, _weight, _color, 'label');
                    if (context.mounted) Navigator.pop(context);
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Fehler: Konnte nicht gespeichert werden')),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
          child: Text(isEdit ? 'Speichern' : 'Erstellen'),
        ),
      ],
    );
  }
}
