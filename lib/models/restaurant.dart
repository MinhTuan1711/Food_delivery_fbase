import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:food_delivery_fbase/models/cart_item.dart';
import 'package:food_delivery_fbase/models/food.dart';
import 'package:food_delivery_fbase/services/food_service.dart';
import 'package:food_delivery_fbase/services/cart_service.dart';
import 'package:food_delivery_fbase/services/order_service.dart';
import 'package:food_delivery_fbase/models/order.dart' as order_model;
import 'package:food_delivery_fbase/utils/image_placeholders.dart';

class Restaurant extends ChangeNotifier {
  final FoodService _foodService = FoodService();
  final CartService _cartService = CartService();
  final OrderService _orderService = OrderService();
  List<Food> _menu = [
    // burgers
    Food(
      name: "Classic Cheeseburger",
      description:
          "a juicy beef patty with melted cheddar, lettuce, tomato, and a hint of onion and pickle.",
      imagePath: generatePlaceholderImage("classic-cheeseburger"),
      price: 25000,
      availableAddons: [
        Addon(name: "Extra Cheese", price: 25000),
        Addon(name: "Bacon", price: 50000),
        Addon(name: "Avocado", price: 75000)
      ],
      category: FoodCategory.bac,
      quantity: 10,
    ),
    Food(
      name: "aboutcom__coeus__resourceburger",
      description: "lettuce, tomato, and a hint of onion and pickle...",
      imagePath: generatePlaceholderImage("aboutcom-coeus-resourceburger"),
      price: 75000,
      availableAddons: [
        Addon(name: "Extra Cheese", price: 75000),
        Addon(name: "Bacon", price: 87000),
        Addon(name: "Avocado", price: 132000)
      ],
      category: FoodCategory.bac,
      quantity: 10,
    ),
    Food(
      name: "comte-cheesburgers",
      description:
          "A no frills burger joint in the heart of the city of Phnom Penh. We provide you with full bellies, board games for days and banter you will enjoy. Meat, vegetarian and vegan options - something for everyone!",
      imagePath: generatePlaceholderImage("crispy-comte-cheeseburgers"),
      price: 48000,
      availableAddons: [
        Addon(name: "Extra Cheese", price: 48000),
        Addon(name: "Bacon", price: 61000),
        Addon(name: "Avocado", price: 147000)
      ],
      category: FoodCategory.bac,
      quantity: 10,
    ),
    Food(
      name: "Beef-Salmon-and-Kebab",
      description:
          "Eleven One Kitchen is an environmentally responsible restaurant committed to serving delicious, high quality, healthy food. The Khmer and western-inspired menu is a combination of much-loved favourites and regularly changing specials that make use of the produce in season. There is plenty of choice for",
      imagePath: generatePlaceholderImage("homemade-beef-salmon-kebab"),
      price: 37500,
      availableAddons: [
        Addon(name: "Extra Cheese", price: 37500),
        Addon(name: "Bacon", price: 58250),
        Addon(name: "Avocado", price: 83250)
      ],
      category: FoodCategory.bac,
      quantity: 10,
    ),
    Food(
      name: "mushroom-black-beanburger",
      description: "Vegetarian Friendly, Vegan Options",
      imagePath: generatePlaceholderImage("mushroom-black-beanburger"),
      price: 124750,
      availableAddons: [
        Addon(name: "Extra Cheese", price: 124750),
        Addon(name: "Bacon", price: 163750),
        Addon(name: "Avocado", price: 221250)
      ],
      category: FoodCategory.bac,
      quantity: 10,
    ),
    // salads
    Food(
      name: "superfoodssalad",
      description:
          "Gerbies Salad and Sandwich is Phnom Penh's first quality salad and sandwich shop which aims to provide speedy eat-in and self-takeaway service to those that are on the move or they have limited lunch time at down to earth prices . Our cold salads are carefully prepared by ourselves and are packed in our unique designed boxes. These cold salads boxes can be taken away or eaten in our shop. These boxed salads are 'made today and gone today', so nothing will be kept for the next day. In addition, we also have varieties of warm salads including beef, crispy squid & chorizo, brouillee and Lardon & Mushroom. We also sell deliciously ranges of cold and hot baguette sandwiches and paninis as well as varieties of fresh fruits, juices, smoothies, coffee, etc... We are located in the most popular tourist area of Boeng Keng Kong 1 at No 78, Street 51 ( Pasteur) , Phnom Penh (Opposite Wat Lanka's book stalls). Our boutique shop has 45 seats capacity and is well air-conditioned. Our first floor has a terrace over looking the bustling street of 51 and Sihanouk Boulevard ,next door to Independence Monument. Our staff are well trained and speak good level of English. We hope to serving you soon.",
      imagePath: generatePlaceholderImage("superfoodssalad"),
      price: 139750,
      availableAddons: [
        Addon(name: "Extra Cheese", price: 139750),
        Addon(name: "Bacon", price: 163750),
        Addon(name: "Avocado", price: 221250)
      ],
      category: FoodCategory.trung,
      quantity: 10,
    ),
    Food(
      name: "chopped-power-salad-with-chicken",
      description:
          "Salad K is a restaurant sells specifically for Salad and fresh juice only with very low price compare to all restaurants where salad and juice are served in Cambodia. Most customers especially foreign customers are satisfied with our restaurant and always asking whether we have tripadviser to rate best grade for us and recommend to other travelers who would like to have salad and fresh juice.",
      imagePath: generatePlaceholderImage("chopped-power-salad-with-chicken"),
      price: 49750,
      availableAddons: [
        Addon(name: "Extra Cheese", price: 49750),
        Addon(name: "Bacon", price: 163750),
        Addon(name: "Avocado", price: 213750)
      ],
      category: FoodCategory.trung,
      quantity: 10,
    ),
    Food(
      name: "Italian Chopped Salad",
      description:
          "This chopped salad is so flavorful that even salad skeptics will pile their plates with seconds! The key ingredients? A punchy dressing, pepperoncini, and TWO types of cheese.",
      imagePath: generatePlaceholderImage("italian-chopped-salad"),
      price: 99750,
      availableAddons: [
        Addon(name: "Extra Cheese", price: 99750),
        Addon(name: "Bacon", price: 163750),
        Addon(name: "Avocado", price: 213750)
      ],
      category: FoodCategory.trung,
      quantity: 10,
    ),
    Food(
      name: "Beet Salad",
      description:
          "This beet, apple, and goat cheese salad would be at home on any holiday table. To get ahead, roast the beets and make the balsamic vinaigrette a day or two in advance.",
      imagePath: generatePlaceholderImage("beet-salad"),
      price: 199750,
      availableAddons: [
        Addon(name: "Extra Cheese", price: 199750),
        Addon(name: "Bacon", price: 263750),
        Addon(name: "Avocado", price: 288750)
      ],
      category: FoodCategory.trung,
      quantity: 10,
    ),
    Food(
      name: "Mediterranean-Chopped-Salad",
      description:
          "It’s complete with crispy tortilla strips, savory plant-based taco “meat,” and a zesty cilantro lime dressing. Healthy lunches don’t get tastier than this.",
      imagePath: generatePlaceholderImage("mediterranean-chopped-salad"),
      price: 174750,
      availableAddons: [
        Addon(name: "Extra Cheese", price: 174750),
        Addon(name: "Bacon", price: 214500),
        Addon(name: "Avocado", price: 288750)
      ],
      category: FoodCategory.trung,
      quantity: 10,
    ),

    // desserts
    Food(
      name: "Cherry-Delight-Dessert",
      description:
          "We believe the best kind of brownie recipe is the one that results the fudgy kind of brownies. If you think otherwise, trust us, these chocolate brownies are sure to change your mind. Originally created in the 1800s, the decadent US-born",
      imagePath: generatePlaceholderImage("cherry-delight-dessert"),
      price: 74750,
      availableAddons: [
        Addon(name: "Extra Cheese", price: 74750),
        Addon(name: "Bacon", price: 138750),
        Addon(name: "Avocado", price: 288750)
      ],
      category: FoodCategory.nam,
      quantity: 10,
    ),
    Food(
      name: "Chocolate-sandwich-cupcakes",
      description:
          "Every cook needs a moist banana cake recipe that they keep coming back to, and we think this recipe is the only one you need. Not to be mistaken for banana bread, this recipe proves there's a difference between the two related",
      imagePath: generatePlaceholderImage("chocolate-sandwich-cupcakes"),
      price: 29750,
      availableAddons: [
        Addon(name: "Extra Cheese", price: 29750),
        Addon(name: "Bacon", price: 138750),
        Addon(name: "Avocado", price: 221250)
      ],
      category: FoodCategory.nam,
      quantity: 10,
    ),
    Food(
      name: "milk-n-cookies-icebox",
      description:
          "What's better than a decadent chocolate mousse recipe? A easy chocolate mousse recipe that's ready in mere minutes. With its timeless elegance, chocolate mousse is always in fashion. From its first appearance in France in the",
      imagePath: generatePlaceholderImage("milk-n-cookies-icebox"),
      price: 55500,
      availableAddons: [
        Addon(name: "Extra Cheese", price: 55500),
        Addon(name: "Bacon", price: 113750),
        Addon(name: "Avocado", price: 138750)
      ],
      category: FoodCategory.nam,
      quantity: 10,
    ),
    Food(
      name: "CremeCaramel",
      description:
          "Classic sticky date pudding recipe An ultra-moist, brown sugar cake doused in rich butterscotch sauce, our classic sticky date pudding recipe is what comfort food eating is all about. Is there a more glorious pudding in the world than",
      imagePath: generatePlaceholderImage("cremecaramel"),
      price: 149750,
      availableAddons: [
        Addon(name: "Extra Cheese", price: 149750),
        Addon(name: "Bacon", price: 213750),
        Addon(name: "Avocado", price: 238750)
      ],
      category: FoodCategory.nam,
      quantity: 10,
    ),
    Food(
      name: "summer-desserts",
      description:
          "Is it odd that one of the greatest cakes in the world is made with a vegetable? Not at all. Carrots have a natural sweetness that becomes more pronounced the longer they cook. This carrot cake recipe presents carrot cake with a swoon-",
      imagePath: generatePlaceholderImage("summer-desserts"),
      price: 27750,
      availableAddons: [
        Addon(name: "Extra Cheese", price: 27750),
        Addon(name: "Bacon", price: 127750),
        Addon(name: "Avocado", price: 188750)
      ],
      category: FoodCategory.nam,
      quantity: 10,
    ),
    // drinks
    Food(
      name: "Blue Drink-Silver Factory",
      description:
          "Cool down with this fresh peach fizz served with mint leaves and juicy raspberries.",
      imagePath: generatePlaceholderImage("blue-drink-silver-factory"),
      price: 30250,
      availableAddons: [
        Addon(name: "Extra Cheese", price: 30250),
        Addon(name: "Bacon", price: 77750),
        Addon(name: "Avocado", price: 113750)
      ],
      category: FoodCategory.bac,
      quantity: 10,
    ),
    Food(
      name: "Frozen apple margarita",
      description:
          "To make this frozen drink into a mocktail, swap the tequila for an extra cup of sparkling apple juice.",
      imagePath: generatePlaceholderImage("frozen-apple-margarita"),
      price: 55250,
      availableAddons: [
        Addon(name: "Extra Cheese", price: 55250),
        Addon(name: "Bacon", price: 88000),
        Addon(name: "Avocado", price: 113500)
      ],
      category: FoodCategory.bac,
      quantity: 10,
    ),
    Food(
      name: "Pink grapefruit party punch",
      description:
          "Go alcohol-free and swap the tequila and Cointreau for 3/4 cup (185ml) mango and orange flavoured mineral water.",
      imagePath: generatePlaceholderImage("pink-grapefruit-party-punch"),
      price: 30250,
      availableAddons: [
        Addon(name: "Extra Cheese", price: 30250),
        Addon(name: "Bacon", price: 95250),
        Addon(name: "Avocado", price: 111250)
      ],
      category: FoodCategory.bac,
      quantity: 10,
    ),
    Food(
      name: "Curtis Stone's fresh strawberry water",
      description:
          "Serve a round of Curtis Stone's non-alcoholic summer drink, made with fresh strawberries, lime juice and mint.",
      imagePath: generatePlaceholderImage("fresh-strawberry-water"),
      price: 55250,
      availableAddons: [
        Addon(name: "Extra Cheese", price: 55250),
        Addon(name: "Bacon", price: 77750),
        Addon(name: "Avocado", price: 113750)
      ],
      category: FoodCategory.bac,
      quantity: 10,
    ),
    Food(
      name: "Basil, strawberry and watermelon cooler",
      description:
          "Everyone will love this pretty-in-pink strawberry and watermelon cocktail.",
      imagePath: generatePlaceholderImage("watermelon-cooler"),
      price: 55500,
      availableAddons: [
        Addon(name: "Extra Cheese", price: 55500),
        Addon(name: "Bacon", price: 80250),
        Addon(name: "Avocado", price: 106250)
      ],
      category: FoodCategory.bac,
      quantity: 10,
    ),
  ];

