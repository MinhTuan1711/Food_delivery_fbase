import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_delivery_fbase/models/food.dart';

class CartItem {
  String? id; // Firestore document ID
  String foodId; // Reference to food document
  Food? food; // Full food object (loaded separately)
  List<Addon> selectedAddons;
  int quantity;
  DateTime addedAt;
  bool isSelected; // Track if item is selected for payment

  CartItem({
    this.id,
    required this.foodId,
    this.food,
    required this.selectedAddons,
    this.quantity = 1,
    DateTime? addedAt,
    this.isSelected = true, // Default to selected
  }) : addedAt = addedAt ?? DateTime.now();

  double get totalPrice {
    if (food == null) return 0.0;
    double addonsPrice =
        selectedAddons.fold(0, (sum, addon) => sum + addon.price);
    return (food!.price + addonsPrice) * quantity;
  }

  // Convert CartItem to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'foodId': foodId,
      'selectedAddons': selectedAddons.map((addon) => addon.toMap()).toList(),
      'quantity': quantity,
      'addedAt': Timestamp.fromDate(addedAt),
      'isSelected': isSelected,
    };
  }

  // Create CartItem from Firestore document
  factory CartItem.fromMap(Map<String, dynamic> map, String documentId) {
    return CartItem(
      id: documentId,
      foodId: map['foodId'] ?? '',
      selectedAddons: (map['selectedAddons'] as List<dynamic>?)
          ?.map((addonMap) => Addon.fromMap(addonMap))
          .toList() ?? [],
      quantity: map['quantity'] ?? 1,
      addedAt: (map['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isSelected: map['isSelected'] ?? true, // Default to selected for backward compatibility
    );
  }

  // Copy with method for updates
  CartItem copyWith({
    String? id,
    String? foodId,
    Food? food,
    List<Addon>? selectedAddons,
    int? quantity,
    DateTime? addedAt,
    bool? isSelected,
  }) {
    return CartItem(
      id: id ?? this.id,
      foodId: foodId ?? this.foodId,
      food: food ?? this.food,
      selectedAddons: selectedAddons ?? this.selectedAddons,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
