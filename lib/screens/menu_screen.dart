import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() =>
      _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  final _db = FirebaseFirestore.instance;
  String _selectedCategory = 'All';
  String _search = '';

  static const _defaultCategories = [
    'Başlangıçlar',
    'Ana Yemekler',
    'Yan Yemekler',
    'İçecekler',
    'Tatlılar',
  ];

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
        title: Text(
          'Menü Yönetimi',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          SizedBox(
            width: 240,
            child: TextField(
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              style: GoogleFonts.montserrat(
                  fontSize: 13, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ürün ara…',
                hintStyle: GoogleFonts.montserrat(
                    fontSize: 13, color: Colors.white54),
                prefixIcon: const Icon(Icons.search,
                    size: 18, color: Colors.white54),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.25)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.25)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: Colors.white, width: 1.5),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add, size: 16, color: Color(0xFF000052)),
            label: Text('Ürün Ekle',
                style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF000052))),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF000052),
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          SizedBox(width: 210, child: _buildCategoryPanel()),
          Expanded(child: _buildItemGrid()),
        ],
      ),
    );
  }

  Widget _buildCategoryPanel() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF000052),
        border: Border(
            right: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('menuItems').snapshots(),
        builder: (_, snap) {
          final counts = <String, int>{'All': 0};
          final catSet = <String>{'All'};
          if (snap.hasData) {
            for (final doc in snap.data!.docs) {
              final d = doc.data() as Map<String, dynamic>;
              final cat = d['category'] as String? ?? '';
              counts['All'] = (counts['All'] ?? 0) + 1;
              if (cat.isNotEmpty) {
                catSet.add(cat);
                counts[cat] = (counts[cat] ?? 0) + 1;
              }
            }
          }
          catSet.addAll(_defaultCategories);
          final list = ['All', ..._defaultCategories,
            ...catSet.where((c) => c != 'All' && !_defaultCategories.contains(c))];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: Text('KATEGORİLER',
                    style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: Colors.white54)),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final cat = list[i];
                    final active = _selectedCategory == cat;
                    final count = counts[cat] ?? 0;
                    return _buildCategoryTile(cat, active, count);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryTile(String cat, bool active, int count) {
    return InkWell(
      onTap: () => setState(() => _selectedCategory = cat),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: active
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: active ? Colors.white : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                cat == 'All' ? 'Tümü' : cat,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? Colors.white : Colors.white60,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (count > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: active
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: active
                        ? const Color(0xFF000052)
                        : Colors.white54,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemGrid() {
    Query query = _db.collection('menuItems');
    if (_selectedCategory != 'All') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (_, snap) {
        if (snap.hasError) {
          return Center(
            child: Text('Yükleme hatası',
                style: GoogleFonts.montserrat(
                    fontSize: 14, color: const Color(0xFFDC2626))),
          );
        }
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF000052)));
        }

        var docs = snap.data!.docs;
        docs.sort((a, b) {
          final na = ((a.data() as Map)['name'] as String? ?? '').toLowerCase();
          final nb = ((b.data() as Map)['name'] as String? ?? '').toLowerCase();
          return na.compareTo(nb);
        });

        if (_search.isNotEmpty) {
          docs = docs.where((d) {
            final name =
                ((d.data() as Map)['name'] as String? ?? '').toLowerCase();
            return name.contains(_search);
          }).toList();
        }

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.restaurant_menu_outlined,
                      size: 36, color: Color(0xFF1E40AF)),
                ),
                const SizedBox(height: 16),
                Text(
                  _search.isNotEmpty
                      ? '"$_search" için ürün bulunamadı'
                      : '$_selectedCategory kategorisinde ürün yok',
                  style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827)),
                ),
                const SizedBox(height: 6),
                Text('Yeni bir ürün ekleyerek başlayın',
                    style: GoogleFonts.montserrat(
                        fontSize: 13, color: const Color(0xFF1E40AF))),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _showAddDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text('Ürün Ekle',
                      style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111827),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _selectedCategory == 'All'
                        ? 'Tüm Ürünler'
                        : _selectedCategory,
                    style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827)),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF000052),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${docs.length}',
                        style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: LayoutBuilder(
                  builder: (_, constraints) {
                    final cols = constraints.maxWidth > 900
                        ? 4
                        : constraints.maxWidth > 600
                            ? 3
                            : 2;
                    return GridView.builder(
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.55,
                      ),
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final doc = docs[i];
                        final data = doc.data() as Map<String, dynamic>;
                        return _MenuItemCard(
                          docId: doc.id,
                          data: data,
                          db: _db,
                          onEdit: () => _showEditDialog(doc.id, data),
                          onDelete: () => _confirmDelete(
                              doc.id, data['name'] as String? ?? ''),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddDialog() => _showItemDialog();
  void _showEditDialog(String id, Map<String, dynamic> data) =>
      _showItemDialog(docId: id, existing: data);

  void _showItemDialog({String? docId, Map<String, dynamic>? existing}) {
    final isEdit = docId != null;
    final nameCtrl = TextEditingController(
        text: existing?['name'] as String? ?? '');
    final priceCtrl = TextEditingController(
        text: existing != null
            ? (existing['price'] as num?)?.toStringAsFixed(2) ?? ''
            : '');
    final descCtrl = TextEditingController(
        text: existing?['description'] as String? ?? '');
    String category =
        existing?['category'] as String? ?? _defaultCategories.first;
    bool saving = false;
    final formKey = GlobalKey<FormState>();

    final inputDecoration = InputDecoration(
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
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
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isEdit ? Icons.edit_outlined : Icons.add,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isEdit ? 'Ürün Düzenle' : 'Yeni Ürün Ekle',
                style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: const Color(0xFF111827)),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: nameCtrl,
                    autofocus: true,
                    style: GoogleFonts.montserrat(
                        fontSize: 14, color: const Color(0xFF111827)),
                    decoration:
                        inputDecoration.copyWith(labelText: 'Ürün Adı'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Zorunlu' : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _defaultCategories.contains(category)
                        ? category
                        : null,
                    decoration:
                        inputDecoration.copyWith(labelText: 'Kategori'),
                    dropdownColor: Colors.white,
                    style: GoogleFonts.montserrat(
                        fontSize: 14, color: const Color(0xFF111827)),
                    items: _defaultCategories
                        .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c,
                                style: GoogleFonts.montserrat(
                                    color: const Color(0xFF111827)))))
                        .toList(),
                    onChanged: (v) =>
                        setLocal(() => category = v ?? category),
                    validator: (v) => v == null ? 'Kategori seçin' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    style: GoogleFonts.montserrat(
                        fontSize: 14, color: const Color(0xFF111827)),
                    decoration: inputDecoration.copyWith(
                        labelText: 'Fiyat (TL)', prefixText: 'TL '),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Zorunlu';
                      if (double.tryParse(v.trim()) == null) {
                        return 'Geçerli bir sayı girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 2,
                    style: GoogleFonts.montserrat(
                        fontSize: 14, color: const Color(0xFF111827)),
                    decoration: inputDecoration.copyWith(
                      labelText: 'Açıklama (isteğe bağlı)',
                      hintText: 'Kısa açıklama…',
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: saving ? null : () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
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
                    onPressed: saving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setLocal(() => saving = true);
                            final payload = {
                              'name': nameCtrl.text.trim(),
                              'category': category,
                              'price': double.parse(priceCtrl.text.trim()),
                              'description':
                                  descCtrl.text.trim().isEmpty
                                      ? null
                                      : descCtrl.text.trim(),
                              if (!isEdit) 'isAvailable': true,
                              if (!isEdit) 'preparationTime': 10,
                              'updatedAt': FieldValue.serverTimestamp(),
                            };
                            if (isEdit) {
                              await _db
                                  .collection('menuItems')
                                  .doc(docId)
                                  .update(payload);
                            } else {
                              payload['createdAt'] =
                                  FieldValue.serverTimestamp();
                              await _db.collection('menuItems').add(payload);
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF111827),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            isEdit ? 'Kaydet' : 'Ürün Ekle',
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

  Future<void> _confirmDelete(String docId, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline,
                  size: 18, color: Color(0xFFDC2626)),
            ),
            const SizedBox(width: 12),
            Text('Ürünü Sil',
                style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: const Color(0xFF111827))),
          ],
        ),
        content: Text('"$name" menüden kalıcı olarak silinecek.',
            style: GoogleFonts.montserrat(
                fontSize: 14, color: const Color(0xFF6B7280))),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
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
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Sil',
                      style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (ok == true) {
      await _db.collection('menuItems').doc(docId).delete();
    }
  }
}

