enum ContentType {
  news,
  blog,
  report;

  /// Returns the corresponding SNAPI v4 endpoint segment
  String get endpoint {
    switch (this) {
      case ContentType.news:
        return 'articles';
      case ContentType.blog:
        return 'blogs';
      case ContentType.report:
        return 'reports';
    }
  }

  /// Returns category name
  String get displayName {
    switch (this) {
      case ContentType.news:
        return 'News';
      case ContentType.blog:
        return 'Blog';
      case ContentType.report:
        return 'Reports';
    }
  }
}
