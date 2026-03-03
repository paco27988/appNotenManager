import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/classes/screens/home_screen.dart';
import '../features/classes/screens/class_detail_screen.dart';
import '../features/students/screens/student_detail_screen.dart';
import '../features/grades/screens/grade_entry_screen.dart';
import '../features/report/screens/report_screen.dart';
import '../features/categories/screens/categories_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/backup/screens/backup_screen.dart';
import '../features/subjects/screens/subject_detail_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/class/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        if (id == null) return const Scaffold(body: Center(child: Text('Ungültige Klassen-ID')));
        return ClassDetailScreen(classId: id);
      },
      routes: [
        GoRoute(
          path: 'student/:sid',
          builder: (context, state) {
            final classId = int.tryParse(state.pathParameters['id'] ?? '');
            final studentId = int.tryParse(state.pathParameters['sid'] ?? '');
            if (classId == null || studentId == null) {
              return const Scaffold(body: Center(child: Text('Ungültige ID')));
            }
            return StudentDetailScreen(
              studentId: studentId,
              classId: classId,
            );
          },
          routes: [
            GoRoute(
              path: 'grades/:subjectId',
              builder: (context, state) {
                final classId = int.tryParse(state.pathParameters['id'] ?? '');
                final studentId = int.tryParse(state.pathParameters['sid'] ?? '');
                final subjectId = int.tryParse(state.pathParameters['subjectId'] ?? '');
                if (classId == null || studentId == null || subjectId == null) {
                  return const Scaffold(body: Center(child: Text('Ungültige ID')));
                }
                return GradeEntryScreen(
                  studentId: studentId,
                  subjectId: subjectId,
                  classId: classId,
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: 'report',
          builder: (context, state) {
            final classId = int.tryParse(state.pathParameters['id'] ?? '');
            if (classId == null) return const Scaffold(body: Center(child: Text('Ungültige ID')));
            return ReportScreen(classId: classId);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/categories',
      builder: (context, state) => const CategoriesScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
      routes: [
        GoRoute(
          path: 'subject/:id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            if (id == null) {
              return const Scaffold(body: Center(child: Text('Ungültige Fach-ID')));
            }
            return SubjectDetailScreen(subjectId: id);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/backup',
      builder: (context, state) => const BackupScreen(),
    ),
  ],
  errorBuilder: (context, state) => const Scaffold(
    body: Center(child: Text('Seite nicht gefunden')),
  ),
);
