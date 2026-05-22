import '../core/api/api_client.dart';
import '../core/models/paged_response.dart';

class SystemService {
  SystemService(this._api);
  final ApiClient _api;

  Future<List<Map<String, dynamic>>> getServices() => _api.get(
        '/system/services',
        fromJson: (json) => (json as List)
            .map((e) => e as Map<String, dynamic>)
            .toList(),
      );

  Future<Map<String, dynamic>> getHealthStats() => _api.get(
        '/system/health/stats',
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<PagedResponse<Map<String, dynamic>>> getBackups({
    int page = 0,
    int size = 20,
  }) =>
      _api.get(
        '/system/backups',
        queryParameters: {'page': page, 'size': size},
        fromJson: (json) =>
            PagedResponse.fromDynamic(json, (m) => m),
      );

  Future<Map<String, dynamic>> createBackup({String type = 'FULL'}) =>
      _api.post(
        '/system/backups',
        data: {'type': type},
        fromJson: (json) => json as Map<String, dynamic>,
      );
}
