import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_delivery_fbase/components/my_button.dart';
import 'package:food_delivery_fbase/models/food.dart';
import 'package:food_delivery_fbase/services/cart_service.dart';
import 'package:food_delivery_fbase/services/favorite_service.dart';
import 'package:food_delivery_fbase/utils/currency_formatter.dart';
import 'package:provider/provider.dart';
import 'package:food_delivery_fbase/models/restaurant.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FoodPage extends StatefulWidget {
  final Food food;
  final Map<Addon, bool> selectedAddons = {};

  FoodPage({
    super.key,
    required this.food,
  }) {
    // initialize all addons as unselected
    for (Addon addon in food.availableAddons) {
      selectedAddons[addon] = false;
    }
  }

  @override
  State<FoodPage> createState() => _FoodPageState();
}

class _FoodPageState extends State<FoodPage> {
  final CartService _cartService = CartService();
  final FavoriteService _favoriteService = FavoriteService();
  bool _isAddingToCart = false;
  bool _isTogglingFavorite = false;

  //method to add food to cart
  Future<void> addToCart(Food food, Map<Addon, bool> selectedAddons) async {
    if (_isAddingToCart) return;

    // Kiểm tra số lượng còn lại
    if (!food.isInStock) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sản phẩm đã hết hàng!'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isAddingToCart = true;
    });

    try {
      //format the selected addons
      List<Addon> currentSelectedAddons = [];
      for (Addon addon in widget.food.availableAddons) {
        if (widget.selectedAddons[addon] == true) {
          currentSelectedAddons.add(addon);
        }
      }

      // Add to cart using Restaurant model
      final restaurant = Provider.of<Restaurant>(context, listen: false);
      await restaurant.addToFirebaseCart(
        foodId: food.id!,
        selectedAddons: currentSelectedAddons,
        quantity: 1,
      );

      //close the current page
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm vào giỏ hàng thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi thêm vào giỏ hàng: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        actions: [
          // Favorite button
          if (FirebaseAuth.instance.currentUser != null)
            StreamBuilder<bool>(
              stream: _favoriteService.isFavoriteStream(widget.food.id ?? ''),
              builder: (context, snapshot) {
                final isFavorite = snapshot.data ?? false;
                return IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite
                        ? Colors.red
                        : Theme.of(context).colorScheme.inversePrimary,
                  ),
                  onPressed: _isTogglingFavorite
                      ? null
                      : () async {
                          setState(() => _isTogglingFavorite = true);
                          try {
                            await _favoriteService
                                .toggleFavorite(widget.food.id ?? '');
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
                              setState(() => _isTogglingFavorite = false);
                            }
                          }
                        },
                  tooltip:
                      isFavorite ? 'Xóa khỏi yêu thích' : 'Thêm vào yêu thích',
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            //food image
            Container(
              width: double.infinity,
              height: 350,
              child: ClipRect(
                child: _buildFoodImage(),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //food name
                  Text(
                    widget.food.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  //food price
                  Text(
                    CurrencyFormatter.formatPrice(widget.food.price),
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),

                  SizedBox(height: 10),

                  // Stock quantity and status
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: widget.food.isInStock
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            widget.food.isInStock ? Colors.green : Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.food.isInStock
                              ? Icons.inventory_2
                              : Icons.inventory_2_outlined,
                          color:
                              widget.food.isInStock ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.food.isInStock
                              ? 'Còn ${widget.food.quantity} sản phẩm'
                              : 'Hết hàng',
                          style: TextStyle(
                            color: widget.food.isInStock
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 10),

                  //food description
                  Text(
                    widget.food.description,
                  ),

                  SizedBox(height: 10),

                  Divider(
                    color: Theme.of(context).colorScheme.secondary,
                  ),

                  Text(
                    "Tùy chọn thêm",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),

                  //addon
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: widget.food.availableAddons.length,
                      itemBuilder: ((context, index) {
                        // get individual addon
                        Addon addon = widget.food.availableAddons[index];

                        //return addon checkbox
                        return CheckboxListTile(
                          title: Text(addon.name),
                          subtitle: Text(
                            CurrencyFormatter.formatPrice(addon.price),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          value: widget.selectedAddons[addon],
                          onChanged: (bool? value) {
                            setState(() {
                              widget.selectedAddons[addon] = value ?? false;
                            });
                          },
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),

            //button -> add to cart
            MyButton(
              onTap: (_isAddingToCart || !widget.food.isInStock)
                  ? null
                  : () => addToCart(widget.food, widget.selectedAddons),
              text: !widget.food.isInStock
                  ? "Hết hàng"
                  : _isAddingToCart
                      ? "Đang thêm..."
                      : "Thêm vào giỏ hàng",
              backgroundColor: !widget.food.isInStock
                  ? Colors.grey
                  : Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodImage() {
    if (widget.food.imagePath.isNotEmpty &&
        widget.food.imagePath.startsWith('https://')) {
      return Image.network(
        widget.food.imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      );
    }

    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fastfood,
              color: Colors.grey,
              size: 80,
            ),
            SizedBox(height: 16),
            Text(
              'Không có hình ảnh',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
