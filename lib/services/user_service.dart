import 'package:pocketbase/pocketbase.dart';
import 'package:myshop/models/user.dart'; // Import User model (đã cập nhật)
// Import PocketBaseService không cần thiết nếu chỉ dùng pb instance
// import 'pocketbase_service.dart';

/// Lớp Service chuyên xử lý các thao tác liên quan đến Collection 'users'
class UserService {
  final PocketBase pb;

  // Constructor nhận instance PocketBase
  UserService(this.pb);

  // --- CÁC HÀM QUẢN LÝ USER ---

  /// Lấy danh sách người dùng, có thể lọc theo điều kiện (ví dụ: role)
  Future<List<User>> getUsers({String? filter}) async {
    try {
      final records = await pb
          .collection('users')
          .getFullList(
            filter: filter,
            sort: 'name', // Sắp xếp theo 'name'
          );
      return records.map((record) => User.fromRecord(record)).toList();
    } catch (e) {
      print('UserService - Error fetching users: $e');
      throw Exception('Failed to load users: $e');
    }
  }

  /// Thêm người dùng mới (ví dụ: nhân viên)
  Future<void> addUser({
    required String email,
    required String password,
    required UserRole role,
    String? name,
  }) async {
    try {
      final body = <String, dynamic>{
        "email": email,
        "emailVisibility": true,
        "password": password,
        "passwordConfirm": password,
        "role": role.toJson(),
      };
      body['name'] = name ?? email.split('@').first;

      await pb.collection('users').create(body: body);
    } catch (e) {
      print('UserService - Error adding user: $e');
      if (e is ClientException && e.response.containsKey('data')) {
        final errors = e.response['data'] as Map<String, dynamic>;
        String errorMsg = 'Lỗi không xác định.';
        if (errors.containsKey('email')) {
          errorMsg = 'Email đã tồn tại.';
        } else if (errors.containsKey('password')) {
          errorMsg = 'Mật khẩu không hợp lệ (quá ngắn?).';
        } else if (errors.containsKey('name')) {
          errorMsg = 'Tên không hợp lệ.';
        }
        throw Exception(errorMsg);
      }
      throw Exception('Failed to add user: $e');
    }
  }

  /// Xóa người dùng theo ID
  Future<void> deleteUser(String userId) async {
    try {
      await pb.collection('users').delete(userId);
    } catch (e) {
      print('UserService - Error deleting user: $e');
      throw Exception('Failed to delete user: $e');
    }
  }

  // --- HÀM CẬP NHẬT USER (TÊN VÀ MẬT KHẨU) ---
  /// Cập nhật thông tin người dùng (Tên và Mật khẩu)
  Future<void> updateUser({
    required String userId,
    String? newName, // Tên mới (optional)
    String? oldPassword, // Mật khẩu cũ (bắt buộc nếu đổi mk)
    String? newPassword, // Mật khẩu mới (optional)
    String? newPasswordConfirm, // Xác nhận mk mới (optional)
  }) async {
    try {
      // Dữ liệu chỉ chứa các trường cần cập nhật
      final body = <String, dynamic>{};

      // Thêm tên nếu có
      if (newName != null) {
        body['name'] = newName;
      }

      // Thêm mật khẩu nếu có (và hợp lệ)
      if (newPassword != null && newPassword.isNotEmpty) {
        if (oldPassword == null || oldPassword.isEmpty) {
          throw Exception('Vui lòng nhập mật khẩu cũ để đổi mật khẩu.');
        }
        if (newPassword != newPasswordConfirm) {
          throw Exception('Mật khẩu mới và xác nhận không khớp.');
        }
        // PocketBase yêu cầu cả 3 trường khi đổi mật khẩu
        body['oldPassword'] = oldPassword;
        body['password'] = newPassword;
        body['passwordConfirm'] = newPasswordConfirm;
      }

      // Nếu không có gì để cập nhật, không cần gọi API
      if (body.isEmpty) return;

      // Gọi API cập nhật
      await pb.collection('users').update(userId, body: body);
    } catch (e) {
      print('UserService - Error updating user: $e');
      // Xử lý lỗi cụ thể từ PocketBase (ví dụ: sai mật khẩu cũ)
      if (e is ClientException && e.response.containsKey('data')) {
        final errors = e.response['data'] as Map<String, dynamic>;
        if (errors.containsKey('oldPassword')) {
          throw Exception('Mật khẩu cũ không chính xác.');
        } else if (errors.containsKey('password')) {
          throw Exception('Mật khẩu mới không hợp lệ (quá ngắn?).');
        }
      }
      throw Exception('Failed to update user: $e');
    }
  }
}
