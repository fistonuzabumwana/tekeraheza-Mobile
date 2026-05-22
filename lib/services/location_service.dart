import '../core/api/api_client.dart';

class LocationService {
  LocationService(this._api);
  final ApiClient _api;

  Future<List<String>> getProvinces() => _api.get(
        '/locations/provinces',
        fromJson: (json) => (json as List).map((e) => e.toString()).toList(),
      );

  Future<List<String>> getDistricts(String province) => _api.get(
        '/locations/districts',
        queryParameters: {'province': province},
        fromJson: (json) => (json as List).map((e) => e.toString()).toList(),
      );

  Future<List<String>> getSectors(String district) => _api.get(
        '/locations/sectors',
        queryParameters: {'district': district},
        fromJson: (json) => (json as List).map((e) => e.toString()).toList(),
      );

  Future<List<String>> getCells(String sector) => _api.get(
        '/locations/cells',
        queryParameters: {'sector': sector},
        fromJson: (json) => (json as List).map((e) => e.toString()).toList(),
      );

  Future<List<String>> getVillages(String cell) => _api.get(
        '/locations/villages',
        queryParameters: {'cell': cell},
        fromJson: (json) => (json as List).map((e) => e.toString()).toList(),
      );
}
