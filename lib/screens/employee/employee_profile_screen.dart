import 'package:flutter/material.dart';
import 'package:myshop/models/staff_profile.dart';
import 'package:myshop/services/pocketbase_service.dart';
import 'package:myshop/screens/employee/edit_profile_screen.dart';
import 'package:myshop/screens/employee/notification_screen.dart';
import 'package:myshop/screens/employee/schedule_screen.dart';

class EmployeeProfileScreen extends StatefulWidget {
  const EmployeeProfileScreen({super.key});

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
  final pbService = PocketBaseService.instance;
  StaffProfile? currentProfile;
  String? _error;
  int _notificationCount = 0; // <-- BIẾN MỚI: Đếm số thông báo

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
    _loadNotificationCount(); // <-- Gọi hàm đếm
  }

  Future<void> _loadCurrentProfile() async {
    setState(() {
      _error = null;
      currentProfile = null;
    });
    try {
      final userId = pbService.pb.authStore.record?.id;
      if (userId == null) {
        throw Exception("Không tìm thấy ID người dùng đã đăng nhập.");
      }
      final profile = await pbService.users.getStaffProfileForUser(userId);
      if (mounted) {
        setState(() {
          currentProfile = profile;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  // --- HÀM MỚI: Tải số lượng thông báo ---
  Future<void> _loadNotificationCount() async {
    try {
      // Gọi hàm đếm thông minh mới trong Service
      final count = await pbService.notifications.getUnreadCount();
      if (mounted) {
        setState(() {
          _notificationCount = count;
        });
      }
    } catch (e) {
      print("Lỗi tải thông báo: $e");
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => screen)).then((_) {
      // Khi quay lại từ màn hình khác (ví dụ sau khi xem thông báo), tải lại số lượng
      _loadNotificationCount();
    });
  }

  void _navigateToEditProfile() {
    if (currentProfile == null) return;

    Navigator.of(context)
        .push<bool>(
          MaterialPageRoute(
            builder: (context) => EditProfileScreen(profile: currentProfile!),
          ),
        )
        .then((didUpdate) {
          if (didUpdate == true) {
            _loadCurrentProfile();
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản của tôi'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(child: Text('Lỗi: $_error'));
    }

    if (currentProfile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      children: [
        UserAccountsDrawerHeader(
          accountName: Text(
            currentProfile!.name.isNotEmpty
                ? currentProfile!.name
                : 'Chưa cập nhật tên',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          accountEmail: Text(currentProfile!.email),
          currentAccountPicture: CircleAvatar(
            backgroundColor: Colors.white,
            child: Text(
              (currentProfile!.name.isNotEmpty
                      ? currentProfile!.name[0]
                      : currentProfile!.email[0])
                  .toUpperCase(),
              style: TextStyle(
                fontSize: 40.0,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          decoration: BoxDecoration(color: Theme.of(context).primaryColor),
        ),

        // --- CÁC MỤC CHỨC NĂNG ---
        ListTile(
          leading: const Icon(Icons.edit_note),
          title: const Text('Chỉnh sửa thông tin'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _navigateToEditProfile,
        ),
        ListTile(
          leading: const Icon(Icons.calendar_month),
          title: const Text('Xem lịch làm việc'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _navigateTo(ScheduleScreen(profile: currentProfile!));
          },
        ),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Thông báo'),
          // --- HIỂN THỊ BADGE SỐ LƯỢNG MÀU ĐỎ ---
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_notificationCount > 0)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$_notificationCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (_notificationCount > 0) const SizedBox(width: 10),
              const Icon(Icons.chevron_right),
            ],
          ),
          // ---------------------------------------
          onTap: () {
            _navigateTo(const NotificationScreen());
          },
        ),
      ],
    );
  }
}
