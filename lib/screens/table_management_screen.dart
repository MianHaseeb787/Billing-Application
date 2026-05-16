import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/table_model.dart';
import '../utils/constants.dart';
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
      backgroundColor: AppConstants.bg,
      appBar: AppBar(
        title: const Text('Masa Yönetimi'),
        actions: [
          TextButton.icon(
            onPressed: () => _addTable(context),
            icon: const Icon(Icons.add,
                size: 16, color: AppConstants.amber),
            label: Text('Masa Ekle',
                style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppConstants.amber)),
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
        border: Border(bottom: BorderSide(color: AppConstants.border)),
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
          _legend(AppConstants.green, 'Boş'),
          const SizedBox(width: 16),
          _legend(AppConstants.red, 'Dolu'),
          const SizedBox(width: 16),
          _legend(AppConstants.yellow, 'Rezerve'),
          const SizedBox(width: 16),
          _legend(AppConstants.text3, 'Temizleniyor'),
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
              ? AppConstants.amber.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color:
                active ? AppConstants.amber : AppConstants.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: active
                ? AppConstants.amber
                : AppConstants.text2,
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
                fontSize: 11, color: AppConstants.text3)),
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
                    GoogleFonts.montserrat(color: AppConstants.red)),
          );
        }
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(
                  color: AppConstants.amber));
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
                    size: 56, color: AppConstants.text3),
                const SizedBox(height: 12),
                Text(
                  _filter == null
                      ? 'Masa yapılandırılmadı. Başlamak için "Masa Ekle"ye dokunun.'
                      : 'Bu durumda masa yok.',
                  style: GoogleFonts.montserrat(
                      fontSize: 14, color: AppConstants.text2),
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
        title: Text('Masa ${table.tableNo} Aç',
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                color: AppConstants.text1)),
        content: TextFormField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: GoogleFonts.montserrat(color: AppConstants.text1),
          decoration: const InputDecoration(
              labelText: 'Misafir sayısı',
              prefixIcon: Icon(Icons.people_outlined,
                  size: 18, color: AppConstants.text2)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Aç')),
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
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                  color: AppConstants.border,
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
                          color: AppConstants.text1)),
                  const Spacer(),
                  _StatusBadge(table.status),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add_shopping_cart_outlined,
                  color: AppConstants.amber, size: 20),
              title: Text('Ürün Ekle / Görüntüle',
                  style: GoogleFonts.montserrat(
                      fontSize: 14, color: AppConstants.text1)),
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
                    color: AppConstants.green, size: 20),
                title: Text('Boş Olarak İşaretle',
                    style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: AppConstants.text1)),
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
                    color: AppConstants.yellow, size: 20),
                title: Text('Rezerve Olarak İşaretle',
                    style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: AppConstants.text1)),
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
                  color: AppConstants.text2,
                  size: 20),
              title: Text('Temizleniyor Olarak İşaretle',
                  style: GoogleFonts.montserrat(
                      fontSize: 14, color: AppConstants.text1)),
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
                  color: AppConstants.red, size: 20),
              title: Text('Masayı Kaldır',
                  style: GoogleFonts.montserrat(
                      fontSize: 14, color: AppConstants.red)),
              onTap: () async {
                Navigator.pop(ctx);
                final sure = await showDialog<bool>(
                  context: context,
                  builder: (d) => AlertDialog(
                    title: Text(
                        'Masa ${table.tableNo} Kaldır',
                        style: GoogleFonts.montserrat(
                            color: AppConstants.text1)),
                    content: Text('Bu işlem geri alınamaz.',
                        style: GoogleFonts.montserrat(
                            color: AppConstants.text2)),
                    actions: [
                      TextButton(
                          onPressed: () =>
                              Navigator.pop(d, false),
                          child: const Text('İptal')),
                      ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(d, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.red,
                            foregroundColor: Colors.white),
                        child: const Text('Kaldır'),
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
        title: Text('Yeni Masa Ekle',
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                color: AppConstants.text1)),
        content: TextFormField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: GoogleFonts.montserrat(color: AppConstants.text1),
          decoration: const InputDecoration(
              labelText: 'Masa Numarası (örn. 7)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal')),
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
            child: const Text('Ekle'),
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
      borderRadius:
          BorderRadius.circular(AppConstants.cardRadius),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: isUrgent
              ? Border.all(color: AppConstants.red, width: 2)
              : Border.all(color: color.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: AppConstants.purple.withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, 3),
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
                        color: AppConstants.text1)),
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
                borderRadius: BorderRadius.circular(4),
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
                        size: 11, color: AppConstants.text3),
                    const SizedBox(width: 2),
                    Text('${table.guestCount}',
                        style: GoogleFonts.montserrat(
                            fontSize: 11,
                            color: AppConstants.text3)),
                  ])
                else
                  const SizedBox.shrink(),
                if (elapsed != null)
                  Row(children: [
                    Icon(Icons.timer_outlined,
                        size: 11,
                        color: isUrgent
                            ? AppConstants.red
                            : AppConstants.text3),
                    const SizedBox(width: 2),
                    Text(elapsed,
                        style: GoogleFonts.montserrat(
                            fontSize: 11,
                            color: isUrgent
                                ? AppConstants.red
                                : AppConstants.text3,
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
        return AppConstants.green;
      case TableStatus.occupied:
        return AppConstants.red;
      case TableStatus.reserved:
        return AppConstants.yellow;
      case TableStatus.cleaning:
        return AppConstants.text3;
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
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
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
        return AppConstants.green;
      case TableStatus.occupied:
        return AppConstants.red;
      case TableStatus.reserved:
        return AppConstants.yellow;
      case TableStatus.cleaning:
        return AppConstants.text3;
    }
  }
}
