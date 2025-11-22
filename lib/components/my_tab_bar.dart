import 'package:flutter/material.dart';
import 'package:food_delivery_fbase/models/food.dart';

class MyTabBar extends StatelessWidget {
  final TabController tabController;

  const MyTabBar({
    super.key,
    required this.tabController,
  });

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

  List<Tab> _buildCategoryTabs() {
    return FoodCategory.values.map((category) {
      return Tab(
        text: _getCategoryName(category),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: TabBar(
        controller: tabController,
        tabs: _buildCategoryTabs(),
        labelColor: Theme.of(context).colorScheme.onSurface,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        indicatorColor: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
