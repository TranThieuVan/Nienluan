import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:myshop/models/table.dart';
import 'package:myshop/models/menu_item.dart'; // Vẫn cần cho getOrderItemsWithDetails
import 'package:myshop/models/order.dart';
import 'package:myshop/models/order_item_view.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'notification_service.dart'; // <-- THÊM IMPORT MỚI
import 'schedule_service.dart'; // <-- THÊM IMPORT MỚI
// Import các service con
import 'user_service.dart';
import 'menu_service.dart'; // <-- IMPORT SERVICE MỚI
// Import các view model
import 'package:myshop/models/order_view.dart'; // <-- SỬA LẠI IMPORT

class PocketBaseService {
  // --- Singleton Pattern ---
  static final PocketBaseService _instance = PocketBaseService._internal();
  factory PocketBaseService() => _instance;
  static PocketBaseService get instance => _instance;

  final PocketBase pb;
  // --- Các service con ---
  late final UserService users; // Service quản lý người dùng
  late final MenuService menuItems; // <-- THÊM SERVICE MỚI
  late final NotificationService notifications; // <-- THÊM DÒNG NÀY
  late final ScheduleService schedules; // <-- THÊM DÒNG NÀY

  PocketBaseService._internal()
    // Lấy URL từ .env, fallback về localhost
    : pb = PocketBase(dotenv.env['POCKETBASE_URL'] ?? 'http://127.0.0.1:8091') {
    // Khởi tạo service con, truyền instance `pb` hiện có
    users = UserService(pb);
    menuItems = MenuService(pb); // <-- KHỞI TẠO SERVICE MỚI
    notifications = NotificationService(pb); // <-- KHỞI TẠO NÓ
    schedules = ScheduleService(pb); // <-- KHỞI TẠO NÓ
  }
  // --- Hết phần Singleton ---

  // --- Chức Năng Xác Thực ---
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

