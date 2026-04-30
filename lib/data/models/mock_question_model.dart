class MockQuestionModel {
  final int id;
  final String questionText;
  final String? optionA;
  final String? optionB;
  final String? optionC;
  final String? optionD;
  final String correctOption;
  final String? questionImage;
  final String? optionAImage;
  final String? optionBImage;
  final String? optionCImage;
  final String? optionDImage;
  final String? explanation;
  final String setName;
  final String? chapterName;
  final String? topicName;
  final String? subtopicName;
  final int? categoryId;
  final int? subcategoryId;
  final int? companyId;
  final String? subcategoryName;
  final String? companyName;
  final String? category;
  final String? language;

  MockQuestionModel({
    required this.id,
    required this.questionText,
    this.optionA,
    this.optionB,
    this.optionC,
    this.optionD,
    required this.correctOption,
    this.questionImage,
    this.optionAImage,
    this.optionBImage,
    this.optionCImage,
    this.optionDImage,
    this.explanation,
    required this.setName,
    this.chapterName,
    this.topicName,
    this.subtopicName,
    this.categoryId,
    this.subcategoryId,
    this.companyId,
    this.subcategoryName,
    this.companyName,
    this.category,
    this.language,
  });

  factory MockQuestionModel.fromJson(Map<String, dynamic> json) {
    return MockQuestionModel(
      id: json['id'],
      questionText: json['question_text'] ?? '',
      optionA: json['option_a'],
      optionB: json['option_b'],
      optionC: json['option_c'],
      optionD: json['option_d'],
      correctOption: (json['correct_option'] ?? '').toString().toLowerCase(),
      questionImage: json['question_image'],
      optionAImage: json['option_a_image'],
      optionBImage: json['option_b_image'],
      optionCImage: json['option_c_image'],
      optionDImage: json['option_d_image'],
      explanation: json['explanation_answer'],
      setName: json['set_name'] ?? '',
      chapterName: json['chapter_name'],
      topicName: json['topic_name'],
      subtopicName: json['subtopic_name'],
      categoryId: json['category_id'],
      subcategoryId: json['subcategory_id'],
      companyId: json['company_id'],
      subcategoryName: json['subcategory_name'],
      companyName: json['company_name'],
      category: json['category'],
      language: json['language'],
    );
  }

  bool get hasImages =>
      questionImage != null ||
      optionAImage != null ||
      optionBImage != null ||
      optionCImage != null ||
      optionDImage != null;

  String getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return 'https://digilogy-skyhigh.s3.eu-north-1.amazonaws.com/$cleanPath';
  }

  String get fullQuestionImage => getFullImageUrl(questionImage);
  String get fullOptionAImage => getFullImageUrl(optionAImage);
  String get fullOptionBImage => getFullImageUrl(optionBImage);
  String get fullOptionCImage => getFullImageUrl(optionCImage);
  String get fullOptionDImage => getFullImageUrl(optionDImage);

  String getOptionText(String option) {
    switch (option.toLowerCase()) {
      case 'a':
        return optionA ?? '';
      case 'b':
        return optionB ?? '';
      case 'c':
        return optionC ?? '';
      case 'd':
        return optionD ?? '';
      default:
        return '';
    }
  }

  String? getOptionImage(String option) {
    switch (option.toLowerCase()) {
      case 'a':
        return optionAImage;
      case 'b':
        return optionBImage;
      case 'c':
        return optionCImage;
      case 'd':
        return optionDImage;
      default:
        return null;
    }
  }
}
