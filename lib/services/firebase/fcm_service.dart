import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Top-level function to handle background messages
/// Phải được khai báo ở top-level, không phải trong class
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  debugPrint('Message data: ${message.data}');
  debugPrint('Message notification: ${message.notification?.title}');
}

/// Service để quản lý Firebase Cloud Messaging
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _fcmToken;
  StreamSubscription<String>? _tokenSubscription;

  /// FCM Token của thiết bị hiện tại
  String? get fcmToken => _fcmToken;

  /// Khởi tạo FCM Service
  Future<void> initialize() async {
    try {
      // Yêu cầu quyền thông báo (iOS)
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('Notification permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted notification permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('User granted provisional notification permission');
      } else {
        debugPrint('User denied or has not accepted notification permission');
        return;
      }

      // Đăng ký background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Lấy FCM token
      await _getFCMToken();

      // Lắng nghe thay đổi token
      _tokenSubscription = _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token refreshed: $newToken');
        _fcmToken = newToken;
        _saveTokenToFirestore(newToken);
      });

      // Xử lý thông báo khi app đang mở (foreground)
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Xử lý khi người dùng click vào thông báo (app đang đóng hoặc background)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Kiểm tra nếu app được mở từ thông báo khi app đang đóng
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }
    } catch (e) {
      debugPrint('Error initializing FCM: $e');
    }
  }

  /// Lấy FCM Token
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        debugPrint('FCM Token: $_fcmToken');
        await _saveTokenToFirestore(_fcmToken!);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  /// Lưu FCM token vào Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('No user logged in, cannot save FCM token');
        return;
      }

      // Lưu token vào collection fcm_tokens
      await _firestore.collection('fcm_tokens').doc(user.uid).set({
        'token': token,
        'userId': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.name,
      }, SetOptions(merge: true));

      // Cũng lưu token vào user document để dễ truy vấn
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('FCM token saved to Firestore for user: ${user.uid}');
    } catch (e) {
      debugPrint('Error saving FCM token to Firestore: $e');
    }
  }

  /// Xử lý thông báo khi app đang mở (foreground)
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.messageId}');
    debugPrint('Message data: ${message.data}');
    debugPrint('Message notification: ${message.notification?.title}');
    
    // Có thể hiển thị local notification hoặc in-app notification
    // Ở đây chúng ta chỉ log, bạn có thể tích hợp với flutter_local_notifications
    // để hiển thị notification khi app đang mở
  }

  /// Xử lý khi người dùng click vào thông báo
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Notification opened app: ${message.messageId}');
    debugPrint('Message data: ${message.data}');
    
    // Có thể điều hướng đến trang cụ thể dựa trên data trong message
    // Ví dụ: điều hướng đến trang đơn hàng nếu có orderId
    if (message.data.containsKey('orderId')) {
      final orderId = message.data['orderId'];
      debugPrint('Navigate to order: $orderId');
      // TODO: Implement navigation to order details page
    }
  }

  /// Lấy FCM token của user
  static Future<String?> getUserFCMToken(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('fcm_tokens')
          .doc(userId)
          .get();
      
      if (doc.exists && doc.data() != null) {
        return doc.data()!['token'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user FCM token: $e');
      return null;
    }
  }

  /// Xóa FCM token khi user đăng xuất
  Future<void> deleteToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('fcm_tokens').doc(user.uid).delete();
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': FieldValue.delete(),
          'fcmTokenUpdatedAt': FieldValue.delete(),
        });
      }
      await _messaging.deleteToken();
      _fcmToken = null;
      debugPrint('FCM token deleted');
    } catch (e) {
      debugPrint('Error deleting FCM token: $e');
    }
  }

  /// Cleanup khi service bị dispose
  void dispose() {
    _tokenSubscription?.cancel();
  }
}










































