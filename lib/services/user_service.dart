import '../core/api/api_client.dart';
import '../core/models/paged_response.dart';

class UserService {
  UserService(this._api);
  final ApiClient _api;

  Future<PagedResponse<Map<String, dynamic>>> getAll({
    int page = 0,
    int size = 20,
  }) =>
      _api.get(
        '/users',
        queryParameters: {'page': page, 'size': size},
        fromJson: (json) =>
            PagedResponse.fromDynamic(json, (m) => m),
      );

  Future<Map<String, dynamic>> getById(String id) => _api.get(
        '/users/$id',
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) =>
      _api.put(
        '/users/profile',
        data: data,
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) =>
      _api.post(
        '/users',
        data: data,
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<void> deactivate(String id) => _api.patch(
        '/users/$id/deactivate',
        fromJson: (json) => json,
      );
}
