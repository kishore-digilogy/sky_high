import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sky_high/core/services/wiki_image_service.dart';

/// A widget that displays a relevant image for a category/department
/// fetched from Wikipedia based on the category name.
class CategoryIcon extends StatefulWidget {
  final String categoryName;
  final String fallbackEmoji;
  final Color backgroundColor;
  final double size;

  const CategoryIcon({
    super.key,
    required this.categoryName,
    required this.fallbackEmoji,
    required this.backgroundColor,
    this.size = 36,
  });

  @override
  State<CategoryIcon> createState() => _CategoryIconState();
}

class _CategoryIconState extends State<CategoryIcon> {
  late Future<String> _imageUrlFuture;

  @override
  void initState() {
    super.initState();
    _imageUrlFuture = WikiImageService().getImageUrl(widget.categoryName);
  }

  @override
  void didUpdateWidget(CategoryIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryName != widget.categoryName) {
      _imageUrlFuture = WikiImageService().getImageUrl(widget.categoryName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        shape: BoxShape.circle,
      ),
      child: FutureBuilder<String>(
        future: _imageUrlFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
              width: widget.size,
              height: widget.size,
              child: const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final imageUrl = snapshot.data ?? '';
          if (imageUrl.isEmpty) {
            return _buildFallback();
          }

          return CachedNetworkImage(
            imageUrl: imageUrl,
            width: widget.size,
            height: widget.size,
            fit: BoxFit.contain,
            placeholder: (context, url) => SizedBox(
              width: widget.size,
              height: widget.size,
              child: const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            errorWidget: (context, url, error) => _buildFallback(),
          );
        },
      ),
    );
  }

  Widget _buildFallback() {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Center(
        child: Text(
          widget.fallbackEmoji,
          style: TextStyle(fontSize: widget.size * 0.65),
        ),
      ),
    );
  }
}
