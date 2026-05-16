import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
import '../utils/constants.dart';
import '../utils/receipt_printer.dart';

class GenerateBillScreen extends StatefulWidget {
  const GenerateBillScreen({super.key});

  @override
  State<GenerateBillScreen> createState() =>
      _GenerateBillScreenState();
}

class _GenerateBillScreenState extends State<GenerateBillScreen> {
  Order? _selected;
  PaymentMethod _payment = PaymentMethod.cash;
  double _discount = 0;
  final _discountCtrl = TextEditingController();
  final _cashCtrl = TextEditingController();
  bool _processing = false;

  @override
  void dispose() {
    _discountCtrl.dispose();
    _cashCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.bg,
      appBar: AppBar(title: const Text('Hesap Kes')),
      body: Row(
        children: [
          SizedBox(
              width: 300,
              child: _OrderList(
                selected: _selected,
                onSelect: (order) => setState(() {
                  _selected = order;
                  _discount = order.discount;
                  _discountCtrl.text = order.discount > 0
                      ? order.discount.toStringAsFixed(2)
                      : '';
                  _cashCtrl.clear();
                }),
              )),
          Expanded(child: _buildBillPanel()),
        ],
      ),
    );
  }

  Widget _buildBillPanel() {
    if (_selected == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.touch_app_outlined,
                size: 52, color: AppConstants.text3),
            const SizedBox(height: 14),
            Text('Hesap kesmek için sipariş seçin',
                style: GoogleFonts.montserrat(
                    fontSize: 15, color: AppConstants.text2)),
            const SizedBox(height: 4),
            Text(
                'Mutfak hazır olarak işaretlediğinde siparişler görünür',
                style: GoogleFonts.montserrat(
                    fontSize: 12, color: AppConstants.text3)),
          ],
        ),
      );
    }

    final order = _selected!;
    final effectiveDiscount =
        _discount.clamp(0, order.subtotal).toDouble();
    final effectiveTotal = order.subtotal +
        order.tax +
        order.serviceCharge -
        effectiveDiscount;
    final cashPaid = double.tryParse(_cashCtrl.text) ?? 0;
    final changeDue =
        _payment == PaymentMethod.cash && cashPaid > 0
            ? cashPaid - effectiveTotal
            : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppConstants.cardRadius),
              boxShadow: [
                BoxShadow(
                  color: AppConstants.purple.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Text('DinO Dine',
                          style: GoogleFonts.montserrat(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppConstants.text1,
                              letterSpacing: -0.5)),
                      const SizedBox(height: 2),
                      Text('Restoran POS',
                          style: GoogleFonts.montserrat(
                              fontSize: 11,
                              color: AppConstants.text3,
                              letterSpacing: 2)),
                      const SizedBox(height: 14),
                      const Divider(color: AppConstants.border),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Masa ${order.tableNo}',
                              style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppConstants.text1)),
                          Text(
                              'Sipariş #${order.id.substring(0, 6).toUpperCase()}',
                              style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppConstants.text1)),
                        ],
                      ),
                      if (order.createdAt != null) ...[
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(_fmtDt(order.createdAt!),
                              style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  color: AppConstants.text3)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: AppConstants.border),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                        child: Text('Ürün',
                            style: GoogleFonts.montserrat(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppConstants.text3))),
                    SizedBox(
                        width: 40,
                        child: Text('Adet',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppConstants.text3))),
                    SizedBox(
                        width: 90,
                        child: Text('Tutar',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.montserrat(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppConstants.text3))),
                  ],
                ),
                const Divider(
                    height: 12, color: AppConstants.border),
                ...order.items.map((item) => Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Expanded(
                              child: Text(item.name,
                                  style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      color: AppConstants.text1))),
                          SizedBox(
                              width: 40,
                              child: Text('×${item.quantity}',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      color: AppConstants.text2))),
                          SizedBox(
                              width: 90,
                              child: Text(
                                  'TL ${item.total.toStringAsFixed(2)}',
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      color: AppConstants.text1))),
                        ],
                      ),
                    )),
                const SizedBox(height: 8),
                const Divider(color: AppConstants.border),
                const SizedBox(height: 6),
                _billRow('Ara Toplam', order.subtotal),
                _billRow('KDV (%15)', order.tax),
                _billRow('Servis Ücreti (%5)',
                    order.serviceCharge),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text('İndirim (TL)',
                              style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color: AppConstants.text2))),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _discountCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          textAlign: TextAlign.right,
                          style: GoogleFonts.montserrat(
                              fontSize: 13,
                              color: AppConstants.red),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                            hintText: '0.00',
                            hintStyle: GoogleFonts.montserrat(
                                fontSize: 13,
                                color: AppConstants.text3),
                          ),
                          onChanged: (v) => setState(() =>
                              _discount =
                                  double.tryParse(v) ?? 0),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppConstants.border),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TOPLAM',
                        style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppConstants.text1)),
                    Text(
                        'TL ${effectiveTotal.toStringAsFixed(2)}',
                        style: GoogleFonts.montserrat(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppConstants.amber)),
                  ],
                ),
                const SizedBox(height: 22),
                Text('Ödeme Yöntemi',
                    style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.text1)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: PaymentMethod.values.map((m) {
                    final sel = _payment == m;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _payment = m),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppConstants.amber.withValues(alpha: 0.10)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: sel
                                ? AppConstants.amber
                                : AppConstants.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_paymentIcon(m),
                                size: 15,
                                color: sel
                                    ? AppConstants.amber
                                    : AppConstants.text2),
                            const SizedBox(width: 6),
                            Text(_paymentLabel(m),
                                style: GoogleFonts.montserrat(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: sel
                                        ? AppConstants.amber
                                        : AppConstants.text2)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (_payment == PaymentMethod.cash) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                          child: Text('Verilen Nakit (TL)',
                              style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color: AppConstants.text2))),
                      SizedBox(
                        width: 110,
                        child: TextField(
                          controller: _cashCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          textAlign: TextAlign.right,
                          style: GoogleFonts.montserrat(
                              fontSize: 13,
                              color: AppConstants.text1),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                            hintText: '0.00',
                            hintStyle: GoogleFonts.montserrat(
                                fontSize: 13,
                                color: AppConstants.text3),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  if (changeDue != null && changeDue >= 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Para Üstü',
                            style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppConstants.green)),
                        Text(
                            'TL ${changeDue.toStringAsFixed(2)}',
                            style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppConstants.green)),
                      ],
                    ),
                  ] else if (changeDue != null &&
                      changeDue < 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Yetersiz nakit — TL ${(-changeDue).toStringAsFixed(2)} daha gerekli',
                      style: GoogleFonts.montserrat(
                          fontSize: 12, color: AppConstants.red),
                    ),
                  ],
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _processing
                            ? null
                            : () => ReceiptPrinter.printReceipt(
                                order),
                        icon: const Icon(Icons.print_outlined,
                            size: 16),
                        label: Text('Önizle',
                            style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: (_processing ||
                                (_payment ==
                                        PaymentMethod.cash &&
                                    cashPaid > 0 &&
                                    cashPaid < effectiveTotal))
                            ? null
                            : () => _processPayment(
                                context,
                                order,
                                effectiveDiscount),
                        icon: _processing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black),
                              )
                            : const Icon(
                                Icons.check_circle_outline,
                                size: 16),
                        label: Text('Ödemeyi İşle',
                            style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.green,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _billRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.montserrat(
                  fontSize: 12, color: AppConstants.text2)),
          Text('TL ${amount.toStringAsFixed(2)}',
              style: GoogleFonts.montserrat(
                  fontSize: 12, color: AppConstants.text2)),
        ],
      ),
    );
  }

  Future<void> _processPayment(BuildContext context, Order order,
      double discount) async {
    setState(() => _processing = true);
    final messenger = ScaffoldMessenger.of(context);
    final orderProvider = context.read<OrderProvider>();

    try {
      await orderProvider.completeOrder(order.id, _payment,
          discount: discount);

      final tableQ = await FirebaseFirestore.instance
          .collection('tables')
          .where('currentOrderId', isEqualTo: order.id)
          .limit(1)
          .get();
      if (tableQ.docs.isNotEmpty) {
        await tableQ.docs.first.reference.update({
          'status': 'cleaning',
          'currentOrderId': '',
          'guestCount': 0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await ReceiptPrinter.printReceipt(order);

      if (mounted) {
        setState(() {
          _selected = null;
          _discount = 0;
          _discountCtrl.clear();
          _cashCtrl.clear();
        });
        messenger.showSnackBar(const SnackBar(
            content: Text('Ödeme başarıyla işlendi')));
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppConstants.red),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  String _paymentLabel(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cash:
        return 'Nakit';
      case PaymentMethod.card:
        return 'Kart';
      case PaymentMethod.split:
        return 'Bölüşümlü';
      case PaymentMethod.online:
        return 'Online';
    }
  }

  IconData _paymentIcon(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cash:
        return Icons.payments_outlined;
      case PaymentMethod.card:
        return Icons.credit_card_outlined;
      case PaymentMethod.split:
        return Icons.call_split_outlined;
      case PaymentMethod.online:
        return Icons.phone_android_outlined;
    }
  }

  String _fmtDt(DateTime dt) {
    const mo = [
      'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${mo[dt.month - 1]} ${dt.day}, ${dt.year}  $h:$m';
  }
}

String _orderStatusTr(OrderStatus s) {
  switch (s) {
    case OrderStatus.ready:
      return 'HAZIR';
    case OrderStatus.served:
      return 'SERVİS';
    default:
      return s.name.toUpperCase();
  }
}

class _OrderList extends StatelessWidget {
  final Order? selected;
  final ValueChanged<Order> onSelect;
  const _OrderList(
      {required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppConstants.border)),
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
                const Icon(Icons.receipt_long_outlined,
                    size: 16, color: AppConstants.text2),
                const SizedBox(width: 8),
                Text('Hesap Kesilecek',
                    style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.text1)),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('status',
                      whereIn: ['ready', 'served']).snapshots(),
              builder: (_, snap) {
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Hata: ${snap.error}',
                        style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: AppConstants.red)),
                  );
                }
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppConstants.amber));
                }

                final orders = snap.data!.docs
                    .map((d) => Order.fromFirestore(
                        d.data() as Map<String, dynamic>, d.id))
                    .toList()
                  ..sort((a, b) {
                    if (a.status != b.status) {
                      return a.status == OrderStatus.ready
                          ? -1
                          : 1;
                    }
                    return (a.createdAt ?? DateTime(0))
                        .compareTo(b.createdAt ?? DateTime(0));
                  });

                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long_outlined,
                            size: 40,
                            color: AppConstants.text3),
                        const SizedBox(height: 12),
                        Text('Hesap kesilecek sipariş yok',
                            style: GoogleFonts.montserrat(
                                fontSize: 13,
                                color: AppConstants.text2)),
                        const SizedBox(height: 4),
                        Text(
                          'Mutfak yemeği hazırladığında\nsiparişi hazır olarak işaretler',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                              fontSize: 11,
                              color: AppConstants.text3),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const Divider(
                      height: 1, color: AppConstants.border),
                  itemBuilder: (ctx, i) => _OrderTile(
                      order: orders[i],
                      selected: selected,
                      onSelect: onSelect),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final Order order;
  final Order? selected;
  final ValueChanged<Order> onSelect;
  const _OrderTile(
      {required this.order,
      required this.selected,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isSel = selected?.id == order.id;
    final statusColor = order.status == OrderStatus.ready
        ? AppConstants.green
        : AppConstants.yellow;

    return InkWell(
      onTap: () => onSelect(order),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        color: isSel
            ? AppConstants.amber.withValues(alpha: 0.07)
            : Colors.transparent,
        child: Row(
          children: [
            Container(
              width: 3,
              height: 44,
              decoration: BoxDecoration(
                color: isSel
                    ? AppConstants.amber
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Masa ${order.tableNo}',
                          style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSel
                                  ? AppConstants.amber
                                  : AppConstants.text1)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor
                              .withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(4),
                        ),
                        child: Text(
                          _orderStatusTr(order.status),
                          style: GoogleFonts.montserrat(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: statusColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${order.items.length} ürün  ·  TL ${order.total.toStringAsFixed(2)}',
                    style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: AppConstants.text2),
                  ),
                  if (order.createdAt != null)
                    Text(
                      _fmtTime(order.createdAt!),
                      style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: AppConstants.text3),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
