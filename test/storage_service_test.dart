import 'package:flutter_test/flutter_test.dart';
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
}
