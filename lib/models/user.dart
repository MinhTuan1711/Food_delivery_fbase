import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? phoneNumber;
  final String? address;
  final String? profileImageUrl;
  final bool isAdmin;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Delivery information
  final String? deliveryName;
  final String? deliveryPhone;
  final String? deliveryAddress;
  
  // Location information
  final double? latitude;
  final double? longitude;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.phoneNumber,
    this.address,
    this.profileImageUrl,
    this.isAdmin = false,
    required this.createdAt,
    this.updatedAt,
    this.deliveryName,
    this.deliveryPhone,
    this.deliveryAddress,
    this.latitude,
    this.longitude,
  });

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'address': address,
      'profileImageUrl': profileImageUrl,
      'isAdmin': isAdmin,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'deliveryName': deliveryName,
      'deliveryPhone': deliveryPhone,
      'deliveryAddress': deliveryAddress,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Create UserModel from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      phoneNumber: map['phoneNumber'],
      address: map['address'],
      profileImageUrl: map['profileImageUrl'],
      isAdmin: map['isAdmin'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      deliveryName: map['deliveryName'],
      deliveryPhone: map['deliveryPhone'],
      deliveryAddress: map['deliveryAddress'],
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
    );
  }

  // Create UserModel from Firebase Auth User
  factory UserModel.fromFirebaseUser(dynamic firebaseUser) {
    return UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      phoneNumber: firebaseUser.phoneNumber,
      profileImageUrl: firebaseUser.photoURL,
      isAdmin: false,
      createdAt: DateTime.now(),
    );
  }

  // Copy with method for updating
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? address,
    String? profileImageUrl,
    bool? isAdmin,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? deliveryName,
    String? deliveryPhone,
    String? deliveryAddress,
    double? latitude,
    double? longitude,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deliveryName: deliveryName ?? this.deliveryName,
      deliveryPhone: deliveryPhone ?? this.deliveryPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  // Get display name or email as fallback
  String get displayNameOrEmail {
    return displayName?.isNotEmpty == true ? displayName! : email;
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName, isAdmin: $isAdmin)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}

