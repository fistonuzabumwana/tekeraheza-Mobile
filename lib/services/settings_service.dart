import '../core/api/api_client.dart';

class SettingsService {
  SettingsService(this._api);
  final ApiClient _api;

  Future<Map<String, dynamic>> getCompanySettings() => _api.get(
        '/settings/company',
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<Map<String, dynamic>> updateCompanySettings(
    Map<String, dynamic> data,
  ) =>
      _api.put(
        '/settings/company',
        data: data,
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<void> deleteCompanyLogo() => _api.delete('/settings/company/logo');

  Future<Map<String, dynamic>> getSecuritySettings() => _api.get(
        '/settings/security',
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<List<Map<String, dynamic>>> getNotificationPreferences() => _api.get(
        '/settings/notifications',
        fromJson: (json) =>
            (json as List).map((e) => e as Map<String, dynamic>).toList(),
      );

  Future<Map<String, dynamic>> updateNotificationPreference(
    String id,
    Map<String, dynamic> data,
  ) =>
      _api.put(
        '/settings/notifications/$id',
        data: data,
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<List<Map<String, dynamic>>> updateAllNotificationPreferences(
    List<Map<String, dynamic>> preferences,
  ) =>
      _api.put(
        '/settings/notifications/bulk',
        data: {'preferences': preferences},
        fromJson: (json) =>
            (json as List).map((e) => e as Map<String, dynamic>).toList(),
      );

  Future<Map<String, dynamic>> getAppearanceSettings() => _api.get(
        '/settings/appearance',
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<Map<String, dynamic>> updateAppearanceSettings(
    Map<String, dynamic> data,
  ) =>
      _api.put(
        '/settings/appearance',
        data: data,
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) =>
      _api.post(
        '/auth/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
        fromJson: (json) => json,
      );
}
