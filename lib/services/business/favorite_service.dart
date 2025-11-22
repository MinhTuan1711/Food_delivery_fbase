import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_delivery_fbase/models/food.dart';
import 'package:food_delivery_fbase/services/business/food_service.dart';

class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FoodService _foodService = FoodService();

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Get favorites collection reference for current user
  CollectionReference get _favoritesCollection {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return _firestore
        .collection('user_favorites')
        .doc(userId)
        .collection('favorites');
  }

  // Add food to favorites
  Future<void> addToFavorites(String foodId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check if already in favorites
      final existingDoc = await _favoritesCollection.doc(foodId).get();
      if (existingDoc.exists) {
        // Already in favorites, no need to add again
        return;
      }

      // Add to favorites with timestamp
      await _favoritesCollection.doc(foodId).set({
        'foodId': foodId,
        'addedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add to favorites: $e');
    }
  }

  // Remove food from favorites
  Future<void> removeFromFavorites(String foodId) async {
    try {
      await _favoritesCollection.doc(foodId).delete();
    } catch (e) {
      throw Exception('Failed to remove from favorites: $e');
    }
  }

  // Toggle favorite status
  Future<void> toggleFavorite(String foodId) async {
    try {
      final favoriteStatus = await isFavorite(foodId);
      if (favoriteStatus) {
        await removeFromFavorites(foodId);
      } else {
        await addToFavorites(foodId);
      }
    } catch (e) {
      throw Exception('Failed to toggle favorite: $e');
    }
  }

  // Check if food is in favorites
  Future<bool> isFavorite(String foodId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) return false;

      final doc = await _favoritesCollection.doc(foodId).get();
      return doc.exists;
    } catch (e) {
      print('Error checking favorite: $e');
      return false;
    }
  }

  // Get favorite status stream for real-time updates
  Stream<bool> isFavoriteStream(String foodId) {
    try {
      final userId = _currentUserId;
      if (userId == null) return Stream.value(false);

      return _favoritesCollection
          .doc(foodId)
          .snapshots()
          .map((doc) => doc.exists);
    } catch (e) {
      return Stream.value(false);
    }
  }

  // Get all favorite food IDs
  Future<List<String>> getFavoriteFoodIds() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _favoritesCollection
          .orderBy('addedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .map((data) => data['foodId'] as String)
          .toList();
    } catch (e) {
      throw Exception('Failed to get favorite food IDs: $e');
    }
  }

  // Get all favorite foods with details
  Future<List<Food>> getFavoriteFoods() async {
    try {
      final favoriteIds = await getFavoriteFoodIds();
      final foods = <Food>[];

      for (final foodId in favoriteIds) {
        try {
          final food = await _foodService.getFoodById(foodId);
          if (food != null) {
            foods.add(food);
          }
        } catch (e) {
          print('Failed to load food $foodId: $e');
          // Continue loading other foods
        }
      }

      return foods;
    } catch (e) {
      throw Exception('Failed to get favorite foods: $e');
    }
  }

  // Get favorite foods stream for real-time updates
  Stream<List<Food>> getFavoriteFoodsStream() {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      return _favoritesCollection
          .orderBy('addedAt', descending: true)
          .snapshots()
          .asyncMap((snapshot) async {
        final foods = <Food>[];

        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final foodId = data['foodId'] as String;

          try {
            final food = await _foodService.getFoodById(foodId);
            if (food != null) {
              foods.add(food);
            }
          } catch (e) {
            print('Failed to load food $foodId: $e');
            // Continue loading other foods
          }
        }

        return foods;
      });
    } catch (e) {
      throw Exception('Failed to get favorite foods stream: $e');
    }
  }

  // Get favorites count
  Future<int> getFavoritesCount() async {
    try {
      final userId = _currentUserId;
      if (userId == null) return 0;

      final querySnapshot = await _favoritesCollection.get();
      return querySnapshot.docs.length;
    } catch (e) {
      print('Error getting favorites count: $e');
      return 0;
    }
  }

  // Get favorites count stream
  Stream<int> getFavoritesCountStream() {
    try {
      final userId = _currentUserId;
      if (userId == null) return Stream.value(0);

      return _favoritesCollection.snapshots().map((snapshot) => snapshot.docs.length);
    } catch (e) {
      return Stream.value(0);
    }
  }

  // Clear all favorites
  Future<void> clearAllFavorites() async {
    try {
      final batch = _firestore.batch();
      final querySnapshot = await _favoritesCollection.get();

      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to clear favorites: $e');
    }
  }
}

