import '../core/api/api_client.dart';

class AlertService {
  AlertService(this._api);
  final ApiClient _api;

  Future<List<Map<String, dynamic>>> getRules() => _api.get(
        '/alert-rules',
        fromJson: (json) => (json as List)
            .map((e) => e as Map<String, dynamic>)
            .toList(),
      );

  Future<Map<String, dynamic>> createRule(Map<String, dynamic> data) =>
      _api.post(
        '/alert-rules',
        data: data,
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<Map<String, dynamic>> toggleRule(String id, bool isActive) =>
      _api.patch(
        '/alert-rules/$id/toggle',
        data: {'isActive': isActive},
        fromJson: (json) => json as Map<String, dynamic>,
      );
}
