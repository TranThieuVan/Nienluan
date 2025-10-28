import 'package:pocketbase/pocketbase.dart';

/// Enum định nghĩa các trạng thái của Hóa đơn
/// Giúp code an toàn hơn thay vì dùng String 'pending'
enum OrderStatus {
  pending,
  completed,
  paid;

  /// Chuyển đổi từ String (lấy từ DB) sang Enum
  static OrderStatus fromString(String? statusString) {
    switch (statusString) {
      case 'completed':
        return OrderStatus.completed;
      case 'paid':
        return OrderStatus.paid;
      default:
        return OrderStatus.pending; // Mặc định là 'pending'
    }
  }

  /// Chuyển đổi từ Enum sang String (để gửi lên DB)
  String toJson() {
    return name; // 'pending', 'completed', 'paid'
  }
}

class OrderModel {
  final String id;
  final String tableId; // ID của bàn (từ relation 'table')
  final OrderStatus status;
  final double totalPrice;
  final String? createdById; // ID của user (từ relation 'created_by')

  OrderModel({
    required this.id,
    required this.tableId,
    required this.status,
    required this.totalPrice,
    this.createdById, // Có thể null (vì không bắt buộc)
  });

  /// Phương thức factory để chuyển đổi từ PocketBase RecordModel
  factory OrderModel.fromRecord(RecordModel record) {
    final createdBy = record.getStringValue('created_by');

    return OrderModel(
      id: record.id,
      tableId: record.getStringValue('table'),
      status: OrderStatus.fromString(record.getStringValue('status')),
      totalPrice: record.getDoubleValue('total_price'),
      createdById: createdBy.isNotEmpty ? createdBy : null,
    );
  }

  // Chúng ta sẽ không cần 'toJson' ngay
  // vì khi tạo Hóa đơn, chúng ta sẽ gửi một Map<String, dynamic>
  // trực tiếp từ service layer.
}
