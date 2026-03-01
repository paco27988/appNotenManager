import 'package:flutter_test/flutter_test.dart';
import 'package:leher_app/core/utils/grade_calculator.dart';

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

    test('roundToWholeGrade clamps to 1-6', () {
      expect(GradeCalculator.roundToWholeGrade(1.4), 1);
      expect(GradeCalculator.roundToWholeGrade(1.5), 2);
      expect(GradeCalculator.roundToWholeGrade(6.9), 6);
    });

    test('formatGradeDetail', () {
      expect(GradeCalculator.formatGradeDetail(2.333), '2.3');
      expect(GradeCalculator.formatGradeDetail(null), '–');
    });

    test('formatGradeReport', () {
      expect(GradeCalculator.formatGradeReport(2.4), '2');
      expect(GradeCalculator.formatGradeReport(2.5), '3');
    });
  });
}
