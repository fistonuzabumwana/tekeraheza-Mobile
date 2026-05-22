import '../core/api/api_client.dart';

class ReceiptService {
  ReceiptService(this._api);
  final ApiClient _api;

  Future<Map<String, dynamic>> getByPayment(String paymentId) => _api.get(
        '/payments/receipts/payment/$paymentId',
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<Map<String, dynamic>> getStats() => _api.get(
        '/payments/receipts/stats',
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<void> sendReceipt(String paymentId) => _api.post(
        '/payments/receipts/payment/$paymentId/send',
        data: {},
        fromJson: (json) => json,
      );
}
