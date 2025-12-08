// [CẬP NHẬT FILE: lib/screens/employee/notification_screen.dart]

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myshop/models/notification.dart';
import 'package:myshop/services/pocketbase_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final pbService = PocketBaseService.instance;

  List<NotificationModel> _notifications = [];
  Set<String> _readIds = {}; // Lưu các ID đã đọc để hiển thị UI
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Tải dữ liệu và trạng thái đọc
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Chạy song song 2 tác vụ: Tải thông báo & Tải danh sách đã đọc
      final results = await Future.wait([
        pbService.notifications.getNotifications(),
        pbService.notifications.getReadIds(),
      ]);

      if (mounted) {
        setState(() {
          _notifications = results[0] as List<NotificationModel>;
          _readIds = (results[1] as List<String>).toSet();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Lỗi tải thông báo: $e");
    }
  }

  // Xử lý khi bấm vào 1 thông báo
  Future<void> _handleTapNotification(NotificationModel notif) async {
    // Nếu chưa đọc thì đánh dấu là đã đọc
    if (!_readIds.contains(notif.id)) {
      await pbService.notifications.markAsRead([notif.id]);
      setState(() {
        _readIds.add(notif.id); // Cập nhật UI ngay lập tức
      });
    }

    // Hiển thị nội dung chi tiết (nếu cần)
    // Ở đây dùng showDialog để xem rõ hơn
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(notif.title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(notif.created),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Text(notif.content),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Đóng"),
            ),
          ],
        ),
      );
    }
  }

  // Đánh dấu tất cả là đã đọc (Nút trên AppBar)
  Future<void> _markAllAsRead() async {
    final allIds = _notifications.map((e) => e.id).toList();
    await pbService.notifications.markAsRead(allIds);
    setState(() {
      _readIds.addAll(allIds);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đã đánh dấu tất cả là đã đọc")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: "Đánh dấu tất cả đã đọc",
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? const Center(child: Text('Chưa có thông báo nào.'))
          : ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: _notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notif = _notifications[index];
                final isRead = _readIds.contains(notif.id);

                return Card(
                  elevation: isRead ? 0 : 2, // Chưa đọc thì nổi lên
                  color: isRead ? Colors.transparent : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: isRead
                        ? BorderSide.none
                        : BorderSide(color: Colors.indigo.shade100),
                  ),
                  child: ListTile(
                    onTap: () => _handleTapNotification(notif),
                    leading: CircleAvatar(
                      backgroundColor: isRead
                          ? Colors.grey.shade200
                          : Colors.indigo.shade100,
                      child: Icon(
                        Icons.notifications,
                        color: isRead ? Colors.grey : Colors.indigo,
                      ),
                    ),
                    title: Text(
                      notif.title,
                      style: TextStyle(
                        fontWeight: isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                        color: isRead ? Colors.black87 : Colors.black,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          notif.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isRead
                                ? Colors.grey.shade600
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(notif.created),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    trailing: !isRead
                        ? const Icon(Icons.circle, size: 10, color: Colors.red)
                        : null,
                  ),
                );
              },
            ),
    );
  }
}
