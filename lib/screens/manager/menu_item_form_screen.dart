// [DÁN TOÀN BỘ CODE NÀY VÀO lib/screens/manager/menu_item_form_screen.dart]

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myshop/models/menu_item.dart';
import 'package:myshop/services/pocketbase_service.dart';

class MenuItemFormScreen extends StatefulWidget {
  final MenuItemModel? menuItem;

  const MenuItemFormScreen({super.key, this.menuItem});

  @override
  State<MenuItemFormScreen> createState() => _MenuItemFormScreenState();
}

class _MenuItemFormScreenState extends State<MenuItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final pbService = PocketBaseService.instance;
  bool _isLoading = false;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _unitController;
  late TextEditingController _descriptionController;
  late TextEditingController _costController; // <-- Controller cho Giá vốn

  // State
  MenuItemCategory _selectedCategory = MenuItemCategory.food;
  bool _inStock = true;
  XFile? _selectedImage;
  String? _existingImageUrl;

  bool get _isEditing => widget.menuItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.menuItem;
    _nameController = TextEditingController(text: item?.name);
    _priceController = TextEditingController(
      text: item?.price.toString() ?? '0',
    );
    _unitController = TextEditingController(text: item?.unit);
    _descriptionController = TextEditingController(text: item?.description);
    _costController = TextEditingController(
      text: item?.cost.toString() ?? '0',
    ); // <-- Khởi tạo
    _selectedCategory = item?.category ?? MenuItemCategory.food;
    _inStock = item?.inStock ?? true;
    _existingImageUrl = item?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    _descriptionController.dispose();
    _costController.dispose(); // <-- Dispose
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      final name = _nameController.text;
      final price = double.tryParse(_priceController.text) ?? 0.0;
      final unit = _unitController.text;
      final description = _descriptionController.text;
      final cost =
          double.tryParse(_costController.text) ?? 0.0; // <-- Lấy giá vốn
      final category = _selectedCategory == MenuItemCategory.food
          ? 'food'
          : 'drink';

      File? imageFile = _selectedImage != null
          ? File(_selectedImage!.path)
          : null;

      if (_isEditing) {
        // --- SỬA LỖI Ở ĐÂY ---
        await pbService.menu.updateMenuItem(
          id: widget.menuItem!.id,
          name: name,
          price: price,
          category: category,
          inStock: _inStock,
          unit: unit,
          description: description,
          image: imageFile,
          // Sửa tên tham số 'currentImageFilename'
          currentImageFilename: widget.menuItem!.image,
          cost: cost, // <-- Truyền giá vốn
        );
      } else {
        // --- SỬA LỖI Ở ĐÂY ---
        await pbService.menu.createMenuItem(
          name: name,
          price: price,
          category: category,
          inStock: _inStock,
          unit: unit,
          description: description,
          image: imageFile,
          cost: cost, // <-- Truyền giá vốn
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã lưu món "${name}" thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true); // Trả về true để refresh
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi lưu: $e'), backgroundColor: Colors.red),
      );
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa Món' : 'Thêm Món Mới'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildImagePicker(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên món',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tên món';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Giá bán (VND)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          double.tryParse(value) == null) {
                        return 'Vui lòng nhập giá hợp lệ';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _costController, // <-- THÊM TRƯỜNG GIÁ VỐN
                    decoration: const InputDecoration(
                      labelText: 'Giá vốn (VND)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          double.tryParse(value) == null) {
                        return 'Vui lòng nhập giá hợp lệ';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _unitController,
              decoration: const InputDecoration(
                labelText: 'Đơn vị (vd: ly, dĩa, phần)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<MenuItemCategory>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Phân loại',
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
                    _selectedCategory = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả (không bắt buộc)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Còn hàng'),
              value: _inStock,
              onChanged: (value) {
                setState(() {
                  _inStock = value;
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isLoading ? 'Đang lưu...' : 'Lưu'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: _isLoading ? null : _submitForm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildImage(),
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.image),
            label: Text(_selectedImage != null ? 'Đổi ảnh khác' : 'Chọn ảnh'),
            onPressed: _pickImage,
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (_selectedImage != null) {
      return Image.file(File(_selectedImage!.path), fit: BoxFit.cover);
    }
    if (_existingImageUrl != null) {
      return Image.network(
        _existingImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, size: 50, color: Colors.grey),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
      );
    }
    return const Icon(Icons.no_photography, size: 50, color: Colors.grey);
  }
}
