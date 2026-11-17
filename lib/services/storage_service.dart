import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

/// Service for managing local persistence via SharedPreferences.
///
/// Handles user registration, authentication session, and active user tracking
/// without any external state management package.
class StorageService {
  final SharedPreferences? prefs;

  StorageService({this.prefs});

  Future<SharedPreferences> get _instance async =>
      prefs ?? await SharedPreferences.getInstance();

  // ==========================================
  // AUTHENTICATION & SESSION MANAGEMENT
  // ==========================================

  /// Retrieves list of all registered users
  Future<List<UserModel>> getRegisteredUsers() async {
    final prefs = await _instance;
    final jsonString = prefs.getString(AppConstants.keyRegisteredUsers);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> list = jsonDecode(jsonString);
      return list
          .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Checks if a username is already registered (case-insensitive)
  Future<bool> isUsernameTaken(String username) async {
    final users = await getRegisteredUsers();
    final normalized = username.trim().toLowerCase();
    return users.any((u) => u.username.trim().toLowerCase() == normalized);
  }

  /// Registers a new user.
  ///
  /// Returns `true` if registered successfully.
  /// Returns `false` if username is empty, password is empty, or username already exists.
  Future<bool> register(String username, String password) async {
    final trimmedUser = username.trim();
    final trimmedPass = password.trim();

    if (trimmedUser.isEmpty || trimmedPass.isEmpty) {
      return false;
    }

    if (await isUsernameTaken(trimmedUser)) {
      return false;
    }

    final users = await getRegisteredUsers();
    users.add(UserModel(username: trimmedUser, password: trimmedPass));

    final prefs = await _instance;
    final jsonString = jsonEncode(users.map((u) => u.toJson()).toList());
    return await prefs.setString(AppConstants.keyRegisteredUsers, jsonString);
  }

  /// Authenticates a user against registered credentials.
  ///
  /// If credentials match:
  /// - Sets [keyIsLoggedIn] to `true`
  /// - Sets [keyCurrentUser] to the registered username
  /// Returns `true` on success, `false` otherwise.
  Future<bool> login(String username, String password) async {
    final trimmedUser = username.trim();
    final trimmedPass = password.trim();

    if (trimmedUser.isEmpty || trimmedPass.isEmpty) {
      return false;
    }

    final users = await getRegisteredUsers();
    final userIndex = users.indexWhere(
      (u) =>
          u.username.trim().toLowerCase() == trimmedUser.toLowerCase() &&
          u.password == trimmedPass,
    );

    if (userIndex != -1) {
      final matchedUser = users[userIndex];
      final prefs = await _instance;
      await prefs.setBool(AppConstants.keyIsLoggedIn, true);
      await prefs.setString(AppConstants.keyCurrentUser, matchedUser.username);
      return true;
    }

    return false;
  }

  /// Checks if there is an active logged-in session (auto-login check)
  Future<bool> isLoggedIn() async {
    final prefs = await _instance;
    return prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;
  }

  /// Returns the username of the active logged-in user
  Future<String?> getCurrentUser() async {
    final prefs = await _instance;
    return prefs.getString(AppConstants.keyCurrentUser);
  }

  /// Logs out the user by clearing active session flags
  Future<void> logout() async {
    final prefs = await _instance;
    await prefs.setBool(AppConstants.keyIsLoggedIn, false);
    await prefs.remove(AppConstants.keyCurrentUser);
  }
}
