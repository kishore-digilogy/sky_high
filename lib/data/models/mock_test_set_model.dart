class MockTestSetModel {
  final String? setName;
  final String? category;
  final int? chapterId;
  final int? topicId;
  final int? subtopicId;
  final String? chapterName;
  final String? topicName;
  final String? subtopicName;

  MockTestSetModel({
    this.setName,
    this.category,
    this.chapterId,
    this.topicId,
    this.subtopicId,
    this.chapterName,
    this.topicName,
    this.subtopicName,
  });

  factory MockTestSetModel.fromJson(Map<String, dynamic> json) {
    return MockTestSetModel(
      setName: json['set_name'],
      category: json['category'],
      chapterId: json['chapter_id'],
      topicId: json['topic_id'],
      subtopicId: json['subtopic_id'],
      chapterName: json['chapter_name'],
      topicName: json['topic_name'],
      subtopicName: json['subtopic_name'],
    );
  }
}
