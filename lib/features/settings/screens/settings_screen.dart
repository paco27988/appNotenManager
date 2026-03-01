import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../settings/settings_provider.dart';
import '../../subjects/subjects_provider.dart';
import '../../../core/database/app_database.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalSettingAsync = ref.watch(globalSemesterSettingProvider);
    final subjectsAsync = ref.watch(subjectsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // ── Globale Halbjahresgewichtung ──────────────────────────────────
          _SectionHeader(
            title: 'Globale Halbjahres-Gewichtung',
            subtitle: 'Gilt für alle Fächer ohne individuelle Einstellung',
          ),
          const SizedBox(height: 12),
          globalSettingAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Fehler: $e'),
            data: (setting) => _SemesterWeightEditor(
              firstHalf: setting?.firstHalfWeight ?? 50.0,
              secondHalf: setting?.secondHalfWeight ?? 50.0,
              onChanged: (w1, w2) async {
                await ref
                    .read(settingsNotifierProvider.notifier)
                    .updateGlobal(w1, w2);
              },
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 32),
          // ── Fach-spezifische Gewichtung ───────────────────────────────────
          _SectionHeader(
            title: 'Fach-individuelle Gewichtung',
            subtitle: 'Überschreibt die globale Einstellung für einzelne Fächer',
          ),
          const SizedBox(height: 12),
          subjectsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Fehler: $e'),
            data: (subjects) {
              if (subjects.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Noch keine Fächer vorhanden.',
                  ),
                );
              }
              return Column(
                children: subjects
                    .map((s) => _SubjectSettingTile(subject: s))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 8),
          const Divider(height: 32),
          // ── Fächer verwalten ──────────────────────────────────────────────
          _SectionHeader(
            title: 'Fächer verwalten',
          ),
          const SizedBox(height: 8),
          subjectsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Fehler: $e'),
            data: (subjects) => _SubjectsManager(subjects: subjects),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.6),
                ),
          ),
        ],
      ],
    );
  }
}

class _SemesterWeightEditor extends StatefulWidget {
  final double firstHalf;
  final double secondHalf;
  final Future<void> Function(double w1, double w2) onChanged;

  const _SemesterWeightEditor({
    required this.firstHalf,
    required this.secondHalf,
    required this.onChanged,
  });

  @override
  State<_SemesterWeightEditor> createState() => _SemesterWeightEditorState();
}

class _SemesterWeightEditorState extends State<_SemesterWeightEditor> {
  late double _w1;

  @override
  void initState() {
    super.initState();
    _w1 = widget.firstHalf;
  }

  @override
  Widget build(BuildContext context) {
    final w2 = 100.0 - _w1;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('HJ 1: ${_w1.toStringAsFixed(0)}%'),
                Text('HJ 2: ${w2.toStringAsFixed(0)}%'),
              ],
            ),
            Slider(
              value: _w1,
              min: 10,
              max: 90,
              divisions: 8,
              label: '${_w1.toStringAsFixed(0)} / ${w2.toStringAsFixed(0)}',
              onChanged: (v) => setState(() => _w1 = v),
              onChangeEnd: (v) async {
                await widget.onChanged(v, 100 - v);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Einstellung gespeichert'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectSettingTile extends ConsumerWidget {
  final Subject subject;
  const _SubjectSettingTile({required this.subject});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingAsync = ref.watch(subjectSemesterSettingProvider(subject.id));
    final globalAsync = ref.watch(globalSemesterSettingProvider);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        title: Text(subject.name),
        subtitle: settingAsync.when(
          loading: () => const Text('...'),
          error: (e, _) => Text('Fehler: $e'),
          data: (setting) {
            if (setting == null) {
              final g = globalAsync.valueOrNull;
              return Text(
                'Global: ${g?.firstHalfWeight.toStringAsFixed(0) ?? 50}% / ${g?.secondHalfWeight.toStringAsFixed(0) ?? 50}%',
                style: const TextStyle(fontStyle: FontStyle.italic),
              );
            }
            return Text(
              'Individuell: ${setting.firstHalfWeight.toStringAsFixed(0)}% / ${setting.secondHalfWeight.toStringAsFixed(0)}%',
            );
          },
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: settingAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Fehler: $e'),
              data: (setting) {
                final globalW1 =
                    globalAsync.valueOrNull?.firstHalfWeight ?? 50.0;
                return Column(
                  children: [
                    _SemesterWeightEditor(
                      firstHalf: setting?.firstHalfWeight ?? globalW1,
                      secondHalf:
                          setting?.secondHalfWeight ?? (100 - globalW1),
                      onChanged: (w1, w2) async {
                        await ref
                            .read(settingsNotifierProvider.notifier)
                            .updateForSubject(subject.id, w1, w2);
                      },
                    ),
                    if (setting != null)
                      TextButton.icon(
                        onPressed: () async {
                          await ref
                              .read(settingsNotifierProvider.notifier)
                              .resetSubjectOverride(subject.id);
                        },
                        icon: const Icon(Icons.restore),
                        label: const Text('Auf Global zurücksetzen'),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectsManager extends ConsumerWidget {
  final List<Subject> subjects;
  const _SubjectsManager({required this.subjects});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...subjects.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Card(
              child: ListTile(
                leading: Icon(
                  Icons.menu_book_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(s.name),
                trailing: IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  tooltip: 'Fach löschen',
                  onPressed: () => _confirmDelete(context, ref, s),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        FilledButton.icon(
          onPressed: () => _showAddSubjectDialog(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Fach hinzufügen'),
        ),
      ],
    );
  }

  void _showAddSubjectDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Neues Fach'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Fachname',
            hintText: 'z.B. Mathematik',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              await ref
                  .read(subjectsNotifierProvider.notifier)
                  .addSubject(name);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Erstellen'),
          ),
        ],
      ),
    ).then((_) => ctrl.dispose());
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Subject subject) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Fach löschen'),
        content: Text('Fach "${subject.name}" löschen?'),
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
                  .read(subjectsNotifierProvider.notifier)
                  .deleteSubject(subject.id);
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}
