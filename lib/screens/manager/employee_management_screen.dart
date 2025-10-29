import 'package:flutter/material.dart';
// Import service chính (chứa users service)
import 'package:myshop/services/pocketbase_service.dart';
import 'package:myshop/models/user.dart';
// Import các widget con mới
import 'package:myshop/widgets/manager/employee_list_view.dart';
import 'package:myshop/widgets/manager/add_employee_dialog.dart';
// Import dialog sửa
import 'package:myshop/widgets/manager/edit_employee_dialog.dart';

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() =>
      _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  final PocketBaseService pbService = PocketBaseService.instance;
  late Future<List<User>> _employeesFuture;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    if (mounted) {
      setState(() {
        _employeesFuture = pbService.users.getUsers(
          filter: "role = 'employee'",
        );
      });
    }
  }

  // --- LOGIC XỬ LÝ ---

  // Hiển thị dialog thêm nhân viên
  void _showAddEmployeeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AddEmployeeDialog(onAdd: _handleAddEmployee);
      },
    );
  }

  // Xử lý thêm nhân viên
  Future<void> _handleAddEmployee({
    required String email,
    required String password,
    required String confirmPassword,
    String? name,
  }) async {
    try {
      await pbService.users.addUser(
        email: email,
        password: password,
        role: UserRole.employee,
        name: name,
      );
      _showSnackbar(
        'Thêm nhân viên ${name?.isNotEmpty == true ? name : email} thành công!',
        Colors.green,
      );
      _loadEmployees();
    } catch (e) {
      _showSnackbar('Lỗi thêm nhân viên: $e', Colors.red);
      throw e;
    }
  }

  // Xử lý xóa nhân viên
  Future<bool> _handleDeleteEmployee(User user) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xác nhận Xóa'),
            content: Text(
              'Bạn có chắc chắn muốn xóa nhân viên ${user.name.isNotEmpty ? user.name : user.email} không?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed) {
      try {
        await pbService.users.deleteUser(user.id);
        _showSnackbar(
          'Xóa nhân viên ${user.name.isNotEmpty ? user.name : user.email} thành công!',
          Colors.green,
        );
        _loadEmployees(); // Tải lại sau khi xóa thành công
        return true;
      } catch (e) {
        _showSnackbar('Lỗi xóa nhân viên: $e', Colors.red);
        return false;
      }
    }
    return false;
  }

  // Hiển thị Dialog Sửa
  void _showEditEmployeeDialog(User user) {
    showDialog(
      context: context,
      barrierDismissible: false, // Không đóng khi nhấn ra ngoài
      builder: (context) {
        // *** LỖI ĐÃ SỬA: Truyền một callback duy nhất ***
        return EditEmployeeDialog(
          employee: user,
          onUpdate: _handleUpdateEmployee, // Callback cập nhật tổng hợp
        );
      },
    );
  }

  // --- HÀM XỬ LÝ CẬP NHẬT (GỘP LẠI) ---
  // Nhận tất cả tham số từ Dialog EditEmployeeDialog
  Future<void> _handleUpdateEmployee({
    required String userId,
    String? newName,
    String? oldPassword,
    String? newPassword,
    String? confirmNewPassword, // Sửa tên tham số cho khớp
  }) async {
    try {
      // Gọi hàm updateUser duy nhất trong service
      await pbService.users.updateUser(
        userId: userId,
        newName: newName,
        oldPassword: oldPassword,
        newPassword: newPassword,
        newPasswordConfirm: confirmNewPassword,
      );
      _showSnackbar('Cập nhật thông tin thành công!', Colors.green);
      _loadEmployees(); // Làm mới danh sách
    } catch (e) {
      _showSnackbar('Lỗi cập nhật: $e', Colors.red);
      throw e; // Ném lại lỗi để Dialog biết và không tự đóng
    }
  }

  // --- ĐÃ XÓA _handleUpdateName và _handleUpdatePassword ---

  // Hàm hiển thị Snackbar
  void _showSnackbar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
    }
  }

  // --- GIAO DIỆN (BUILD) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý Nhân viên"),
        backgroundColor: Colors.indigo.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEmployees,
            tooltip: 'Làm mới danh sách',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadEmployees,
        child: FutureBuilder<List<User>>(
          future: _employeesFuture,
          builder: (context, snapshot) {
            // Xử lý Loading
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Xử lý Lỗi
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 40,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Lỗi tải danh sách nhân viên: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadEmployees,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Xử lý Thành công -> Gọi EmployeeListView
            final employees = snapshot.data ?? [];
            return EmployeeListView(
              employees: employees,
              onDeleteConfirmed: _handleDeleteEmployee,
              // Gọi hàm hiển thị dialog sửa
              onEdit: _showEditEmployeeDialog,
            );
          },
        ),
      ),
      // Nút Thêm (FloatingActionButton)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEmployeeDialog,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Thêm NV'),
      ),
    );
  }
}
