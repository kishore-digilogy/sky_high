class TestimonialModel {
  final int id;
  final int userId;
  final String userName;
  final String? userRole;
  final String content;
  final int stars;
  final int likes;
  final String language;
  final int? categoryId;
  final bool isApproved;
  final DateTime createdAt;

  TestimonialModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userRole,
    required this.content,
    required this.stars,
    required this.likes,
    required this.language,
    this.categoryId,
    required this.isApproved,
    required this.createdAt,
  });

  factory TestimonialModel.fromJson(Map<String, dynamic> json) {
    return TestimonialModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      userName: json['user_name'] ?? 'Anonymous',
      userRole: json['user_role'],
      content: json['content'] ?? '',
      stars: json['stars'] ?? 0,
      likes: json['likes'] ?? 0,
      language: json['language'] ?? 'English',
      categoryId: json['category_id'],
      isApproved: (json['is_approved'] ?? 0) == 1,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  /// Returns initials from userName for avatar display
  String get initials {
    final parts = userName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return userName.isNotEmpty ? userName[0].toUpperCase() : '?';
  }

  /// Returns a human-readable time ago string
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
