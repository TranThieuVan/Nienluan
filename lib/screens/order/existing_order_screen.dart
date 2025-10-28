import 'package:flutter/material.dart';
import 'package:myshop/models/table.dart';
import 'package:myshop/models/order.dart';
import 'package:myshop/models/order_item_view.dart';
import 'package:myshop/services/pocketbase_service.dart';
import 'package:myshop/utils/currency_formatter.dart';
// *** BƯỚC 5: Import OrderDetailScreen ***
import 'order_detail_screen.dart';

class ExistingOrderScreen extends StatefulWidget {
  final TableModel table;

  const ExistingOrderScreen({super.key, required this.table});

  @override
  State<ExistingOrderScreen> createState() => _ExistingOrderScreenState();
}

class _ExistingOrderScreenState extends State<ExistingOrderScreen> {
  final pbService = PocketBaseService.instance;

  late Future<bool> _orderDataFuture;
  OrderModel? _order;
  List<OrderItemView> _items = [];
  double _totalPrice = 0.0;
  bool _isProcessingCheckout = false;

  @override
  void initState() {
    super.initState();
    _orderDataFuture = _loadOrderData();
  }

  /// Hàm tải thông tin hóa đơn và các món đã gọi
  Future<bool> _loadOrderData() async {
    // Tạm thời set loading để tránh lỗi null
    setState(() {
      _order = null;
      _items = [];
      _totalPrice = 0.0;
    });
    try {
      final order = await pbService.getPendingOrderForTable(widget.table.id);
      if (order == null) {
        throw Exception('Không tìm thấy hóa đơn "pending" nào cho bàn này.');
      }
      final items = await pbService.getOrderItemsWithDetails(order.id);
      double total = 0.0;
      for (var item in items) {
        total += item.subtotal;
      }
      // Cập nhật state sau khi đã có dữ liệu
      if (mounted) {
        setState(() {
          _order = order;
          _items = items;
          _totalPrice = total;
        });
      }
      return true;
    } catch (e) {
      print('Lỗi khi tải _loadOrderData: $e');
      rethrow;
    }
  }

  /// *** BƯỚC 5: Cập nhật Logic cho nút "Gọi thêm" ***
  void _onOrderMore() async {
    // Đảm bảo _order đã được tải
    if (_order == null) return;

    // 1. Điều hướng đến `OrderDetailScreen`
    //    Truyền `widget.table` VÀ `_order` (existingOrder)
    final bool? didUpdate = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(
          table: widget.table,
          existingOrder: _order, // Quan trọng: Truyền hóa đơn hiện tại
        ),
      ),
    );

    // 2. Nếu `OrderDetailScreen` trả về true (đã thêm món thành công)
    //    thì tải lại dữ liệu hóa đơn hiện tại để cập nhật danh sách món
    if (didUpdate == true && mounted) {
      // Gọi lại hàm load data để cập nhật _items và _totalPrice
      setState(() {
        // Đặt lại future để FutureBuilder chạy lại
        _orderDataFuture = _loadOrderData();
      });
    }
  }

  /// Logic cho nút "Thanh toán"
  void _onCheckout() async {
    if (_order == null) return;

    final bool? didConfirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận Thanh Toán'),
          content: Text(
            'Bạn có chắc muốn thanh toán hóa đơn cho ${widget.table.name}?\n\n'
            'Tổng tiền: ${formatCurrency(_totalPrice)}',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('XÁC NHẬN'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (didConfirm != true) return;

    setState(() {
      _isProcessingCheckout = true;
    });

    try {
      await pbService.checkoutOrder(_order!.id, widget.table.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thanh toán thành công cho ${widget.table.name}!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true); // Trả về true để refresh EmployeeHome
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi thanh toán: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingCheckout = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chi tiết Bàn ${widget.table.name}"),
        backgroundColor: Colors.red.shade400, // Bàn đỏ
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<bool>(
        future: _orderDataFuture,
        builder: (context, snapshot) {
          // Trạng thái Đang tải...
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text('Đang tải thông tin hóa đơn...'),
                ],
              ),
            );
          }

          // Trạng thái Lỗi
          if (snapshot.hasError || _order == null) {
            // Thêm kiểm tra _order null
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  // Thêm Column để hiển thị nút thử lại
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 40,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Lỗi tải dữ liệu hóa đơn: ${snapshot.error ?? "Không tìm thấy hóa đơn"}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => setState(() {
                        _orderDataFuture = _loadOrderData(); // Gọi lại future
                      }),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Trạng thái Thành công (Hiển thị dữ liệu)
          return Column(
            children: [
              // Phần 1: Tiêu đề và Tổng tiền
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Các món đã gọi (${_items.length})',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      formatCurrency(_totalPrice),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Phần 2: Danh sách các món đã gọi
              Expanded(
                child: _items.isEmpty
                    ? const Center(
                        child: Text("Chưa có món nào được gọi."),
                      ) // Xử lý trường hợp không có item
                    : ListView.builder(
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return ListTile(
                            leading:
                                (item.menuItem.imageUrl != null &&
                                    item
                                        .menuItem
                                        .imageUrl!
                                        .isNotEmpty) // Kiểm tra imageUrl không rỗng
                                ? Image.network(
                                    item.menuItem.imageUrl!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.broken_image,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  )
                                : const SizedBox(
                                    width: 50,
                                    height: 50,
                                    child: Icon(
                                      Icons.fastfood,
                                      color: Colors.grey,
                                    ),
                                  ),
                            title: Text(
                              item.menuItem.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${item.quantity} x ${formatCurrency(item.price)}',
                            ),
                            trailing: Text(
                              formatCurrency(item.subtotal),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Phần 3: Các nút hành động
              if (_isProcessingCheckout)
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                )
              else
                _buildActionButtons(),
            ],
          );
        },
      ),
    );
  }

  // Widget: Các nút hành động "Gọi thêm" và "Thanh toán"
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Chỉnh sửa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: _onOrderMore, // ĐÃ SỬA: Gọi hàm điều hướng
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.payment),
              label: const Text('Thanh Toán'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: _onCheckout,
            ),
          ),
        ],
      ),
    );
  }
}
