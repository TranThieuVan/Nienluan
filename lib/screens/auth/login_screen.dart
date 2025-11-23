// [CẬP NHẬT FILE: lib/screens/auth/login_screen.dart]

import 'package:flutter/material.dart';
// Import các màn hình và service cần thiết
import '../../services/pocketbase_service.dart';
import '../employee/employee_home.dart';
import '../manager/manager_home.dart';
// Lưu ý: Đã xóa import AppRoutes vì bạn chuyển sang dùng MaterialPageRoute

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Biến điều khiển
  final _formKey = GlobalKey<FormState>(); // Thêm form key cho validation
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final pbService = PocketBaseService.instance;
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
    // Sử dụng formKey để validate input
    if (!_formKey.currentState!.validate()) {
      _showSnackbar('Vui lòng nhập đầy đủ và đúng định dạng.', isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      await pbService.login(emailController.text, passwordController.text);

      final role = pbService.getRole();

      if (role == 'employee') {
        _navigateTo(const EmployeeHome());
      } else if (role == 'manager') {
        _navigateTo(const ManagerHome());
      } else {
        pbService.logout();
        _showSnackbar(
          'Tài khoản có vai trò không xác định. Đã đăng xuất.',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackbar(
        'Đăng nhập thất bại: Email hoặc mật khẩu không chính xác.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- VỊ TRÍ APP ICON ---
              Image.asset('assets/icon/vanbeef.png', height: 200),
              const SizedBox(height: 32),

              const Text(
                'Đăng nhập',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 32),

              // --- FORM ĐĂNG NHẬP ---
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Email Input
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (value) {
                        if (value == null || !value.contains('@')) {
                          return 'Email không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Input
                    TextFormField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        labelText: "Mật khẩu",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Mật khẩu phải có ít nhất 6 ký tự';
                        }
                        return null;
                      },
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
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
            ],
          ),
        ),
      ),
    );
  }
}
