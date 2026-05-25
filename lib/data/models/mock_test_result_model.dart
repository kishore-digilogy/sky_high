import 'package:sky_high/core/utils/localization_helper.dart';

class MockTestResultModel {
  final int id;
  final int userId;
  final String category;
  final String language;
  final String setName;
  final int score;
  final int totalQuestions;
  final DateTime completedAt;
  final int? subcategoryId;
  final int? companyId;
  final String? subcategoryName;
  final String? companyName;
  final int? categoryId;

  MockTestResultModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.language,
    required this.setName,
    required this.score,
    required this.totalQuestions,
    required this.completedAt,
    this.subcategoryId,
    this.companyId,
    this.subcategoryName,
    this.companyName,
    this.categoryId,
  });

  factory MockTestResultModel.fromJson(Map<String, dynamic> json) {
    return MockTestResultModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['user_id'] is int
          ? json['user_id']
          : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      category: LocalizationHelper.getLocalized(json, 'category'),
      language: json['language']?.toString() ?? 'english',
      setName: LocalizationHelper.getLocalized(json, 'set_name'),
      score: json['score'] is int
          ? json['score']
          : int.tryParse(json['score']?.toString() ?? '0') ?? 0,
      totalQuestions: json['total_questions'] is int
          ? json['total_questions']
          : int.tryParse(json['total_questions']?.toString() ?? '0') ?? 0,
      completedAt:
          DateTime.tryParse(json['completed_at'] ?? '') ?? DateTime.now(),
      subcategoryId: json['subcategory_id'] is int
          ? json['subcategory_id']
          : int.tryParse(json['subcategory_id']?.toString() ?? ''),
      companyId: json['company_id'] is int
          ? json['company_id']
          : int.tryParse(json['company_id']?.toString() ?? ''),
      subcategoryName: LocalizationHelper.getLocalized(
        json,
        'subcategory_name',
      ),
      companyName: LocalizationHelper.getLocalized(json, 'company_name'),
      categoryId: json['category_id'] is int
          ? json['category_id']
          : int.tryParse(json['category_id']?.toString() ?? ''),
    );
  }

  /// Calculates accuracy percentage (e.g. 75.0)
  double get accuracy {
    if (totalQuestions <= 0) return 0.0;
    return (score / totalQuestions) * 100;
  }

  /// Get name to display for category / company
  String get displayCategory {
    if (companyName != null && companyName!.isNotEmpty) {
      return companyName!;
    }
    if (category.isNotEmpty) {
      return category;
    }
    if (subcategoryName != null && subcategoryName!.isNotEmpty) {
      return subcategoryName!;
    }
    return 'General';
  }

  /// Get formatted date string: e.g. "May 18, 2026"
  String get formattedDate {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final localTime = completedAt.toLocal();
    final day = localTime.day.toString().padLeft(2, '0');
    final monthStr = months[localTime.month - 1];
    final year = localTime.year;

    // Add time details as well for clarity: "10:30 AM"
    final hour24 = localTime.hour;
    final amPm = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
    final minuteStr = localTime.minute.toString().padLeft(2, '0');

    return '$day $monthStr $year at $hour12:$minuteStr $amPm';
  }
}
