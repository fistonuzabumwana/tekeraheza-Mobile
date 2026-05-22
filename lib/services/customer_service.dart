import '../core/api/api_client.dart';
import '../core/models/paged_response.dart';

class CustomerService {
  CustomerService(this._api);
  final ApiClient _api;

  Future<PagedResponse<Map<String, dynamic>>> getAll({
    int page = 0,
    int size = 20,
  }) =>
      _api.get(
        '/customers',
        queryParameters: {'page': page, 'size': size},
        fromJson: (json) =>
            PagedResponse.fromDynamic(json, (m) => m),
      );

  Future<Map<String, dynamic>> getById(String id) => _api.get(
        '/customers/$id',
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<Map<String, dynamic>> getMe() => _api.get(
        '/customers/me',
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<Map<String, dynamic>> getByPhone(String phoneNumber) => _api.get(
        '/customers/phone/$phoneNumber',
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<List<Map<String, dynamic>>> getVIP() => _api.get(
        '/customers/vip',
        fromJson: (json) =>
            (json as List).map((e) => e as Map<String, dynamic>).toList(),
      );

  Future<List<Map<String, dynamic>>> getWithOutstandingBalance() => _api.get(
        '/customers/outstanding-balance',
        fromJson: (json) =>
            (json as List).map((e) => e as Map<String, dynamic>).toList(),
      );

  Future<PagedResponse<Map<String, dynamic>>> search(String q,
          {int page = 0}) =>
      _api.get(
        '/customers/search',
        queryParameters: {'q': q, 'page': page, 'size': 20},
        fromJson: (json) =>
            PagedResponse.fromDynamic(json, (m) => m),
      );

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) =>
      _api.post(
        '/customers',
        data: data,
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> data,
  ) =>
      _api.put(
        '/customers/$id',
        data: data,
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<void> delete(String id) => _api.delete('/customers/$id');

  Future<Map<String, dynamic>> addAddress(
    String customerId,
    Map<String, dynamic> address,
  ) =>
      _api.post(
        '/customers/$customerId/addresses',
        data: address,
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<Map<String, dynamic>> updateAddress(
    String customerId,
    String addressId,
    Map<String, dynamic> address,
  ) =>
      _api.put(
        '/customers/$customerId/addresses/$addressId',
        data: address,
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<void> deleteAddress(String customerId, String addressId) =>
      _api.delete('/customers/$customerId/addresses/$addressId');
}
