import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
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
  final _cashCtrl     = TextEditingController();
  bool _processing    = false;

  @override
  void dispose() {
    _discountCtrl.dispose();
    _cashCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDE0FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hesap Kes',
              style: GoogleFonts.montserrat(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            Text(
              'Sipariş seçin ve ödemeyi işleyin',
              style: GoogleFonts.montserrat(
                fontSize: 11,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
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
            ),
          ),
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
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.receipt_long_outlined,
                  size: 34, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 16),
            Text('Sipariş Seçin',
                style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827))),
            const SizedBox(height: 6),
            Text('Hesap kesmek için sol panelden sipariş seçin',
                style: GoogleFonts.montserrat(
                    fontSize: 13, color: const Color(0xFF6B7280))),
            const SizedBox(height: 4),
            Text('Mutfak hazır olarak işaretlediğinde görünür',
                style: GoogleFonts.montserrat(
                    fontSize: 12, color: const Color(0xFF9CA3AF))),
          ],
        ),
      );
    }

    final order            = _selected!;
    final effectiveDiscount =
        _discount.clamp(0, order.subtotal).toDouble();
    final effectiveTotal   = order.subtotal +
        order.tax +
        order.serviceCharge -
        effectiveDiscount;
    final cashPaid         = double.tryParse(_cashCtrl.text) ?? 0;
    final changeDue        =
        _payment == PaymentMethod.cash && cashPaid > 0
            ? cashPaid - effectiveTotal
            : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            children: [
              _ReceiptCard(
                order: order,
                effectiveDiscount: effectiveDiscount,
                effectiveTotal: effectiveTotal,
                discountCtrl: _discountCtrl,
                onDiscountChanged: (v) =>
                    setState(() => _discount = double.tryParse(v) ?? 0),
              ),
              const SizedBox(height: 16),
              _PaymentPanel(
                payment: _payment,
                effectiveTotal: effectiveTotal,
                cashCtrl: _cashCtrl,
                changeDue: changeDue,
                processing: _processing,
                onMethodChanged: (m) => setState(() => _payment = m),
                onCashChanged: (_) => setState(() {}),
                onPrint: () => ReceiptPrinter.printReceipt(order),
                onProcess: () =>
                    _processPayment(context, order, effectiveDiscount),
                cashPaid: cashPaid,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processPayment(
      BuildContext context, Order order, double discount) async {
    setState(() => _processing = true);
    final messenger   = ScaffoldMessenger.of(context);
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
            content: Text('Ödeme başarıyla işlendi'),
            backgroundColor: Color(0xFF16A34A)));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: const Color(0xFFDC2626)));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }
}

class _ReceiptCard extends StatelessWidget {
  final Order order;
  final double effectiveDiscount;
  final double effectiveTotal;
  final TextEditingController discountCtrl;
  final ValueChanged<String> onDiscountChanged;

