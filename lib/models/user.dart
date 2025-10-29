import 'package:pocketbase/pocketbase.dart';

// Enum UserRole (Giữ nguyên)
enum UserRole {
  employee,
  manager;

  static UserRole fromString(String? roleString) {
    switch (roleString) {
      case 'employee':
        return UserRole.employee;
      case 'manager':
        return UserRole.manager;
      default:
        print(
          'Cảnh báo: Vai trò không xác định "$roleString", mặc định là employee.',
        );
        return UserRole.employee;
    }
  }

  String toJson() {
    return name;
  }

  String get display {
    switch (this) {
      case UserRole.employee:
        return 'Nhân viên';
      case UserRole.manager:
        return 'Quản lý';
    }
  }
}

class User {
  final String id;
  final String collectionId;
  // *** ĐÃ XÓA USERNAME ***
  // final String username;
  final String email;
  final String name;
  final UserRole role;
  final DateTime created;
  final DateTime updated;

  User({
    required this.id,
    required this.collectionId,
    // *** ĐÃ XÓA USERNAME ***
    // required this.username,
    required this.email,
    required this.name,
    required this.role,
    required this.created,
    required this.updated,
  });

  /// Tạo một đối tượng User từ một RecordModel.
  factory User.fromRecord(RecordModel record) {
    return User(
      id: record.id,
      collectionId: record.collectionId,
      // *** ĐÃ XÓA USERNAME ***
      // username: record.getStringValue('username'),
      email: record.getStringValue('email'),
      name: record.getStringValue('name'),
      role: UserRole.fromString(record.getStringValue('role')),
      created: DateTime.parse(record.getStringValue('created')),
      updated: DateTime.parse(record.getStringValue('updated')),
    );
  }

  /// Chuyển đổi thành Map để CẬP NHẬT (Ví dụ: chỉ cập nhật role và name)
  Map<String, dynamic> toJsonForUpdate() {
    return {"role": role.toJson(), "name": name};
  }
}
