import 'package:flutter/material.dart';
import 'package:myshop/services/pocketbase_service.dart';
import 'package:myshop/screens/auth/login_screen.dart';
// Thêm import cho màn hình Quản lý Nhân viên thực tế
import 'package:myshop/screens/manager/employee_management_screen.dart';

// Lớp dữ liệu cho các hành động của quản lý
class _ManagerAction {
  final String title;
  final IconData icon;
  final Widget screen;
  final Color color;

  _ManagerAction({
    required this.title,
    required this.icon,
    required this.screen,
    required this.color,
  });
}

class ManagerHome extends StatelessWidget {
  const ManagerHome({super.key});

  void _logout(BuildContext context) {
    // 1. Gọi hàm logout từ PocketBaseService
    PocketBaseService().logout();

    // 2. Điều hướng về màn hình đăng nhập và xóa lịch sử
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => screen));
  }

  // Danh sách các chức năng chính của Quản lý
  List<_ManagerAction> _getActions(BuildContext context) {
    return [
      _ManagerAction(
        title: "Nhân viên",
        icon: Icons.people_alt,
        color: Colors.indigo.shade600,
        screen:
            const EmployeeManagementScreen(), // Đã thay thế bằng màn hình thực tế
      ),
      _ManagerAction(
        title: "Thực đơn",
        icon: Icons.restaurant_menu,
        color: Colors.green.shade600,
        screen: const MenuItemManagementScreen(),
      ),
      _ManagerAction(
        title: "Thống kê",
        icon: Icons.bar_chart,
        color: Colors.amber.shade700,
        screen: const ReportsScreen(),
      ),
      _ManagerAction(
        title: "Quản lý Bàn",
        icon: Icons.table_bar,
        color: Colors.blueGrey.shade600,
        // Dùng màn hình nhân viên làm màn hình quản lý bàn tạm thời
        screen: const Text("Tạm thời chưa có màn hình chi tiết"),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final actions = _getActions(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý Hệ thống"),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            tooltip: 'Đăng xuất Quản lý',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header chào mừng
            const Padding(
              padding: EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Chào mừng Quản lý!",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Dashboard quản lý các chức năng chính của hệ thống.",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),

            // Grid View cho các chức năng
            GridView.builder(
              shrinkWrap:
                  true, // Quan trọng để đặt GridView bên trong SingleChildScrollView
              physics:
                  const NeverScrollableScrollPhysics(), // Vô hiệu hóa cuộn bên trong GridView
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 cột
                childAspectRatio:
                    1.5, // Tỉ lệ chiều rộng/chiều cao của mỗi item
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final action = actions[index];
                return _buildActionCard(context, action);
              },
            ),

            // FIX LỖI: Thêm khoảng đệm an toàn ở cuối Column
            const SizedBox(height: 50.0),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, _ManagerAction action) {
    return InkWell(
      onTap: () => _navigateTo(context, action.screen),
      child: Card(
        color: action.color,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(action.icon, size: 40, color: Colors.white),
              Text(
                action.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- MÀN HÌNH PLACEHOLDER CŨ ---

// Placeholder cho Quản lý Thực đơn
class MenuItemManagementScreen extends StatelessWidget {
  const MenuItemManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý Thực đơn"),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          "Đây là nơi thêm, sửa, xóa món ăn và cập nhật giá/tồn kho.",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

// Placeholder cho Báo cáo
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Báo cáo & Thống kê"),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          "Đây là nơi hiển thị biểu đồ doanh thu, thống kê theo ngày/tháng.",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
