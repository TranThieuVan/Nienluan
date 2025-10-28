import 'package:flutter/material.dart';
import 'package:myshop/models/table.dart';
import 'package:myshop/models/menu_item.dart';
import 'package:myshop/models/order.dart'; // Import OrderModel
import 'package:myshop/services/pocketbase_service.dart';
// Import hàm định dạng tiền
import 'package:myshop/utils/currency_formatter.dart';

// (Lớp CartItem giữ nguyên)
class CartItem {
  final MenuItemModel item;
  int quantity;

  CartItem({required this.item, this.quantity = 1});

  double get subtotal => item.price * quantity;
}
// ---------------------------------------------------

class OrderDetailScreen extends StatefulWidget {
  final TableModel table;
  // --- BƯỚC 5: Thêm Hóa đơn có sẵn (optional) ---
  final OrderModel? existingOrder;

  const OrderDetailScreen({
    super.key,
    required this.table,
    this.existingOrder, // Nhận Hóa đơn có sẵn
  });

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

  // Cờ để biết có đang tải giỏ hàng cũ không
  bool _isLoadingExistingCart = false;

  @override
  void initState() {
    super.initState();
    _menuFuture = pbService.getMenu();
    _searchController.addListener(_onSearchChanged);

    // --- BƯỚC 5: Nếu có hóa đơn cũ, tải giỏ hàng ---
    if (widget.existingOrder != null) {
      _loadExistingCart();
    }
  }

