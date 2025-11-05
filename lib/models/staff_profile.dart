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

  // --- THÊM CÁC TRƯỜNG MỚI CHO LỊCH ---
  final String workType; // 'full_time', 'part_time'
  final List<String> defaultDays; // ['T2', 'T3', 'T4', ...]
  final List<String> defaultShifts; // ['Ca sáng', 'Ca chiều', ...]
  // --- KẾT THÚC THÊM ---

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
    // --- THÊM VÀO CONSTRUCTOR ---
    required this.workType,
    this.defaultDays = const [], // Mặc định là list rỗng
    this.defaultShifts = const [], // Mặc định là list rỗng
  });

  factory StaffProfile.fromRecord(RecordModel record) {
    User? expandedUser;
    if (record.expand.containsKey('user_account')) {
      final userRecordList = record.expand['user_account'] as List;
      if (userRecordList.isNotEmpty) {
        expandedUser = User.fromRecord(userRecordList.first);
      }
    }

    // Chuyển đổi List<dynamic> (từ PocketBase) -> List<String>
    final days = List<String>.from(record.data['default_days'] ?? []);
    final shifts = List<String>.from(record.data['default_shifts'] ?? []);

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

      // --- LẤY DỮ LIỆU TỪ RECORD ---
      workType: record.getStringValue('work_type'),
      defaultDays: days,
      defaultShifts: shifts,
    );
  }

  bool get hasLoginAccount => userId != null && userId!.isNotEmpty;
  String get email => userAccount?.email ?? 'N/A';
}
