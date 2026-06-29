import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import 'table_management_screen.dart';
import 'menu_screen.dart';
import 'sales.dart';
import 'kitchen_display_screen.dart';
import 'settings_screen.dart';
import 'generate_bill_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Timer _clock;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clock.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final role = auth.user?.role;

    return Scaffold(
      backgroundColor: const Color(0xFF000052),
      body: Column(
        children: [
          _TopBar(now: _now, auth: auth),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _StatsRow(),
                  const SizedBox(height: 28),
                  Text(
                    'HIZLI ERİŞİM',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.purple.withValues(alpha: 0.6),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (ctx, c) {
                        final cols = c.maxWidth > 800 ? 3 : 2;
                        final defs = _navDefs(context, role);
                        final rows = <List<_NavDef>>[];
                        for (int i = 0; i < defs.length; i += cols) {
                          rows.add(defs.sublist(
                              i, (i + cols).clamp(0, defs.length)));
                        }
                        return Column(
                          children: [
                            for (int r = 0; r < rows.length; r++) ...[
                              Expanded(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    for (int ci = 0;
                                        ci < rows[r].length;
                                        ci++) ...[
                                      Expanded(
                                        child: _NavCard(
                                          def: rows[r][ci],
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    rows[r][ci].screen),
                                          ),
                                        ),
                                      ),
                                      if (ci < rows[r].length - 1)
                                        const SizedBox(width: 14),
                                    ],
                                    for (int e = rows[r].length;
                                        e < cols;
                                        e++) ...[
                                      const SizedBox(width: 14),
                                      const Expanded(child: SizedBox()),
                                    ],
                                  ],
                                ),
                              ),
                              if (r < rows.length - 1)
                                const SizedBox(height: 14),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_NavDef> _navDefs(BuildContext context, UserRole? role) {
    final all = <_NavDef>[
      _NavDef(
          'Masalar',
          'Misafir al ve sipariş ver',
          Icons.table_restaurant_outlined,
          AppConstants.blue,
          const TableManagementScreen()),
      _NavDef('Hesap Kes', 'Ödeme işle', Icons.receipt_long_outlined,
          AppConstants.green, const GenerateBillScreen()),
      if (role == UserRole.kitchen ||
          role == UserRole.admin ||
          role == UserRole.manager)
        _NavDef(
            'Mutfak Ekranı',
            'Sipariş kuyruğunu yönet',
            Icons.kitchen_outlined,
            AppConstants.yellow,
            const KitchenDisplayScreen()),
      if (role == UserRole.admin ||
          role == UserRole.manager ||
          role == UserRole.cashier)
        _NavDef(
            'Menü',
            'Ürünler ve kategoriler',
            Icons.restaurant_menu_outlined,
            AppConstants.amber,
            const MenuManagementScreen()),
      if (role == UserRole.admin || role == UserRole.manager)
        _NavDef('Satışlar', 'Gelir ve raporlar', Icons.bar_chart_outlined,
            AppConstants.purple, const SalesScreen()),
      if (role == UserRole.admin)
        _NavDef(
            'Ayarlar',
            'Kullanıcılar ve yapılandırma',
            Icons.settings_outlined,
            AppConstants.text3,
            const SettingsScreen()),
    ];
    return all;
  }
}

class _TopBar extends StatelessWidget {
  final DateTime now;
  final AuthProvider auth;
  const _TopBar({required this.now, required this.auth});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: const Color(0xFF000052),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000052).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.restaurant_menu,
                size: 20, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dijital Adisyon',
                style: GoogleFonts.montserrat(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'SATIŞ NOKTASI',
                style: GoogleFonts.montserrat(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Colors.white54,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _hhmm(now),
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  _date(now),
                  style: GoogleFonts.montserrat(
                      fontSize: 10,
                      color: Colors.white60,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (auth.user != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    child: Text(
                      auth.user!.name[0].toUpperCase(),
                      style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(auth.user!.name,
                          style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      Text(auth.user!.role.name.toUpperCase(),
                          style: GoogleFonts.montserrat(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.white60,
                              letterSpacing: 1)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
          ],
          TextButton.icon(
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout_outlined,
                size: 16, color: Colors.white70),
            label: Text(
              'Çıkış',
              style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70),
            ),
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28))),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<AuthProvider>().signOut();
    }
  }

  String _hhmm(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _date(DateTime dt) {
    const wd = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    const mo = [
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara'
    ];
    return '${wd[dt.weekday - 1]}, ${mo[dt.month - 1]} ${dt.day}';
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final midnight = DateTime(today.year, today.month, today.day);

    return Row(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('salesLogs')
                .where('createdAt',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(midnight))
                .snapshots(),
            builder: (_, snap) {
              final total = snap.hasData
                  ? snap.data!.docs.fold(
                      0.0,
                      (s, d) =>
                          s + ((d.data() as Map)['total'] ?? 0).toDouble())
                  : 0.0;
              return _StatCard(
                label: 'Bugünkü Gelir',
                value: 'TL ${total.toStringAsFixed(2)}',
                icon: Icons.attach_money,
                color: AppConstants.green,
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('status', whereIn: [
              'pending',
              'preparing',
              'ready',
              'served'
            ]).snapshots(),
            builder: (_, snap) {
              final count = snap.hasData ? snap.data!.docs.length : 0;
              return _StatCard(
                label: 'Aktif Siparişler',
                value: '$count',
                icon: Icons.receipt_outlined,
                color: AppConstants.amber,
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('status', whereIn: ['pending', 'preparing']).snapshots(),
            builder: (_, snap) {
              final count = snap.hasData ? snap.data!.docs.length : 0;
              return _StatCard(
                label: 'Mutfak Kuyruğu',
                value: '$count',
                icon: Icons.kitchen_outlined,
                color: AppConstants.red,
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('tables').snapshots(),
            builder: (_, snap) {
              final docs =
                  snap.hasData ? snap.data!.docs : <QueryDocumentSnapshot>[];
              final total = docs.length;
              final occ = docs
                  .where((d) => (d.data() as Map)['status'] == 'occupied')
                  .length;
              return _StatCard(
                label: 'Masalar',
                value: '$occ / $total dolu',
                icon: Icons.table_restaurant_outlined,
                color: AppConstants.blue,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: Colors.black87),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1E40AF),
                        letterSpacing: 0.3)),
                const SizedBox(height: 3),
                Text(value,
                    style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827)),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavDef {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget screen;
  const _NavDef(this.title, this.subtitle, this.icon, this.color, this.screen);
}

class _NavCard extends StatelessWidget {
  final _NavDef def;
  final VoidCallback onTap;
  const _NavCard({required this.def, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFDBEAFE),
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: def.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(def.icon, size: 30, color: def.color),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(def.title,
                      style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827))),
                  const SizedBox(height: 2),
                  Text(def.subtitle,
                      style: GoogleFonts.montserrat(
                          fontSize: 11, color: const Color(0xFF6B4FA0))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
