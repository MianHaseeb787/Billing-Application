import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/table_model.dart';
import 'order_screen.dart';

class TableManagementScreen extends StatefulWidget {
  const TableManagementScreen({super.key});

  @override
  State<TableManagementScreen> createState() =>
      _TableManagementScreenState();
}

class _TableManagementScreenState
    extends State<TableManagementScreen> {
  TableStatus? _filter;

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
        title: Text(
          'Masa Yönetimi',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _addTable(context),
            icon: const Icon(Icons.add,
                size: 16, color: Color(0xFFD97706)),
            label: Text('Masa Ekle',
                style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFD97706))),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(child: _buildGrid()),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          _chip('Tümü', null),
          const SizedBox(width: 8),
          _chip('Boş', TableStatus.available),
          const SizedBox(width: 8),
          _chip('Dolu', TableStatus.occupied),
          const SizedBox(width: 8),
          _chip('Rezerve', TableStatus.reserved),
          const SizedBox(width: 8),
          _chip('Temizleniyor', TableStatus.cleaning),
          const Spacer(),
          _legend(const Color(0xFF16A34A), 'Boş'),
          const SizedBox(width: 16),
          _legend(const Color(0xFFDC2626), 'Dolu'),
          const SizedBox(width: 16),
          _legend(const Color(0xFFD97706), 'Rezerve'),
          const SizedBox(width: 16),
          _legend(const Color(0xFF9CA3AF), 'Temizleniyor'),
        ],
      ),
    );
  }

  Widget _chip(String label, TableStatus? status) {
    final active = _filter == status;
    return GestureDetector(
      onTap: () => setState(() => _filter = status),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF111827).withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color:
                active ? const Color(0xFF111827) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: active
                ? const Color(0xFF111827)
                : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.montserrat(
                fontSize: 11, color: const Color(0xFF9CA3AF))),
      ],
    );
  }

  Widget _buildGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tables')
          .orderBy('tableNo')
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Text('Hata: ${snap.error}',
                style:
                    GoogleFonts.montserrat(color: const Color(0xFFDC2626))),
          );
        }
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF111827)));
        }

        var tables = snap.data!.docs
            .map((d) => RestaurantTable.fromFirestore(
                d.data() as Map<String, dynamic>, d.id))
            .toList();

        if (_filter != null) {
          tables =
              tables.where((t) => t.status == _filter).toList();
        }

        if (tables.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.table_restaurant_outlined,
                    size: 56, color: Color(0xFF9CA3AF)),
                const SizedBox(height: 12),
                Text(
                  _filter == null
                      ? 'Masa yapılandırılmadı. Başlamak için "Masa Ekle"ye dokunun.'
                      : 'Bu durumda masa yok.',
                  style: GoogleFonts.montserrat(
                      fontSize: 14, color: const Color(0xFF6B7280)),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.05,
          ),
          itemCount: tables.length,
          itemBuilder: (ctx, i) => _TableCard(
            table: tables[i],
            onTap: () => _onTap(context, tables[i]),
            onOptions: () => _showOptions(context, tables[i]),
          ),
        );
      },
    );
  }

  void _onTap(BuildContext context, RestaurantTable table) {
    if (table.status == TableStatus.available ||
        table.status == TableStatus.cleaning) {
      _openTable(context, table);
    } else {
      _showOptions(context, table);
    }
  }

  Future<void> _openTable(
      BuildContext context, RestaurantTable table) async {
    final ctrl = TextEditingController(
        text:
            table.guestCount > 0 ? '${table.guestCount}' : '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        title: Text('Masa ${table.tableNo} Aç',
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827))),
        content: TextFormField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: GoogleFonts.montserrat(color: const Color(0xFF111827)),
          decoration: InputDecoration(
            labelText: 'Misafir sayısı',
            labelStyle: GoogleFonts.montserrat(
                color: const Color(0xFF9CA3AF), fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF3F4F6),
            prefixIcon: const Icon(Icons.people_outlined,
                size: 18, color: Color(0xFF6B7280)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: Color(0xFF111827), width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('İptal',
                  style: GoogleFonts.montserrat(
                      color: const Color(0xFF6B7280)))),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111827),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Aç',
                  style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w600))),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      final guests = int.tryParse(ctrl.text.trim()) ?? 0;
      if (guests > 0) {
        await FirebaseFirestore.instance
            .collection('tables')
            .doc(table.id)
            .update({
          'guestCount': guests,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => OrderScreen(table: table)),
        );
      }
    }
  }

  void _showOptions(
      BuildContext context, RestaurantTable table) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(14))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text('Masa ${table.tableNo}',
                      style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827))),
                  const Spacer(),
                  _StatusBadge(table.status),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            ListTile(
              leading: const Icon(Icons.add_shopping_cart_outlined,
                  color: Color(0xFF111827), size: 20),
              title: Text('Ürün Ekle / Görüntüle',
                  style: GoogleFonts.montserrat(
                      fontSize: 14, color: const Color(0xFF111827))),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          OrderScreen(table: table)),
                );
              },
            ),
            if (table.status == TableStatus.occupied)
              ListTile(
                leading: const Icon(Icons.check_circle_outline,
                    color: Color(0xFF16A34A), size: 20),
                title: Text('Boş Olarak İşaretle',
                    style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: const Color(0xFF111827))),
                onTap: () async {
                  Navigator.pop(ctx);
                  await FirebaseFirestore.instance
                      .collection('tables')
                      .doc(table.id)
                      .update({
                    'status': 'available',
                    'currentOrderId': '',
                    'guestCount': 0,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                },
              ),
            if (table.status == TableStatus.available)
              ListTile(
                leading: const Icon(Icons.event_seat_outlined,
                    color: Color(0xFFD97706), size: 20),
                title: Text('Rezerve Olarak İşaretle',
                    style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: const Color(0xFF111827))),
                onTap: () async {
                  Navigator.pop(ctx);
                  await FirebaseFirestore.instance
                      .collection('tables')
                      .doc(table.id)
                      .update({
                    'status': 'reserved',
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                },
              ),
            ListTile(
              leading: const Icon(
                  Icons.cleaning_services_outlined,
                  color: Color(0xFF6B7280),
                  size: 20),
              title: Text('Temizleniyor Olarak İşaretle',
                  style: GoogleFonts.montserrat(
                      fontSize: 14, color: const Color(0xFF111827))),
              onTap: () async {
                Navigator.pop(ctx);
                await FirebaseFirestore.instance
                    .collection('tables')
                    .doc(table.id)
                    .update({
                  'status': 'cleaning',
                  'guestCount': 0,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline,
                  color: Color(0xFFDC2626), size: 20),
              title: Text('Masayı Kaldır',
                  style: GoogleFonts.montserrat(
                      fontSize: 14, color: const Color(0xFFDC2626))),
              onTap: () async {
                Navigator.pop(ctx);
                final sure = await showDialog<bool>(
                  context: context,
                  builder: (d) => AlertDialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    title: Text(
                        'Masa ${table.tableNo} Kaldır',
                        style: GoogleFonts.montserrat(
                            color: const Color(0xFF111827))),
                    content: Text('Bu işlem geri alınamaz.',
                        style: GoogleFonts.montserrat(
                            color: const Color(0xFF6B7280))),
                    actions: [
                      TextButton(
                          onPressed: () =>
                              Navigator.pop(d, false),
                          child: Text('İptal',
                              style: GoogleFonts.montserrat(
                                  color: const Color(0xFF6B7280)))),
                      ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(d, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10))),
                        child: Text('Kaldır',
                            style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                );
                if (sure == true) {
                  await FirebaseFirestore.instance
                      .collection('tables')
                      .doc(table.id)
                      .delete();
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _addTable(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        title: Text('Yeni Masa Ekle',
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827))),
        content: TextFormField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: GoogleFonts.montserrat(
              color: const Color(0xFF111827)),
          decoration: InputDecoration(
            labelText: 'Masa Numarası (örn. 7)',
            labelStyle: GoogleFonts.montserrat(
                color: const Color(0xFF9CA3AF), fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF3F4F6),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: Color(0xFF111827), width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('İptal',
                  style: GoogleFonts.montserrat(
                      color: const Color(0xFF6B7280)))),
          ElevatedButton(
            onPressed: () {
              final num = int.tryParse(ctrl.text.trim());
              if (num != null && num > 0) {
                FirebaseFirestore.instance
                    .collection('tables')
                    .add({
                  'tableNo': num,
                  'status': 'available',
                  'currentOrderId': '',
                  'guestCount': 0,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF111827),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Ekle',
                style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

String _tableStatusTr(TableStatus s) {
  switch (s) {
    case TableStatus.available:
      return 'BOŞ';
    case TableStatus.occupied:
      return 'DOLU';
    case TableStatus.reserved:
      return 'REZERVE';
    case TableStatus.cleaning:
      return 'TEMİZLENİYOR';
  }
}

class _TableCard extends StatelessWidget {
  final RestaurantTable table;
  final VoidCallback onTap;
  final VoidCallback onOptions;
  const _TableCard(
      {required this.table,
      required this.onTap,
      required this.onOptions});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(table.status);
    final isOccupied = table.status == TableStatus.occupied;
    final elapsed = isOccupied && table.updatedAt != null
        ? _elapsed(table.updatedAt!)
        : null;
    final isUrgent = isOccupied &&
        table.updatedAt != null &&
        DateTime.now()
                .difference(table.updatedAt!)
                .inMinutes >=
            90;

    return InkWell(
      onTap: onTap,
      onLongPress: onOptions,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isUrgent
              ? Border.all(color: const Color(0xFFDC2626), width: 2)
              : Border.all(color: color.withValues(alpha: 0.35)),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('M${table.tableNo}',
                    style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827))),
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _tableStatusTr(table.status),
                style: GoogleFonts.montserrat(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.5),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (table.guestCount > 0)
                  Row(children: [
                    const Icon(Icons.person_outlined,
                        size: 11, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 2),
                    Text('${table.guestCount}',
                        style: GoogleFonts.montserrat(
                            fontSize: 11,
                            color: const Color(0xFF9CA3AF))),
                  ])
                else
                  const SizedBox.shrink(),
                if (elapsed != null)
                  Row(children: [
                    Icon(Icons.timer_outlined,
                        size: 11,
                        color: isUrgent
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF9CA3AF)),
                    const SizedBox(width: 2),
                    Text(elapsed,
                        style: GoogleFonts.montserrat(
                            fontSize: 11,
                            color: isUrgent
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF9CA3AF),
                            fontWeight: isUrgent
                                ? FontWeight.w600
                                : FontWeight.normal)),
                  ]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(TableStatus s) {
    switch (s) {
      case TableStatus.available:
        return const Color(0xFF16A34A);
      case TableStatus.occupied:
        return const Color(0xFFDC2626);
      case TableStatus.reserved:
        return const Color(0xFFD97706);
      case TableStatus.cleaning:
        return const Color(0xFF9CA3AF);
    }
  }

  String _elapsed(DateTime since) {
    final d = DateTime.now().difference(since);
    if (d.inHours > 0) {
      return '${d.inHours}s${d.inMinutes.remainder(60)}d';
    }
    if (d.inMinutes > 0) return '${d.inMinutes}d';
    return 'şimdi';
  }
}

class _StatusBadge extends StatelessWidget {
  final TableStatus status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        _tableStatusTr(status),
        style: GoogleFonts.montserrat(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color),
      ),
    );
  }

  Color _color(TableStatus s) {
    switch (s) {
      case TableStatus.available:
        return const Color(0xFF16A34A);
      case TableStatus.occupied:
        return const Color(0xFFDC2626);
      case TableStatus.reserved:
        return const Color(0xFFD97706);
      case TableStatus.cleaning:
        return const Color(0xFF9CA3AF);
    }
  }
}
