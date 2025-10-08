import 'package:Project_SPA/function/ip_address.dart';
import 'package:Project_SPA/function/rupiah_formatter.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

class POPemasokController extends GetxController {
  final dio = Dio();

  // Supplier
  final RxList<Map<String, dynamic>> suppliers = <Map<String, dynamic>>[].obs;
  final RxnString selectedSupplierId = RxnString();

  // Item milik supplier terpilih (dari /supplier/{id}/items)
  final RxList<Map<String, dynamic>> supplierItems = <Map<String, dynamic>>[].obs;

  // Baris input item yang akan dibeli
  final RxList<Map<String, dynamic>> itemRows = <Map<String, dynamic>>[].obs;

  // No Form auto
  final RxString noForm = ''.obs;

  String get _base => myIpAddr().replaceAll(RegExp(r"/$"), "");
  String _ts() => DateTime.now().millisecondsSinceEpoch.toString();
  Options get _noCache => Options(
    headers: const {
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    },
  );

  @override
  void onInit() {
    super.onInit();
    selectedSupplierId.value = null; // clear saat buka page
    fetchSuppliers();
    addItemRow(); // mulai 1 baris kosong
  }

  @override
  void onClose() {
    for (final r in itemRows) {
      (r['qty'] as TextEditingController).dispose();
      (r['price'] as TextEditingController).dispose();
    }
    try {
      selectedSupplierId.close();
    } catch (_) {}
    super.onClose();
  }

  // ================= NO FORM AUTO =================
  Future<void> refreshNoForm(DateTime tgl) async {
    final res = await dio.get(
      '$_base/pembelian/nextid',
      queryParameters: {'tanggal_form': DateFormat('yyyy-MM-dd').format(tgl)},
      options: _noCache,
    );
    noForm.value = (res.data?['id_form'] ?? '').toString();
  }

  // ================= SUPPLIERS =================
  Future<void> fetchSuppliers() async {
    try {
      final res = await dio.get('$_base/supplier/listsupplier?_ts=${_ts()}', options: _noCache);
      if (res.data is! List) {
        suppliers.assignAll([]);
        return;
      }
      final List data = res.data;
      final seen = <String>{};
      final all = <Map<String, dynamic>>[];
      for (final e in data) {
        final id = e['id_supplier']?.toString() ?? '';
        if (id.isEmpty) continue;
        if (seen.add(id)) {
          all.add({
            'id_supplier': id,
            'nama_supplier': e['nama_supplier'],
            'alamat': e['alamat'],
            'telp': e['telp'],
            'kota': e['kota'],
            'contact_person': e['contact_person'],
          });
        }
      }
      suppliers.assignAll(all);

      selectedSupplierId.value = null;
      supplierItems.clear();
      clearAllItemRows();
      addItemRow();
    } catch (e) {
      suppliers.assignAll([]);
      selectedSupplierId.value = null;
      supplierItems.clear();
    }
  }

  //Ganti supplier, fetch ulang
  Future<void> onSupplierChanged(String? id) async {
    selectedSupplierId.value = id;
    await fetchSupplierItems(id);
    clearAllItemRows();
    addItemRow();
  }

  // ================= SUPPLIER ITEMS (tetap dari supplier) =================
  Future<void> fetchSupplierItems(String? idSupplier) async {
    supplierItems.clear();
    if (idSupplier == null || idSupplier.isEmpty) return;
    try {
      final res = await dio.get('$_base/supplier/$idSupplier/items?_ts=${_ts()}', options: _noCache);
      if (res.data is List) {
        // ekspektasi backend: [{id, id_supplier, nama_item, harga_item}, ...]
        supplierItems.assignAll(List<Map<String, dynamic>>.from(res.data));
      }
    } catch (e) {
      supplierItems.clear();
    }
  }

  Map<String, dynamic>? itemById(String? id) {
    if (id == null) return null;
    for (final it in supplierItems) {
      if ((it['id'] ?? '').toString() == id) return it;
    }
    return null;
  }

  // ================= ROWS =================
  void addItemRow() {
    itemRows.add({'itemId': null, 'qty': TextEditingController(), 'price': TextEditingController()});
  }

