import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latres/models/article_model.dart';
import 'package:latres/screens/detail_screen.dart';
import 'package:latres/services/api_service.dart';
import 'package:latres/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final sampleArticleJson = {
    'id': 40846,
    'title': 'Next Vega C Launch Edges Closer to Christmas Day',
    'url': 'https://europeanspaceflight.com/sample',
    'image_url': 'https://europeanspaceflight.com/sample.webp',
    'news_site': 'European Spaceflight',
    'summary': 'Italian rocket manufacturer Avio has revealed delays...',
    'published_at': '2026-11-14T06:00:41Z',
  };

  Widget createWidgetUnderTest({
    ContentType type = ContentType.news,
    int id = 40846,
    required ApiService apiService,
    Future<bool> Function(Uri, {LaunchMode mode})? urlLauncher,
  }) {
    return MaterialApp(
      home: DetailScreen(
        type: type,
        id: id,
        apiService: apiService,
        urlLauncher: urlLauncher,
      ),
    );
  }

  group('DetailScreen Widget Tests', () {
    testWidgets('Displays loading indicator while fetching detail',
        (tester) async {
      final mockClient = MockClient((request) async {
        await Future.delayed(const Duration(milliseconds: 200));
        return http.Response(jsonEncode(sampleArticleJson), 200);
      });
      final apiService = ApiService(client: mockClient);

      await tester.pumpWidget(
        createWidgetUnderTest(apiService: apiService),
      );

      expect(find.byKey(const Key('detail_loading_indicator')), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byKey(const Key('detail_loading_indicator')), findsNothing);
    });

    testWidgets(
        'Displays error state and retry button on failure, retry successfully fetches',
        (tester) async {
      int attempts = 0;
      final mockClient = MockClient((request) async {
        attempts++;
        if (attempts == 1) {
          return http.Response('Not Found', 404);
        }
        return http.Response(jsonEncode(sampleArticleJson), 200);
      });
      final apiService = ApiService(client: mockClient);

      await tester.pumpWidget(
        createWidgetUnderTest(apiService: apiService),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('detail_retry_button')), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);

      // Tap retry
      await tester.tap(find.byKey(const Key('detail_retry_button')));
      await tester.pumpAndSettle();

      expect(
        find.text('Next Vega C Launch Edges Closer to Christmas Day'),
        findsOneWidget,
      );
    });

    testWidgets(
        'Renders title, author (news_site), ISO published_at, and summary',
        (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode(sampleArticleJson), 200);
      });
      final apiService = ApiService(client: mockClient);

      await tester.pumpWidget(
        createWidgetUnderTest(
          type: ContentType.news,
          id: 40846,
          apiService: apiService,
        ),
      );
      await tester.pumpAndSettle();

      // AppBar title
      expect(find.text('Detail News'), findsOneWidget);

      // Title
      expect(
        find.text('Next Vega C Launch Edges Closer to Christmas Day'),
        findsOneWidget,
      );

      // Author / Publisher
      expect(find.text('European Spaceflight'), findsOneWidget);

      // Published At (ISO string apa adanya)
      expect(find.text('2026-11-14T06:00:41Z'), findsOneWidget);

      // Summary
      expect(
        find.text('Italian rocket manufacturer Avio has revealed delays...'),
        findsOneWidget,
      );
    });

    testWidgets('Fallback broken_image icon is rendered when image is null',
        (tester) async {
      final nullImageJson = Map<String, dynamic>.from(sampleArticleJson);
      nullImageJson['image_url'] = null;

      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode(nullImageJson), 200);
      });
      final apiService = ApiService(client: mockClient);

      await tester.pumpWidget(
        createWidgetUnderTest(apiService: apiService),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.broken_image), findsOneWidget);
    });

    testWidgets('AppBar favorite heart icon toggles local state in this session',
        (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode(sampleArticleJson), 200);
      });
      final apiService = ApiService(client: mockClient);

      await tester.pumpWidget(
        createWidgetUnderTest(apiService: apiService),
      );
      await tester.pumpAndSettle();

      // Initial state: favorite_border
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNothing);

      // Tap favorite icon to toggle on
      await tester.tap(find.byKey(const Key('detail_favorite_button')));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsNothing);

      // Tap again to toggle off
      await tester.tap(find.byKey(const Key('detail_favorite_button')));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets(
        'FAB "open in new" with tooltip "Buka Web" launches url in externalApplication mode',
        (tester) async {
      Uri? launchedUri;
      LaunchMode? usedMode;

      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode(sampleArticleJson), 200);
      });
      final apiService = ApiService(client: mockClient);

      await tester.pumpWidget(
        createWidgetUnderTest(
          apiService: apiService,
          urlLauncher: (uri, {mode = LaunchMode.platformDefault}) async {
            launchedUri = uri;
            usedMode = mode;
            return true;
          },
        ),
      );
      await tester.pumpAndSettle();

      // Verify FAB exists with tooltip and icon
      final fabFinder = find.byKey(const Key('detail_open_web_fab'));
      expect(fabFinder, findsOneWidget);
      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
      final fabWidget = tester.widget<FloatingActionButton>(fabFinder);
      expect(fabWidget.tooltip, 'Buka Web');

      // Tap FAB
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      expect(launchedUri, Uri.parse('https://europeanspaceflight.com/sample'));
      expect(usedMode, LaunchMode.externalApplication);
    });

    testWidgets('Shows red SnackBar when url_launcher fails', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode(sampleArticleJson), 200);
      });
      final apiService = ApiService(client: mockClient);

      await tester.pumpWidget(
        createWidgetUnderTest(
          apiService: apiService,
          urlLauncher: (uri, {mode = LaunchMode.platformDefault}) async {
            return false; // simulate launch failure
          },
        ),
      );
      await tester.pumpAndSettle();

      // Tap FAB
      await tester.tap(find.byKey(const Key('detail_open_web_fab')));
      await tester.pumpAndSettle();

      // SnackBar with consistent error message should appear
      expect(find.text(AppConstants.openWebErrorMessage), findsOneWidget);
      expect(find.text('Gagal membuka tautan web'), findsOneWidget);
    });
  });
}
