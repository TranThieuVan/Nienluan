import 'package:flutter/material.dart';
import 'package:myshop/models/user.dart';

class EmployeeListItem extends StatelessWidget {
  final User employee;
  // Callback function để xác nhận xóa
  final Future<bool> Function(User) onDeleteConfirmed;
  // Callback function khi nhấn vào item (để sửa)
  final VoidCallback onTap;

  const EmployeeListItem({
    super.key,
    required this.employee,
    required this.onDeleteConfirmed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(employee.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red.shade700,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: const Icon(Icons.delete_sweep, color: Colors.white),
      ),
      // Gọi callback xác nhận xóa
      confirmDismiss: (direction) => onDeleteConfirmed(employee),
      child: ListTile(
        leading: CircleAvatar(
          // Dùng CircleAvatar
          backgroundColor: Colors.indigo.shade100,
          child: Text(
            // Lấy chữ cái đầu tiên của tên hoặc email
            (employee.name.isNotEmpty ? employee.name[0] : employee.email[0])
                .toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade700,
            ),
          ),
        ),
        // Ưu tiên hiển thị tên đầy đủ, fallback về email
        title: Text(
          employee.name.isNotEmpty ? employee.name : employee.email,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text('Email: ${employee.email}'), // Chỉ hiển thị email
        trailing: Icon(
          Icons.edit_note,
          color: Colors.grey.shade600,
        ), // Icon sửa
        onTap: onTap, // Gọi callback khi nhấn (để mở dialog sửa)
      ),
    );
  }
}
