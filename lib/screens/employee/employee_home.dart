// [DÁN TOÀN BỘ CODE NÀY VÀO lib/screens/employee/employee_home.dart]

import 'package:flutter/material.dart';
import 'package:myshop/services/pocketbase_service.dart';
import 'package:myshop/screens/auth/login_screen.dart';
import 'package:myshop/models/table.dart';
// Import các màn hình Order
import 'package:myshop/screens/order/order_detail_screen.dart';
import 'package:myshop/screens/order/existing_order_screen.dart';
// Import màn hình mới
import 'package:myshop/screens/order/completed_orders_screen.dart';
// Import widget
import 'package:myshop/widgets/table_grid_view.dart';
import 'package:myshop/screens/employee/employee_profile_screen.dart';
// --- DÒNG IMPORT ĐÚNG ---
import 'package:pocketbase/pocketbase.dart';

class EmployeeHome extends StatefulWidget {
  const EmployeeHome({super.key});

  @override
  State<EmployeeHome> createState() => _EmployeeHomeState();
}

class _EmployeeHomeState extends State<EmployeeHome> {
  final PocketBaseService pbService = PocketBaseService.instance;

  // Future lưu trữ trạng thái tải bàn
  late Future<List<TableModel>> _tablesFuture;

  @override
  void initState() {
    super.initState();
    _loadTables();
    // --- GỌI HÀM ĐĂNG KÝ REALTIME ---
    _subscribeToTableChanges();
  }

  // --- HÀM MỚI: HỦY ĐĂNG KÝ KHI RỜI MÀN HÌNH ---
  @override
  void dispose() {
    _unsubscribeFromTableChanges();
    super.dispose();
  }

  // --- HÀM MỚI: ĐĂNG KÝ LẮNG NGHE THAY ĐỔI ---
  void _subscribeToTableChanges() {
    print('Đang đăng ký lắng nghe collection "tables"...');
    pbService.pb.collection('tables').subscribe('*', _handleTableEvent);
  }

  // --- HÀM MỚI: HỦY ĐĂNG KÝ ---
  void _unsubscribeFromTableChanges() {
    print('Đang hủy lắng nghe collection "tables"...');
    pbService.pb.collection('tables').unsubscribe('*');
  }

  // =========================================================
  // --- HÀM MỚI: XỬ LÝ KHI CÓ THAY ĐỔI (ĐÃ SỬA TÊN LỚP) ---
  void _handleTableEvent(RealtimeCallbackEvent e) {
    // <--- ĐÂY LÀ DÒNG ĐÃ SỬA
    print('Sự kiện Realtime: Bàn ${e.record?.id} đã ${e.action}');
    if (mounted) {
      // Khi có bất kỳ thay đổi nào (ai đó tạo/sửa/xóa bàn)
      // Tải lại toàn bộ danh sách bàn
      _loadTables();
    }
  }
  // =========================================================

  // Phương thức tải/làm mới danh sách bàn (giữ nguyên)
  Future<void> _loadTables() async {
    if (mounted) {
      setState(() {
        _tablesFuture = pbService.getTables();
      });
    }
    await _tablesFuture; // Chờ Future hoàn thành
  }

  void _logout(BuildContext context) {
    pbService.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void _navigateToCompletedOrders() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CompletedOrdersScreen()),
    );
  }

  /// Hàm xử lý khi nhấn vào bàn (giữ nguyên)
  void _onTableTapped(TableModel table) async {
    bool? didUpdate;

    if (table.isOccupied) {
      didUpdate = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => ExistingOrderScreen(table: table),
        ),
      );
    } else {
      didUpdate = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => OrderDetailScreen(table: table),
        ),
      );
    }

    if (didUpdate == true && mounted) {
      // (Dòng này không cần thiết nữa vì Realtime đã xử lý)
      // await _loadTables();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý Bàn"),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.account_circle, color: Colors.white, size: 30),
          tooltip: 'Tài khoản',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const EmployeeProfileScreen(),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long, color: Colors.white),
            tooltip: 'Xem hóa đơn đã hoàn thành',
            onPressed: _navigateToCompletedOrders,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Đăng xuất',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: FutureBuilder<List<TableModel>>(
        future: _tablesFuture,
        builder: (context, snapshot) {
          // ----- (Các trạng thái Loading, Error, Empty giữ nguyên) -----
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 40,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Lỗi tải danh sách bàn. Chi tiết: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _loadTables,
                      child: const Text('Thử tải lại'),
                    ),
                  ],
                ),
              ),
            );
          }
          final tables = snapshot.data!;
          if (tables.isEmpty) {
            return RefreshIndicator(
              onRefresh: _loadTables,
              child: ListView(
                children: [
                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * 0.3,
                      ),
                      child: const Text(
                        'Không tìm thấy bàn nào. Vui lòng thêm bàn trên PocketBase.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // ----- TRẠNG THÁI THÀNH CÔNG (CÓ DỮ LIỆU) -----
          return TableGridView(
            tables: tables,
            onRefresh: _loadTables,
            onTableTapped: _onTableTapped,
          );
        },
      ),
    );
  }
}
