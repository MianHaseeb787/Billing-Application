import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus { pending, preparing, ready, served, paid, cancelled }

enum PaymentMethod { cash, card, split, online }

class OrderItem {
  final String menuItemId;
  final String name;
  final double price;
  int quantity;
  final String? specialInstructions;

  OrderItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.specialInstructions,
  });

  double get total => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'price': price,
      'qty': quantity,
      'specialInstructions': specialInstructions,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      menuItemId: map['menuItemId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['qty'] ?? 1,
      specialInstructions: map['specialInstructions'],
    );
  }
}

class Order {
  final String id;
  final int tableNo;
  OrderStatus status;
  List<OrderItem> items;
  double subtotal;
  double tax;
  double serviceCharge;
  double discount;
  double total;
  PaymentMethod? paymentMethod;
  final DateTime? createdAt;
  DateTime? updatedAt;

  Order({
    required this.id,
    required this.tableNo,
    this.status = OrderStatus.pending,
    List<OrderItem>? items,
    this.subtotal = 0,
    this.tax = 0,
    this.serviceCharge = 0,
    this.discount = 0,
    this.total = 0,
    this.paymentMethod,
    this.createdAt,
    this.updatedAt,
  }) : items = items ?? [];

  void calculateTotals() {
    subtotal = items.fold(0, (sum, item) => sum + item.total);
    tax = subtotal * 0.15; // 15% tax
    serviceCharge = subtotal * 0.05; // 5% service charge
    total = subtotal + tax + serviceCharge - discount;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tableNo': tableNo,
      'status': status.toString().split('.').last,
      'items': items.map((e) => e.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'serviceCharge': serviceCharge,
      'discount': discount,
      'total': total,
      'paymentMethod': paymentMethod?.toString().split('.').last,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Order.fromFirestore(Map<String, dynamic> data, String id) {
    return Order(
      id: id,
      tableNo: data['tableNo'] ?? 0,
      status: OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => OrderStatus.pending,
      ),
      items:
          (data['items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      tax: (data['tax'] ?? 0).toDouble(),
      serviceCharge: (data['serviceCharge'] ?? 0).toDouble(),
      discount: (data['discount'] ?? 0).toDouble(),
      total: (data['total'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'] != null
          ? PaymentMethod.values.firstWhere(
              (e) => e.toString().split('.').last == data['paymentMethod'],
            )
          : null,
      createdAt: data['createdAt']?.toDate(),
      updatedAt: data['updatedAt']?.toDate(),
    );
  }
}
