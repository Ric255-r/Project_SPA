import 'package:Project_SPA/admin/stok_opname.dart';
import 'package:Project_SPA/function/admin_drawer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:dio/dio.dart';
import 'package:Project_SPA/function/ip_address.dart';

class BarangController extends GetxController {
  final dio = Dio();

  final RxList<Map<String, dynamic>> items = <Map<String, dynamic>>[].obs;

  // form controllers
  final namaC = TextEditingController();
  final stokC = TextEditingController();
  final satuanC = TextEditingController();

  // search
  final query = ''.obs;
  final searchC = TextEditingController();

  String get _base => myIpAddr().replaceAll(RegExp(r"/$"), "");
  String _ts() => DateTime.now().millisecondsSinceEpoch.toString();

  Options get _noCache => Options(
    headers: const {
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    },
  );

  List<Map<String, dynamic>> get filtered {
    final q = query.value.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((e) {
      final n = (e['nama_brg'] ?? '').toString().toLowerCase();
      final s = (e['satuan'] ?? '').toString().toLowerCase();
      return n.contains(q) || s.contains(q);
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    fetchBarang();
  }

  @override
  void onClose() {
    namaC.dispose();
    stokC.dispose();
    satuanC.dispose();
    searchC.dispose();
    super.onClose();
  }

  /// ---------- API ----------
  Future<void> fetchBarang() async {
    final res = await dio.get('$_base/listbarang/getbarang?_ts=${_ts()}', options: _noCache);
    final List data = res.data;
    items.assignAll(
      data.map<Map<String, dynamic>>(
        (e) => {
          "id_brg": e["id_brg"],
          "nama_brg": e["nama_brg"],
          "stok_brg": e["stok_brg"],
          "satuan": e["satuan"],
        },
      ),
    );
  }

  Future<void> addBarang() async {
    final nama = namaC.text.trim();
    final satuan = satuanC.text.trim();
    final stokStr = stokC.text.trim();

    if (nama.isEmpty || satuan.isEmpty || stokStr.isEmpty) {
      CherryToast.warning(
        title: const Text('Validasi'),
        description: const Text('Nama, stok, dan satuan wajib diisi'),
      ).show(Get.context!);
      return;
    }
    final stok = int.tryParse(stokStr);
    if (stok == null) {
      CherryToast.warning(
        title: const Text('Validasi'),
        description: const Text('Stok harus angka'),
      ).show(Get.context!);
      return;
    }

    await dio.post(
      '$_base/listbarang/insertbarang',
      data: {"nama_brg": nama, "stok_brg": stok, "satuan": satuan},
    );

    await fetchBarang();
    namaC.clear();
    stokC.clear();
    satuanC.clear();
    Get.back(); // tutup dialog
  }

  Future<void> updateBarang(Map<String, dynamic> row) async {
    await dio.put(
      '$_base/listbarang/updatebarang',
      data: {
        "id_brg": row["id_brg"],
        "nama_brg": row["nama_brg"],
        "stok_brg": row["stok_brg"],
        "satuan": row["satuan"],
      },
    );
    await fetchBarang();
  }

  Future<void> deleteBarang(String id) async {
    final ok = await _confirmDelete(Get.context!, name: id);
    if (!ok) return;
    await dio.delete('$_base/listbarang/deletebarang', data: {"id_brg": id});
    await fetchBarang();
  }

  void setQuery(String q) => query.value = q;
  void clearQuery() {
    if (searchC.text.isNotEmpty) searchC.clear();
    query.value = '';
  }
}

class ListBarang extends StatelessWidget {
  ListBarang({super.key});

  final c = Get.put(BarangController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE0B2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFE0B2),
        title: const Text("List Barang", style: TextStyle(fontFamily: 'Poppins', fontSize: 30)),
        actions: [
          TextButton(
            onPressed: () => Get.to(() => StokOpnamePage()),
            child: const Text(
              'Stok Opname',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 30, color: Colors.red),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: AdminDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Search bar
            TextField(
              controller: c.searchC,
              onChanged: c.setQuery,
              decoration: InputDecoration(
                hintText: 'Cari barang (nama/satuan)',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Obx(() {
                final data = c.filtered;
                if (data.isEmpty) {
                  return const Center(child: Text('Belum ada barang'));
                }
                return Theme(
                  data: Theme.of(context).copyWith(
                    // warna garis pemisah ListView.separated
                    dividerColor: const Color(0xFFBCAAA4),

                    // default untuk semua ListTile di dalamnya
                    listTileTheme: ListTileThemeData(
                      tileColor: Colors.white, // bg item
                      selectedTileColor: const Color(0xFF8D6E63).withOpacity(.12),
                      iconColor: const Color(0xFF6D4C41), // warna ikon
                      textColor: const Color(0xFF3E2723), // warna teks
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    ),
                  ),
                  child: ListView.separated(
                    itemCount: data.length,
                    separatorBuilder: (_, __) => const Divider(height: 3),
                    itemBuilder: (_, i) {
                      final it = data[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Text('${i + 1}'), // <<< nomor urut otomatis
                        ),
                        title: Text(it['nama_brg'] ?? ''),
                        subtitle: Text("Stok: ${it['stok_brg']}  •  Satuan: ${it['satuan']}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditDialog(context, it),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => c.deleteBarang(it['id_brg']),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    c.namaC.clear();
    c.stokC.clear();
    c.satuanC.clear();

    Get.dialog(
      AlertDialog(
        title: const Text('Tambah Barang'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: c.namaC,
                  decoration: const InputDecoration(labelText: "Nama Barang", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: c.stokC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Stok", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: c.satuanC,
                  decoration: const InputDecoration(
                    labelText: "Satuan (kg, batang, dus, ...)",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(onPressed: c.addBarang, child: const Text('Simpan')),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _showEditDialog(BuildContext context, Map<String, dynamic> row) {
    final namaEC = TextEditingController(text: row['nama_brg']?.toString() ?? '');
    final stokEC = TextEditingController(text: row['stok_brg']?.toString() ?? '');
    final satuanEC = TextEditingController(text: row['satuan']?.toString() ?? '');

    Get.dialog(
      AlertDialog(
        title: Text('Edit ${row['id_brg']}'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaEC,
                decoration: const InputDecoration(labelText: "Nama Barang", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: stokEC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Stok", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: satuanEC,
                decoration: const InputDecoration(labelText: "Satuan", border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final patched = {
                "id_brg": row["id_brg"],
                "nama_brg": namaEC.text.trim(),
                "stok_brg": int.tryParse(stokEC.text.trim()) ?? 0,
                "satuan": satuanEC.text.trim(),
              };
              await c.updateBarang(patched);
              Get.back();
            },
            child: const Text('Update'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}

/// konfirmasi hapus
Future<bool> _confirmDelete(BuildContext context, {required String name}) async {
  final res = await Get.dialog<bool>(
    AlertDialog(
      title: const Text('Hapus Barang?'),
      content: Text('Yakin ingin menghapus "$name"?'),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: const Text('Tidak')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Get.back(result: true),
          child: const Text('Ya, Hapus'),
        ),
      ],
    ),
    barrierDismissible: false,
  );
  return res ?? false;
}
