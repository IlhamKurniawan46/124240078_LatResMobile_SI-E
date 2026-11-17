import 'package:flutter_test/flutter_test.dart';
import 'package:latres/models/article_model.dart';
import 'package:latres/services/api_service.dart';

void main() {
  group('ArticleModel Tests', () {
    test('Correctly parses from real SNAPI v4 response JSON', () {
      final sampleJson = {
        'id': 40846,
        'title': 'Next Vega C Launch Edges Closer to Christmas Day',
        'authors': [
          {'name': 'European Spaceflight', 'socials': null}
        ],
        'url': 'https://europeanspaceflight.com/sample',
        'image_url': 'https://europeanspaceflight.com/sample.webp',
        'news_site': 'European Spaceflight',
        'summary': 'Italian rocket manufacturer Avio has revealed delays...',
        'published_at': '2026-11-14T06:00:41Z',
      };

      final article = ArticleModel.fromJson(sampleJson, defaultType: ContentType.news);

      expect(article.id, 40846);
      expect(article.title, 'Next Vega C Launch Edges Closer to Christmas Day');
      expect(article.author, 'European Spaceflight');
      expect(article.imageUrl, 'https://europeanspaceflight.com/sample.webp');
      expect(article.summary, startsWith('Italian rocket'));
      expect(article.publishedAt, '2026-11-14T06:00:41Z');
      expect(article.type, ContentType.news);
    });

    test('Falls back to authors list if news_site is null or empty', () {
      final sampleJson = {
        'id': 12345,
        'title': 'Test Article',
        'authors': [
          {'name': 'Author In List', 'socials': null}
        ],
        'news_site': '',
      };

      final article = ArticleModel.fromJson(sampleJson);
      expect(article.author, 'Author In List');
    });

    test('Serialization to/from JSON roundtrip preserves all fields', () {
      const original = ArticleModel(
        id: 999,
        title: 'Title Favorite',
        imageUrl: 'https://example.com/image.png',
        author: 'NASA',
        summary: 'Favorite summary',
        publishedAt: '2026-11-15T00:00:00Z',
        url: 'https://example.com/nasa',
        type: ContentType.blog,
      );

      final map = original.toJson();
      final restored = ArticleModel.fromJson(map);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.imageUrl, original.imageUrl);
      expect(restored.author, original.author);
      expect(restored.summary, original.summary);
      expect(restored.publishedAt, original.publishedAt);
      expect(restored.url, original.url);
      expect(restored.type, original.type);
    });
  });

  group('ApiService Live Integration Test', () {
    test('fetchList returns valid list of articles from SNAPI v4', () async {
      final apiService = ApiService();
      final articles = await apiService.fetchList(ContentType.news, limit: 2);

      expect(articles, isNotEmpty);
      expect(articles.length, lessThanOrEqualTo(2));
      expect(articles.first.id, isPositive);
      expect(articles.first.title, isNotEmpty);
      expect(articles.first.author, isNotEmpty);
      expect(articles.first.type, ContentType.news);
    });

    test('fetchDetail returns correct article', () async {
      final apiService = ApiService();
      final list = await apiService.fetchList(ContentType.news, limit: 1);
      expect(list, isNotEmpty);

      final detail = await apiService.fetchDetail(ContentType.news, list.first.id);
      expect(detail.id, list.first.id);
      expect(detail.title, list.first.title);
    });
  });
}
