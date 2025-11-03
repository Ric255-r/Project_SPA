import 'package:Project_SPA/function/admin_drawer.dart';
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

  // Item milik supplier terpilih
  final RxList<Map<String, dynamic>> supplierItems = <Map<String, dynamic>>[].obs;

  // Baris input item yang akan dibeli
  final RxList<Map<String, dynamic>> itemRows = <Map<String, dynamic>>[].obs;

  // No Form auto
  final RxString noForm = ''.obs;

  // ===== Diskon =====
  final RxString discountMode = 'amount'.obs; // 'amount' | 'percent'
  final RxInt discountAmount = 0.obs; // rupiah bulat
  final RxDouble discountPercent = 0.0.obs; // 0..100

  // ===== Pajak (2 desimal) =====
  final RxDouble taxAmount = 0.0.obs; // rupiah desimal (mis. 1234.56)

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
    selectedSupplierId.value = null;
    fetchSuppliers();
    addItemRow();
  }

  @override
  void onClose() {
    for (final r in itemRows) {
      (r['qty'] as TextEditingController).dispose();
      (r['price'] as TextEditingController).dispose();
      (r['purchaseUnit'] as TextEditingController).dispose();
      (r['factor'] as TextEditingController).dispose();
      (r['total'] as TextEditingController).dispose();
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

  // ================= SUPPLIER ITEMS =================
  Future<void> fetchSupplierItems(String? idSupplier) async {
    supplierItems.clear();
    if (idSupplier == null || idSupplier.isEmpty) return;
    try {
      final res = await dio.get('$_base/supplier/$idSupplier/items?_ts=${_ts()}', options: _noCache);
      if (res.data is List) {
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
    final qty = TextEditingController();
    final price = TextEditingController();
    final unit = TextEditingController(text: '');
    final factor = TextEditingController(text: '');
    final total = TextEditingController();

    // Seed awal supaya tidak kosong
    total.text = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(0);
    itemRows.add({
      'itemId': null, // supplier_items.id (opsional)
      'qty': TextEditingController(),
      'price': TextEditingController(),
      'purchaseUnit': TextEditingController(text: ''),
      'factor': TextEditingController(text: ''),
      'total': TextEditingController(), // total baris (editable)
    });
  }

  void removeItemRow(int index) {
    if (index < 0 || index >= itemRows.length) return;
    (itemRows[index]['qty'] as TextEditingController).dispose();
    (itemRows[index]['price'] as TextEditingController).dispose();
    (itemRows[index]['purchaseUnit'] as TextEditingController).dispose();
    (itemRows[index]['factor'] as TextEditingController).dispose();
    (itemRows[index]['total'] as TextEditingController).dispose();
    itemRows.removeAt(index);
  }

  void clearAllItemRows() {
    for (final r in itemRows) {
      (r['qty'] as TextEditingController).dispose();
      (r['price'] as TextEditingController).dispose();
      (r['purchaseUnit'] as TextEditingController).dispose();
      (r['factor'] as TextEditingController).dispose();
      (r['total'] as TextEditingController).dispose();
    }
    itemRows.clear();
  }

  // ================= HELPER PARSE & FORMAT =================
  String _stripCurrency(String s) {
    // sisakan digit, titik, koma, minus
    return s.replaceAll(RegExp(r'[^0-9,.\-]'), '');
  }

  // PERBAIKAN UTAMA: heuristik titik/koma agar "20.000" dibaca 20000 (bukan 20.0)
  double _parseNumFlexible(String s) {
    if (s.isEmpty) return 0.0;
    var t = _stripCurrency(s);
    if (t.isEmpty) return 0.0;

    final hasDot = t.contains('.');
    final hasComma = t.contains(',');

    if (hasDot && hasComma) {
      // Contoh: "1.234,56" -> ribuan '.', desimal ','
      t = t.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(t) ?? 0.0;
    }

    if (hasComma && !hasDot) {
      // Contoh: "1234,56" -> desimal ','
      t = t.replaceAll(',', '.');
      return double.tryParse(t) ?? 0.0;
    }

    if (hasDot && !hasComma) {
      // Hanya titik: cek pola ribuan 1.234(.567)*
      final thousandsPattern = RegExp(r'^\d{1,3}(\.\d{3})+$');
      if (thousandsPattern.hasMatch(t)) {
        // Anggap titik sebagai pemisah ribuan
        t = t.replaceAll('.', '');
        return double.tryParse(t) ?? 0.0;
      } else {
        // Titik dianggap desimal (misal "12.5")
        return double.tryParse(t) ?? 0.0;
      }
    }

    // Tanpa titik & koma: langsung parse
    return double.tryParse(t) ?? 0.0;
  }

  int _parseCurrencyToInt(String s) {
    final onlyDigits = s.replaceAll(RegExp(r'[^0-9]'), '');
    if (onlyDigits.isEmpty) return 0;
    return int.tryParse(onlyDigits) ?? 0;
  }

  // ================= HITUNG TOTAL =================
  num lineTotal(Map<String, dynamic> r) {
    final q = _parseNumFlexible((r['qty'] as TextEditingController).text.trim());
    final p = _parseNumFlexible((r['price'] as TextEditingController).text.trim());
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

  // ===== setter Diskon/Pajak =====
  void setDiscountText(String text) {
    if (discountMode.value == 'amount') {
      discountAmount.value = _parseCurrencyToInt(text);
    } else {
      final v = _parseNumFlexible(text);
      discountPercent.value = v.clamp(0.0, 100.0);
    }
  }

  void setTaxText(String text) {
    if (text.trim().isEmpty) {
      taxAmount.value = 0.0;
      return;
    }
    var v = _parseNumFlexible(text);
    v = (v * 100).round() / 100.0; // 2 desimal
    if (v < 0) v = 0.0;
    taxAmount.value = v;
  }

  // ===== Nominal Diskon =====
  int get discountNominal {
    final sub = subtotal.round();
    if (discountMode.value == 'percent') {
      final d = (sub * (discountPercent.value / 100.0)).floor();
      return d.clamp(0, sub);
    }
    return discountAmount.value.clamp(0, sub);
  }

  // ===== Grand total sebelum pembulatan (setelah diskon + pajak) =====
  double get grandTotalFinal {
    final net = (subtotal - discountNominal).toDouble() + taxAmount.value;
    return net < 0 ? 0.0 : ((net * 100).round() / 100.0); // pastikan 2 desimal
  }

  // ===== Aturan pembulatan: 2 digit desimal >= 50 => ceil, else floor =====
  int _roundByCentsRule(double amount) {
    final intPart = amount.floor();
    int cents = ((amount - intPart) * 100).round(); // 0..99
    if (cents >= 50) return intPart + 1;
    return intPart;
  }

  // Grand total dibulatkan sesuai aturan
  int get grandTotalRounded => _roundByCentsRule(grandTotalFinal);

  // ===== Format uang =====
  String money0(num n) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(n);
  String money2(num n) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 2).format(n);

  // ================= SIMPAN =================
  Future<void> simpanPembelian({
    required String noFaktur,
    required DateTime tanggalForm,
    required BuildContext context,
  }) async {
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
      final idStr = r['itemId'] as String?; // referensi dropdown
      final selected = itemById(idStr);
      final namaItem = (selected?['nama_item'] ?? '').toString().trim();

      final qty = _parseNumFlexible((r['qty'] as TextEditingController).text.trim()).round();
      final harga = _parseCurrencyToInt((r['price'] as TextEditingController).text.trim());
      final purchaseUnit = (r['purchaseUnit'] as TextEditingController).text.trim();
      final factor = _parseNumFlexible((r['factor'] as TextEditingController).text.trim());

      if (namaItem.isEmpty || qty <= 0 || harga < 0 || purchaseUnit.isEmpty || factor <= 0) {
        CherryToast.error(
          title: const Text("Cek lagi baris item. Ada yang belum lengkap/valid."),
        ).show(context);
        return;
      }

      final row = {
        'nama_item': namaItem,
        'purchase_unit': purchaseUnit,
        'factor_to_pcs': factor,
        'qty': qty,
        'harga_beli': harga,
      };

      if (idStr != null && idStr.isNotEmpty) {
        final supplierItemId = int.tryParse(idStr);
        if (supplierItemId != null && supplierItemId > 0) {
          row['supplier_item_id'] = supplierItemId;
        }
      }
      detail.add(row);
    }

    final body = {
      "no_faktur": noFaktur,
      "tanggal_form": DateFormat('yyyy-MM-dd').format(tanggalForm),
      "id_supplier": selectedSupplierId.value!,
      "diskon_type": discountMode.value,
      "diskon_value": discountMode.value == 'percent' ? discountPercent.value : discountAmount.value,
      "diskon": discountNominal,
      "pajak": taxAmount.value, // desimal
      "items": detail,
      // "grand_total_bulat": grandTotalRounded, // jika backend perlu
    };

    try {
      final res = await dio.post('$_base/pembelian/simpan', data: body);
      final idForm = res.data?['data']?['id_form'] ?? res.data?['id_form'];
      CherryToast.success(title: Text("Tersimpan • ${idForm ?? ''}")).show(context);

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
    clearAllItemRows();
    addItemRow();
    refreshNoForm(tgl);
    discountMode.value = 'amount';
    discountAmount.value = 0;
    discountPercent.value = 0.0;
    taxAmount.value = 0.0;
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
  final _diskonC = TextEditingController();
  final _pajakC = TextEditingController(); // controller pajak

  DateTime? _selectedDate;

  late final POPemasokController c;
  Worker? _noFormWorker;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _dateC.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
    c = Get.put(POPemasokController());
    _noFormC.text = c.noForm.value;
    _noFormWorker = ever<String>(c.noForm, (v) => _noFormC.text = v);
    c.refreshNoForm(_selectedDate!);
  }

  @override
  void dispose() {
    _noFormWorker?.dispose();
    _dateC.dispose();
    _noFormC.dispose();
    _fakturC.dispose();
    _diskonC.dispose();
    _pajakC.dispose();
    Get.delete<POPemasokController>();
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
      await c.refreshNoForm(picked);
    }
  }

  // Util: format rupiah bulat pada TextEditingController
  void _setMoney0(TextEditingController ctrl, num value) {
    ctrl.text = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(value);
  }

  // handler ubah "Total" → hitung price = total / qty
  void _applyTotalToPrice({
    required TextEditingController qtyC,
    required TextEditingController priceC,
    required TextEditingController totalC,
  }) {
    final qty = c._parseNumFlexible(qtyC.text.trim());
    final desiredTotal = c._parseCurrencyToInt(totalC.text.trim());
    if (qty <= 0) {
      CherryToast.error(title: const Text("Qty harus > 0 untuk mengubah Total.")).show(Get.context!);
      final computed = c.lineTotal({'qty': qtyC, 'price': priceC});
      _setMoney0(totalC, computed);
      return;
    }
    final newPrice = (desiredTotal / qty).round(); // harga bulat
    priceC.text = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(newPrice);
    final recomputed = (qty * newPrice).round();
    _setMoney0(totalC, recomputed);
    c.itemRows.refresh();
    setState(() {});
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
      drawer: AdminDrawer(),
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
                                controller: _noFormC,
                                readOnly: true,
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
                              controller: _fakturC,
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
                                  labelText: 'Supplier',
                                  hintText: 'Pilih Supplier',
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
                        _fakturC.clear();
                        _diskonC.clear();
                        _pajakC.clear();
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
              // Container LIST INPUT ITEM DIBELI (Responsif, anti-overflow)
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

                        // Baris input (responsif)
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

                          return LayoutBuilder(
                            builder: (ctx, cons) {
                              final isNarrow = cons.maxWidth < 1050;

                              return Column(
                                children: List.generate(c.itemRows.length, (i) {
                                  final r = c.itemRows[i];
                                  final qtyC = r['qty'] as TextEditingController;
                                  final priceC = r['price'] as TextEditingController;
                                  final unitC = r['purchaseUnit'] as TextEditingController;
                                  final factorC = r['factor'] as TextEditingController;
                                  final totalC = r['total'] as TextEditingController;
                                  final selItemId = r['itemId'] as String?;
                                  final totalCalc = c.lineTotal(r);

                                  // sinkronisasi otomatis total ketika qty/price berubah
                                  void _syncTotalFromQtyPrice() {
                                    _setMoney0(totalC, totalCalc);
                                  }

                                  // widgets kecil agar reusable
                                  Widget namaItemDD() => Obx(
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
                                        c.itemRows.refresh();
                                      },
                                    ),
                                  );

                                  Widget qtyField() => TextField(
                                    controller: qtyC,
                                    onChanged: (_) {
                                      _syncTotalFromQtyPrice();
                                      c.itemRows.refresh();
                                    },
                                    keyboardType: const TextInputType.numberWithOptions(decimal: false),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      labelText: "Qty",
                                      border: OutlineInputBorder(),
                                    ),
                                  );

                                  Widget hargaField() => TextField(
                                    controller: priceC,
                                    onChanged: (_) {
                                      _syncTotalFromQtyPrice();
                                      c.itemRows.refresh();
                                    },
                                    keyboardType: const TextInputType.numberWithOptions(decimal: false),
                                    inputFormatters: <TextInputFormatter>[RupiahInputFormatter()],
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: "Harga",
                                      isDense: true,
                                    ),
                                  );

                                  Widget unitField() => TextField(
                                    controller: unitC,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      labelText: "Unit",
                                      border: OutlineInputBorder(),
                                    ),
                                  );

                                  Widget faktorField() => TextField(
                                    controller: factorC,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      labelText: "Faktor",
                                      border: OutlineInputBorder(),
                                    ),
                                  );

                                  // Total editable: ketika user Enter/blur → set price = total / qty
                                  Widget totalField() => TextField(
                                    controller: totalC,
                                    onSubmitted:
                                        (_) => _applyTotalToPrice(qtyC: qtyC, priceC: priceC, totalC: totalC),
                                    onEditingComplete:
                                        () => _applyTotalToPrice(qtyC: qtyC, priceC: priceC, totalC: totalC),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: false),
                                    inputFormatters: <TextInputFormatter>[RupiahInputFormatter()],
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      labelText: "Total",
                                      border: OutlineInputBorder(),
                                    ),
                                  );

                                  Widget deleteBtn() => SizedBox(
                                    width: 40,
                                    child: IconButton(
                                      tooltip: 'Hapus baris',
                                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                                      onPressed: () => c.removeItemRow(i),
                                    ),
                                  );

                                  if (!isNarrow) {
                                    // 1 baris (lebar)
                                    _syncTotalFromQtyPrice();
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 48,
                                            child: Text(
                                              '${i + 1}',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(fontFamily: 'Poppins'),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(flex: 5, child: namaItemDD()),
                                          const SizedBox(width: 8),
                                          Expanded(flex: 2, child: qtyField()),
                                          const SizedBox(width: 8),
                                          Expanded(flex: 3, child: hargaField()),
                                          const SizedBox(width: 8),
                                          Expanded(flex: 2, child: unitField()),
                                          const SizedBox(width: 8),
                                          Expanded(flex: 2, child: faktorField()),
                                          const SizedBox(width: 8),
                                          Expanded(flex: 3, child: totalField()), // editable
                                          const SizedBox(width: 8),
                                          deleteBtn(),
                                        ],
                                      ),
                                    );
                                  }

                                  // 2 baris (sempit)
                                  _syncTotalFromQtyPrice();
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            SizedBox(
                                              width: 48,
                                              child: Text(
                                                '${i + 1}',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(fontFamily: 'Poppins'),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(flex: 4, child: namaItemDD()),
                                            const SizedBox(width: 8),
                                            Expanded(flex: 2, child: qtyField()),
                                            const SizedBox(width: 8),
                                            Expanded(flex: 2, child: unitField()),
                                            const SizedBox(width: 8),
                                            Expanded(flex: 3, child: hargaField()),
                                            const SizedBox(width: 8),
                                            Expanded(flex: 2, child: faktorField()),
                                            const SizedBox(width: 8),
                                            Expanded(flex: 4, child: totalField()),
                                            const SizedBox(width: 8),
                                            deleteBtn(),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              );
                            },
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

                        // Ringkasan total + Diskon + Pajak + Pembulatan
                        Obx(
                          () => Align(
                            alignment: Alignment.centerRight,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "Subtotal: ${c.money0(c.subtotal)}",
                                  style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),

                                // Input Diskon
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    const Text("Diskon: ", style: TextStyle(fontFamily: 'Poppins')),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 150,
                                      child: DropdownButtonFormField<String>(
                                        value: c.discountMode.value,
                                        isExpanded: true,
                                        items: const [
                                          DropdownMenuItem(value: 'amount', child: Text('Nominal (Rp)')),
                                          DropdownMenuItem(value: 'percent', child: Text('Persen (%)')),
                                        ],
                                        onChanged: (v) {
                                          if (v == null) return;
                                          setState(() {
                                            c.discountMode.value = v;
                                            _diskonC.text = '';
                                            if (v == 'amount') {
                                              c.discountPercent.value = 0.0;
                                            } else {
                                              c.discountAmount.value = 0;
                                            }
                                          });
                                        },
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          border: OutlineInputBorder(),
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 180,
                                      child: TextField(
                                        controller: _diskonC,
                                        onChanged: (v) => c.setDiscountText(v),
                                        inputFormatters:
                                            c.discountMode.value == 'amount'
                                                ? <TextInputFormatter>[RupiahInputFormatter()]
                                                : <TextInputFormatter>[
                                                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                                                ],
                                        keyboardType:
                                            c.discountMode.value == 'amount'
                                                ? const TextInputType.numberWithOptions(decimal: false)
                                                : const TextInputType.numberWithOptions(decimal: true),
                                        textAlign: TextAlign.right,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          hintText: c.discountMode.value == 'amount' ? "0" : "0 - 100",
                                          suffixText: c.discountMode.value == 'amount' ? null : "%",
                                          border: const OutlineInputBorder(),
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                if (c.discountMode.value == 'percent') ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    "≈ Potongan: ${c.money0(c.discountNominal)}",
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],

                                // Pajak
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    const Text("Pajak (Rp): ", style: TextStyle(fontFamily: 'Poppins')),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 180,
                                      child: TextField(
                                        controller: _pajakC,
                                        onChanged: (v) {
                                          c.setTaxText(v);
                                          setState(() {});
                                        },
                                        inputFormatters: <TextInputFormatter>[
                                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                                        ],
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        textAlign: TextAlign.right,
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          hintText: "0,00",
                                          border: OutlineInputBorder(),
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),
                                // Tampilkan sebelum & sesudah pembulatan
                                Text(
                                  "Grand Total (sebelum pembulatan): ${c.money2(c.grandTotalFinal)}",
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                Text(
                                  "Grand Total: ${c.money0(c.grandTotalRounded)}",
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
