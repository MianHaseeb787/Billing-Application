import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
      backgroundColor: const Color(0xFFEDE0FF),
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(bottom: BorderSide(color: AppConstants.border)),
      ),
      child: Row(
        children: [
          Text(
            'DinO Dine',
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 10),
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
            child: SvgPicture.asset(
              'assets/images/dino_logo.svg',
              height: 40,
              colorFilter:
                  const ColorFilter.mode(Color(0xFF3889BC), BlendMode.srcIn),
            ),
          ),
          const SizedBox(width: 10),
          SvgPicture.asset(
            'assets/images/trex-green.svg',
            height: 40,
          ),
          const Spacer(),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _hhmm(now),
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                _date(now),
                style: GoogleFonts.montserrat(
                    fontSize: 10, color: AppConstants.text3),
              ),
            ],
          ),
          const SizedBox(width: 20),
          if (auth.user != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppConstants.surface2,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppConstants.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: AppConstants.amber.withValues(alpha: 0.2),
                    child: Text(
                      auth.user!.name[0].toUpperCase(),
                      style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppConstants.amber),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(auth.user!.name,
                          style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      Text(auth.user!.role.name.toUpperCase(),
                          style: GoogleFonts.montserrat(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.text3,
                              letterSpacing: 1)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            icon: const Icon(Icons.logout_outlined,
                size: 20, color: AppConstants.text2),
            tooltip: 'Çıkış yap',
            onPressed: () => _confirmLogout(context),
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
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
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
                        color: Colors.black54,
                        letterSpacing: 0.3)),
                const SizedBox(height: 3),
                Text(value,
                    style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87),
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
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: def.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(def.icon, size: 22, color: def.color),
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
                          color: Colors.black87)),
                  const SizedBox(height: 2),
                  Text(def.subtitle,
                      style: GoogleFonts.montserrat(
                          fontSize: 11, color: Colors.black45)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
