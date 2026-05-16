import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

enum _Period { today, week, month, all }

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  _Period _period = _Period.today;

  DateTime get _from {
    final now = DateTime.now();
    switch (_period) {
      case _Period.today:
        return DateTime(now.year, now.month, now.day);
      case _Period.week:
        return now.subtract(const Duration(days: 7));
      case _Period.month:
        return now.subtract(const Duration(days: 30));
      case _Period.all:
        return DateTime(2000);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.bg,
      appBar: AppBar(title: const Text('Satış Paneli')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('salesLogs')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(
                    color: AppConstants.amber));
          }

          final cutoff = _from;
          final docs = snap.data!.docs.where((d) {
            final ts = d['createdAt'];
            if (ts == null) return false;
            return (ts as Timestamp).toDate().isAfter(cutoff);
          }).toList();

          double totalRevenue = 0;
          final Map<String, double> byMethod = {};
          final Map<String, double> byItem = {};

          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final total =
                (data['total'] as num?)?.toDouble() ?? 0;
            totalRevenue += total;

            final method =
                data['paymentMethod'] as String? ?? 'cash';
            byMethod[method] = (byMethod[method] ?? 0) + total;

            for (final item in (data['items'] as List<dynamic>? ??
                [])) {
              final name =
                  item['name'] as String? ?? 'Bilinmiyor';
              final qty =
                  (item['qty'] as num?)?.toDouble() ?? 1;
              byItem[name] = (byItem[name] ?? 0) + qty;
            }
          }

          final topItems = (byItem.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .take(5)
              .toList();

          return Column(
            children: [
              _PeriodBar(
                period: _period,
                onChanged: (p) => setState(() => _period = p),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _SummaryCard(
                            label: 'Gelir',
                            value:
                                'TL ${totalRevenue.toStringAsFixed(2)}',
                            icon: Icons.attach_money_outlined,
                            color: AppConstants.green,
                          ),
                          const SizedBox(width: 14),
                          _SummaryCard(
                            label: 'Siparişler',
                            value: '${docs.length}',
                            icon: Icons.receipt_long_outlined,
                            color: AppConstants.blue,
                          ),
                          const SizedBox(width: 14),
                          _SummaryCard(
                            label: 'Ortalama Sipariş',
                            value: docs.isEmpty
                                ? 'TL 0.00'
                                : 'TL ${(totalRevenue / docs.length).toStringAsFixed(2)}',
                            icon: Icons.bar_chart_outlined,
                            color: AppConstants.purple,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: _PaymentBreakdown(
                                  byMethod: byMethod,
                                  total: totalRevenue)),
                          const SizedBox(width: 14),
                          Expanded(
                              child:
                                  _TopItems(items: topItems)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _TransactionLog(docs: docs),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PeriodBar extends StatelessWidget {
  final _Period period;
  final ValueChanged<_Period> onChanged;
  const _PeriodBar(
      {required this.period, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const labels = {
      _Period.today: 'Bugün',
      _Period.week: 'Son 7 Gün',
      _Period.month: 'Son 30 Gün',
      _Period.all: 'Tüm Zamanlar',
    };

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppConstants.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_outlined,
              size: 14, color: AppConstants.text3),
          const SizedBox(width: 8),
          Text('Dönem:',
              style: GoogleFonts.montserrat(
                  fontSize: 12, color: AppConstants.text3)),
          const SizedBox(width: 12),
          ..._Period.values.map((p) {
            final active = period == p;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onChanged(p),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: active
                        ? AppConstants.amber
                            .withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: active
                          ? AppConstants.amber
                          : AppConstants.border,
                    ),
                  ),
                  child: Text(labels[p]!,
                      style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: active
                              ? AppConstants.amber
                              : AppConstants.text2)),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _SummaryCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppConstants.surface,
          borderRadius:
              BorderRadius.circular(AppConstants.cardRadius),
          border: Border.all(color: AppConstants.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: AppConstants.text2)),
                const SizedBox(height: 3),
                Text(value,
                    style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.text1)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentBreakdown extends StatelessWidget {
  final Map<String, double> byMethod;
  final double total;
  const _PaymentBreakdown(
      {required this.byMethod, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppConstants.purple.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ödeme Yöntemleri',
              style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.text1)),
          const SizedBox(height: 16),
          if (byMethod.isEmpty)
            Text('Henüz veri yok',
                style: GoogleFonts.montserrat(
                    fontSize: 13, color: AppConstants.text3))
          else
            ...byMethod.entries.map((e) {
              final pct = total > 0 ? (e.value / total) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key.toUpperCase(),
                            style: GoogleFonts.montserrat(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppConstants.text2)),
                        Text(
                          'TL ${e.value.toStringAsFixed(2)} · ${(pct * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.montserrat(
                              fontSize: 11,
                              color: AppConstants.text3),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: pct.toDouble(),
                        backgroundColor: AppConstants.surface2,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(
                                AppConstants.amber),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _TopItems extends StatelessWidget {
  final List<MapEntry<String, double>> items;
  const _TopItems({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppConstants.purple.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('En Çok Satan Ürünler',
              style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.text1)),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Text('Henüz veri yok',
                style: GoogleFonts.montserrat(
                    fontSize: 13, color: AppConstants.text3))
          else
            ...items.asMap().entries.map((e) {
              final rank = e.key + 1;
              final item = e.value;
              final rankColor = rank == 1
                  ? AppConstants.amber
                  : rank == 2
                      ? AppConstants.text2
                      : AppConstants.text3;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      child: Text('$rank.',
                          style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: rankColor)),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(item.key,
                          style: GoogleFonts.montserrat(
                              fontSize: 13,
                              color: AppConstants.text1)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppConstants.surface2,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text('×${item.value.toInt()}',
                          style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.text2)),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _TransactionLog extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  const _TransactionLog({required this.docs});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppConstants.purple.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.fromLTRB(20, 20, 20, 14),
            child: Text('İşlem Günlüğü',
                style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.text1)),
          ),
          const Divider(height: 1, color: AppConstants.border),
          if (docs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text('Bu dönemde işlem yok',
                    style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: AppConstants.text3)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const Divider(
                  height: 1, color: AppConstants.border),
              itemBuilder: (_, i) {
                final data =
                    docs[i].data() as Map<String, dynamic>;
                final total =
                    (data['total'] as num?)?.toDouble() ?? 0;
                final method =
                    (data['paymentMethod'] as String? ?? 'cash')
                        .toUpperCase();
                final tableNo = data['tableNo'];
                final ts = data['createdAt'];
                final date = ts != null
                    ? (ts as Timestamp).toDate()
                    : null;
                final itemCount =
                    (data['items'] as List?)?.length ?? 0;

                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 4),
                  leading: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppConstants.green
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                        Icons.check_circle_outline,
                        color: AppConstants.green,
                        size: 17),
                  ),
                  title: Text(
                    'Masa $tableNo  ·  $itemCount ürün',
                    style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppConstants.text1),
                  ),
                  subtitle: date != null
                      ? Text(_fmtDt(date),
                          style: GoogleFonts.montserrat(
                              fontSize: 11,
                              color: AppConstants.text3))
                      : null,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('TL ${total.toStringAsFixed(2)}',
                          style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppConstants.amber)),
                      Text(method,
                          style: GoogleFonts.montserrat(
                              fontSize: 10,
                              color: AppConstants.text3)),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _fmtDt(DateTime dt) {
    const mo = [
      'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${mo[dt.month - 1]} ${dt.day}  $h:$m';
  }
}
