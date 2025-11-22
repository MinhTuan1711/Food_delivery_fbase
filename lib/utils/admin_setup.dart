import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_delivery_fbase/services/auth/auth_service.dart';

class AdminSetup {
  static final AuthService _authService = AuthService();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Thiết lập user đầu tiên làm admin
  /// Gọi method này sau khi user đã đăng ký thành công
  static Future<void> setupFirstAdmin(String email) async {
    try {
      await _authService.setUserAsAdmin(email);
      print('User $email đã được thiết lập làm admin');
    } catch (e) {
      print('Lỗi khi thiết lập admin: $e');
    }
  }

  /// Kiểm tra xem có admin nào trong hệ thống không
  static Future<bool> hasAdmin() async {
    try {
      // Có thể thêm logic kiểm tra admin trong Firestore
      return false; // Placeholder
    } catch (e) {
      print('Lỗi khi kiểm tra admin: $e');
      return false;
    }
  }

  /// Thiết lập cấu hình phạm vi giao hàng (restaurant_config)
  /// Tạo document restaurant_config/delivery_range với country mặc định là "Vietnam"
  /// 
  /// [country] - Tên quốc gia được hỗ trợ giao hàng (mặc định: "Vietnam")
  /// 
  /// Returns: true nếu setup thành công, false nếu có lỗi
  static Future<bool> setupRestaurantConfig({String country = 'Vietnam'}) async {
    try {
      await _firestore
          .collection('restaurant_config')
          .doc('delivery_range')
          .set({
        'country': country,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('✅ Restaurant config đã được thiết lập thành công!');
      print('   - Country: $country');
      print('   - Document: restaurant_config/delivery_range');
      return true;
    } catch (e) {
      print('❌ Lỗi khi thiết lập restaurant config: $e');
      return false;
    }
  }

  /// Kiểm tra xem restaurant_config đã được setup chưa
  /// Returns: true nếu đã setup, false nếu chưa
  static Future<bool> isRestaurantConfigSetup() async {
    try {
      final doc = await _firestore
          .collection('restaurant_config')
          .doc('delivery_range')
          .get();
      
      return doc.exists && doc.data()?['country'] != null;
    } catch (e) {
      print('Lỗi khi kiểm tra restaurant config: $e');
      return false;
    }
  }

  /// Lấy thông tin cấu hình phạm vi giao hàng hiện tại
  /// Returns: Map chứa thông tin config hoặc null nếu chưa setup
  static Future<Map<String, dynamic>?> getRestaurantConfig() async {
    try {
      final doc = await _firestore
          .collection('restaurant_config')
          .doc('delivery_range')
          .get();
      
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Lỗi khi lấy restaurant config: $e');
      return null;
    }
  }
}


