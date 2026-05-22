import '../core/api/api_client.dart';
import '../core/models/paged_response.dart';

class CreditService {
  CreditService(this._api);
  final ApiClient _api;

  Future<PagedResponse<Map<String, dynamic>>> getAccounts({
    int page = 0,
    int size = 20,
  }) =>
      _api.get(
        '/credit/accounts',
        queryParameters: {'page': page, 'size': size},
        fromJson: (json) =>
            PagedResponse.fromDynamic(json, (m) => m),
      );

  Future<Map<String, dynamic>> getStats() => _api.get(
        '/credit/stats',
        fromJson: (json) => json as Map<String, dynamic>,
      );
}
