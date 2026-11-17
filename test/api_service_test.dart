import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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

  group('ApiService Mock Client Tests', () {
    test('fetchList parses mock HTTP response correctly with limit parameter', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/v4/articles/');
        expect(request.url.queryParameters['limit'], '50');

        return http.Response(
          jsonEncode({
            'count': 1,
            'results': [
              {
                'id': 1001,
                'title': 'Mock Article Title',
                'url': 'https://example.com/article',
                'image_url': 'https://example.com/image.png',
                'news_site': 'NASASpaceflight',
                'summary': 'Mock summary',
                'published_at': '2026-11-18T00:00:00Z',
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiService = ApiService(client: mockClient);
      final list = await apiService.fetchList(ContentType.news, limit: 50);

      expect(list.length, 1);
      expect(list.first.id, 1001);
      expect(list.first.title, 'Mock Article Title');
      expect(list.first.author, 'NASASpaceflight');
      expect(list.first.type, ContentType.news);
    });

    test('fetchDetail parses mock detail response correctly by ID', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/v4/blogs/502/');

        return http.Response(
          jsonEncode({
            'id': 502,
            'title': 'Mock Blog Detail',
            'url': 'https://example.com/blog',
            'image_url': 'https://example.com/blog.png',
            'news_site': 'SpaceX',
            'summary': 'Mock blog summary detail',
            'published_at': '2026-11-18T01:00:00Z',
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiService = ApiService(client: mockClient);
      final detail = await apiService.fetchDetail(ContentType.blog, 502);

      expect(detail.id, 502);
      expect(detail.title, 'Mock Blog Detail');
      expect(detail.author, 'SpaceX');
      expect(detail.type, ContentType.blog);
    });

    test('fetchDetail throws ApiException on 404', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      final apiService = ApiService(client: mockClient);
      expect(
        () => apiService.fetchDetail(ContentType.news, 999999),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
