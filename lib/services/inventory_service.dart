import 'package:pocketbase/pocketbase.dart';
import 'package:myshop/models/ingredient.dart';
import 'package:myshop/models/menu_item_ingredient.dart';
import 'package:myshop/models/order_item_view.dart';

class InventoryService {
  final PocketBase pb;

  InventoryService(this.pb);

  // ============================================
  // 1. QUẢN LÝ NGUYÊN VẬT LIỆU
  // ============================================

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

  // ============================================
  // 2. QUẢN LÝ CÔNG THỨC
  // ============================================

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

  Future<void> deleteMenuItemIngredient(String recipeItemId) async {
    try {
      await pb.collection('menu_item_ingredients').delete(recipeItemId);
    } catch (e) {
      print('InventoryService - deleteMenuItemIngredient Error: $e');
      throw Exception('Lỗi xóa khỏi công thức: $e');
    }
  }

  // ============================================
  // ⭐ NEW: UPDATE MỘT NGUYÊN LIỆU TRONG CÔNG THỨC
  // ============================================

  Future<void> updateMenuItemIngredient({
    required String recipeItemId,
    required double quantityNeeded,
  }) async {
    try {
      await pb
          .collection('menu_item_ingredients')
          .update(recipeItemId, body: {'quantity_needed': quantityNeeded});
    } catch (e) {
      print('InventoryService - updateMenuItemIngredient Error: $e');
      throw Exception('Lỗi cập nhật công thức: $e');
    }
  }

  // ============================================
  // 3. TỰ ĐỘNG TRỪ KHO KHI TẠO HÓA ĐƠN
  // ============================================

  Future<void> deductStockForOrder(List<OrderItemView> itemsInOrder) async {
    print('Bắt đầu trừ kho...');
    try {
      // Lấy danh sách id menu item
      final menuItemIdFilter =
          '(${itemsInOrder.map((item) => "menu_item.id = '${item.menuItem.id}'").join(' || ')})';

      final allRecipes = await pb
          .collection('menu_item_ingredients')
          .getFullList(filter: menuItemIdFilter);

      // Tính tổng cần trừ
      final Map<String, double> deductionMap = {};

      for (final itemInOrder in itemsInOrder) {
        final recipesForThisItem = allRecipes.where(
          (recipe) =>
              recipe.getStringValue('menu_item') == itemInOrder.menuItem.id,
        );

        for (final recipe in recipesForThisItem) {
          final ingredientId = recipe.getStringValue('ingredient');
          final quantityNeeded = recipe.getDoubleValue('quantity_needed');

          final totalToDeduct = quantityNeeded * itemInOrder.quantity;

          deductionMap[ingredientId] =
              (deductionMap[ingredientId] ?? 0) + totalToDeduct;
        }
      }

      print('Sẽ trừ kho: $deductionMap');

      // Trừ kho bằng "-="
      for (final entry in deductionMap.entries) {
        final ingredientId = entry.key;
        final amountToDeduct = entry.value;

        try {
          await pb
              .collection('ingredients')
              .update(ingredientId, body: {'stock_quantity-=': amountToDeduct});
        } catch (e) {
          print('LỖI NGHIÊM TRỌNG khi trừ kho cho $ingredientId: $e');
        }
      }

      print('Trừ kho hoàn tất.');
    } catch (e) {
      print('InventoryService - deductStockForOrder Error: $e');
    }
  }
}
