import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../classes_provider.dart';
import '../../students/students_provider.dart';
import '../../subjects/subjects_provider.dart';
import '../../../core/database/app_database.dart';

class ClassDetailScreen extends ConsumerWidget {
  final int classId;
  const ClassDetailScreen({super.key, required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classAsync = ref.watch(classByIdProvider(classId));
    final studentsAsync = ref.watch(studentsByClassProvider(classId));
    final classSubjectsAsync = ref.watch(classSubjectsProvider(classId));

    return classAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Ein Fehler ist aufgetreten')),
      ),
      data: (cls) {
        if (cls == null) {
          return const Scaffold(
              body: Center(child: Text('Klasse nicht gefunden')));
        }
        return DefaultTabController(
          length: 2,
          child: Builder(
            builder: (tabContext) => Scaffold(
              appBar: AppBar(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cls.name),
                    Text(
                      cls.schoolYear,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.grading),
                    tooltip: 'Zeugnis',
                    onPressed: () => context.push('/class/$classId/report'),
                  ),
                ],
              ),
              body: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(icon: Icon(Icons.people), text: 'Schüler'),
                      Tab(icon: Icon(Icons.book), text: 'Fächer'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _StudentsTab(
                          classId: classId,
                          studentsAsync: studentsAsync,
                        ),
                        _SubjectsTab(
                          classId: classId,
                          classSubjectsAsync: classSubjectsAsync,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              floatingActionButton: _buildFab(tabContext, ref),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFab(BuildContext context, WidgetRef ref) {
    return DefaultTabController.maybeOf(context) != null
        ? _TabAwareFab(classId: classId)
        : const SizedBox.shrink();
  }
}

class _TabAwareFab extends ConsumerStatefulWidget {
  final int classId;
  const _TabAwareFab({required this.classId});

  @override
  ConsumerState<_TabAwareFab> createState() => _TabAwareFabState();
}

class _TabAwareFabState extends ConsumerState<_TabAwareFab> {
  int _tabIndex = 0;
  TabController? _tc;

  void _onTabChange() {
    if (mounted) setState(() => _tabIndex = _tc!.index);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tc = DefaultTabController.of(context);
    if (tc != _tc) {
      _tc?.removeListener(_onTabChange);
      _tc = tc;
      _tc!.addListener(_onTabChange);
    }
  }

  @override
  void dispose() {
    _tc?.removeListener(_onTabChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_tabIndex == 0) {
      return FloatingActionButton.extended(
        heroTag: 'student_fab',
        onPressed: () => _showAddStudentDialog(context, ref),
        icon: const Icon(Icons.person_add),
        label: const Text('Schüler'),
      );
    } else {
      return FloatingActionButton.extended(
        heroTag: 'subject_fab',
        onPressed: () => _showSubjectPicker(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Fach zuweisen'),
      );
    }
  }

  void _showAddStudentDialog(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(studentsNotifierProvider.notifier);
    showDialog(
      context: context,
      builder: (_) => _StudentDialog(
        onSave: (firstName, lastName) =>
            notifier.addStudent(widget.classId, firstName, lastName),
      ),
    );
  }

  void _showSubjectPicker(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _SubjectPickerDialog(classId: widget.classId),
    );
  }
}

class _StudentsTab extends ConsumerWidget {
  final int classId;
  final AsyncValue<List<Student>> studentsAsync;

  const _StudentsTab({
    required this.classId,
    required this.studentsAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return studentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text('Ein Fehler ist aufgetreten')),
      data: (students) {
        if (students.isEmpty) {
          return const _EmptyTabState(
            icon: Icons.person_add_outlined,
            title: 'Noch keine Schüler',
            subtitle: 'Tippe auf "Schüler", um den ersten Schüler hinzuzufügen.',
          );
        }
        final sorted = [...students]
          ..sort(
            (a, b) => '${a.lastName} ${a.firstName}'.compareTo(
              '${b.lastName} ${b.firstName}',
            ),
          );
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: sorted.length,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _StudentTile(student: sorted[i], classId: classId),
          ),
        );
      },
    );
  }
}

class _StudentTile extends ConsumerWidget {
  final Student student;
  final int classId;

