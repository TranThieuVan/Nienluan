// LỖI 1 ĐÃ SỬA: Dư "package"
import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:myshop/models/table.dart';
import 'package:myshop/models/menu_item.dart';
import 'package:myshop/models/order.dart';
// import 'package:myshop/models/order_item.dart'; // Không cần
import 'package:myshop/models/order_item_view.dart';

class PocketBaseService {
  // --- Singleton Pattern (Giữ nguyên) ---
  static final PocketBaseService _instance = PocketBaseService._internal();
  factory PocketBaseService() => _instance;
  static PocketBaseService get instance => _instance;

  final PocketBase pb;

  PocketBaseService._internal()
    : pb = PocketBase(dotenv.env['POCKETBASE_URL'] ?? 'http://127.0.0.1:8091');
  // --- Hết phần Singleton ---

  // --- Chức Năng Xác Thực (Giữ nguyên) ---
  Future<void> login(String email, String password) async {
    try {
      await pb.collection('users').authWithPassword(email, password);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  String getRole() {
    return pb.authStore.record?.getStringValue('role') ?? '';
  }

  void logout() {
    pb.authStore.clear();
  }

  // --- Chức Năng Quản Lý Bàn (Giữ nguyên) ---
  Future<List<TableModel>> getTables() async {
    try {
      final records = await pb.collection('tables').getFullList(sort: 'name');
      return records.map((record) => TableModel.fromRecord(record)).toList();
    } catch (e) {
      print('Error fetching tables: $e');
      throw Exception('Failed to load tables: $e');
    }
  }

  Future<void> updateTableStatus(String tableId, String newStatus) async {
    try {
      await pb
          .collection('tables')
          .update(tableId, body: {'status': newStatus});
    } catch (e) {
      print('Error updating table status: $e');
      throw Exception('Failed to update table: $e');
    }
  }

  // --- Chức Năng Quản Lý Menu ---
  Future<List<MenuItemModel>> getMenu() async {
    try {
      final records = await pb
          .collection('menu_items')
          .getFullList(sort: 'name', filter: 'in_stock = true');
      // Sửa lại: Dùng (record, pb) - 2 tham số vị trí
      return records
          .map((record) => MenuItemModel.fromRecord(record, pb))
          .toList();
    } catch (e) {
      print('Error fetching menu: $e');
      throw Exception('Failed to load menu: $e');
    }
  }

  // --- Chức Năng Tạo Hóa Đơn Mới (Giữ nguyên) ---
  Future<String> createOrderRecord(String tableId, double totalPrice) async {
    try {
      final record = await pb
          .collection('orders')
          .create(
            body: {
              'table': tableId,
              'total_price': totalPrice,
              'status': 'pending',
              'created_by': pb.authStore.record?.id,
            },
          );
      return record.id;
    } catch (e) {
      print('Error creating order record: $e');
      throw Exception('Failed to create order record: $e');
    }
  }

  Future<void> createOrderItemRecord({
    required String orderId,
    required String menuItemId,
    required int quantity,
    required double price,
  }) async {
    try {
      await pb
          .collection('order_items')
          .create(
            body: {
              'order': orderId,
              'menu_item': menuItemId,
              'quantity': quantity,
              'price': price,
            },
          );
    } catch (e) {
      print('Error creating order item record: $e');
      throw Exception('Failed to create order item record: $e');
    }
  }

  // --- CÁC HÀM MỚI CHO LOGIC BÀN ĐÃ CÓ KHÁCH ---

  /// 1. Tìm hóa đơn (order) 'pending' của một bàn
  Future<OrderModel?> getPendingOrderForTable(String tableId) async {
    try {
      final record = await pb
          .collection('orders')
          .getFirstListItem('table = "$tableId" && status = "pending"');
      return OrderModel.fromRecord(record);
    } on ClientException catch (e) {
      if (e.statusCode == 404) {
        return null;
      }
      throw Exception('Error fetching pending order: $e');
    } catch (e) {
      throw Exception('Error fetching pending order: $e');
    }
  }

  /// 2. Lấy tất cả các món (order_items) của một hóa đơn
  Future<List<OrderItemView>> getOrderItemsWithDetails(String orderId) async {
    try {
      final records = await pb
          .collection('order_items')
          .getFullList(filter: 'order = "$orderId"', expand: 'menu_item');

      return records.map((record) {
        final expandedData = record.get<List<RecordModel>>('expand.menu_item');

        if (expandedData.isEmpty) {
          final fakeRecord = RecordModel({
            'id': 'deleted',
            'collectionId': 'menu_items',
            'created': DateTime.now().toIso8601String(),
            'updated': DateTime.now().toIso8601String(),
            'name': 'Món đã bị xóa',
            'price': record.getDoubleValue('price'),
            'category': 'food',
            'image': '',
            'in_stock': false,
            'unit': '',
            'description': '',
          });

          final deletedMenuItem = MenuItemModel.fromRecord(fakeRecord, pb);

          return OrderItemView(
            id: record.id,
            quantity: record.getIntValue('quantity'),
            price: record.getDoubleValue('price'),
            menuItem: deletedMenuItem,
          );
        }

        final menuItemRecord = expandedData.first;
        final menuItem = MenuItemModel.fromRecord(menuItemRecord, pb);

        return OrderItemView(
          id: record.id,
          quantity: record.getIntValue('quantity'),
          price: record.getDoubleValue('price'),
          menuItem: menuItem,
        );
      }).toList();
    } catch (e) {
      print('Error fetching order items: $e');
      throw Exception('Failed to load order items: $e');
    }
  }

  /// 3. Xử lý "Thanh toán" (Giữ nguyên)
  Future<void> checkoutOrder(String orderId, String tableId) async {
    try {
      await pb.collection('orders').update(orderId, body: {'status': 'paid'});

      await pb.collection('tables').update(tableId, body: {'status': 'empty'});
    } catch (e) {
      print('Error during checkout: $e');
      throw Exception('Failed to process checkout: $e');
    }
  }

  // --- HÀM MỚI CHO "GỌI THÊM" ---

  /// 4. Cập nhật tổng tiền cho một hóa đơn đã tồn tại
  Future<void> updateOrderTotalPrice(
    String orderId,
    double newTotalPrice,
  ) async {
    try {
      await pb
          .collection('orders')
          .update(orderId, body: {'total_price': newTotalPrice});
    } catch (e) {
      print('Error updating order total price: $e');
      throw Exception('Failed to update order total price: $e');
    }
  }
}
