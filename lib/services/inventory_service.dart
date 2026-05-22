import '../core/api/api_client.dart';
import '../core/models/paged_response.dart';

class InventoryService {
  InventoryService(this._api);
  final ApiClient _api;

  Future<List<Map<String, dynamic>>> getAllStock() => _api.get(
        '/inventory/stock',
        fromJson: (json) => (json as List)
            .map((e) => e as Map<String, dynamic>)
            .toList(),
      );

  Future<List<Map<String, dynamic>>> getLowStock() => _api.get(
        '/inventory/stock/low',
        fromJson: (json) => (json as List)
            .map((e) => e as Map<String, dynamic>)
            .toList(),
      );

  Future<PagedResponse<Map<String, dynamic>>> getProducts({
    int page = 0,
    int size = 20,
  }) =>
      _api.get(
        '/products',
        queryParameters: {'page': page, 'size': size},
        fromJson: (json) =>
            PagedResponse.fromDynamic(json, (m) => m),
      );

  Future<Map<String, dynamic>> getProductById(String id) => _api.get(
        '/products/$id',
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) =>
      _api.post(
        '/products',
        data: data,
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<Map<String, dynamic>> updateProduct(
    String id,
    Map<String, dynamic> data,
  ) =>
      _api.put(
        '/products/$id',
        data: data,
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<PagedResponse<Map<String, dynamic>>> getCylinders({
    int page = 0,
    int size = 20,
    String sortBy = 'updatedAt',
    String sortDir = 'desc',
  }) =>
      _api.get(
        '/cylinders',
        queryParameters: {
          'page': page,
          'size': size,
          'sortBy': sortBy,
          'sortDir': sortDir,
        },
        fromJson: (json) =>
            PagedResponse.fromDynamic(json, (m) => m),
      );

  Future<PagedResponse<Map<String, dynamic>>> getCylindersByStatus(
    String status, {
    int page = 0,
    int size = 50,
  }) =>
      _api.get(
        '/cylinders/status/$status',
        queryParameters: {'page': page, 'size': size},
        fromJson: (json) =>
            PagedResponse.fromDynamic(json, (m) => m),
      );

  Future<List<Map<String, dynamic>>> getExpiredCylinders() => _api.get(
        '/cylinders/expired',
        fromJson: (json) => (json as List)
            .map((e) => e as Map<String, dynamic>)
            .toList(),
      );

  Future<int> getCylinderCountByStatus(String status) => _api.get(
        '/cylinders/count/status/$status',
        fromJson: (json) => (json as num).toInt(),
      );

  /// Admin/Manager only on backend (`CylinderAnalyticsController`).
  Future<Map<String, dynamic>> getCylinderAnalytics() => _api.get(
        '/cylinders/analytics',
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<PagedResponse<Map<String, dynamic>>> searchCylinders(
    String q, {
    int page = 0,
    int size = 30,
  }) =>
      _api.get(
        '/cylinders/search',
        queryParameters: {'q': q, 'page': page, 'size': size},
        fromJson: (json) =>
            PagedResponse.fromDynamic(json, (m) => m),
      );

  Future<Map<String, dynamic>> getCylinderById(String id) => _api.get(
        '/cylinders/$id',
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<Map<String, dynamic>> getCylinderBySerial(String serial) => _api.get(
        '/cylinders/serial/$serial',
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<List<Map<String, dynamic>>> getCylindersNeedingInspection() =>
      _api.get(
        '/cylinders/needs-inspection',
        fromJson: (json) => (json as List)
            .map((e) => e as Map<String, dynamic>)
            .toList(),
      );

  Future<PagedResponse<Map<String, dynamic>>> searchProducts(String q) =>
      _api.get(
        '/products/search',
        queryParameters: {'q': q, 'page': 0, 'size': 30},
        fromJson: (json) =>
            PagedResponse.fromDynamic(json, (m) => m),
      );

  Future<void> rejectReturn(String id, String reason) => _api.post(
        '/inventory/returns/$id/reject',
        queryParameters: {'reason': reason},
        fromJson: (json) => json,
      );

  Future<Map<String, dynamic>> adjustStock(Map<String, dynamic> data) =>
      _api.post(
        '/inventory/adjust',
        data: data,
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<List<Map<String, dynamic>>> getWarehousesList() => _api.get(
        '/warehouses/list',
        fromJson: (json) => (json as List)
            .map((e) => e as Map<String, dynamic>)
            .toList(),
      );

  Future<PagedResponse<Map<String, dynamic>>> getSuppliers({
    int page = 0,
    int size = 20,
  }) =>
      _api.get(
        '/suppliers',
        queryParameters: {'page': page, 'size': size},
        fromJson: (json) =>
            PagedResponse.fromDynamic(json, (m) => m),
      );

  Future<List<Map<String, dynamic>>> getPendingReturns() => _api.get(
        '/inventory/returns/pending',
        fromJson: (json) => (json as List)
            .map((e) => e as Map<String, dynamic>)
            .toList(),
      );

  Future<Map<String, dynamic>> approveReturn(
    String id,
    Map<String, dynamic> data,
  ) =>
      _api.post(
        '/inventory/returns/$id/approve',
        data: data,
        fromJson: (json) => json as Map<String, dynamic>,
      );
}