  const _StudentTile({
    required this.student,
    required this.classId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/class/$classId/student/${student.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: cs.secondaryContainer,
                child: Text(
                  student.firstName.isNotEmpty
                      ? student.firstName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: cs.onSecondaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  '${student.lastName}, ${student.firstName}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w500),
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
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _StudentDialog(
        initialFirst: student.firstName,
        initialLast: student.lastName,
        onSave: (first, last) async {
          await ref
              .read(studentsNotifierProvider.notifier)
              .updateStudent(student.id, classId, first, last);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Schüler löschen'),
        content: Text(
          '${student.firstName} ${student.lastName} und alle Noten löschen?',
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
                  .read(studentsNotifierProvider.notifier)
                  .deleteStudent(student.id, classId);
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}

class _EmptyTabState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyTabState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

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
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: cs.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: cs.onSurface.withOpacity( 0.5)),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity( 0.6),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectsTab extends ConsumerWidget {
  final int classId;
  final AsyncValue<List<Subject>> classSubjectsAsync;

  const _SubjectsTab({
    required this.classId,
    required this.classSubjectsAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return classSubjectsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text('Ein Fehler ist aufgetreten')),
      data: (subjects) {
        if (subjects.isEmpty) {
          return const _EmptyTabState(
            icon: Icons.menu_book_outlined,
            title: 'Keine Fächer zugewiesen',
            subtitle: 'Tippe auf "Fach zuweisen", um Fächer hinzuzufügen.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: subjects.length,
          itemBuilder: (context, i) {
            final s = subjects[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading: Icon(
                    Icons.menu_book_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(s.name),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.remove_circle_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    tooltip: 'Fach entfernen',
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Fach entfernen'),
                        content: Text('Fach "${s.name}" von der Klasse entfernen?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Abbrechen'),
                          ),
                          FilledButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              await ref
                                  .read(classesNotifierProvider.notifier)
                                  .removeSubject(classId, s.id);
                            },
                            child: const Text('Entfernen'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SubjectPickerDialog extends ConsumerWidget {
  final int classId;
  const _SubjectPickerDialog({required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allSubjectsAsync = ref.watch(subjectsStreamProvider);
    final assignedAsync = ref.watch(classSubjectsProvider(classId));

    return AlertDialog(
      title: const Text('Fach zuweisen'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: allSubjectsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => const Text('Fehler beim Laden'),
          data: (allSubjects) {
            final assigned = assignedAsync.valueOrNull ?? [];
            final assignedIds = assigned.map((s) => s.id).toSet();

            if (allSubjects.isEmpty) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Noch keine Fächer vorhanden.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/settings');
                    },
                    child: const Text('Fächer verwalten'),
                  ),
                ],
              );
            }

            return ListView.builder(
              itemCount: allSubjects.length,
              itemBuilder: (context, i) {
                final s = allSubjects[i];
                final isAssigned = assignedIds.contains(s.id);
                return CheckboxListTile(
                  title: Text(s.name),
                  value: isAssigned,
                  onChanged: (val) async {
                    final notifier = ref.read(classesNotifierProvider.notifier);
                    if (val == true) {
                      await notifier.assignSubject(classId, s.id);
                    } else {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Fach entfernen'),
                          content: Text('Fach "${s.name}" von der Klasse entfernen?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Abbrechen'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Entfernen'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await notifier.removeSubject(classId, s.id);
                      }
                    }
                  },
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fertig'),
        ),
      ],
    );
  }
}

class _StudentDialog extends StatefulWidget {
  final String? initialFirst;
  final String? initialLast;
  final Future<void> Function(String firstName, String lastName) onSave;

  const _StudentDialog({
    this.initialFirst,
    this.initialLast,
    required this.onSave,
  });

  @override
  State<_StudentDialog> createState() => _StudentDialogState();
}

class _StudentDialogState extends State<_StudentDialog> {
  late final TextEditingController _firstCtrl;
  late final TextEditingController _lastCtrl;
  bool _loading = false;
  String? _firstError;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _firstCtrl = TextEditingController(text: widget.initialFirst ?? '');
    _lastCtrl = TextEditingController(text: widget.initialLast ?? '');
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialFirst != null;
    return AlertDialog(
      title: Text(isEdit ? 'Schüler bearbeiten' : 'Neuer Schüler'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _firstCtrl,
            decoration: InputDecoration(
              labelText: 'Vorname',
              prefixIcon: const Icon(Icons.person_outline),
              errorText: _firstError,
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            maxLength: 100,
            onChanged: (_) {
              if (_firstError != null) setState(() => _firstError = null);
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _lastCtrl,
            decoration: InputDecoration(
              labelText: 'Nachname',
              prefixIcon: const Icon(Icons.badge_outlined),
              errorText: _lastError,
            ),
            textCapitalization: TextCapitalization.words,
            maxLength: 100,
            onChanged: (_) {
              if (_lastError != null) setState(() => _lastError = null);
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
                  final first = _firstCtrl.text.trim();
                  final last = _lastCtrl.text.trim();
                  if (first.isEmpty || last.isEmpty) {
                    setState(() {
                      _firstError = first.isEmpty ? 'Pflichtfeld' : null;
                      _lastError = last.isEmpty ? 'Pflichtfeld' : null;
                    });
                    return;
                  }
                  setState(() => _loading = true);
                  try {
                    await widget.onSave(first, last);
                    if (context.mounted) Navigator.pop(context);
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Fehler: Konnte nicht gespeichert werden')),
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
