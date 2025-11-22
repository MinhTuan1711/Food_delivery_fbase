import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_delivery_fbase/models/food.dart';

class FoodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'foods';

  // Get all foods
  Stream<List<Food>> getFoods() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots() 
        .map((snapshot) {
      try {
        return snapshot.docs.map((doc) {
          return Food.fromMap(doc.data(), doc.id);
        }).toList();
      } catch (e) {
        print('FoodService: Error parsing foods: $e');
        return <Food>[];
      }
    }).handleError((error) {
      print('FoodService: Error in getFoods stream: $error');
    });
  }

  // Get foods by category
  Stream<List<Food>> getFoodsByCategory(FoodCategory category) {
    return _firestore
        .collection(_collection)
        .where('category', isEqualTo: category.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      try {
        return snapshot.docs.map((doc) {
          return Food.fromMap(doc.data(), doc.id);
        }).toList();
      } catch (e) {
        print('FoodService: Error parsing foods by category: $e');
        return <Food>[];
      }
    }).handleError((error) {
      print('FoodService: Error in getFoodsByCategory stream: $error');
    });
  }

  // Add new food
  Future<String> addFood(Food food) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to add food');
      }
      
      final docRef = await _firestore.collection(_collection).add(food.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add food: $e');
    }
  }

  // Update food
  Future<void> updateFood(Food food) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to update food');
      }
      
      if (food.id == null) {
        throw Exception('Food ID is required for update');
      }
      
      final updateData = food.toMap();
      updateData.remove('createdAt'); // Don't update createdAt
      updateData['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore.collection(_collection).doc(food.id!).update(updateData);
    } catch (e) {
      throw Exception('Failed to update food: $e');
    }
  }

  // Delete food
  Future<void> deleteFood(String foodId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to delete food');
      }
      
      await _firestore.collection(_collection).doc(foodId).delete();
    } catch (e) {
      throw Exception('Failed to delete food: $e');
    }
  }

  // Get single food by ID
  Future<Food?> getFoodById(String foodId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(foodId).get();
      if (doc.exists) {
        return Food.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get food: $e');
    }
  }

  // Search foods by name
  Stream<List<Food>> searchFoods(String query) {
    return _firestore
        .collection(_collection)
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: query + 'z')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Food.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Update food quantity (increase or decrease)
  Future<void> updateFoodQuantity(String foodId, int quantityChange) async {
    try {
      print('updateFoodQuantity called: foodId=$foodId, quantityChange=$quantityChange');
      final food = await getFoodById(foodId);
      if (food == null) {
        print('ERROR: Food not found with id: $foodId');
        throw Exception('Food not found');
      }

      print('Current food quantity: ${food.quantity}');
      final newQuantity = (food.quantity + quantityChange).clamp(0, double.infinity).toInt();
      print('New food quantity will be: $newQuantity');
      
      await _firestore.collection(_collection).doc(foodId).update({
        'quantity': newQuantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Successfully updated food $foodId quantity to $newQuantity in Firestore');
    } catch (e, stackTrace) {
      print('ERROR in updateFoodQuantity: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to update food quantity: $e');
    }
  }
}
