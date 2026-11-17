import 'content_type.dart';
export 'content_type.dart';

/// Generic data model for Spaceflight News API content (news, blog, report).
class ArticleModel {
  final int id;
  final String title;
  final String? imageUrl;
  final String author;
  final String summary;
  final String publishedAt;
  final String url;
  final ContentType type;

  const ArticleModel({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.author,
    required this.summary,
    required this.publishedAt,
    required this.url,
    required this.type,
  });

  /// Factory to parse from API JSON or local SharedPreferences JSON.
  /// 
  /// Per PRD & SNAPI v4 response verification, [author] is extracted from `news_site`.
  /// A fallback to `author`, `authors[0].name`, or 'Unknown' is included for robustness.
  factory ArticleModel.fromJson(
    Map<String, dynamic> json, {
    ContentType? defaultType,
  }) {
    // Resolve ContentType
    ContentType resolvedType = defaultType ?? ContentType.news;
    if (json['type'] != null) {
      final typeString = json['type'].toString().trim().toLowerCase();
      for (final val in ContentType.values) {
        if (val.name.toLowerCase() == typeString) {
          resolvedType = val;
          break;
        }
      }
    }

    // Resolve author: prioritized from 'news_site', with fallback to 'author' or authors list
    String resolvedAuthor = 'Unknown';
    if (json['news_site'] != null &&
        json['news_site'].toString().trim().isNotEmpty) {
      resolvedAuthor = json['news_site'].toString().trim();
    } else if (json['author'] != null &&
        json['author'].toString().trim().isNotEmpty) {
      resolvedAuthor = json['author'].toString().trim();
    } else if (json['authors'] is List && (json['authors'] as List).isNotEmpty) {
      final first = (json['authors'] as List).first;
      if (first is Map && first['name'] != null) {
        resolvedAuthor = first['name'].toString().trim();
      }
    }

    return ArticleModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String?,
      author: resolvedAuthor,
      summary: json['summary'] as String? ?? '',
      publishedAt: json['published_at'] as String? ??
          json['publishedAt'] as String? ??
          '',
      url: json['url'] as String? ?? '',
      type: resolvedType,
    );
  }

  /// Converts the model to JSON Map (used for persisting favorites in SharedPreferences)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'author': author,
      'summary': summary,
      'publishedAt': publishedAt,
      'url': url,
      'type': type.name,
    };
  }

  factory ArticleModel.fromMap(Map<String, dynamic> map) =>
      ArticleModel.fromJson(map);

  Map<String, dynamic> toMap() => toJson();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArticleModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type;

  @override
  int get hashCode => id.hashCode ^ type.hashCode;

  @override
  String toString() {
    return 'ArticleModel(id: $id, title: $title, author: $author, type: ${type.name})';
  }
}
