import 'package:pocketbase/pocketbase.dart';
// Import các model mới
import 'package:myshop/models/staff_profile.dart';
import 'package:myshop/models/staff_role.dart';
// Import model 'User' cũ (chỉ dùng cho hàm login)
import 'package:myshop/models/user.dart';

/// Lớp Service này giờ đây quản lý "Hồ sơ Nhân viên" (staff_profiles)
/// và các tài khoản "users" liên quan đến hồ sơ đó.
class UserService {
  final PocketBase pb;

  UserService(this.pb);

  /// 1. LẤY (READ)
  /// Lấy tất cả hồ sơ nhân viên (từ collection 'staff_profiles')
  Future<List<StaffProfile>> getStaffProfiles() async {
    try {
      final records = await pb
          .collection('staff_profiles')
          .getFullList(
            sort: 'name',
            // 'expand' để lấy thông tin 'email' từ bảng 'users'
            expand: 'user_account',
          );
      return records.map((record) => StaffProfile.fromRecord(record)).toList();
    } catch (e) {
      print('UserService - Error fetching staff profiles: $e');
      throw Exception('Failed to load staff list: $e');
    }
  }

  /// 7. LẤY (READ) 1 HỒ SƠ
  /// Lấy hồ sơ nhân viên (staff_profile) dựa trên ID tài khoản (user_id)
  Future<StaffProfile> getStaffProfileForUser(String userId) async {
    try {
      final record = await pb
          .collection('staff_profiles')
          .getFirstListItem(
            'user_account = \'$userId\'', // Tìm hồ sơ liên kết với user_id này
            expand: 'user_account', // Vẫn expand để lấy email
          );
      return StaffProfile.fromRecord(record);
    } catch (e) {
      print('UserService - Error fetching single staff profile: $e');
      throw Exception('Không tìm thấy hồ sơ nhân viên.');
    }
  }

  /// 2. THÊM (CREATE) - (ĐÃ ĐƠN GIẢN HÓA)
  Future<void> addStaffProfile({
    required String name,
    required StaffRole role,
    double salary = 0.0,
    String? email,
    String? password,
  }) async {
    String? newUserId;
    try {
      if (role.needsLoginAccount) {
        if (email == null || password == null) {
          throw Exception('Email và Mật khẩu là bắt buộc cho vai trò này.');
        }
        final userRecord = await pb
            .collection('users')
            .create(
              body: {
                'email': email,
                'password': password,
                'passwordConfirm': password,
                'emailVisibility': true,
                'name': name,
                'role': role.name,
              },
            );
        newUserId = userRecord.id;
      }

      final profileBody = <String, dynamic>{
        'name': name,
        'role': role.toJson(),
        'salary': salary,
        'status': 'active',
        // --- CÁC TRƯỜNG LỊCH ĐÃ BỊ XÓA KHỎI ĐÂY ---
        // (Chúng ta sẽ gán giá trị default từ PocketBase)
      };

      if (newUserId != null) {
        profileBody['user_account'] = newUserId;
      }
      await pb.collection('staff_profiles').create(body: profileBody);
    } catch (e) {
      // ... (Phần rollback lỗi giữ nguyên) ...
      if (newUserId != null) {
        try {
          await pb.collection('users').delete(newUserId);
        } catch (deleteError) {
          print(
            "CRITICAL ERROR: Failed to rollback user creation: $deleteError",
          );
        }
      }
      print('UserService - Error adding staff: $e');
      if (e is ClientException && e.response.containsKey('data')) {
        final errors = e.response['data'] as Map<String, dynamic>;
        if (errors.containsKey('email')) {
          throw Exception('Email đã tồn tại.');
        }
      }
      throw Exception('Failed to add staff: $e');
    }
  }

