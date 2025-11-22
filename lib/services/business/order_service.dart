import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_delivery_fbase/models/order.dart' as order_model;
import 'package:food_delivery_fbase/models/cart_item.dart';
import 'package:food_delivery_fbase/services/business/food_service.dart';
import 'package:food_delivery_fbase/services/business/notification_service.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FoodService _foodService = FoodService();
  final NotificationService _notificationService = NotificationService();

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Get orders collection reference
  CollectionReference get _ordersCollection => _firestore.collection('orders');

  // Generate readable order code (format: DH-YYYYMMDD-XXXX)
  Future<String> _generateOrderCode(DateTime orderDate) async {
    try {
      // Format: DH-YYYYMMDD
      final datePrefix = 'DH-${orderDate.year}${orderDate.month.toString().padLeft(2, '0')}${orderDate.day.toString().padLeft(2, '0')}';
      
      // Get count of orders created today
      final startOfDay = DateTime(orderDate.year, orderDate.month, orderDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final querySnapshot = await _ordersCollection
          .where('orderDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('orderDate', isLessThan: Timestamp.fromDate(endOfDay))
          .get();
      
      // Generate sequence number (1-based)
      final sequenceNumber = querySnapshot.docs.length + 1;
      final sequenceStr = sequenceNumber.toString().padLeft(4, '0');
      
      return '$datePrefix-$sequenceStr';
    } catch (e) {
      // Fallback: use timestamp-based code
      final timestamp = orderDate.millisecondsSinceEpoch;
      return 'DH-${timestamp.toString().substring(timestamp.toString().length - 8)}';
    }
  }

  // Create new order with stock check and transaction safety
  // Sử dụng Firestore transaction để đảm bảo atomicity
  Future<String> createOrderWithStockCheck({
    required List<CartItem> items,
    required double totalAmount,
    required order_model.OrderPaymentMethod paymentMethod,
    required String customerName,
    required String customerPhone,
    required String deliveryAddress,
    String? notes,
    Map<String, dynamic>? paymentDetails,
    required String transactionId, // Transaction ID từ payment gateway
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Generate order code trước (không thể async trong transaction)
      final orderDate = DateTime.now();
      final orderCode = await _generateOrderCode(orderDate);

      // Load food details trước khi vào transaction
      final itemsWithFood = <CartItem>[];
      for (final item in items) {
        try {
          final food = await _foodService.getFoodById(item.foodId);
          final itemWithFood = item.copyWith(food: food);
          itemsWithFood.add(itemWithFood);
        } catch (e) {
          // Nếu không load được food, vẫn tiếp tục với item
          itemsWithFood.add(item);
        }
      }

      // Sử dụng Firestore transaction để đảm bảo atomicity
      return await _firestore.runTransaction((transaction) async {
        final foodDocs = <String, DocumentSnapshot>{};

        // Kiểm tra tồn kho trong transaction
        for (final item in items) {
          // Lấy food document trong transaction
          final foodDoc = await transaction.get(
            _firestore.collection('foods').doc(item.foodId),
          );

          if (!foodDoc.exists) {
            throw Exception('Sản phẩm ${item.foodId} không tồn tại');
          }

          final foodData = foodDoc.data() as Map<String, dynamic>;
          final currentQuantity = (foodData['quantity'] ?? 0) as int;

          // Kiểm tra tồn kho
          if (currentQuantity < item.quantity) {
            final foodName = foodData['name'] ?? 'Sản phẩm';
            throw Exception(
              '$foodName chỉ còn $currentQuantity sản phẩm. Bạn đã chọn ${item.quantity} sản phẩm.',
            );
          }

          // Kiểm tra sản phẩm có còn hàng không
          if (currentQuantity <= 0) {
            final foodName = foodData['name'] ?? 'Sản phẩm';
            throw Exception('$foodName đã hết hàng');
          }

          // Lưu food document để cập nhật sau
          foodDocs[item.foodId] = foodDoc;
        }

        // Tạo payment details với transaction ID (không lưu thông tin thẻ)
        final safePaymentDetails = <String, dynamic>{
          'transactionId': transactionId,
          'method': paymentMethod.name,
        };

        final order = order_model.Order(
          userId: userId,
          orderCode: orderCode,
          items: itemsWithFood,
          totalAmount: totalAmount,
          status: order_model.OrderStatus.pending,
          paymentMethod: paymentMethod,
          customerName: customerName,
          customerPhone: customerPhone,
          deliveryAddress: deliveryAddress,
          notes: notes,
          paymentDetails: safePaymentDetails,
          orderDate: orderDate,
        );

        // Tạo đơn hàng trong transaction
        final orderRef = _ordersCollection.doc();
        transaction.set(orderRef, order.toMap());
        final orderId = orderRef.id;

        // Cập nhật số lượng sản phẩm trong transaction
        for (final entry in foodDocs.entries) {
          final foodId = entry.key;
          final foodDoc = entry.value;
          final foodData = foodDoc.data() as Map<String, dynamic>;
          final currentQuantity = (foodData['quantity'] ?? 0) as int;

          // Tìm quantity cần giảm
          final item = items.firstWhere((i) => i.foodId == foodId);
          final newQuantity = currentQuantity - item.quantity;

          // Cập nhật trong transaction
          transaction.update(
            _firestore.collection('foods').doc(foodId),
            {
              'quantity': newQuantity,
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );
        }

        return orderId;
      }).then((orderId) async {
        // Gửi thông báo sau khi tạo đơn thành công (ngoài transaction)
        try {
          await _notificationService.sendOrderStatusUpdateNotification(
            orderId: orderId,
            userId: userId,
            oldStatus: order_model.OrderStatus.pending,
            newStatus: order_model.OrderStatus.pending,
            orderNumber: orderCode,
          );
        } catch (e) {
          // Log lỗi nhưng không throw vì đơn hàng đã được tạo thành công
          print('Failed to send notification for order $orderId: $e');
        }
        return orderId;
      });
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  // Create new order (legacy method - giữ lại để tương thích)
  Future<String> createOrder({
    required List<CartItem> items,
    required double totalAmount,
    required order_model.OrderPaymentMethod paymentMethod,
    required String customerName,
    required String customerPhone,
    required String deliveryAddress,
    String? notes,
    Map<String, dynamic>? paymentDetails,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Load food details for all items
      final itemsWithFood = <CartItem>[];
      for (final item in items) {
        try {
          final food = await _foodService.getFoodById(item.foodId);
          final itemWithFood = item.copyWith(food: food);
          itemsWithFood.add(itemWithFood);
        } catch (e) {
          print('Failed to load food for item ${item.foodId}: $e');
          // Continue without food details
          itemsWithFood.add(item);
        }
      }

      final orderDate = DateTime.now();
      final orderCode = await _generateOrderCode(orderDate);

      final order = order_model.Order(
        userId: userId,
        orderCode: orderCode,
        items: itemsWithFood,
        totalAmount: totalAmount,
        status: order_model.OrderStatus.pending,
        paymentMethod: paymentMethod,
        customerName: customerName,
        customerPhone: customerPhone,
        deliveryAddress: deliveryAddress,
        notes: notes,
        paymentDetails: paymentDetails,
        orderDate: orderDate,
      );

      final docRef = await _ordersCollection.add(order.toMap());
      final orderId = docRef.id;

      // Cập nhật số lượng sản phẩm sau khi tạo đơn hàng thành công
      try {
        print('Updating food quantities for order $orderId...');
        print('Total items to update: ${itemsWithFood.length}');
        for (final item in itemsWithFood) {
          if (item.foodId.isEmpty) {
            print('WARNING: Skipping item with empty foodId');
            continue;
          }
          print('Updating food ${item.foodId}: reducing quantity by ${item.quantity}');
          await _foodService.updateFoodQuantity(item.foodId, -item.quantity);
          print('Successfully updated food ${item.foodId}');
        }
        print('All food quantities updated successfully for order $orderId');
      } catch (e, stackTrace) {
        // Nếu cập nhật số lượng thất bại, vẫn giữ đơn hàng nhưng log lỗi
        print('ERROR: Failed to update food quantities for order $orderId: $e');
        print('Stack trace: $stackTrace');
      }

      // Gửi thông báo khi đơn hàng mới được tạo
      await _notificationService.sendOrderStatusUpdateNotification(
        orderId: orderId,
        userId: userId,
        oldStatus: order_model.OrderStatus.pending,
        newStatus: order_model.OrderStatus.pending,
        orderNumber: orderCode,
      );

      return orderId;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  // Get order by ID
  Future<order_model.Order?> getOrderById(String orderId) async {
    try {
      final doc = await _ordersCollection.doc(orderId).get();
      if (doc.exists) {
        final order = order_model.Order.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        // Load food details for all items
        final itemsWithFood = <CartItem>[];
        for (final item in order.items) {
          try {
            final food = await _foodService.getFoodById(item.foodId);
            final itemWithFood = item.copyWith(food: food);
            itemsWithFood.add(itemWithFood);
          } catch (e) {
            print('Failed to load food for item ${item.foodId}: $e');
            // Continue without food details
            itemsWithFood.add(item);
          }
        }
        return order.copyWith(items: itemsWithFood);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  // Get order by ID stream for real-time updates
  Stream<order_model.Order?> getOrderByIdStream(String orderId) {
    return _ordersCollection.doc(orderId).snapshots().asyncMap((doc) async {
      if (doc.exists) {
        final order = order_model.Order.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        // Load food details for all items
        final itemsWithFood = <CartItem>[];
        for (final item in order.items) {
          try {
            final food = await _foodService.getFoodById(item.foodId);
            final itemWithFood = item.copyWith(food: food);
            itemsWithFood.add(itemWithFood);
          } catch (e) {
            print('Failed to load food for item ${item.foodId}: $e');
            // Continue without food details
            itemsWithFood.add(item);
          }
        }
        return order.copyWith(items: itemsWithFood);
      }
      return null;
    });
  }

  // Get user's orders
  Future<List<order_model.Order>> getUserOrders() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      List<order_model.Order> orders;
      
      // Try with composite query first
      try {
        final querySnapshot = await _ordersCollection
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .get();

        orders = querySnapshot.docs
            .map((doc) => order_model.Order.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
      } catch (e) {
        // If composite query fails, try simple query
        if (e.toString().contains('index')) {
          print('Composite index not found, using simple query...');
          final querySnapshot = await _ordersCollection
              .where('userId', isEqualTo: userId)
              .get();
          
          // Sort manually
          orders = querySnapshot.docs
              .map((doc) => order_model.Order.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();
          
          orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
        } else {
          rethrow;
        }
      }

      // Load food details for all items in all orders
      final ordersWithFood = <order_model.Order>[];
      for (final order in orders) {
        final itemsWithFood = <CartItem>[];
        for (final item in order.items) {
          try {
            final food = await _foodService.getFoodById(item.foodId);
            final itemWithFood = item.copyWith(food: food);
            itemsWithFood.add(itemWithFood);
          } catch (e) {
            print('Failed to load food for item ${item.foodId}: $e');
            // Continue without food details
            itemsWithFood.add(item);
          }
        }
        ordersWithFood.add(order.copyWith(items: itemsWithFood));
      }
      
      return ordersWithFood;
    } catch (e) {
      throw Exception('Failed to get user orders: $e');
    }
  }

  // Get user's orders stream for real-time updates
  Stream<List<order_model.Order>> getUserOrdersStream() {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      return _ordersCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => order_model.Order.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to get user orders stream: $e');
    }
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, order_model.OrderStatus newStatus) async {
    try {
      // Lấy trạng thái cũ trước khi cập nhật
      final order = await getOrderById(orderId);
      final oldStatus = order?.status;

      // Cập nhật trạng thái đơn hàng
      await _ordersCollection.doc(orderId).update({
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Hoàn lại số lượng sản phẩm nếu chuyển sang trạng thái cancelled
      // (chỉ khi trước đó chưa phải cancelled)
      if (order != null && 
          oldStatus != null && 
          oldStatus != order_model.OrderStatus.cancelled &&
          newStatus == order_model.OrderStatus.cancelled) {
        try {
          for (final item in order.items) {
            await _foodService.updateFoodQuantity(item.foodId, item.quantity);
          }
        } catch (e) {
          // Nếu hoàn lại số lượng thất bại, vẫn giữ trạng thái cancelled nhưng log lỗi
          print('Warning: Failed to restore food quantities for cancelled order $orderId: $e');
        }
      }

      // Gửi thông báo nếu trạng thái thay đổi và có order
      if (order != null && oldStatus != null && oldStatus != newStatus) {
        await _notificationService.sendOrderStatusUpdateNotification(
          orderId: orderId,
          userId: order.userId,
          oldStatus: oldStatus,
          newStatus: newStatus,
          orderNumber: order.displayOrderCode,
        );
      }
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // Cancel order
  Future<void> cancelOrder(String orderId) async {
    try {
      final order = await getOrderById(orderId);
      if (order == null) {
        throw Exception('Order not found');
      }

      if (!order.canBeCancelled) {
        throw Exception('Order cannot be cancelled');
      }

      // updateOrderStatus sẽ tự động hoàn lại số lượng khi chuyển sang cancelled
      await updateOrderStatus(orderId, order_model.OrderStatus.cancelled);
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }

  // Update order with delivery information
  Future<void> updateOrderDeliveryInfo({
    required String orderId,
    String? deliveryPerson,
    String? deliveryPersonPhone,
    String? trackingNumber,
    DateTime? deliveryDate,
    String? deliveryTime,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (deliveryPerson != null) updateData['deliveryPerson'] = deliveryPerson;
      if (deliveryPersonPhone != null) updateData['deliveryPersonPhone'] = deliveryPersonPhone;
      if (trackingNumber != null) updateData['trackingNumber'] = trackingNumber;
      if (deliveryDate != null) updateData['deliveryDate'] = Timestamp.fromDate(deliveryDate);
      if (deliveryTime != null) updateData['deliveryTime'] = deliveryTime;

      await _ordersCollection.doc(orderId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update delivery info: $e');
    }
  }

  // ADMIN METHODS

  // Get all orders (for admin)
  Future<List<order_model.Order>> getAllOrders() async {
    try {
      final querySnapshot = await _ordersCollection.get();
      
      final orders = querySnapshot.docs
          .map((doc) => order_model.Order.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      // Sort manually to avoid index requirement
      orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));

      // Load food details for all items in all orders
      final ordersWithFood = <order_model.Order>[];
      for (final order in orders) {
        final itemsWithFood = <CartItem>[];
        for (final item in order.items) {
          try {
            final food = await _foodService.getFoodById(item.foodId);
            final itemWithFood = item.copyWith(food: food);
            itemsWithFood.add(itemWithFood);
          } catch (e) {
            print('Failed to load food for item ${item.foodId}: $e');
            // Continue without food details
            itemsWithFood.add(item);
          }
        }
        ordersWithFood.add(order.copyWith(items: itemsWithFood));
      }
      
      return ordersWithFood;
    } catch (e) {
      throw Exception('Failed to get all orders: $e');
    }
  }

  // Get all orders stream (for admin)
  Stream<List<order_model.Order>> getAllOrdersStream() {
    return _ordersCollection
        .snapshots()
        .asyncMap((snapshot) async {
      final orders = snapshot.docs
          .map((doc) => order_model.Order.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      // Sort manually to avoid index requirement
      orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));

      // Load food details for all items in all orders
      final ordersWithFood = <order_model.Order>[];
      for (final order in orders) {
        final itemsWithFood = <CartItem>[];
        for (final item in order.items) {
          try {
            final food = await _foodService.getFoodById(item.foodId);
            final itemWithFood = item.copyWith(food: food);
            itemsWithFood.add(itemWithFood);
          } catch (e) {
            print('Failed to load food for item ${item.foodId}: $e');
            // Continue without food details
            itemsWithFood.add(item);
          }
        }
        ordersWithFood.add(order.copyWith(items: itemsWithFood));
      }
      
      return ordersWithFood;
    });
  }

  // Get orders by status (for admin)
  Future<List<order_model.Order>> getOrdersByStatus(order_model.OrderStatus status) async {
    try {
      final querySnapshot = await _ordersCollection
          .where('status', isEqualTo: status.name)
          .orderBy('orderDate', descending: true)
          .get();

      final orders = querySnapshot.docs
          .map((doc) => order_model.Order.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Load food details for all items in all orders
      final ordersWithFood = <order_model.Order>[];
      for (final order in orders) {
        final itemsWithFood = <CartItem>[];
        for (final item in order.items) {
          try {
            final food = await _foodService.getFoodById(item.foodId);
            final itemWithFood = item.copyWith(food: food);
            itemsWithFood.add(itemWithFood);
          } catch (e) {
            print('Failed to load food for item ${item.foodId}: $e');
            // Continue without food details
            itemsWithFood.add(item);
          }
        }
        ordersWithFood.add(order.copyWith(items: itemsWithFood));
      }
      
      return ordersWithFood;
    } catch (e) {
      throw Exception('Failed to get orders by status: $e');
    }
  }

  // Get orders by date range (for admin)
  Future<List<order_model.Order>> getOrdersByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final querySnapshot = await _ordersCollection
          .where('orderDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('orderDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('orderDate', descending: true)
          .get();

      final orders = querySnapshot.docs
          .map((doc) => order_model.Order.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Load food details for all items in all orders
      final ordersWithFood = <order_model.Order>[];
      for (final order in orders) {
        final itemsWithFood = <CartItem>[];
        for (final item in order.items) {
          try {
            final food = await _foodService.getFoodById(item.foodId);
            final itemWithFood = item.copyWith(food: food);
            itemsWithFood.add(itemWithFood);
          } catch (e) {
            print('Failed to load food for item ${item.foodId}: $e');
            // Continue without food details
            itemsWithFood.add(item);
          }
        }
        ordersWithFood.add(order.copyWith(items: itemsWithFood));
      }
      
      return ordersWithFood;
    } catch (e) {
      throw Exception('Failed to get orders by date range: $e');
    }
  }

  // Get order statistics (for admin)
  Future<Map<String, dynamic>> getOrderStatistics() async {
    try {
      final allOrders = await getAllOrders();
      
      final totalOrders = allOrders.length;
      final pendingOrders = allOrders.where((o) => o.status == order_model.OrderStatus.pending).length;
      final confirmedOrders = allOrders.where((o) => o.status == order_model.OrderStatus.confirmed).length;
      final preparingOrders = allOrders.where((o) => o.status == order_model.OrderStatus.preparing).length;
      final readyOrders = allOrders.where((o) => o.status == order_model.OrderStatus.ready).length;
      final deliveredOrders = allOrders.where((o) => o.status == order_model.OrderStatus.delivered).length;
      final cancelledOrders = allOrders.where((o) => o.status == order_model.OrderStatus.cancelled).length;
      
      final totalRevenue = allOrders
          .where((o) => o.status == order_model.OrderStatus.delivered)
          .fold(0.0, (sum, order) => sum + order.totalAmount);
      
      final averageOrderValue = deliveredOrders > 0 ? totalRevenue / deliveredOrders : 0.0;

      return {
        'totalOrders': totalOrders,
        'pendingOrders': pendingOrders,
        'confirmedOrders': confirmedOrders,
        'preparingOrders': preparingOrders,
        'readyOrders': readyOrders,
        'deliveredOrders': deliveredOrders,
        'cancelledOrders': cancelledOrders,
        'totalRevenue': totalRevenue,
        'averageOrderValue': averageOrderValue,
      };
    } catch (e) {
      throw Exception('Failed to get order statistics: $e');
    }
  }

  // Search orders (for admin)
  Future<List<order_model.Order>> searchOrders(String query) async {
    try {
      // Search by order code, order ID, customer name, or phone
      final allOrders = await getAllOrders();
      return allOrders.where((order) {
        return order.orderCode?.toLowerCase().contains(query.toLowerCase()) == true ||
               order.id?.toLowerCase().contains(query.toLowerCase()) == true ||
               order.customerName.toLowerCase().contains(query.toLowerCase()) ||
               order.customerPhone.contains(query) ||
               order.trackingNumber?.toLowerCase().contains(query.toLowerCase()) == true;
      }).toList();
    } catch (e) {
      throw Exception('Failed to search orders: $e');
    }
  }

  // Get count of pending orders for admin
  Future<int> getPendingOrdersCount() async {
    try {
      final querySnapshot = await _ordersCollection
          .where('status', isEqualTo: order_model.OrderStatus.pending.name)
          .get();
      return querySnapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Get stream of pending orders count for admin
  Stream<int> getPendingOrdersCountStream() {
    return _ordersCollection
        .where('status', isEqualTo: order_model.OrderStatus.pending.name)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get count of active orders for user
  Future<int> getActiveOrdersCount(String userId) async {
    try {
      final querySnapshot = await _ordersCollection
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: [
            order_model.OrderStatus.confirmed.name,
            order_model.OrderStatus.preparing.name,
            order_model.OrderStatus.ready.name,
          ])
          .get();
      return querySnapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Get stream of active orders count for user
  Stream<int> getActiveOrdersCountStream(String userId) {
    return _ordersCollection
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: [
          order_model.OrderStatus.confirmed.name,
          order_model.OrderStatus.preparing.name,
          order_model.OrderStatus.ready.name,
        ])
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}