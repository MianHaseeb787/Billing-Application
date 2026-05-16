import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/order.dart';
import '../services/firestore_service.dart';

class OrderProvider extends ChangeNotifier {
  final FirestoreService _svc = FirestoreService();
  List<Order> _activeOrders = [];
  bool _isLoading = false;

  List<Order> get activeOrders => _activeOrders;
  bool get isLoading => _isLoading;

  int get pendingCount => _activeOrders.where((o) => o.status == OrderStatus.pending).length;
  int get preparingCount => _activeOrders.where((o) => o.status == OrderStatus.preparing).length;
  int get readyCount => _activeOrders.where((o) => o.status == OrderStatus.ready).length;

  void initialize() {
    _svc.getActiveOrders().listen((orders) {
      _activeOrders = orders;
      notifyListeners();
    });
  }

  Future<String> createOrder(Order order) async {
    _isLoading = true;
    notifyListeners();
    try {
      final id = await _svc.createOrder(order);
      return id;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _svc.updateOrderStatus(orderId, status);
    final i = _activeOrders.indexWhere((o) => o.id == orderId);
    if (i != -1) {
      _activeOrders[i].status = status;
      notifyListeners();
    }
  }

  /// Marks the order as paid, logs the sale, and optionally applies a discount.
  Future<void> completeOrder(
    String orderId,
    PaymentMethod method, {
    double discount = 0,
  }) async {
    // Fetch the order directly from Firestore — avoids relying on the local
    // in-memory list which may be empty if initialize() was never called.
    final doc = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
    if (!doc.exists) throw Exception('Order $orderId not found');

    final order = Order.fromFirestore(doc.data()!, orderId);

    // Apply discount if provided
    if (discount > 0) {
      order.discount = discount;
      order.calculateTotals();
    }

    await _svc.completeOrder(orderId, method);
    await _svc.logSale(order);

    _activeOrders.removeWhere((o) => o.id == orderId);
    notifyListeners();
  }

  Order? getOrderById(String id) {
    try {
      return _activeOrders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Order> getOrdersByTable(int tableNo) =>
      _activeOrders.where((o) => o.tableNo == tableNo).toList();
}
