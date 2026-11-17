import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latres/models/article_model.dart';
import 'package:latres/screens/detail_screen.dart';
import 'package:latres/screens/favorite_screen.dart';
import 'package:latres/services/api_service.dart';
import 'package:latres/services/storage_service.dart';
import 'package:latres/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storageService = StorageService();
    await storageService.register('tester', 'password123');
    await storageService.login('tester', 'password123');
  });

  final sampleArticleJson = {
    'id': 101,
    'title': 'Falcon 9 Heavy Lift',
    'url': 'https://example.com/falcon9',
    'image_url': 'https://example.com/falcon9.jpg',
    'news_site': 'Spaceflight Now',
    'summary': 'A successful mission to orbit.',
    'published_at': '2026-11-18T05:00:00Z',
  };

  group('Favorite Synchronization End-to-End Tests', () {
    testWidgets(
        'Sync flow 1: Detail -> favoritkan -> FavoriteScreen menampilkan item',
        (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode(sampleArticleJson), 200);
      });
      final apiService = ApiService(client: mockClient);

      // Open DetailScreen
      await tester.pumpWidget(
        MaterialApp(
          home: DetailScreen(
            type: ContentType.news,
            id: 101,
            apiService: apiService,
            storageService: storageService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial state: not favorite
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);

      // Tap favorite icon
      await tester.tap(find.byKey(const Key('detail_favorite_button')));
      await tester.pumpAndSettle();

      // Heart turns red & SnackBar appears
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.text(AppConstants.addedToFavoriteMessage), findsOneWidget);

      // Verify stored in StorageService
      expect(await storageService.isFavorite(ContentType.news, 101), isTrue);

      // Open FavoriteScreen
      await tester.pumpWidget(
        MaterialApp(
          home: FavoriteScreen(
            apiService: apiService,
            storageService: storageService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Item should be displayed
      expect(find.text('Falcon 9 Heavy Lift'), findsOneWidget);
      expect(find.text('Spaceflight Now'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets(
        'Sync flow 2: Hapus di FavoriteScreen -> buka DetailScreen item sama (ikon hati kosong)',
        (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode(sampleArticleJson), 200);
      });
      final apiService = ApiService(client: mockClient);

      // Pre-populate favorite
      await storageService.addFavorite(const ArticleModel(
        id: 101,
        title: 'Falcon 9 Heavy Lift',
        imageUrl: 'https://example.com/falcon9.jpg',
        author: 'Spaceflight Now',
        summary: '',
        publishedAt: '',
        url: '',
        type: ContentType.news,
      ));

      // Open FavoriteScreen
      await tester.pumpWidget(
        MaterialApp(
          home: FavoriteScreen(
            apiService: apiService,
            storageService: storageService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Falcon 9 Heavy Lift'), findsOneWidget);

      // Tap red heart icon to remove
      final removeBtn =
          find.byKey(const Key('fav_remove_btn_news_101'));
      expect(removeBtn, findsOneWidget);
      await tester.tap(removeBtn);
      await tester.pumpAndSettle();

      // SnackBar feedback
      expect(
          find.text(AppConstants.removedFromFavoriteMessage), findsOneWidget);

      // List immediately clears the item
      expect(find.text('Falcon 9 Heavy Lift'), findsNothing);
      expect(find.text('Belum ada data favorit.'), findsOneWidget);
      expect(await storageService.isFavorite(ContentType.news, 101), isFalse);

      // Now open DetailScreen for that same item
      await tester.pumpWidget(
        MaterialApp(
          home: DetailScreen(
            type: ContentType.news,
            id: 101,
            apiService: apiService,
            storageService: storageService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Heart icon in DetailScreen is empty (favorite_border)
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNothing);
    });

    testWidgets(
        'Sync flow 3: FavoriteScreen -> DetailScreen -> un-favorite -> Back -> item hilang',
        (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode(sampleArticleJson), 200);
      });
      final apiService = ApiService(client: mockClient);

      // Pre-populate favorite
      await storageService.addFavorite(const ArticleModel(
        id: 101,
        title: 'Falcon 9 Heavy Lift',
        imageUrl: 'https://example.com/falcon9.jpg',
        author: 'Spaceflight Now',
        summary: '',
        publishedAt: '',
        url: '',
        type: ContentType.news,
      ));

      // Open FavoriteScreen within Navigator
      await tester.pumpWidget(
        MaterialApp(
          home: FavoriteScreen(
            apiService: apiService,
            storageService: storageService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Falcon 9 Heavy Lift'), findsOneWidget);

      // Tap item card to navigate to DetailScreen
      final cardFinder = find.byKey(const Key('fav_card_news_101'));
      expect(cardFinder, findsOneWidget);
      await tester.tap(cardFinder);
      await tester.pumpAndSettle();

      // We are now on DetailScreen
      expect(find.text('Detail News'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);

      // Un-favorite by tapping favorite button in Detail
      await tester.tap(find.byKey(const Key('detail_favorite_button')));
      await tester.pumpAndSettle();

      // Heart is now empty
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(
          find.text(AppConstants.removedFromFavoriteMessage), findsOneWidget);

      // Press Back button in AppBar
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      // We are back on FavoriteScreen
      expect(find.text('Favorite Content'), findsOneWidget);
      // Item must be gone because _loadFavorites was called on return
      expect(find.text('Falcon 9 Heavy Lift'), findsNothing);
      expect(find.text('Belum ada data favorit.'), findsOneWidget);
    });

    testWidgets(
        'FavoriteScreen renders mixed content types (news, blog, report) together',
        (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode(sampleArticleJson), 200);
      });
      final apiService = ApiService(client: mockClient);

      // Add news, blog, and report items
      await storageService.addFavorite(const ArticleModel(
        id: 1,
        title: 'News Headline',
        author: 'News Reporter',
        summary: '',
        publishedAt: '',
        url: '',
        type: ContentType.news,
      ));
      await storageService.addFavorite(const ArticleModel(
        id: 2,
        title: 'Blog Story',
        author: 'Blogger Bob',
        summary: '',
        publishedAt: '',
        url: '',
        type: ContentType.blog,
      ));
      await storageService.addFavorite(const ArticleModel(
        id: 3,
        title: 'Mission Report',
        author: 'NASA Station',
        summary: '',
        publishedAt: '',
        url: '',
        type: ContentType.report,
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: FavoriteScreen(
            apiService: apiService,
            storageService: storageService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('News Headline'), findsOneWidget);
      expect(find.text('News Reporter'), findsOneWidget);

      expect(find.text('Blog Story'), findsOneWidget);
      expect(find.text('Blogger Bob'), findsOneWidget);

      expect(find.text('Mission Report'), findsOneWidget);
      expect(find.text('NASA Station'), findsOneWidget);
    });
  });
}
