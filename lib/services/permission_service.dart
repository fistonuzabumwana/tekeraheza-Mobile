import '../core/api/api_client.dart';

class PermissionService {
  PermissionService(this._api);
  final ApiClient _api;

  Future<List<Map<String, dynamic>>> getGroups() => _api.get(
        '/permissions/groups',
        fromJson: (json) => (json as List)
            .map((e) => e as Map<String, dynamic>)
            .toList(),
      );

  Future<Map<String, dynamic>> getPermissionsByCategory() => _api.get(
        '/permissions/by-category',
        fromJson: (json) => json as Map<String, dynamic>,
      );
}
