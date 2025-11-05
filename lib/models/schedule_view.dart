import 'package:myshop/models/schedule_exception.dart';
import 'package:myshop/models/staff_profile.dart';
import 'package:intl/intl.dart';

// Enum thể hiện trạng thái làm việc cuối cùng
enum WorkStatus { working, absent, offDay }

// Lớp chứa thông tin ca làm việc đã được tổng hợp
class DailySchedule {
  final WorkStatus status;
  final List<String> shifts; // Các ca làm việc (VD: ['Ca sáng', 'Ca chiều'])

  DailySchedule({required this.status, this.shifts = const []});
}

// Lớp Logic chính
class ScheduleView {
  final StaffProfile profile;
  final List<ScheduleExceptionModel> exceptions;
  final Map<int, String> _weekdayMap = {
    1: 'T2',
    7: 'CN',
    2: 'T3',
    3: 'T4',
    4: 'T5',
    5: 'T6',
    6: 'T7',
  };

  ScheduleView({required this.profile, required this.exceptions});

  // Hàm quan trọng nhất: Trả về lịch làm việc cho một ngày cụ thể
  DailySchedule getScheduleForDay(DateTime date) {
    // 1. Kiểm tra "Ngoại lệ" (Exceptions) trước - (Ưu tiên cao nhất)
    for (final ex in exceptions) {
      if (isSameDay(ex.date, date)) {
        if (ex.type == ScheduleExceptionType.absent) {
          return DailySchedule(status: WorkStatus.absent); // Nghỉ
        }
        if (ex.type == ScheduleExceptionType.extraShift) {
          return DailySchedule(
            status: WorkStatus.working,
            shifts: [ex.shift ?? 'Ca làm thêm'], // Làm thêm
          );
        }
      }
    }

    // 2. Kiểm tra "Lịch Cố Định" (Default Schedule)
    final String weekday = _weekdayMap[date.weekday]!; // Lấy T2, T3...

    // Nếu hôm đó KHÔNG có trong danh sách ngày làm cố định
    if (!profile.defaultDays.contains(weekday)) {
      return DailySchedule(status: WorkStatus.offDay); // Ngày nghỉ
    }

    // Nếu hôm đó CÓ trong lịch làm cố định
    return DailySchedule(
      status: WorkStatus.working,
      shifts: profile.defaultShifts, // Lấy các ca cố định
    );
  }

  // Hàm helper kiểm tra 2 ngày có trùng nhau không
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
