import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/table_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<MenuItem>> getMenuItems() {
    return _firestore
        .collection('menuItems')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MenuItem.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> addMenuItem(MenuItem item) {
    return _firestore.collection('menuItems').add(item.toFirestore());
  }

  Future<void> updateMenuItem(String id, Map<String, dynamic> data) {
    return _firestore.collection('menuItems').doc(id).update(data);
  }

  Future<void> deleteMenuItem(String id) {
    return _firestore.collection('menuItems').doc(id).delete();
  }

  Stream<List<RestaurantTable>> getTables() {
    return _firestore
        .collection('tables')
        .orderBy('tableNo')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RestaurantTable.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> updateTableStatus(String id, TableStatus status) {
    return _firestore.collection('tables').doc(id).update({
      'status': status.toString().split('.').last,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Order>> getActiveOrders() {
    
    return _firestore
        .collection('orders')
        .where('status', whereIn: ['pending', 'preparing', 'ready', 'served'])
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => Order.fromFirestore(doc.data(), doc.id))
              .toList();
          orders.sort((a, b) =>
              (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
          return orders;
        });
  }

  Future<String> createOrder(Order order) {
    return _firestore
        .collection('orders')
        .add(order.toFirestore())
        .then((doc) => doc.id);
  }

  Future<void> updateOrderStatus(String id, OrderStatus status) {
    return _firestore.collection('orders').doc(id).update({
      'status': status.toString().split('.').last,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> completeOrder(String id, PaymentMethod method) {
    return _firestore.collection('orders').doc(id).update({
      'status': OrderStatus.paid.toString().split('.').last,
      'paymentMethod': method.toString().split('.').last,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> logSale(Order order) {
    return _firestore.collection('salesLogs').add({
      ...order.toFirestore(),
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getInventory() {
    return _firestore.collection('inventory').snapshots();
  }

  Future<void> updateInventory(String id, int quantity) {
    return _firestore.collection('inventory').doc(id).update({
      'stock': quantity,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
