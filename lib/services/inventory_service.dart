// [DÁN TOÀN BỘ CODE NÀY VÀO lib/services/inventory_service.dart]

import 'package:pocketbase/pocketbase.dart';
import 'package:myshop/models/ingredient.dart';
import 'package:myshop/models/menu_item_ingredient.dart';

class InventoryService {
  final PocketBase pb;

  InventoryService(this.pb);

  // --- 1. QUẢN LÝ NGUYÊN VẬT LIỆU ---

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

  Future<void> deleteIngredient(String id) async {
    try {
      await pb.collection('ingredients').delete(id);
    } catch (e) {
      print('InventoryService - deleteIngredient Error: $e');
      throw Exception('Lỗi xóa nguyên vật liệu: $e');
    }
  }

  // --- 2. QUẢN LÝ CÔNG THỨC ---

  Future<List<MenuItemIngredient>> getIngredientsForMenuItem(
    String menuItemId,
  ) async {
    try {
      final records = await pb
          .collection('menu_item_ingredients')
          .getFullList(
            filter: 'menu_item = "$menuItemId"',
            expand: 'ingredient',
          );
      return records.map((r) => MenuItemIngredient.fromRecord(r)).toList();
    } catch (e) {
      print('InventoryService - getIngredientsForMenuItem Error: $e');
      throw Exception('Lỗi tải công thức: $e');
    }
  }

  // --- HÀM MỚI ---
  /// Thêm một nguyên liệu vào công thức
  Future<void> createMenuItemIngredient({
    required String menuItemId,
    required String ingredientId,
    required double quantityNeeded,
  }) async {
    try {
      await pb
          .collection('menu_item_ingredients')
          .create(
            body: {
              'menu_item': menuItemId,
              'ingredient': ingredientId,
              'quantity_needed': quantityNeeded,
            },
          );
    } catch (e) {
      print('InventoryService - createMenuItemIngredient Error: $e');
      throw Exception('Lỗi thêm vào công thức: $e');
    }
  }

  // --- HÀM MỚI ---
  /// Xóa một nguyên liệu khỏi công thức
  Future<void> deleteMenuItemIngredient(String recipeItemId) async {
    try {
      await pb.collection('menu_item_ingredients').delete(recipeItemId);
    } catch (e) {
      print('InventoryService - deleteMenuItemIngredient Error: $e');
      throw Exception('Lỗi xóa khỏi công thức: $e');
    }
  }
}
