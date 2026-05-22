import 'package:flutter/foundation.dart';

import '../core/di/service_locator.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = sl<NotificationService>();

  int _unreadCount = 0;

  int get unreadCount => _unreadCount;

  Future<void> refreshUnreadCount() async {
    try {
      _unreadCount = await _service.getUnreadCount();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markAsRead(String id) async {
    await _service.markAsRead(id);
    await refreshUnreadCount();
  }

  Future<void> markAllRead() async {
    await _service.markAllAsRead();
    _unreadCount = 0;
    notifyListeners();
  }
}