  void removeItemRow(int index) {
    if (index < 0 || index >= itemRows.length) return;
    (itemRows[index]['qty'] as TextEditingController).dispose();
    (itemRows[index]['price'] as TextEditingController).dispose();
    itemRows.removeAt(index);
  }

  void clearAllItemRows() {
    for (final r in itemRows) {
      (r['qty'] as TextEditingController).dispose();
      (r['price'] as TextEditingController).dispose();
    }
    itemRows.clear();
  }

  // ================= HITUNG TOTAL =================
  num _num(String s) {
    if (s.isEmpty) return 0;
    final cleaned = s.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0;
  }

  String _priceString(dynamic harga) {
    if (harga == null) return '';
    return NumberFormat.decimalPattern('id').format(harga);
  }

  num lineTotal(Map<String, dynamic> r) {
    final q = _num((r['qty'] as TextEditingController).text.trim());
    final p = _num((r['price'] as TextEditingController).text.trim());
    return q * p;
  }

  num get subtotal {
    num sum = 0;
    for (final r in itemRows) {
      sum += lineTotal(r);
    }
    return sum;
  }

  num get grandTotal => subtotal;

  String money(num n) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(n);

  // ================= SIMPAN =================
  Future<void> simpanPembelian({
    required String noFaktur,
    required DateTime tanggalForm,
    required BuildContext context,
  }) async {
    // >>> VALIDASI: no faktur wajib
    if (noFaktur.trim().isEmpty) {
      CherryToast.error(title: const Text("No Faktur Supplier wajib diisi")).show(context);
      return;
    }

    if (selectedSupplierId.value == null || selectedSupplierId.value!.trim().isEmpty) {
      CherryToast.error(title: const Text("Pilih pemasok terlebih dahulu")).show(context);
      return;
    }
    if (itemRows.isEmpty) {
      CherryToast.error(title: const Text("Item masih kosong")).show(context);
      return;
    }

    final detail = <Map<String, dynamic>>[];
    for (final r in itemRows) {
      final idStr = r['itemId'] as String?;
      final qty = int.tryParse((r['qty'] as TextEditingController).text.trim()) ?? 0;
      final harga =
          int.tryParse(
            (r['price'] as TextEditingController).text.trim().replaceAll('.', '').replaceAll(',', ''),
          ) ??
          0;
      if (idStr == null || idStr.isEmpty || qty <= 0 || harga < 0) {
        CherryToast.error(
          title: const Text("Cek lagi baris item. Ada yang belum lengkap/valid."),
        ).show(context);
        return;
      }
      final supplierItemId = int.tryParse(idStr) ?? -1; // supplier_items.id
      if (supplierItemId <= 0) {
        CherryToast.error(title: const Text("ID item tidak valid")).show(context);
        return;
      }
      detail.add({"supplier_item_id": supplierItemId, "qty": qty, "harga_beli": harga});
    }

    final body = {
      "no_faktur": noFaktur,
      "tanggal_form": DateFormat('yyyy-MM-dd').format(tanggalForm),
      "id_supplier": selectedSupplierId.value!,
      "items": detail,
    };

    try {
      final res = await dio.post('$_base/pembelian/simpan', data: body);
      final idForm = res.data?['data']?['id_form'];
      CherryToast.success(title: Text("Tersimpan • $idForm")).show(context);

      // CLEAR ALL
      selectedSupplierId.value = null;
      supplierItems.clear();
      _clearAllFieldsAfterSave(tanggalForm);
    } on DioException catch (e) {
      CherryToast.error(
        title: const Text("Gagal simpan"),
        description: Text("${e.response?.statusCode} ${e.response?.data ?? e.message}"),
      ).show(context);
    } catch (e) {
      CherryToast.error(title: const Text("Gagal simpan"), description: Text("$e")).show(context);
    }
  }

  void _clearAllFieldsAfterSave(DateTime tgl) {
    // kosongkan baris & input
    clearAllItemRows();
    addItemRow();
    // regenerate no form
    refreshNoForm(tgl);
  }
}

