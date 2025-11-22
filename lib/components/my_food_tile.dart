import 'package:flutter/material.dart';
import 'package:food_delivery_fbase/models/food.dart';
import 'package:food_delivery_fbase/utils/currency_formatter.dart';
import 'package:food_delivery_fbase/services/favorite_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FoodTile extends StatelessWidget {
  final Food food;
  final void Function()? onTap;
  const FoodTile({super.key, required this.food, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Food image with better styling
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).colorScheme.surfaceVariant,
                    ),
                    child: _buildFoodImage(context),
                  ),
                ),
                const SizedBox(width: 12),
                // Food details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Food name with favorite button
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              food.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Favorite button
                          if (FirebaseAuth.instance.currentUser != null)
                            _FavoriteButton(foodId: food.id ?? ''),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Food description
                      Text(
                        food.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Price and category
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Price
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              CurrencyFormatter.formatPrice(food.price),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          // Category badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _getCategoryName(food.category),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Stock quantity and status
                      Row(
                        children: [
                          // Stock quantity badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: food.isInStock
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  food.isInStock
                                      ? Icons.inventory_2
                                      : Icons.inventory_2_outlined,
                                  size: 14,
                                  color: food.isInStock
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  food.isInStock
                                      ? 'Còn ${food.quantity}'
                                      : 'Hết hàng',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: food.isInStock
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
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

  Widget _buildFoodImage(BuildContext context) {
    if (food.imagePath.isNotEmpty && food.imagePath.startsWith('https://')) {
      return Image.network(
        food.imagePath,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildPlaceholder(context),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingPlaceholder(context);
        },
      );
    }

    return _buildPlaceholder(context);
  }

  Widget _buildLoadingPlaceholder(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Icon(
        Icons.fastfood,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 30,
      ),
    );
  }
}

// Favorite button widget
class _FavoriteButton extends StatefulWidget {
  final String foodId;

  const _FavoriteButton({required this.foodId});

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton> {
  final FavoriteService _favoriteService = FavoriteService();
  bool _isToggling = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _favoriteService.isFavoriteStream(widget.foodId),
      builder: (context, snapshot) {
        final isFavorite = snapshot.data ?? false;

        return IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite
                ? Colors.red
                : Theme.of(context).colorScheme.onSurfaceVariant,
            size: 22,
          ),
          onPressed: _isToggling
              ? null
              : () async {
                  setState(() => _isToggling = true);
                  try {
                    await _favoriteService.toggleFavorite(widget.foodId);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isFavorite
                                ? 'Đã xóa khỏi món yêu thích'
                                : 'Đã thêm vào món yêu thích',
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: $e')),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isToggling = false);
                    }
                  }
                },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: isFavorite ? 'Xóa khỏi yêu thích' : 'Thêm vào yêu thích',
        );
      },
    );
  }
}
