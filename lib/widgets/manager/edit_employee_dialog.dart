import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myshop/models/staff_profile.dart';
import 'package:myshop/models/staff_role.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart'; // <-- Package mới

// Callback mới (cần thêm các trường lịch)
typedef UpdateStaffProfileCallback =
    Future<void> Function({
      required String profileId,
      required String name,
      required StaffRole role,
      required double salary,
      required String status,
      // Thêm các trường lịch
      required String workType,
      required List<String> defaultDays,
      required List<String> defaultShifts,
    });

class EditEmployeeDialog extends StatefulWidget {
  final StaffProfile profile;
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

  // --- THÊM STATE CHO LỊCH ---
  late String _selectedWorkType;
  List<String> _selectedDays = [];
  List<String> _selectedShifts = [];

  // Danh sách tùy chọn
  final List<String> _statusOptions = ['active', 'resigned', 'on_leave'];
  final List<String> _workTypeOptions = ['full_time', 'part_time', 'casual'];
  final List<String> _dayOptions = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  final List<String> _shiftOptions = ['Ca sáng', 'Ca chiều', 'Ca tối'];
  // --- KẾT THÚC THÊM ---

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.profile.name);
    salaryController = TextEditingController(
      text: widget.profile.salary.toStringAsFixed(0),
    );
    _selectedRole = widget.profile.role;
    _selectedStatus = widget.profile.status;

    // --- KHỞI TẠO GIÁ TRỊ LỊCH ---
    _selectedWorkType = widget.profile.workType;
    _selectedDays = List<String>.from(widget.profile.defaultDays);
    _selectedShifts = List<String>.from(widget.profile.defaultShifts);

    if (!_statusOptions.contains(_selectedStatus)) {
      _selectedStatus = 'active';
    }
    if (!_workTypeOptions.contains(_selectedWorkType)) {
      _selectedWorkType = 'part_time';
    }
    // --- KẾT THÚC KHỞI TẠO ---
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
          // --- GỬI DỮ LIỆU LỊCH ---
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
      title: Text('Sửa Hồ sơ: ${widget.profile.name}'),
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
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Trạng thái*'),
                items: _statusOptions.map((status) {
                  return DropdownMenuItem(value: status, child: Text(status));
                }).toList(),
                onChanged: (value) {
                  if (value != null)
                    setState(() {
                      _selectedStatus = value;
                    });
                },
              ),

              if (widget.profile.hasLoginAccount)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: SelectableText(
                    'Email đăng nhập: ${widget.profile.email}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
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
                title: const Text("Chọn ngày làm việc"),
                selectedColor: Theme.of(context).primaryColor,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                buttonIcon: const Icon(Icons.calendar_today),
                buttonText: Text(
                  "Ngày làm cố định",
                  style: TextStyle(color: Colors.grey[700], fontSize: 16),
                ),
                initialValue: _selectedDays,
                onConfirm: (results) {
                  setState(() {
                    _selectedDays = results;
                  });
                },
                chipDisplay: MultiSelectChipDisplay(
                  onTap: (value) {
                    setState(() {
                      _selectedDays.remove(value);
                    });
                  },
                ),
              ),
              const SizedBox(height: 10),
              MultiSelectDialogField<String>(
                items: _shiftOptions
                    .map((shift) => MultiSelectItem(shift, shift))
                    .toList(),
                title: const Text("Chọn ca làm việc"),
                selectedColor: Theme.of(context).primaryColor,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                buttonIcon: const Icon(Icons.access_time),
                buttonText: Text(
                  "Ca làm cố định",
                  style: TextStyle(color: Colors.grey[700], fontSize: 16),
                ),
                initialValue: _selectedShifts,
                onConfirm: (results) {
                  setState(() {
                    _selectedShifts = results;
                  });
                },
                chipDisplay: MultiSelectChipDisplay(
                  onTap: (value) {
                    setState(() {
                      _selectedShifts.remove(value);
                    });
                  },
                ),
              ),
              // --- KẾT THÚC THÊM TRƯỜNG LỊCH ---
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
