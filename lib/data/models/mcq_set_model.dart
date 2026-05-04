class McqSetModel {
  final String? setKey;
  final int? chapterId;
  final String? chapterName;
  final int? topicId;
  final String? topicName;
  final int? subtopicId;
  final String? subtopicName;
  final String? setName;
  final int? questionCount;

  McqSetModel({
    this.setKey,
    this.chapterId,
    this.chapterName,
    this.topicId,
    this.topicName,
    this.subtopicId,
    this.subtopicName,
    this.setName,
    this.questionCount,
  });

  factory McqSetModel.fromJson(Map<String, dynamic> json) {
    return McqSetModel(
      setKey: json['setKey'],
      chapterId: json['chapterId'],
      chapterName: json['chapterName'],
      topicId: json['topicId'],
      topicName: json['topicName'],
      subtopicId: json['subtopicId'],
      subtopicName: json['subtopicName'],
      setName: json['setName'],
      questionCount: json['questionCount'],
    );
  }
}
