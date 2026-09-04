import 'package:dio/dio.dart';
import 'package:zentrapay_application/core/models/notification.dart';
import 'package:zentrapay_application/core/repositories/cached_resource.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';

/// Backs the home screen's notification-bell overlay — `GET/PATCH
/// /api/notifications`. "Load once, apply deltas" like every other list
/// resource here: mark-as-read patches the cached item in place instead of
/// re-fetching the whole list.
class NotificationsRepository extends CachedListResource<AppNotification> {
  NotificationsRepository._();
  static final NotificationsRepository instance = NotificationsRepository._();

  final Dio _dio = ApiClient().dio;

  /// Count of unread notifications — drives the bell's badge dot.
  int get unreadCount => (data ?? []).where((n) => !n.isRead).length;

  @override
  Future<List<AppNotification>> fetch() async {
    final response = await _dio.get('/api/notifications');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> markRead(String notificationId) async {
    // Comment: optimistic — flip it locally first so the tap feels instant,
    // then fire the request. A failure here is low-stakes (a read flag)
    // and self-heals on the next refresh, so no revert-on-failure needed.
    applyDelta(
      (current) => [
        for (final n in current)
          n.notificationId == notificationId ? n.copyWith(isRead: true) : n,
      ],
    );
    try {
      await _dio.patch('/api/notifications/$notificationId/read');
    } catch (_) {
      // Comment: swallow — see note above.
    }
  }
}
