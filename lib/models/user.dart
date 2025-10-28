import 'package:pocketbase/pocketbase.dart';

// Đã loại bỏ 'unknown'
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
        // Nếu role không khớp, ném ra lỗi hoặc trả về một giá trị mặc định an toàn.
        // Tùy chọn 1: Ném lỗi nếu dữ liệu không hợp lệ (nên dùng cho ứng dụng lớn)
        // throw Exception("Invalid role string: $roleString");

        // Tùy chọn 2: Trả về employee mặc định nếu không khớp
        return UserRole.employee;
    }
  }

  String toJson() {
    return name;
  }
}

class User {
  final String id;
  final String collectionId;
  final String username;
  final String email;
  final UserRole role;
  final DateTime created;
  final DateTime updated;

  User({
    required this.id,
    required this.collectionId,
    required this.username,
    required this.email,
    required this.role,
    required this.created,
    required this.updated,
  });

  /// Tạo một đối tượng User từ một RecordModel (dữ liệu từ PocketBase).
  factory User.fromRecord(RecordModel record) {
    return User(
      id: record.id,
      collectionId: record.collectionId,
      username: record.data['username'] ?? '',
      email: record.data['email'] ?? '',
      role: UserRole.fromString(record.data['role']),

      // Dùng get<String> để truy cập các trường hệ thống
      created: DateTime.parse(record.get<String>('created')),
      updated: DateTime.parse(record.get<String>('updated')),
    );
  }

  /// Chuyển đổi thành Map để CẬP NHẬT.
  Map<String, dynamic> toJson() {
    return {"role": role.toJson()};
  }
}
