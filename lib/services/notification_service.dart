// [CẬP NHẬT FILE: lib/services/notification_service.dart]

import 'package:pocketbase/pocketbase.dart';
import 'package:myshop/models/notification.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <-- Import này

class NotificationService {
  final PocketBase pb;
  static const String _readKey = 'read_notification_ids';
  NotificationService(this.pb);

  // Lấy danh sách
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final records = await pb
          .collection('notifications')
          .getFullList(sort: '-created');
      return records.map((r) => NotificationModel.fromRecord(r)).toList();
    } catch (e) {
      print('Error fetching notifications: $e');
      throw Exception('Failed to load notifications: $e');
    }
  }

  Future<void> markAsRead(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final readIds = prefs.getStringList(_readKey) ?? [];

    bool changed = false;
    for (var id in ids) {
      if (!readIds.contains(id)) {
        readIds.add(id);
        changed = true;
      }
    }

    if (changed) {
      await prefs.setStringList(_readKey, readIds);
    }
  }

  Future<List<String>> getReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_readKey) ?? [];
  }

  Future<int> getUnreadCount() async {
    try {
      // 1. Lấy tất cả thông báo từ Server
      final allNotifications = await getNotifications();

      // 2. Lấy danh sách ID đã đọc từ bộ nhớ máy
      final prefs = await SharedPreferences.getInstance();
      final readIds = prefs.getStringList(_readKey) ?? [];

      // 3. Đếm những cái chưa có trong danh sách đã đọc
      final unreadCount = allNotifications
          .where((n) => !readIds.contains(n.id))
          .length;

      return unreadCount;
    } catch (e) {
      return 0;
    }
  }

  // Tạo mới
  Future<void> createNotification({
    required String title,
    required String content, // Dùng content
  }) async {
    try {
      await pb
          .collection('notifications')
          .create(
            body: {
              'title': title,
              'content': content, // Dùng content
            },
          );
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  // --- HÀM MỚI: CẬP NHẬT ---
  Future<void> updateNotification({
    required String id,
    required String title,
    required String content, // Dùng content
  }) async {
    try {
      await pb
          .collection('notifications')
          .update(
            id,
            body: {
              'title': title,
              'content': content, // Dùng content
            },
          );
    } catch (e) {
      throw Exception('Failed to update notification: $e');
    }
  }

  // --- HÀM MỚI: XÓA ---
  Future<void> deleteNotification(String id) async {
    try {
      await pb.collection('notifications').delete(id);
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }
}
