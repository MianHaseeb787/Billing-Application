import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _tab = 0;
  final _db = FirebaseFirestore.instance;

  final _nameCtrl    = TextEditingController(text: 'DinO Dine');
  final _addressCtrl = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _taxCtrl     = TextEditingController(text: '15');
  final _serviceCtrl = TextEditingController(text: '5');
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final doc = await _db
        .collection('settings')
        .doc('restaurant')
        .get();
    if (doc.exists && mounted) {
      final d = doc.data()!;
      setState(() {
        _nameCtrl.text    = d['name'] ?? 'DinO Dine';
        _addressCtrl.text = d['address'] ?? '';
        _phoneCtrl.text   = d['phone'] ?? '';
        _taxCtrl.text     = (d['taxPercent'] ?? 15).toString();
        _serviceCtrl.text =
            (d['servicePercent'] ?? 5).toString();
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _taxCtrl.dispose();
    _serviceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.user?.role != UserRole.admin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ayarlar')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline,
                  size: 48, color: AppConstants.text3),
              const SizedBox(height: 14),
              Text('Yalnızca yönetici erişimi',
                  style: GoogleFonts.montserrat(
                      fontSize: 15, color: AppConstants.text2)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppConstants.bg,
      appBar: AppBar(title: const Text('Ayarlar')),
      body: Row(
        children: [
          SizedBox(width: 220, child: _buildSidebar()),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    const tabs = [
      (Icons.people_outline, 'Kullanıcı Yönetimi'),
      (Icons.store_outlined, 'Restoran Bilgileri'),
      (Icons.print_outlined, 'Fiş Ayarları'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppConstants.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
            child: Text('YÖNETİM',
                style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: AppConstants.text3)),
          ),
          ...tabs.asMap().entries.map((e) {
            final active = _tab == e.key;
            final (icon, label) = e.value;
            return InkWell(
              onTap: () => setState(() => _tab = e.key),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: active
                      ? AppConstants.amber
                          .withValues(alpha: 0.08)
                      : Colors.transparent,
                  border: Border(
                    left: BorderSide(
                      color: active
                          ? AppConstants.amber
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(icon,
                        size: 18,
                        color: active
                            ? AppConstants.amber
                            : AppConstants.text2),
                    const SizedBox(width: 12),
                    Text(label,
                        style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: active
                                ? AppConstants.amber
                                : AppConstants.text2)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_tab) {
      case 0:
        return _buildUserManagement();
      case 1:
        return _buildRestaurantInfo();
      case 2:
        return _buildReceiptSettings();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildUserManagement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kullanıcı Yönetimi',
                      style: GoogleFonts.montserrat(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppConstants.text1)),
                  const SizedBox(height: 2),
                  Text('Personel hesapları ve rolleri yönetin',
                      style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: AppConstants.text3)),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () =>
                    _showRegisterDialog(context),
                icon: const Icon(
                    Icons.person_add_outlined,
                    size: 16),
                label: Text('Üye Ekle',
                    style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('users')
                .orderBy('name')
                .snapshots(),
            builder: (_, snap) {
              if (!snap.hasData) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: AppConstants.amber));
              }

              final users = snap.data!.docs
                  .map((d) => AppUser.fromFirestore(
                      d.data() as Map<String, dynamic>))
                  .toList();

              if (users.isEmpty) {
                return Center(
                  child: Text('Kullanıcı bulunamadı',
                      style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: AppConstants.text3)),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: users.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 8),
                itemBuilder: (_, i) =>
                    _UserCard(user: users[i], db: _db),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRestaurantInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Restoran Bilgileri',
              'Restoran detaylarınızı yapılandırın'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(24),
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
              children: [
                _field('Restoran Adı', _nameCtrl),
                const SizedBox(height: 14),
                _field('Adres', _addressCtrl, maxLines: 2),
                const SizedBox(height: 14),
                _field('Telefon Numarası', _phoneCtrl,
                    keyboard: TextInputType.phone),
                const SizedBox(height: 20),
                const Divider(color: AppConstants.border),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Vergi ve Servis Oranları',
                      style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.text1)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _field('Vergi Oranı (%)',
                            _taxCtrl,
                            keyboard:
                                TextInputType.number,
                            suffix: '%')),
                    const SizedBox(width: 14),
                    Expanded(
                        child: _field(
                            'Servis Ücreti (%)',
                            _serviceCtrl,
                            keyboard:
                                TextInputType.number,
                            suffix: '%')),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveInfo,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black),
                          )
                        : Text('Değişiklikleri Kaydet',
                            style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRegisterDialog(BuildContext context) {
    final nameCtrl     = TextEditingController();
    final emailCtrl    = TextEditingController();
    final passwordCtrl = TextEditingController();
    final formKey      = GlobalKey<FormState>();
    UserRole selectedRole = UserRole.cashier;
    bool obscure = true;
    bool loading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppConstants.amber
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person_add_outlined,
                    size: 18, color: AppConstants.amber),
              ),
              const SizedBox(width: 12),
              Text('Personel Kaydet',
                  style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.text1)),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    autofocus: true,
                    style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: AppConstants.text1),
                    decoration: const InputDecoration(
                        labelText: 'Ad Soyad'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Zorunlu';
                      }
                      if (v.trim().length < 3) {
                        return 'En az 3 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: AppConstants.text1),
                    decoration: const InputDecoration(
                        labelText: 'E-posta Adresi'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Zorunlu';
                      }
                      if (!v.contains('@')) {
                        return 'Geçerli bir e-posta girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordCtrl,
                    obscureText: obscure,
                    style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: AppConstants.text1),
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure
                              ? Icons
                                  .visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                          color: AppConstants.text3,
                        ),
                        onPressed: () =>
                            setLocal(() => obscure = !obscure),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Zorunlu';
                      }
                      if (v.length < 6) {
                        return 'Minimum 6 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  Text('Rol',
                      style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.text2)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        UserRole.values.map((role) {
                      final sel = selectedRole == role;
                      final color = _roleColor(role);
                      return GestureDetector(
                        onTap: () => setLocal(
                            () => selectedRole = role),
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 9),
                          decoration: BoxDecoration(
                            color: sel
                                ? color
                                    .withValues(alpha: 0.12)
                                : AppConstants.surface2,
                            borderRadius:
                                BorderRadius.circular(8),
                            border: Border.all(
                              color: sel
                                  ? color
                                  : AppConstants.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_roleIcon(role),
                                  size: 14,
                                  color: sel
                                      ? color
                                      : AppConstants.text3),
                              const SizedBox(width: 6),
                              Text(
                                role.name.toUpperCase(),
                                style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight.w600,
                                    color: sel
                                        ? color
                                        : AppConstants
                                            .text2),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  loading ? null : () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }
                      setLocal(() => loading = true);
                      try {
                        final auth =
                            context.read<AuthProvider>();
                        final ok = await auth.signUp(
                          emailCtrl.text.trim(),
                          passwordCtrl.text,
                          nameCtrl.text.trim(),
                          selectedRole,
                        );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            SnackBar(
                              content: Text(ok
                                  ? '${nameCtrl.text.trim()} başarıyla kaydedildi'
                                  : auth.error ??
                                      'Kayıt başarısız'),
                              backgroundColor: ok
                                  ? AppConstants.green
                                  : AppConstants.red,
                            ),
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            SnackBar(
                                content: Text('Hata: $e'),
                                backgroundColor:
                                    AppConstants.red),
                          );
                        }
                      }
                    },
              child: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black),
                    )
                  : const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return AppConstants.red;
      case UserRole.manager:
        return AppConstants.blue;
      case UserRole.cashier:
        return AppConstants.green;
      case UserRole.kitchen:
        return AppConstants.yellow;
    }
  }

  IconData _roleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings_outlined;
      case UserRole.manager:
        return Icons.manage_accounts_outlined;
      case UserRole.cashier:
        return Icons.point_of_sale_outlined;
      case UserRole.kitchen:
        return Icons.kitchen_outlined;
    }
  }

  Future<void> _saveInfo() async {
    setState(() => _saving = true);
    try {
      await _db
          .collection('settings')
          .doc('restaurant')
          .set({
        'name': _nameCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'taxPercent':
            double.tryParse(_taxCtrl.text.trim()) ?? 15,
        'servicePercent':
            double.tryParse(_serviceCtrl.text.trim()) ?? 5,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Restoran bilgileri kaydedildi')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppConstants.red));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildReceiptSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Fiş Ayarları',
              'Fişlerin nasıl yazdırılacağını yapılandırın'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(24),
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: AppConstants.text3),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Fiş yazdırma, sistem yazdırma iletişim kutusunu kullanır. '
                        'Fiş yazıcınızı varsayılan olarak ayarlayın ve '
                        '80mm rulo formatını desteklediğinden emin olun.',
                        style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: AppConstants.text3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: AppConstants.border),
                const SizedBox(height: 16),
                _receiptToggle(
                  'Ödemede Fiş Yazdır',
                  'Ödemeden sonra yazdırma iletişim kutusunu otomatik açar',
                  true,
                ),
                const SizedBox(height: 14),
                _receiptToggle(
                  'Mutfak Bileti Yazdır',
                  'Sipariş verildiğinde mutfağa bilet yazdırır',
                  false,
                ),
                const SizedBox(height: 14),
                _receiptToggle(
                  'Vergi Dökümünü Göster',
                  'Vergi ve servis ücretini ayrı göster',
                  true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptToggle(
      String title, String subtitle, bool value) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppConstants.text1)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: AppConstants.text3)),
            ],
          ),
        ),
        Switch(value: value, onChanged: (_) {}),
      ],
    );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.montserrat(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppConstants.text1)),
        const SizedBox(height: 2),
        Text(subtitle,
            style: GoogleFonts.montserrat(
                fontSize: 12, color: AppConstants.text3)),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    TextInputType? keyboard,
    int maxLines = 1,
    String? suffix,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      style:
          GoogleFonts.montserrat(fontSize: 14, color: AppConstants.text1),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final AppUser user;
  final FirebaseFirestore db;
  const _UserCard({required this.user, required this.db});

  @override
  Widget build(BuildContext context) {
    final roleColor = _roleColor(user.role);

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          CircleAvatar(
            radius: 20,
            backgroundColor: roleColor.withValues(alpha: 0.14),
            child: Text(
              user.name.isNotEmpty
                  ? user.name[0].toUpperCase()
                  : '?',
              style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: roleColor),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.text1)),
                Text(user.email,
                    style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: AppConstants.text3)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                  color: roleColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              user.role.name.toUpperCase(),
              style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: roleColor),
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              Text(
                user.isActive ? 'Aktif' : 'Pasif',
                style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: user.isActive
                        ? AppConstants.green
                        : AppConstants.text3),
              ),
              const SizedBox(width: 6),
              Switch(
                value: user.isActive,
                onChanged: (v) => db
                    .collection('users')
                    .doc(user.uid)
                    .update({'isActive': v}),
                materialTapTargetSize:
                    MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return AppConstants.red;
      case UserRole.manager:
        return AppConstants.blue;
      case UserRole.cashier:
        return AppConstants.green;
      case UserRole.kitchen:
        return AppConstants.yellow;
    }
  }
}
