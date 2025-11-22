import 'package:flutter/material.dart';
import 'package:food_delivery_fbase/components/my_quantity_selector.dart';
import 'package:food_delivery_fbase/models/cart_item.dart';
import 'package:food_delivery_fbase/utils/currency_formatter.dart';

class MyCartTile extends StatelessWidget {
  final CartItem cartItem;
  final VoidCallback? onRemove;
  final Function(int)? onUpdateQuantity;
  final VoidCallback? onToggleSelection;

  const MyCartTile({
    super.key,
    required this.cartItem,
    this.onRemove,
    this.onUpdateQuantity,
    this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = cartItem.isSelected;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.secondary
            : theme.colorScheme.secondary.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selection checkbox
                if (onToggleSelection != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0, top: 4.0),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (value) => onToggleSelection!(),
                      activeColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                //food image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildFoodImage(context),
                ),
                const SizedBox(width: 12),
                //name and price
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //food name
                      Text(
                        cartItem.food?.name ?? 'Đang tải...',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      //food base price
                      Text(
                        cartItem.food != null
                            ? CurrencyFormatter.formatPrice(
                                cartItem.food!.price)
                            : 'Đang tải...',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Total price for this item
                      Text(
                        'Tổng: ${CurrencyFormatter.formatTotal(cartItem.totalPrice)}',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Quantity selector and Remove button row
                      Row(
                        children: [
                          // increment and decrement buttons
                          if (cartItem.food != null)
                            Expanded(
                              flex: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.background,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: theme.colorScheme.outline
                                        .withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Decrement button
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          if (onUpdateQuantity != null &&
                                              cartItem.quantity > 1) {
                                            onUpdateQuantity!(
                                                cartItem.quantity - 1);
                                          }
                                        },
                                        borderRadius:
                                            const BorderRadius.horizontal(
                                          left: Radius.circular(20),
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 6,
                                          ),
                                          child: Icon(
                                            Icons.remove,
                                            size: 16,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Quantity display
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      child: Text(
                                        cartItem.quantity.toString(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    // Increment button
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          if (onUpdateQuantity != null) {
                                            onUpdateQuantity!(
                                                cartItem.quantity + 1);
                                          }
                                        },
                                        borderRadius:
                                            const BorderRadius.horizontal(
                                          right: Radius.circular(20),
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 6,
                                          ),
                                          child: Icon(
                                            Icons.add,
                                            size: 16,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (cartItem.food != null && onRemove != null)
                            const SizedBox(width: 6),
                          // Remove button
                          if (onRemove != null)
                            Expanded(
                              flex: 1,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: onRemove,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.delete_outline,
                                          size: 16,
                                          color: Colors.red[600],
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          'Xóa',
                                          style: TextStyle(
                                            color: Colors.red[600],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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
          //addons
          if (cartItem.selectedAddons.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: cartItem.selectedAddons
                    .map(
                      (addon) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.background.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.colorScheme.outline.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${addon.name} (${CurrencyFormatter.formatPrice(addon.price)})',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFoodImage(BuildContext context) {
    final imagePath = cartItem.food?.imagePath ?? '';
    if (imagePath.isNotEmpty && imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        height: 100,
        width: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 100,
      width: 100,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.fastfood,
        color: Colors.grey,
        size: 40,
      ),
    );
  }
}
