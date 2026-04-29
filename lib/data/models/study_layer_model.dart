class StudyLayerModel {
  final int id;
  final String title;
  final String? subtitle;
  final int moduleNumber;
  final String? icon;
  final String? description;
  final int points;
  final List<dynamic> materials;

  StudyLayerModel({
    required this.id,
    required this.title,
    this.subtitle,
    required this.moduleNumber,
    this.icon,
    this.description,
    this.points = 0,
    this.materials = const [],
  });

  factory StudyLayerModel.fromJson(Map<String, dynamic> json) {
    return StudyLayerModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      subtitle: json['subtitle'],
      moduleNumber: json['module_number'] ?? 0,
      icon: json['icon'],
      description: json['description'],
      points: json['points'] ?? 0,
      materials: json['materials'] ?? [],
    );
  }

  bool get isFree => moduleNumber <= 3;
}
