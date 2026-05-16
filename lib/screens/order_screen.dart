import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/table_model.dart';
import '../models/menu_item.dart' as menu_model;
import '../models/order.dart';
import '../providers/cart_provider.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';

class OrderScreen extends StatelessWidget {
  final RestaurantTable table;
  const OrderScreen({super.key, required this.table});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CartProvider()..setTableNo(table.tableNo),
      child: _OrderBody(table: table),
    );
  }
}

class _OrderBody extends StatefulWidget {
  final RestaurantTable table;
  const _OrderBody({required this.table});

  @override
  State<_OrderBody> createState() => _OrderBodyState();
}

class _OrderBodyState extends State<_OrderBody> {
  String _category = 'All';
  final FirestoreService _svc = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppConstants.bg,
      appBar: AppBar(
        title: Text(
          'Masa ${widget.table.tableNo}  —  Yeni Sipariş',
          style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppConstants.text1),
        ),
        actions: [
          if (cart.items.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.symmetric(
                  vertical: 14, horizontal: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:
                    AppConstants.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: AppConstants.amber
                        .withValues(alpha: 0.4)),
              ),
              child: Text(
                '${cart.itemCount} ürün',
                style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.amber),
              ),
            ),
          ],
        ],
      ),
      body: Row(
        children: [
          SizedBox(
            width: 120,
            child: _CategorySidebar(
              selected: _category,
              onSelect: (c) => setState(() => _category = c),
              svc: _svc,
            ),
          ),
          Expanded(
            flex: 3,
            child: _MenuGrid(category: _category, svc: _svc),
          ),
          SizedBox(
            width: 290,
            child: _Cart(
                cart: cart, table: widget.table, svc: _svc),
          ),
        ],
      ),
    );
  }
}

