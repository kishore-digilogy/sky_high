import 'package:dio/dio.dart';

/// Service that fetches relevant thumbnail images from Wikipedia
/// based on a search term (e.g. category/department name).
class WikiImageService {
  static final WikiImageService _instance = WikiImageService._internal();
  factory WikiImageService() => _instance;
  WikiImageService._internal();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );
  final String _baseUrl = 'https://en.wikipedia.org/w/api.php';

  // In-memory cache: searchTerm → imageUrl
  final Map<String, String> _cache = {};

  // Keywords to append for better search results for Indian govt categories
  static const _searchHints = {
    'navratna': 'Navratna public sector India',
    'miniratna': 'Miniratna public sector India',
    'maharatna': 'Maharatna public sector India',
    'cpse': 'Central Public Sector Enterprises India',
    'railway': 'Indian Railways',
    'tamil nadu': 'Government of Tamil Nadu',
    'telangana': 'Government of Telangana',
    'andhra pradesh': 'Government of Andhra Pradesh',
    'karnataka': 'Government of Karnataka',
    'keralam': 'Government of Kerala',
    'kerala': 'Government of Kerala',
  };

  /// Returns a Wikipedia thumbnail URL for the given [searchTerm],
  /// or an empty string if not found.
  Future<String> getImageUrl(String searchTerm) async {
    // Return cached result if available
    if (_cache.containsKey(searchTerm)) {
      return _cache[searchTerm]!;
    }

    try {
      // Try to find a better search query based on known keywords
      final query = _buildSearchQuery(searchTerm);

      // Step 1: Search Wikipedia for the term
      final searchResponse = await _dio.get(
        _baseUrl,
        queryParameters: {
          'action': 'query',
          'list': 'search',
          'srsearch': query,
          'format': 'json',
          'srlimit': '1',
        },
      );

      final searchResults = searchResponse.data['query']?['search'] as List?;
      if (searchResults == null || searchResults.isEmpty) {
        _cache[searchTerm] = '';
        return '';
      }

      final pageTitle = searchResults[0]['title'] as String;

      // Step 2: Get the page image (with pilicense=any to include logos)
      final imageResponse = await _dio.get(
        _baseUrl,
        queryParameters: {
          'action': 'query',
          'titles': pageTitle,
          'prop': 'pageimages',
          'format': 'json',
          'pithumbsize': '200',
          'piprop': 'thumbnail',
          'pilicense': 'any',
        },
      );

      final pages = imageResponse.data['query']?['pages'] as Map?;
      if (pages == null || pages.isEmpty) {
        _cache[searchTerm] = '';
        return '';
      }

      final page = pages.values.first as Map;
      final thumbnail = page['thumbnail'] as Map?;
      final imageUrl = thumbnail?['source'] as String? ?? '';

      _cache[searchTerm] = imageUrl;
      return imageUrl;
    } catch (e) {
      _cache[searchTerm] = '';
      return '';
    }
  }

  /// Builds a more targeted Wikipedia search query from the category title
  String _buildSearchQuery(String title) {
    final lower = title.toLowerCase();
    for (final entry in _searchHints.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    // Fallback: use the title directly with "India" appended
    return '$title India';
  }
}
