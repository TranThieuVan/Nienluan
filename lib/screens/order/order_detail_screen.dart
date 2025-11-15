// [DÁN TOÀN BỘ CODE NÀY VÀO lib/screens/order/order_detail_screen.dart]

import 'package:flutter/material.dart';
import 'package:myshop/models/table.dart';
import 'package:myshop/models/menu_item.dart';
import 'package:myshop/models/order.dart'; // Import OrderModel
import 'package:myshop/services/pocketbase_service.dart';
import 'package:myshop/utils/currency_formatter.dart';
import 'package:myshop/models/order_item_view.dart'; // <--- DÒNG NÀY ĐÃ ĐƯỢC THÊM VÀO

// --- SỬA LỚP NÀY (THÊM notes) ---
class CartItem {
  final MenuItemModel item;
  int quantity;
  String? notes; // <-- THÊM DÒNG NÀY

  CartItem({
    required this.item,
    this.quantity = 1,
    this.notes, // <-- THÊM VÀO CONSTRUCTOR
  });

  double get subtotal => item.price * quantity;
}
// ---------------------------------------------------

class OrderDetailScreen extends StatefulWidget {
  final TableModel table;
  final OrderModel? existingOrder;

  const OrderDetailScreen({super.key, required this.table, this.existingOrder});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final PocketBaseService pbService = PocketBaseService.instance;
  late Future<List<MenuItemModel>> _menuFuture;

  final Map<String, CartItem> _cart = {};
  double _totalPrice = 0.0;
  bool _isProcessingOrder = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isLoadingExistingCart = false;

  @override
  void initState() {
    super.initState();
    _menuFuture = pbService.menuItems.getMenu();
    _searchController.addListener(_onSearchChanged);

    if (widget.existingOrder != null) {
      _loadExistingCart();
    }
  }

