import '../../core/database/app_database.dart';

/// Pure calculation logic – no Flutter/DB dependencies, easy to unit-test.
class GradeCalculator {
  /// Calculates the semester grade for a student in one subject.
  ///
  /// [grades] – all grades for this student/subject in the given semester
  /// [categories] – all available categories with their weightPercent
  ///
  /// Formula:
  ///   HJ_Note = Σ(avg(grades in category) × category.weightPercent) / totalWeight
  ///
  /// Only categories that have at least one grade contribute.
  /// Remaining weight from empty categories is redistributed proportionally.
  static double? calculateSemesterGrade(
    List<Grade> grades,
    List<GradeCategory> categories,
    int semester,
  ) {
    final semesterGrades = grades.where((g) => g.semester == semester).toList();
    if (semesterGrades.isEmpty) return null;

    final Map<int, List<double>> gradesByCategory = {};
    for (final g in semesterGrades) {
      gradesByCategory.putIfAbsent(g.categoryId, () => []).add(g.value);
    }

    double weightedSum = 0;
    double totalUsedWeight = 0;

    for (final cat in categories) {
      final catGrades = gradesByCategory[cat.id];
      if (catGrades == null || catGrades.isEmpty) continue;
      final avg = catGrades.reduce((a, b) => a + b) / catGrades.length;
      weightedSum += avg * cat.weightPercent;
      totalUsedWeight += cat.weightPercent;
    }

    if (totalUsedWeight == 0) return null;

    // Normalize by actually used weight so partial category sets still work
    return weightedSum / totalUsedWeight;
  }

  /// Calculates the yearly grade from two semester grades.
  ///
  /// [firstHalfWeight] + [secondHalfWeight] should equal 100.
  static double? calculateYearlyGrade(
    double? hj1,
    double? hj2,
    double firstHalfWeight,
    double secondHalfWeight,
  ) {
    if (hj1 == null && hj2 == null) return null;
    if (hj1 == null) return hj2;
    if (hj2 == null) return hj1;

    final totalWeight = firstHalfWeight + secondHalfWeight;
    if (totalWeight == 0) return null;

    return (hj1 * firstHalfWeight + hj2 * secondHalfWeight) / totalWeight;
  }

  /// Round to nearest integer for Zeugnis display (1–6).
  static int roundToWholeGrade(double grade) => grade.round().clamp(1, 6);

  /// Format grade for detail display (1 decimal place).
  static String formatGradeDetail(double? grade) {
    if (grade == null) return '–';
    return grade.toStringAsFixed(1);
  }

  /// Format grade for report/Zeugnis (whole number).
  static String formatGradeReport(double? grade) {
    if (grade == null) return '–';
    return roundToWholeGrade(grade).toString();
  }
}
