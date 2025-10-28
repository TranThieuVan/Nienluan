import 'package:flutter/material.dart';
import '../../services/pocketbase_service.dart'; // Đảm bảo đường dẫn này đúng
import 'package:myshop/screens/auth/login_screen.dart'; // Đảm bảo đường dẫn này đúng

class ManagerHome extends StatelessWidget {
  const ManagerHome({super.key});

  void _logout(BuildContext context) {
    // 1. Gọi hàm logout từ PocketBaseService (hoặc AuthService)
    PocketBaseService().logout();

    // 2. Điều hướng về màn hình đăng nhập và xóa lịch sử
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manager Home"),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.exit_to_app, // Biểu tượng exit/logout
              color: Colors.white,
            ),
            tooltip: 'Đăng xuất Quản lý',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.admin_panel_settings,
                size: 80,
                color: Colors.indigo.shade700,
              ),
              const SizedBox(height: 20),
              const Text(
                "Giao diện quản lý (chủ)",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const Text(
                "Bạn có quyền truy cập đầy đủ vào hệ thống.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
