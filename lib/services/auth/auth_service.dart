import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_delivery_fbase/models/user.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  // get instance of firebase auth
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //get current user
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  //sign in
  Future<UserCredential> signInWithEmailPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  //sign up
  Future<UserCredential> signUpWithEmailPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      
      // Save user data to Firestore
      final userModel = UserModel.fromFirebaseUser(userCredential.user!);
      await _firestore
      .collection('users')
      .doc(userCredential.user!.uid)
      .set(userModel.toMap());
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  //sign out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    // Also sign out from Google if user signed in with Google
    final googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
  }

  //sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        throw Exception('Đăng nhập Google đã bị hủy');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);

      // Check if this is a new user (first time signing in)
      final user = userCredential.user;
      if (user != null) {
        try {
          final userDoc = await _firestore
              .collection('users')
              .doc(user.uid)
              .get()
              .timeout(const Duration(seconds: 10));
          
          // If user doesn't exist in Firestore, create a new user document
          if (!userDoc.exists) {
            final userModel = UserModel.fromFirebaseUser(user);
            await _firestore
                .collection('users')
                .doc(user.uid)
                .set(userModel.toMap())
                .timeout(const Duration(seconds: 10));
          } else {
            // Update existing user with latest Google profile info
            await _firestore
                .collection('users')
                .doc(user.uid)
                .update({
              'displayName': user.displayName,
              'profileImageUrl': user.photoURL,
              'updatedAt': FieldValue.serverTimestamp(),
            }).timeout(const Duration(seconds: 10));
          }
        } catch (firestoreError) {
          // Log Firestore error but don't fail the sign-in
          // The user is already authenticated, Firestore update is secondary
          print('Warning: Failed to update Firestore user data: $firestoreError');
          // Continue anyway - user is signed in successfully
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Lỗi đăng nhập Google');
    } catch (e) {
      // If it's already our custom exception, rethrow it
      if (e.toString().contains('Đăng nhập Google đã bị hủy')) {
        rethrow;
      }
      throw Exception('Lỗi đăng nhập Google: ${e.toString()}');
    }
  }

  //reset password
  Future<void> resetPassword(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  //update username
  Future<void> updateUsername(String username) async {
    await _firebaseAuth.currentUser?.updateDisplayName(username);
  }

  //delete account
  Future<void> deleteAccount({
    required String password,
    required String email,
  }) async {
    AuthCredential credential =
        EmailAuthProvider.credential(email: email, password: password);
    await _firebaseAuth.currentUser?.reauthenticateWithCredential(credential);
    await _firebaseAuth.currentUser?.delete();
    await _firebaseAuth.signOut();
  }

  //check if user is admin
  Future<bool> isAdmin() async {
    final user = getCurrentUser();
    if (user == null) return false;
    
    try {
      final doc = await _firestore
      .collection('users')
      .doc(user.uid)
      .get();
      return doc.exists && doc.data()?['isAdmin'] == true;
    } catch (e) {
      return false;
    }
  }

  //set user as admin (for initial setup)
  Future<void> setUserAsAdmin(String email) async {
    try {
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (userQuery.docs.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(userQuery.docs.first.id)
            .update({'isAdmin': true});
      }
    } catch (e) {
      throw Exception('Failed to set user as admin: $e');
    }
  }

  // Delete user account (admin only) - for future use with Firebase Admin SDK
  Future<void> deleteUserAccount(String uid) async {
    try {
      // This would typically be implemented using Firebase Admin SDK
      // on a backend server for security reasons
      throw Exception('User account deletion requires backend implementation with Firebase Admin SDK');
    } catch (e) {
      throw Exception('Failed to delete user account: $e');
    }
  }

  // Get current user data from Firestore
  Future<UserModel?> getCurrentUserData() async {
    final user = getCurrentUser();
    if (user == null) return null;
    
    try {
      final doc = await _firestore
      .collection('users')
      .doc(user.uid) 
      .get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? phoneNumber,
    String? address,
    String? profileImageUrl,
  }) async {
    final user = getCurrentUser();
    if (user == null) throw Exception('No user logged in');
    
    try {
      Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (displayName != null) {
        updateData['displayName'] = displayName;
        // Also update Firebase Auth display name
        await user.updateDisplayName(displayName);
      }
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (address != null) updateData['address'] = address;
      if (profileImageUrl != null) {
        updateData['profileImageUrl'] = profileImageUrl;
        // Also update Firebase Auth photo URL
        await user.updatePhotoURL(profileImageUrl);
      }
      
      await _firestore.collection('users').doc(user.uid).update(updateData);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Stream of current user data
  Stream<UserModel?> getCurrentUserStream() {
    final user = getCurrentUser();
    if (user == null) return Stream.value(null);
    
    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return UserModel.fromMap(doc.data()!);
          }
          return null;
        });
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    final user = getCurrentUser();
    if (user == null) throw Exception('No user logged in');
    
    try {
      await user.updatePassword(newPassword);
    } catch (e) {
      throw Exception('Failed to update password: $e');
    }
  }

  // Reauthenticate user (required for sensitive operations)
  Future<void> reauthenticateUser(String email, String password) async {
    final user = getCurrentUser();
    if (user == null) throw Exception('No user logged in');
    
    try {
      final credential = EmailAuthProvider.credential(email: email, password: password);
      await user.reauthenticateWithCredential(credential);
    } catch (e) {
      throw Exception('Reauthentication failed: $e');
    }
  }
}
