import 'package:flutter_test/flutter_test.dart';
import 'package:latres/models/article_model.dart';
import 'package:latres/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('StorageService Auth & Session Tests', () {
    test('register adds user successfully', () async {
      final storage = StorageService();

      final success = await storage.register('rahman', 'password123');
      expect(success, isTrue);

      final users = await storage.getRegisteredUsers();
      expect(users.length, 1);
      expect(users.first.username, 'rahman');
      expect(users.first.password, 'password123');
    });

    test('register rejects duplicate username (case-insensitive)', () async {
      final storage = StorageService();

      final first = await storage.register('rahman', 'pass1');
      expect(first, isTrue);

      // Exact match
      final duplicateExact = await storage.register('rahman', 'pass2');
      expect(duplicateExact, isFalse);

      // Case-insensitive match
      final duplicateCase = await storage.register('RAHMAN', 'pass3');
      expect(duplicateCase, isFalse);

      final users = await storage.getRegisteredUsers();
      expect(users.length, 1);
    });

    test('register rejects empty username or password', () async {
      final storage = StorageService();

      expect(await storage.register('', 'pass'), isFalse);
      expect(await storage.register('user', ''), isFalse);
      expect(await storage.register('   ', '   '), isFalse);
    });

    test('login with wrong credentials fails and does not set session', () async {
      final storage = StorageService();
      await storage.register('rahman', 'secret');

      // Wrong username
      expect(await storage.login('unknown', 'secret'), isFalse);
      expect(await storage.isLoggedIn(), isFalse);

      // Wrong password
      expect(await storage.login('rahman', 'wrong'), isFalse);
      expect(await storage.isLoggedIn(), isFalse);
    });

    test('login with correct credentials succeeds and saves session', () async {
      final storage = StorageService();
      await storage.register('rahman', 'secret');

      final result = await storage.login('rahman', 'secret');
      expect(result, isTrue);

      expect(await storage.isLoggedIn(), isTrue);
      expect(await storage.getCurrentUser(), 'rahman');
    });

    test('auto-login simulation: session persists across new service instances', () async {
      final storage1 = StorageService();
      await storage1.register('budi', 'budi123');
      await storage1.login('budi', 'budi123');

      // Simulate app restart by creating a new StorageService instance
      final storage2 = StorageService();
      expect(await storage2.isLoggedIn(), isTrue);
      expect(await storage2.getCurrentUser(), 'budi');
    });

    test('logout clears active login session', () async {
      final storage = StorageService();
      await storage.register('siti', 'siti123');
      await storage.login('siti', 'siti123');
      expect(await storage.isLoggedIn(), isTrue);

      await storage.logout();

      expect(await storage.isLoggedIn(), isFalse);
      expect(await storage.getCurrentUser(), isNull);
    });
  });

  group('StorageService Favorite Management Tests', () {
    test('addFavorite and getFavorites persists items per-user with composite identity', () async {
      final storage = StorageService();
      await storage.register('rahman', 'pass123');
      await storage.login('rahman', 'pass123');

      final article = const ArticleModel(
        id: 101,
        title: 'Starship Launch',
        imageUrl: 'https://img.com/101.jpg',
        author: 'SpaceX',
        summary: 'Flight test 6',
        publishedAt: '2026-11-18',
        url: 'https://starship.com',
        type: ContentType.news,
      );

      final added = await storage.addFavorite(article);
      expect(added, isTrue);

      expect(await storage.isFavorite(ContentType.news, 101), isTrue);
      expect(await storage.isFavorite(ContentType.blog, 101), isFalse);

      final favs = await storage.getFavorites();
      expect(favs.length, 1);
      expect(favs.first.id, 101);
      expect(favs.first.type, ContentType.news);
      expect(favs.first.title, 'Starship Launch');
      expect(favs.first.author, 'SpaceX');
      expect(favs.first.imageUrl, 'https://img.com/101.jpg');
    });

    test('Items with same id but different types do not overwrite each other', () async {
      final storage = StorageService();
      await storage.register('rahman', 'pass123');
      await storage.login('rahman', 'pass123');

      final news101 = const ArticleModel(
        id: 101,
        title: 'News 101',
        imageUrl: 'https://img.com/n101.jpg',
        author: 'News Author',
        summary: 'News summary',
        publishedAt: '2026-11-18',
        url: 'https://news.com',
        type: ContentType.news,
      );

      final blog101 = const ArticleModel(
        id: 101,
        title: 'Blog 101',
        imageUrl: 'https://img.com/b101.jpg',
        author: 'Blog Author',
        summary: 'Blog summary',
        publishedAt: '2026-11-18',
        url: 'https://blog.com',
        type: ContentType.blog,
      );

      await storage.addFavorite(news101);
      await storage.addFavorite(blog101);

      final favs = await storage.getFavorites();
      expect(favs.length, 2);

      expect(await storage.isFavorite(ContentType.news, 101), isTrue);
      expect(await storage.isFavorite(ContentType.blog, 101), isTrue);

      // Remove only the news item
      await storage.removeFavorite(ContentType.news, 101);
      expect(await storage.isFavorite(ContentType.news, 101), isFalse);
      expect(await storage.isFavorite(ContentType.blog, 101), isTrue);
      final remaining = await storage.getFavorites();
      expect(remaining.length, 1);
      expect(remaining.first.type, ContentType.blog);
    });

    test('Different accounts have completely isolated favorites', () async {
      final storage = StorageService();
      await storage.register('userA', 'passA');
      await storage.register('userB', 'passB');

      // User A favorites News 201
      await storage.login('userA', 'passA');
      await storage.addFavorite(const ArticleModel(
        id: 201,
        title: 'A Favorite',
        author: 'Author A',
        summary: '',
        publishedAt: '',
        url: '',
        type: ContentType.news,
      ));
      expect(await storage.isFavorite(ContentType.news, 201), isTrue);

      // User B logs in
      await storage.login('userB', 'passB');
      expect(await storage.isFavorite(ContentType.news, 201), isFalse);
      expect(await storage.getFavorites(), isEmpty);

      // User B favorites Blog 301
      await storage.addFavorite(const ArticleModel(
        id: 301,
        title: 'B Favorite',
        author: 'Author B',
        summary: '',
        publishedAt: '',
        url: '',
        type: ContentType.blog,
      ));
      expect(await storage.isFavorite(ContentType.blog, 301), isTrue);

      // Re-login as User A
      await storage.login('userA', 'passA');
      expect(await storage.isFavorite(ContentType.news, 201), isTrue);
      expect(await storage.isFavorite(ContentType.blog, 301), isFalse);
    });

    test('Favorites persist after restart simulation', () async {
      final storage1 = StorageService();
      await storage1.register('persistent_user', 'pass');
      await storage1.login('persistent_user', 'pass');
      await storage1.addFavorite(const ArticleModel(
        id: 999,
        title: 'Persistent Title',
        author: 'Avio',
        summary: '',
        publishedAt: '',
        url: '',
        type: ContentType.report,
      ));

      // Simulate app restart with a fresh StorageService instance
      final storage2 = StorageService();
      expect(await storage2.isFavorite(ContentType.report, 999), isTrue);
      final favs = await storage2.getFavorites();
      expect(favs.length, 1);
      expect(favs.first.id, 999);
      expect(favs.first.title, 'Persistent Title');
    });
  });
}
