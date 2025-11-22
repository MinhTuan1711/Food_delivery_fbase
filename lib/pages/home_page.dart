import 'package:flutter/material.dart';
import 'package:food_delivery_fbase/components/my_current_location.dart';
import 'package:food_delivery_fbase/components/my_description_box.dart';
import 'package:food_delivery_fbase/components/my_drawer.dart';
import 'package:food_delivery_fbase/components/my_food_tile.dart';
import 'package:food_delivery_fbase/components/my_sliver_app_bar.dart';
import 'package:food_delivery_fbase/components/my_tab_bar.dart';
import 'package:food_delivery_fbase/models/food.dart';
import 'package:food_delivery_fbase/models/restaurant.dart';
import 'package:food_delivery_fbase/pages/food_page.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin { 
  //tab controller
  late TabController _tabController;
  
  // Search and filter controllers
  late TextEditingController _searchController;
  String _searchQuery = '';
  FoodCategory? _selectedCategoryFilter;
  String? _sortBy; // 'price_asc', 'price_desc', 'name'
  
  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: FoodCategory.values.length, vsync: this);
    _searchController = TextEditingController();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Filter foods based on search query and selected category
  List<Food> _filterFoods(List<Food> allFoods) {
    List<Food> filtered = allFoods;
    
    // Filter by search query (name or description)
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((food) {
        final query = _searchQuery.toLowerCase();
        return food.name.toLowerCase().contains(query) ||
               food.description.toLowerCase().contains(query);
      }).toList();
    }
    
    // Filter by category
    if (_selectedCategoryFilter != null) {
      filtered = filtered.where((food) => food.category == _selectedCategoryFilter).toList();
    }
    
    // Sort
    if (_sortBy == 'price_asc') {
      filtered.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'price_desc') {
      filtered.sort((a, b) => b.price.compareTo(a.price));
    } else if (_sortBy == 'name') {
      filtered.sort((a, b) => a.name.compareTo(b.name));
    }
    
    return filtered;
  }

  // Handle filter button tap
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lọc món ăn'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Danh mục:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Tất cả'),
                    selected: _selectedCategoryFilter == null,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategoryFilter = null;
                      });
                      Navigator.pop(context);
                      _showFilterDialog();
                    },
                  ),
                  ...FoodCategory.values.map((category) => ChoiceChip(
                    label: Text(_getCategoryName(category)),
                    selected: _selectedCategoryFilter == category,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategoryFilter = selected ? category : null;
                      });
                      Navigator.pop(context);
                      _showFilterDialog();
                    },
                  )),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Sắp xếp:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Mặc định'),
                    selected: _sortBy == null,
                    onSelected: (selected) {
                      setState(() {
                        _sortBy = null;
                      });
                      Navigator.pop(context);
                      _showFilterDialog();
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Giá tăng dần'),
                    selected: _sortBy == 'price_asc',
                    onSelected: (selected) {
                      setState(() {
                        _sortBy = selected ? 'price_asc' : null;
                      });
                      Navigator.pop(context);
                      _showFilterDialog();
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Giá giảm dần'),
                    selected: _sortBy == 'price_desc',
                    onSelected: (selected) {
                      setState(() {
                        _sortBy = selected ? 'price_desc' : null;
                      });
                      Navigator.pop(context);
                      _showFilterDialog();
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Tên A-Z'),
                    selected: _sortBy == 'name',
                    onSelected: (selected) {
                      setState(() {
                        _sortBy = selected ? 'name' : null;
                      });
                      Navigator.pop(context);
                      _showFilterDialog();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedCategoryFilter = null;
                _sortBy = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Đặt lại'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
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

  // sort out and return a list of food items that belong to a specific category
  List<Food> _filterMenuByCategory(FoodCategory category, List<Food> fullMenu) {
    return fullMenu.where((food) => food.category == category).toList();
  }

  // return list of foods in given category
  List<Widget> getFoodInThisCategory(List<Food> fullMenu) {
    final filteredMenu = _filterFoods(fullMenu);
    
    return FoodCategory.values.map((category) {
      // get category menu
      List<Food> categoryMenu = _filterMenuByCategory(category, filteredMenu);

      return ListView.builder(
          itemCount: categoryMenu.length,
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemBuilder: (context, index) {
            // // get individual food
            final food = categoryMenu[index];
            return FoodTile(
              food: food,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FoodPage(food: food),
                ),
              ),
            );
          });
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MyDrawer(),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          MySliverAppBar(
            title: MyTabBar(tabController: _tabController),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Compact header section
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      // Current location - more compact
                      MyCurrentLocation(),
                      const SizedBox(height: 8),
                      // Search box
                      MyDescriptionBox(
                        searchController: _searchController,
                        onSearchChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        onFilterTap: _showFilterDialog,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
        body: Consumer<Restaurant>(
          builder: (context, restaurant, child) {
            // Use cached data immediately if available
            final cachedMenu = restaurant.menu;
            
            return StreamBuilder<List<Food>>(
              stream: restaurant.getFoodsStream(),
              initialData: cachedMenu.isNotEmpty ? cachedMenu : null,
              builder: (context, snapshot) {
                // Show loading only if we have no data at all (neither stream nor cached)
                if (snapshot.connectionState == ConnectionState.waiting && 
                    (snapshot.data == null || snapshot.data!.isEmpty) &&
                    cachedMenu.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                // If stream has error but we have cached data, use cached data
                if (snapshot.hasError && cachedMenu.isNotEmpty) {
                  print('Stream error but using cached data: ${snapshot.error}');
                }

                // Show error only if we have no cached data
                if (snapshot.hasError && cachedMenu.isEmpty) {
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

                // Use stream data if available, otherwise fallback to cached or hardcoded data
                final foods = snapshot.data ?? cachedMenu;
              
              return Stack(
                children: [
                  TabBarView(
                    controller: _tabController,
                    children: getFoodInThisCategory(foods)
                        .map((child) => Container(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondary, // set up background color for each tab
                              child: child,
                            ))
                        .toList(),
                  ),
                  // Show subtle loading indicator when data is being refreshed (only if we already have data)
                  if (snapshot.connectionState == ConnectionState.waiting && 
                      foods.isNotEmpty)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
          },
        ),
      ),
    );
  }
}
