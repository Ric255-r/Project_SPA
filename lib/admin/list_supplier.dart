import 'dart:collection';
import 'dart:developer';

import 'package:Project_SPA/function/admin_drawer.dart';
import 'package:Project_SPA/function/rupiah_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:intl/intl.dart';
import '../function/ip_address.dart';

class SupplierController extends GetxController {
  final dio = Dio();

  final RxList<Map<String, dynamic>> suppliers = <Map<String, dynamic>>[].obs;
  final RxnString selectedSupplierId = RxnString(); // ex: "SUP001"
  final RxList<Map<String, dynamic>> items = <Map<String, dynamic>>[].obs;

  // Master nama item (gabungan 3 tabel) untuk DropdownSearch di "Tambah Item"
  final RxList<String> masterNama = <String>[].obs;
  final RxList<String> masterSatuan = <String>[].obs;

  String get _base => myIpAddr().replaceAll(RegExp(r"/$"), "");
  String _ts() => DateTime.now().millisecondsSinceEpoch.toString();
  Options get _noCache => Options(
    headers: const {
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    },
  );

  // Query pencarian item
  final itemQuery = ''.obs;
  final itemSearchC = TextEditingController();

  void setItemQuery(String q) => itemQuery.value = q;

  void clearItemQuery() {
    if (itemSearchC.text.isNotEmpty) itemSearchC.clear(); // kosongkan textbox
    itemQuery.value = ''; // reset filter
  }

  @override
  void onClose() {
    itemSearchC.dispose();
    try {
      selectedSupplierId.close();
    } catch (_) {}
    super.onClose();
  }

  /// Daftar item terfilter (nama/harga mengandung query)
  List<Map<String, dynamic>> get filteredItems {
    final q = itemQuery.value.trim().toLowerCase();
    if (q.isEmpty) return items;

    return items.where((item) {
      // Check the main item name
      final name = (item['nama_item'] ?? '').toString().toLowerCase();
      if (name.contains(q)) {
        return true;
      }

      // Check within the nested details list
      final List details = item['detail_supplier_information'] ?? [];
      return details.any((detail) {
        final unit = (detail['satuan'] ?? '').toString().toLowerCase();
        final priceStr = (detail['harga'] ?? '').toString().toLowerCase();
        return unit.contains(q) || priceStr.contains(q);
      });
    }).toList();
  }

  @override
  Future<void> onInit() async {
    super.onInit();
    // whenever selected changes -> auto fetch items
    ever<String?>(selectedSupplierId, (id) async {
      if (id == null) {
        items.clear();
      } else {
        await fetchItems(id);
      }
    });

    await Future.wait([fetchSuppliers(), fetchMasterNama()]);
  }

  /// ---------- GET ----------
  Future<void> fetchSuppliers() async {
    try {
      final res = await dio.get('$_base/supplier/listsupplier?_ts=${_ts()}', options: _noCache);
      final List data = res.data;

      // dedup by id + simpan detail
      final seen = <String>{};
      final all = <Map<String, dynamic>>[];
      for (final e in data) {
        final id = e['id_supplier'].toString();
        if (seen.add(id)) {
          all.add({
            "id_supplier": id,
            "nama_supplier": e["nama_supplier"],
            "alamat": e["alamat"],
            "telp": e["telp"],
            "kota": e["kota"],
            "contact_person": e["contact_person"],
          });
        }
      }
      suppliers.assignAll(all);
    } catch (e) {
      if (e is DioException) {
        log("Error FetchSupplier ${e.response!.data}");
      }
    }
  }

  Future<void> fetchItems(String idSupplier) async {
    final res = await dio.get(
      '$_base/supplier/${Uri.encodeComponent(idSupplier)}/items?_ts=${_ts()}',
      options: _noCache,
    );
    final List data = res.data;
    items.assignAll(
      data.map<Map<String, dynamic>>(
        (e) => {
          "id": e["id"],
          "id_supplier": e["id_supplier"],
          "nama_item": e["nama_item"],
          "detail_supplier_information": e["detail_supplier_information"],
        },
      ),
    );
  }