class _MenuItemCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final FirebaseFirestore db;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MenuItemCard({
    required this.docId,
    required this.data,
    required this.db,
    required this.onEdit,
    required this.onDelete,
  });

  static const _categoryColors = <String, Color>{
    'Başlangıçlar': Color(0xFFF97316),
    'Ana Yemekler': Color(0xFF2563EB),
    'Yan Yemekler': Color(0xFF16A34A),
    'İçecekler': Color(0xFF0891B2),
    'Tatlılar': Color(0xFFDB2777),
  };

  @override
  Widget build(BuildContext context) {
    final name = data['name'] as String? ?? '';
    final category = data['category'] as String? ?? '';
    final price = (data['price'] as num?)?.toDouble() ?? 0;
    final available = data['isAvailable'] as bool? ?? true;
    final desc = data['description'] as String?;
    final catColor =
        _categoryColors[category] ?? const Color(0xFF6B7280);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF000052),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 4,
              color: available ? catColor : const Color(0xFFE5E7EB),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _categoryIcon(category),
                            size: 20,
                            color: catColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (desc != null && desc.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  desc,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 11,
                                    color: Colors.white60,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TL ${price.toStringAsFixed(2)}',
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () => db
                                    .collection('menuItems')
                                    .doc(docId)
                                    .update({'isAvailable': !available}),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: available
                                        ? const Color(0xFF16A34A)
                                            .withValues(alpha: 0.2)
                                        : Colors.white.withValues(alpha: 0.1),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: available
                                              ? const Color(0xFF16A34A)
                                              : Colors.white54,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        available ? 'Mevcut' : 'Tükendi',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: available
                                              ? const Color(0xFF16A34A)
                                              : Colors.white54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            _ActionBtn(
                              icon: Icons.edit_outlined,
                              color: Colors.white70,
                              onTap: onEdit,
                            ),
                            const SizedBox(width: 6),
                            _ActionBtn(
                              icon: Icons.delete_outline,
                              color: const Color(0xFFDC2626),
                              onTap: onDelete,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Başlangıçlar':
        return Icons.soup_kitchen_outlined;
      case 'Ana Yemekler':
        return Icons.dinner_dining_outlined;
      case 'Yan Yemekler':
        return Icons.rice_bowl_outlined;
      case 'İçecekler':
        return Icons.local_drink_outlined;
      case 'Tatlılar':
        return Icons.cake_outlined;
      default:
        return Icons.restaurant_outlined;
    }
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
