import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/di/service_locator.dart';
import '../core/models/app_user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _init();
  }

  final AuthService _auth = sl<AuthService>();

  AppUser? _user;
  bool _isLoading = true;
  String? _error;

  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    try {
      if (await _auth.isAuthenticated()) {
        _user = await _auth.getStoredUser();
        if (_user != null) {
          try {
            _user = await _auth.getCurrentUser();
          } catch (_) {}
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _error = null;
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _auth.login(email, password);
      if (response['requiresTwoFactor'] == true) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      _user = await _auth.completeLogin(response);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<AppUser> loginWith2fa(
    String token,
    String code, {
    bool useBackupCode = false,
  }) async {
    _error = null;
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _auth.verifyTwoFactor(
        token,
        code,
        useBackupCode: useBackupCode,
      );
      _isLoading = false;
      notifyListeners();
      return _user!;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loginWithGoogle() async {
    _error = null;
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _auth.signInWithGoogle();
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    await _auth.logout();
    _user = null;
    notifyListeners();
  }

  void setUser(AppUser user) {
    _user = user;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