  //user cart
  final List<CartItem> _cart = [];
  List<CartItem> _firebaseCart = [];
  bool _isCartLoading = false;

  //orders
  List<order_model.Order> _allOrders = [];
  List<order_model.Order> _userOrders = [];
  bool _isOrdersLoading = false;
  /*

  GETTERS

  */

  List<Food> get menu => _menu;
  List<CartItem> get cart => _cart;
  List<CartItem> get firebaseCart => _firebaseCart;
  bool get isCartLoading => _isCartLoading;
  List<order_model.Order> get allOrders => _allOrders;
  List<order_model.Order> get userOrders => _userOrders;
  bool get isOrdersLoading => _isOrdersLoading;

  /*
  
  OPERATIONS

  */

  //add to cart
  void addToCart(Food food, List<Addon> selectedAddons) {
    // see if there is a cart item already with the same food and selected addons
    CartItem? cartItem = _cart.firstWhereOrNull((item) {
      // check if the food items are the same
      bool isSameFood = item.food == food;

      // check if the list of selected addons are the same
      bool isSameAddons =
          ListEquality().equals(item.selectedAddons, selectedAddons);

      return isSameFood && isSameAddons;
    });
    //if item already exists, increase it's quantity
    if (cartItem != null) {
      cartItem.quantity++;
    }

    // otherwise,add a new cart item to the cart
    else {
      _cart.add(
        CartItem(
          foodId: food.id ?? '',
          food: food,
          selectedAddons: selectedAddons,
        ),
      );
    }
    notifyListeners();
  }

