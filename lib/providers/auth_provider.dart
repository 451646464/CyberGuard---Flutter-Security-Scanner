import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _username;

  bool get isAuthenticated => _isAuthenticated;
  String? get username => _username;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isAuthenticated = prefs.getBool('isAuthenticated') ?? false;
    _username = prefs.getString('username');
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    try {
      final success = await DatabaseService.instance.authenticateUser(
        username,
        password,
      );

      if (success) {
        _isAuthenticated = true;
        _username = username;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isAuthenticated', true);
        await prefs.setString('username', username);
        debugPrint('Login successful for user: $username');
        notifyListeners();
      } else {
        debugPrint('Login failed for user: $username');
      }

      return success;
    } catch (e) {
      debugPrint('Error during login: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _username = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAuthenticated', false);
    await prefs.remove('username');
    notifyListeners();
  }

  Future<bool> register(String username, String password) async {
    try {
      final success = await DatabaseService.instance.createUser(
        username,
        password,
      );

      if (success) {
        debugPrint('User registered successfully: $username');
        return await login(username, password);
      } else {
        debugPrint('Failed to register user: $username');
      }

      return false;
    } catch (e) {
      debugPrint('Error during registration: $e');
      return false;
    }
  }
}

