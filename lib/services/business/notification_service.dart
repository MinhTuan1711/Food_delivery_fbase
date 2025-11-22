import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_delivery_fbase/models/order.dart' as order_model;
import 'package:food_delivery_fbase/services/firebase/fcm_service.dart';

/// Service để gửi thông báo khi đơn hàng được cập nhật
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Gửi thông báo khi trạng thái đơn hàng thay đổi
  /// 
  /// Lưu notification vào Firestore, Cloud Function sẽ tự động gửi FCM notification
  Future<void> sendOrderStatusUpdateNotification({
    required String orderId,
    required String userId,
    required order_model.OrderStatus oldStatus,
    required order_model.OrderStatus newStatus,
    String? orderNumber,
  }) async {
    try {
      // Lấy thông tin đơn hàng
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      final orderData = orderDoc.data()!;
      final customerName = orderData['customerName'] ?? 'Khách hàng';
      final totalAmount = orderData['totalAmount'] ?? 0.0;

      // Tạo nội dung thông báo
      final title = _getNotificationTitle(newStatus);
      final body = _getNotificationBody(newStatus, customerName, totalAmount, orderNumber);

      // Lưu notification vào Firestore
      // Cloud Function sẽ lắng nghe và gửi FCM notification
      await _firestore.collection('notifications').add({
        'userId': userId,
        'orderId': orderId,
        'type': 'order_status_update',
        'title': title,
        'body': body,
        'data': {
          'orderId': orderId,
          'oldStatus': oldStatus.name,
          'newStatus': newStatus.name,
          'orderNumber': orderNumber,
        },
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Gửi notification trực tiếp (fallback method)
      // Nếu Cloud Function chưa được setup, có thể sử dụng cách này
      // await _sendDirectNotification(userId, title, body, orderId);
    } catch (e) {
      print('Error sending order status notification: $e');
      // Không throw error để không ảnh hưởng đến việc cập nhật trạng thái đơn hàng
    }
  }

  /// Lấy tiêu đề thông báo dựa trên trạng thái
  String _getNotificationTitle(order_model.OrderStatus status) {
    switch (status) {
      case order_model.OrderStatus.pending:
        return 'Đơn hàng đã được đặt';
      case order_model.OrderStatus.confirmed:
        return 'Đơn hàng đã được xác nhận';
      case order_model.OrderStatus.preparing:
        return 'Đơn hàng đang được chuẩn bị';
      case order_model.OrderStatus.ready:
        return 'Đơn hàng sẵn sàng giao';
      case order_model.OrderStatus.delivered:
        return 'Đơn hàng đã được giao';
      case order_model.OrderStatus.cancelled:
        return 'Đơn hàng đã bị hủy';
    }
  }

  /// Lấy nội dung thông báo dựa trên trạng thái
  String _getNotificationBody(
    order_model.OrderStatus status,
    String customerName,
    double totalAmount,
    String? orderNumber,
  ) {
    final orderInfo = orderNumber != null ? 'Đơn hàng #$orderNumber' : 'Đơn hàng của bạn';
    final amount = _formatCurrency(totalAmount);

    switch (status) {
      case order_model.OrderStatus.pending:
        return '$orderInfo đã được đặt thành công. Tổng tiền: $amount. Đang chờ xác nhận.';
      case order_model.OrderStatus.confirmed:
        return '$orderInfo đã được xác nhận. Chúng tôi sẽ bắt đầu chuẩn bị ngay.';
      case order_model.OrderStatus.preparing:
        return '$orderInfo đang được chuẩn bị. Vui lòng chờ trong giây lát.';
      case order_model.OrderStatus.ready:
        return '$orderInfo đã sẵn sàng. Nhân viên giao hàng sẽ đến ngay.';
      case order_model.OrderStatus.delivered:
        return '$orderInfo đã được giao thành công. Cảm ơn bạn đã sử dụng dịch vụ!';
      case order_model.OrderStatus.cancelled:
        return '$orderInfo đã bị hủy. Nếu có thắc mắc, vui lòng liên hệ với chúng tôi.';
    }
  }

  /// Format số tiền thành chuỗi VNĐ
  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}₫';
  }

  /// Gửi thông báo trực tiếp (fallback method)
  /// Phương thức này yêu cầu Firebase Admin SDK hoặc REST API
  /// Khuyến nghị sử dụng Cloud Functions thay vì phương thức này
  Future<void> _sendDirectNotification(
    String userId,
    String title,
    String body,
    String orderId,
  ) async {
    try {
      // Lấy FCM token của user
      final fcmToken = await FCMService.getUserFCMToken(userId);
      if (fcmToken == null) {
        print('No FCM token found for user: $userId');
        return;
      }

      // Gửi notification qua HTTP request đến Firebase Admin REST API
      // LƯU Ý: Cần Firebase Admin SDK hoặc Cloud Functions để gửi
      // Phương thức này chỉ là placeholder, cần implement với Admin SDK
      print('Would send notification to token: $fcmToken');
      print('Title: $title');
      print('Body: $body');
      
      // TODO: Implement với Firebase Admin REST API hoặc Cloud Functions
    } catch (e) {
      print('Error sending direct notification: $e');
    }
  }

  /// Gửi thông báo tùy chỉnh
  Future<void> sendCustomNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'custom',
        'title': title,
        'body': body,
        'data': data ?? {},
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending custom notification: $e');
    }
  }

  /// Lấy danh sách thông báo của user
  Stream<QuerySnapshot> getNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Lấy danh sách thông báo chưa đọc của user
  Stream<QuerySnapshot> getUnreadNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Lấy số lượng thông báo chưa đọc
  Future<int> getUnreadCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();
      return querySnapshot.docs.length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  /// Lấy stream số lượng thông báo chưa đọc
  /// Không dùng orderBy để tránh cần composite index
  Stream<int> getUnreadCountStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Đánh dấu thông báo là đã đọc
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Đánh dấu tất cả thông báo là đã đọc
  Future<void> markAllAsRead(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  /// Xóa thông báo
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  /// Xóa tất cả thông báo đã đọc
  Future<void> deleteAllRead(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error deleting all read notifications: $e');
    }
  }
}



