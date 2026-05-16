// import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum TableStatus { available, occupied, reserved, cleaning }

class RestaurantTable {
  final String id;
  final int tableNo;
  TableStatus status;
  String? currentOrderId;
  int guestCount;
  final DateTime? updatedAt;

  RestaurantTable({
    required this.id,
    required this.tableNo,
    this.status = TableStatus.available,
    this.currentOrderId,
    this.guestCount = 0,
    this.updatedAt,
  });

  Color get statusColor {
    switch (status) {
      case TableStatus.available:
        return Colors.green;
      case TableStatus.occupied:
        return Colors.red;
      case TableStatus.reserved:
        return Colors.orange;
      case TableStatus.cleaning:
        return Colors.grey;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tableNo': tableNo,
      'status': status.toString().split('.').last,
      'currentOrderId': currentOrderId,
      'guestCount': guestCount,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory RestaurantTable.fromFirestore(Map<String, dynamic> data, String id) {
    return RestaurantTable(
      id: id,
      tableNo: data['tableNo'] ?? 0,
      status: TableStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => TableStatus.available,
      ),
      currentOrderId: data['currentOrderId'],
      guestCount: data['guestCount'] ?? 0,
      updatedAt: data['updatedAt']?.toDate(),
    );
  }
}
