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

    final Map<int, List<Grade>> gradesByCategory = {};
    for (final g in semesterGrades) {
      gradesByCategory.putIfAbsent(g.categoryId, () => []).add(g);
    }

    double weightedSum = 0;
    double totalUsedWeight = 0;

    for (final cat in categories) {
      final catGrades = gradesByCategory[cat.id];
      if (catGrades == null || catGrades.isEmpty) continue;
      // Gewichteter Schnitt innerhalb der Kategorie (Faktor pro Note)
      final totalFactor = catGrades.fold(0.0, (s, g) => s + g.factor);
      final avg = catGrades.fold(0.0, (s, g) => s + g.value * g.factor) /
          totalFactor;
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

  /// Format grade for detail display (1 decimal place, German comma).
  static String formatGradeDetail(double? grade) {
    if (grade == null) return '–';
    return grade.toStringAsFixed(1).replaceAll('.', ',');
  }

  /// Format grade for report/Zeugnis (whole number).
  static String formatGradeReport(double? grade) {
    if (grade == null) return '–';
    return roundToWholeGrade(grade).toString();
  }

  /// German grade steps with +/- modifiers (1/3-step convention).
  /// 16 entries: 1+ (0.67) through 5- (5.33) and 6 (6.0).
  static const List<(double, String)> gradeSteps = [
    (0.67, '1+'), (1.0, '1'), (1.33, '1-'),
    (1.67, '2+'), (2.0, '2'), (2.33, '2-'),
    (2.67, '3+'), (3.0, '3'), (3.33, '3-'),
    (3.67, '4+'), (4.0, '4'), (4.33, '4-'),
    (4.67, '5+'), (5.0, '5'), (5.33, '5-'),
    (6.0, '6'),
  ];

  /// Formats an individual entered grade as German +/- notation.
  /// Returns e.g. "2+", "3", "4-" if the value matches a standard step,
  /// otherwise falls back to one-decimal notation.
  static String formatGradeEntry(double value) {
    for (final (v, label) in gradeSteps) {
      if ((value - v).abs() < 0.02) return label;
    }
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }

  /// Berechnet den gewichteten Schnitt einer Liste von Noten (mit Faktor).
  static double? categoryAverage(List<Grade> grades) {
    if (grades.isEmpty) return null;
    final totalFactor = grades.fold(0.0, (s, g) => s + g.factor);
    if (totalFactor == 0) return null;
    return grades.fold(0.0, (s, g) => s + g.value * g.factor) / totalFactor;
  }

  /// Applies subject-specific overrides to the global category list.
  /// Returns only active categories, with overridden weights if set.
  static List<GradeCategory> applySubjectOverrides(
    List<GradeCategory> globalCategories,
    List<SubjectCategoryOverride> overrides,
  ) {
    if (overrides.isEmpty) return globalCategories;
    final overrideMap = {for (final o in overrides) o.categoryId: o};
    return globalCategories
        .where((cat) => overrideMap[cat.id]?.isActive ?? true)
        .map((cat) {
          final o = overrideMap[cat.id];
          if (o?.weightOverride != null) {
            return GradeCategory(
              id: cat.id,
              name: cat.name,
              weightPercent: o!.weightOverride!,
              colorHex: cat.colorHex,
              icon: cat.icon,
            );
          }
          return cat;
        })
        .toList();
  }
}