  const _ReceiptCard({
    required this.order,
    required this.effectiveDiscount,
    required this.effectiveTotal,
    required this.discountCtrl,
    required this.onDiscountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 20, horizontal: 28),
              color: const Color(0xFF111827),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.restaurant_menu,
                            size: 18, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dijital Adisyon',
                              style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.3)),
                          Text('RESTORAN POS',
                              style: GoogleFonts.montserrat(
                                  fontSize: 9,
                                  color: Colors.white54,
                                  letterSpacing: 2)),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Masa ${order.tableNo}',
                              style: GoogleFonts.montserrat(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          Text(
                              '#${order.id.substring(0, 6).toUpperCase()}',
                              style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  color: Colors.white54)),
                        ],
                      ),
                    ],
                  ),
                  if (order.createdAt != null) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(_fmtDt(order.createdAt!),
                          style: GoogleFonts.montserrat(
                              fontSize: 11,
                              color: Colors.white54)),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: Text('ÜRÜN',
                              style: _headerStyle)),
                      SizedBox(
                          width: 44,
                          child: Text('ADET',
                              textAlign: TextAlign.center,
                              style: _headerStyle)),
                      SizedBox(
                          width: 90,
                          child: Text('TUTAR',
                              textAlign: TextAlign.right,
                              style: _headerStyle)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: Color(0xFFE5E7EB)),
                  const SizedBox(height: 4),
                  ...order.items.map((item) => Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                                child: Text(item.name,
                                    style: GoogleFonts.montserrat(
                                        fontSize: 13,
                                        color:
                                            const Color(0xFF111827)))),
                            SizedBox(
                                width: 44,
                                child: Text('×${item.quantity}',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.montserrat(
                                        fontSize: 13,
                                        color: const Color(
                                            0xFF6B7280)))),
                            SizedBox(
                                width: 90,
                                child: Text(
                                    'TL ${item.total.toStringAsFixed(2)}',
                                    textAlign: TextAlign.right,
                                    style: GoogleFonts.montserrat(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(
                                            0xFF111827)))),
                          ],
                        ),
                      )),
                  const SizedBox(height: 8),
                  const Divider(color: Color(0xFFE5E7EB)),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
              child: Column(
                children: [
                  _billRow('Ara Toplam', order.subtotal),
                  const SizedBox(height: 4),
                  _billRow('KDV (%15)', order.tax),
                  const SizedBox(height: 4),
                  _billRow('Servis Ücreti (%5)', order.serviceCharge),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: Text('İndirim (TL)',
                              style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color: const Color(0xFF6B7280)))),
                      SizedBox(
                        width: 110,
                        child: TextField(
                          controller: discountCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          textAlign: TextAlign.right,
                          style: GoogleFonts.montserrat(
                              fontSize: 13,
                              color: const Color(0xFFDC2626),
                              fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                            filled: true,
                            fillColor: const Color(0xFFFEF2F2),
                            hintText: '0.00',
                            hintStyle: GoogleFonts.montserrat(
                                fontSize: 13,
                                color: const Color(0xFF9CA3AF)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: Color(0xFFFECACA)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: Color(0xFFDC2626), width: 1.5),
                            ),
                          ),
                          onChanged: onDiscountChanged,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(28, 16, 28, 20),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('GENEL TOPLAM',
                      style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                          letterSpacing: 1)),
                  Text(
                      'TL ${effectiveTotal.toStringAsFixed(2)}',
                      style: GoogleFonts.montserrat(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle get _headerStyle => GoogleFonts.montserrat(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.5,
      color: const Color(0xFF9CA3AF));

  Widget _billRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.montserrat(
                fontSize: 12, color: const Color(0xFF6B7280))),
        Text('TL ${amount.toStringAsFixed(2)}',
            style: GoogleFonts.montserrat(
                fontSize: 12, color: const Color(0xFF6B7280))),
      ],
    );
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

class _PaymentPanel extends StatelessWidget {
  final PaymentMethod payment;
  final double effectiveTotal;
  final TextEditingController cashCtrl;
  final double? changeDue;
  final bool processing;
  final double cashPaid;
  final ValueChanged<PaymentMethod> onMethodChanged;
  final ValueChanged<String> onCashChanged;
  final VoidCallback onPrint;
  final VoidCallback onProcess;

  const _PaymentPanel({
    required this.payment,
    required this.effectiveTotal,
    required this.cashCtrl,
    required this.changeDue,
    required this.processing,
    required this.cashPaid,
    required this.onMethodChanged,
    required this.onCashChanged,
    required this.onPrint,
    required this.onProcess,
  });

  static const _methods = [
    (PaymentMethod.cash, Icons.payments_outlined, 'Nakit'),
    (PaymentMethod.card, Icons.credit_card_outlined, 'Kart'),
    (PaymentMethod.split, Icons.call_split_outlined, 'Bölüşümlü'),
    (PaymentMethod.online, Icons.phone_android_outlined, 'Online'),
  ];

