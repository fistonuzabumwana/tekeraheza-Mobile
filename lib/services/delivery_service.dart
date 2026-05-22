import '../core/api/api_client.dart';
import '../core/models/paged_response.dart';

class DeliveryService {
  DeliveryService(this._api);
  final ApiClient _api;

  Future<PagedResponse<Map<String, dynamic>>> getAll({
    int page = 0,
    int size = 20,
  }) =>
      _api.get(
        '/deliveries',
        queryParameters: {'page': page, 'size': size},
        fromJson: (json) =>
            PagedResponse.fromDynamic(json, (m) => m),
      );

  Future<Map<String, dynamic>> getById(String id) => _api.get(
        '/deliveries/$id',
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<PagedResponse<Map<String, dynamic>>> getByCustomer(
    String customerId, {
    int page = 0,
    int size = 20,
  }) =>
      _api.get(
        '/deliveries/customer/$customerId',
        queryParameters: {'page': page, 'size': size},
        fromJson: (json) => PagedResponse.fromDynamic(json, (m) => m),
      );

  Future<PagedResponse<Map<String, dynamic>>> getByStatus(
    String status, {
    int page = 0,
    int size = 20,
    String sortBy = 'updatedAt',
    String sortDir = 'desc',
  }) =>
      _api.get(
        '/deliveries/status/$status',
        queryParameters: {
          'page': page,
          'size': size,
          'sortBy': sortBy,
          'sortDir': sortDir,
        },
        fromJson: (json) => PagedResponse.fromDynamic(json, (m) => m),
      );

  /// Resolve delivery for an order (web: `/deliveries/order/:orderId`).
  Future<Map<String, dynamic>> getByOrderId(String orderId) => _api.get(
        '/deliveries/order/$orderId',
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<List<Map<String, dynamic>>> getMyDeliveries() => _api.get(
        '/deliveries/my-deliveries',
        fromJson: (json) => (json as List)
            .map((e) => e as Map<String, dynamic>)
            .toList(),
      );

  Future<List<Map<String, dynamic>>> getUnassigned() => _api.get(
        '/deliveries/unassigned',
        fromJson: (json) => (json as List)
            .map((e) => e as Map<String, dynamic>)
            .toList(),
      );

  Future<List<Map<String, dynamic>>> getInTransit() => _api.get(
        '/deliveries/in-transit',
        fromJson: (json) => (json as List)
            .map((e) => e as Map<String, dynamic>)
            .toList(),
      );

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) => _api.post(
        '/deliveries',
        data: body,
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<Map<String, dynamic>> assignDriver(
    String id,
    Map<String, dynamic> body,
  ) =>
      _api.post(
        '/deliveries/$id/assign',
        data: body,
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<Map<String, dynamic>> updateStatus(
    String id,
    Map<String, dynamic> body,
  ) =>
      _api.patch(
        '/deliveries/$id/status',
        data: body,
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<Map<String, dynamic>> updateLocation(
    String id,
    Map<String, dynamic> body,
  ) =>
      _api.patch(
        '/deliveries/$id/location',
        data: body,
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<Map<String, dynamic>> optimizeRoute(Map<String, dynamic> body) =>
      _api.post(
        '/deliveries/optimize-route',
        data: body,
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<List<Map<String, dynamic>>> getAvailableDrivers() => _api.get(
        '/users/delivery-personnel',
        fromJson: (json) => (json as List)
            .map((e) => e as Map<String, dynamic>)
            .toList(),
      );

  Future<Map<String, dynamic>> acceptDelivery(String id) => _api.post(
        '/deliveries/$id/accept',
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<Map<String, dynamic>> rejectDelivery(String id, {String? reason}) =>
      _api.post(
        '/deliveries/$id/reject',
        data: reason != null ? {'reason': reason} : null,
        fromJson: (json) => json as Map<String, dynamic>,
      );
}
