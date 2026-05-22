import '../core/api/api_client.dart';
import '../core/models/paged_response.dart';

class OrderService {
  OrderService(this._api);
  final ApiClient _api;

  Future<PagedResponse<Map<String, dynamic>>> getAll({
    int page = 0,
    int size = 20,
    String sortBy = 'updatedAt',
    String sortDir = 'desc',
  }) =>
      _api.get(
        '/orders',
        queryParameters: {
          'page': page,
          'size': size,
          'sortBy': sortBy,
          'sortDir': sortDir,
        },
        fromJson: (json) => PagedResponse.fromDynamic(
          json,
          (m) => m,
        ),
      );

  Future<Map<String, dynamic>> getById(String id) => _api.get(
        '/orders/$id',
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<Map<String, dynamic>> getByOrderNumber(String orderNumber) => _api.get(
        '/orders/number/$orderNumber',
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<PagedResponse<Map<String, dynamic>>> getByCustomer(
    String customerId, {
    int page = 0,
    int size = 20,
  }) =>
      _api.get(
        '/orders/customer/$customerId',
        queryParameters: {'page': page, 'size': size},
        fromJson: (json) => PagedResponse.fromDynamic(json, (m) => m),
      );

  Future<PagedResponse<Map<String, dynamic>>> getByStatus(
    String status, {
    int page = 0,
    int size = 20,
  }) =>
      _api.get(
        '/orders/status/$status',
        queryParameters: {'page': page, 'size': size},
        fromJson: (json) => PagedResponse.fromDynamic(json, (m) => m),
      );

  Future<PagedResponse<Map<String, dynamic>>> search(String q,
          {int page = 0, int size = 20}) =>
      _api.get(
        '/orders/search',
        queryParameters: {'q': q, 'page': page, 'size': size},
        fromJson: (json) =>
            PagedResponse.fromDynamic(json, (m) => m),
      );

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) =>
      _api.post(
        '/orders',
        data: data,
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<Map<String, dynamic>> updateStatus(String id, String status) =>
      _api.patch(
        '/orders/$id/status',
        data: {'status': status},
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<void> cancel(String id, {String? reason}) => _api.post(
        '/orders/$id/cancel',
        queryParameters: reason != null ? {'reason': reason} : null,
        fromJson: (json) => json,
      );

  Future<Map<String, dynamic>> confirm(String id) => _api.post(
        '/orders/$id/confirm',
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<Map<String, dynamic>> createBulk(
    List<Map<String, dynamic>> orders, {
    bool processInParallel = false,
    bool stopOnError = true,
    String? batchReference,
  }) =>
      _api.post(
        '/orders/bulk',
        data: {
          'orders': orders,
          'processInParallel': processInParallel,
          'stopOnError': stopOnError,
          if (batchReference != null) 'batchReference': batchReference,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );
}
