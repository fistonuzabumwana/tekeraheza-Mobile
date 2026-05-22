import '../core/api/api_client.dart';

class LoyaltyService {
  LoyaltyService(this._api);
  final ApiClient _api;

  Future<List<Map<String, dynamic>>> getTiers() => _api.get(
        '/loyalty/tiers',
        fromJson: (json) => (json as List)
            .map((e) => e as Map<String, dynamic>)
            .toList(),
      );

  Future<Map<String, dynamic>> getStats() => _api.get(
        '/loyalty/stats',
        fromJson: (json) => json as Map<String, dynamic>,
      );
}
