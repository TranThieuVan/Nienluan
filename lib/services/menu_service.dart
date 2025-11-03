// lib/services/menu_service.dart

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:myshop/models/menu_item.dart';

/// Lớp Service chuyên xử lý các thao tác liên quan đến Collection 'menu_items'
class MenuService {
  final PocketBase pb;

  // Constructor nhận instance PocketBase
  MenuService(this.pb);

  /// 1. Lấy (Read) danh sách món ăn
  Future<List<MenuItemModel>> getMenu() async {
    try {
      final records = await pb
          .collection('menu_items')
          .getFullList(sort: 'name'); // Sửa: Tải TẤT CẢ món để quản lý

      return records
          .map((record) => MenuItemModel.fromRecord(record, pb))
          .toList();
    } catch (e) {
      print('MenuService - Error fetching menu: $e');
      throw Exception('Failed to load menu: $e');
    }
  }

  /// 2. Thêm (Create) một món ăn mới (có thể kèm hình ảnh)
  Future<void> addMenuItem({
    required String name,
    required double price,
    required String category,
    required String unit,
    required bool inStock,
    String? description,
    XFile? imageFile, // Từ package image_picker
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'price': price,
        'category': category,
        'unit': unit,
        'in_stock': inStock,
        'description': description ?? '',
      };

      // --- PHẦN SỬA LỖI ---
      // Khởi tạo list non-nullable (không thể null)
      final List<http.MultipartFile> files = [];

      if (imageFile != null) {
        // Thêm vào list nếu file tồn tại
        files.add(
          await http.MultipartFile.fromPath(
            'image', // Tên trường 'image' trong PocketBase
            imageFile.path,
            filename: imageFile.name,
          ),
        );
      }
      // --- KẾT THÚC PHẦN SỬA ---

      // 'files' giờ luôn là List<MultipartFile> (có thể rỗng, nhưng không null)
      await pb.collection('menu_items').create(body: body, files: files);
    } catch (e) {
      print('MenuService - Error adding menu item: $e');
      throw Exception('Failed to add menu item: $e');
    }
  }

  /// 3. Cập nhật (Update) một món ăn
  Future<void> updateMenuItem({
    required String id,
    required String name,
    required double price,
    required String category,
    required String unit,
    required bool inStock,
    String? description,
    XFile? newImageFile, // Hình ảnh mới (nếu thay đổi)
    bool deleteExistingImage = false, // Cờ để xóa ảnh cũ
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'price': price,
        'category': category,
        'unit': unit,
        'in_stock': inStock,
        'description': description ?? '',
      };

      if (deleteExistingImage) {
        body['image'] = null; // Gán null để xóa ảnh
      }

      // --- PHẦN SỬA LỖI ---
      // Khởi tạo list non-nullable (không thể null)
      final List<http.MultipartFile> files = [];

      if (newImageFile != null) {
        // Thêm vào list nếu file tồn tại
        files.add(
          await http.MultipartFile.fromPath(
            'image',
            newImageFile.path,
            filename: newImageFile.name,
          ),
        );
      }
      // --- KẾT THÚC PHẦN SỬA ---

      // 'files' giờ luôn là List<MultipartFile> (có thể rỗng, nhưng không null)
      await pb.collection('menu_items').update(id, body: body, files: files);
    } catch (e) {
      print('MenuService - Error updating menu item: $e');
      throw Exception('Failed to update menu item: $e');
    }
  }

  /// 4. Xóa (Delete) một món ăn
  Future<void> deleteMenuItem(String id) async {
    try {
      await pb.collection('menu_items').delete(id);
    } catch (e) {
      print('MenuService - Error deleting menu item: $e');
      throw Exception('Failed to delete menu item: $e');
    }
  }
}
