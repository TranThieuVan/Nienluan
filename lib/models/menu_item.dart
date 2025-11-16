// [DÁN TOÀN BỘ CODE NÀY VÀO lib/models/menu_item.dart]

import 'package:pocketbase/pocketbase.dart';

enum MenuItemCategory { food, drink }

class MenuItemModel {
  final String id;
  final String name;
  final double price;
  final MenuItemCategory category;
  final String? image;
  final bool inStock;
  final String unit;
  final String description;
  final String? imageUrl;
  final double cost; // Giá vốn

  MenuItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.image,
    this.inStock = true,
    this.unit = '',
    this.description = '',
    this.imageUrl,
    this.cost = 0.0,
  });

  factory MenuItemModel.fromRecord(RecordModel record, PocketBase pb) {
    String? imageUrl;
    final imageFilename = record.getStringValue('image');
    if (imageFilename.isNotEmpty) {
      imageUrl = pb
          .getFileUrl(record, imageFilename, thumb: '100x100')
          .toString();
    }

    return MenuItemModel(
      id: record.id,
      name: record.getStringValue('name'),
      price: record.getDoubleValue('price'),
      category: record.getStringValue('category') == 'food'
          ? MenuItemCategory.food
          : MenuItemCategory.drink,
      image: imageFilename,
      inStock: record.getBoolValue('in_stock'),
      unit: record.getStringValue('unit'),
      description: record.getStringValue('description'),
      imageUrl: imageUrl,
      cost: record.getDoubleValue('cost'),
    );
  }

  // --- SỬA LỖI: THÊM LẠI GETTER NÀY ---
  String get displayCategory {
    return category == MenuItemCategory.food ? 'Món ăn' : 'Thức uống';
  }
  // --- KẾT THÚC SỬA LỖI ---

  double get profit => price - cost;
}