  //remove from cart
  void removeFromCart(CartItem cartItem) {
    int cartIndex = _cart.indexOf(cartItem);

    if (cartIndex != -1) {
      if (_cart[cartIndex].quantity > 1) {
        _cart[cartIndex].quantity--;
      } else {
        _cart.removeAt(cartIndex);
      }
    }
    notifyListeners();
  }

  //get total price of cart
  double gettotalPrice() {
    double total = 0;
    for (CartItem cartItem in _cart) {
      double itemTotal = cartItem.food?.price ?? 0.0;
      for (Addon addon in cartItem.selectedAddons) {
        itemTotal += addon.price;
      }
      total += itemTotal * cartItem.quantity;
    }
    return total;
  }

  //get total number of items in cart
  int getTotalItemCount() {
    int totalItemCount = 0;
    for (CartItem cartItem in _cart) {
      totalItemCount += cartItem.quantity;
    }
    return totalItemCount;
  }

  //clear cart
  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  //load menu from Firestore
  Future<void> loadMenuFromFirestore() async {
    try {
      final foods = await _foodService.getFoods().first;
      _menu = foods;
      notifyListeners();
    } catch (e) {
      // If Firestore fails, keep using hardcoded data
      print('Failed to load menu from Firestore: $e');
    }
  }

