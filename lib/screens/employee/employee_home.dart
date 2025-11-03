import 'package:flutter/material.dart';
import 'package:myshop/services/pocketbase_service.dart';
import 'package:myshop/screens/auth/login_screen.dart';
import 'package:myshop/models/table.dart';
// Import các màn hình Order
import 'package:myshop/screens/order/order_detail_screen.dart';
import 'package:myshop/screens/order/existing_order_screen.dart';
// Import màn hình mới
import 'package:myshop/screens/order/completed_orders_screen.dart';
// --- IMPORT WIDGET MỚI ĐƯỢC TẠO ---
import 'package:myshop/widgets/table_grid_view.dart';
import 'package:myshop/screens/employee/employee_profile_screen.dart'; // <-- THÊM IMPORT NÀY

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
  }

  // Phương thức tải/làm mới danh sách bàn
  Future<void> _loadTables() async {
    // Dùng async để có thể dùng hàm này cho RefreshIndicator
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

  /// Hàm xử lý khi nhấn vào bàn: Điều hướng đến màn hình tạo hoặc xem hóa đơn.
  void _onTableTapped(TableModel table) async {
    bool? didUpdate;

    if (table.isOccupied) {
      // BÀN ĐỎ (CÓ KHÁCH) -> Mở màn hình Xem/Gọi thêm Hóa đơn
      didUpdate = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => ExistingOrderScreen(table: table),
        ),
      );
    } else {
      // BÀN XANH (TRỐNG) -> Mở màn hình Tạo Hóa đơn mới
      didUpdate = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => OrderDetailScreen(table: table),
        ),
      );
    }

    // TỰ ĐỘNG REFRESH nếu có cập nhật trạng thái bàn
    if (didUpdate == true && mounted) {
      await _loadTables();
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
          // ----- TRẠNG THÁI LOADING -----
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ----- TRẠNG THÁI LỖI -----
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

          // ----- TRẠNG THÁI KHÔNG CÓ DỮ LIỆU -----
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
          // SỬ DỤNG WIDGET TableGridView ĐÃ TÁCH
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
