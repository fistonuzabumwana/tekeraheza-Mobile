import '../core/api/api_client.dart';
import '../core/models/paged_response.dart';

class MaintenanceService {
  MaintenanceService(this._api);
  final ApiClient _api;

  Future<PagedResponse<Map<String, dynamic>>> getAllMaintenance({
    int page = 0,
    int size = 10,
    String sortBy = 'scheduledDate',
    String sortDir = 'desc',
  }) =>
      _api.get(
        '/maintenance',
        queryParameters: {
          'page': page,
          'size': size,
          'sortBy': sortBy,
          'sortDir': sortDir,
        },
        fromJson: (json) =>
            PagedResponse.fromDynamic(json, (m) => m),
      );

  Future<Map<String, dynamic>> getMaintenanceById(String id) => _api.get(
        '/maintenance/$id',
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<PagedResponse<Map<String, dynamic>>> getMaintenanceByCylinder(
    String cylinderId, {
    int page = 0,
    int size = 10,
  }) =>
      _api.get(
        '/maintenance/cylinder/$cylinderId',
        queryParameters: {'page': page, 'size': size},
        fromJson: (json) =>
            PagedResponse.fromDynamic(json, (m) => m),
      );

  Future<PagedResponse<Map<String, dynamic>>> getMaintenanceByStatus(
    String status, {
    int page = 0,
    int size = 10,
  }) =>
      _api.get(
        '/maintenance/status/$status',
        queryParameters: {'page': page, 'size': size},
        fromJson: (json) =>
            PagedResponse.fromDynamic(json, (m) => m),
      );

  Future<List<Map<String, dynamic>>> getScheduledForToday() => _api.get(
        '/maintenance/scheduled-today',
        fromJson: (json) => (json as List)
            .map((e) => e as Map<String, dynamic>)
            .toList(),
      );

  Future<List<Map<String, dynamic>>> getOverdueMaintenance() => _api.get(
        '/maintenance/overdue',
        fromJson: (json) => (json as List)
            .map((e) => e as Map<String, dynamic>)
            .toList(),
      );

  Future<List<Map<String, dynamic>>> getDueForMaintenance({
    int daysAhead = 30,
  }) =>
      _api.get(
        '/maintenance/due',
        queryParameters: {'daysAhead': daysAhead},
        fromJson: (json) => (json as List)
            .map((e) => e as Map<String, dynamic>)
            .toList(),
      );

  Future<Map<String, dynamic>> scheduleMaintenance(
    Map<String, dynamic> data,
  ) =>
      _api.post(
        '/maintenance',
        data: data,
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<Map<String, dynamic>> startMaintenance(String id) => _api.post(
        '/maintenance/$id/start',
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<Map<String, dynamic>> completeMaintenance(
    String id,
    Map<String, dynamic> data,
  ) =>
      _api.post(
        '/maintenance/$id/complete',
        data: data,
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<Map<String, dynamic>> cancelMaintenance(
    String id,
    String reason,
  ) =>
      _api.post(
        '/maintenance/$id/cancel',
        queryParameters: {'reason': reason},
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<PagedResponse<Map<String, dynamic>>> getComplianceByCylinder(
    String cylinderId, {
    int page = 0,
    int size = 10,
  }) =>
      _api.get(
        '/maintenance/compliance/cylinder/$cylinderId',
        queryParameters: {'page': page, 'size': size},
        fromJson: (json) =>
            PagedResponse.fromDynamic(json, (m) => m),
      );

  Future<Map<String, dynamic>> createComplianceCheck(
    Map<String, dynamic> data,
  ) =>
      _api.post(
        '/maintenance/compliance',
        data: data,
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<Map<String, dynamic>> verifyCompliance(
    String id, {
    required String status,
    String? notes,
  }) =>
      _api.post(
        '/maintenance/compliance/$id/verify',
        queryParameters: {
          'status': status,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );
}
