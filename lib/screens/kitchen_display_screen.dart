import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/order.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';

class KitchenDisplayScreen extends StatefulWidget {
  const KitchenDisplayScreen({super.key});

  @override
  State<KitchenDisplayScreen> createState() =>
      _KitchenDisplayScreenState();
}

class _KitchenDisplayScreenState
    extends State<KitchenDisplayScreen> {
  final FirestoreService _svc = FirestoreService();
  late Timer _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 10),
              decoration: const BoxDecoration(
                  color: AppConstants.green,
                  shape: BoxShape.circle),
            ),
            Text('MUTFAK EKRANI',
                style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 2)),
          ],
        ),
        actions: [
          _legend(AppConstants.yellow, 'BEKLEMEDE'),
          const SizedBox(width: 16),
          _legend(AppConstants.blue, 'HAZIRLANIYOR'),
          const SizedBox(width: 16),
          _legend(AppConstants.green, 'HAZIR'),
          const SizedBox(width: 16),
        ],
      ),
      body: StreamBuilder<List<Order>>(
        stream: _svc.getActiveOrders(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: AppConstants.amber));
          }

          final orders = (snap.data ?? [])
              .where((o) =>
                  o.status == OrderStatus.pending ||
                  o.status == OrderStatus.preparing ||
                  o.status == OrderStatus.ready)
              .toList()
            ..sort((a, b) {
              const p = {
                OrderStatus.pending: 0,
                OrderStatus.preparing: 1,
                OrderStatus.ready: 2,
              };
              final cmp =
                  (p[a.status] ?? 3).compareTo(p[b.status] ?? 3);
              if (cmp != 0) return cmp;
              return (a.createdAt ?? _now)
                  .compareTo(b.createdAt ?? _now);
            });

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 72, color: AppConstants.green),
                  const SizedBox(height: 16),
                  Text('Tüm Siparişler Tamam',
                      style: GoogleFonts.montserrat(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: AppConstants.text1)),
                  const SizedBox(height: 6),
                  Text('Kuyrukta aktif sipariş yok',
                      style: GoogleFonts.montserrat(
                          fontSize: 15, color: AppConstants.text2)),
                ],
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
              childAspectRatio: 0.82,
            ),
            itemCount: orders.length,
            itemBuilder: (ctx, i) => _KdsCard(
                order: orders[i], now: _now, svc: _svc),
          );
        },
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.montserrat(
                fontSize: 10, color: Colors.white70)),
      ],
    );
  }
}

class _KdsCard extends StatelessWidget {
  final Order order;
  final DateTime now;
  final FirestoreService svc;
  const _KdsCard(
      {required this.order, required this.now, required this.svc});

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusLabel) = _statusInfo(order.status);
    final elapsed = order.createdAt != null
        ? now.difference(order.createdAt!)
        : Duration.zero;
    final isUrgent = elapsed.inMinutes >= 15 &&
        order.status == OrderStatus.pending;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: isUrgent
            ? Border.all(color: AppConstants.red, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppConstants.purple.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MASA ${order.tableNo}',
                          style: GoogleFonts.montserrat(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppConstants.text1,
                              letterSpacing: 0.5)),
                      Text(
                          '#${order.id.substring(0, 6).toUpperCase()}',
                          style: GoogleFonts.montserrat(
                              fontSize: 10,
                              color: AppConstants.text3)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color:
                                statusColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(statusLabel,
                          style: GoogleFonts.montserrat(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                              letterSpacing: 0.5)),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.timer_outlined,
                            size: 10,
                            color: isUrgent
                                ? AppConstants.red
                                : AppConstants.text3),
                        const SizedBox(width: 2),
                        Text(_elapsedLabel(elapsed),
                            style: GoogleFonts.montserrat(
                                fontSize: 10,
                                color: isUrgent
                                    ? AppConstants.red
                                    : AppConstants.text3,
                                fontWeight: isUrgent
                                    ? FontWeight.w700
                                    : FontWeight.normal)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              itemCount: order.items.length,
              itemBuilder: (_, i) {
                final item = order.items[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color:
                              Colors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.center,
                        child: Text('×${item.quantity}',
                            style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppConstants.text1)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(item.name,
                            style: GoogleFonts.montserrat(
                                fontSize: 13,
                                color: AppConstants.text2)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: _actionButton(order),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(Order order) {
    switch (order.status) {
      case OrderStatus.pending:
        return ElevatedButton(
          onPressed: () => svc.updateOrderStatus(
              order.id, OrderStatus.preparing),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6)),
          ),
          child: Text('HAZIRLAMAYA BAŞLA',
              style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
        );
      case OrderStatus.preparing:
        return ElevatedButton(
          onPressed: () =>
              svc.updateOrderStatus(order.id, OrderStatus.ready),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.green,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 10),
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6)),
          ),
          child: Text('HAZIR OLARAK İŞARETLE',
              style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
        );
      case OrderStatus.ready:
        return ElevatedButton(
          onPressed: () =>
              svc.updateOrderStatus(order.id, OrderStatus.served),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.purple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6)),
          ),
          child: Text('SERVİS EDİLDİ ✓',
              style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  (Color, String) _statusInfo(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return (AppConstants.yellow, 'BEKLEMEDE');
      case OrderStatus.preparing:
        return (AppConstants.blue, 'HAZIRLANIYOR');
      case OrderStatus.ready:
        return (AppConstants.green, 'HAZIR');
      default:
        return (AppConstants.text3, s.name.toUpperCase());
    }
  }

  String _elapsedLabel(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}s ${d.inMinutes.remainder(60)}d';
    }
    if (d.inMinutes > 0) return '${d.inMinutes}d önce';
    return 'şimdi';
  }
}
