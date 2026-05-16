import 'package:flutter/foundation.dart';
import '../models/order.dart';

class CartProvider extends ChangeNotifier {
  List<OrderItem> _items = [];
  double _discount = 0;
  String _specialInstructions = '';
  int _tableNo = 0;

  List<OrderItem> get items => _items;
  double get discount => _discount;
  String get specialInstructions => _specialInstructions;
  int get tableNo => _tableNo;

  int get itemCount => _items.length;

  double get subtotal => _items.fold(0, (sum, item) => sum + item.total);

  double get tax => subtotal * 0.15;

  double get serviceCharge => subtotal * 0.05;

  double get total => subtotal + tax + serviceCharge - _discount;

  void setTableNo(int no) {
    _tableNo = no;
    notifyListeners();
  }

  void addItem(OrderItem item) {
    final index = _items.indexWhere((i) => i.menuItemId == item.menuItemId);
    if (index != -1) {
      _items[index].quantity += 1;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void removeItem(String menuItemId) {
    _items.removeWhere((item) => item.menuItemId == menuItemId);
    notifyListeners();
  }

  void increaseQuantity(String menuItemId) {
    final index = _items.indexWhere((i) => i.menuItemId == menuItemId);
    if (index != -1) {
      _items[index].quantity += 1;
      notifyListeners();
    }
  }

  void decreaseQuantity(String menuItemId) {
    final index = _items.indexWhere((i) => i.menuItemId == menuItemId);
    if (index != -1) {
      if (_items[index].quantity > 1) {
        _items[index].quantity -= 1;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void setDiscount(double value) {
    _discount = value;
    notifyListeners();
  }

  void setSpecialInstructions(String instructions) {
    _specialInstructions = instructions;
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _discount = 0;
    _specialInstructions = '';
    notifyListeners();
  }

  Order createOrder() {
    return Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tableNo: _tableNo,
      status: OrderStatus.pending,
      items: List.from(_items),
      subtotal: subtotal,
      tax: tax,
      serviceCharge: serviceCharge,
      discount: _discount,
      total: total,
    );
  }
}
