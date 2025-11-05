import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myshop/models/staff_role.dart'; // <-- IMPORT MỚI

// Định nghĩa kiểu callback function mới
typedef AddStaffProfileCallback =
    Future<void> Function({
      required String name,
      required StaffRole role,
      double salary,
      String? email,
      String? password,
    });

class AddEmployeeDialog extends StatefulWidget {
  final AddStaffProfileCallback onAdd;

  const AddEmployeeDialog({super.key, required this.onAdd});

  @override
  State<AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<AddEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final salaryController = TextEditingController(text: '0');

  StaffRole _selectedRole = StaffRole.employee; // Giá trị mặc định
  bool _isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    salaryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });
      try {
        await widget.onAdd(
          name: nameController.text,
          role: _selectedRole,
          salary: double.tryParse(salaryController.text) ?? 0.0,
          email: _selectedRole.needsLoginAccount ? emailController.text : null,
          password: _selectedRole.needsLoginAccount
              ? passwordController.text
              : null,
        );
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
          );
        }
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm Nhân viên Mới'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên đầy đủ*'),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Tên không được để trống'
                    : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<StaffRole>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: 'Vai trò*'),
                items: StaffRole.values.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.display),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedRole = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: salaryController,
                decoration: const InputDecoration(labelText: 'Lương (VND)'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),

              // --- Hiển thị có điều kiện ---
              if (_selectedRole.needsLoginAccount)
                Column(
                  children: [
                    const Divider(height: 20),
                    Text(
                      'Tài khoản đăng nhập (Bắt buộc cho ${(_selectedRole).display})',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email*'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (_selectedRole.needsLoginAccount &&
                            (value == null || !value.contains('@'))) {
                          return 'Vui lòng nhập email hợp lệ';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: 'Mật khẩu*'),
                      obscureText: true,
                      validator: (value) {
                        if (_selectedRole.needsLoginAccount &&
                            (value == null || value.length < 8)) {
                          return 'Mật khẩu phải có ít nhất 8 ký tự';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
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
