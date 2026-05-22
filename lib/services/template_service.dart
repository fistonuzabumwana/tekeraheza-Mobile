import '../core/api/api_client.dart';

class TemplateService {
  TemplateService(this._api);
  final ApiClient _api;

  Future<List<Map<String, dynamic>>> getTemplates() => _api.get(
        '/notification-templates',
        fromJson: (json) => (json as List)
            .map((e) => e as Map<String, dynamic>)
            .toList(),
      );

  Future<Map<String, dynamic>> toggleActive(String id) => _api.patch(
        '/notification-templates/$id/toggle-active',
        fromJson: (json) => json as Map<String, dynamic>,
      );
}
