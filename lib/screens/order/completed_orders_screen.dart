import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Để định dạng giờ
import 'package:myshop/services/pocketbase_service.dart'; // Import service và OrderViewModel
import 'package:myshop/utils/currency_formatter.dart'; // Import định dạng tiền
import 'package:myshop/screens/order/completed_order_detail_screen.dart'; // <-- IMPORT MỚI

class CompletedOrdersScreen extends StatefulWidget {
  const CompletedOrdersScreen({super.key});

  @override
  State<CompletedOrdersScreen> createState() => _CompletedOrdersScreenState();
}

class _CompletedOrdersScreenState extends State<CompletedOrdersScreen> {
  final pbService = PocketBaseService.instance;
  late Future<List<OrderViewModel>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    setState(() {
      _ordersFuture = pbService.getCompletedOrdersToday();
    });
  }

  // --- HÀM XỬ LÝ SỰ KIỆN BẤM VÀO HÓA ĐƠN ---
  void _navigateToDetail(OrderViewModel order) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => CompletedOrderDetailScreen(orderView: order),
          ),
        )
        .then((_) {
          // Khi quay lại từ màn hình chi tiết, tự động refresh danh sách
          _loadOrders();
        });
  }
  // ------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hóa Đơn Đã Hoàn Thành Hôm Nay'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<OrderViewModel>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          // Trạng thái Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Trạng thái Lỗi
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Lỗi tải danh sách hóa đơn: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // Trạng thái Không có dữ liệu
          final orders = snapshot.data;
          if (orders == null || orders.isEmpty) {
            return RefreshIndicator(
              // Thêm RefreshIndicator
              onRefresh: () async => _loadOrders(),
              child: ListView(
                // Dùng ListView để RefreshIndicator hoạt động
                children: [
                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * 0.3,
                      ),
                      child: const Text(
                        'Chưa có hóa đơn nào được hoàn thành hôm nay.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Trạng thái Thành công: Hiển thị danh sách
          return RefreshIndicator(
            // Thêm RefreshIndicator
            onRefresh: () async => _loadOrders(),
            child: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                // Định dạng thời gian tạo (ví dụ: 09:30 AM)
                final formattedTime = DateFormat(
                  'hh:mm a',
                ).format(order.created);

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 6.0,
                  ),
                  elevation: 2.0,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                    ),
                    title: Text(
                      '${order.tableName}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Thời gian: $formattedTime'),
                    trailing: Text(
                      formatCurrency(order.totalPrice),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.deepPurple,
                      ),
                    ),
                    // KÍCH HOẠT CHỨC NĂNG ONTAP
                    onTap: () => _navigateToDetail(order),
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
