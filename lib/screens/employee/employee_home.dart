import 'package:flutter/material.dart';
import 'package:myshop/services/auth_service.dart'; // Đảm bảo đường dẫn này đúng
import 'package:myshop/screens/auth/login_screen.dart'; // Đảm bảo đường dẫn này đúng

class EmployeeHome extends StatelessWidget {
  const EmployeeHome({super.key});

  void _logout(BuildContext context) {
    // 1. Gọi hàm logout từ AuthService
    AuthService().logout();

    // 2. Điều hướng về màn hình đăng nhập và xóa lịch sử (để không quay lại được)
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) =>
            const LoginScreen(), // Thay thế bằng màn hình đăng nhập thực tế của bạn
      ),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Employee Home"),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Đăng xuất',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_pin, size: 60, color: Colors.blueGrey),
              SizedBox(height: 10),
              Text(
                "Giao diện nhân viên",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                "Chào mừng bạn quay trở lại hệ thống.",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