  /// 3. XÓA (DELETE)
  /// Xóa hồ sơ nhân viên (và cả tài khoản 'users' liên quan)
  Future<void> deleteStaffProfile(StaffProfile profile) async {
    try {
      // Xóa hồ sơ 'staff_profiles' trước
      await pb.collection('staff_profiles').delete(profile.id);

      // Nếu hồ sơ này có liên kết tài khoản 'users', xóa luôn tài khoản đó
      if (profile.hasLoginAccount) {
        await pb.collection('users').delete(profile.userId!);
      }
    } catch (e) {
      print('UserService - Error deleting staff: $e');
      throw Exception('Failed to delete staff: $e');
    }
  }

  /// 4. SỬA (UPDATE) - (Đã nâng cấp)
  /// Cập nhật thông tin hồ sơ và tài khoản (nếu có)
  Future<void> updateStaffDetails({
    // Thông tin Profile (Bắt buộc)
    required String profileId,
    required String name,
    required StaffRole role,
    required double salary,
    required String status,

    // Thông tin Account (Tùy chọn)
    String? userId, // ID của 'users' collection
    String? newEmail,
    String? newPassword,
  }) async {
    try {
      // --- Luôn cập nhật 'staff_profiles' ---
      final profileBody = <String, dynamic>{
        'name': name,
        'role': role.toJson(),
        'salary': salary,
        'status': status,
      };
      // (Lưu ý: Logic chuyển đổi vai trò (vd: Chef -> Employee)
      //  rất phức tạp và sẽ cần xử lý riêng, ở đây ta tạm bỏ qua)
      await pb
          .collection('staff_profiles')
          .update(profileId, body: profileBody);

      // --- Chỉ cập nhật 'users' nếu có thông tin ---
      if (userId != null && (newEmail != null || newPassword != null)) {
        final userBody = <String, dynamic>{};

        // Nếu email thay đổi
        if (newEmail != null) {
          userBody['email'] = newEmail;
          userBody['emailVisibility'] = true;
        }

        // Nếu mật khẩu mới được nhập
        if (newPassword != null) {
          userBody['password'] = newPassword;
          userBody['passwordConfirm'] = newPassword;
        }

        // (Với quyền Admin, PocketBase cho phép đổi pass mà ko cần pass cũ)
        await pb.collection('users').update(userId, body: userBody);
      }
    } catch (e) {
      print('UserService - Error updating details: $e');
      if (e is ClientException && e.response.containsKey('data')) {
        final errors = e.response['data'] as Map<String, dynamic>;
        if (errors.containsKey('email')) {
          throw Exception('Email này đã tồn tại.');
        }
      }
      throw Exception('Failed to update staff details: $e');
    }
  }

  /// 5. HÀM CŨ (Vẫn cần cho nhân viên tự đổi mật khẩu)
  /// Cập nhật Mật khẩu cho tài khoản 'users' (dùng ở EditProfileScreen)
  Future<void> updateUserPassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    try {
      final body = <String, dynamic>{
        'oldPassword': oldPassword,
        'password': newPassword,
        'passwordConfirm': newPasswordConfirm,
      };
      await pb.collection('users').update(userId, body: body);
    } catch (e) {
      print('UserService - Error updating password: $e');
      if (e is ClientException && e.response.containsKey('data')) {
        final errors = e.response['data'] as Map<String, dynamic>;
        if (errors.containsKey('oldPassword')) {
          throw Exception('Mật khẩu cũ không chính xác.');
        }
      }
      throw Exception('Failed to update password: $e');
    }
  }

  /// 6. HÀM CŨ (Vẫn cần cho nhân viên tự đổi tên)
  /// Cập nhật Tên trong cả 'users' và 'staff_profiles'
  Future<void> updateUserAndProfileName({
    required String userId,
    required String profileId,
    required String newName,
  }) async {
    try {
      // Cập nhật 'name' trong 'users' (để login/hiển thị)
      await pb.collection('users').update(userId, body: {'name': newName});
      // Cập nhật 'name' trong 'staff_profiles' (để quản lý)
      await pb
          .collection('staff_profiles')
          .update(profileId, body: {'name': newName});
    } catch (e) {
      print('UserService - Error updating name: $e');
      throw Exception('Failed to update name: $e');
    }
  }
}
