import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myshop/models/staff_profile.dart'; // <-- IMPORT MỚI
import 'package:myshop/models/staff_role.dart'; // <-- IMPORT MỚI

// Callback mới
typedef UpdateStaffProfileCallback =
    Future<void> Function({
      required String profileId,
      required String name,
      required StaffRole role,
      required double salary,
      required String status,
    });

class EditEmployeeDialog extends StatefulWidget {
  final StaffProfile profile; // <-- Đổi thành StaffProfile
  final UpdateStaffProfileCallback onUpdate;

  const EditEmployeeDialog({
    super.key,
    required this.profile,
    required this.onUpdate,
  });

  @override
  State<EditEmployeeDialog> createState() => _EditEmployeeDialogState();
}

class _EditEmployeeDialogState extends State<EditEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController salaryController;
  late StaffRole _selectedRole;
  late String _selectedStatus;
  bool _isLoading = false;

  // Bạn có thể lấy list này từ Constants sau
  final List<String> _statusOptions = ['active', 'resigned', 'on_leave'];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.profile.name);
    salaryController = TextEditingController(
      text: widget.profile.salary.toStringAsFixed(0),
    );
    _selectedRole = widget.profile.role;
    _selectedStatus = widget.profile.status;

    // Đảm bảo status cũ có trong list, nếu không thì dùng 'active'
    if (!_statusOptions.contains(_selectedStatus)) {
      _selectedStatus = 'active';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    salaryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });
      try {
        await widget.onUpdate(
          profileId: widget.profile.id,
          name: nameController.text,
          role: _selectedRole,
          salary: double.tryParse(salaryController.text) ?? 0.0,
          status: _selectedStatus,
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
      title: Text('Sửa Hồ sơ: ${widget.profile.name}'),
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
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Trạng thái*'),
                items: _statusOptions.map((status) {
                  return DropdownMenuItem(value: status, child: Text(status));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  }
                },
              ),
              // Hiển thị email (chỉ xem, không sửa)
              if (widget.profile.hasLoginAccount)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: SelectableText(
                    'Email đăng nhập: ${widget.profile.email}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
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
              : const Text('Lưu'),
        ),
      ],
    );
  }
}
