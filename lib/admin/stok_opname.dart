// stok_opname.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:Project_SPA/function/ip_address.dart';
import 'package:cherry_toast/cherry_toast.dart';

class StokOpnameController extends GetxController {
  final dio = Dio();

  /// Semua item gabungan dari backend /opname/getmasternama
  /// Elemen: { 'nama': String, 'sumber': 'barang'|'menu_produk'|'menu_fnb', 'stok': int, 'satuan': String }
  final RxList<Map<String, dynamic>> allItems = <Map<String, dynamic>>[].obs;

  // Pencarian & pilihan
  final RxString query = ''.obs;
  final Rxn<Map<String, dynamic>> selectedItem = Rxn<Map<String, dynamic>>();

  // Form
  final qtyC = TextEditingController();
  final noteC = TextEditingController(); // dipakai untuk catatan BATCH
  final searchC = TextEditingController();

  // Qty reaktif agar preview update saat mengetik
  final RxString qtyText = ''.obs;

  // Mode opname: true = Tambah, false = Kurangi
  final RxBool isAdd = true.obs;

  // ====== Batch state ======
  // Elemen: { 'nama','sumber','satuan','perubahan','stok_sekarang' }
  final RxList<Map<String, dynamic>> batchItems = <Map<String, dynamic>>[].obs;
  final RxBool isSaving = false.obs;
  final RxBool isLoadingMaster = false.obs;

  String get _base => myIpAddr().replaceAll(RegExp(r"/$"), "");
  String _ts() => DateTime.now().millisecondsSinceEpoch.toString();

  Options get _noCache => Options(
    headers: const {
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    },
  );

