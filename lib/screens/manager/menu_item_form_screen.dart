// lib/screens/manager/menu_item_form_screen.dart (ĐÃ SỬA LỖI dart:io)

// --- KHÔNG CÒN import 'dart:io'; ---
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myshop/models/menu_item.dart';
import 'package:myshop/services/pocketbase_service.dart';
import 'package:myshop/utils/constants.dart';
// --- THÊM IMPORT NÀY ĐỂ DÙNG Uint8List ---
import 'dart:typed_data';

class MenuItemFormScreen extends StatefulWidget {
  final MenuItemModel? menuItem;
  const MenuItemFormScreen({super.key, this.menuItem});

  @override
  State<MenuItemFormScreen> createState() => _MenuItemFormScreenState();
}

class _MenuItemFormScreenState extends State<MenuItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final pbService = PocketBaseService.instance;
  final ImagePicker _picker = ImagePicker();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  String _unit = MENU_ITEM_UNITS.first;

  // Form values
  MenuItemCategory _category = MenuItemCategory.food;
  bool _inStock = true;
  String? _existingImageUrl; // Hình ảnh cũ (nếu có)
  bool _deleteExistingImage = false; // Cờ để xóa ảnh
  bool _isLoading = false;

  // --- THAY ĐỔI ĐỂ SỬA LỖI ---
  XFile? _newImageFile; // Giữ XFile để upload
  Uint8List? _newImagePreviewBytes; // Dùng Uint8List để PREVIEW ảnh

  bool get _isEditMode => widget.menuItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.menuItem;
    _nameController = TextEditingController(text: item?.name ?? '');
    _priceController = TextEditingController(
      text: item?.price.toStringAsFixed(0) ?? '',
    );
    _descController = TextEditingController(text: item?.description ?? '');
    _category = item?.category ?? MenuItemCategory.food;
    _inStock = item?.inStock ?? true;
    _existingImageUrl = item?.imageUrl;

    _unit = item?.unit ?? MENU_ITEM_UNITS.first;
    if (!MENU_ITEM_UNITS.contains(_unit)) {
      _unit = MENU_ITEM_UNITS.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // Xử lý chọn ảnh
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      // Đọc dữ liệu ảnh vào bộ nhớ
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _newImageFile = pickedFile; // Lưu file để upload
        _newImagePreviewBytes = bytes; // Lưu bytes để preview
        _deleteExistingImage = false;
        _existingImageUrl = null; // Xóa ảnh cũ (nếu có)
      });
    }
  }

  // Xử lý Lưu form (Không cần thay đổi logic, vì service đã nhận XFile)
  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_isLoading) return;
      setState(() {
        _isLoading = true;
      });

      try {
        final data = {
          'name': _nameController.text,
          'price': double.tryParse(_priceController.text) ?? 0.0,
          'category': _category.name,
          'unit': _unit,
          'inStock': _inStock,
          'description': _descController.text,
        };

        if (_isEditMode) {
          await pbService.menuItems.updateMenuItem(
            id: widget.menuItem!.id,
            name: data['name'] as String,
            price: data['price'] as double,
            category: data['category'] as String,
            unit: data['unit'] as String,
            inStock: data['inStock'] as bool,
            description: data['description'] as String,
            newImageFile: _newImageFile, // Gửi XFile
            deleteExistingImage: _deleteExistingImage,
          );
        } else {
          await pbService.menuItems.addMenuItem(
            name: data['name'] as String,
            price: data['price'] as double,
            category: data['category'] as String,
            unit: data['unit'] as String,
            inStock: data['inStock'] as bool,
            description: data['description'] as String,
            imageFile: _newImageFile, // Gửi XFile
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditMode ? 'Cập nhật thành công!' : 'Thêm món thành công!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Trả về true để báo reload
        }
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Sửa Món Ăn' : 'Thêm Món Ăn Mới'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _submitForm,
            tooltip: 'Lưu',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(/* ... */)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // (TextFormField Tên Món - giữ nguyên)
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên món ăn*',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => (value?.isEmpty ?? true)
                          ? 'Tên không được để trống'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // (Phần Hình ảnh - giữ nguyên)
                    Text(
                      'Hình ảnh',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    _buildImagePreview(), // DÙNG HÀM MỚI
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Chọn ảnh mới'),
                          onPressed: _pickImage,
                        ),
                        if (_isEditMode &&
                            (_existingImageUrl != null ||
                                _newImagePreviewBytes !=
                                    null)) // SỬA BIẾN CHECK
                          TextButton.icon(
                            icon: Icon(
                              Icons.delete_forever,
                              color: Colors.red.shade700,
                            ),
                            label: Text(
                              'Xóa ảnh',
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                            onPressed: () {
                              setState(() {
                                _newImageFile = null;
                                _newImagePreviewBytes = null; // SỬA BIẾN NÀY
                                _existingImageUrl = null;
                                _deleteExistingImage = true;
                              });
                            },
                          ),
                      ],
                    ),
                    const Divider(height: 24),

                    // (Phần Giá và Đơn vị - đã sửa)
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(
                              labelText: 'Giá (VND)*',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value?.isEmpty ?? true)
                                return 'Giá không được trống';
                              if (double.tryParse(value!) == null)
                                return 'Giá không hợp lệ';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            value: _unit,
                            decoration: const InputDecoration(
                              labelText: 'Đơn vị*',
                              border: OutlineInputBorder(),
                            ),
                            items: MENU_ITEM_UNITS.map((String unitValue) {
                              return DropdownMenuItem<String>(
                                value: unitValue,
                                child: Text(unitValue),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _unit = value;
                                });
                              }
                            },
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                ? 'Chưa chọn'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // (Phần Phân loại - giữ nguyên)
                    DropdownButtonFormField<MenuItemCategory>(
                      value: _category,
                      decoration: const InputDecoration(
                        labelText: 'Phân loại*',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: MenuItemCategory.food,
                          child: Text('Món ăn'),
                        ),
                        DropdownMenuItem(
                          value: MenuItemCategory.drink,
                          child: Text('Thức uống'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _category = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // (Phần Mô tả - giữ nguyên)
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả (không bắt buộc)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // (Switch Tình trạng - giữ nguyên)
                    SwitchListTile(
                      title: Text(_inStock ? 'Đang còn hàng' : 'Đã hết hàng'),
                      value: _inStock,
                      onChanged: (value) {
                        setState(() {
                          _inStock = value;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // --- SỬA LẠI HÀM NÀY ĐỂ DÙNG Image.memory ---
  Widget _buildImagePreview() {
    return Center(
      child: Container(
        width: double.infinity,
        height: 250,
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade100,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _newImagePreviewBytes != null
              // 1. Hiển thị ảnh mới (từ bộ nhớ)
              ? Image.memory(_newImagePreviewBytes!, fit: BoxFit.contain)
              // 2. Hiển thị ảnh cũ (từ URL)
              : _existingImageUrl != null
              ? Image.network(
                  _existingImageUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image,
                    size: 50,
                    color: Colors.red,
                  ),
                )
              // 3. Hiển thị placeholder
              : const Center(
                  child: Icon(Icons.image_search, size: 60, color: Colors.grey),
                ),
        ),
      ),
    );
  }
}