class PesananPembelian extends StatefulWidget {
  const PesananPembelian({super.key});

  @override
  State<PesananPembelian> createState() => _PesananPembelianState();
}

class _PesananPembelianState extends State<PesananPembelian> {
  final _dateC = TextEditingController();
  final _noFormC = TextEditingController();
  final _fakturC = TextEditingController();
  DateTime? _selectedDate;

  late final POPemasokController c;
  Worker? _noFormWorker;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _dateC.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
    c = Get.put(POPemasokController());

    // sinkronkan no form auto ke textfield tanpa mengubah layout
    _noFormWorker = ever<String>(c.noForm, (v) => _noFormC.text = v);
    // generate pertama kali
    c.refreshNoForm(_selectedDate!);
  }

  @override
  void dispose() {
    _noFormWorker?.dispose();
    _dateC.dispose();
    _noFormC.dispose();
    _fakturC.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateC.text = DateFormat('dd/MM/yyyy').format(picked);
      });
      await c.refreshNoForm(picked); // update no form saat tanggal berubah
    }
  }

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(fontFamily: 'Poppins');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Pembelian', style: TextStyle(fontFamily: 'Poppins', fontSize: 40)),
        centerTitle: true,
        backgroundColor: const Color(0XFFFFE0B2),
      ),
      body: Container(
        decoration: const BoxDecoration(color: Color(0XFFFFE0B2)),
        width: Get.width,
        height: Get.height,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: SizedBox(
                              width: Get.width * 0.4,
                              child: TextFormField(
                                controller: _noFormC, // auto
                                decoration: const InputDecoration(
                                  labelText: 'No Form',
                                  labelStyle: labelStyle,
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey, width: 1.5),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 11),
                          SizedBox(
                            width: Get.width * 0.4,
                            child: TextFormField(
                              controller: _fakturC, // no faktur
                              decoration: const InputDecoration(
                                labelText: 'No Faktur Supplier',
                                labelStyle: labelStyle,
                                border: OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey, width: 1.5),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: SizedBox(
                              width: Get.width * 0.4,
                              child: TextFormField(
                                controller: _dateC,
                                readOnly: true,
                                onTap: _pickDate,
                                decoration: const InputDecoration(
                                  labelText: 'Tanggal Form',
                                  labelStyle: labelStyle,
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey, width: 1.5),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 11),
                          SizedBox(
                            width: Get.width * 0.4,
                            child: Obx(
                              () => DropdownButtonFormField<String>(
                                value: c.selectedSupplierId.value,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Pemasok',
                                  hintText: 'Pilih Pemasok',
                                  labelStyle: labelStyle,
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey, width: 1.5),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                items:
                                    c.suppliers
                                        .map(
                                          (e) => DropdownMenuItem<String>(
                                            value: e['id_supplier']?.toString(),
                                            child: Text(
                                              '${e['id_supplier'] ?? '-'} - ${e['nama_supplier'] ?? '-'}',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (v) async => await c.onSupplierChanged(v),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: GestureDetector(
                      onTap: () async {
                        if (_fakturC.text.trim().isEmpty) {
                          CherryToast.error(
                            title: const Text("No Faktur Supplier wajib diisi"),
                          ).show(context);
                          return;
                        }

                        await c.simpanPembelian(
                          noFaktur: _fakturC.text.trim(),
                          tanggalForm: _selectedDate ?? DateTime.now(),
                          context: context,
                        );
                        // bersihkan input UI lain
                        _fakturC.clear();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white),
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        height: 120,
                        width: 120,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(padding: EdgeInsets.only(top: 10), child: Icon(Icons.save, size: 80)),
                            Text('Simpan', style: TextStyle(fontSize: 15, fontFamily: 'Poppins')),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // =========================================================
              // Container LIST INPUT ITEM DIBELI
              // =========================================================
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: Get.width,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "Daftar Item Dibeli",
                          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        const SizedBox(height: 8),

                        // Header kolom
                        Row(
                          children: const [
                            SizedBox(
                              width: 48,
                              child: Text(
                                "No",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              flex: 4,
                              child: Text(
                                "Nama Item",
                                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "Qty",
                                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: Text(
                                "Harga",
                                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: Text(
                                "Total",
                                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                              ),
                            ),
                            SizedBox(width: 8),
                            SizedBox(width: 40),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Baris input (ikut scroll halaman)
                        Obx(() {
                          if (c.itemRows.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                "Belum ada baris. Tekan 'Tambah Baris'.",
                                style: TextStyle(fontFamily: 'Poppins'),
                              ),
                            );
                          }

                          return Column(
                            children: List.generate(c.itemRows.length, (i) {
                              final r = c.itemRows[i];
                              final qtyC = r['qty'] as TextEditingController;
                              final priceC = r['price'] as TextEditingController;
                              final selItemId = r['itemId'] as String?;
                              final total = c.lineTotal(r);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    // No
                                    SizedBox(
                                      width: 48,
                                      child: Text(
                                        '${i + 1}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontFamily: 'Poppins'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Nama Item (Dropdown) -> supplier_items
                                    Expanded(
                                      flex: 4,
                                      child: Obx(
                                        () => DropdownButtonFormField<String>(
                                          value: selItemId,
                                          isExpanded: true,
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            labelText: "Nama Item",
                                            border: OutlineInputBorder(),
                                          ),
                                          items:
                                              c.supplierItems
                                                  .map(
                                                    (it) => DropdownMenuItem<String>(
                                                      value: it['id']?.toString(),
                                                      child: Text(
                                                        '${it['nama_item'] ?? '-'} - ${it['satuan'] ?? '-'}',
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                          onChanged: (val) {
                                            if (c.selectedSupplierId.value == null) {
                                              CherryToast.error(
                                                title: const Text("Pilih pemasok terlebih dahulu"),
                                              ).show(Get.context!);
                                              return;
                                            }
                                            r['itemId'] = val;

                                            // auto set harga dari supplier_items
                                            final item = c.itemById(val);
                                            if (item != null) {
                                              priceC.text = c._priceString(item['harga_item']);
                                            }
                                            c.itemRows.refresh();
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Qty
                                    Expanded(
                                      flex: 2,
                                      child: TextField(
                                        controller: qtyC,
                                        onChanged: (_) => c.itemRows.refresh(),
                                        keyboardType: const TextInputType.numberWithOptions(decimal: false),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          labelText: "Qty",
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Harga
                                    Expanded(
                                      flex: 3,
                                      child: TextField(
                                        controller: priceC,
                                        onChanged: (_) => c.itemRows.refresh(),
                                        keyboardType: const TextInputType.numberWithOptions(decimal: false),
                                        inputFormatters: <TextInputFormatter>[RupiahInputFormatter()], //
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(),
                                          hintText: "Harga ",
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Total (readOnly)
                                    Expanded(
                                      flex: 3,
                                      child: TextField(
                                        readOnly: true,
                                        controller: TextEditingController(text: c.money(total)),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          labelText: "Total",
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Hapus baris
                                    SizedBox(
                                      width: 40,
                                      child: IconButton(
                                        tooltip: 'Hapus baris',
                                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                                        onPressed: () => c.removeItemRow(i),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          );
                        }),

                        // Tambah Baris
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () {
                              if (c.selectedSupplierId.value == null) {
                                CherryToast.error(
                                  title: const Text("Pilih pemasok terlebih dahulu"),
                                ).show(context);
                                return;
                              }
                              if (c.supplierItems.isEmpty) {
                                CherryToast.error(
                                  title: const Text("Pemasok tidak memiliki item"),
                                ).show(context);
                                return;
                              }
                              c.addItemRow();
                            },
                            icon: const Icon(Icons.add),
                            label: const Text("Tambah Baris", style: TextStyle(fontFamily: 'Poppins')),
                          ),
                        ),

                        const Divider(height: 24),

                        // Ringkasan total
                        Obx(
                          () => Align(
                            alignment: Alignment.centerRight,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "Subtotal: ${c.money(c.subtotal)}",
                                  style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Grand Total: ${c.money(c.grandTotal)}",
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
