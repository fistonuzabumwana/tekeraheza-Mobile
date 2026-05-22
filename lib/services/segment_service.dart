import '../core/api/api_client.dart';
import '../core/models/paged_response.dart';

class SegmentService {
  SegmentService(this._api);
  final ApiClient _api;

  Future<List<Map<String, dynamic>>> getSegments() => _api.get(
        '/customer-segments',
        fromJson: (json) => (json as List)
            .map((e) => e as Map<String, dynamic>)
            .toList(),
      );

  Future<Map<String, dynamic>> getStats() => _api.get(
        '/customer-segments/stats',
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<PagedResponse<Map<String, dynamic>>> getSegmentCustomers(
    String segmentId, {
    int page = 0,
  }) =>
      _api.get(
        '/customer-segments/$segmentId/customers',
        queryParameters: {'page': page, 'size': 20},
        fromJson: (json) =>
            PagedResponse.fromDynamic(json, (m) => m),
      );
}
