import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latres/models/article_model.dart';
import 'package:latres/screens/detail_screen.dart';
import 'package:latres/screens/favorite_screen.dart';
import 'package:latres/screens/list_screen.dart';
import 'package:latres/services/api_service.dart';

void main() {
  final sampleArticles = [
    {
      'id': 101,
      'title': 'SpaceX Launches Starship Flight 6',
      'url': 'https://example.com/spacex-starship',
      'image_url': 'https://example.com/starship.jpg',
      'news_site': 'NASASpaceflight',
      'summary': 'Starship Flight 6 lifted off successfully...',
      'published_at': '2026-11-18T10:00:00Z',
    },
    {
      'id': 102,
      'title': 'NASA Prepares Artemis II Astronauts for Moon Mission',
      'url': 'https://example.com/artemis-2',
      'image_url': null,
      'news_site': 'NASA',
      'summary': 'Astronauts are training for deep space...',
      'published_at': '2026-11-17T12:00:00Z',
    },
  ];

  Widget createWidgetUnderTest({
    ContentType type = ContentType.news,
    required ApiService apiService,
  }) {
    return MaterialApp(
      home: ListScreen(
        type: type,
        apiService: apiService,
      ),
    );
  }

  group('ListScreen Tests', () {
    testWidgets('Displays AppBar title according to ContentType',
        (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'count': 0, 'results': []}),
          200,
        );
      });
      final apiService = ApiService(client: mockClient);

      await tester.pumpWidget(
        createWidgetUnderTest(
          type: ContentType.blog,
          apiService: apiService,
        ),
      );

      expect(find.text('Blog'), findsOneWidget);
      expect(find.byKey(const Key('list_favorite_button')), findsOneWidget);
    });

    testWidgets('Displays loading indicator while fetching', (tester) async {
      final mockClient = MockClient((request) async {
        // Delay response
        await Future.delayed(const Duration(milliseconds: 200));
        return http.Response(
          jsonEncode({'count': 0, 'results': []}),
          200,
        );
      });
      final apiService = ApiService(client: mockClient);

      await tester.pumpWidget(
        createWidgetUnderTest(
          type: ContentType.news,
          apiService: apiService,
        ),
      );

      // Immediately after pump, it should be in loading state
      expect(find.byKey(const Key('list_loading_indicator')), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byKey(const Key('list_loading_indicator')), findsNothing);
    });

    testWidgets('Displays empty state message when results are empty',
        (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'count': 0, 'results': []}),
          200,
        );
      });
      final apiService = ApiService(client: mockClient);

      await tester.pumpWidget(
        createWidgetUnderTest(apiService: apiService),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('list_empty_text')), findsOneWidget);
      expect(find.text('Belum ada data tersedia saat ini.'), findsOneWidget);
    });

    testWidgets(
        'Displays error state and "Coba lagi" button on network failure, retry works',
        (tester) async {
      int attempts = 0;
      final mockClient = MockClient((request) async {
        attempts++;
        if (attempts == 1) {
          return http.Response('Server Error', 500);
        }
        return http.Response(
          jsonEncode({'count': sampleArticles.length, 'results': sampleArticles}),
          200,
        );
      });
      final apiService = ApiService(client: mockClient);

      await tester.pumpWidget(
        createWidgetUnderTest(apiService: apiService),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('list_retry_button')), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);

      // Tap "Coba lagi"
      await tester.tap(find.byKey(const Key('list_retry_button')));
      await tester.pumpAndSettle();

      // Now data should be loaded successfully
      expect(find.text('SpaceX Launches Starship Flight 6'), findsOneWidget);
      expect(find.text('NASASpaceflight'), findsOneWidget);
    });

    testWidgets(
        'Renders cards with thumbnail (fallback for null), 2-line title, and author',
        (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'count': sampleArticles.length, 'results': sampleArticles}),
          200,
        );
      });
      final apiService = ApiService(client: mockClient);

      await tester.pumpWidget(
        createWidgetUnderTest(apiService: apiService),
      );
      await tester.pumpAndSettle();

      // Check article 1
      expect(find.text('SpaceX Launches Starship Flight 6'), findsOneWidget);
      expect(find.text('NASASpaceflight'), findsOneWidget);

      // Check article 2 with null image (fallback icon)
      expect(
          find.text('NASA Prepares Artemis II Astronauts for Moon Mission'),
          findsOneWidget);
      expect(find.text('NASA'), findsOneWidget);
      expect(find.byIcon(Icons.broken_image), findsAtLeastNWidgets(1));
    });

    testWidgets('Tapping favorite icon navigates to FavoriteScreen',
        (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'count': 0, 'results': []}),
          200,
        );
      });
      final apiService = ApiService(client: mockClient);

      await tester.pumpWidget(
        createWidgetUnderTest(apiService: apiService),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('list_favorite_button')));
      await tester.pumpAndSettle();

      expect(find.byType(FavoriteScreen), findsOneWidget);
      expect(find.text('Favorite Content'), findsOneWidget);
    });

    testWidgets('Tapping item card navigates to DetailScreen with type and id',
        (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'count': sampleArticles.length, 'results': sampleArticles}),
          200,
        );
      });
      final apiService = ApiService(client: mockClient);

      await tester.pumpWidget(
        createWidgetUnderTest(
          type: ContentType.news,
          apiService: apiService,
        ),
      );
      await tester.pumpAndSettle();

      // Tap the first item card
      await tester.tap(find.text('SpaceX Launches Starship Flight 6'));
      await tester.pumpAndSettle();

      expect(find.byType(DetailScreen), findsOneWidget);
      expect(
        find.textContaining('Detail Screen Placeholder (type: news, id: 101)'),
        findsOneWidget,
      );
    });

    testWidgets('Pull to refresh re-fetches articles', (tester) async {
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        return http.Response(
          jsonEncode({'count': sampleArticles.length, 'results': sampleArticles}),
          200,
        );
      });
      final apiService = ApiService(client: mockClient);

      await tester.pumpWidget(
        createWidgetUnderTest(apiService: apiService),
      );
      await tester.pumpAndSettle();

      expect(requestCount, 1);

      // Perform fling down to trigger RefreshIndicator
      await tester.fling(
        find.text('SpaceX Launches Starship Flight 6'),
        const Offset(0.0, 300.0),
        1000.0,
      );
      await tester.pumpAndSettle();

      expect(requestCount, 2);
    });
  });
}
