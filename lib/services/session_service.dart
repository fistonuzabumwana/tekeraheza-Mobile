import '../core/api/api_client.dart';
import '../core/models/paged_response.dart';

class SessionService {
  SessionService(this._api);
  final ApiClient _api;

  Future<PagedResponse<Map<String, dynamic>>> getMyActivities({
    int page = 0,
    int size = 20,
  }) =>
      _api.get(
        '/session-activities/my-activities',
        queryParameters: {'page': page, 'size': size},
        fromJson: (json) =>
            PagedResponse.fromDynamic(json, (m) => m),
      );

  Future<List<Map<String, dynamic>>> getActiveSessions() => _api.get(
        '/sessions/active',
        fromJson: (json) => (json as List)
            .map((e) => e as Map<String, dynamic>)
            .toList(),
      );

  Future<void> terminateSession(String sessionId) =>
      _api.delete('/sessions/$sessionId');
}