class _CategorySidebar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  final FirestoreService svc;
  const _CategorySidebar(
      {required this.selected,
      required this.onSelect,
      required this.svc});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppConstants.border)),
      ),
      child: StreamBuilder<List<menu_model.MenuItem>>(
        stream: svc.getMenuItems(),
        builder: (_, snap) {
          final categories = <String>[
            'All',
            ...{for (final i in snap.data ?? []) i.category}
          ];

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: categories.length,
            itemBuilder: (ctx, i) {
              final cat = categories[i];
              final active = selected == cat;
              return _CategoryTile(
                category: cat,
                active: active,
                onTap: () => onSelect(cat),
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String category;
  final bool active;
  final VoidCallback onTap;
  const _CategoryTile(
      {required this.category,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final displayName = category == 'All' ? 'Tümü' : category;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? AppConstants.amber.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? AppConstants.amber.withValues(alpha: 0.4)
                : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: active
                    ? AppConstants.amber.withValues(alpha: 0.15)
                    : AppConstants.surface2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.restaurant_outlined,
                size: 22,
                color: active
                    ? AppConstants.amber
                    : AppConstants.text3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              displayName,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight:
                    active ? FontWeight.w600 : FontWeight.normal,
                color: active
                    ? AppConstants.amber
                    : AppConstants.text2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuGrid extends StatelessWidget {
  final String category;
  final FirestoreService svc;
  const _MenuGrid({required this.category, required this.svc});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<menu_model.MenuItem>>(
      stream: svc.getMenuItems(),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(
                  color: AppConstants.amber));
        }

        var items =
            snap.data!.where((i) => i.isAvailable).toList();
        if (category != 'All') {
          items = items
              .where((i) => i.category == category)
              .toList();
        }

        if (items.isEmpty) {
          return Center(
            child: Text(
              category == 'All'
                  ? 'Menüde ürün yok'
                  : '$category kategorisinde ürün yok',
              style: GoogleFonts.montserrat(
                  fontSize: 14, color: AppConstants.text2),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(14),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: items.length,
          itemBuilder: (ctx, i) =>
              _MenuCard(item: items[i]),
        );
      },
    );
  }
}

class _MenuCard extends StatelessWidget {
  final menu_model.MenuItem item;
  const _MenuCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.read<CartProvider>().addItem(
              OrderItem(
                menuItemId: item.id,
                name: item.name,
                price: item.price,
              ),
            );
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
            content: Text('${item.name} eklendi',
                style: GoogleFonts.montserrat(fontSize: 13)),
            duration: const Duration(milliseconds: 700),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(
                bottom: 80, left: 300, right: 16),
          ));
      },
      borderRadius:
          BorderRadius.circular(AppConstants.cardRadius),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          boxShadow: [
            BoxShadow(
              color: AppConstants.purple.withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppConstants.surface2,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(item.category,
                  style: GoogleFonts.montserrat(
                      fontSize: 9,
                      color: AppConstants.text3,
                      fontWeight: FontWeight.w500)),
            ),
            Expanded(
              child: Center(
                child: Text(
                  item.name,
                  style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.text1),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TL ${item.price.toStringAsFixed(2)}',
                  style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.amber),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppConstants.amber,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.add,
                      size: 16, color: Colors.black),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Cart extends StatelessWidget {
  final CartProvider cart;
  final RestaurantTable table;
  final FirestoreService svc;
  const _Cart(
      {required this.cart,
      required this.table,
      required this.svc});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: AppConstants.border)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(
                  bottom:
                      BorderSide(color: AppConstants.border)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart_outlined,
                    size: 16, color: AppConstants.text2),
                const SizedBox(width: 8),
                Text('Mevcut Sipariş',
                    style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.text1)),
                const Spacer(),
                if (cart.items.isNotEmpty)
                  GestureDetector(
                    onTap: cart.clearCart,
                    child: Text('Temizle',
                        style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: AppConstants.text3)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: cart.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        const Icon(
                            Icons.shopping_cart_outlined,
                            size: 40,
                            color: AppConstants.text3),
                        const SizedBox(height: 8),
                        Text('Henüz ürün yok',
                            style: GoogleFonts.montserrat(
                                fontSize: 13,
                                color: AppConstants.text3)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(vertical: 6),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const Divider(
                        height: 1, color: AppConstants.border),
                    itemBuilder: (ctx, i) {
                      final item = cart.items[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(item.name,
                                      style: GoogleFonts.montserrat(
                                          fontSize: 13,
                                          fontWeight:
                                              FontWeight.w600,
                                          color: AppConstants
                                              .text1)),
                                  Text(
                                      'TL ${item.price.toStringAsFixed(2)} / adet',
                                      style: GoogleFonts.montserrat(
                                          fontSize: 11,
                                          color: AppConstants
                                              .text3)),
                                ],
                              ),
                            ),
                            _QtyControl(
                              qty: item.quantity,
                              onDec: () =>
                                  cart.decreaseQuantity(
                                      item.menuItemId),
                              onInc: () =>
                                  cart.increaseQuantity(
                                      item.menuItemId),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 64,
                              child: Text(
                                'TL ${item.total.toStringAsFixed(2)}',
                                textAlign: TextAlign.right,
                                style: GoogleFonts.montserrat(
                                    fontSize: 13,
                                    fontWeight:
                                        FontWeight.w600,
                                    color: AppConstants.text1),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (cart.items.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                  border: Border(
                      top: BorderSide(
                          color: AppConstants.border))),
              child: Column(
                children: [
                  _row('Ara Toplam', cart.subtotal),
                  const SizedBox(height: 4),
                  _row('KDV (%15)', cart.tax),
                  const SizedBox(height: 4),
                  _row('Servis (%5)', cart.serviceCharge),
                  const Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 10),
                    child: Divider(
                        height: 1,
                        color: AppConstants.border),
                  ),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TOPLAM',
                          style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppConstants.text1)),
                      Text(
                          'TL ${cart.total.toStringAsFixed(2)}',
                          style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppConstants.amber)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _placeOrder(context, cart),
                      icon: const Icon(Icons.send_outlined,
                          size: 16),
                      label: Text('MUTFAĞA GÖNDER',
                          style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              letterSpacing: 0.5)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.montserrat(
                fontSize: 12, color: AppConstants.text2)),
        Text('TL ${amount.toStringAsFixed(2)}',
            style: GoogleFonts.montserrat(
                fontSize: 12, color: AppConstants.text2)),
      ],
    );
  }

  Future<void> _placeOrder(
      BuildContext context, CartProvider cart) async {
    try {
      final order = cart.createOrder();
      final orderId = await svc.createOrder(order);

      await FirebaseFirestore.instance
          .collection('tables')
          .doc(table.id)
          .update({
        'status': 'occupied',
        'currentOrderId': orderId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      cart.clearCart();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Sipariş mutfağa gönderildi')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppConstants.red));
      }
    }
  }
}

class _QtyControl extends StatelessWidget {
  final int qty;
  final VoidCallback onDec;
  final VoidCallback onInc;
  const _QtyControl(
      {required this.qty,
      required this.onDec,
      required this.onInc});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _btn(Icons.remove, onDec),
        SizedBox(
          width: 26,
          child: Text('$qty',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.text1)),
        ),
        _btn(Icons.add, onInc),
      ],
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: AppConstants.surface2,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppConstants.border),
        ),
        child:
            Icon(icon, size: 12, color: AppConstants.text2),
      ),
    );
  }
}
