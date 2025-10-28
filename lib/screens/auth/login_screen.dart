import 'package:flutter/material.dart';
import '../../services/pocketbase_service.dart';
import '../employee/employee_home.dart';
import '../manager/manager_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final pbService = PocketBaseService();
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _navigateTo(Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _showSnackbar('Vui lòng nhập đầy đủ Email và Mật khẩu.', isError: true);
      return;
    }

    // 1. Bắt đầu loading
    setState(() => isLoading = true);

    try {
      // 2. Gọi hàm login. Nếu hàm login() ném ra Exception (ví dụ: sai mật khẩu),
      // nó sẽ nhảy sang khối catch. Nếu không, nó sẽ chạy tiếp.
      await pbService.login(emailController.text, passwordController.text);

      // 3. Nếu không có exception, login thành công. Ta kiểm tra role và điều hướng.
      final role = pbService.getRole();

      if (role == 'employee') {
        _navigateTo(const EmployeeHome());
        _showSnackbar('Đăng nhập thành công với vai trò Nhân viên!');
      } else if (role == '') {
        _navigateTo(const ManagerHome());
        _showSnackbar('Đăng nhập thành công với vai trò Quản lý!');
      } else {
        // Vai trò không hợp lệ
        pbService.logout();
        _showSnackbar(
          'Tài khoản có vai trò không xác định. Đã đăng xuất.',
          isError: true,
        );
      }
    } catch (e) {
      // Xử lý lỗi (bao gồm lỗi xác thực từ PocketBase và lỗi kết nối)
      // Thường lỗi xác thực sẽ có code 400.
      _showSnackbar(
        'Đăng nhập thất bại: Email hoặc mật khẩu không chính xác.',
        isError: true,
      );
      // Bạn có thể dùng 'Lỗi: ${e.toString()}' để debug chi tiết hơn.
    } finally {
      // Đặt isLoading về false
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Email Input
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),

            // Password Input
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 32),

            // Login Button / Loading Indicator
            SizedBox(
              width: double.infinity,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Đăng nhập",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
