import '../core/api/api_client.dart';
import '../core/models/paged_response.dart';

class PaymentService {
  PaymentService(this._api);
  final ApiClient _api;

  Future<PagedResponse<Map<String, dynamic>>> getAll({
    int page = 0,
    int size = 20,
    String sortBy = 'paymentDate',
    String sortDir = 'desc',
    String? status,
    String? paymentMethod,
  }) =>
      _api.get(
        '/payments',
        queryParameters: {
          'page': page,
          'size': size,
          'sortBy': sortBy,
          'sortDir': sortDir,
          if (status != null && status.trim().isNotEmpty) 'status': status,
          if (paymentMethod != null && paymentMethod.trim().isNotEmpty)
            'paymentMethod': paymentMethod,
        },
        fromJson: (json) =>
            PagedResponse.fromDynamic(json, (m) => m),
      );

  Future<PagedResponse<Map<String, dynamic>>> getByCustomer(
    String customerId, {
    int page = 0,
    int size = 20,
  }) =>
      _api.get(
        '/payments/customer/$customerId',
        queryParameters: {'page': page, 'size': size},
        fromJson: (json) => PagedResponse.fromDynamic(json, (m) => m),
      );

  Future<Map<String, dynamic>> getById(String id) => _api.get(
        '/payments/$id',
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<List<Map<String, dynamic>>> getByOrder(String orderId) => _api.get(
        '/payments/order/$orderId',
        fromJson: (json) =>
            (json as List).map((e) => e as Map<String, dynamic>).toList(),
      );

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) =>
      _api.post(
        '/payments',
        data: data,
        fromJson: (json) => json as Map<String, dynamic>,
      );

  // Invoices
  Future<PagedResponse<Map<String, dynamic>>> getInvoices({
    int page = 0,
    int size = 20,
  }) =>
      _api.get(
        '/payments/invoices',
        queryParameters: {'page': page, 'size': size},
        fromJson: (json) =>
            PagedResponse.fromDynamic(json, (m) => m),
      );

  Future<Map<String, dynamic>> getInvoiceById(String id) => _api.get(
        '/payments/invoices/$id',
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<Map<String, dynamic>> getInvoiceByOrder(String orderId) => _api.get(
        '/payments/invoices/order/$orderId',
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<Map<String, dynamic>> createInvoice(String orderId) => _api.post(
        '/payments/invoices/order/$orderId',
        data: {},
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<void> sendInvoice(String invoiceId, {String? email}) => _api.post(
        '/payments/invoices/$invoiceId/send',
        data: {if (email != null && email.trim().isNotEmpty) 'email': email},
        fromJson: (json) => json,
      );

  Future<List<Map<String, dynamic>>> getOverdueInvoices() => _api.get(
        '/payments/invoices/overdue',
        fromJson: (json) =>
            (json as List).map((e) => e as Map<String, dynamic>).toList(),
      );

  Future<Map<String, dynamic>> verify(String id) => _api.post(
        '/payments/$id/verify',
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<Map<String, dynamic>> refund(
    String id,
    double amount, {
    String? reason,
  }) =>
      _api.post(
        '/payments/$id/refund',
        data: {'amount': amount, if (reason != null) 'reason': reason},
        fromJson: (json) => json as Map<String, dynamic>,
      );
}
