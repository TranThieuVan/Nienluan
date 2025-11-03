import 'package:flutter/material.dart';
import 'package:myshop/services/pocketbase_service.dart';
import 'package:myshop/screens/auth/login_screen.dart';
import 'package:myshop/screens/manager/employee_management_screen.dart';

// --- BƯỚC 1: THÊM IMPORT CHO CÁC MÀN HÌNH THẬT ---
import 'package:myshop/screens/manager/manage_menu.dart';
import 'package:myshop/screens/manager/reports.dart'; // (Giả định bạn cũng có file này)
import 'package:myshop/screens/manager/notification_management_screen.dart';

// Lớp dữ liệu (Giữ nguyên)
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
    PocketBaseService().logout();
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
        screen: const EmployeeManagementScreen(),
      ),
      _ManagerAction(
        title: "Thực đơn",
        icon: Icons.restaurant_menu,
        color: Colors.green.shade600,
        // --- BƯỚC 2: SỬA LẠI ĐỂ TRỎ ĐẾN MÀN HÌNH THẬT ---
        screen: ManageMenuScreen(), // <-- ĐÃ SỬA
      ),
      _ManagerAction(
        title: "Thống kê",
        icon: Icons.bar_chart,
        color: Colors.amber.shade700,
        // --- (Tùy chọn) Sửa luôn màn hình Báo cáo ---
        screen: ReportsScreen(), // <-- ĐÃ SỬA
      ),
      _ManagerAction(
        title: "Quản lý Bàn",
        icon: Icons.table_bar,
        color: Colors.blueGrey.shade600,
        screen: const Text("Tạm thời chưa có màn hình chi tiết"),
      ),
      // --- THÊM CARD MỚI NÀY ---
      _ManagerAction(
        title: "Thông báo",
        icon: Icons.campaign,
        color: Colors.purple.shade600,
        screen: const NotificationManagementScreen(),
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
            // Header chào mừng (Giữ nguyên)
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

            // Grid View (Giữ nguyên)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final action = actions[index];
                return _buildActionCard(context, action);
              },
            ),
            const SizedBox(height: 50.0),
          ],
        ),
      ),
    );
  }

  // (Hàm _buildActionCard giữ nguyên)
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

// --- BƯỚC 3: XÓA CÁC CLASS PLACEHOLDER CŨ ---
// (Không còn cần MenuItemManagementScreen và ReportsScreen ở đây nữa)
