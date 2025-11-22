import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_delivery_fbase/models/cart_item.dart';
import 'package:food_delivery_fbase/models/food.dart';
import 'package:food_delivery_fbase/services/business/food_service.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FoodService _foodService = FoodService();

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Get cart collection reference for current user
  CollectionReference get _cartCollection {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return _firestore.collection('user_carts').doc(userId).collection('items');
  }

  // Get cart collection reference for specific user (for admin)
  CollectionReference _getCartCollectionForUser(String userId) {
    return _firestore.collection('user_carts').doc(userId).collection('items');
  }

  // Add item to cart
  Future<void> addToCart({
    required String foodId,
    required List<Addon> selectedAddons,
    int quantity = 1,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get food details to check stock
      final food = await _foodService.getFoodById(foodId);
      if (food == null) {
        throw Exception('Food not found');
      }

      // Check if item already exists in cart
      final existingQuery = await _cartCollection
          .where('foodId', isEqualTo: foodId)
          .where('selectedAddons', isEqualTo: selectedAddons.map((a) => a.toMap()).toList())
          .get();

      int newQuantity = quantity;
      if (existingQuery.docs.isNotEmpty) {
        // Calculate total quantity if item exists
        final existingDoc = existingQuery.docs.first;
        final currentQuantity = (existingDoc.data() as Map<String, dynamic>?)?['quantity'] ?? 0;
        newQuantity = currentQuantity + quantity;
      }

      // Check if stock is sufficient
      if (!food.isInStock) {
        throw Exception('Sản phẩm đã hết hàng');
      }

      if (newQuantity > food.quantity) {
        throw Exception('Số lượng không đủ. Chỉ còn ${food.quantity} sản phẩm');
      }

      if (existingQuery.docs.isNotEmpty) {
        // Update quantity if item exists
        final existingDoc = existingQuery.docs.first;
        await existingDoc.reference.update({
          'quantity': newQuantity,
        });
      } else {
        // Add new item to cart
        final cartItem = CartItem(
          foodId: foodId,
          selectedAddons: selectedAddons,
          quantity: quantity,
        );
        await _cartCollection.add(cartItem.toMap());
      }
    } catch (e) {
      throw Exception('Failed to add item to cart: $e');
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(String cartItemId) async {
    try {
      await _cartCollection.doc(cartItemId).delete();
    } catch (e) {
      throw Exception('Failed to remove item from cart: $e');
    }
  }

  // Update item quantity in cart
  Future<void> updateQuantity(String cartItemId, int newQuantity) async {
    try {
      if (newQuantity <= 0) {
        await removeFromCart(cartItemId);
        return;
      }

      // Get cart item to check food stock
      final cartItemDoc = await _cartCollection.doc(cartItemId).get();
      if (!cartItemDoc.exists) {
        throw Exception('Cart item not found');
      }

      final cartItemData = cartItemDoc.data() as Map<String, dynamic>;
      final foodId = cartItemData['foodId'] as String;

      // Get food details to check stock
      final food = await _foodService.getFoodById(foodId);
      if (food == null) {
        throw Exception('Food not found');
      }

      // Check if stock is sufficient
      if (!food.isInStock) {
        throw Exception('Sản phẩm đã hết hàng');
      }

      if (newQuantity > food.quantity) {
        throw Exception('Số lượng không đủ. Chỉ còn ${food.quantity} sản phẩm');
      }

      await _cartCollection.doc(cartItemId).update({'quantity': newQuantity});
    } catch (e) {
      throw Exception('Failed to update quantity: $e');
    }
  }

  // Get cart items for current user
  Future<List<CartItem>> getCartItems() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _cartCollection.orderBy('addedAt', descending: false).get();
      final cartItems = <CartItem>[];

      for (final doc in querySnapshot.docs) {
        final cartItem = CartItem.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        
        // Load food details
        try {
          final food = await _foodService.getFoodById(cartItem.foodId);
          cartItem.food = food;
        } catch (e) {
          print('Failed to load food for cart item: $e');
          // Continue without food details
        }
        
        cartItems.add(cartItem);
      }

      return cartItems;
    } catch (e) {
      throw Exception('Failed to get cart items: $e');
    }
  }

  // Get cart items stream for real-time updates
  Stream<List<CartItem>> getCartItemsStream() {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      return _cartCollection
          .orderBy('addedAt', descending: false)
          .snapshots()
          .asyncMap((snapshot) async {
        final cartItems = <CartItem>[];

        for (final doc in snapshot.docs) {
          final cartItem = CartItem.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          
          // Load food details
          try {
            final food = await _foodService.getFoodById(cartItem.foodId);
            cartItem.food = food;
          } catch (e) {
            print('Failed to load food for cart item: $e');
            // Continue without food details
          }
          
          cartItems.add(cartItem);
        }

        return cartItems;
      });
    } catch (e) {
      throw Exception('Failed to get cart items stream: $e');
    }
  }

  // Clear entire cart
  Future<void> clearCart() async {
    try {
      final batch = _firestore.batch();
      final querySnapshot = await _cartCollection.get();
      
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to clear cart: $e');
    }
  }

  // Get total cart value
  Future<double> getCartTotal() async {
    try {
      final cartItems = await getCartItems();
      double total = 0.0;
      for (final item in cartItems) {
        total += item.totalPrice;
      }
      return total;
    } catch (e) {
      throw Exception('Failed to get cart total: $e');
    }
  }

  // Get total value of selected items only
  Future<double> getSelectedItemsTotal() async {
    try {
      final cartItems = await getCartItems();
      double total = 0.0;
      for (final item in cartItems) {
        if (item.isSelected) {
          total += item.totalPrice;
        }
      }
      return total;
    } catch (e) {
      throw Exception('Failed to get selected items total: $e');
    }
  }

  // Toggle item selection
  Future<void> toggleItemSelection(String cartItemId) async {
    try {
      final doc = await _cartCollection.doc(cartItemId).get();
      if (doc.exists) {
        final currentSelection = (doc.data() as Map<String, dynamic>?)?['isSelected'] ?? true;
        await _cartCollection.doc(cartItemId).update({'isSelected': !currentSelection});
      }
    } catch (e) {
      throw Exception('Failed to toggle item selection: $e');
    }
  }

  // Select all items
  Future<void> selectAllItems() async {
    try {
      final querySnapshot = await _cartCollection.get();
      final batch = _firestore.batch();
      
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isSelected': true});
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to select all items: $e');
    }
  }

  // Deselect all items
  Future<void> deselectAllItems() async {
    try {
      final querySnapshot = await _cartCollection.get();
      final batch = _firestore.batch();
      
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isSelected': false});
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to deselect all items: $e');
    }
  }

  // Get selected items only
  Future<List<CartItem>> getSelectedItems() async {
    try {
      final cartItems = await getCartItems();
      return cartItems.where((item) => item.isSelected).toList();
    } catch (e) {
      throw Exception('Failed to get selected items: $e');
    }
  }

  // Get cart items count
  Future<int> getCartItemsCount() async {
    try {
      final cartItems = await getCartItems();
      int total = 0;
      for (final item in cartItems) {
        total += item.quantity;
      }
      return total;
    } catch (e) {
      throw Exception('Failed to get cart items count: $e');
    }
  }

}
