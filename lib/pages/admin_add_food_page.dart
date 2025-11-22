import 'dart:io';
import 'package:flutter/material.dart';
import 'package:food_delivery_fbase/components/my_button.dart';
import 'package:food_delivery_fbase/components/my_textfield.dart';
import 'package:food_delivery_fbase/models/food.dart';
import 'package:food_delivery_fbase/services/food_service.dart';
import 'package:food_delivery_fbase/services/image_service.dart';
import 'package:food_delivery_fbase/utils/currency_formatter.dart';

class AdminAddFoodPage extends StatefulWidget {
  const AdminAddFoodPage({super.key});

  @override
  State<AdminAddFoodPage> createState() => _AdminAddFoodPageState();
}

class _AdminAddFoodPageState extends State<AdminAddFoodPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  //final _imagePathController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController(text: '0');
  
  FoodCategory _selectedCategory = FoodCategory.bac;
  final List<Addon> _addons = [];
  
  final FoodService _foodService = FoodService();
  final ImageService _imageService = ImageService();
  bool _isLoading = false;
  File? _selectedImage;
  String? _imageUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
   // _imagePathController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _addFood() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ảnh')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      //upload image to Firebase Storage
      final fileName = _imageService.generateUniqueFileName(
        _selectedImage!.path.split('/').last,
      );
      _imageUrl = await _imageService.uploadImageToFirebase(_selectedImage!, fileName);

      //add food to Firestore
      final food = Food(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        //imagePath: _imagePathController.text.trim(),
        imagePath: _imageUrl!,
        price: double.parse(_priceController.text.trim()),
        category: _selectedCategory,
        availableAddons: _addons,
        quantity: int.tryParse(_quantityController.text.trim()) ?? 0,
      );

      await _foodService.addFood(food);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thêm sản phẩm thành công!')),
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
        title: const Text('Thêm sản phẩm mới'),
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
              // Chọn hình ảnh (đưa lên đầu)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    if (_selectedImage != null)
                      Container(
                        height: 200,
                        width: double.infinity,
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ListTile(
                      leading: const Icon(Icons.image),
                      title: Text(_selectedImage != null ? 'Thay đổi hình ảnh' : 'Chọn hình ảnh'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: _pickImage,
                    ),
                  ],
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
                      trailing: IconButton(
                        onPressed: () => _removeAddon(index),
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 32),

              // Nút thêm sản phẩm
              MyButton(
                text: _isLoading ? 'Đang thêm...' : 'Thêm sản phẩm',
                onTap: _isLoading ? null : _addFood,
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
  final Function(Addon) onAdd;

  const _AddonDialog({required this.onAdd});

  @override
  State<_AddonDialog> createState() => _AddonDialogState();
}

class _AddonDialogState extends State<_AddonDialog> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm Add-on'),
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
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurface,
          ),
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
          style: ElevatedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            backgroundColor: Colors.transparent,
            elevation: 0,
            side: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
          child: const Text('Thêm'),
        ),
      ],
    );
  }
}


