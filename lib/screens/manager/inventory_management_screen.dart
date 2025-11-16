// [TẠO FILE MỚI: lib/screens/manager/inventory_management_screen.dart]

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myshop/models/ingredient.dart';
import 'package:myshop/services/pocketbase_service.dart';
import 'package:myshop/utils/currency_formatter.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() =>
      _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  final pbService = PocketBaseService.instance;
  late Future<List<Ingredient>> _ingredientsFuture;

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    if (mounted) {
      setState(() {
        _ingredientsFuture = pbService.inventory.getIngredients();
      });
    }
  }

  void _showIngredientDialog({Ingredient? ingredient}) {
    showDialog(
      context: context,
      builder: (context) {
        return _IngredientFormDialog(
          ingredient: ingredient,
          onSave: () {
            _loadIngredients(); // Tải lại danh sách sau khi lưu
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Kho'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Ingredient>>(
        future: _ingredientsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          final ingredients = snapshot.data ?? [];
          if (ingredients.isEmpty) {
            return const Center(
              child: Text('Kho trống. Hãy thêm nguyên vật liệu.'),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadIngredients,
            child: ListView.builder(
              itemCount: ingredients.length,
              itemBuilder: (context, index) {
                final ingredient = ingredients[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.brown.shade100,
                    child: Text(
                      ingredient.unit,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.brown.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(ingredient.name),
                  subtitle: Text(
                    'Tồn kho: ${ingredient.stockQuantity} ${ingredient.unit}',
                  ),
                  trailing: Text(
                    formatCurrency(ingredient.costPerUnit),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () => _showIngredientDialog(ingredient: ingredient),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showIngredientDialog(),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// --- WIDGET DIALOG (Form) ---

class _IngredientFormDialog extends StatefulWidget {
  final Ingredient? ingredient;
  final VoidCallback onSave;

  const _IngredientFormDialog({this.ingredient, required this.onSave});

  @override
  State<_IngredientFormDialog> createState() => _IngredientFormDialogState();
}

class _IngredientFormDialogState extends State<_IngredientFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final pbService = PocketBaseService.instance;
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _unitController;
  late TextEditingController _costController;
  late TextEditingController _stockController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.ingredient?.name);
    _unitController = TextEditingController(text: widget.ingredient?.unit);
    _costController = TextEditingController(
      text: widget.ingredient?.costPerUnit.toString() ?? '0',
    );
    _stockController = TextEditingController(
      text: widget.ingredient?.stockQuantity.toString() ?? '0',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _costController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      final name = _nameController.text;
      final unit = _unitController.text;
      final cost = double.tryParse(_costController.text) ?? 0.0;
      final stock = double.tryParse(_stockController.text) ?? 0.0;

      if (widget.ingredient == null) {
        // Tạo mới
        await pbService.inventory.createIngredient(
          name: name,
          unit: unit,
          costPerUnit: cost,
          stockQuantity: stock,
        );
      } else {
        // Cập nhật
        await pbService.inventory.updateIngredient(
          id: widget.ingredient!.id,
          name: name,
          unit: unit,
          costPerUnit: cost,
          stockQuantity: stock,
        );
      }

      widget.onSave();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lưu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.ingredient != null;
    return AlertDialog(
      title: Text(isEditing ? 'Sửa Nguyên vật liệu' : 'Thêm Nguyên vật liệu'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên (vd: Bò)'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Không được bỏ trống' : null,
              ),
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(labelText: 'Đơn vị (vd: kg)'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Không được bỏ trống' : null,
              ),
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(
                  labelText: 'Giá vốn / đơn vị',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                validator: (v) =>
                    (double.tryParse(v ?? '') == null) ? 'Phải là số' : null,
              ),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Số lượng tồn kho',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                validator: (v) =>
                    (double.tryParse(v ?? '') == null) ? 'Phải là số' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: Text(_isLoading ? 'Đang lưu...' : 'Lưu'),
        ),
      ],
    );
  }
}
