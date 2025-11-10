// [DÁN TOÀN BỘ CODE NÀY VÀO lib/models/staff_profile.dart]

import 'package:pocketbase/pocketbase.dart';
import 'package:myshop/models/staff_role.dart';
import 'package:myshop/models/user.dart';

class StaffProfile {
  final String id;
  final String name;
  final StaffRole role;
  final double salary;
  final String status;
  final String? userId;
  final DateTime created;
  final DateTime updated;
  final User? userAccount;

  // --- SỬA Ở ĐÂY (Đã xóa workType) ---
  final Map<String, List<String>> defaultSchedule;
  // --- KẾT THÚC SỬA ---

  StaffProfile({
    required this.id,
    required this.name,
    required this.role,
    this.salary = 0.0,
    this.status = 'active',
    this.userId,
    required this.created,
    required this.updated,
    this.userAccount,
    // --- SỬA CONSTRUCTOR ---
    this.defaultSchedule = const {},
  });

  factory StaffProfile.fromRecord(RecordModel record) {
    User? expandedUser;
    if (record.expand.containsKey('user_account')) {
      final userRecordList = record.expand['user_account'] as List;
      if (userRecordList.isNotEmpty) {
        expandedUser = User.fromRecord(userRecordList.first);
      }
    }

    // --- LOGIC ĐỌC JSON MỚI ---
    final scheduleData = record.data['default_schedule'];
    final Map<String, List<String>> schedule = {};

    // Khởi tạo tất cả các ngày
    const List<String> allDays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    for (var day in allDays) {
      schedule[day] = []; // Mặc định là danh sách rỗng
    }

    // Kiểm tra xem scheduleData có phải là Map không
    if (scheduleData is Map) {
      // Lặp qua từng entry (ví dụ: 'T2': ['Ca sáng', 'Ca chiều'])
      for (final entry in scheduleData.entries) {
        final key = entry.key as String;
        final value = entry.value;

        // Kiểm tra xem value có phải là List không
        if (value is List) {
          // Ghi đè lên danh sách rỗng nếu có dữ liệu
          schedule[key] = value.map((item) => item.toString()).toList();
        }
      }
    }
    // --- KẾT THÚC LOGIC ĐỌC JSON ---

    return StaffProfile(
      id: record.id,
      name: record.getStringValue('name'),
      role: StaffRole.fromString(record.getStringValue('role')),
      salary: record.getDoubleValue('salary'),
      status: record.getStringValue('status'),
      userId: record.getStringValue('user_account'),
      created: DateTime.parse(record.created),
      updated: DateTime.parse(record.updated),
      userAccount: expandedUser,
      // Gán map đã xử lý
      defaultSchedule: schedule,
    );
  }

  bool get hasLoginAccount => userId != null && userId!.isNotEmpty;
  String get email => userAccount?.email ?? 'N/A';
}