  static const _methodColors = {
    PaymentMethod.cash: Color(0xFF16A34A),
    PaymentMethod.card: Color(0xFF2563EB),
    PaymentMethod.split: Color(0xFFD97706),
    PaymentMethod.online: Color(0xFF7C3AED),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ÖDEME YÖNTEMİ',
              style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: const Color(0xFF9CA3AF))),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 3.2,
            children: _methods.map((m) {
              final (method, icon, label) = m;
              final sel = payment == method;
              final color =
                  _methodColors[method] ?? const Color(0xFF6B7280);
              return GestureDetector(
                onTap: () => onMethodChanged(method),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: sel
                        ? color.withValues(alpha: 0.08)
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: sel ? color : const Color(0xFFE5E7EB),
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon,
                          size: 18,
                          color:
                              sel ? color : const Color(0xFF9CA3AF)),
                      const SizedBox(width: 8),
                      Text(label,
                          style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: sel
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: sel
                                  ? color
                                  : const Color(0xFF6B7280))),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (payment == PaymentMethod.cash) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE5E7EB)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Verilen Nakit',
                          style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF374151))),
                      const SizedBox(height: 2),
                      Text('TL cinsinden girin',
                          style: GoogleFonts.montserrat(
                              fontSize: 11,
                              color: const Color(0xFF9CA3AF))),
                    ],
                  ),
                ),
                SizedBox(
                  width: 130,
                  child: TextField(
                    controller: cashCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                            decimal: true),
                    textAlign: TextAlign.right,
                    style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827)),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      prefixText: 'TL ',
                      prefixStyle: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: const Color(0xFF9CA3AF)),
                      hintText: '0.00',
                      hintStyle: GoogleFonts.montserrat(
                          fontSize: 15,
                          color: const Color(0xFF9CA3AF)),
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFF111827), width: 1.5),
                      ),
                    ),
                    onChanged: onCashChanged,
                  ),
                ),
              ],
            ),
            if (changeDue != null && changeDue! >= 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color:
                          const Color(0xFF16A34A).withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 16, color: Color(0xFF16A34A)),
                        const SizedBox(width: 8),
                        Text('Para Üstü',
                            style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF16A34A))),
                      ],
                    ),
                    Text('TL ${changeDue!.toStringAsFixed(2)}',
                        style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF16A34A))),
                  ],
                ),
              ),
            ] else if (changeDue != null && changeDue! < 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color:
                          const Color(0xFFDC2626).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 16, color: Color(0xFFDC2626)),
                    const SizedBox(width: 8),
                    Text(
                      'TL ${(-changeDue!).toStringAsFixed(2)} daha gerekli',
                      style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFDC2626)),
                    ),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: processing ? null : onPrint,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6B7280),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 13),
                ),
                icon: const Icon(Icons.print_outlined, size: 16),
                label: Text('Önizle',
                    style: GoogleFonts.montserrat(
                        fontSize: 13, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (processing ||
                          (payment == PaymentMethod.cash &&
                              cashPaid > 0 &&
                              cashPaid < effectiveTotal))
                      ? null
                      : onProcess,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  icon: processing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(
                          Icons.check_circle_outline, size: 18),
                  label: Text('Ödemeyi İşle',
                      style: GoogleFonts.montserrat(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
  const _OrderList({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 18, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.receipt_long_outlined,
                      size: 16, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Text('Bekleyen Ödemeler',
                    style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827))),
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
                            color: const Color(0xFFDC2626))),
                  );
                }
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF111827)));
                }

                final orders = snap.data!.docs
                    .map((d) => Order.fromFirestore(
                        d.data() as Map<String, dynamic>, d.id))
                    .toList()
                  ..sort((a, b) {
                    if (a.status != b.status) {
                      return a.status == OrderStatus.ready ? -1 : 1;
                    }
                    return (a.createdAt ?? DateTime(0))
                        .compareTo(b.createdAt ?? DateTime(0));
                  });

                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                              Icons.receipt_long_outlined,
                              size: 26, color: Color(0xFF9CA3AF)),
                        ),
                        const SizedBox(height: 14),
                        Text('Bekleyen sipariş yok',
                            style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF111827))),
                        const SizedBox(height: 6),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Mutfak siparişi hazır olarak\nişaretlediğinde burada görünür',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                                fontSize: 11,
                                color: const Color(0xFF9CA3AF)),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const Divider(
                      height: 1, color: Color(0xFFE5E7EB)),
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
    final isSel       = selected?.id == order.id;
    final isReady     = order.status == OrderStatus.ready;
    final statusColor = isReady
        ? const Color(0xFF16A34A)
        : const Color(0xFFD97706);

    return InkWell(
      onTap: () => onSelect(order),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: 18, vertical: 14),
        color: isSel
            ? const Color(0xFF111827).withValues(alpha: 0.05)
            : Colors.white,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSel
                    ? const Color(0xFF111827)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${order.tableNo}',
                  style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color:
                          isSel ? Colors.white : const Color(0xFF111827)),
                ),
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
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827))),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
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
                    '${order.items.length} ürün',
                    style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: const Color(0xFF9CA3AF)),
                  ),
                  Text(
                    'TL ${order.total.toStringAsFixed(2)}',
                    style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827)),
                  ),
                ],
              ),
            ),
            if (isSel)
              const Icon(Icons.chevron_right,
                  size: 18, color: Color(0xFF111827)),
          ],
        ),
      ),
    );
  }
}
