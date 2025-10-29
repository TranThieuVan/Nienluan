import 'package:flutter/material.dart';
import 'package:myshop/models/user.dart'; // Cần UserRole

// Định nghĩa kiểu callback function
typedef AddEmployeeCallback =
    Future<void> Function({
      required String email,
      required String password,
      required String confirmPassword,
      String? name,
    });

class AddEmployeeDialog extends StatefulWidget {
  final AddEmployeeCallback onAdd;

  const AddEmployeeDialog({super.key, required this.onAdd});

  @override
  State<AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<AddEmployeeDialog> {
  final _formKey = GlobalKey<FormState>(); // Key để validate form
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nameController = TextEditingController();
  bool _isLoading = false; // Trạng thái loading khi nhấn nút Thêm

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Validate form trước khi submit
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });
      try {
        // Gọi callback truyền về màn hình chính
        await widget.onAdd(
          email: emailController.text,
          password: passwordController.text,
          confirmPassword: confirmPasswordController.text,
          name: nameController.text.isNotEmpty ? nameController.text : null,
        );
        // Nếu không có lỗi, tự động đóng dialog
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        // Lỗi sẽ được xử lý và hiển thị Snackbar ở màn hình chính
        // Ở đây chỉ cần tắt loading
        if (mounted)
          setState(() {
            _isLoading = false;
          });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm Nhân viên Mới'),
      content: SingleChildScrollView(
        child: Form(
          // Bọc trong Form để validate
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                // Dùng TextFormField để validate
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email*'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty || !value.contains('@')) {
                    return 'Vui lòng nhập email hợp lệ';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên đầy đủ'),
                validator: (value) {
                  // Ví dụ: Tên không quá 50 ký tự
                  if (value != null && value.length > 50) {
                    return 'Tên không được quá 50 ký tự';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Mật khẩu*'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty || value.length < 8) {
                    return 'Mật khẩu phải có ít nhất 8 ký tự';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Xác nhận Mật khẩu*',
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng xác nhận mật khẩu';
                  }
                  if (value != passwordController.text) {
                    return 'Mật khẩu xác nhận không khớp';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          // Vô hiệu hóa nút Hủy khi đang loading
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          // Hiển thị loading hoặc nút Thêm
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Thêm'),
        ),
      ],
    );
  }
}
