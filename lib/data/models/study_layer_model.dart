import 'package:intl/intl.dart';
import 'dart:convert';

class StudyLayerModel {
  final int id;
  final String layer;
  final String title;
  final String? titleTa, titleTe, titleKn, titleMl;
  final String? content;
  final String? contentTa, contentTe, contentKn, contentMl;
  final String? url;
  final String? urlTa, urlTe, urlKn, urlMl;
  final String visibility;
  final int orderIndex;
  final String? createdAt;
  final String? updatedAt;
  final String? chapterName;
  final String? topicName;
  final int? subJobId;
  final int? jobId;
  final int? isActive;
  final List<String> imagesGallery;

  StudyLayerModel({
    required this.id,
    required this.layer,
    required this.title,
    this.titleTa,
    this.titleTe,
    this.titleKn,
    this.titleMl,
    this.content,
    this.contentTa,
    this.contentTe,
    this.contentKn,
    this.contentMl,
    this.url,
    this.urlTa,
    this.urlTe,
    this.urlKn,
    this.urlMl,
    required this.visibility,
    required this.orderIndex,
    this.createdAt,
    this.updatedAt,
    this.chapterName,
    this.topicName,
    this.subJobId,
    this.jobId,
    this.isActive,
    this.imagesGallery = const [],
  });

  factory StudyLayerModel.fromJson(Map<String, dynamic> json) {
    return StudyLayerModel(
      id: json['id'] ?? 0,
      layer: json['layer'] ?? '',
      title: json['title'] ?? '',
      titleTa: json['title_ta'],
      titleTe: json['title_te'],
      titleKn: json['title_kn'],
      titleMl: json['title_ml'],
      content: json['content'],
      contentTa: json['content_ta'],
      contentTe: json['content_te'],
      contentKn: json['content_kn'],
      contentMl: json['content_ml'],
      url: json['url'],
      urlTa: json['url_ta'],
      urlTe: json['url_te'],
      urlKn: json['url_kn'],
      urlMl: json['url_ml'],
      visibility: json['visibility'] ?? 'paid',
      orderIndex: json['order_index'] ?? 0,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      chapterName: json['chapter_name'],
      topicName: json['topic_name'],
      subJobId: json['sub_job_id'],
      jobId: json['job_id'],
      isActive: json['is_active'],
      imagesGallery: _parseImagesGallery(json['images_gallery']),
    );
  }

  static List<String> _parseImagesGallery(dynamic data) {
    if (data == null) return [];
    if (data is String) {
      try {
        final decoded = json.decode(data);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (e) {
        return [];
      }
    }
    if (data is List) {
      return data.map((e) => e.toString()).toList();
    }
    return [];
  }

  String getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return 'https://digilogy-skyhigh.s3.eu-north-1.amazonaws.com/$cleanPath';
  }

  String getLocalizedTitle(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'ta':
        return titleTa ?? title;
      case 'te':
        return titleTe ?? title;
      case 'kn':
        return titleKn ?? title;
      case 'ml':
        return titleMl ?? title;
      default:
        return title;
    }
  }

  String? getLocalizedContent(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'ta':
        return contentTa ?? content;
      case 'te':
        return contentTe ?? content;
      case 'kn':
        return contentKn ?? content;
      case 'ml':
        return contentMl ?? content;
      default:
        return content;
    }
  }

  String? getLocalizedUrl(String langCode) {
    String? resolvedUrl;
    switch (langCode.toLowerCase()) {
      case 'ta':
        resolvedUrl = urlTa ?? url;
        break;
      case 'te':
        resolvedUrl = urlTe ?? url;
        break;
      case 'kn':
        resolvedUrl = urlKn ?? url;
        break;
      case 'ml':
        resolvedUrl = urlMl ?? url;
        break;
      default:
        resolvedUrl = url;
        break;
    }

    if (resolvedUrl == null || resolvedUrl.isEmpty) return null;
    if (resolvedUrl.startsWith('http')) return resolvedUrl;
    final cleanPath = resolvedUrl.startsWith('/')
        ? resolvedUrl.substring(1)
        : resolvedUrl;
    return 'https://digilogy-skyhigh.s3.eu-north-1.amazonaws.com/$cleanPath';
  }

  String getFormattedDate() {
    final dateStr = updatedAt ?? createdAt;
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return '';
    }
  }

  bool get isFree => visibility.toLowerCase() == 'free';

  int get moduleNumber {
    switch (layer.toLowerCase()) {
      case 'basic_info':
        return 1;
      case 'syllabus':
        return 2;
      case 'preparation_plan':
        return 3;
      case 'notes':
        return 4;
      case 'video':
        return 7;
      default:
        return 0;
    }
  }
}
