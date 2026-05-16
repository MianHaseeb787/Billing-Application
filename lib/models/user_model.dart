import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, cashier, manager, kitchen }

class AppUser {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.isActive = true,
    this.createdAt,
    this.lastLogin,
  });

  // Convert UserRole to string for Firestore
  String get roleString => role.toString().split('.').last;

  // Get permissions based on role
  List<String> get permissions {
    switch (role) {
      case UserRole.admin:
        return [
          'manage_menu',
          'manage_tables',
          'view_sales',
          'manage_users',
          'manage_inventory',
          'generate_bills',
          'view_kitchen',
          'all_access',
        ];
      case UserRole.manager:
        return [
          'manage_menu',
          'manage_tables',
          'view_sales',
          'manage_inventory',
          'generate_bills',
          'view_kitchen',
        ];
      case UserRole.cashier:
        return ['manage_tables', 'generate_bills', 'view_sales'];
      case UserRole.kitchen:
        return ['view_kitchen', 'manage_inventory'];
    }
  }

  bool hasPermission(String permission) => permissions.contains(permission);

  factory AppUser.fromFirestore(Map<String, dynamic> data) {
    return AppUser(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == data['role'],
        orElse: () => UserRole.cashier,
      ),
      isActive: data['isActive'] is bool
          ? data['isActive'] as bool
          : data['isActive']?.toString().toLowerCase() == 'true',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': roleString,
      'isActive': isActive,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'lastLogin': lastLogin ?? FieldValue.serverTimestamp(),
    };
  }
}