  // Preload menu data for faster initial display
  Future<void> preloadMenu() async {
    try {
      // Try to get cached data first
      final cachedFoods = await _foodService.getFoods().first;
      if (cachedFoods.isNotEmpty) {
        _menu = cachedFoods;
        notifyListeners();
      }
    } catch (e) {
      print('Failed to preload menu: $e');
      // Keep using hardcoded data as fallback
    }
  }

  //get stream of foods from Firestore
  Stream<List<Food>> getFoodsStream() {
    return _foodService.getFoods();
  }

  //get foods by category from Firestore
  Stream<List<Food>> getFoodsByCategoryStream(FoodCategory category) {
    return _foodService.getFoodsByCategory(category);
  }

  // CART MANAGEMENT METHODS

  // Load cart from Firebase
  Future<void> loadCartFromFirebase() async {
    try {
      _isCartLoading = true;
      notifyListeners();

      final cartItems = await _cartService.getCartItems();
      _firebaseCart = cartItems;
      notifyListeners();
    } catch (e) {
      print('Failed to load cart from Firebase: $e');
    } finally {
      _isCartLoading = false;
      notifyListeners();
    }
  }

  // Get cart items stream
  Stream<List<CartItem>> getCartItemsStream() {
    return _cartService.getCartItemsStream();
  }

  // Add item to Firebase cart
  Future<void> addToFirebaseCart({
    required String foodId,
    required List<Addon> selectedAddons,
    int quantity = 1,
  }) async {
    try {
      await _cartService.addToCart(
        foodId: foodId,
        selectedAddons: selectedAddons,
        quantity: quantity,
      );
      // Reload cart to get updated data
      await loadCartFromFirebase();
    } catch (e) {
      print('Failed to add to Firebase cart: $e');
      rethrow;
    }
  }

  // Remove item from Firebase cart
  Future<void> removeFromFirebaseCart(String cartItemId) async {
    try {
      await _cartService.removeFromCart(cartItemId);
      // Reload cart to get updated data
      await loadCartFromFirebase();
    } catch (e) {
      print('Failed to remove from Firebase cart: $e');
      rethrow;
    }
  }

