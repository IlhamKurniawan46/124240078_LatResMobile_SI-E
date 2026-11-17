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
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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
      expect(find.text('NASASpaceflight'), findsWidgets);
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
      expect(find.text('NASASpaceflight'), findsWidgets);

      // Check article 2 with null image (fallback icon)
      expect(
          find.text('NASA Prepares Artemis II Astronauts for Moon Mission'),
          findsOneWidget);
      expect(find.text('NASA'), findsWidgets);
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
      final detailWidget =
          tester.widget<DetailScreen>(find.byType(DetailScreen));
      expect(detailWidget.type, ContentType.news);
      expect(detailWidget.id, 101);
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

    testWidgets('Extracts unique authors alphabetically and renders FilterChips',
        (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'count': sampleArticles.length, 'results': sampleArticles}),
          200,
        );
      });
      final apiService = ApiService(client: mockClient);

      await tester.pumpWidget(createWidgetUnderTest(apiService: apiService));
      await tester.pumpAndSettle();

      // sampleArticles has 'NASASpaceflight' and 'NASA'. Alphabetical order: 'NASA', 'NASASpaceflight'
      expect(find.byType(FilterChip), findsNWidgets(2));
      expect(find.text('NASA'), findsWidgets);
      expect(find.text('NASASpaceflight'), findsWidgets);
    });

    testWidgets(
        'Selecting a chip filters articles, shows checkmark, and tapping again deselects to show all',
        (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'count': sampleArticles.length, 'results': sampleArticles}),
          200,
        );
      });
      final apiService = ApiService(client: mockClient);

      await tester.pumpWidget(createWidgetUnderTest(apiService: apiService));
      await tester.pumpAndSettle();

      // Initially both articles are shown
      expect(find.text('SpaceX Launches Starship Flight 6'), findsOneWidget);
      expect(find.text('NASA Prepares Artemis II Astronauts for Moon Mission'),
          findsOneWidget);

      // Select 'NASA' chip
      await tester.tap(find.byKey(const Key('filter_chip_NASA')));
      await tester.pumpAndSettle();

      // Only NASA article is visible
      expect(find.text('NASA Prepares Artemis II Astronauts for Moon Mission'),
          findsOneWidget);
      expect(find.text('SpaceX Launches Starship Flight 6'), findsNothing);

      // Tap 'NASA' chip again to deselect
      await tester.tap(find.byKey(const Key('filter_chip_NASA')));
      await tester.pumpAndSettle();

      // Both articles visible again
      expect(find.text('SpaceX Launches Starship Flight 6'), findsOneWidget);
      expect(find.text('NASA Prepares Artemis II Astronauts for Moon Mission'),
          findsOneWidget);
    });

    testWidgets('Filter state is preserved after returning from DetailScreen',
        (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/101/')) {
          return http.Response(jsonEncode(sampleArticles[0]), 200);
        }
        return http.Response(
          jsonEncode({'count': sampleArticles.length, 'results': sampleArticles}),
          200,
        );
      });
      final apiService = ApiService(client: mockClient);

      await tester.pumpWidget(createWidgetUnderTest(apiService: apiService));
      await tester.pumpAndSettle();

      // Select 'NASASpaceflight' chip
      await tester.tap(find.byKey(const Key('filter_chip_NASASpaceflight')));
      await tester.pumpAndSettle();

      expect(find.text('SpaceX Launches Starship Flight 6'), findsOneWidget);
      expect(find.text('NASA Prepares Artemis II Astronauts for Moon Mission'),
          findsNothing);

      // Tap card to open DetailScreen
      await tester.tap(find.text('SpaceX Launches Starship Flight 6'));
      await tester.pumpAndSettle();

      expect(find.byType(DetailScreen), findsOneWidget);

      // Pop back to ListScreen
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.byType(ListScreen), findsOneWidget);
      // Filter is still preserved
      expect(find.text('SpaceX Launches Starship Flight 6'), findsOneWidget);
      expect(find.text('NASA Prepares Artemis II Astronauts for Moon Mission'),
          findsNothing);
    });
  });
}
