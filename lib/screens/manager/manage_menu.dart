// lib/screens/manager/menu_management_screen.dart (File mới)

import 'package:flutter/material.dart';
import 'package:myshop/models/menu_item.dart';
import 'package:myshop/services/pocketbase_service.dart';
import 'package:myshop/utils/currency_formatter.dart';
// Import màn hình Form (sẽ tạo ở Bước 3)
import 'menu_item_form_screen.dart';

class ManageMenuScreen extends StatefulWidget {
  const ManageMenuScreen({super.key});

  @override
  State<ManageMenuScreen> createState() => _ManageMenuScreenState();
}

class _ManageMenuScreenState extends State<ManageMenuScreen> {
  final pbService = PocketBaseService.instance;
  late Future<List<MenuItemModel>> _menuFuture;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    if (mounted) {
      setState(() {
        _menuFuture = pbService.menuItems.getMenu();
      });
    }
  }

  // Hàm điều hướng đến Form (Sửa)
  void _navigateToForm(MenuItemModel? item) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => MenuItemFormScreen(menuItem: item),
          ),
        )
        .then((didUpdate) {
          if (didUpdate == true) {
            _loadMenu(); // Tải lại nếu có cập nhật
          }
        });

    // Tạm thời (trước khi có Bước 3)
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text('Chuyển đến form cho: ${item?.name ?? 'Món mới'}'),
    //   ),
    // );
  }

  // Hàm xử lý Xóa
  Future<void> _deleteItem(MenuItemModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận Xóa'),
        content: Text('Bạn có chắc muốn xóa món "${item.name}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await pbService.menuItems.deleteMenuItem(item.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã xóa "${item.name}"'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _loadMenu(); // Tải lại danh sách
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi xóa: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý Thực đơn"),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMenu,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: FutureBuilder<List<MenuItemModel>>(
        future: _menuFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Lỗi tải thực đơn: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: _loadMenu,
              child: ListView(
                children: const [Center(child: Text('Chưa có món ăn nào.'))],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadMenu,
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final imageUrl = item.imageUrl;

                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey.shade200,
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.broken_image,
                                    color: Colors.red,
                                  ),
                            )
                          : const Icon(Icons.fastfood, color: Colors.blueGrey),
                    ),
                  ),
                  title: Text(
                    item.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: item.inStock ? Colors.black : Colors.grey,
                      decoration: item.inStock
                          ? TextDecoration.none
                          : TextDecoration.lineThrough,
                    ),
                  ),
                  subtitle: Text(
                    '${formatCurrency(item.price)}/${item.unit} - (${item.displayCategory})',
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red.shade700,
                    ),
                    onPressed: () => _deleteItem(item),
                  ),
                  onTap: () => _navigateToForm(item), // Mở form Sửa
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(null), // Mở form Thêm
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Thêm Món'),
      ),
    );
  }
}
