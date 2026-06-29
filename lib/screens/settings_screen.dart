import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _tab = 0;
  final _db = FirebaseFirestore.instance;

  final _nameCtrl    = TextEditingController(text: 'Dijital Adisyon');
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
    final doc = await _db.collection('settings').doc('restaurant').get();
    if (doc.exists && mounted) {
      final d = doc.data()!;
      setState(() {
        _nameCtrl.text    = d['name'] ?? 'Dijital Adisyon';
        _addressCtrl.text = d['address'] ?? '';
        _phoneCtrl.text   = d['phone'] ?? '';
        _taxCtrl.text     = (d['taxPercent'] ?? 15).toString();
        _serviceCtrl.text = (d['servicePercent'] ?? 5).toString();
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

  InputDecoration get _inputDecoration => InputDecoration(
    filled: true,
    fillColor: const Color(0xFFF3F4F6),
    labelStyle:
        GoogleFonts.montserrat(color: const Color(0xFF9CA3AF), fontSize: 14),
    hintStyle:
        GoogleFonts.montserrat(color: const Color(0xFF9CA3AF), fontSize: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF111827), width: 1.5),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.user?.role != UserRole.admin) {
      return Scaffold(
        backgroundColor: const Color(0xFFDBEAFE),
        appBar: _buildAppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.lock_outline,
                    size: 30, color: Color(0xFF000052)),
              ),
              const SizedBox(height: 16),
              Text('Yönetici Erişimi Gerekli',
                  style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827))),
              const SizedBox(height: 6),
              Text('Bu sayfaya yalnızca yöneticiler erişebilir',
                  style: GoogleFonts.montserrat(
                      fontSize: 13, color: const Color(0xFF6B7280))),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFDBEAFE),
      appBar: _buildAppBar(),
      body: Row(
        children: [
          SizedBox(width: 230, child: _buildSidebar()),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF000052),
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: Colors.white),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ayarlar',
            style: GoogleFonts.montserrat(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            'Sistem yapılandırması',
            style: GoogleFonts.montserrat(
              fontSize: 11,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final tabs = [
      (Icons.people_outline, 'Kullanıcılar', 'Personel yönetimi'),
      (Icons.store_outlined, 'Restoran', 'Genel bilgiler'),
      (Icons.print_outlined, 'Fiş Ayarları', 'Yazdırma seçenekleri'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF000052),
        border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text('YÖNETİM PANELİ',
                style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: Colors.white54)),
          ),
          ...tabs.asMap().entries.map((e) {
            final active = _tab == e.key;
            final (icon, label, sub) = e.value;
            return InkWell(
              onTap: () => setState(() => _tab = e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: active
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.transparent,
                  border: Border(
                    left: BorderSide(
                      color: active
                          ? Colors.white
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white.withValues(alpha: 0.20)
                            : Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(icon,
                          size: 17,
                          color: active
                              ? Colors.white
                              : Colors.white60),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label,
                              style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  fontWeight: active
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: active
                                      ? Colors.white
                                      : Colors.white60)),
                          Text(sub,
                              style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  color: Colors.white54)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const Spacer(),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.12)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_outline,
                        size: 16, color: Color(0xFF16A34A)),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sistem Aktif',
                          style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                      Text('v1.0  ·  Dijital Adisyon',
                          style: GoogleFonts.montserrat(
                              fontSize: 10,
                              color: Colors.white54)),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kullanıcı Yönetimi',
                      style: GoogleFonts.montserrat(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827))),
                  const SizedBox(height: 2),
                  Text('Personel hesapları ve rollerini yönetin',
                      style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: const Color(0xFF6B7280))),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showRegisterDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF000052),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
                icon: const Icon(Icons.person_add_outlined, size: 16),
                label: Text('Personel Ekle',
                    style: GoogleFonts.montserrat(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE5E7EB)),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                _db.collection('users').orderBy('name').snapshots(),
            builder: (_, snap) {
              if (!snap.hasData) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF000052)));
              }

              final users = snap.data!.docs
                  .map((d) => AppUser.fromFirestore(
                      d.data() as Map<String, dynamic>))
                  .toList();

              if (users.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.people_outline,
                            size: 30, color: Color(0xFF9CA3AF)),
                      ),
                      const SizedBox(height: 14),
                      Text('Henüz kullanıcı yok',
                          style: GoogleFonts.montserrat(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF111827))),
                      const SizedBox(height: 6),
                      Text('Personel ekleyerek başlayın',
                          style: GoogleFonts.montserrat(
                              fontSize: 13,
                              color: const Color(0xFF6B7280))),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: users.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
              Icons.store_outlined,
              'Restoran Bilgileri',
              'Restoran detaylarınızı buradan güncelleyin'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
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
                Text('Temel Bilgiler',
                    style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827))),
                const SizedBox(height: 14),
                _field('Restoran Adı', _nameCtrl),
                const SizedBox(height: 12),
                _field('Adres', _addressCtrl, maxLines: 2),
                const SizedBox(height: 12),
                _field('Telefon Numarası', _phoneCtrl,
                    keyboard: TextInputType.phone),
                const SizedBox(height: 24),
                const Divider(color: Color(0xFFE5E7EB)),
                const SizedBox(height: 20),
                Text('Vergi ve Ücretler',
                    style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827))),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                        child: _field('Vergi Oranı (%)', _taxCtrl,
                            keyboard: TextInputType.number,
                            suffix: '%')),
                    const SizedBox(width: 14),
                    Expanded(
                        child: _field(
                            'Servis Ücreti (%)', _serviceCtrl,
                            keyboard: TextInputType.number,
                            suffix: '%')),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveInfo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF000052),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text('Değişiklikleri Kaydet',
                            style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w700,
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

  Widget _buildReceiptSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.print_outlined, 'Fiş Ayarları',
              'Yazdırma davranışını yapılandırın'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
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
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFF2563EB)
                            .withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: Color(0xFF2563EB)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Fiş yazıcınızı 80mm rulo için yapılandırın ve varsayılan yazıcı olarak ayarlayın.',
                          style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: const Color(0xFF2563EB)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('Yazdırma Seçenekleri',
                    style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827))),
                const SizedBox(height: 16),
                _receiptToggle(
                  Icons.receipt_outlined,
                  'Ödemede Fiş Yazdır',
                  'Ödeme tamamlandığında otomatik yazdırma açılır',
                  true,
                ),
                const Divider(height: 28, color: Color(0xFFE5E7EB)),
                _receiptToggle(
                  Icons.kitchen_outlined,
                  'Mutfak Bileti Yazdır',
                  'Sipariş verildiğinde mutfak biletini yazdırır',
                  false,
                ),
                const Divider(height: 28, color: Color(0xFFE5E7EB)),
                _receiptToggle(
                  Icons.calculate_outlined,
                  'Vergi Dökümünü Göster',
                  'Fişte KDV ve servis ücretini ayrı satırlarda göster',
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
      IconData icon, String title, String subtitle, bool value) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF000052).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF000052)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827))),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: GoogleFonts.montserrat(
                      fontSize: 11, color: const Color(0xFF6B7280))),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: (_) {},
          activeThumbColor: const Color(0xFF000052),
        ),
      ],
    );
  }

  Widget _sectionHeader(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF000052),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.montserrat(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827))),
            Text(subtitle,
                style: GoogleFonts.montserrat(
                    fontSize: 12, color: const Color(0xFF6B7280))),
          ],
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {TextInputType? keyboard, int maxLines = 1, String? suffix}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: GoogleFonts.montserrat(
          fontSize: 14, color: const Color(0xFF111827)),
      decoration: _inputDecoration.copyWith(
          labelText: label, suffixText: suffix),
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

    final inputDec = InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      labelStyle:
          GoogleFonts.montserrat(color: const Color(0xFF9CA3AF), fontSize: 14),
      hintStyle:
          GoogleFonts.montserrat(color: const Color(0xFF9CA3AF), fontSize: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: Color(0xFF111827), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: Color(0xFFDC2626), width: 1.5),
      ),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          actionsPadding:
              const EdgeInsets.fromLTRB(24, 16, 24, 20),
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_add_outlined,
                    size: 18, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text('Yeni Personel',
                  style: GoogleFonts.montserrat(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827))),
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
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: nameCtrl,
                    autofocus: true,
                    style: GoogleFonts.montserrat(
                        fontSize: 14, color: const Color(0xFF111827)),
                    decoration:
                        inputDec.copyWith(labelText: 'Ad Soyad'),
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
                        fontSize: 14, color: const Color(0xFF111827)),
                    decoration: inputDec.copyWith(
                        labelText: 'E-posta Adresi'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Zorunlu';
                      }
                      if (!v.contains('@')) {
                        return 'Geçerli e-posta girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordCtrl,
                    obscureText: obscure,
                    style: GoogleFonts.montserrat(
                        fontSize: 14, color: const Color(0xFF111827)),
                    decoration: inputDec.copyWith(
                      labelText: 'Şifre',
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                          color: const Color(0xFF9CA3AF),
                        ),
                        onPressed: () =>
                            setLocal(() => obscure = !obscure),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Zorunlu';
                      if (v.length < 6) return 'Min 6 karakter';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Text('ROL SEÇİN',
                      style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          color: const Color(0xFF9CA3AF))),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 3,
                    children: UserRole.values.map((role) {
                      final sel = selectedRole == role;
                      final color = _roleColor(role);
                      return GestureDetector(
                        onTap: () =>
                            setLocal(() => selectedRole = role),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel
                                ? color.withValues(alpha: 0.1)
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: sel
                                  ? color
                                  : const Color(0xFFE5E7EB),
                              width: sel ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(_roleIcon(role),
                                  size: 15,
                                  color: sel
                                      ? color
                                      : const Color(0xFF9CA3AF)),
                              const SizedBox(width: 8),
                              Text(
                                role.name.toUpperCase(),
                                style: GoogleFonts.montserrat(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: sel
                                        ? color
                                        : const Color(0xFF6B7280)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        loading ? null : () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(
                          color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('İptal',
                        style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B7280))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
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
                                    .showSnackBar(SnackBar(
                                  content: Text(ok
                                      ? '${nameCtrl.text.trim()} kaydedildi'
                                      : auth.error ?? 'Kayıt başarısız'),
                                  backgroundColor: ok
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFDC2626),
                                ));
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text('Hata: $e'),
                                  backgroundColor:
                                      const Color(0xFFDC2626),
                                ));
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF111827),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white),
                          )
                        : Text('Kaydet',
                            style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const Color(0xFFDC2626);
      case UserRole.manager:
        return const Color(0xFF2563EB);
      case UserRole.cashier:
        return const Color(0xFF16A34A);
      case UserRole.kitchen:
        return const Color(0xFFD97706);
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
      await _db.collection('settings').doc('restaurant').set({
        'name': _nameCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'taxPercent': double.tryParse(_taxCtrl.text.trim()) ?? 15,
        'servicePercent':
            double.tryParse(_serviceCtrl.text.trim()) ?? 5,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Restoran bilgileri kaydedildi')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: const Color(0xFFDC2626)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _UserCard extends StatelessWidget {
  final AppUser user;
  final FirebaseFirestore db;
  const _UserCard({required this.user, required this.db});

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const Color(0xFFDC2626);
      case UserRole.manager:
        return const Color(0xFF2563EB);
      case UserRole.cashier:
        return const Color(0xFF16A34A);
      case UserRole.kitchen:
        return const Color(0xFFD97706);
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

  @override
  Widget build(BuildContext context) {
    final roleColor = _roleColor(user.role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: GoogleFonts.montserrat(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: roleColor),
              ),
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
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827))),
                Text(user.email,
                    style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: const Color(0xFF9CA3AF))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: roleColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_roleIcon(user.role), size: 12, color: roleColor),
                const SizedBox(width: 5),
                Text(
                  user.role.name.toUpperCase(),
                  style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: roleColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              Text(
                user.isActive ? 'Aktif' : 'Pasif',
                style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: user.isActive
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF9CA3AF)),
              ),
              Switch(
                value: user.isActive,
                onChanged: (v) => db
                    .collection('users')
                    .doc(user.uid)
                    .update({'isActive': v}),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeThumbColor: const Color(0xFF000052),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
