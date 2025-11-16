// [TẠO FILE MỚI: lib/screens/manager/recipe_management_screen.dart]

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myshop/models/ingredient.dart';
import 'package:myshop/models/menu_item.dart';
import 'package:myshop/models/menu_item_ingredient.dart';
import 'package:myshop/services/pocketbase_service.dart';
import 'package:myshop/utils/currency_formatter.dart';

class RecipeManagementScreen extends StatefulWidget {
  final MenuItemModel menuItem;
  const RecipeManagementScreen({super.key, required this.menuItem});

  @override
  State<RecipeManagementScreen> createState() => _RecipeManagementScreenState();
}

class _RecipeManagementScreenState extends State<RecipeManagementScreen> {
  final pbService = PocketBaseService.instance;
  late Future<List<MenuItemIngredient>> _recipeFuture;
  List<Ingredient> _allIngredients = []; // Cache
  double _totalCost = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Tải song song công thức của món VÀ tất cả nguyên liệu trong kho
    setState(() {
      _recipeFuture =
          Future.wait([
            pbService.inventory.getIngredientsForMenuItem(widget.menuItem.id),
            pbService.inventory.getIngredients(),
          ]).then((results) {
            final recipeItems = results[0] as List<MenuItemIngredient>;
            _allIngredients = results[1] as List<Ingredient>;
            _calculateTotalCost(recipeItems);
            return recipeItems;
          });
    });
  }

  void _calculateTotalCost(List<MenuItemIngredient> recipeItems) {
    double total = 0.0;
    for (var item in recipeItems) {
      total += item.cost;
    }
    setState(() {
      _totalCost = total;
    });
  }

  // Cập nhật giá vốn (cost) mới vào collection 'menu_items'
  Future<void> _updateMenuItemCost() async {
    try {
      await pbService.menu.updateMenuItem(
        id: widget.menuItem.id,
        name: widget.menuItem.name,
        price: widget.menuItem.price,
        category: widget.menuItem.category == MenuItemCategory.food
            ? 'food'
            : 'drink',
        inStock: widget.menuItem.inStock,
        unit: widget.menuItem.unit,
        description: widget.menuItem.description,
        currentImageFilename: widget.menuItem.image,
        cost: _totalCost, // Cập nhật giá vốn mới
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật tổng giá vốn cho món ăn!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật giá vốn: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addIngredient() async {
    // Hiển thị Dialog chọn nguyên liệu
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) =>
          _AddIngredientDialog(allIngredients: _allIngredients),
    );

    if (result != null) {
      try {
        await pbService.inventory.createMenuItemIngredient(
          menuItemId: widget.menuItem.id,
          ingredientId: result['ingredient'].id,
          quantityNeeded: result['quantity'],
        );
        _loadData(); // Tải lại công thức
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi thêm nguyên liệu: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteIngredient(String recipeItemId) async {
    try {
      await pbService.inventory.deleteMenuItemIngredient(recipeItemId);
      _loadData(); // Tải lại công thức
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xóa nguyên liệu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Công thức: ${widget.menuItem.name}'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Lưu tổng giá vốn',
            onPressed: _updateMenuItemCost, // <-- Nút lưu giá vốn
          ),
        ],
      ),
      body: FutureBuilder<List<MenuItemIngredient>>(
        future: _recipeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          final recipeItems = snapshot.data ?? [];

          return Column(
            children: [
              Expanded(
                child: recipeItems.isEmpty
                    ? const Center(child: Text('Chưa có nguyên liệu nào.'))
                    : ListView.builder(
                        itemCount: recipeItems.length,
                        itemBuilder: (context, index) {
                          final item = recipeItems[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(item.ingredient.unit),
                            ),
                            title: Text(item.ingredient.name),
                            subtitle: Text(
                              'Số lượng: ${item.quantityNeeded} ${item.ingredient.unit}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => _deleteIngredient(item.id),
                            ),
                          );
                        },
                      ),
              ),
              // Thanh tổng kết ở dưới cùng
              BottomAppBar(
                color: Colors.white,
                elevation: 10,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tổng Giá Vốn:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        formatCurrency(_totalCost),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addIngredient,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// --- DIALOG CHỌN NGUYÊN VẬT LIỆU ---
class _AddIngredientDialog extends StatefulWidget {
  final List<Ingredient> allIngredients;
  const _AddIngredientDialog({required this.allIngredients});

  @override
  State<_AddIngredientDialog> createState() => _AddIngredientDialogState();
}

class _AddIngredientDialogState extends State<_AddIngredientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  Ingredient? _selectedIngredient;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm Nguyên liệu'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<Ingredient>(
              value: _selectedIngredient,
              decoration: const InputDecoration(labelText: 'Chọn Nguyên liệu'),
              items: widget.allIngredients.map((ing) {
                return DropdownMenuItem(
                  value: ing,
                  child: Text('${ing.name} (${ing.unit})'),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedIngredient = val;
                });
              },
              validator: (val) => val == null ? 'Vui lòng chọn' : null,
            ),
            TextFormField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText:
                    'Số lượng cần dùng (${_selectedIngredient?.unit ?? '...'})',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              validator: (val) {
                if (val == null || val.isEmpty) return 'Không được trống';
                if (double.tryParse(val) == null) return 'Phải là số';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'ingredient': _selectedIngredient,
                'quantity': double.parse(_quantityController.text),
              });
            }
          },
          child: const Text('Thêm'),
        ),
      ],
    );
  }
}
