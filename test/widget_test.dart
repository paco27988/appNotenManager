import 'package:flutter_test/flutter_test.dart';
import 'package:leher_app/core/database/app_database.dart';
import 'package:leher_app/core/utils/grade_calculator.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

Grade _grade(int categoryId, double value, int semester, {double factor = 1.0}) {
  return Grade(
    id: 1,
    studentId: 1,
    subjectId: 1,
    categoryId: categoryId,
    value: value,
    factor: factor,
    semester: semester,
    date: DateTime(2024, 1, 1),
    comment: '',
  );
}

GradeCategory _cat(int id, double weight) {
  return GradeCategory(
    id: id,
    name: 'Cat$id',
    weightPercent: weight,
    colorHex: '#2196F3',
    icon: 'label',
  );
}

SubjectCategoryOverride _override(
  int categoryId, {
  bool isActive = true,
  double? weightOverride,
}) {
  return SubjectCategoryOverride(
    subjectId: 1,
    categoryId: categoryId,
    isActive: isActive,
    weightOverride: weightOverride,
  );
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('GradeCalculator', () {
    test('calculateYearlyGrade with 50/50 weighting', () {
      final result = GradeCalculator.calculateYearlyGrade(2.0, 4.0, 50, 50);
      expect(result, closeTo(3.0, 0.001));
    });

    test('calculateYearlyGrade with 60/40 weighting', () {
      final result = GradeCalculator.calculateYearlyGrade(2.0, 4.0, 60, 40);
      expect(result, closeTo(2.8, 0.001));
    });

    test('calculateYearlyGrade returns null when both null', () {
      final result =
          GradeCalculator.calculateYearlyGrade(null, null, 50, 50);
      expect(result, isNull);
    });

    test('calculateYearlyGrade returns hj1 when hj2 is null', () {
      final result = GradeCalculator.calculateYearlyGrade(2.5, null, 50, 50);
      expect(result, 2.5);
    });

    test('calculateYearlyGrade returns hj2 when hj1 is null', () {
      expect(GradeCalculator.calculateYearlyGrade(null, 4.0, 50, 50), closeTo(4.0, 0.001));
    });

    test('calculateYearlyGrade returns null when both weights are zero', () {
      expect(GradeCalculator.calculateYearlyGrade(2.0, 4.0, 0, 0), isNull);
    });

    group('categoryAverage', () {
      test('returns null for empty list', () {
        expect(GradeCalculator.categoryAverage([]), isNull);
      });

      test('returns null when all factors are zero', () {
        final grades = [
          Grade(id: 1, studentId: 1, subjectId: 1, categoryId: 1,
                value: 3.0, factor: 0.0, semester: 1,
                date: DateTime(2024), comment: ''),
        ];
        expect(GradeCalculator.categoryAverage(grades), isNull);
      });

      test('weighted by factor', () {
        final grades = [
          Grade(id: 1, studentId: 1, subjectId: 1, categoryId: 1,
                value: 2.0, factor: 1.0, semester: 1,
                date: DateTime(2024), comment: ''),
          Grade(id: 2, studentId: 1, subjectId: 1, categoryId: 1,
                value: 4.0, factor: 3.0, semester: 1,
                date: DateTime(2024), comment: ''),
        ];
        // (2*1 + 4*3) / 4 = 14/4 = 3.5
        expect(GradeCalculator.categoryAverage(grades), closeTo(3.5, 0.001));
      });
    });

    test('roundToWholeGrade clamps to 1-6', () {
      expect(GradeCalculator.roundToWholeGrade(1.4), 1);
      expect(GradeCalculator.roundToWholeGrade(1.5), 2);
      expect(GradeCalculator.roundToWholeGrade(6.9), 6);
    });

    test('formatGradeDetail uses German comma', () {
      expect(GradeCalculator.formatGradeDetail(2.333), '2,3');
      expect(GradeCalculator.formatGradeDetail(null), '–');
    });

    test('formatGradeReport', () {
      expect(GradeCalculator.formatGradeReport(2.4), '2');
      expect(GradeCalculator.formatGradeReport(2.5), '3');
    });

    group('formatGradeEntry', () {
      test('exact step values return label', () {
        expect(GradeCalculator.formatGradeEntry(0.67), '1+');
        expect(GradeCalculator.formatGradeEntry(1.0), '1');
        expect(GradeCalculator.formatGradeEntry(1.33), '1-');
        expect(GradeCalculator.formatGradeEntry(1.67), '2+');
        expect(GradeCalculator.formatGradeEntry(2.0), '2');
        expect(GradeCalculator.formatGradeEntry(6.0), '6');
      });

      test('values within tolerance return label', () {
        expect(GradeCalculator.formatGradeEntry(0.675), '1+');
        expect(GradeCalculator.formatGradeEntry(0.655), '1+');
        expect(GradeCalculator.formatGradeEntry(1.005), '1');
      });

      test('legacy non-step values fall back to decimal with comma', () {
        expect(GradeCalculator.formatGradeEntry(2.5), '2,5');
        expect(GradeCalculator.formatGradeEntry(3.7), '3,7');
      });

      test('all gradeSteps round-trip correctly', () {
        for (final (value, label) in GradeCalculator.gradeSteps) {
          expect(GradeCalculator.formatGradeEntry(value), label,
              reason: '$value should format as $label');
        }
      });
    });

    // ── calculateSemesterGrade ──────────────────────────────────────────────

    group('calculateSemesterGrade', () {
      test('empty grade list returns null', () {
        final cats = [_cat(1, 100.0)];
        expect(GradeCalculator.calculateSemesterGrade([], cats, 1), isNull);
      });

      test('one category one grade', () {
        final cats = [_cat(1, 100.0)];
        final grades = [_grade(1, 3.0, 1)];
        final result =
            GradeCalculator.calculateSemesterGrade(grades, cats, 1);
        expect(result, closeTo(3.0, 0.001));
      });

      test('multiple categories with different weights normalized correctly',
          () {
        // Cat1: 60%, Cat2: 40%. Grade in cat1=2.0, in cat2=4.0.
        // Expected = (2.0*60 + 4.0*40) / (60+40) = (120+160)/100 = 2.8
        final cats = [_cat(1, 60.0), _cat(2, 40.0)];
        final grades = [_grade(1, 2.0, 1), _grade(2, 4.0, 1)];
        final result =
            GradeCalculator.calculateSemesterGrade(grades, cats, 1);
        expect(result, closeTo(2.8, 0.001));
      });

      test('grade with factor != 1.0 is weighted within category', () {
        // One category, two grades: 2.0 (factor 1.0) and 4.0 (factor 2.0)
        // Weighted avg = (2.0*1 + 4.0*2) / (1+2) = 10/3 ≈ 3.333
        final cats = [_cat(1, 100.0)];
        final grades = [
          _grade(1, 2.0, 1, factor: 1.0),
          _grade(1, 4.0, 1, factor: 2.0),
        ];
        final result =
            GradeCalculator.calculateSemesterGrade(grades, cats, 1);
        expect(result, closeTo(10.0 / 3.0, 0.001));
      });

      test('only grades from requested semester contribute', () {
        // Semester 1 grade: 2.0; Semester 2 grade: 5.0 (should be ignored)
        final cats = [_cat(1, 100.0)];
        final grades = [
          _grade(1, 2.0, 1),
          _grade(1, 5.0, 2),
        ];
        final result =
            GradeCalculator.calculateSemesterGrade(grades, cats, 1);
        expect(result, closeTo(2.0, 0.001));
      });

      test('returns null when no grades in requested semester', () {
        final cats = [_cat(1, 100.0)];
        final grades = [_grade(1, 3.0, 2)]; // only semester 2
        expect(
          GradeCalculator.calculateSemesterGrade(grades, cats, 1),
          isNull,
        );
      });
    });

    // ── applySubjectOverrides ───────────────────────────────────────────────

    group('applySubjectOverrides', () {
      test('empty overrides returns identical list', () {
        final cats = [_cat(1, 60.0), _cat(2, 40.0)];
        final result =
            GradeCalculator.applySubjectOverrides(cats, []);
        expect(result, cats);
      });

      test('inactive category is excluded', () {
        final cats = [_cat(1, 60.0), _cat(2, 40.0)];
        final overrides = [_override(2, isActive: false)];
        final result =
            GradeCalculator.applySubjectOverrides(cats, overrides);
        expect(result.map((c) => c.id), [1]);
      });

      test('weight override is applied', () {
        final cats = [_cat(1, 60.0), _cat(2, 40.0)];
        final overrides = [_override(1, weightOverride: 80.0)];
        final result =
            GradeCalculator.applySubjectOverrides(cats, overrides);
        final cat1 = result.firstWhere((c) => c.id == 1);
        expect(cat1.weightPercent, closeTo(80.0, 0.001));
      });

      test('mixed active/inactive with weight overrides', () {
        final cats = [_cat(1, 60.0), _cat(2, 30.0), _cat(3, 10.0)];
        final overrides = [
          _override(1, weightOverride: 70.0),
          _override(2, isActive: false),
        ];
        final result =
            GradeCalculator.applySubjectOverrides(cats, overrides);
        expect(result.map((c) => c.id).toList(), [1, 3]);
        expect(result.firstWhere((c) => c.id == 1).weightPercent,
            closeTo(70.0, 0.001));
        expect(result.firstWhere((c) => c.id == 3).weightPercent,
            closeTo(10.0, 0.001));
      });

      test('override only affects matching categoryId (no cross-contamination)',
          () {
        final cats = [_cat(1, 60.0), _cat(2, 40.0)];
        final overrides = [_override(1, weightOverride: 50.0)];
        final result =
            GradeCalculator.applySubjectOverrides(cats, overrides);
        // Cat2 must keep its original weight
        expect(result.firstWhere((c) => c.id == 2).weightPercent,
            closeTo(40.0, 0.001));
      });

      test('returns empty list when all categories are deactivated', () {
        final cats = [
          const GradeCategory(id: 1, name: 'A', weightPercent: 60, colorHex: '#4CAF50', icon: 'label'),
          const GradeCategory(id: 2, name: 'B', weightPercent: 40, colorHex: '#2196F3', icon: 'label'),
        ];
        final overrides = [
          const SubjectCategoryOverride(subjectId: 1, categoryId: 1, isActive: false, weightOverride: null),
          const SubjectCategoryOverride(subjectId: 1, categoryId: 2, isActive: false, weightOverride: null),
        ];
        expect(GradeCalculator.applySubjectOverrides(cats, overrides), isEmpty);
      });
    });
  });
}
