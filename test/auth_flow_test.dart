import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latres/main.dart';
import 'package:latres/services/storage_service.dart';
import 'package:latres/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Auth UI & Session Flow Widget Tests', () {
    testWidgets('Initial gate: opens LoginScreen when not logged in',
        (tester) async {
      await tester.pumpWidget(const SpaceflightApp());
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsWidgets);
      expect(find.byKey(const Key('login_username_field')), findsOneWidget);
      expect(find.byKey(const Key('login_password_field')), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
      expect(find.text('Daftar di sini'), findsOneWidget);
    });

    testWidgets('Register flow: navigates to register and registers new account',
        (tester) async {
      await tester.pumpWidget(const SpaceflightApp());
      await tester.pumpAndSettle();

      // Tap 'Daftar di sini'
      await tester.tap(find.text('Daftar di sini'));
      await tester.pumpAndSettle();

      expect(find.text('Buat Akun Baru'), findsOneWidget);

      // Enter username & password
      await tester.enterText(
        find.byKey(const Key('register_username_field')),
        'astronaut1',
      );
      await tester.enterText(
        find.byKey(const Key('register_password_field')),
        'password123',
      );

      // Tap Daftar
      await tester.tap(find.byKey(const Key('register_submit_button')));
      await tester.pumpAndSettle();

      // Returned to LoginScreen with success snackbar
      expect(find.text('Registrasi berhasil! Silakan login.'), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);

      // Verify stored in SharedPreferences
      final storage = StorageService();
      final users = await storage.getRegisteredUsers();
      expect(users.length, 1);
      expect(users.first.username, 'astronaut1');
    });

    testWidgets('Register flow: rejects duplicate username with SnackBar',
        (tester) async {
      final storage = StorageService();
      await storage.register('existinguser', 'secret');

      await tester.pumpWidget(const SpaceflightApp());
      await tester.pumpAndSettle();

      // Navigate to Register
      await tester.tap(find.text('Daftar di sini'));
      await tester.pumpAndSettle();

      // Try registering with same username
      await tester.enterText(
        find.byKey(const Key('register_username_field')),
        'existinguser',
      );
      await tester.enterText(
        find.byKey(const Key('register_password_field')),
        'newpass',
      );

      await tester.tap(find.byKey(const Key('register_submit_button')));
      await tester.pumpAndSettle();

      expect(
        find.text('Username sudah terdaftar! Gunakan username lain.'),
        findsOneWidget,
      );
    });

    testWidgets('Login flow: wrong credentials shows red SnackBar exactly per PRD',
        (tester) async {
      await tester.pumpWidget(const SpaceflightApp());
      await tester.pumpAndSettle();

      // Attempt login with empty or wrong fields
      await tester.enterText(
        find.byKey(const Key('login_username_field')),
        'nonexistent',
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        'wrongpass',
      );

      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      // Must show exact red SnackBar required by PRD & exam sheet
      expect(find.text(AppConstants.loginFailedMessage), findsOneWidget);
      expect(
        find.text('Login Gagal! Pastikan sudah Register atau cek password.'),
        findsOneWidget,
      );
    });

    testWidgets('Login flow: successful login navigates to HomeScreen with greeting',
        (tester) async {
      final storage = StorageService();
      await storage.register('apollo11', 'moonwalk');

      await tester.pumpWidget(const SpaceflightApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('login_username_field')),
        'apollo11',
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        'moonwalk',
      );

      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      // Should be on HomeScreen
      expect(find.text('Hai, apollo11!'), findsOneWidget);
      expect(find.byKey(const Key('home_logout_button')), findsOneWidget);

      // Verify session stored
      expect(await storage.isLoggedIn(), isTrue);
      expect(await storage.getCurrentUser(), 'apollo11');
    });

    testWidgets('Auto-login test: restarting app when logged in opens HomeScreen directly',
        (tester) async {
      // Simulate already logged in session
      final storage = StorageService();
      await storage.register('neil', 'armstrong');
      await storage.login('neil', 'armstrong');

      // Launch app fresh
      await tester.pumpWidget(const SpaceflightApp());
      await tester.pumpAndSettle();

      // Should bypass LoginScreen and land on HomeScreen
      expect(find.text('Hai, neil!'), findsOneWidget);
      expect(find.byKey(const Key('home_logout_button')), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsNothing);
    });

    testWidgets('Logout flow: pressing Log Out clears session and returns to LoginScreen',
        (tester) async {
      final storage = StorageService();
      await storage.register('buzz', 'aldrin');
      await storage.login('buzz', 'aldrin');

      await tester.pumpWidget(const SpaceflightApp());
      await tester.pumpAndSettle();

      expect(find.text('Hai, buzz!'), findsOneWidget);

      // Tap Log Out
      await tester.tap(find.byKey(const Key('home_logout_button')));
      await tester.pumpAndSettle();

      // Should be back on LoginScreen
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
      expect(find.text('Hai, buzz!'), findsNothing);

      // Session in storage is cleared
      expect(await storage.isLoggedIn(), isFalse);
    });
  });
}
