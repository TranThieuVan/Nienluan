import 'package:flutter/material.dart';
import 'package:myshop/services/pocketbase_service.dart';
import 'package:myshop/screens/auth/login_screen.dart';
import 'package:myshop/models/table.dart';
// Import các màn hình Order
import 'package:myshop/screens/order/order_detail_screen.dart';
import 'package:myshop/screens/order/existing_order_screen.dart';

class EmployeeHome extends StatefulWidget {
  const EmployeeHome({super.key});

  @override
  State<EmployeeHome> createState() => _EmployeeHomeState();
}

class _EmployeeHomeState extends State<EmployeeHome> {
  final PocketBaseService pbService = PocketBaseService.instance;

  late Future<List<TableModel>> _tablesFuture;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  void _loadTables() {
    setState(() {
      _tablesFuture = pbService.getTables();
    });
  }

  void _logout(BuildContext context) {
    pbService.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  // --- HÀM ĐIỀU HƯỚNG QUAN TRỌNG (ĐÃ CẬP NHẬT) ---
  void _onTableTapped(TableModel table) async {
    // `result` sẽ là `true` nếu màn hình con (Order/Thanh toán)
    // thực hiện một thay đổi và muốn màn hình này refresh.
    bool? didUpdate;

    if (table.isOccupied) {
      // ---------------------------------------------------
      // BÀN ĐỎ (CÓ KHÁCH) -> Mở màn hình Xem Hóa đơn
      // ---------------------------------------------------
      didUpdate = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => ExistingOrderScreen(
            table: table, // Truyền bàn có khách
          ),
        ),
      );
    } else {
      // ---------------------------------------------------
      // BÀN XANH (TRỐNG) -> Mở màn hình Tạo Hóa đơn
      // ---------------------------------------------------
      didUpdate = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => OrderDetailScreen(
            table: table, // Truyền bàn trống
            // (Không truyền existingOrder)
          ),
        ),
      );
    }

    // --- TỰ ĐỘNG REFRESH ---
    // Nếu màn hình con trả về `true` (ví dụ: sau khi Thanh toán hoặc Tạo HĐ)
    // thì tự động tải lại danh sách bàn.
    if (didUpdate == true && mounted) {
      _loadTables();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý Bàn"),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
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
                      'Lỗi tải danh sách bàn: Vui lòng kiểm tra API Rules của collection "tables" trên PocketBase.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Chi tiết lỗi: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
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
              onRefresh: () async => _loadTables(),
              child: ListView(
                // Dùng ListView để RefreshIndicator hoạt động
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
          return RefreshIndicator(
            onRefresh: () async {
              _loadTables();
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(12.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.0,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: tables.length,
              itemBuilder: (context, index) {
                final table = tables[index];
                final Color cardColor = table.isOccupied
                    ? Colors.red.shade400
                    : Colors.green.shade400;
                const Color textColor = Colors.white;

                return InkWell(
                  onTap: () => _onTableTapped(table), // GỌI HÀM ĐIỀU HƯỚNG
                  splashColor: Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                  child: Card(
                    elevation: 4.0,
                    color: cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            table.isOccupied
                                ? Icons.restaurant
                                : Icons.event_seat,
                            color: textColor,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            table.name,
                            style: const TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            table.displayStatus,
                            style: TextStyle(
                              color: textColor.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
