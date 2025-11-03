import 'package:flutter/material.dart';
import 'package:myshop/models/user.dart';
import 'package:myshop/services/pocketbase_service.dart';
// (Giả sử bạn sẽ tạo file này ở bước sau, tương tự như EditEmployeeDialog)
import 'package:myshop/screens/employee/edit_profile_screen.dart';
// (các import khác)
import 'package:myshop/screens/employee/notification_screen.dart'; // <-- THÊM IMPORT NÀY

class EmployeeProfileScreen extends StatefulWidget {
  const EmployeeProfileScreen({super.key});

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
  final pbService = PocketBaseService.instance;
  User? currentUser;

  @override
  void initState() {
    super.initState();
    // Tải thông tin user đang đăng nhập
    _loadCurrentUser();
  }

  void _loadCurrentUser() {
    // Lấy record của user đã đăng nhập từ service
    final record = pbService.pb.authStore.record;
    if (record != null) {
      setState(() {
        currentUser = User.fromRecord(record);
      });
    }
  }

  // Hàm helper để điều hướng
  void _navigateTo(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => screen));
  }

  // Hàm điều hướng đến màn hình chỉnh sửa
  void _navigateToEditProfile() {
    if (currentUser == null) return;

    // --- ĐÃ SỬA ---
    Navigator.of(context)
        .push<bool>(
          // Nhận kết quả boolean
          MaterialPageRoute(
            builder: (context) => EditProfileScreen(employee: currentUser!),
          ),
        )
        .then((didUpdate) {
          // Nếu màn hình Edit trả về 'true' (tức là đã cập nhật)
          if (didUpdate == true) {
            _loadCurrentUser(); // Tải lại thông tin để cập nhật tên
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
      body: currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // --- PHẦN HEADER THÔNG TIN ---
                UserAccountsDrawerHeader(
                  accountName: Text(
                    currentUser!.name.isNotEmpty
                        ? currentUser!.name
                        : 'Chưa cập nhật tên',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  accountEmail: Text(currentUser!.email),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(
                      (currentUser!.name.isNotEmpty
                              ? currentUser!.name[0]
                              : currentUser!.email[0])
                          .toUpperCase(),
                      style: TextStyle(
                        fontSize: 40.0,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                  ),
                ),

                // --- PHẦN CHỨC NĂNG ---
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
                    _navigateTo(
                      const _PlaceholderScreen(title: 'Lịch làm việc'),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Thông báo'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Bỏ placeholder và gọi màn hình thật
                    _navigateTo(
                      const NotificationScreen(), // <-- ĐÃ SỬA
                    );
                  },
                ),
              ],
            ),
    );
  }
}

// Lớp màn hình tạm thời
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Đây là màn hình cho chức năng: $title')),
    );
  }
}
