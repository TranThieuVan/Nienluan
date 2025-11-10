// [FILE MỚI: lib/services/report_service.dart]

import 'package:pocketbase/pocketbase.dart';
import 'package:myshop/models/order.dart'; // Cần model Order

class ReportService {
  final PocketBase pb;

  ReportService(this.pb);

  /// Lấy danh sách các Order ĐÃ HOÀN THÀNH trong một khoảng thời gian
  Future<List<OrderModel>> getCompletedOrders(
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Đảm bảo endDate là cuối ngày (23:59:59)
    final endOfDay = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
    );

    // Format ngày sang chuỗi ISO 8601 mà PocketBase hiểu
    // (Lưu ý: PocketBase lưu giờ UTC, nên ta dùng toIso8601String)
    final String startISO = startDate.toIso8601String();
    final String endISO = endOfDay.toIso8601String();

    try {
      final records = await pb
          .collection('orders')
          .getFullList(
            // Lọc theo:
            // 1. Trạng thái là 'completed'
            // 2. Ngày tạo (created) >= ngày bắt đầu
            // 3. Ngày tạo (created) <= ngày kết thúc
            filter:
                'status = "completed" && created >= "$startISO" && created <= "$endISO"',
            sort: 'created', // Sắp xếp theo ngày
          );

      return records.map((record) => OrderModel.fromRecord(record)).toList();
    } catch (e) {
      print('ReportService - Error fetching completed orders: $e');
      throw Exception('Lỗi tải dữ liệu báo cáo: $e');
    }
  }

  // (Chúng ta sẽ thêm các hàm getBestSellers, getAttendance... vào đây sau)
}