  // ====== Derivations ======
  List<Map<String, dynamic>> get _filteredAll {
    final q = query.value.trim().toLowerCase();
    if (q.isEmpty) return allItems;
    return allItems.where((e) {
      final n = (e['nama'] ?? '').toString().toLowerCase();
      final s = (e['sumber'] ?? '').toString().toLowerCase();
      final u = (e['satuan'] ?? '').toString().toLowerCase();
      return n.contains(q) || s.contains(q) || u.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get barangItems =>
      _filteredAll.where((e) => (e['sumber'] ?? '') == 'barang').toList();

  List<Map<String, dynamic>> get produkItems =>
      _filteredAll.where((e) => (e['sumber'] ?? '') == 'menu_produk').toList();

  List<Map<String, dynamic>> get fnbItems =>
      _filteredAll.where((e) => (e['sumber'] ?? '') == 'menu_fnb').toList();

  int get stokLama {
    final it = selectedItem.value;
    if (it == null) return 0;
    final v = it['stok'];
    if (v is int) return v;
    return int.tryParse('$v') ?? 0;
  }

  // Qty dibaca dari qtyText agar Obx reaktif
  int get qty => int.tryParse(qtyText.value.trim()) ?? 0;

  int get stokBaru {
    if (selectedItem.value == null) return 0;
    if (qty <= 0) return stokLama;
    final calc = isAdd.value ? (stokLama + qty) : (stokLama - qty);
    return calc < 0 ? 0 : calc; // cegah negatif
  }

  // Ringkasan batch
  int get totalBaris => batchItems.length;
  int get totalPenambahan =>
      batchItems.fold<int>(0, (a, b) => a + ((b['perubahan'] as int) > 0 ? (b['perubahan'] as int) : 0));
  int get totalPengurangan =>
      batchItems.fold<int>(0, (a, b) => a + ((b['perubahan'] as int) < 0 ? -(b['perubahan'] as int) : 0));
  int get totalNet => batchItems.fold<int>(0, (a, b) => a + (b['perubahan'] as int));

  // ====== Lifecycle ======
  @override
  void onInit() {
    super.onInit();
    fetchMasterGabungan();
    qtyText.value = qtyC.text; // sinkron awal (jika ada preset)
  }

  @override
  void onClose() {
    qtyC.dispose();
    noteC.dispose();
    searchC.dispose();
    super.onClose();
  }

  // ====== APIs ======
  Future<void> fetchMasterGabungan() async {
    isLoadingMaster.value = true;
    try {
      final res = await dio.get('$_base/opname/getmasternama?_ts=${_ts()}', options: _noCache);
      final data = res.data;
      if (data is List) {
        // Normalisasi field agar selalu ada 'satuan'
        final list =
            data.map<Map<String, dynamic>>((e) {
              final satuan = (e['satuan'] ?? '').toString().trim();
              return {
                'nama': e['nama'],
                'sumber': e['sumber'],
                'stok': e['stok'] ?? 0,
                'satuan': (satuan.isNotEmpty ? satuan : 'pcs'), // fallback pcs bila kosong
              };
            }).toList();
        allItems.assignAll(list);
      } else {
        allItems.assignAll([]);
      }
    } catch (e) {
      final ctx = Get.context;
      if (ctx != null) {
        CherryToast.error(
          title: const Text('Error'),
          description: Text('Gagal mengambil master gabungan: $e'),
        ).show(ctx);
      }
    } finally {
      isLoadingMaster.value = false;
    }
  }

  // ====== Mutations ======
  void setQuery(String q) => query.value = q;

  void pilihItem(Map<String, dynamic> it) {
    selectedItem.value = Map<String, dynamic>.from(it);
  }

  void _toastSuccess(String title, String desc) {
    final ctx = Get.context;
    if (ctx != null) {
      CherryToast.success(title: Text(title), description: Text(desc)).show(ctx);
    }
  }

  void _toastWarning(String title, String desc) {
    final ctx = Get.context;
    if (ctx != null) {
      CherryToast.warning(title: Text(title), description: Text(desc)).show(ctx);
    }
  }

  void _toastError(String title, String desc) {
    final ctx = Get.context;
    if (ctx != null) {
      CherryToast.error(title: Text(title), description: Text(desc)).show(ctx);
    }
  }

  void clearForm({bool keepSelection = true}) {
    qtyC.clear();
    qtyText.value = '';
    if (!keepSelection) {
      selectedItem.value = null;
    }
  }

  // ====== ADD to batch (dari form kanan) ======
  void addToBatch() {
    final it = selectedItem.value;
    if (it == null) {
      _toastWarning('Validasi', 'Pilih item terlebih dahulu');
      return;
    }
    if (qty <= 0) {
      _toastWarning('Validasi', 'Jumlah harus lebih dari 0');
      return;
    }

    final perubahan = isAdd.value ? qty : -qty;

    // Jika item sama (nama+sumber) sudah ada, gabungkan quantity
    final idx = batchItems.indexWhere((e) => e['nama'] == it['nama'] && e['sumber'] == it['sumber']);
    if (idx >= 0) {
      final merged = Map<String, dynamic>.from(batchItems[idx]);
      merged['perubahan'] = (merged['perubahan'] as int) + perubahan;
      batchItems[idx] = merged;
    } else {
      batchItems.add({
        'nama': it['nama'],
        'sumber': it['sumber'],
        'satuan': it['satuan'] ?? 'pcs',
        'perubahan': perubahan,
        'stok_sekarang': it['stok'] ?? 0,
      });
    }
    batchItems.refresh();

    // Bersihkan form agar siap input berikutnya
    clearForm(keepSelection: false);

    _toastSuccess('Ditambahkan', 'Item masuk ke daftar batch.');
  }

  void removeFromBatch(int index) {
    if (index < 0 || index >= batchItems.length) return;
    batchItems.removeAt(index);
    batchItems.refresh();
  }

  // ====== SAVE batch ke backend ======
  Future<void> saveBatch() async {
    if (batchItems.isEmpty) {
      _toastWarning('Validasi', 'Daftar batch masih kosong');
      return;
    }

    isSaving.value = true;
    try {
      final body = {
        "note": noteC.text.trim().isEmpty ? null : noteC.text.trim(),
        "items":
            batchItems
                .map(
                  (e) => {
                    "sumber": e["sumber"],
                    "nama": e["nama"],
                    "perubahan": e["perubahan"],
                    "satuan": e["satuan"], // opsional, backend punya default/meta
                  },
                )
                .toList(),
      };

      final res = await dio.post('$_base/opname/simpan-batch', data: body);
      final ok = res.data is Map && (res.data["status"] == "OK");

      if (!ok) {
        _toastError('Gagal', 'Simpan batch gagal: ${res.data}');
        return;
      }

      // Refresh master stok
      await fetchMasterGabungan();

      // Kosongkan batch & form
      final jml = int.tryParse('${res.data['jumlah_baris'] ?? batchItems.length}') ?? batchItems.length;
      final plus = totalPenambahan;
      final minus = totalPengurangan;
      final net = totalNet;

      batchItems.clear();
      noteC.clear();
      clearForm(keepSelection: false);

      _toastSuccess(
        'Sukses Menyimpan',
        'Batch opname tersimpan ($jml baris).\nΔ+: $plus, Δ-: $minus, Net: $net',
      );
    } catch (e) {
      _toastError('Error', 'Gagal menyimpan batch: $e');
    } finally {
      isSaving.value = false;
    }
  }

  // ====== (Opsional) Single submit lama — masih tersedia jika ingin pakai ======
  Future<void> submitSingle() async {
    final it = selectedItem.value;
    if (it == null) {
      _toastWarning('Validasi', 'Pilih item terlebih dahulu');
      return;
    }
    if (qty <= 0) {
      _toastWarning('Validasi', 'Jumlah harus lebih dari 0');
      return;
    }

    final perubahan = isAdd.value ? qty : -qty;

    try {
      final body = {
        "note": noteC.text.trim().isEmpty ? null : noteC.text.trim(),
        "sumber": it["sumber"], // 'barang' | 'menu_produk' | 'menu_fnb'
        "nama": it["nama"],
        "perubahan": perubahan,
        "satuan": it["satuan"] ?? "pcs",
      };

      final res = await dio.post('$_base/opname/simpan', data: body);
      final ok = res.data is Map && (res.data["status"] == "OK");
      if (!ok) {
        _toastError('Gagal', 'Simpan opname gagal: ${res.data}');
        return;
      }

      // Ambil stok_awal & stok_akhir dari backend untuk akurasi toast
      final itemResp = (res.data["item"] ?? {}) as Map;
      final int stokAwalResp = int.tryParse("${itemResp["stok_awal"] ?? 0}") ?? 0;
      final int stokAkhirResp = int.tryParse("${itemResp["stok_akhir"] ?? 0}") ?? 0;

      // Sinkron list allItems
      final idx = allItems.indexWhere((e) => (e['sumber'] == it['sumber']) && (e['nama'] == it['nama']));
      if (idx >= 0) {
        final copy = Map<String, dynamic>.from(allItems[idx]);
        copy['stok'] = stokAkhirResp;
        allItems[idx] = copy;
        allItems.refresh();
      }

      selectedItem.value = {...it, 'stok': stokAkhirResp};

      CherryToast.success(
        title: const Text('Sukses Menyimpan'),
        description: Text(
          'Opname ${it["nama"]} '
          '${perubahan >= 0 ? "bertambah" : "berkurang"} ${perubahan.abs()}\n'
          '(${stokAwalResp} → ${stokAkhirResp} ${it["satuan"] ?? "pcs"})',
        ),
      ).show(Get.context!);

      // reset qty & note
      qtyC.clear();
      qtyText.value = '';
      // noteC tidak di-clear agar bisa lanjut single beberapa kali dgn catatan sama
    } catch (e) {
      _toastError('Gagal', 'Gagal menyimpan stok opname: $e');
    }
  }
}

class StokOpnamePage extends StatelessWidget {
  StokOpnamePage({super.key});

  final c = Get.put(StokOpnameController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE0B2),
      appBar: AppBar(
        title: const Text('Stok Opname', style: TextStyle(fontFamily: 'Poppins', fontSize: 24)),
        backgroundColor: const Color(0xFFFFE0B2),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () async => c.fetchMasterGabungan(),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, cons) {
            final isWide = cons.maxWidth >= 1000;
            return Padding(
              padding: const EdgeInsets.all(12),
              child:
                  isWide
                      ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Kiri: Daftar (lebih ramping)
                          Expanded(flex: 5, child: _panelDaftar(context)),
                          const SizedBox(width: 12),
                          // Kanan: Form + Batch
                          Expanded(flex: 7, child: _panelBatch(context)),
                        ],
                      )
                      : SingleChildScrollView(
                        child: Column(
                          children: [_panelDaftar(context), const SizedBox(height: 12), _panelBatch(context)],
                        ),
                      ),
            );
          },
        ),
      ),
    );
  }

  // =======================
  // Panel kiri: pilih item
  // =======================
  Widget _panelDaftar(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined),
                const SizedBox(width: 8),
                const Text('Pilih Barang/Menu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const Spacer(),
                Obx(() => Text('Total: ${c.allItems.length}', style: const TextStyle(color: Colors.brown))),
              ],
            ),
            const SizedBox(height: 10),

            // Search (nama / satuan / sumber)
            Obx(() {
              final hasText = c.query.value.trim().isNotEmpty;
              return TextField(
                controller: c.searchC,
                onChanged: c.setQuery,
                decoration: InputDecoration(
                  hintText: 'Cari (nama / satuan / sumber)',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      hasText
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              c.searchC.clear();
                              c.setQuery('');
                            },
                          )
                          : null,
                  filled: true,
                  isDense: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }),
            const SizedBox(height: 10),

            // ====== LIST DIPISAH MENJADI 3 SECTION ======
            Expanded(
              child: Obx(() {
                if (c.isLoadingMaster.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                final barang = c.barangItems;
                final produk = c.produkItems;
                final fnb = c.fnbItems;

                if (barang.isEmpty && produk.isEmpty && fnb.isEmpty) {
                  return const Center(child: Text('Tidak ada data'));
                }

                return Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: const Color(0xFFBCAAA4),
                    listTileTheme: ListTileThemeData(
                      tileColor: Colors.white,
                      selectedTileColor: const Color(0xFF8D6E63).withOpacity(.12),
                      iconColor: const Color(0xFF6D4C41),
                      textColor: const Color(0xFF3E2723),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    ),
                  ),
                  child: ListView(
                    children: [
                      if (barang.isNotEmpty) ...[
                        _sectionHeader(Icons.inventory_2, 'Barang'),
                        ...List.generate(barang.length, (i) {
                          final it = barang[i];
                          return _selectableTile(
                            index: i + 1,
                            title: it['nama'] ?? '',
                            subtitle: 'Stok: ${it['stok']}  •  Satuan: ${it['satuan']}',
                            selected:
                                (c.selectedItem.value?['sumber'] == it['sumber']) &&
                                (c.selectedItem.value?['nama'] == it['nama']),
                            onTap: () => c.pilihItem(it),
                          );
                        }),
                        const SizedBox(height: 8),
                      ],
                      if (produk.isNotEmpty) ...[
                        _sectionHeader(Icons.shopping_bag_outlined, 'Menu Produk'),
                        ...List.generate(produk.length, (i) {
                          final it = produk[i];
                          return _selectableTile(
                            index: i + 1,
                            title: it['nama'] ?? '',
                            subtitle: 'Stok: ${it['stok']}  •  Satuan: ${it['satuan']}',
                            selected:
                                (c.selectedItem.value?['sumber'] == it['sumber']) &&
                                (c.selectedItem.value?['nama'] == it['nama']),
                            onTap: () => c.pilihItem(it),
                          );
                        }),
                        const SizedBox(height: 8),
                      ],
                      if (fnb.isNotEmpty) ...[
                        _sectionHeader(Icons.local_dining_outlined, 'Menu FnB'),
                        ...List.generate(fnb.length, (i) {
                          final it = fnb[i];
                          return _selectableTile(
                            index: i + 1,
                            title: it['nama'] ?? '',
                            subtitle: 'Stok: ${it['stok']}  •  Satuan: ${it['satuan']}',
                            selected:
                                (c.selectedItem.value?['sumber'] == it['sumber']) &&
                                (c.selectedItem.value?['nama'] == it['nama']),
                            onTap: () => c.pilihItem(it),
                          );
                        }),
                      ],
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6D4C41)),
          const SizedBox(width: 6),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _selectableTile({
    required int index,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: ValueKey('$title-$index'),
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: ListTile(
        leading: CircleAvatar(backgroundColor: Colors.white, child: Text('$index')),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: selected ? Colors.brown : Colors.grey,
        ),
      ),
    );
  }

  // =========================
  // Panel kanan: form + batch
  // =========================
  Widget _panelBatch(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Obx(() {
          final it = c.selectedItem.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: const [
                  Icon(Icons.edit_note_outlined),
                  SizedBox(width: 8),
                  Text('Form Batch Opname', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),

              // Info item terpilih (tanpa "Sumber:")
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFBCAAA4)),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child:
                    it == null
                        ? const Text('Belum ada item terpilih')
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${it['nama'] ?? ''}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text('Stok saat ini: ${it['stok']} ${it['satuan'] ?? "pcs"}'),
                          ],
                        ),
              ),
              const SizedBox(height: 12),

              // Toggle Tambah/Kurangi (reaktif)
              Obx(
                () => Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        value: true,
                        groupValue: c.isAdd.value,
                        onChanged: (v) => c.isAdd.value = v ?? true,
                        title: const Text('Tambah'),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        value: false,
                        groupValue: c.isAdd.value,
                        onChanged: (v) => c.isAdd.value = v ?? false,
                        title: const Text('Kurangi'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Qty + Catatan BATCH
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: c.qtyC,
                      keyboardType: TextInputType.number,
                      onChanged: (v) => c.qtyText.value = v,
                      decoration: const InputDecoration(
                        labelText: 'Jumlah',
                        border: OutlineInputBorder(),
                        hintText: 'Misal: 5',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: c.noteC,
                      decoration: const InputDecoration(
                        labelText: 'Catatan Batch (opsional)',
                        border: OutlineInputBorder(),
                        hintText: 'Misal: Opname Akhir Bulan',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Preview + Tambah ke daftar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFBCAAA4)),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.calculate_outlined),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        it == null
                            ? 'Pilih item untuk melihat preview'
                            : 'Preview: ${c.stokLama} → ${c.stokBaru} ${it['satuan'] ?? "pcs"}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah ke Daftar'),
                      onPressed: (it == null) ? null : () => c.addToBatch(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6D4C41),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 5),

              // Ringkasan batch + tombol simpan semua
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Obx(
                    () => Row(
                      children: [
                        const Icon(Icons.list_alt),
                        const SizedBox(width: 8),
                        Text('Baris: ${c.totalBaris}'),
                        const SizedBox(width: 16),
                        Text('Δ+: ${c.totalPenambahan}'),
                        const SizedBox(width: 16),
                        Text('Δ-: ${c.totalPengurangan}'),
                        const SizedBox(width: 16),
                        Text('Net: ${c.totalNet}'),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: c.isSaving.value ? null : () => c.saveBatch(),
                          icon:
                              c.isSaving.value
                                  ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                  : const Icon(Icons.save_outlined),
                          label: const Text('Simpan Semua'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6D4C41),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Tabel daftar batch
              Expanded(
                child: Obx(() {
                  final data = c.batchItems;
                  if (data.isEmpty) {
                    return const Center(child: Text('Daftar batch masih kosong'));
                  }
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        // <-- VERTICAL scroll
                        padding: const EdgeInsets.all(8),
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          // <-- HORIZONTAL scroll
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingTextStyle: const TextStyle(fontWeight: FontWeight.bold),
                            columns: const [
                              DataColumn(label: Text('No')),
                              DataColumn(label: Text('Nama')),
                              DataColumn(label: Text('Satuan')),
                              DataColumn(label: Text('Perubahan')),
                              DataColumn(label: Text('Stok Sekarang')),
                              DataColumn(label: Text('Aksi')),
                            ],
                            rows: List<DataRow>.generate(data.length, (i) {
                              final r = data[i];
                              return DataRow(
                                cells: [
                                  DataCell(Text('${i + 1}')),
                                  DataCell(Text('${r['nama']}')),
                                  DataCell(Text('${r['satuan']}')),
                                  DataCell(Text('${r['perubahan']}')),
                                  DataCell(Text('${r['stok_sekarang']}')),
                                  DataCell(
                                    IconButton(
                                      tooltip: 'Hapus',
                                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                                      onPressed: () => c.removeFromBatch(i),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        }),
      ),
    );
  }
}
