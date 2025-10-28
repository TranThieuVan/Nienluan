import 'package:pocketbase/pocketbase.dart';

// Enum để định nghĩa rõ ràng các loại món
enum MenuItemCategory {
  food,
  drink;

  static MenuItemCategory fromString(String? categoryString) {
    return (categoryString == 'drink')
        ? MenuItemCategory.drink
        : MenuItemCategory.food;
  }
}

class MenuItemModel {
  final String id;
  final String name;
  final MenuItemCategory category;
  final double price;
  final String description;
  final bool inStock;
  final String unit;

  // Xử lý hình ảnh
  final String? imageFilename; // Tên file gốc (ví dụ: 'image.png')
  final String? imageUrl; // URL đầy đủ để hiển thị (ví dụ: 'http://...')

  MenuItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.inStock,
    required this.unit,
    this.imageFilename,
    this.imageUrl,
  });

  /// Phương thức factory để chuyển đổi từ PocketBase RecordModel
  /// Nó cần instance `pb` để xây dựng URL hình ảnh
  factory MenuItemModel.fromRecord(RecordModel record, PocketBase pb) {
    // Lấy tên file từ trường 'image'
    final filename = record.getStringValue('image');
    String? fullUrl;

    // Nếu tên file tồn tại (người dùng đã upload ảnh)
    if (filename.isNotEmpty) {
      // Xây dựng URL đầy đủ
      fullUrl = pb.getFileUrl(record, filename).toString();
    }

    return MenuItemModel(
      id: record.id,
      name: record.getStringValue('name'),
      category: MenuItemCategory.fromString(record.getStringValue('category')),
      price: record.getDoubleValue('price'), // Lấy giá trị dạng double
      description: record.getStringValue('description'),
      inStock: record.getBoolValue('in_stock'),
      unit: record.getStringValue('unit'),

      imageFilename: filename.isNotEmpty ? filename : null,
      imageUrl: fullUrl,
    );
  }

  // Getter tiện lợi
  String get displayCategory =>
      (category == MenuItemCategory.drink) ? 'Nước uống' : 'Món ăn';
}
