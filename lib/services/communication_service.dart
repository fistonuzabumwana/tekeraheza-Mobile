import '../core/api/api_client.dart';
import '../core/models/paged_response.dart';

class CommunicationService {
  CommunicationService(this._api);
  final ApiClient _api;

  Future<PagedResponse<Map<String, dynamic>>> getAll({
    int page = 0,
    int size = 20,
  }) =>
      _api.get(
        '/communications',
        queryParameters: {'page': page, 'size': size},
        fromJson: (json) =>
            PagedResponse.fromDynamic(json, (m) => m),
      );

  Future<Map<String, dynamic>> send(Map<String, dynamic> data) => _api.post(
        '/communications/send',
        data: data,
        fromJson: (json) => json as Map<String, dynamic>,
      );
}