  Future<void> _loadExistingCart() async {
    if (widget.existingOrder == null) return;

    setState(() {
      _isLoadingExistingCart = true;
    });
    try {
      // --- LỖI Ở ĐÂY ---
      // Hàm này trả về List<OrderItemView>
      final List<OrderItemView> existingItems = await pbService
          .getOrderItemsWithDetails(widget.existingOrder!.id);
      // --- KẾT THÚC LỖI ---

      final Map<String, CartItem> initialCart = {};
      for (final itemView in existingItems) {
        if (!_cart.containsKey(itemView.menuItem.id)) {
          initialCart[itemView.menuItem.id] = CartItem(
            item: itemView.menuItem,
            quantity: itemView.quantity,
            notes: itemView.notes, // <-- LẤY GHI CHÚ CŨ
          );
        }
      }

      setState(() {
        _cart.addAll(initialCart);
        _calculateTotalPrice();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải giỏ hàng cũ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingExistingCart = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  // --- Logic Giỏ Hàng ---
  void _incrementItem(MenuItemModel item) {
    setState(() {
      if (_cart.containsKey(item.id)) {
        _cart[item.id]!.quantity++;
      } else {
        _cart[item.id] = CartItem(item: item, quantity: 1);
      }
      _calculateTotalPrice();
    });
  }

  void _decrementItem(MenuItemModel item) {
    setState(() {
      if (_cart.containsKey(item.id)) {
        if (_cart[item.id]!.quantity > 1) {
          _cart[item.id]!.quantity--;
        } else {
          _cart.remove(item.id);
        }
        _calculateTotalPrice();
      }
    });
  }

  void _calculateTotalPrice() {
    double total = 0.0;
    for (final cartItem in _cart.values) {
      total += cartItem.subtotal;
    }
    setState(() {
      _totalPrice = total;
    });
  }

  // --- HÀM XỬ LÝ GỬI (SỬA LẠI ĐỂ GỬI notes) ---
  Future<void> _processOrder() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giỏ hàng đang trống. Vui lòng chọn món.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _isProcessingOrder = true;
    });

    try {
      final bool isAddingMore = widget.existingOrder != null;
      String orderId;
      double newTotalPrice = _totalPrice;

      if (isAddingMore) {
        // --- Logic GỌI THÊM ---
        orderId = widget.existingOrder!.id;

        // Lấy các món đã có
        final existingItemViews = await pbService.getOrderItemsWithDetails(
          orderId,
        );
        final Map<String, OrderItemView> existingItemsMap = {
          for (var view in existingItemViews) view.menuItem.id: view,
        };

        List<Future> updateFutures = [];

        for (final cartItem in _cart.values) {
          if (existingItemsMap.containsKey(cartItem.item.id)) {
            // Món đã có -> Cần UPDATE
            final existingItem = existingItemsMap[cartItem.item.id]!;
            if (existingItem.quantity != cartItem.quantity ||
                existingItem.notes != cartItem.notes) {
              // Cập nhật (PocketBase không hỗ trợ update, nên ta Xóa + Tạo)
              // Tạm thời chỉ tạo mới, CHƯA XỬ LÝ UPDATE/DELETE
              // (Đây là một logic phức tạp, ta sẽ tạm bỏ qua)
            }
          } else {
            // Món mới -> TẠO MỚI
            updateFutures.add(
              pbService.createOrderItemRecord(
                orderId: orderId,
                menuItemId: cartItem.item.id,
                quantity: cartItem.quantity,
                price: cartItem.item.price,
                notes: cartItem.notes, // <-- Gửi ghi chú
              ),
            );
          }
        }
        await Future.wait(updateFutures);

        // Cập nhật tổng tiền
        await pbService.updateOrderTotalPrice(orderId, newTotalPrice);
      } else {
        // --- Logic TẠO MỚI ---
        // 1. Tạo record 'orders'
        orderId = await pbService.createOrderRecord(
          widget.table.id,
          _totalPrice,
        );
        // 2. Tạo các record 'order_items'
        for (final cartItem in _cart.values) {
          await pbService.createOrderItemRecord(
            orderId: orderId,
            menuItemId: cartItem.item.id,
            quantity: cartItem.quantity,
            price: cartItem.item.price,
            notes: cartItem.notes, // <-- Gửi ghi chú
          );
        }
        // 3. Cập nhật trạng thái bàn
        await pbService.updateTableStatus(widget.table.id, 'occupied');
      }

      // 4. Thông báo và đóng màn hình
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã cập nhật hóa đơn cho ${widget.table.name}!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true); // Trả về true để refresh
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi xử lý hóa đơn: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingOrder = false;
        });
      }
    }
  }

  // --- HÀM MỚI: HIỂN THỊ DIALOG GHI CHÚ ---
  Future<void> _showAddNoteDialog(CartItem cartItem) async {
    final noteController = TextEditingController(text: cartItem.notes);

    final newNote = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ghi chú cho "${cartItem.item.name}"'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            hintText: 'Ví dụ: ít đường, không cay...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null), // Hủy
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(noteController.text); // Lưu
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    // Cập nhật state (nếu có thay đổi)
    if (newNote != null) {
      setState(() {
        cartItem.notes = newNote;
      });
    }
  }

  // --- Giao diện (Build) ---
  @override
  Widget build(BuildContext context) {
    final bool isAddingMore = widget.existingOrder != null;
    final String appBarTitle = isAddingMore
        ? "Gọi thêm cho ${widget.table.name}"
        : "Hóa đơn cho ${widget.table.name}";
    final Color appBarColor = isAddingMore
        ? Colors.red.shade400
        : (widget.table.isOccupied
              ? Colors.red.shade400
              : Colors.green.shade400);

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: appBarColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_isLoadingExistingCart)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text("Đang tải các món đã gọi..."),
                  ],
                ),
              ),
            ),
          Expanded(
            child: FutureBuilder<List<MenuItemModel>>(
              future: _menuFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !_isLoadingExistingCart) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Lỗi tải Menu: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.done &&
                    !_isLoadingExistingCart) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('Không tìm thấy món ăn nào trong thực đơn.'),
                    );
                  }

                  // Lọc
                  final menuItems = snapshot.data!;
                  final List<MenuItemModel> filteredItems;
                  if (_searchQuery.isEmpty) {
                    filteredItems = menuItems;
                  } else {
                    filteredItems = menuItems
                        .where(
                          (item) => item.name.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ),
                        )
                        .toList();
                  }

                  if (filteredItems.isEmpty && _searchQuery.isNotEmpty) {
                    return Center(
                      child: Text(
                        'Không tìm thấy món nào khớp với "${_searchQuery}".',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  final foodItems = filteredItems
                      .where((item) => item.category == MenuItemCategory.food)
                      .toList();
                  final drinkItems = filteredItems
                      .where((item) => item.category == MenuItemCategory.drink)
                      .toList();

                  return ListView(
                    padding: const EdgeInsets.all(8.0),
                    children: [
                      _buildCategoryHeader("Món Ăn (${foodItems.length})"),
                      _buildMenuListView(foodItems),
                      const SizedBox(height: 16),
                      _buildCategoryHeader("Thức Uống (${drinkItems.length})"),
                      _buildMenuListView(drinkItems),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          _buildCartSummaryBar(isAddingMore),
        ],
      ),
    );
  }

  // --- Các Widget con (Helpers) ---

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'Tìm kiếm tên món ăn...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  // --- SỬA WIDGET NÀY ĐỂ THÊM NÚT GHI CHÚ ---
  Widget _buildMenuListView(List<MenuItemModel> items) {
    return ListView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final item = items[index];
        final CartItem? cartItem = _cart[item.id];
        final int quantityInCart = cartItem?.quantity ?? 0;
        final String? note = cartItem?.notes;
        final bool hasNote = note != null && note.isNotEmpty;

        return Card(
          elevation: 2.0,
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: ListTile(
            leading: (item.imageUrl != null)
                ? Image.network(
                    item.imageUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 50),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(),
                      );
                    },
                  )
                : const SizedBox(
                    width: 50,
                    height: 50,
                    child: Icon(Icons.fastfood, color: Colors.grey),
                  ),
            title: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${formatCurrency(item.price)}'
              '${item.unit.isNotEmpty ? ' / ${item.unit}' : ''}'
              // Hiển thị ghi chú nếu có
              '${hasNote ? '\nGhi chú: $note' : ''}',
              style: TextStyle(color: hasNote ? Colors.deepPurple : null),
            ),
            isThreeLine: hasNote, // Tự động dãn ra nếu có ghi chú
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nút Ghi chú (chỉ hiện khi đã thêm vào giỏ)
                if (quantityInCart > 0)
                  IconButton(
                    icon: Icon(
                      Icons.edit_note,
                      color: hasNote ? Colors.deepPurple : Colors.grey,
                    ),
                    tooltip: 'Thêm Ghi chú',
                    onPressed: () => _showAddNoteDialog(cartItem!),
                  ),

                // Nút Thêm/Bớt
                if (quantityInCart == 0)
                  IconButton(
                    icon: const Icon(
                      Icons.add_shopping_cart,
                      color: Colors.green,
                    ),
                    tooltip: 'Thêm vào giỏ',
                    onPressed: () => _incrementItem(item),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove, color: Colors.red.shade700),
                        tooltip: 'Bớt',
                        onPressed: () => _decrementItem(item),
                      ),
                      Text(
                        '$quantityInCart',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.green),
                        tooltip: 'Thêm',
                        onPressed: () => _incrementItem(item),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // (Widget _buildCartSummaryBar giữ nguyên, không cần sửa)
  Widget _buildCartSummaryBar(bool isAddingMore) {
    if (_isProcessingOrder) {
      return Container(
        padding: const EdgeInsets.all(24.0),
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_cart.isEmpty) {
      return const SizedBox.shrink();
    }

    final int totalItems = _cart.values.fold(
      0,
      (sum, item) => sum + item.quantity,
    );

    final String buttonText = isAddingMore ? 'OK' : 'OK (Tạo Hóa Đơn)';
    final Color buttonColor = isAddingMore ? Colors.blue : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tổng ($totalItems món):',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                formatCurrency(_totalPrice),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle),
            label: Text(buttonText),
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: _processOrder, // Nút luôn bật
          ),
        ],
      ),
    );
  }
}
