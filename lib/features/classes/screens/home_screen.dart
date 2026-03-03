import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../classes_provider.dart';
import '../../../core/database/app_database.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(classesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meine Klassen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            tooltip: 'Kategorien',
            onPressed: () => context.push('/categories'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Einstellungen',
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.backup),
            tooltip: 'Backup',
            onPressed: () => context.push('/backup'),
          ),
        ],
      ),
      body: classesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
          onRetry: () => ref.invalidate(classesStreamProvider),
        ),
        data: (classes) {
          if (classes.isEmpty) {
            return _EmptyClassesState();
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: classes.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ClassCard(cls: classes[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddClassDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Neue Klasse'),
      ),
    );
  }

  void _showAddClassDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _ClassDialog(
        onSave: (name, year) async {
          await ref
              .read(classesNotifierProvider.notifier)
              .addClass(name, year);
        },
      ),
    );
  }
}

class _EmptyClassesState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.school_outlined, size: 48, color: cs.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'Noch keine Klassen',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tippe auf "Neue Klasse", um deine erste Klasse anzulegen.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withOpacity(0.6),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback? onRetry;
  const _ErrorState({this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: cs.error),
            const SizedBox(height: 16),
            Text(
              'Ein Fehler ist aufgetreten',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: cs.error),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Erneut versuchen'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ClassCard extends ConsumerWidget {
  final SchoolClass cls;
  const _ClassCard({required this.cls});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/class/${cls.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: cs.primaryContainer,
                child: Text(
                  cls.name.isNotEmpty ? cls.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cls.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Schuljahr ${cls.schoolYear}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: cs.onSurface.withOpacity(0.6)),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditDialog(context, ref);
                  } else if (value == 'delete') {
                    _confirmDelete(context, ref);
                  }
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
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _ClassDialog(
        initialName: cls.name,
        initialYear: cls.schoolYear,
        onSave: (name, year) async {
          await ref
              .read(classesNotifierProvider.notifier)
              .updateClass(cls.id, name, year);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Klasse löschen'),
        content: Text(
          'Klasse "${cls.name}" und alle zugehörigen Schüler und Noten löschen?',
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
                  .read(classesNotifierProvider.notifier)
                  .deleteClass(cls.id);
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}

class _ClassDialog extends StatefulWidget {
  final String? initialName;
  final String? initialYear;
  final Future<void> Function(String name, String year) onSave;

  const _ClassDialog({
    this.initialName,
    this.initialYear,
    required this.onSave,
  });

  @override
  State<_ClassDialog> createState() => _ClassDialogState();
}

class _ClassDialogState extends State<_ClassDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _yearCtrl;
  bool _loading = false;
  String? _nameError;
  String? _yearError;

  static String _defaultSchoolYear() {
    final now = DateTime.now();
    final year = now.month >= 8 ? now.year : now.year - 1;
    return '$year/${(year + 1).toString().substring(2)}';
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
    _yearCtrl = TextEditingController(
        text: widget.initialYear ?? _defaultSchoolYear());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialName != null;
    return AlertDialog(
      title: Text(isEdit ? 'Klasse bearbeiten' : 'Neue Klasse'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: 'Klassenname',
              hintText: 'z.B. 9a',
              prefixIcon: const Icon(Icons.class_outlined),
              errorText: _nameError,
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.none,
            maxLength: 100,
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _yearCtrl,
            decoration: InputDecoration(
              labelText: 'Schuljahr',
              hintText: 'z.B. 2025/26',
              prefixIcon: const Icon(Icons.calendar_today_outlined),
              errorText: _yearError,
            ),
            maxLength: 20,
            onChanged: (_) {
              if (_yearError != null) setState(() => _yearError = null);
            },
          ),
        ],
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
                  final year = _yearCtrl.text.trim();
                  if (name.isEmpty || year.isEmpty) {
                    setState(() {
                      _nameError = name.isEmpty ? 'Pflichtfeld' : null;
                      _yearError = year.isEmpty ? 'Pflichtfeld' : null;
                    });
                    return;
                  }
                  setState(() => _loading = true);
                  try {
                    await widget.onSave(name, year);
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
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEdit ? 'Speichern' : 'Erstellen'),
        ),
      ],
    );
  }
}
