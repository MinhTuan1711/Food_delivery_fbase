import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_delivery_fbase/models/user.dart';
import 'package:food_delivery_fbase/services/auth/auth_service.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();

  // Get current user data
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _authService.getCurrentUser();
    if (firebaseUser == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Stream of current user data
  Stream<UserModel?> getCurrentUserStream() {
    final firebaseUser = _authService.getCurrentUser();
    if (firebaseUser == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return UserModel.fromMap(doc.data()!);
          }
          return null;
        });
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? phoneNumber,
    String? address,
    String? profileImageUrl,
    String? deliveryName,
    String? deliveryPhone,
    String? deliveryAddress,
  }) async {
    final firebaseUser = _authService.getCurrentUser();
    if (firebaseUser == null) throw Exception('No user logged in');

    try {
      Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (displayName != null) {
        updateData['displayName'] = displayName;
        // Also update Firebase Auth display name
        await firebaseUser.updateDisplayName(displayName);
      }
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (address != null) updateData['address'] = address;
      if (profileImageUrl != null) {
        updateData['profileImageUrl'] = profileImageUrl;
        // Also update Firebase Auth photo URL
        await firebaseUser.updatePhotoURL(profileImageUrl);
      }
      if (deliveryName != null) updateData['deliveryName'] = deliveryName;
      if (deliveryPhone != null) updateData['deliveryPhone'] = deliveryPhone;
      if (deliveryAddress != null) updateData['deliveryAddress'] = deliveryAddress;

      await _firestore.collection('users').doc(firebaseUser.uid).update(updateData);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Update user location
  Future<void> updateUserLocation(double latitude, double longitude) async {
    final firebaseUser = _authService.getCurrentUser();
    if (firebaseUser == null) throw Exception('No user logged in');

    try {
      await _firestore.collection('users').doc(firebaseUser.uid).update({
        'latitude': latitude,
        'longitude': longitude,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user location: $e');
    }
  }

  // Create user document (used during registration)
  Future<void> createUserDocument(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toMap());
    } catch (e) {
      throw Exception('Failed to create user document: $e');
    }
  }

  // Check if user is admin
  Future<bool> isUserAdmin() async {
    final user = await getCurrentUser();
    return user?.isAdmin ?? false;
  }

  // Get user by ID
  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  // Get all users (admin only)
  Future<List<UserModel>> getAllUsers() async {
    try {
      final querySnapshot = await _firestore.collection('users').get();
      return querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all users: $e');
    }
  }

  // Update user admin status (admin only)
  Future<void> updateUserAdminStatus(String uid, bool isAdmin) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isAdmin': isAdmin,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update admin status: $e');
    }
  }

  // Delete user (admin only) - deletes Firestore document and cleans up related data
  Future<void> deleteUser(String uid) async {
    try {
      // Clean up related data first
      await _cleanupUserData(uid);
      
      // Delete the Firestore document
      await _firestore.collection('users').doc(uid).delete();
      
      // Note: Firebase Auth account deletion requires admin privileges
      // This would typically be handled by Firebase Admin SDK on a backend server
      // For now, we'll just delete the Firestore document and mark user as deleted
      
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  // Clean up user-related data (cart, orders, etc.)
  Future<void> _cleanupUserData(String uid) async {
    try {
      // Delete user cart
      final cartQuery = await _firestore
          .collection('user_carts')
          .doc(uid)
          .collection('items')
          .get();
      
      for (var doc in cartQuery.docs) {
        await doc.reference.delete();
      }
      
      // Delete user cart document
      await _firestore.collection('user_carts').doc(uid).delete();
      
      // Update orders to mark user as deleted (don't delete orders for record keeping)
      final ordersQuery = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: uid)
          .get();
      
      for (var doc in ordersQuery.docs) {
        await doc.reference.update({
          'userDeleted': true,
          'userEmail': '[Deleted User]',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Log error but don't throw - cleanup is not critical
      print('Error cleaning up user data: $e');
    }
  }
}