  // --- Chức Năng Quản Lý Bàn ---
  Future<List<TableModel>> getTables() async {
    try {
      // 1. Lấy danh sách từ PocketBase
      // (Không cần sort ở đây nữa, vì chúng ta sẽ sort bằng Dart)
      final records = await pb.collection('tables').getFullList();

      // 2. Chuyển đổi (map) thành List<TableModel>
      final tables = records
          .map((record) => TableModel.fromRecord(record))
          .toList();

      // 3. Sắp xếp (sort) lại danh sách bằng logic của Dart
      tables.sort((a, b) {
        // Lấy số từ tên của bàn a và b bằng hàm helper
        final numA = _extractTableNumber(a.name);
        final numB = _extractTableNumber(b.name);

        // So sánh 2 số đó
        return numA.compareTo(numB);
      });

      // 4. Trả về danh sách đã được sắp xếp
      return tables;
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
  //
  // *** HÀM getMenu() ĐÃ BỊ XÓA KHỎI ĐÂY (ĐÃ CHUYỂN QUA MenuService) ***
  //
  // --- Chức Năng Tạo Hóa Đơn Mới ---
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

  // --- CÁC HÀM CHO LOGIC BÀN ĐÃ CÓ KHÁCH ---

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

          // Vẫn cần `pb` instance để gọi `MenuItemModel.fromRecord`
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

  /// 3. Xử lý "Thanh toán"
  Future<void> checkoutOrder(String orderId, String tableId) async {
    try {
      await pb.collection('orders').update(orderId, body: {'status': 'paid'});

      await pb.collection('tables').update(tableId, body: {'status': 'empty'});
    } catch (e) {
      print('Error during checkout: $e');
      throw Exception('Failed to process checkout: $e');
    }
  }

  // --- HÀM CHO "GỌI THÊM" ---

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

  // [Bên trong lớp PocketBaseService]

  /// (Hàm helper) Thoát các giá trị chuỗi để dùng trong filter
  /// Nó thay thế dấu ' thành ''
  String _escapeFilterValue(String value) {
    return value.replaceAll("'", "''");
  }

  /// Lấy danh sách các hóa đơn đã hoàn thành ('paid')
  /// có thể lọc theo ngày VÀ/HOẶC từ khóa tìm kiếm (ID)
  Future<List<OrderViewModel>> getCompletedOrders({
    DateTime? selectedDate,
    String? searchTerm,
  }) async {
    try {
      final now = DateTime.now();

      // --- PHẦN SỬA LỖI LỌC NGÀY ---
      DateTime startDateTimeLocal;
      DateTime endDateTimeLocal;

      if (selectedDate != null) {
        // Lọc theo 1 ngày: Lấy từ 00:00:00 đến 23:59:59 của ngày đó (giờ ĐỊA PHƯƠNG)
        startDateTimeLocal = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          0,
          0,
          0, // 00:00:00
        );
        endDateTimeLocal = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          23,
          59,
          59, // 23:59:59
        );
      } else {
        // Mặc định (30 ngày): Lấy từ 00:00:00 của 30 ngày trước
        final thirtyDaysAgo = now.subtract(const Duration(days: 30));
        startDateTimeLocal = DateTime(
          thirtyDaysAgo.year,
          thirtyDaysAgo.month,
          thirtyDaysAgo.day,
          0,
          0,
          0,
        );
        // Đến 23:59:59 của ngày hôm nay
        endDateTimeLocal = DateTime(now.year, now.month, now.day, 23, 59, 59);
      }

      // Chuyển đổi sang chuỗi UTC mà PocketBase có thể hiểu
      final startFilter = startDateTimeLocal.toUtc().toIso8601String();
      final endFilter = endDateTimeLocal.toUtc().toIso8601String();
      // --- KẾT THÚC PHẦN SỬA LỖI ---

      // --- Xây dựng Filter động (BẰNG TAY) ---
      List<String> filters = [
        'status = "paid"',
        // Dùng dấu nháy đơn ' và giá trị UTC đã chuẩn hóa
        'created >= \'$startFilter\'',
        'created <= \'$endFilter\'',
      ];

      // Thêm điều kiện tìm kiếm (nếu có)
      if (searchTerm != null && searchTerm.isNotEmpty) {
        final escapedTerm = _escapeFilterValue(searchTerm);
        filters.add('id ~ \'$escapedTerm\'');
      }

      final filterString = filters.join(' && ');
      // --- Kết thúc xây dựng Filter ---

      final records = await pb
          .collection('orders')
          .getFullList(
            filter: filterString, // Gửi chuỗi filter đã build
            sort: '-created',
            expand: 'table,created_by',
          );

      return records.map((record) {
        // ... (logic map của bạn giữ nguyên)
        RecordModel? tableRecord;
        final tableExpand = record.get<List<RecordModel>>('expand.table');
        if (tableExpand.isNotEmpty) {
          tableRecord = tableExpand.first;
        }
        RecordModel? creatorRecord;
        final creatorExpand = record.get<List<RecordModel>>(
          'expand.created_by',
        );
        if (creatorExpand.isNotEmpty) {
          creatorRecord = creatorExpand.first;
        }
        return OrderViewModel.fromRecord(record, tableRecord, creatorRecord);
      }).toList();
    } catch (e) {
      print('Error fetching completed orders: $e');
      throw Exception('Failed to load completed orders: $e');
    }
  }

  int _extractTableNumber(String name) {
    // Dùng RegExp để tìm tất cả các chữ số trong tên
    final match = RegExp(r'\d+').firstMatch(name);
    if (match != null) {
      // Nếu tìm thấy số, chuyển nó thành int
      return int.tryParse(match.group(0)!) ?? 0;
    }
    // Nếu không tìm thấy số (ví dụ: "Bàn VIP"), trả về 0 hoặc một số lớn
    return 0;
  }
} // End of PocketBaseService
