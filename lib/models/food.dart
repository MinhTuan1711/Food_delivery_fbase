import 'package:cloud_firestore/cloud_firestore.dart';

class Food {
  final String? id; // Firestore document ID
  final String name;
  final String description;
  final String imagePath;
  final double price;
  final FoodCategory category;
  List<Addon> availableAddons;
  final int quantity; // Số lượng sản phẩm còn lại

  Food({
    this.id,
    required this.name,
    required this.description,
    required this.imagePath,
    required this.price,
    required this.category,
    required this.availableAddons,
    this.quantity = 0, // Mặc định là 0
  });

  // Convert Food to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imagePath': imagePath,
      'price': price,
      'category': category.name,
      'availableAddons': availableAddons.map((addon) => addon.toMap()).toList(),
      'quantity': quantity,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Create Food from Firestore document
  factory Food.fromMap(Map<String, dynamic> map, String documentId) {
    return Food(
      id: documentId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      imagePath: map['imagePath'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      category: FoodCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => FoodCategory.bac,
      ),
      availableAddons: (map['availableAddons'] as List<dynamic>?)
          ?.map((addonMap) => Addon.fromMap(addonMap))
          .toList() ?? [],
      quantity: map['quantity'] ?? 0,
    );
  }

  // Copy with method for updates
  Food copyWith({
    String? id,
    String? name,
    String? description,
    String? imagePath,
    double? price,
    FoodCategory? category,
    List<Addon>? availableAddons,
    int? quantity,
  }) {
    return Food(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      price: price ?? this.price,
      category: category ?? this.category,
      availableAddons: availableAddons ?? this.availableAddons,
      quantity: quantity ?? this.quantity,
    );
  }

  // Kiểm tra xem sản phẩm còn hàng không
  bool get isInStock => quantity > 0;

}

enum FoodCategory {
  bac,    // Miền Bắc
  trung,  // Miền Trung
  nam,    // Miền Nam
}

class Addon {
  String name;
  double price;

  Addon({
    required this.name,
    required this.price,
  });

  // Convert Addon to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
    };
  }

  // Create Addon from Map
  factory Addon.fromMap(Map<String, dynamic> map) {
    return Addon(
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
    );
  }

}
