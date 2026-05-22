import '../core/api/api_client.dart';
import '../core/models/paged_response.dart';

class NotificationService {
  NotificationService(this._api);
  final ApiClient _api;

  Future<PagedResponse<Map<String, dynamic>>> getAll({
    int page = 0,
    int size = 20,
  }) =>
      _api.get(
        '/notifications',
        queryParameters: {'page': page, 'size': size},
        fromJson: (json) =>
            PagedResponse.fromDynamic(json, (m) => m),
      );

  Future<List<Map<String, dynamic>>> getUnread() => _api.get(
        '/notifications/unread',
        fromJson: (json) =>
            (json as List).map((e) => e as Map<String, dynamic>).toList(),
      );

  Future<int> getUnreadCount() async {
    final data = await _api.get<Map<String, dynamic>>(
      '/notifications/unread/count',
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return data['count'] as int? ?? 0;
  }

  Future<void> markAsRead(String id) => _api.post(
        '/notifications/$id/read',
        fromJson: (json) => json,
      );

  Future<void> markAllAsRead() => _api.post(
        '/notifications/read-all',
        fromJson: (json) => json,
      );

  Future<void> delete(String id) => _api.delete('/notifications/$id');

  Future<void> deleteAll() => _api.delete('/notifications/all');

  Future<Map<String, dynamic>> send({
    required String userId,
    required String title,
    required String message,
    required String type,
  }) =>
      _api.post(
        '/notifications/send',
        data: {
          'userId': userId,
          'title': title,
          'message': message,
          'type': type,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

  Future<void> cleanup({int daysOld = 30}) =>
      _api.delete('/notifications/cleanup', queryParameters: {'daysOld': daysOld});
}