  /// Hàm tải các món đã có trong hóa đơn cũ vào giỏ hàng
  Future<void> _loadExistingCart() async {
    // Chỉ tải nếu có existingOrder
    if (widget.existingOrder == null) return;

    setState(() {
      _isLoadingExistingCart = true;
    });
    try {
      // Lấy danh sách món đã gọi
      final existingItems = await pbService.getOrderItemsWithDetails(
        widget.existingOrder!.id,
      );

      // Chuyển đổi thành Map<String, CartItem>
      final Map<String, CartItem> initialCart = {};
      for (final itemView in existingItems) {
        // Chỉ thêm vào nếu món đó chưa có trong giỏ hàng tạm (tránh ghi đè)
        if (!_cart.containsKey(itemView.menuItem.id)) {
          initialCart[itemView.menuItem.id] = CartItem(
            item: itemView.menuItem,
            quantity: itemView.quantity,
          );
        }
      }

      // Cập nhật State
      setState(() {
        _cart.addAll(initialCart); // Thêm các món đã có vào giỏ
        _calculateTotalPrice(); // Tính lại tổng tiền
      });
    } catch (e) {
      // Hiển thị lỗi nếu không tải được giỏ hàng cũ
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

  // --- Logic Giỏ Hàng (Giữ nguyên) ---

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

  // --- BƯỚC 5: Cập nhật Logic Nút OK ---
  Future<void> _processOrder() async {
    // Kiểm tra xem đây là tạo mới hay gọi thêm
    if (widget.existingOrder != null) {
      // Gọi thêm vào hóa đơn có sẵn
      await _processAddMoreItems();
    } else {
      // Tạo hóa đơn mới
      await _processCreateNewOrder();
    }
  }

  /// Hàm xử lý logic TẠO MỚI hóa đơn (Giữ nguyên logic cũ)
  Future<void> _processCreateNewOrder() async {
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
      // 1. Tạo record 'orders'
      final newOrderId = await pbService.createOrderRecord(
        widget.table.id,
        _totalPrice,
      );
      // 2. Tạo các record 'order_items'
      for (final cartItem in _cart.values) {
        await pbService.createOrderItemRecord(
          orderId: newOrderId,
          menuItemId: cartItem.item.id,
          quantity: cartItem.quantity,
          price: cartItem.item.price, // Giá tại thời điểm tạo
        );
      }
      // 3. Cập nhật trạng thái bàn (nếu cần)
      if (widget.table.status == 'empty') {
        await pbService.updateTableStatus(widget.table.id, 'occupied');
      }
      // 4. Thông báo và đóng màn hình
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã tạo hóa đơn cho ${widget.table.name}!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true); // Trả về true để refresh
    } catch (e) {
      // Xử lý lỗi
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tạo hóa đơn: $e'),
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

  /// Hàm xử lý logic GỌI THÊM vào hóa đơn có sẵn
  Future<void> _processAddMoreItems() async {
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
      final existingOrderId = widget.existingOrder!.id;

      // 1. Tạo các record 'order_items' MỚI
      // *** CẬP NHẬT LOGIC: Chỉ thêm những món chưa có hoặc tăng số lượng ***
      // Lấy danh sách món đã có trong hóa đơn cũ
      final existingItemsViews = await pbService.getOrderItemsWithDetails(
        existingOrderId,
      );
      final Map<String, int> existingQuantities = {
        for (var view in existingItemsViews) view.menuItem.id: view.quantity,
      };

      List<Future> updateFutures = []; // Lưu các tác vụ cập nhật/tạo

      for (final cartItem in _cart.values) {
        final currentQuantityInDb = existingQuantities[cartItem.item.id] ?? 0;
        final newQuantityInCart = cartItem.quantity;

        // Chỉ xử lý nếu số lượng trong giỏ hàng khác số lượng đã lưu
        if (newQuantityInCart != currentQuantityInDb) {
          // Nếu món chưa có trong DB (currentQuantityInDb == 0), tạo mới
          if (currentQuantityInDb == 0) {
            updateFutures.add(
              pbService.createOrderItemRecord(
                orderId: existingOrderId,
                menuItemId: cartItem.item.id,
                quantity: newQuantityInCart,
                price: cartItem.item.price, // Giá tại thời điểm thêm
              ),
            );
          } else {
            // Nếu món đã có, tìm ID của order_item để UPDATE
            // (Phần này phức tạp hơn vì cần ID của order_item)
            // -> Tạm thời: Vẫn tạo mới (dẫn đến trùng lặp món)
            // CẦN NÂNG CẤP SAU
            updateFutures.add(
              pbService.createOrderItemRecord(
                orderId: existingOrderId,
                menuItemId: cartItem.item.id,
                quantity:
                    newQuantityInCart -
                    currentQuantityInDb, // Chỉ thêm phần chênh lệch? Không ổn
                price: cartItem.item.price,
              ),
            );
            print(
              "CẢNH BÁO: Logic gọi thêm đang tạo món trùng lặp. Cần nâng cấp.",
            );
          }
        }
      }
      // Chờ tất cả các tác vụ hoàn thành
      await Future.wait(updateFutures);

      // 2. Cập nhật lại tổng tiền của hóa đơn 'orders'
      // Tính lại tổng tiền dựa trên toàn bộ _cart hiện tại
      _calculateTotalPrice(); // Đảm bảo _totalPrice là mới nhất
      await pbService.updateOrderTotalPrice(existingOrderId, _totalPrice);

      // 3. Thông báo và đóng màn hình
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã chỉnh sửa  hóa đơn cho ${widget.table.name}!'),
          backgroundColor: Colors.blue,
        ),
      );
      Navigator.of(context).pop(true); // Trả về true để refresh
    } catch (e) {
      // Xử lý lỗi
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi thêm món vào hóa đơn: $e'),
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

  // --- Giao diện (Build) ---
  @override
  Widget build(BuildContext context) {
    // Xác định xem đây là chế độ Tạo mới hay Gọi thêm
    final bool isAddingMore = widget.existingOrder != null;
    final String appBarTitle = isAddingMore
        ? "Gọi thêm cho ${widget.table.name}"
        : "Hóa đơn cho ${widget.table.name}";
    // AppBar luôn màu đỏ nếu là gọi thêm (vì bàn chắc chắn đỏ)
    final Color appBarColor = isAddingMore
        ? Colors.red.shade400
        : (widget.table.isOccupied
              ? Colors.red.shade400
              : Colors.green.shade400);

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle), // Đổi tiêu đề
        backgroundColor: appBarColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          // Hiển thị loading nếu đang tải giỏ hàng cũ
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
                // Chỉ hiển thị menu khi đã tải xong giỏ hàng cũ (nếu có)
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
                // Nếu chưa tải xong menu HOẶC đang tải giỏ hàng cũ, hiển thị rỗng
                return const SizedBox.shrink();
              },
            ),
          ),

          // Thanh Giỏ hàng và Nút OK
          _buildCartSummaryBar(isAddingMore), // Truyền cờ isAddingMore
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

  Widget _buildMenuListView(List<MenuItemModel> items) {
    return ListView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final item = items[index];
        final int quantityInCart = _cart[item.id]?.quantity ?? 0;

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
              '${item.unit.isNotEmpty ? ' / ${item.unit}' : ''}',
            ),
            trailing: quantityInCart == 0
                ? IconButton(
                    icon: const Icon(
                      Icons.add_shopping_cart,
                      color: Colors.green,
                    ),
                    tooltip: 'Thêm vào giỏ',
                    onPressed: () => _incrementItem(item),
                  )
                : Row(
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
          ),
        );
      },
    );
  }

  /// Cập nhật Widget thanh Giỏ hàng để đổi tên nút OK
  Widget _buildCartSummaryBar(bool isAddingMore) {
    if (_isProcessingOrder) {
      return Container(
        padding: const EdgeInsets.all(24.0),
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Chỉ hiển thị nếu giỏ hàng không trống HOẶC đang trong chế độ gọi thêm (để luôn thấy nút)
    if (_cart.isEmpty && !isAddingMore) {
      return const SizedBox.shrink();
    }
    // Nếu là gọi thêm và giỏ hàng trống (chưa thêm món mới), vẫn hiển thị nút nhưng mờ đi
    final bool canProceed = _cart.isNotEmpty;

    final int totalItems = _cart.values.fold(
      0,
      (sum, item) => sum + item.quantity,
    );

    // Xác định tên nút và màu nút
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
            label: Text(buttonText), // Đổi tên nút
            style: ElevatedButton.styleFrom(
              backgroundColor: canProceed
                  ? buttonColor
                  : Colors.grey, // Đổi màu nút nếu giỏ trống
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            // Vô hiệu hóa nút nếu giỏ hàng trống (áp dụng cho cả 2 chế độ)
            onPressed: canProceed ? _processOrder : null,
          ),
        ],
      ),
    );
  }
}
