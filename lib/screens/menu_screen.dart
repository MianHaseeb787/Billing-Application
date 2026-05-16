import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

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
    'Başlangıçlar', 'Ana Yemekler', 'Yan Yemekler', 'İçecekler', 'Tatlılar',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.bg,
      appBar: AppBar(
        title: const Text('Menü Yönetimi'),
        actions: [
          SizedBox(
            width: 220,
            child: TextField(
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              style: GoogleFonts.montserrat(
                  fontSize: 13, color: AppConstants.text1),
              decoration: InputDecoration(
                hintText: 'Ürün ara…',
                hintStyle: GoogleFonts.montserrat(
                    fontSize: 13, color: AppConstants.text3),
                prefixIcon: const Icon(Icons.search,
                    size: 16, color: AppConstants.text3),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: AppConstants.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: AppConstants.border),
                ),
                filled: true,
                fillColor: AppConstants.surface2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add,
                size: 16, color: AppConstants.amber),
            label: Text('Ürün Ekle',
                style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppConstants.amber)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          SizedBox(width: 200, child: _buildCategoryPanel()),
          Expanded(child: _buildItemList()),
        ],
      ),
    );
  }

  // ── Category sidebar ─────────────────────────────────────────────────────

  Widget _buildCategoryPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppConstants.border)),
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
          final list = catSet.toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('KATEGORİLER',
                    style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        color: AppConstants.text3)),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 12),
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
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: active
              ? AppConstants.amber.withValues(alpha: 0.08)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color:
                  active ? AppConstants.amber : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                cat,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight:
                      active ? FontWeight.w600 : FontWeight.normal,
                  color: active
                      ? AppConstants.amber
                      : AppConstants.text2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: active
                      ? AppConstants.amber.withValues(alpha: 0.15)
                      : AppConstants.surface2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: active
                        ? AppConstants.amber
                        : AppConstants.text3,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Item list ────────────────────────────────────────────────────────────

  Widget _buildItemList() {
    // No .orderBy() here — combining where+orderBy requires a composite
    // Firestore index. Sort client-side instead.
    Query query = _db.collection('menuItems');
    if (_selectedCategory != 'All') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (_, snap) {
        if (snap.hasError) {
          return Center(
            child: Text('Error loading items',
                style: GoogleFonts.montserrat(
                    fontSize: 14, color: AppConstants.red)),
          );
        }
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(
                  color: AppConstants.amber));
        }

        var docs = snap.data!.docs;
        // Client-side sort by name
        docs.sort((a, b) {
          final na = ((a.data() as Map<String, dynamic>)['name']
                      as String? ??
                  '')
              .toLowerCase();
          final nb = ((b.data() as Map<String, dynamic>)['name']
                      as String? ??
                  '')
              .toLowerCase();
          return na.compareTo(nb);
        });

        if (_search.isNotEmpty) {
          docs = docs.where((d) {
            final name = ((d.data() as Map<String, dynamic>)['name']
                        as String? ??
                    '')
                .toLowerCase();
            return name.contains(_search);
          }).toList();
        }

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.restaurant_menu_outlined,
                    size: 52, color: AppConstants.text3),
                const SizedBox(height: 12),
                Text('$_selectedCategory kategorisinde ürün yok',
                    style: GoogleFonts.montserrat(
                        fontSize: 14, color: AppConstants.text2)),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: _showAddDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('İlk Ürünü Ekle'),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppConstants.cardRadius),
              boxShadow: [
                BoxShadow(
                  color: AppConstants.purple.withValues(alpha: 0.10),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.cardRadius),
              child: Column(
                children: [
                  // Table header
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    decoration: BoxDecoration(
                      color: AppConstants.purple.withValues(alpha: 0.06),
                      border: const Border(
                          bottom: BorderSide(color: AppConstants.border)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 3),
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 17),
                            child: Text('ÜRÜN',
                                style: GoogleFonts.montserrat(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: AppConstants.purple)),
                          ),
                        ),
                        SizedBox(
                          width: 110,
                          child: Text('KATEGORİ',
                              style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: AppConstants.purple)),
                        ),
                        SizedBox(
                          width: 88,
                          child: Text('FİYAT',
                              textAlign: TextAlign.right,
                              style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: AppConstants.purple)),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 56,
                          child: Text('DURUM',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: AppConstants.purple)),
                        ),
                        const SizedBox(width: 64),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, color: AppConstants.border),
                      itemBuilder: (_, i) {
                        final doc = docs[i];
                        final data = doc.data() as Map<String, dynamic>;
                        return _MenuItemRow(
                          docId: doc.id,
                          data: data,
                          db: _db,
                          onEdit: () => _showEditDialog(doc.id, data),
                          onDelete: () => _confirmDelete(
                              doc.id, data['name'] as String? ?? ''),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Dialogs ──────────────────────────────────────────────────────────────

  void _showAddDialog() => _showItemDialog();
  void _showEditDialog(String id, Map<String, dynamic> data) =>
      _showItemDialog(docId: id, existing: data);

  void _showItemDialog(
      {String? docId, Map<String, dynamic>? existing}) {
    final isEdit    = docId != null;
    final nameCtrl  = TextEditingController(
        text: existing?['name'] as String? ?? '');
    final priceCtrl = TextEditingController(
        text: existing != null
            ? (existing['price'] as num?)?.toStringAsFixed(2) ?? ''
            : '');
    final descCtrl  = TextEditingController(
        text: existing?['description'] as String? ?? '');
    String category =
        existing?['category'] as String? ?? _defaultCategories.first;
    bool saving = false;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(isEdit ? 'Ürün Düzenle' : 'Menü Ürünü Ekle',
              style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                  color: AppConstants.text1)),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    autofocus: true,
                    style: GoogleFonts.montserrat(
                        fontSize: 14, color: AppConstants.text1),
                    decoration: const InputDecoration(
                        labelText: 'Ürün Adı'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Zorunlu'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _defaultCategories.contains(category)
                        ? category
                        : null,
                    decoration: const InputDecoration(
                        labelText: 'Kategori'),
                    dropdownColor: AppConstants.surface2,
                    style: GoogleFonts.montserrat(
                        fontSize: 14, color: AppConstants.text1),
                    items: _defaultCategories
                        .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c,
                                style: GoogleFonts.montserrat(
                                    color: AppConstants.text1))))
                        .toList(),
                    onChanged: (v) =>
                        setLocal(() => category = v ?? category),
                    validator: (v) =>
                        v == null ? 'Kategori seçin' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    style: GoogleFonts.montserrat(
                        fontSize: 14, color: AppConstants.text1),
                    decoration: const InputDecoration(
                        labelText: 'Fiyat (TL)',
                        prefixText: 'TL '),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Zorunlu';
                      }
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
                        fontSize: 14, color: AppConstants.text1),
                    decoration: const InputDecoration(
                      labelText: 'Açıklama (isteğe bağlı)',
                      hintText: 'Kısa açıklama…',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed:
                    saving ? null : () => Navigator.pop(ctx),
                child: const Text('İptal')),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setLocal(() => saving = true);

                      final payload = {
                        'name': nameCtrl.text.trim(),
                        'category': category,
                        'price':
                            double.parse(priceCtrl.text.trim()),
                        'description': descCtrl.text.trim().isEmpty
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
                        await _db
                            .collection('menuItems')
                            .add(payload);
                      }

                      if (ctx.mounted) Navigator.pop(ctx);
                    },
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                  : Text(isEdit ? 'Değişiklikleri Kaydet' : 'Ürün Ekle'),
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
        title: Text('Ürünü Sil',
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                color: AppConstants.text1)),
        content: Text('"$name" menüden kaldırılsın mı?',
            style: GoogleFonts.montserrat(color: AppConstants.text2)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.red,
                foregroundColor: Colors.white),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _db.collection('menuItems').doc(docId).delete();
    }
  }
}

