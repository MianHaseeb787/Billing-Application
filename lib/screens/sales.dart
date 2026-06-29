import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      backgroundColor: const Color(0xFFDBEAFE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000052),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Satış Paneli',
              style: GoogleFonts.montserrat(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              'Gelir ve işlem özeti',
              style: GoogleFonts.montserrat(
                fontSize: 11,
                color: Colors.white60,
              ),
            ),
          ],
        ),
        actions: [
          _PeriodSelector(
            period: _period,
            onChanged: (p) => setState(() => _period = p),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('salesLogs')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF000052)));
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
            final total = (data['total'] as num?)?.toDouble() ?? 0;
            totalRevenue += total;
            final method = data['paymentMethod'] as String? ?? 'cash';
            byMethod[method] = (byMethod[method] ?? 0) + total;
            for (final item in (data['items'] as List<dynamic>? ?? [])) {
              final name = item['name'] as String? ?? 'Bilinmiyor';
              final qty = (item['qty'] as num?)?.toDouble() ?? 1;
              byItem[name] = (byItem[name] ?? 0) + qty;
            }
          }

          final topItems = (byItem.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .take(5)
              .toList();

          final avgOrder =
              docs.isEmpty ? 0.0 : totalRevenue / docs.length;
          final topMethod = byMethod.isEmpty
              ? '—'
              : (byMethod.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value)))
                  .first
                  .key
                  .toUpperCase();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _KpiRow(
                  totalRevenue: totalRevenue,
                  orderCount: docs.length,
                  avgOrder: avgOrder,
                  topMethod: topMethod,
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _TransactionLog(docs: docs),
                    ),
                    const SizedBox(width: 20),
                    SizedBox(
                      width: 280,
                      child: Column(
                        children: [
                          _PaymentBreakdown(
                              byMethod: byMethod, total: totalRevenue),
                          const SizedBox(height: 16),
                          _TopItems(items: topItems),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final _Period period;
  final ValueChanged<_Period> onChanged;
  const _PeriodSelector(
      {required this.period, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const labels = {
      _Period.today: 'Bugün',
      _Period.week: '7 Gün',
      _Period.month: '30 Gün',
      _Period.all: 'Tümü',
    };

    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _Period.values.map((p) {
          final active = period == p;
          return GestureDetector(
            onTap: () => onChanged(p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: active ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        )
                      ]
                    : [],
              ),
              child: Text(
                labels[p]!,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight:
                      active ? FontWeight.w700 : FontWeight.w500,
                  color: active
                      ? const Color(0xFF111827)
                      : Colors.white70,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  final double totalRevenue;
  final int orderCount;
  final double avgOrder;
  final String topMethod;

  const _KpiRow({
    required this.totalRevenue,
    required this.orderCount,
    required this.avgOrder,
    required this.topMethod,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _KpiCard(
          label: 'Toplam Gelir',
          value: 'TL ${totalRevenue.toStringAsFixed(2)}',
          icon: Icons.trending_up_rounded,
          iconColor: const Color(0xFF16A34A),
          sub: 'Seçili dönem',
        ),
        const SizedBox(width: 14),
        _KpiCard(
          label: 'Sipariş Sayısı',
          value: '$orderCount',
          icon: Icons.receipt_long_outlined,
          iconColor: const Color(0xFF2563EB),
          sub: 'Tamamlanan',
        ),
        const SizedBox(width: 14),
        _KpiCard(
          label: 'Ortalama Sipariş',
          value: 'TL ${avgOrder.toStringAsFixed(2)}',
          icon: Icons.bar_chart_outlined,
          iconColor: const Color(0xFFD97706),
          sub: 'Sipariş başına',
        ),
        const SizedBox(width: 14),
        _KpiCard(
          label: 'En Çok Kullanılan',
          value: topMethod,
          icon: Icons.payments_outlined,
          iconColor: const Color(0xFF7C3AED),
          sub: 'Ödeme yöntemi',
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String sub;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6B7280))),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(sub,
                style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: const Color(0xFF9CA3AF))),
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

  static const _methodColors = {
    'cash': Color(0xFF16A34A),
    'card': Color(0xFF2563EB),
    'split': Color(0xFFD97706),
    'online': Color(0xFF7C3AED),
  };

  static const _methodLabels = {
    'cash': 'Nakit',
    'card': 'Kart',
    'split': 'Bölüşümlü',
    'online': 'Online',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF000052).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.pie_chart_outline,
                    size: 16, color: Color(0xFF000052)),
              ),
              const SizedBox(width: 10),
              Text('Ödeme Yöntemleri',
                  style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827))),
            ],
          ),
          const SizedBox(height: 18),
          if (byMethod.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('Bu dönemde veri yok',
                    style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: const Color(0xFF9CA3AF))),
              ),
            )
          else
            ...byMethod.entries.map((e) {
              final pct = total > 0 ? (e.value / total) : 0.0;
              final color = _methodColors[e.key] ?? const Color(0xFF6B7280);
              final label = _methodLabels[e.key] ?? e.key.toUpperCase();
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(label,
                              style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF111827))),
                        ),
                        Text(
                          'TL ${e.value.toStringAsFixed(0)}',
                          style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827)),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 36,
                          child: Text(
                            '${(pct * 100).toStringAsFixed(0)}%',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.montserrat(
                                fontSize: 11,
                                color: const Color(0xFF9CA3AF)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct.toDouble(),
                        backgroundColor: const Color(0xFFF3F4F6),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
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

  static const _rankColors = [
    Color(0xFFD97706),
    Color(0xFF6B7280),
    Color(0xFF92400E),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.star_outline_rounded,
                    size: 16, color: Color(0xFFD97706)),
              ),
              const SizedBox(width: 10),
              Text('En Çok Satanlar',
                  style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827))),
            ],
          ),
          const SizedBox(height: 18),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('Bu dönemde veri yok',
                    style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: const Color(0xFF9CA3AF))),
              ),
            )
          else
            ...items.asMap().entries.map((e) {
              final rank = e.key + 1;
              final item = e.value;
              final rankColor = rank <= 3
                  ? _rankColors[rank - 1]
                  : const Color(0xFF9CA3AF);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: rankColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text('$rank',
                            style: GoogleFonts.montserrat(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: rankColor)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(item.key,
                          style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF111827)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('×${item.value.toInt()}',
                          style: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF6B7280))),
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

  static const _methodColors = {
    'cash': Color(0xFF16A34A),
    'card': Color(0xFF2563EB),
    'split': Color(0xFFD97706),
    'online': Color(0xFF7C3AED),
  };

  static const _methodLabels = {
    'cash': 'Nakit',
    'card': 'Kart',
    'split': 'Bölüşümlü',
    'online': 'Online',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.history_rounded,
                      size: 16, color: Color(0xFF16A34A)),
                ),
                const SizedBox(width: 10),
                Text('İşlem Geçmişi',
                    style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827))),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${docs.length} işlem',
                      style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              border: Border.symmetric(
                horizontal: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('MASA / SİPARİŞ',
                      style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: const Color(0xFF9CA3AF))),
                ),
                SizedBox(
                  width: 90,
                  child: Text('YÖNTEM',
                      style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: const Color(0xFF9CA3AF))),
                ),
                SizedBox(
                  width: 60,
                  child: Text('ADET',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: const Color(0xFF9CA3AF))),
                ),
                SizedBox(
                  width: 100,
                  child: Text('TUTAR',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: const Color(0xFF9CA3AF))),
                ),
              ],
            ),
          ),
          if (docs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long_outlined,
                        size: 36, color: Color(0xFF9CA3AF)),
                    const SizedBox(height: 10),
                    Text('Bu dönemde işlem yok',
                        style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: const Color(0xFF9CA3AF))),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
              itemBuilder: (_, i) {
                final data = docs[i].data() as Map<String, dynamic>;
                final total =
                    (data['total'] as num?)?.toDouble() ?? 0;
                final method =
                    (data['paymentMethod'] as String? ?? 'cash');
                final methodLabel =
                    _methodLabels[method] ?? method.toUpperCase();
                final methodColor =
                    _methodColors[method] ?? const Color(0xFF6B7280);
                final tableNo = data['tableNo'];
                final ts = data['createdAt'];
                final date =
                    ts != null ? (ts as Timestamp).toDate() : null;
                final itemCount =
                    (data['items'] as List?)?.length ?? 0;

                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  color: Colors.transparent,
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: Color(0xFF16A34A), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Masa $tableNo',
                                style: GoogleFonts.montserrat(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF111827))),
                            if (date != null)
                              Text(_fmtDt(date),
                                  style: GoogleFonts.montserrat(
                                      fontSize: 11,
                                      color: const Color(0xFF9CA3AF))),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                methodColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(methodLabel,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: methodColor)),
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Text('$itemCount',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                                fontSize: 13,
                                color: const Color(0xFF111827))),
                      ),
                      SizedBox(
                        width: 100,
                        child: Text(
                          'TL ${total.toStringAsFixed(2)}',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 8),
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