  /// Ambil master nama items gabungan dari backend untuk dropdown
  Future<void> fetchMasterNama() async {
    try {
      final res = await dio.get('$_base/supplier/master-nama-items?_ts=${_ts()}', options: _noCache);
      Map responseData = res.data;

      final List dataProduk = responseData['produk'];
      final String dataSatuan = responseData['satuan'];
      final s = <String>{};
      for (final e in dataProduk) {
        final n = (e['nama'] ?? '').toString().trim();
        if (n.isNotEmpty) s.add(n);
      }

      masterNama.assignAll(s.toList()..sort());
      // Bersihkan string dari karakter yang tidak dibutuhkan
      final String cleanedString = dataSatuan
          .replaceAll("enum(", "") // -> "'pcs','pack','liter','box')"
          .replaceAll(")", "") // -> "'pcs','pack','liter','box'"
          .replaceAll("'", ""); // -> "pcs,pack,liter,box"

      // Pisahkan string menjadi List berdasarkan koma
      final List<String> satuanList = cleanedString.split(',');
      masterSatuan.assignAll(satuanList);
    } catch (e) {
      if (e is DioException) {
        log("Error FetchMasterNama ${e.response!.data}");
      }
    }
  }

  /// Re-fetch suppliers & keep selection (atau pilih pertama jika hilang)
  Future<void> refreshSuppliersPreserve({String? preferId}) async {
    final keep = preferId ?? selectedSupplierId.value;
    if (keep != null && suppliers.any((s) => s['id_supplier'] == keep)) {
      selectedSupplierId.value = keep; // triggers ever -> fetchItems
    } else if (suppliers.isNotEmpty) {
      selectedSupplierId.value = suppliers.first['id_supplier'].toString(); // triggers ever
    } else {
      selectedSupplierId.value = null; // triggers ever -> items.clear()
    }
  }

  /// ---------- Supplier CRUD ----------
  Future<void> addSupplier(
    String nama, {
    required String alamat,
    required String telp,
    required String kota,
    required String contactPerson,
  }) async {
    try {
      final res = await dio.post(
        '$_base/supplier/daftarsupplier',
        data: {
          "nama_supplier": nama,
          "alamat": alamat,
          "telp": telp, // biarkan string (bisa +62, spasi, dll.)
          "kota": kota,
          "contact_person": contactPerson,
        },
        options: Options(contentType: Headers.jsonContentType),
      );

      final newId = (res.data?['data']?['id_supplier'])?.toString();
      await refreshSuppliersPreserve(preferId: newId);

      // opsional: set pilihan ke supplier baru jika belum kepilih
      if (newId != null && selectedSupplierId.value != newId) {
        selectedSupplierId.value = newId;
      }
    } on DioException catch (_) {
      rethrow; // biarkan dialog yang menampilkan toast
    }
  }

  Future<void> updateSupplier(
    String id, {
    String? namaSupplier,
    String? alamat,
    String? telp,
    String? kota,
    String? contactPerson,
  }) async {
    final body = <String, dynamic>{};
    if (namaSupplier != null) body['nama_supplier'] = namaSupplier;
    if (alamat != null) body['alamat'] = alamat;
    if (telp != null) body['telp'] = telp;
    if (kota != null) body['kota'] = kota;
    if (contactPerson != null) body['contact_person'] = contactPerson;

    if (body.isEmpty) return;

    await dio.put('$_base/supplier/updatesupplier/$id', data: body);
    await refreshSuppliersPreserve(preferId: id);
  }

  Future<void> deleteSupplier(String id) async {
    await dio.delete('$_base/supplier/$id');
    await refreshSuppliersPreserve();
  }

