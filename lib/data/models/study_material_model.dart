import 'package:sky_high/core/utils/localization_helper.dart';

class StudyMaterialModel {
  final int id;
  final String title;
  final String? category;
  final String fileType;
  final String filePath;
  final String fileName;
  final String? thumbnailPath;
  final String visibility;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? categoryId;
  final String language;
  final String? description;
  final String? categoryTitle;

  StudyMaterialModel({
    required this.id,
    required this.title,
    this.category,
    required this.fileType,
    required this.filePath,
    required this.fileName,
    this.thumbnailPath,
    required this.visibility,
    required this.createdAt,
    required this.updatedAt,
    this.categoryId,
    required this.language,
    this.description,
    this.categoryTitle,
  });

  factory StudyMaterialModel.fromJson(Map<String, dynamic> json) {
    return StudyMaterialModel(
      id: json['id'] ?? 0,
      title: LocalizationHelper.getLocalized(json, 'title'),
      category: LocalizationHelper.getLocalized(json, 'category'),
      fileType: json['fileType'] ?? json['file_type'] ?? 'pdf',
      filePath: json['filePath'] ?? json['file_path'] ?? '',
      fileName: json['fileName'] ?? json['file_name'] ?? '',
      thumbnailPath: json['thumbnailPath'] ?? json['thumbnail_path'],
      visibility: json['visibility'] ?? 'free',
      createdAt:
          DateTime.tryParse(json['createdAt'] ?? json['created_at'] ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] ?? json['updated_at'] ?? '') ??
          DateTime.now(),
      categoryId: json['category_id'],
      language: json['language'] ?? 'English',
      description: LocalizationHelper.getLocalized(json, 'description'),
      categoryTitle: LocalizationHelper.getLocalized(json, 'category_title'),
    );
  }

  String get displayCategory => categoryTitle ?? category ?? 'General';

  bool get isVideo => fileType.toLowerCase() == 'video';
  bool get isPdf => fileType.toLowerCase() == 'pdf';

  String get fullThumbnailUrl {
    if (thumbnailPath == null || thumbnailPath!.isEmpty) return '';
    final cleanPath = thumbnailPath!.startsWith('/')
        ? thumbnailPath!.substring(1)
        : thumbnailPath!;
    return 'https://skyhighedujobs.s3.ap-south-1.amazonaws.com/$cleanPath';
  }

  String get fullFileUrl {
    final cleanPath = filePath.startsWith('/')
        ? filePath.substring(1)
        : filePath;
    return 'https://skyhighedujobs.s3.ap-south-1.amazonaws.com/$cleanPath';
  }
}
