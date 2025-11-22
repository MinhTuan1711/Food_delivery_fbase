import 'dart:async';
import 'package:flutter/material.dart';
import 'package:food_delivery_fbase/services/business/cart_service.dart';
import 'package:food_delivery_fbase/models/cart_item.dart';

class CartBadge extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Stream<int>? countStream;
  final Future<int> Function()? countFuture;
  final int? initialCount;
  final bool useCartService;

  const CartBadge({
    super.key,
    required this.child,
    this.onTap,
    this.countStream,
    this.countFuture,
    this.initialCount,
    this.useCartService = true,
  });

  @override
  State<CartBadge> createState() => _CartBadgeState();
}

class _CartBadgeState extends State<CartBadge> {
  final CartService _cartService = CartService();
  int _itemCount = 0;
  StreamSubscription<List<CartItem>>? _cartSubscription;
  StreamSubscription<int>? _countSubscription;

  @override
  void initState() {
    super.initState();
    _itemCount = widget.initialCount ?? 0;
    _setupCountListener();
  }

  @override
  void dispose() {
    _cartSubscription?.cancel();
    _countSubscription?.cancel();
    super.dispose();
  }

  void _setupCountListener() {
    if (widget.useCartService) {
      _listenToCartChanges();
    } else if (widget.countStream != null) {
      _listenToCustomStream();
    } else if (widget.countFuture != null) {
      _loadCustomCount();
    }
  }

  void _listenToCartChanges() {
    try {
      _cartSubscription = _cartService.getCartItemsStream().listen(
        (cartItems) {
          if (mounted) {
            setState(() {
              _itemCount = cartItems.fold(0, (sum, item) => sum + item.quantity);
            });
          }
        },
        onError: (error) {
          print('Error listening to cart changes: $error');
        },
      );
    } catch (e) {
      print('Error setting up cart listener: $e');
      // Fallback to one-time load
      _loadCartCount();
    }
  }

  void _listenToCustomStream() {
    _countSubscription = widget.countStream!.listen(
      (count) {
        if (mounted) {
          setState(() {
            _itemCount = count;
          });
        }
      },
      onError: (error) {
        print('Error listening to count changes: $error');
      },
    );
  }

  Future<void> _loadCartCount() async {
    try {
      final count = await _cartService.getCartItemsCount();
      if (mounted) {
        setState(() {
          _itemCount = count;
        });
      }
    } catch (e) {
      // Handle error silently or show a debug message
      print('Error loading cart count: $e');
    }
  }

  Future<void> _loadCustomCount() async {
    if (widget.countFuture != null) {
      try {
        final count = await widget.countFuture!();
        if (mounted) {
          setState(() {
            _itemCount = count;
          });
        }
      } catch (e) {
        print('Error loading count: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            widget.child,
            if (_itemCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    _itemCount > 99 ? '99+' : _itemCount.toString(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onError,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Method to refresh the count (can be called from parent)
  void refreshCount() {
    if (widget.useCartService) {
      _loadCartCount();
    } else {
      _loadCustomCount();
    }
  }
}
