import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final String? imageUrl;
  final bool isAvailable;
  final String? description;
  final int preparationTime;
  final DateTime? createdAt;

  MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.imageUrl,
    this.isAvailable = true,
    this.description,
    this.preparationTime = 10,
    this.createdAt,
  });

  factory MenuItem.fromFirestore(Map<String, dynamic> data, String id) {
    return MenuItem(
      id: id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'],
      isAvailable: data['isAvailable'] ?? true,
      description: data['description'],
      preparationTime: data['preparationTime'] ?? 10,
      createdAt: data['createdAt']?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'description': description,
      'preparationTime': preparationTime,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