// ── Menu item row ─────────────────────────────────────────────────────────────

class _MenuItemRow extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final FirebaseFirestore db;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _MenuItemRow(
      {required this.docId,
      required this.data,
      required this.db,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final name      = data['name'] as String? ?? '';
    final category  = data['category'] as String? ?? '';
    final price     = (data['price'] as num?)?.toDouble() ?? 0;
    final available = data['isAvailable'] as bool? ?? true;
    final desc      = data['description'] as String?;

    return Container(
      color: Colors.white,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // Availability accent bar
          Container(
            width: 3,
            color: available ? AppConstants.green : AppConstants.red,
          ),
          // Name + description
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(17, 14, 8, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(name,
                      style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.text1)),
                  if (desc != null && desc.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(desc,
                        style: GoogleFonts.montserrat(
                            fontSize: 11,
                            color: AppConstants.text3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
          ),
          // Category badge
          SizedBox(
            width: 110,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppConstants.surface2,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppConstants.border),
                  ),
                  child: Text(category,
                      style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: AppConstants.text2,
                          fontWeight: FontWeight.w500)),
                ),
              ),
            ),
          ),
          // Price
          SizedBox(
            width: 88,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 14),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('TL ${price.toStringAsFixed(2)}',
                    style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.amber)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Status toggle
          SizedBox(
            width: 56,
            child: Center(
              child: GestureDetector(
                onTap: () => db
                    .collection('menuItems')
                    .doc(docId)
                    .update({'isAvailable': !available}),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: available
                        ? AppConstants.green.withValues(alpha: 0.12)
                        : AppConstants.surface2,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: available
                          ? AppConstants.green.withValues(alpha: 0.4)
                          : AppConstants.border,
                    ),
                  ),
                  child: Text(
                    available ? 'AÇIK' : 'KAPALI',
                    style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: available
                            ? AppConstants.green
                            : AppConstants.text3),
                  ),
                ),
              ),
            ),
          ),
          // Edit / Delete
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onEdit,
                  child: const Icon(Icons.edit_outlined,
                      size: 16, color: AppConstants.text2),
                ),
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(Icons.delete_outline,
                      size: 16, color: AppConstants.red),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}
