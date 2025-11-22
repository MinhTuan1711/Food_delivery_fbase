import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:food_delivery_fbase/components/my_button.dart';
import 'package:food_delivery_fbase/components/my_cart_tile.dart';
import 'package:food_delivery_fbase/models/cart_item.dart';
import 'package:food_delivery_fbase/pages/payment_page.dart';
import 'package:food_delivery_fbase/services/cart_service.dart';
import 'package:food_delivery_fbase/utils/currency_formatter.dart';
import 'package:provider/provider.dart';
import 'package:food_delivery_fbase/models/restaurant.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartService _cartService = CartService();
  double _totalPrice = 0.0;
  double _selectedItemsTotal = 0.0;

  @override
  void initState() {
    super.initState();
    // Preload cart data when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final restaurant = Provider.of<Restaurant>(context, listen: false);
      restaurant.loadCartFromFirebase();
    });
  }

  Future<void> _clearCart() async {
    try {
      final restaurant = Provider.of<Restaurant>(context, listen: false);
      await restaurant.clearFirebaseCart();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa giỏ hàng thành công')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xóa giỏ hàng: $e')),
        );
      }
    }
  }

  Future<void> _removeItem(String cartItemId) async {
    try {
      final restaurant = Provider.of<Restaurant>(context, listen: false);
      await restaurant.removeFromFirebaseCart(cartItemId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xóa món: $e')),
        );
      }
    }
  }

  Future<void> _updateQuantity(String cartItemId, int quantity) async {
    try {
      final restaurant = Provider.of<Restaurant>(context, listen: false);
      await restaurant.updateFirebaseCartQuantity(cartItemId, quantity);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật số lượng: $e')),
        );
      }
    }
  }

  Future<void> _toggleItemSelection(String cartItemId) async {
    try {
      final restaurant = Provider.of<Restaurant>(context, listen: false);
      await restaurant.toggleFirebaseCartItemSelection(cartItemId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn món: $e')),
        );
      }
    }
  }

  Future<void> _selectAllItems() async {
    try {
      await _cartService.selectAllItems();
      final restaurant = Provider.of<Restaurant>(context, listen: false);
      await restaurant.loadCartFromFirebase();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn tất cả: $e')),
        );
      }
    }
  }

  Future<void> _deselectAllItems() async {
    try {
      await _cartService.deselectAllItems();
      final restaurant = Provider.of<Restaurant>(context, listen: false);
      await restaurant.loadCartFromFirebase();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi bỏ chọn tất cả: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          "Giỏ hàng",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Consumer<Restaurant>(
            builder: (context, restaurant, child) {
              return Row(
                children: [
                  //select all button
                  if (restaurant.firebaseCart.isNotEmpty)
                    IconButton(
                      onPressed: _selectAllItems,
                      icon: const Icon(Icons.checklist),
                      tooltip: "Chọn tất cả",
                    ),
                  //deselect all button
                  if (restaurant.firebaseCart.isNotEmpty)
                    IconButton(
                      onPressed: _deselectAllItems,
                      icon: const Icon(Icons.checklist_rtl),
                      tooltip: "Bỏ chọn tất cả",
                    ),
                  //clear all cart
                  if (restaurant.firebaseCart.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Bạn có chắc muốn xóa giỏ hàng?"),
                            content: const Text("Tất cả món ăn trong giỏ hàng sẽ bị xóa."),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            actions: [
                              //cancel button
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  "Hủy",
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              //yes button
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _clearCart();
                                },
                                child: Text(
                                  "Xóa",
                                  style: TextStyle(
                                    color: Colors.red[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete_outline),
                      tooltip: "Xóa giỏ hàng",
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<Restaurant>(
        builder: (context, restaurant, child) {
          return StreamBuilder<List<CartItem>>(
            stream: restaurant.getCartItemsStream(),
            initialData: restaurant.firebaseCart, // Use cached data immediately
            builder: (context, snapshot) {
              // Show loading only if we have no data at all
              if (snapshot.connectionState == ConnectionState.waiting && 
                  (snapshot.data == null || snapshot.data!.isEmpty)) {
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
                        onPressed: () => restaurant.loadCartFromFirebase(),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                );
              }

              final cartItems = snapshot.data ?? restaurant.firebaseCart;
              
              // Calculate totals
              double totalPrice = 0.0;
              double selectedItemsTotal = 0.0;
              
              for (final item in cartItems) {
                totalPrice += item.totalPrice;
                if (item.isSelected) {
                  selectedItemsTotal += item.totalPrice;
                }
              }

              return Column(
                children: [
                  //list of cart items
                  Expanded(
                    child: Column(
                      children: [
                        cartItems.isEmpty
                            ? Expanded(
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.shopping_cart_outlined,
                                        size: 80,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        "Giỏ hàng trống",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Hãy thêm món ăn vào giỏ hàng",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Expanded(
                                child: Stack(
                                  children: [
                                    ListView.builder(
                                      itemCount: cartItems.length,
                                      itemBuilder: (context, index) {
                                        //return individual cart item
                                        final cartItem = cartItems[index];

                                        //return cart tile UI
                                        return MyCartTile(
                                          cartItem: cartItem,
                                          onRemove: () => _removeItem(cartItem.id!),
                                          onUpdateQuantity: (quantity) => 
                                              _updateQuantity(cartItem.id!, quantity),
                                          onToggleSelection: () => _toggleItemSelection(cartItem.id!),
                                        );
                                      },
                                    ),
                                    // Show subtle loading indicator when data is being refreshed
                                    if (snapshot.connectionState == ConnectionState.waiting && 
                                        snapshot.data != null && snapshot.data!.isNotEmpty)
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
                                ),
                              ),
                      ],
                    ),
                  ),

                  // Total price display
                  if (cartItems.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        top: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Selected items total and cart total
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Món đã chọn:',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        CurrencyFormatter.formatTotal(selectedItemsTotal),
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Tổng giỏ hàng:',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        CurrencyFormatter.formatTotal(totalPrice),
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            //payment button
                            SizedBox(
                              width: double.infinity,
                              child: Material(
                                color: selectedItemsTotal > 0
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey[400],
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  onTap: selectedItemsTotal > 0 
                                      ? () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const PaymentPage(),
                                          ),
                                        )
                                      : null,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    child: Center(
                                      child: Text(
                                        selectedItemsTotal > 0 
                                            ? "Thanh toán (${CurrencyFormatter.formatTotal(selectedItemsTotal)})"
                                            : "Chọn món để thanh toán",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
