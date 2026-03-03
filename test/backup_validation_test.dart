import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leher_app/core/database/app_database.dart';
import 'package:leher_app/features/backup/backup_service.dart';

// Minimal valid backup payload for use in tests
Map<String, dynamic> _validData() => {
      'version': 1,
      'exportedAt': '2024-01-01T00:00:00.000',
      'categories': [
        {
          'id': 1,
          'name': 'Mündlich',
          'weightPercent': 60.0,
          'colorHex': '#4CAF50',
          'icon': 'label',
        },
      ],
      'classes': [
        {'id': 1, 'name': '9a', 'schoolYear': '2024/25'},
      ],
      'subjects': [
        {'id': 1, 'name': 'Mathe'},
      ],
      'students': [
        {'id': 1, 'classId': 1, 'firstName': 'Max', 'lastName': 'Muster'},
      ],
      'classSubjects': [
        <String, dynamic>{'classId': 1, 'subjectId': 1},
      ],
      'grades': [
        {
          'id': 1,
          'studentId': 1,
          'subjectId': 1,
          'categoryId': 1,
          'value': 3.0,
          'factor': 1.0,
          'semester': 1,
          'date': '2024-03-01T00:00:00.000',
          'comment': '',
        },
      ],
      'semesterSettings': [
        {'id': 1, 'subjectId': null, 'firstHalfWeight': 50.0, 'secondHalfWeight': 50.0},
      ],
      'subjectCategoryOverrides': [],
    };

BackupService _service() => BackupService(
      AppDatabase.forTesting(NativeDatabase.memory()),
    );

void main() {
  group('BackupService._validateBackupData', () {
    test('valid data passes without throwing', () {
      final svc = _service();
      expect(() => svc.validateBackupData(_validData()), returnsNormally);
    });

    test('version > 1 throws FormatException', () {
      final data = _validData();
      data['version'] = 2;
      expect(
        () => _service().validateBackupData(data),
        throwsA(isA<FormatException>()),
      );
    });

    test('version == 0 passes (forward-compat: only version > 1 rejected)',
        () {
      final data = _validData();
      data['version'] = 0;
      expect(() => _service().validateBackupData(data), returnsNormally);
    });

    test('category id as String throws FormatException', () {
      final data = _validData();
      (data['categories'] as List)[0]['id'] = '1'; // String instead of int
      expect(
        () => _service().validateBackupData(data),
        throwsA(isA<FormatException>()),
      );
    });

    test('category weightPercent as String throws FormatException', () {
      final data = _validData();
      (data['categories'] as List)[0]['weightPercent'] = '60'; // String
      expect(
        () => _service().validateBackupData(data),
        throwsA(isA<FormatException>()),
      );
    });

    test('negative weightPercent throws FormatException', () {
      final data = _validData();
      (data['categories'] as List)[0]['weightPercent'] = -5.0;
      expect(
        () => _service().validateBackupData(data),
        throwsA(isA<FormatException>()),
      );
    });

    test('classSubjects without classId throws FormatException', () {
      final data = _validData();
      (data['classSubjects'] as List)[0] = {'subjectId': 1}; // missing classId
      expect(
        () => _service().validateBackupData(data),
        throwsA(isA<FormatException>()),
      );
    });

    test('classSubjects.classId as String throws FormatException', () {
      final data = _validData();
      (data['classSubjects'] as List)[0]['classId'] = '1'; // String
      expect(
        () => _service().validateBackupData(data),
        throwsA(isA<FormatException>()),
      );
    });

    test('grade.value outside 0.67–6.0 throws FormatException', () {
      final data = _validData();
      (data['grades'] as List)[0]['value'] = 7.0;
      expect(
        () => _service().validateBackupData(data),
        throwsA(isA<FormatException>()),
      );
    });

    test('grade.value as String throws FormatException', () {
      final data = _validData();
      (data['grades'] as List)[0]['value'] = '3.0';
      expect(
        () => _service().validateBackupData(data),
        throwsA(isA<FormatException>()),
      );
    });

    test('subjectCategoryOverrides.isActive as String throws FormatException',
        () {
      final data = _validData();
      data['subjectCategoryOverrides'] = [
        {
          'subjectId': 1,
          'categoryId': 1,
          'isActive': 'true', // String instead of bool
          'weightOverride': null,
        },
      ];
      expect(
        () => _service().validateBackupData(data),
        throwsA(isA<FormatException>()),
      );
    });

    test('subjectCategoryOverrides.weightOverride as String throws FormatException', () {
      final data = _validData();
      (data['subjectCategoryOverrides'] as List).add(<String, dynamic>{
        'subjectId': 1,
        'categoryId': 1,
        'isActive': true,
        'weightOverride': '50.0', // String statt num
      });
      expect(
        () => _service().validateBackupData(data),
        throwsA(isA<FormatException>()),
      );
    });

    test('missing required field throws FormatException', () {
      final data = _validData();
      // Remove required 'name' from classes
      (data['classes'] as List)[0].remove('name');
      expect(
        () => _service().validateBackupData(data),
        throwsA(isA<FormatException>()),
      );
    });

    test('missing top-level section throws FormatException', () {
      final data = _validData();
      data.remove('grades');
      expect(
        () => _service().validateBackupData(data),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
