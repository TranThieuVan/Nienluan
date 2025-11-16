// [TẠO FILE MỚI: lib/services/inventory_service.dart]

import 'package:pocketbase/pocketbase.dart';
import 'package:myshop/models/ingredient.dart';
import 'package:myshop/models/menu_item_ingredient.dart';

class InventoryService {
  final PocketBase pb;

  InventoryService(this.pb);

  // --- 1. QUẢN LÝ NGUYÊN VẬT LIỆU ---

  /// Lấy tất cả nguyên vật liệu
  Future<List<Ingredient>> getIngredients() async {
    try {
      final records = await pb
          .collection('ingredients')
          .getFullList(sort: 'name');
      return records.map((r) => Ingredient.fromRecord(r)).toList();
    } catch (e) {
      print('InventoryService - getIngredients Error: $e');
      throw Exception('Lỗi tải nguyên vật liệu: $e');
    }
  }

  /// Thêm nguyên vật liệu mới
  Future<void> createIngredient({
    required String name,
    required String unit,
    required double costPerUnit,
    required double stockQuantity,
  }) async {
    try {
      await pb
          .collection('ingredients')
          .create(
            body: {
              'name': name,
              'unit': unit,
              'cost_per_unit': costPerUnit,
              'stock_quantity': stockQuantity,
            },
          );
    } catch (e) {
      print('InventoryService - createIngredient Error: $e');
      throw Exception('Lỗi tạo nguyên vật liệu: $e');
    }
  }

  /// Cập nhật nguyên vật liệu
  Future<void> updateIngredient({
    required String id,
    required String name,
    required String unit,
    required double costPerUnit,
    required double stockQuantity,
  }) async {
    try {
      await pb
          .collection('ingredients')
          .update(
            id,
            body: {
              'name': name,
              'unit': unit,
              'cost_per_unit': costPerUnit,
              'stock_quantity': stockQuantity,
            },
          );
    } catch (e) {
      print('InventoryService - updateIngredient Error: $e');
      throw Exception('Lỗi cập nhật nguyên vật liệu: $e');
    }
  }

  /// Xóa nguyên vật liệu
  Future<void> deleteIngredient(String id) async {
    try {
      await pb.collection('ingredients').delete(id);
    } catch (e) {
      print('InventoryService - deleteIngredient Error: $e');
      throw Exception('Lỗi xóa nguyên vật liệu: $e');
    }
  }

  // --- 2. QUẢN LÝ CÔNG THỨC (Sẽ dùng ở Giai đoạn 2) ---

  /// Lấy công thức (các nguyên liệu) của 1 món ăn
  Future<List<MenuItemIngredient>> getIngredientsForMenuItem(
    String menuItemId,
  ) async {
    try {
      final records = await pb
          .collection('menu_item_ingredients')
          .getFullList(
            filter: 'menu_item = "$menuItemId"',
            expand: 'ingredient', // Rất quan trọng
          );
      return records.map((r) => MenuItemIngredient.fromRecord(r)).toList();
    } catch (e) {
      print('InventoryService - getIngredientsForMenuItem Error: $e');
      throw Exception('Lỗi tải công thức: $e');
    }
  }

  // (Chúng ta sẽ thêm các hàm add/remove/update công thức sau)
}
