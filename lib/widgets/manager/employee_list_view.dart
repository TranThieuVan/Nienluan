import 'package:flutter/material.dart';
import 'package:myshop/models/user.dart';
import 'employee_list_item.dart'; // Import item widget

class EmployeeListView extends StatelessWidget {
  final List<User> employees;
  // Callback function để xác nhận xóa (truyền xuống item)
  final Future<bool> Function(User) onDeleteConfirmed;
  // Callback function khi nhấn vào item (truyền xuống item)
  final void Function(User) onEdit; // Nhận User để biết sửa ai

  const EmployeeListView({
    super.key,
    required this.employees,
    required this.onDeleteConfirmed,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (employees.isEmpty) {
      // Stack + ListView để RefreshIndicator hoạt động khi rỗng
      return Stack(
        children: [
          ListView(), // Cần ListView rỗng
          const Center(
            child: Text('Không có nhân viên nào. Hãy thêm người mới!'),
          ),
        ],
      );
    }

    return ListView.separated(
      // Dùng separated để có đường kẻ
      itemCount: employees.length,
      itemBuilder: (context, index) {
        final employee = employees[index];
        return EmployeeListItem(
          employee: employee,
          onDeleteConfirmed: onDeleteConfirmed,
          onTap: () => onEdit(employee), // Gọi callback sửa khi nhấn
        );
      },
      separatorBuilder: (context, index) =>
          const Divider(height: 1), // Thêm đường kẻ
    );
  }
}
