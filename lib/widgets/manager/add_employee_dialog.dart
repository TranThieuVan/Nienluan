import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myshop/models/staff_role.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart'; // <-- Package mới

// Callback function mới
typedef AddStaffProfileCallback =
    Future<void> Function({
      required String name,
      required StaffRole role,
      double salary,
      String? email,
      String? password,
      // Thêm các trường lịch
      required String workType,
      required List<String> defaultDays,
      required List<String> defaultShifts,
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
  bool _isLoading = false;

  // --- State cho Lịch Cố Định ---
  String _selectedWorkType = 'part_time'; // Mặc định
  List<String> _selectedDays = [];
  List<String> _selectedShifts = [];

  // Danh sách tùy chọn (Nên đưa ra Constants sau)
  final List<String> _workTypeOptions = ['full_time', 'part_time', 'casual'];
  final List<String> _dayOptions = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  final List<String> _shiftOptions = ['Ca sáng', 'Ca chiều', 'Ca tối'];
  StaffRole _selectedRole = StaffRole.employee;
  // --- Kết thúc State Lịch ---

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
          // --- Gửi dữ liệu lịch ---
          workType: _selectedWorkType,
          defaultDays: _selectedDays,
          defaultShifts: _selectedShifts,
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
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 24.0,
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  if (value != null)
                    setState(() {
                      _selectedRole = value;
                    });
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: salaryController,
                decoration: const InputDecoration(labelText: 'Lương (VND)'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),

              const Divider(height: 24),
              Text(
                'Lịch làm việc cố định',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),

              // --- THÊM CÁC TRƯỜNG LỊCH MỚI ---
              DropdownButtonFormField<String>(
                value: _selectedWorkType,
                decoration: const InputDecoration(
                  labelText: 'Loại hình làm việc*',
                ),
                items: _workTypeOptions.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  if (value != null)
                    setState(() {
                      _selectedWorkType = value;
                    });
                },
              ),
              const SizedBox(height: 10),
              MultiSelectDialogField<String>(
                items: _dayOptions
                    .map((day) => MultiSelectItem(day, day))
                    .toList(),
                title: const Text("Chọn ngày làm"),
                selectedColor: Theme.of(context).primaryColor,
                buttonIcon: const Icon(Icons.calendar_today),
                buttonText: Text(
                  "Ngày làm cố định",
                  style: TextStyle(color: Colors.grey[700], fontSize: 16),
                ),
                onConfirm: (results) {
                  _selectedDays = results;
                },
              ),
              const SizedBox(height: 10),
              MultiSelectDialogField<String>(
                items: _shiftOptions
                    .map((shift) => MultiSelectItem(shift, shift))
                    .toList(),
                title: const Text("Chọn ca làm"),
                selectedColor: Theme.of(context).primaryColor,
                buttonIcon: const Icon(Icons.access_time),
                buttonText: Text(
                  "Ca làm cố định",
                  style: TextStyle(color: Colors.grey[700], fontSize: 16),
                ),
                onConfirm: (results) {
                  _selectedShifts = results;
                },
              ),
              // --- KẾT THÚC THÊM TRƯỜNG LỊCH ---

              // --- Hiển thị có điều kiện ---
              if (_selectedRole.needsLoginAccount)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 24),
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
