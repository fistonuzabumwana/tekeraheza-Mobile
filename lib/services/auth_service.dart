import 'package:google_sign_in/google_sign_in.dart';

import '../core/api/api_client.dart';
import '../core/config/app_config.dart';
import '../core/api/api_constants.dart';
import '../core/models/app_user.dart';
import '../core/storage/storage_service.dart';

class AuthService {
  AuthService(this._api, this._storage);

  final ApiClient _api;
  final StorageService _storage;

  Future<Map<String, dynamic>> login(String email, String password) async {
    return _api.post<Map<String, dynamic>>(
      ApiConstants.login,
      data: {'email': email, 'password': password},
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  Future<AppUser> verifyTwoFactor(
    String twoFactorToken,
    String code, {
    bool useBackupCode = false,
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      ApiConstants.login2fa,
      data: {
        'twoFactorToken': twoFactorToken,
        'code': code,
        'useBackupCode': useBackupCode,
      },
      fromJson: (json) => json as Map<String, dynamic>,
    );
    await _persistAuth(data);
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> resendLoginOtp(String twoFactorToken) async {
    await _api.post<dynamic>(
      ApiConstants.login2faResend,
      queryParameters: {'twoFactorToken': twoFactorToken},
      fromJson: (json) => json,
    );
  }

  Future<AppUser> completeLogin(Map<String, dynamic> data) async {
    await _persistAuth(data);
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Same contract as web `POST /auth/google` with `{ idToken }`.
  Future<AppUser> googleLogin(String idToken) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/auth/google',
      data: {'idToken': idToken},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return completeLogin(data);
  }

  /// Opens system Google account picker; requires [AppConfig.googleServerClientId].
  Future<AppUser> signInWithGoogle() async {
    if (!AppConfig.isGoogleSignInConfigured) {
      throw ApiException(
        'Google Sign-In is not configured. Pass --dart-define=GOOGLE_SERVER_CLIENT_ID=your_web_client_id',
      );
    }
    final google = GoogleSignIn(
      scopes: ['email', 'openid'],
      serverClientId: AppConfig.googleServerClientId,
    );
    final account = await google.signIn();
    if (account == null) {
      throw ApiException('Sign in cancelled');
    }
    final ga = await account.authentication;
    final id = ga.idToken;
    if (id == null || id.isEmpty) {
      throw ApiException(
        'No ID token from Google. On Android add your SHA-1 in Google Cloud and rebuild.',
      );
    }
    return googleLogin(id);
  }

  Future<void> _persistAuth(Map<String, dynamic> data) async {
    await _storage.saveSession(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      user: data['user'] as Map<String, dynamic>,
    );
  }

  Future<AppUser> register(Map<String, dynamic> body) async {
    final user = await _api.post<Map<String, dynamic>>(
      ApiConstants.register,
      data: body,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return AppUser.fromJson(user);
  }

  Future<void> logout() async {
    try {
      await _api.post<dynamic>(
        ApiConstants.logout,
        fromJson: (json) => json,
      );
    } finally {
      await _storage.clearSession();
    }
  }

  Future<AppUser> getCurrentUser() async {
    final data = await _api.get<Map<String, dynamic>>(
      ApiConstants.me,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    await _storage.updateUser(data);
    return AppUser.fromJson(data);
  }

  Future<void> forgotPassword(String email) async {
    await _api.post<dynamic>(
      ApiConstants.forgotPassword,
      data: {'email': email},
      fromJson: (json) => json,
    );
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _api.post<dynamic>(
      ApiConstants.resetPassword,
      data: {
        'token': token,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
      fromJson: (json) => json,
    );
  }

  Future<bool> isAuthenticated() async {
    final token = await _storage.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<AppUser?> getStoredUser() async {
    final data = await _storage.getUser();
    if (data == null) return null;
    return AppUser.fromJson(data);
  }

  Future<Map<String, dynamic>> verifyManager(String email, String password) async {
    return _api.post<Map<String, dynamic>>(
      ApiConstants.verifyManager,
      data: {'email': email, 'password': password},
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }
}
