import 'package:flutter/material.dart';
import 'package:food_delivery_fbase/components/my_button.dart';
import 'package:food_delivery_fbase/models/food.dart';
import 'package:food_delivery_fbase/pages/admin_add_food_page.dart';
import 'package:food_delivery_fbase/pages/admin_edit_food_page.dart';
import 'package:food_delivery_fbase/services/food_service.dart';
import 'package:food_delivery_fbase/utils/currency_formatter.dart';

class AdminProductManagementPage extends StatefulWidget {
  const AdminProductManagementPage({super.key});

  @override
  State<AdminProductManagementPage> createState() =>
      _AdminProductManagementPageState();
}

class _AdminProductManagementPageState
    extends State<AdminProductManagementPage> {
  final FoodService _foodService = FoodService();
  String _searchQuery = '';
  FoodCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý sản phẩm'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminAddFoodPage(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            tooltip: 'Thêm sản phẩm',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  enableIMEPersonalizedLearning: true,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm sản phẩm...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Tất cả'),
                        selected: _selectedCategory == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ...FoodCategory.values.map((category) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(_getCategoryName(category)),
                            selected: _selectedCategory == category,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = selected ? category : null;
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Products list
          Expanded(
            child: StreamBuilder<List<Food>>(
              stream: _foodService.getFoods(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Lỗi: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                final foods = snapshot.data ?? [];
                final filteredFoods = foods.where((food) {
                  final matchesSearch = _searchQuery.isEmpty ||
                      food.name
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()) ||
                      food.description
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase());

                  final matchesCategory = _selectedCategory == null ||
                      food.category == _selectedCategory;

                  return matchesSearch && matchesCategory;
                }).toList();

                if (filteredFoods.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.restaurant_menu, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty || _selectedCategory != null
                              ? 'Không tìm thấy sản phẩm nào'
                              : 'Chưa có sản phẩm nào',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty || _selectedCategory != null
                              ? 'Thử thay đổi bộ lọc tìm kiếm'
                              : 'Hãy thêm sản phẩm đầu tiên',
                        ),
                        if (_searchQuery.isEmpty &&
                            _selectedCategory == null) ...[
                          const SizedBox(height: 24),
                          MyButton(
                            text: 'Thêm sản phẩm',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AdminAddFoodPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredFoods.length,
                  itemBuilder: (context, index) {
                    final food = filteredFoods[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildFoodImage(food.imagePath),
                        ),
                        title: Text(
                          food.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  CurrencyFormatter.formatPrice(food.price),
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: food.isInStock
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        food.isInStock
                                            ? Icons.inventory_2
                                            : Icons.inventory_2_outlined,
                                        size: 12,
                                        color: food.isInStock
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        food.isInStock
                                            ? 'Còn ${food.quantity}'
                                            : 'Hết hàng',
                                        style: TextStyle(
                                          color: food.isInStock
                                              ? Colors.green
                                              : Colors.red,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              _getCategoryName(food.category),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            if (food.description.isNotEmpty)
                              Text(
                                food.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _navigateToEditFood(food);
                                break;
                              case 'delete':
                                _deleteFood(food.id!, food.name);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 8),
                                  Text('Sửa'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Xóa',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(
      //         builder: (context) => const AdminAddFoodPage(),
      //       ),
      //     );
      //   },
      //   child: const Icon(Icons.add),
      //   tooltip: 'Thêm sản phẩm mới',
      // ),
    );
  }

  Widget _buildFoodImage(String imagePath) {
    if (imagePath.isNotEmpty && imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _foodPlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 60,
            height: 60,
            color: Colors.grey[300],
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      );
    }

    return _foodPlaceholder();
  }

  Widget _foodPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey[300],
      child: const Icon(Icons.fastfood, size: 30, color: Colors.grey),
    );
  }

  void _navigateToEditFood(Food food) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminEditFoodPage(food: food),
      ),
    );
  }

  Future<void> _deleteFood(String foodId, String foodName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa "$foodName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
    foregroundColor: Theme.of(context).colorScheme.inversePrimary,
  ),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _foodService.deleteFood(foodId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa sản phẩm thành công')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi xóa: $e')),
          );
        }
      }
    }
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
