import '../core/api/api_client.dart';

class CustomReportService {
  CustomReportService(this._api);
  final ApiClient _api;

  Future<List<Map<String, dynamic>>> getFields() => _api.get(
        '/reports/fields',
        fromJson: (json) => (json as List)
            .map((e) => e as Map<String, dynamic>)
            .toList(),
      );

  Future<List<Map<String, dynamic>>> getSavedReports() => _api.get(
        '/reports/saved',
        fromJson: (json) => (json as List)
            .map((e) => e as Map<String, dynamic>)
            .toList(),
      );

  Future<List<dynamic>> preview(Map<String, dynamic> body) => _api.post(
        '/reports/preview',
        data: body,
        fromJson: (json) => json as List<dynamic>,
      );
}