  // Update quantity in Firebase cart
  Future<void> updateFirebaseCartQuantity(
      String cartItemId, int quantity) async {
    try {
      await _cartService.updateQuantity(cartItemId, quantity);
      // Reload cart to get updated data
      await loadCartFromFirebase();
    } catch (e) {
      print('Failed to update Firebase cart quantity: $e');
      rethrow;
    }
  }

  // Toggle item selection in Firebase cart
  Future<void> toggleFirebaseCartItemSelection(String cartItemId) async {
    try {
      await _cartService.toggleItemSelection(cartItemId);
      // Reload cart to get updated data
      await loadCartFromFirebase();
    } catch (e) {
      print('Failed to toggle Firebase cart item selection: $e');
      rethrow;
    }
  }

  // Clear Firebase cart
  Future<void> clearFirebaseCart() async {
    try {
      await _cartService.clearCart();
      _firebaseCart.clear();
      notifyListeners();
    } catch (e) {
      print('Failed to clear Firebase cart: $e');
      rethrow;
    }
  }

  // Get Firebase cart total
  Future<double> getFirebaseCartTotal() async {
    try {
      return await _cartService.getCartTotal();
    } catch (e) {
      print('Failed to get Firebase cart total: $e');
      return 0.0;
    }
  }

  // Get selected items total from Firebase cart
  Future<double> getFirebaseSelectedItemsTotal() async {
    try {
      return await _cartService.getSelectedItemsTotal();
    } catch (e) {
      print('Failed to get Firebase selected items total: $e');
      return 0.0;
    }
  }

  // ORDER MANAGEMENT METHODS

  // Load all orders (for admin)
  Future<void> loadAllOrders() async {
    try {
      _isOrdersLoading = true;
      notifyListeners();

      final orders = await _orderService.getAllOrders();
      _allOrders = orders;
      notifyListeners();
    } catch (e) {
      print('Failed to load all orders: $e');
    } finally {
      _isOrdersLoading = false;
      notifyListeners();
    }
  }

  // Load user orders
  Future<void> loadUserOrders() async {
    try {
      _isOrdersLoading = true;
      notifyListeners();

      final orders = await _orderService.getUserOrders();
      _userOrders = orders;
      notifyListeners();
    } catch (e) {
      print('Failed to load user orders: $e');
    } finally {
      _isOrdersLoading = false;
      notifyListeners();
    }
  }

  // Get all orders stream (for admin)
  Stream<List<order_model.Order>> getAllOrdersStream() {
    return _orderService.getAllOrdersStream();
  }

  // Get user orders stream
  Stream<List<order_model.Order>> getUserOrdersStream() {
    return _orderService.getUserOrdersStream();
  }

  // Update order status
  Future<void> updateOrderStatus(
      String orderId, order_model.OrderStatus newStatus) async {
    try {
      await _orderService.updateOrderStatus(orderId, newStatus);
      // Reload orders to get updated data
      await loadAllOrders();
      await loadUserOrders();
    } catch (e) {
      print('Failed to update order status: $e');
      rethrow;
    }
  }

  // Update order delivery info (shipper information)
  Future<void> updateOrderDeliveryInfo({
    required String orderId,
    String? deliveryPerson,
    String? deliveryPersonPhone,
    String? trackingNumber,
    DateTime? deliveryDate,
    String? deliveryTime,
  }) async {
    try {
      await _orderService.updateOrderDeliveryInfo(
        orderId: orderId,
        deliveryPerson: deliveryPerson,
        deliveryPersonPhone: deliveryPersonPhone,
        trackingNumber: trackingNumber,
        deliveryDate: deliveryDate,
        deliveryTime: deliveryTime,
      );
      // Reload orders to get updated data
      await loadAllOrders();
      await loadUserOrders();
    } catch (e) {
      print('Failed to update order delivery info: $e');
      rethrow;
    }
  }

  // Cancel order
  Future<void> cancelOrder(String orderId) async {
    try {
      await _orderService.cancelOrder(orderId);
      // Reload orders to get updated data
      await loadUserOrders();
    } catch (e) {
      print('Failed to cancel order: $e');
      rethrow;
    }
  }

  // Search orders
  Future<List<order_model.Order>> searchOrders(String query) async {
    try {
      return await _orderService.searchOrders(query);
    } catch (e) {
      print('Failed to search orders: $e');
      return [];
    }
  }

  // Update orders list (for search results)
  void updateOrdersList(List<order_model.Order> orders) {
    _allOrders = orders;
    notifyListeners();
  }
}
