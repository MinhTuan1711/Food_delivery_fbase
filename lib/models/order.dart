import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_delivery_fbase/models/cart_item.dart';

enum OrderStatus {
  pending,      // Chờ xác nhận
  confirmed,    // Đã xác nhận
  preparing,     // Đang chuẩn bị
  ready,        // Sẵn sàng giao
  delivered,    // Đã giao
  cancelled,    // Đã hủy
}

enum OrderPaymentMethod {
  cash,
  stripe,
}

class Order {
  final String? id; // Firestore document ID
  final String? orderCode; // Mã đơn hàng dễ đọc (VD: DH-20240115-001)
  final String userId; // ID của user đặt hàng
  final List<CartItem> items; // Danh sách món đã đặt
  final double totalAmount; // Tổng tiền đơn hàng
  final OrderStatus status; // Trạng thái đơn hàng
  final OrderPaymentMethod paymentMethod; // Phương thức thanh toán
  final String customerName; // Tên khách hàng
  final String customerPhone; // Số điện thoại
  final String deliveryAddress; // Địa chỉ giao hàng
  final String? notes; // Ghi chú đặc biệt
  final Map<String, dynamic>? paymentDetails; // Chi tiết thanh toán
  final DateTime orderDate; // Ngày đặt hàng
  final DateTime? deliveryDate; // Ngày giao hàng
  final String? deliveryTime; // Thời gian giao hàng dự kiến
  final String? trackingNumber; // Mã theo dõi
  final String? deliveryPerson; // Người giao hàng
  final String? deliveryPersonPhone; // SĐT người giao hàng

  Order({
    this.id,
    this.orderCode,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    this.notes,
    this.paymentDetails,
    required this.orderDate,
    this.deliveryDate,
    this.deliveryTime,
    this.trackingNumber,
    this.deliveryPerson,
    this.deliveryPersonPhone,
  });

  // Convert Order to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'orderCode': orderCode,
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status.name,
      'paymentMethod': paymentMethod.name,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'deliveryAddress': deliveryAddress,
      'notes': notes,
      'paymentDetails': paymentDetails,
      'orderDate': Timestamp.fromDate(orderDate),
      'deliveryDate': deliveryDate != null ? Timestamp.fromDate(deliveryDate!) : null,
      'deliveryTime': deliveryTime,
      'trackingNumber': trackingNumber,
      'deliveryPerson': deliveryPerson,
      'deliveryPersonPhone': deliveryPersonPhone,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Create Order from Firestore document
  factory Order.fromMap(Map<String, dynamic> map, String documentId) {
    return Order(
      id: documentId,
      orderCode: map['orderCode'],
      userId: map['userId'] ?? '',
      items: (map['items'] as List<dynamic>?)
          ?.map((itemMap) => CartItem.fromMap(itemMap, ''))
          .toList() ?? [],
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      paymentMethod: OrderPaymentMethod.values.firstWhere(
        (e) => e.name == map['paymentMethod'],
        orElse: () => OrderPaymentMethod.cash,
      ),
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      deliveryAddress: map['deliveryAddress'] ?? '',
      notes: map['notes'],
      paymentDetails: map['paymentDetails'] != null 
          ? Map<String, dynamic>.from(map['paymentDetails']) 
          : null,
      orderDate: (map['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deliveryDate: (map['deliveryDate'] as Timestamp?)?.toDate(),
      deliveryTime: map['deliveryTime'],
      trackingNumber: map['trackingNumber'],
      deliveryPerson: map['deliveryPerson'],
      deliveryPersonPhone: map['deliveryPersonPhone'],
    );
  }

  // Copy with method for updates
  Order copyWith({
    String? id,
    String? orderCode,
    String? userId,
    List<CartItem>? items,
    double? totalAmount,
    OrderStatus? status,
    OrderPaymentMethod? paymentMethod,
    String? customerName,
    String? customerPhone,
    String? deliveryAddress,
    String? notes,
    Map<String, dynamic>? paymentDetails,
    DateTime? orderDate,
    DateTime? deliveryDate,
    String? deliveryTime,
    String? trackingNumber,
    String? deliveryPerson,
    String? deliveryPersonPhone,
  }) {
    return Order(
      id: id ?? this.id,
      orderCode: orderCode ?? this.orderCode,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      notes: notes ?? this.notes,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      orderDate: orderDate ?? this.orderDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      deliveryPerson: deliveryPerson ?? this.deliveryPerson,
      deliveryPersonPhone: deliveryPersonPhone ?? this.deliveryPersonPhone,
    );
  }

  // Get status display text in Vietnamese
  String get statusDisplayText {
    switch (status) {
      case OrderStatus.pending:
        return 'Chờ xác nhận';
      case OrderStatus.confirmed:
        return 'Đã xác nhận';
      case OrderStatus.preparing:
        return 'Đang chuẩn bị';
      case OrderStatus.ready:
        return 'Sẵn sàng giao';
      case OrderStatus.delivered:
        return 'Đã giao';
      case OrderStatus.cancelled:
        return 'Đã hủy';
    }
  }

  // Get status color
  String get statusColor {
    switch (status) {
      case OrderStatus.pending:
        return 'orange';
      case OrderStatus.confirmed:
        return 'blue';
      case OrderStatus.preparing:
        return 'purple';
      case OrderStatus.ready:
        return 'green';
      case OrderStatus.delivered:
        return 'green';
      case OrderStatus.cancelled:
        return 'red';
    }
  }

  // Get payment method display text in Vietnamese
  String get paymentMethodDisplayText {
    switch (paymentMethod) {
      case OrderPaymentMethod.cash:
        return 'Tiền mặt';
      case OrderPaymentMethod.stripe:
        return 'Stripe';
    }
  }

  // Check if order can be cancelled
  bool get canBeCancelled {
    return status == OrderStatus.pending || status == OrderStatus.confirmed;
  }

  // Check if order is completed
  bool get isCompleted {
    return status == OrderStatus.delivered;
  }

  // Check if order is active (not cancelled or delivered)
  bool get isActive {
    return status != OrderStatus.cancelled && status != OrderStatus.delivered;
  }

  // Get display order code (fallback to id if orderCode is null)
  String get displayOrderCode {
    return orderCode ?? id ?? 'N/A';
  }
}