class ExamCategoryModel {
  final int id;
  final String title;
  final String? subtitle;
  final String? color;
  final String? icon;
  final String? type;
  final String? section;
  final List<ExamItemModel> items;
  final List<ExamSubcategoryModel> subcategories;

  ExamCategoryModel({
    required this.id,
    required this.title,
    this.subtitle,
    this.color,
    this.icon,
    this.type,
    this.section,
    required this.items,
    this.subcategories = const [],
  });

  factory ExamCategoryModel.fromJson(Map<String, dynamic> json) {
    return ExamCategoryModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      subtitle: json['subtitle'],
      color: json['color'],
      icon: json['icon'],
      type: json['type'],
      section: json['section'],
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (item) => ExamItemModel.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      subcategories:
          (json['subcategories'] as List<dynamic>?)
              ?.map(
                (sub) =>
                    ExamSubcategoryModel.fromJson(sub as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  // Helper getters for UI
  String get displayIcon => (icon != null && icon!.isNotEmpty) ? icon! : '📚';

  /// Returns the full logo URL of the first item that has a valid logo,
  /// or an empty string if none found. Used as the category thumbnail.
  String get firstItemLogoUrl {
    for (final item in items) {
      final url = item.fullLogoUrl;
      if (url.isNotEmpty) return url;
    }
    return '';
  }

  int get displayColorValue {
    switch (color?.toLowerCase()) {
      case 'red':
        return 0xFFEF4444;
      case 'blue':
        return 0xFF3B82F6;
      case 'green':
        return 0xFF10B981;
      case 'yellow':
        return 0xFFF59E0B;
      case 'purple':
        return 0xFF8B5CF6;
      case 'pink':
        return 0xFFEC4899;
      case 'orange':
        return 0xFFF97316;
      case 'teal':
        return 0xFF14B8A6;
      case 'indigo':
        return 0xFF6366F1;
      default:
        return 0xFFF9A826;
    }
  }

  int get totalCount => items.length + subcategories.length;
}

class ExamItemModel {
  final int id;
  final String name;
  final String? type;
  final String? logo;
  final String? section;
  final String? color;
  final String? url;
  final String? description;

  ExamItemModel({
    required this.id,
    required this.name,
    this.type,
    this.logo,
    this.section,
    this.color,
    this.url,
    this.description,
  });

  factory ExamItemModel.fromJson(Map<String, dynamic> json) {
    return ExamItemModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      type: json['type'],
      logo: json['logo'],
      section: json['section'],
      color: json['color'],
      url: json['url']?.toString(),
      description: json['description'],
    );
  }

  String get fullLogoUrl {
    if (logo == null || logo!.isEmpty) return '';
    if (logo!.startsWith('http')) return logo!;
    final cleanPath = logo!.startsWith('/') ? logo!.substring(1) : logo!;
    return 'https://digilogy-skyhigh.s3.eu-north-1.amazonaws.com/$cleanPath';
  }
}

class ExamSubcategoryModel {
  final int id;
  final String name;
  final String? thumbnailImage;
  final String? type;
  final String? section;
  final String? color;
  final List<ExamItemModel> items;

  ExamSubcategoryModel({
    required this.id,
    required this.name,
    this.thumbnailImage,
    this.type,
    this.section,
    this.color,
    required this.items,
  });

  factory ExamSubcategoryModel.fromJson(Map<String, dynamic> json) {
    return ExamSubcategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      thumbnailImage: json['thumbnail_image'],
      type: json['type'],
      section: json['section'],
      color: json['color'],
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (item) => ExamItemModel.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  String get fullLogoUrl {
    if (thumbnailImage == null || thumbnailImage!.isEmpty) return '';
    if (thumbnailImage!.startsWith('http')) return thumbnailImage!;
    final cleanPath = thumbnailImage!.startsWith('/')
        ? thumbnailImage!.substring(1)
        : thumbnailImage!;
    return 'https://digilogy-skyhigh.s3.eu-north-1.amazonaws.com/$cleanPath';
  }
}
