import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminChecker {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Kiểm tra xem user hiện tại có phải admin không
  static Future<bool> isCurrentUserAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.exists && doc.data()?['isAdmin'] == true;
    } catch (e) {
      print('Lỗi khi kiểm tra admin: $e');
      return false;
    }
  }

  /// Lấy thông tin user hiện tại
  static Future<Map<String, dynamic>?> getCurrentUserInfo() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return {
          'uid': user.uid,
          'email': user.email,
          'isAdmin': doc.data()?['isAdmin'] ?? false,
          'createdAt': doc.data()?['createdAt'],
        };
      }
      return null;
    } catch (e) {
      print('Lỗi khi lấy thông tin user: $e');
      return null;
    }
  }

  /// Thiết lập user hiện tại làm admin
  static Future<void> setCurrentUserAsAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email,
        'isAdmin': true,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('User ${user.email} đã được thiết lập làm admin');
    } catch (e) {
      print('Lỗi khi thiết lập admin: $e');
      rethrow;
    }
  }

  /// Kiểm tra và in thông tin debug
  static Future<void> debugAdminStatus() async {
    try {
      final user = _auth.currentUser;
      print('=== ADMIN DEBUG INFO ===');
      print('Current User: ${user?.email ?? 'Not logged in'}');
      print('User UID: ${user?.uid ?? 'N/A'}');
      
      if (user != null) {
        final userInfo = await getCurrentUserInfo();
        print('User Info: $userInfo');
        print('Is Admin: ${userInfo?['isAdmin'] ?? false}');
      }
      print('========================');
    } catch (e) {
      print('Lỗi debug: $e');
    }
  }
}

























































