import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryItem {
  final String id;
  final String name;
  final int stock;
  final String unit;
  final int minimumStock;
  final String? category;
  final DateTime? lastUpdated;

  InventoryItem({
    required this.id,
    required this.name,
    required this.stock,
    required this.unit,
    required this.minimumStock,
    this.category,
    this.lastUpdated,
  });

  bool get isLowStock => stock <= minimumStock;

  double get stockPercentage => (stock / (minimumStock * 2)).clamp(0.0, 1.0);

  factory InventoryItem.fromFirestore(Map<String, dynamic> data, String id) {
    return InventoryItem(
      id: id,
      name: data['item'] ?? data['name'] ?? '',
      stock: (data['stock'] ?? 0).toInt(),
      unit: data['unit'] ?? 'pcs',
      minimumStock: (data['minimumStock'] ?? 10).toInt(),
      category: data['category'],
      lastUpdated: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'item': name,
      'stock': stock,
      'unit': unit,
      'minimumStock': minimumStock,
      'category': category,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class InventoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<InventoryItem>> getInventoryItems() {
    return _firestore
        .collection('inventory')
        .orderBy('item')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => InventoryItem.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<InventoryItem>> getLowStockItems() {
    return _firestore
        .collection('inventory')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => InventoryItem.fromFirestore(doc.data(), doc.id))
              .where((item) => item.isLowStock)
              .toList(),
        );
  }

  Future<void> addInventoryItem(InventoryItem item) async {
    await _firestore.collection('inventory').add(item.toFirestore());
  }

  Future<void> updateStock(String id, int newStock) async {
    await _firestore.collection('inventory').doc(id).update({
      'stock': newStock,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> increaseStock(String id, int amount) async {
    final doc = await _firestore.collection('inventory').doc(id).get();
    if (doc.exists) {
      final currentStock = (doc.data()?['stock'] ?? 0).toInt();
      await updateStock(id, currentStock + amount);
    }
  }

  Future<void> decreaseStock(String id, int amount) async {
    final doc = await _firestore.collection('inventory').doc(id).get();
    if (doc.exists) {
      final currentStock = (doc.data()?['stock'] ?? 0).toInt();
      final newStock = (currentStock - amount).clamp(0, 999999);
      await updateStock(id, newStock);
    }
  }

  Future<void> deleteInventoryItem(String id) async {
    await _firestore.collection('inventory').doc(id).delete();
  }

  Future<void> updateMinimumStock(String id, int minimumStock) async {
    await _firestore.collection('inventory').doc(id).update({
      'minimumStock': minimumStock,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>> getInventoryStats() async {
    final snapshot = await _firestore.collection('inventory').get();

    int totalItems = snapshot.docs.length;
    int lowStockItems = 0;
    int outOfStockItems = 0;
    int? totalStockValue = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final int stock = (data['stock'] ?? 0).toInt();
      final int minimumStock = (data['minimumStock'] ?? 10).toInt();

      if (stock == 0) {
        outOfStockItems++;
      } else if (stock <= minimumStock) {
        lowStockItems++;
      }

      totalStockValue = totalStockValue! + stock;
    }

    return {
      'totalItems': totalItems,
      'lowStockItems': lowStockItems,
      'outOfStockItems': outOfStockItems,
      'totalStockValue': totalStockValue,
      'healthyStockItems': totalItems - lowStockItems - outOfStockItems,
    };
  }

  Future<void> processOrderInventory(Map<String, int> itemUsage) async {
    final batch = _firestore.batch();

    for (var entry in itemUsage.entries) {
      final docRef = _firestore.collection('inventory').doc(entry.key);
      final doc = await docRef.get();

      if (doc.exists) {
        final currentStock = (doc.data()?['stock'] ?? 0).toInt();
        final newStock = (currentStock - entry.value).clamp(0, 999999);
        batch.update(docRef, {
          'stock': newStock,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
  }
}
