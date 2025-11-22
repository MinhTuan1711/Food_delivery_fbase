import 'dart:io';
import 'package:flutter/material.dart';
import 'package:food_delivery_fbase/components/my_button.dart';
import 'package:food_delivery_fbase/components/my_textfield.dart';
import 'package:food_delivery_fbase/models/food.dart';
import 'package:food_delivery_fbase/services/food_service.dart';
import 'package:food_delivery_fbase/services/image_service.dart';
import 'package:food_delivery_fbase/utils/currency_formatter.dart';

class AdminEditFoodPage extends StatefulWidget {
  final Food food;

  const AdminEditFoodPage({super.key, required this.food});

  @override
  State<AdminEditFoodPage> createState() => _AdminEditFoodPageState();
}

class _AdminEditFoodPageState extends State<AdminEditFoodPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _imagePathController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  
  late FoodCategory _selectedCategory;
  late List<Addon> _addons;
  
  final FoodService _foodService = FoodService();
  final ImageService _imageService = ImageService();
  bool _isLoading = false;
  File? _selectedImage;
  String? _newImageUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.food.name);
    _descriptionController = TextEditingController(text: widget.food.description);
    _imagePathController = TextEditingController(text: widget.food.imagePath);
    _priceController = TextEditingController(text: widget.food.price.toString());
    _quantityController = TextEditingController(text: widget.food.quantity.toString());
    _selectedCategory = widget.food.category;
    _addons = List.from(widget.food.availableAddons);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imagePathController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _updateFood() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String imagePath = _imagePathController.text.trim();
      
      // Nếu có ảnh mới được chọn, upload lên Firebase
      if (_selectedImage != null) {
        final fileName = _imageService.generateUniqueFileName(
          _selectedImage!.path.split('/').last,
        );
        _newImageUrl = await _imageService.uploadImageToFirebase(_selectedImage!, fileName);
        imagePath = _newImageUrl!;
        
        // Xóa ảnh cũ nếu có
        if (widget.food.imagePath.startsWith('https://')) {
          try {
            await _imageService.deleteImageFromFirebase(widget.food.imagePath);
          } catch (e) {
            // Bỏ qua lỗi xóa ảnh cũ
          }
        }
      }

      final updatedFood = widget.food.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        imagePath: imagePath,
        price: double.parse(_priceController.text.trim()),
        category: _selectedCategory,
        availableAddons: _addons,
        quantity: int.tryParse(_quantityController.text.trim()) ?? 0,
      );

      await _foodService.updateFood(updatedFood);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật sản phẩm thành công!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
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

  void _addAddon() {
    showDialog(
      context: context,
      builder: (context) => _AddonDialog(
        onAdd: (addon) {
          setState(() {
            _addons.add(addon);
          });
        },
      ),
    );
  }

  void _editAddon(int index) {
    showDialog(
      context: context,
      builder: (context) => _AddonDialog(
        addon: _addons[index],
        onAdd: (addon) {
          setState(() {
            _addons[index] = addon;
          });
        },
      ),
    );
  }

  void _removeAddon(int index) {
    setState(() {
      _addons.removeAt(index);
    });
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final image = await _imageService.pickImageFromGallery();
                  if (image != null) {
                    setState(() {
                      _selectedImage = image;
                    });
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: $e')),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final image = await _imageService.pickImageFromCamera();
                  if (image != null) {
                    setState(() {
                      _selectedImage = image;
                    });
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa sản phẩm'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hình ảnh sản phẩm (đưa lên đầu)
              const Text(
                'Hình ảnh sản phẩm',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 2),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : widget.food.imagePath.startsWith('https://')
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                widget.food.imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text(
                                        'Không thể tải ảnh',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image, size: 50, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  'Chạm để chọn ảnh mới',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 16),

              // Tên sản phẩm
              MyTextField(
                controller: _nameController,
                hintText: 'Tên sản phẩm',
                obscureText: false,
                icon: const Icon(Icons.restaurant),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên sản phẩm';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Mô tả
              MyTextField(
                controller: _descriptionController,
                hintText: 'Mô tả sản phẩm',
                obscureText: false,
                icon: const Icon(Icons.description),
                maxLines: 1,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập mô tả';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Giá
              MyTextField(
                controller: _priceController,
                hintText: 'Giá sản phẩm',
                obscureText: false,
                icon: const Icon(Icons.attach_money),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập giá sản phẩm';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'Vui lòng nhập giá hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Số lượng
              MyTextField(
                controller: _quantityController,
                hintText: 'Số lượng sản phẩm',
                obscureText: false,
                icon: const Icon(Icons.inventory_2),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập số lượng';
                  }
                  final quantity = int.tryParse(value.trim());
                  if (quantity == null || quantity < 0) {
                    return 'Vui lòng nhập số lượng hợp lệ (>= 0)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Danh mục
              DropdownButtonFormField<FoodCategory>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Danh mục',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: FoodCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(_getCategoryName(category)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Add-ons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add-ons',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addAddon,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      side: BorderSide(color: Theme.of(context).colorScheme.outline),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Danh sách add-ons
              if (_addons.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Chưa có add-on nào',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ...List.generate(_addons.length, (index) {
                  final addon = _addons[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(addon.name),
                      subtitle: Text(CurrencyFormatter.formatPrice(addon.price)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _editAddon(index),
                            icon: const Icon(Icons.edit),
                          ),
                          IconButton(
                            onPressed: () => _removeAddon(index),
                            icon: const Icon(Icons.delete, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 32),

              // Nút cập nhật sản phẩm
              MyButton(
                text: _isLoading ? 'Đang cập nhật...' : 'Cập nhật sản phẩm',
                onTap: _isLoading ? null : _updateFood,
                backgroundColor: Theme.of(context).colorScheme.primary,

              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryName(FoodCategory category) {
    switch (category) {
      case FoodCategory.bac:
        return 'Miền Bắc';
      case FoodCategory.trung:
        return 'Miền Trung';
      case FoodCategory.nam:
        return 'Miền Nam';
    }
  }
}

class _AddonDialog extends StatefulWidget {
  final Addon? addon;
  final Function(Addon) onAdd;

  const _AddonDialog({this.addon, required this.onAdd});

  @override
  State<_AddonDialog> createState() => _AddonDialogState();
}

class _AddonDialogState extends State<_AddonDialog> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.addon?.name ?? '');
    _priceController = TextEditingController(text: widget.addon?.price.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.addon == null ? 'Thêm Add-on' : 'Chỉnh sửa Add-on'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              enableIMEPersonalizedLearning: true,
              decoration: const InputDecoration(
                labelText: 'Tên add-on',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên add-on';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Giá add-on',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập giá add-on';
                }
                if (double.tryParse(value.trim()) == null) {
                  return 'Vui lòng nhập giá hợp lệ';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final addon = Addon(
                name: _nameController.text.trim(),
                price: double.parse(_priceController.text.trim()),
              );
              widget.onAdd(addon);
              Navigator.pop(context);
            }
          },
          child: Text(widget.addon == null ? 'Thêm' : 'Cập nhật'),
        ),
      ],
    );
  }
}


