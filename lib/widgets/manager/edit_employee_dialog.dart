import 'package:flutter/material.dart';
import 'package:myshop/models/user.dart'; // Cần User

// *** Định nghĩa callback tổng hợp ***
typedef UpdateEmployeeCallback =
    Future<void> Function({
      required String userId,
      String? newName, // Optional
      String? oldPassword, // Optional
      String? newPassword, // Optional
      String? confirmNewPassword, // Optional
    });

class EditEmployeeDialog extends StatefulWidget {
  final User employee; // Nhận thông tin nhân viên hiện tại
  // *** Sử dụng một callback duy nhất ***
  final UpdateEmployeeCallback onUpdate;

  const EditEmployeeDialog({
    super.key,
    required this.employee,
    required this.onUpdate, // Sử dụng callback tổng hợp
  });

  @override
  State<EditEmployeeDialog> createState() => _EditEmployeeDialogState();
}

class _EditEmployeeDialogState extends State<EditEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmNewPasswordController = TextEditingController();
  // *** Sử dụng một state loading duy nhất ***
  bool _isLoading = false;

  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.employee.name);
  }

  @override
  void dispose() {
    nameController.dispose();
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmNewPasswordController.dispose();
    super.dispose();
  }

  // --- Xử lý Submit (GỘP LẠI) ---
  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Lấy giá trị
      final String? newName =
          (nameController.text != widget.employee.name &&
              nameController.text.isNotEmpty)
          ? nameController.text
          : null; // Chỉ gửi nếu tên thực sự thay đổi và không rỗng
      final String? oldPassword = oldPasswordController.text.isNotEmpty
          ? oldPasswordController.text
          : null;
      final String? newPassword = newPasswordController.text.isNotEmpty
          ? newPasswordController.text
          : null;
      final String? confirmNewPassword =
          confirmNewPasswordController.text.isNotEmpty
          ? confirmNewPasswordController.text
          : null;

      // Kiểm tra logic mật khẩu (nếu người dùng cố gắng đổi)
      if (newPassword != null || confirmNewPassword != null) {
        if (oldPassword == null) {
          // *** LỖI ĐÃ SỬA: Dùng _showErrorDialog ***
          _showErrorDialog(
            'Vui lòng nhập mật khẩu cũ (của bạn) để đổi mật khẩu.',
          );
          return;
        }
        if (newPassword == null || newPassword.length < 8) {
          // *** LỖI ĐÃ SỬA: Dùng _showErrorDialog ***
          _showErrorDialog('Mật khẩu mới phải có ít nhất 8 ký tự.');
          return;
        }
        if (newPassword != confirmNewPassword) {
          // *** LỖI ĐÃ SỬA: Dùng _showErrorDialog ***
          _showErrorDialog('Mật khẩu mới và xác nhận không khớp.');
          return;
        }
      } else if (oldPassword != null) {
        // Nếu chỉ nhập mk cũ mà không nhập mk mới
        // *** LỖI ĐÃ SỬA: Dùng _showErrorDialog ***
        _showErrorDialog('Vui lòng nhập Mật khẩu mới và Xác nhận.');
        return;
      }

      // Kiểm tra xem có gì để lưu không
      if (newName == null && newPassword == null) {
        _showSuccessDialog(
          'Không có thay đổi nào được thực hiện.',
        ); // Thông báo không có gì thay đổi
        return;
      }

      // Bắt đầu loading
      setState(() {
        _isLoading = true;
      });
      try {
        // Gọi callback tổng hợp
        await widget.onUpdate(
          userId: widget.employee.id,
          newName: newName,
          oldPassword: oldPassword,
          newPassword: newPassword,
          confirmNewPassword: confirmNewPassword,
        );
        // Nếu không có lỗi, hiển thị thành công và đóng dialog
        if (mounted) _showSuccessDialog('Cập nhật thông tin thành công!');
      } catch (e) {
        // Hiển thị lỗi ngay trên dialog
        if (mounted) _showErrorDialog('Lỗi cập nhật: $e');
        if (mounted)
          setState(() {
            _isLoading = false;
          });
      } finally {
        // Luôn tắt loading nếu widget còn tồn tại và không thành công
        if (mounted && _isLoading)
          setState(() {
            _isLoading = false;
          });
      }
    }
  }

  // --- Hàm hiển thị lỗi ---
  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Lỗi'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // --- Hàm hiển thị thành công ---
  void _showSuccessDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green),
            SizedBox(width: 8),
            Text('Thành công'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Đóng dialog success
              Navigator.of(context).pop(); // Đóng dialog edit chính
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.edit_note, color: Colors.indigo.shade600),
          const SizedBox(width: 8),
          const Text('Thông Tin Tài khoản'),
        ],
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 24.0,
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Phần Thông tin Cơ bản ---
              Text(
                'Email:',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              SelectableText(
                widget.employee.email,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên đầy đủ',
                  border: OutlineInputBorder(),
                ),
                enabled: !_isLoading, // Chỉ vô hiệu hóa khi đang loading
                validator: (value) {
                  if (value != null && value.length > 50) {
                    return 'Tên không được quá 50 ký tự';
                  }
                  // Tên có thể để trống nếu ban đầu đã trống
                  // if (value != null && value.trim().isEmpty && widget.employee.name.isNotEmpty) {
                  //    return 'Tên không được để trống';
                  // }
                  return null;
                },
              ),

              const Divider(height: 30, thickness: 1.5),

              // --- Phần Đổi Mật khẩu ---
              Text(
                'Đổi Mật khẩu:',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                '(Để trống các ô bên dưới nếu không muốn đổi)',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 15),

              // Mật khẩu Cũ (của Admin)
              TextFormField(
                controller: oldPasswordController,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu CŨ*', // Nhấn mạnh là pass của Admin
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_person),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureOldPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () => setState(
                      () => _obscureOldPassword = !_obscureOldPassword,
                    ),
                  ),
                ),
                enabled: !_isLoading, // Chỉ vô hiệu hóa khi đang loading
                obscureText: _obscureOldPassword,
                // Validate nếu người dùng bắt đầu nhập mật khẩu mới
                validator: (value) {
                  if (newPasswordController.text.isNotEmpty &&
                      (value == null || value.isEmpty)) {
                    return 'Nhập mật khẩu của bạn để xác thực';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Mật khẩu Mới
              TextFormField(
                controller: newPasswordController,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu Mới*',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () => setState(
                      () => _obscureNewPassword = !_obscureNewPassword,
                    ),
                  ),
                ),
                enabled: !_isLoading,
                obscureText: _obscureNewPassword,
                validator: (value) {
                  // Chỉ validate nếu người dùng nhập
                  if (value != null && value.isNotEmpty && value.length < 8) {
                    return 'Ít nhất 8 ký tự';
                  }
                  if (confirmNewPasswordController.text.isNotEmpty &&
                      (value == null || value.isEmpty)) {
                    return 'Nhập mật khẩu mới';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Xác nhận Mật khẩu Mới
              TextFormField(
                controller: confirmNewPasswordController,
                decoration: InputDecoration(
                  labelText: 'Xác nhận Mật khẩu*',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_reset),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                  ),
                ),
                enabled: !_isLoading,
                obscureText: _obscureConfirmPassword,
                validator: (value) {
                  if (newPasswordController.text.isNotEmpty &&
                      value != newPasswordController.text) {
                    return 'Mật khẩu xác nhận không khớp';
                  }
                  if (value != null &&
                      value.isNotEmpty &&
                      newPasswordController.text.isEmpty) {
                    return 'Nhập mật khẩu mới trước';
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
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'), // Đổi thành Hủy
        ),
        // *** Chỉ còn một nút Lưu ***
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Lưu Thay Đổi'), // Đổi tên nút
        ),
      ],
    );
  }
}
