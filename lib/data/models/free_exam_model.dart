class FreeExamModel {
  final String setName;
  final String? category;
  final int? categoryId;
  final int questionCount;
  final DateTime latestDate;
  final String? companyName;

  FreeExamModel({
    required this.setName,
    this.category,
    this.categoryId,
    required this.questionCount,
    required this.latestDate,
    this.companyName,
  });

  factory FreeExamModel.fromJson(Map<String, dynamic> json) {
    return FreeExamModel(
      setName: json['set_name'] ?? '',
      category: json['category'],
      categoryId: json['category_id'],
      questionCount: json['question_count'] ?? 0,
      latestDate:
          DateTime.tryParse(json['latest_date'] ?? '') ?? DateTime.now(),
      companyName: json['company_name'],
    );
  }

  /// Display name: use category or company name if available
  String get displayCategory => category ?? companyName ?? 'General';

  /// Formatted question count
  String get formattedCount {
    if (questionCount >= 1000) {
      return '${(questionCount / 1000).toStringAsFixed(1)}k';
    }
    return '$questionCount';
  }

  /// Time since last update
  String get lastUpdated {
    final diff = DateTime.now().difference(latestDate);
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'Just now';
  }
}