  Future<bool> _confirmDeleteSupplier(BuildContext context, {String? supplierName}) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Hapus Supplier?'),
        content: Text(
          'Yakin ingin menghapus supplier'
          '${supplierName != null && supplierName.isNotEmpty ? ' "$supplierName"' : ''}? '
          'Tindakan ini akan menghapus semua item miliknya.',
        ),
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
    return result ?? false;
  }

  /// ---------- Item CRUD ----------
  Future<void> addItemsToSupplier(String idSupplier, List<Map<String, dynamic>> payload) async {
    await dio.post('$_base/supplier/$idSupplier/items', data: {"items": payload});
    await fetchItems(idSupplier); // AUTO REFRESH
  }

  Future<void> updateItem(int id, String idSupplier, String nama, String satuan, double harga) async {
    await dio.put(
      '$_base/supplier/updateitem/$id',
      data: {"id_supplier_items": nama, "satuan": satuan, "harga_item": harga},
    );
    await fetchItems(idSupplier);
    Get.back(); // AUTO REFRESH
  }

  Future<void> updatePrice(int detailId, {required int harga, required String satuan}) async {
    final idSupplier = selectedSupplierId.value;
    if (idSupplier == null) return;

    await dio.put(
      '$_base/supplier/update-price-detail/$detailId', // Assuming this is your endpoint for price updates
      data: {"harga": harga, "satuan": satuan},
    );
    await fetchItems(idSupplier);
    Get.back(); // Close the dialog and refresh
  }

  Future<void> deleteItem(int id) async {
    try {
      final current = selectedSupplierId.value;
      // Optimistic: hilangkan dulu di UI
      items.removeWhere((it) => it['id'] == id);
      await dio.delete('$_base/supplier/deleteitem/$id');
      CherryToast.success(title: const Text("Sukses Menghapus Item")).show(Get.context!);

      if (current != null) {
        await fetchItems(current); // AUTO REFRESH
      }

      Get.back(result: true);
    } catch (e) {
      CherryToast.error(title: const Text("Gagal Menghapus Item")).show(Get.context!);
      Get.back(result: false);

      log("Error in deleteItem: $e");
    }
  }

  Future<void> deletePrice(int id) async {
    try {
      final current = selectedSupplierId.value;

      await dio.delete('$_base/supplier/delete-price-detail/$id');
      CherryToast.success(title: const Text("Sukses Menghapus Item")).show(Get.context!);

      if (current != null) {
        await fetchItems(current); // AUTO REFRESH
      }

      Get.back(result: true);
    } catch (e) {
      CherryToast.error(title: const Text("Gagal Menghapus Item")).show(Get.context!);
      Get.back(result: false);

      log("Error in deleteItem: $e");
    }
  }

  void _showEditPriceDialog(BuildContext context, Map<String, dynamic> detail) {
    final priceC = TextEditingController(
      text: NumberFormat.decimalPattern('id').format(detail['harga'] ?? 0),
    );
    RxString selectedUnit = "${detail['satuan'] ?? masterSatuan.firstOrNull}".obs;

    Get.dialog(
      AlertDialog(
        title: const Text("Edit Harga & Satuan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(
              () => DropdownSearch<String>(
                items: masterSatuan,
                selectedItem: selectedUnit.value,
                onChanged: (val) {
                  if (val != null) selectedUnit.value = val;
                },
                popupProps: const PopupProps.menu(showSearchBox: true, fit: FlexFit.loose),
                dropdownDecoratorProps: const DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: 'Satuan',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: priceC,
              inputFormatters: <TextInputFormatter>[RupiahInputFormatter()],
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Harga (Rp.)"),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              final unit = selectedUnit.value;
              final hargaStr = priceC.text.replaceAll('.', '').replaceAll(',', '');
              final harga = int.tryParse(hargaStr);

              if (unit.isEmpty || harga == null || harga < 0) {
                CherryToast.error(title: const Text("Input tidak valid")).show(context);
                return;
              }
              try {
                await updatePrice(detail['id'] as int, harga: harga, satuan: unit);
                CherryToast.success(title: const Text("Harga diupdate")).show(Get.context!);
              } on DioException catch (e) {
                CherryToast.error(
                  title: const Text("Gagal update harga"),
                  description: Text("${e.response?.statusCode} ${e.response?.data ?? e.message}"),
                ).show(Get.context!);
              } catch (e) {
                CherryToast.error(
                  title: const Text("Gagal update harga"),
                  description: Text("$e"),
                ).show(Get.context!);
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDeleteItem(BuildContext context, Map<String, dynamic> item) async {
    final res = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Hapus Item?'),
        content: Text('Yakin ingin menghapus item "${item['nama_item']}"?'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Tidak')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => deleteItem(item['id'] as int),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    return res ?? false;
  }

  Future<bool> _confirmDeletePricePerItem(BuildContext context, Map<String, dynamic> item) async {
    final res = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Hapus Harga?'),
        content: Text(
          'Yakin ingin menghapus Harga Rp. ${NumberFormat.decimalPattern('id').format(item['harga'])} / "${item['satuan']} ?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Tidak')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => deletePrice(item['id'] as int),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    return res ?? false;
  }
}

class ListSupplierPage extends StatelessWidget {
  ListSupplierPage({super.key});

  final c = Get.put(SupplierController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0XFFFFE0B2),
      appBar: AppBar(
        title: const Text("List Supplier", style: TextStyle(fontFamily: 'Poppins', fontSize: 30)),
        backgroundColor: const Color(0XFFFFE0B2),
      ),
      drawer: AdminDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSupplierDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // DropdownSearch pilih supplier
            Obx(() {
              Map<String, dynamic>? selected;
              final selId = c.selectedSupplierId.value;
              for (final s in c.suppliers) {
                if (s['id_supplier'] == selId) {
                  selected = s;
                  break;
                }
              }

              return DropdownSearch<Map<String, dynamic>>(
                asyncItems: (String? filter) async {
                  await c.fetchSuppliers();
                  final q = (filter ?? '').trim().toLowerCase();
                  if (q.isEmpty) return List<Map<String, dynamic>>.from(c.suppliers);
                  final seen = <String>{};
                  final list = <Map<String, dynamic>>[];
                  for (final s in c.suppliers) {
                    final id = s['id_supplier'].toString().toLowerCase();
                    final name = s['nama_supplier'].toString().toLowerCase();
                    if (id.contains(q) || name.contains(q)) {
                      final key = s['id_supplier'].toString();
                      if (seen.add(key)) list.add(s);
                    }
                  }
                  return list;
                },
                selectedItem: selected,
                itemAsString: (m) => "${m['id_supplier']} - ${m['nama_supplier']}",
                onChanged: (m) async {
                  final id = m?['id_supplier']?.toString();
                  c.selectedSupplierId.value = id;
                  if (id != null) {
                    await c.fetchItems(id);
                  } else {
                    c.items.clear();
                  }
                },
                compareFn: (a, b) => a['id_supplier'] == b['id_supplier'],
                clearButtonProps: const ClearButtonProps(isVisible: true),
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    decoration: const InputDecoration(
                      hintText: 'Cari supplier (nama/kode)',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                dropdownDecoratorProps: DropDownDecoratorProps(
                  baseStyle: TextStyle(color: Colors.brown.shade900, fontWeight: FontWeight.w500),
                  dropdownSearchDecoration: InputDecoration(
                    labelText: "Pilih Supplier",
                    labelStyle: TextStyle(color: Colors.brown.shade700),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.brown.shade300, width: 1.2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.brown.shade700, width: 2),
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 12),
            Obx(() {
              final selId = c.selectedSupplierId.value;
              if (selId == null) return const SizedBox.shrink();

              final sup = c.suppliers.firstWhereOrNull((s) => s['id_supplier'] == selId);
              if (sup == null) return const SizedBox.shrink();

              Widget row(String label, String? value, {TextStyle? valueStyle}) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 130,
                      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const Text(" : "),
                    Expanded(
                      child: Text(value?.trim().isEmpty == true ? "-" : (value ?? "-"), style: valueStyle),
                    ),
                  ],
                ),
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      row(
                        "Alamat",
                        sup['alamat'] as String?,
                        valueStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                      ),
                      row(
                        "No. Telp",
                        sup['telp'] as String?,
                        valueStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                      ),
                      row(
                        "Kota",
                        sup['kota'] as String?,
                        valueStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                      ),
                      row(
                        "Contact Person",
                        sup['contact_person'] as String?,
                        valueStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // Bar aksi & List Items
            Obx(() {
              final selected = c.selectedSupplierId.value;
              final sup = c.suppliers.firstWhere((s) => s['id_supplier'] == selected, orElse: () => {});

              if (selected == null || sup.isEmpty) {
                return const Expanded(child: Center(child: Text("Pilih supplier terlebih dahulu")));
              }

              // ignore: unused_local_variable
              String supplierName = "";
              for (final s in c.suppliers) {
                if (s['id_supplier'] == selected) {
                  supplierName = s['nama_supplier'];
                  break;
                }
              }

              return Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed:
                              () => _showEditSupplierDialog(
                                context,
                                sup['id_supplier'],
                                nama: sup['nama_supplier'],
                                alamat: sup['alamat'],
                                telp: sup['telp'],
                                kota: sup['kota'],
                                contactPerson: sup['contact_person'],
                              ),
                          child: const Text("Edit Supplier"),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final name =
                                (() {
                                  for (final s in c.suppliers) {
                                    if (s['id_supplier'] == selected) return s['nama_supplier'] as String;
                                  }
                                  return null;
                                })();

                            final ok = await c._confirmDeleteSupplier(context, supplierName: name);
                            if (!ok) return;

                            try {
                              await c.deleteSupplier(selected);
                              c.selectedSupplierId.value = null;
                              c.items.clear();

                              CherryToast.success(title: const Text("Supplier dihapus")).show(Get.context!);
                            } on DioException catch (e) {
                              CherryToast.error(
                                title: const Text("Gagal hapus supplier"),
                                description: Text(
                                  "${e.response?.statusCode} ${e.response?.data ?? e.message}",
                                ),
                              ).show(Get.context!);
                            } catch (e) {
                              CherryToast.error(
                                title: const Text("Gagal hapus supplier"),
                                description: Text("$e"),
                              ).show(Get.context!);
                            }
                          },
                          child: const Text("Hapus Supplier"),
                        ),

                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _showAddItemDialog(context, selected),
                          child: const Text("Tambah Item"),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Obx(
                            () => TextField(
                              controller: c.itemSearchC,
                              onChanged: (v) => c.setItemQuery(v),
                              decoration: InputDecoration(
                                hintText: "Cari item (nama / harga)",
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon:
                                    c.itemQuery.value.isEmpty
                                        ? null
                                        : IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            c.setItemQuery('');
                                            c.clearItemQuery();
                                          },
                                        ),
                                isDense: true,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Obx(() {
                        final data = c.filteredItems;

                        if (data.isEmpty) {
                          return Center(
                            child: Text(
                              c.itemQuery.value.isEmpty ? "Belum ada item" : "Tidak ada item yang cocok",
                            ),
                          );
                        }

                        // Use ExpansionTile for a better user experience

                        return Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: const Color(0xFFBCAAA4), // Color for dividers inside ExpansionTile
                          ),
                          child: ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.all(8),
                            itemCount: data.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final item = data[i];
                              final List details = item['detail_supplier_information'] ?? [];

                              return Card(
                                clipBehavior: Clip.antiAlias,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                margin: EdgeInsets.zero,
                                child: ExpansionTile(
                                  backgroundColor: Colors.white,
                                  title: Text(
                                    item['nama_item'] ?? "Tanpa Nama",
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${details.length} Opsi Harga',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      color: Color(0xFF6D4C41),
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete),
                                    tooltip: 'Edit Nama Item',
                                    onPressed: () => c._confirmDeleteItem(context, item),
                                  ),

                                  children:
                                      details.map((detail) {
                                        return Container(
                                          color: const Color(0xFFF5F5F5),
                                          child: ListTile(
                                            dense: true,
                                            title: Text(
                                              "Harga: Rp. ${NumberFormat.decimalPattern('id').format(detail['harga'])} / ${detail['satuan']}",
                                              style: const TextStyle(fontFamily: 'Poppins'),
                                            ),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit, size: 20),
                                                  tooltip: 'Edit Harga/Satuan',
                                                  onPressed: () => c._showEditPriceDialog(context, detail),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    size: 20,
                                                    color: Colors.redAccent,
                                                  ),
                                                  tooltip: 'Hapus Harga/Satuan',
                                                  onPressed: () {
                                                    c._confirmDeletePricePerItem(context, detail);
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                ),
                              );
                            },
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showAddSupplierDialog(BuildContext context) {
    final nameC = TextEditingController();
    final rows =
        <Map<String, TextEditingController>>[
          {"name": TextEditingController(), "price": TextEditingController()},
        ].obs;
    final saving = false.obs;
    final alamatC = TextEditingController();
    final telpC = TextEditingController();
    final kotaC = TextEditingController();
    final cpC = TextEditingController();

    Get.dialog(
      Obx(
        () => AlertDialog(
          title: const Text("Tambah Supplier", style: TextStyle(fontFamily: 'Poppins')),
          content: SizedBox(
            width: Get.width * 0.5,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameC,
                    decoration: const InputDecoration(
                      labelText: "Nama Supplier",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: alamatC,
                    decoration: const InputDecoration(labelText: "Alamat", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: telpC,
                    decoration: const InputDecoration(labelText: "No. Telp", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: kotaC,
                    decoration: const InputDecoration(labelText: "Kota", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: cpC,
                    decoration: const InputDecoration(
                      labelText: "Contact Person",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Align(
                  //   alignment: Alignment.centerLeft,
                  //   child: Text("Item Awal (opsional)", style: Get.textTheme.labelLarge),
                  // ),
                  // const SizedBox(height: 6),
                  // for (int i = 0; i < rows.length; i++)
                  //   Padding(
                  //     padding: const EdgeInsets.only(bottom: 8),
                  //     child: Row(
                  //       children: [
                  //         Expanded(
                  //           flex: 2,
                  //           child: TextField(
                  //             controller: rows[i]["name"],
                  //             decoration: const InputDecoration(
                  //               labelText: "Nama Item",
                  //               border: OutlineInputBorder(),
                  //             ),
                  //           ),
                  //         ),
                  //         const SizedBox(width: 8),
                  //         Expanded(
                  //           flex: 1,
                  //           child: TextField(
                  //             controller: rows[i]["price"],
                  //             keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  //             decoration: const InputDecoration(
                  //               labelText: "Harga",
                  //               border: OutlineInputBorder(),
                  //             ),
                  //           ),
                  //         ),
                  //         const SizedBox(width: 8),
                  //         IconButton(
                  //           onPressed: () => rows.removeAt(i),
                  //           icon: const Icon(Icons.remove_circle, color: Colors.red),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // Align(
                  //   alignment: Alignment.centerLeft,
                  //   child: TextButton.icon(
                  //     onPressed:
                  //         () => rows.add({"name": TextEditingController(), "price": TextEditingController()}),
                  //     icon: const Icon(Icons.add),
                  //     label: const Text("Tambah Baris"),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: saving.value ? null : () => Get.back(), child: const Text("Batal")),
            ElevatedButton(
              onPressed:
                  saving.value
                      ? null
                      : () async {
                        final nama = nameC.text.trim();
                        if (nama.isEmpty) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(const SnackBar(content: Text("Nama supplier wajib diisi")));
                          return;
                        }
                        final payload = <Map<String, dynamic>>[];
                        for (final r in rows) {
                          final n = r["name"]!.text.trim();
                          final p = r["price"]!.text.trim();
                          if (n.isEmpty && p.isEmpty) continue;
                          if (n.isEmpty || p.isEmpty) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(const SnackBar(content: Text("Nama & harga item wajib diisi")));
                            return;
                          }
                          final harga = double.tryParse(p.replaceAll('.', '').replaceAll(',', '.'));
                          if (harga == null || harga < 0) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text("Harga tidak valid untuk $n")));
                            return;
                          }
                          payload.add({"nama_item": n, "harga_item": harga});
                        }

                        saving.value = true;
                        try {
                          final ctrl = Get.find<SupplierController>();

                          await ctrl.addSupplier(
                            nama,

                            alamat: alamatC.text.trim(),
                            telp: telpC.text.trim(),
                            kota: kotaC.text.trim(),
                            contactPerson: cpC.text.trim(),
                          );

                          final currentId = ctrl.selectedSupplierId.value;

                          await ctrl.fetchItems(currentId!);
                          CherryToast.success(
                            title: const Text("Supplier berhasil ditambahkan"),
                          ).show(Get.context!);
                          c.fetchSuppliers();
                          Get.back();
                        } on DioException catch (e) {
                          saving.value = false;
                          CherryToast.error(
                            title: const Text("Gagal tambah supplier"),
                            description: Text("${e.response?.statusCode} ${e.response?.data ?? e.message}"),
                          ).show(Get.context!);
                        } catch (e) {
                          saving.value = false;
                          CherryToast.error(
                            title: const Text("Gagal tambah supplier"),
                            description: Text("$e"),
                          ).show(Get.context!);
                        }
                      },
              child:
                  saving.value
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text("Simpan"),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Dialog TAMBAH ITEM (HANYA UBAH NAMA ITEM -> DropdownSearch masterNama)
  void _showAddItemDialog(BuildContext context, String idSupplier) {
    final defaultUnit = (c.masterSatuan.isNotEmpty ? c.masterSatuan.first : null);
    // Struktur baris: nameSel untuk pilihan dropdown, price untuk harga
    final rows =
        <Map<String, dynamic>>[
          {"nameSel": RxnString(), "satuanSel": RxnString(defaultUnit), "price": TextEditingController()},
        ].obs;
    final saving = false.obs;

    Get.dialog(
      Obx(
        () => AlertDialog(
          title: const Text("Tambah Item ke Supplier"),
          content: SizedBox(
            width: Get.width * 0.5,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < rows.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          // === DropdownSearch Nama Item (gabungan 3 tabel)
                          Expanded(
                            flex: 2,
                            child: Obx(
                              () => DropdownSearch<String>(
                                items: c.masterNama,
                                selectedItem: rows[i]["nameSel"].value,
                                onChanged: (val) => rows[i]["nameSel"].value = val,
                                popupProps: const PopupProps.menu(showSearchBox: true, fit: FlexFit.loose),
                                dropdownDecoratorProps: const DropDownDecoratorProps(
                                  dropdownSearchDecoration: InputDecoration(
                                    labelText: 'Nama Item',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Satuan
                          Expanded(
                            flex: 1,
                            child: Obx(() {
                              // backfill agar key selalu ada
                              rows[i]["satuanSel"] =
                                  (rows[i]["satuanSel"] as RxnString?) ?? RxnString(defaultUnit);
                              final unitRx = rows[i]["satuanSel"] as RxnString;

                              return DropdownSearch<String>(
                                items: c.masterSatuan,
                                selectedItem: unitRx.value, // aman
                                onChanged: (val) => unitRx.value = val, // aman
                                popupProps: const PopupProps.menu(showSearchBox: true, fit: FlexFit.loose),
                                dropdownDecoratorProps: const DropDownDecoratorProps(
                                  dropdownSearchDecoration: InputDecoration(
                                    labelText: 'Satuan',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(width: 8),

                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: rows[i]["price"],
                              inputFormatters: <TextInputFormatter>[RupiahInputFormatter()], //
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: "Harga (Rp. ) ",
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => rows.removeAt(i),
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed:
                          () => rows.add({
                            "nameSel": RxnString(),
                            "satuanSel": RxnString(defaultUnit),
                            "price": TextEditingController(),
                          }),
                      icon: const Icon(Icons.add),
                      label: const Text("Tambah Baris"),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: saving.value ? null : () => Get.back(), child: const Text("Batal")),
            ElevatedButton(
              onPressed:
                  saving.value
                      ? null
                      : () async {
                        if (rows.isEmpty) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(const SnackBar(content: Text("Minimal 1 item")));
                          return;
                        }
                        final payload = <Map<String, dynamic>>[];
                        for (final r in rows) {
                          final String? n = (r["nameSel"] as RxnString).value;
                          final String? unit = (r["satuanSel"] as RxnString).value;
                          final String p = (r["price"] as TextEditingController).text.trim();
                          if ((n == null || n.trim().isEmpty) || p.isEmpty) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(const SnackBar(content: Text("Nama & harga wajib diisi")));
                            return;
                          }
                          final harga = double.tryParse(p.replaceAll('.', '').replaceAll(',', ''));
                          if (harga == null || harga < 0) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text("Harga tidak valid untuk $n")));
                            return;
                          }
                          payload.add({"nama_item": n.trim(), "satuan": unit!, "harga_item": harga});
                        }

                        saving.value = true;
                        try {
                          final ctrl = Get.find<SupplierController>();
                          await ctrl.addItemsToSupplier(idSupplier, payload); // <-- AUTO REFRESH
                          CherryToast.success(title: const Text("Item ditambahkan")).show(Get.context!);
                          Get.back();
                        } on DioException catch (e) {
                          saving.value = false;
                          CherryToast.error(
                            title: const Text("Gagal tambah item"),
                            description: Text("${e.response?.statusCode} ${e.response?.data ?? e.message}"),
                          ).show(Get.context!);
                        } catch (e) {
                          saving.value = false;
                          CherryToast.error(
                            title: const Text("Gagal tambah item"),
                            description: Text("$e"),
                          ).show(Get.context!);
                        }
                      },
              child:
                  saving.value
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text("Simpan"),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _showEditSupplierDialog(
    BuildContext context,
    String id, {
    required String nama,
    String? alamat,
    String? telp,
    String? kota,
    String? contactPerson,
  }) {
    final nameC = TextEditingController(text: nama);
    final alamatC = TextEditingController(text: alamat ?? "");
    final telpC = TextEditingController(text: telp ?? "");
    final kotaC = TextEditingController(text: kota ?? "");
    final cpC = TextEditingController(text: contactPerson ?? "");

    Get.dialog(
      AlertDialog(
        title: const Text("Edit Supplier"),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameC,
                  decoration: const InputDecoration(labelText: "Nama Supplier", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: alamatC,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: "Alamat", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: telpC,
                  decoration: const InputDecoration(labelText: "No. Telp", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: kotaC,
                  decoration: const InputDecoration(labelText: "Kota", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: cpC,
                  decoration: const InputDecoration(
                    labelText: "Contact Person",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              final namaBaru = nameC.text.trim();
              if (namaBaru.isEmpty) {
                CherryToast.error(title: const Text("Nama tidak boleh kosong")).show(context);
                return;
              }
              try {
                final ctrl = Get.find<SupplierController>();
                await ctrl.updateSupplier(
                  id,
                  namaSupplier: namaBaru,
                  alamat: alamatC.text.trim(),
                  telp: telpC.text.trim(),
                  kota: kotaC.text.trim(),
                  contactPerson: cpC.text.trim(),
                );
                CherryToast.success(title: const Text("Supplier diupdate")).show(Get.context!);
                c.fetchSuppliers();
                Get.back();
              } on DioException catch (e) {
                CherryToast.error(
                  title: const Text("Gagal update supplier"),
                  description: Text("${e.response?.statusCode} ${e.response?.data ?? e.message}"),
                ).show(Get.context!);
              } catch (e) {
                CherryToast.error(
                  title: const Text("Gagal update supplier"),
                  description: Text("$e"),
                ).show(Get.context!);
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }
}
