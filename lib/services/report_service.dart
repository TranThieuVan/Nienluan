// [DÁN TOÀN BỘ CODE NÀY VÀO lib/services/report_service.dart]

import 'package:pocketbase/pocketbase.dart';
import 'package:myshop/models/order.dart';
import 'package:myshop/models/menu_item.dart';
import 'package:myshop/models/best_seller_item.dart';
import 'package:collection/collection.dart'; // <-- Thư viện mới

class ReportService {
  final PocketBase pb;

  ReportService(this.pb);

  /// Lấy danh sách các Order ĐÃ HOÀN THÀNH trong một tháng
  Future<List<OrderModel>> getCompletedOrdersForMonth(
    DateTime selectedMonth,
  ) async {
    // 1. Tính ngày bắt đầu (luôn là ngày 1 của tháng)
    final startDate = DateTime(selectedMonth.year, selectedMonth.month, 1);

    // 2. Tính ngày kết thúc
    final now = DateTime.now();
    DateTime endDate;

    if (selectedMonth.year == now.year && selectedMonth.month == now.month) {
      // Nếu là tháng hiện tại, lấy đến ngày/giờ hiện tại
      endDate = now;
    } else {
      // Nếu là tháng cũ, lấy đến 23:59:59 của ngày cuối tháng
      endDate = DateTime(
        selectedMonth.year,
        selectedMonth.month + 1,
        0,
        23,
        59,
        59,
      );
    }

    final String startISO = startDate.toUtc().toIso8601String();
    final String endISO = endDate.toUtc().toIso8601String();

    try {
      final filter =
          'status = "paid" && created >= "$startISO" && created <= "$endISO"';
      final records = await pb
          .collection('orders')
          .getFullList(filter: filter, sort: 'created');
      return records.map((record) => OrderModel.fromRecord(record)).toList();
    } catch (e) {
      print('ReportService - Error fetching completed orders: $e');
      throw Exception('Lỗi tải dữ liệu báo cáo: $e');
    }
  }

  // --- HÀM MỚI ĐỂ LẤY TOP MÓN BÁN CHẠY ---
  Future<List<BestSellerItem>> getBestSellingItems(
    DateTime selectedMonth,
  ) async {
    // 1. Lấy tất cả các đơn đã thanh toán trong tháng
    final paidOrders = await getCompletedOrdersForMonth(selectedMonth);
    if (paidOrders.isEmpty) {
      return []; // Không có đơn nào, không có món nào
    }

    // 2. Tạo filter để lấy TẤT CẢ order_items từ các đơn trên
    // Ví dụ: (order.id = 'id1' || order.id = 'id2' || ...)
    final orderIdFilter =
        '(${paidOrders.map((o) => "order.id = '${o.id}'").join(' || ')})';

    try {
      // 3. Lấy tất cả order_items, và "expand" thông tin menu_item
      final allItems = await pb
          .collection('order_items')
          .getFullList(filter: orderIdFilter, expand: 'menu_item');

      // 4. Xử lý dữ liệu (Group by): Nhóm các món giống nhau lại
      final grouped = groupBy(allItems, (RecordModel item) {
        // Lấy ID của menu_item
        return item.getStringValue('menu_item');
      });

      final List<BestSellerItem> bestSellers = [];

      // 5. Cộng dồn số lượng
      for (var entry in grouped.entries) {
        int totalQuantity = 0;
        MenuItemModel? menuItem; // Chỉ cần lấy 1

        for (var itemRecord in entry.value) {
          totalQuantity += itemRecord.getIntValue('quantity');

          if (menuItem == null && itemRecord.expand.containsKey('menu_item')) {
            final expandedData = itemRecord.get<List<RecordModel>>(
              'expand.menu_item',
            );
            if (expandedData.isNotEmpty) {
              menuItem = MenuItemModel.fromRecord(expandedData.first, pb);
            }
          }
        }

        // Nếu (vì lý do nào đó) món đã bị xóa
        if (menuItem == null) {
          final firstItem = entry.value.first;
          menuItem = MenuItemModel.fromRecord(
            RecordModel({
              'id': firstItem.getStringValue('menu_item'),
              'collectionId': 'menu_items',
              'created': '',
              'updated': '',
              'name': 'Món đã bị xóa',
              'price': firstItem.getDoubleValue('price'),
              'category': 'food',
              'image': '',
              'in_stock': false,
              'unit': 'N/A',
            }),
            pb,
          );
        }

        bestSellers.add(
          BestSellerItem(menuItem: menuItem, totalQuantity: totalQuantity),
        );
      }

      // 6. Sắp xếp
      bestSellers.sort((a, b) => b.totalQuantity.compareTo(a.totalQuantity));
      return bestSellers;
    } catch (e) {
      print('ReportService - Error fetching best sellers: $e');
      throw Exception('Lỗi tải top món bán chạy: $e');
    }
  }
}
