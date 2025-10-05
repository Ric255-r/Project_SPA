import 'dart:developer';

import 'package:Project_SPA/function/ip_address.dart';
import 'package:Project_SPA/resepsionis/detail_food_n_beverages.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';

class DaftarFakturPembelianController extends GetxController {
  RxList<DateTime?> rangeDatePickerSupplier = <DateTime?>[].obs;
  ScrollController scrollTglController = ScrollController();
  Dio dio = Dio();
  RxList<Map<String, dynamic>> suppliers = <Map<String, dynamic>>[].obs;
  RxnString selectedSupplierId = RxnString(null);
  TextEditingController txtTglController = TextEditingController();
  RxList<Map<String, dynamic>> dataFaktur = <Map<String, dynamic>>[].obs;
  // TAMBAHKAN INI: Variabel untuk "STATE UI" dropdown
  Rxn<Map<String, dynamic>> uiSelectedSupplier = Rxn(null);
  RxBool hasSearched = false.obs;

  @override
  void onClose() {
    // TODO: implement onClose
    try {
      scrollTglController.dispose();
    } catch (_) {}
    try {
      selectedSupplierId.close();
    } catch (_) {}
    try {
      txtTglController.dispose();
    } catch (_) {}
    try {
      uiSelectedSupplier.close();
    } catch (_) {}
    super.onClose();
  }

  String indonesianDateFormat(DateTime date) {
    return '${(date.day).toString().padLeft(2, '0')}-${(date.month).toString().padLeft(2, '0')}-${date.year}';
  }

  Future<void> fetchSuppliers() async {
    try {
      final res = await dio.get('${myIpAddr()}/supplier/listsupplier');
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
    } catch (e) {
      suppliers.assignAll([]);
      selectedSupplierId.value = null;
    }
  }

  Future<void> fetchFakturPembelian() async {
    try {
      String url =
          '${myIpAddr()}/pembelian/list_faktur_pembelian?id_supplier=${selectedSupplierId.value ?? "-"}';
      if (rangeDatePickerSupplier.isNotEmpty) {
        // Jika ada minimal 1 tanggal, tambahkan start_date
        final startDate = rangeDatePickerSupplier[0]!.toString().split(" ")[0];
        url += '&start_date=$startDate';

        // Jika ada tanggal kedua, tambahkan juga end_date
        if (rangeDatePickerSupplier.length > 1) {
          final endDate = rangeDatePickerSupplier[1]!.toString().split(" ")[0];
          url += '&end_date=$endDate';
        }
      }

      var response = await dio.get(url);

      dataFaktur.assignAll((response.data as List).map((el) => {...el}));

      log("response data faktur : ${dataFaktur}");
    } catch (e) {
      if (e is DioException) {
        log("Error di fetchFakturPembelian Dio ${e.response!.data}");
      }

      log("Error di fetchFakturPembelian $e");
    }
  }

  Future<void> showTglDialog() async {
    rangeDatePickerSupplier.clear();
    txtTglController.text = '';

    await Get.dialog(
      AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        content: Builder(
          builder: (context) {
            final mq = MediaQuery.of(context);
            final isPortrait = mq.orientation == Orientation.landscape;

            // Tentukan ukuran dialog yang TEGAS (tight), responsif ke layar
            final maxDialogWidth = 500.0; // cap untuk tablet/layar lebar
            final dialogWidth = mq.size.width.clamp(0.0, maxDialogWidth);
            final dialogHeight = (isPortrait ? mq.size.height * 0.7 : mq.size.height * 0.8) - 110;

            return SizedBox(
              width: dialogWidth,
              height: dialogHeight, // <- TIGHT! tidak ada intrinsic ke anak
              child: Scrollbar(
                controller: scrollTglController,
                thumbVisibility: true,
                child: ListView(
                  // Penting: biarkan default (shrinkWrap: false)
                  controller: scrollTglController,
                  padding: const EdgeInsets.only(right: 4, bottom: 8),
                  children: [
                    const Text(
                      "Petunjuk : Anda bisa memilih lebih dari 1 Tanggal",
                      style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),

                    // Isi lebar dialog
                    SizedBox(
                      width: double.infinity,
                      child: Obx(
                        () => CalendarDatePicker2(
                          config: CalendarDatePicker2Config(
                            calendarType: CalendarDatePicker2Type.range,
                            selectedDayHighlightColor: Colors.deepPurple,
                            selectedRangeHighlightColor: Colors.purpleAccent.withOpacity(0.2),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          ),
                          value: rangeDatePickerSupplier,
                          onValueChanged: (dates) {
                            rangeDatePickerSupplier.assignAll(dates);
                            log("Isi Range Date $rangeDatePickerSupplier");
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        actions: [
          ElevatedButton(
            onPressed: () async {
              Get.back();
            },
            child: const Text("SUBMIT"),
          ),
        ],
      ),
    );
  }
}

class DaftarFakturPembelian extends StatelessWidget {
  DaftarFakturPembelian({super.key});

  final c = Get.put(DaftarFakturPembelianController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Faktur Pembelian', style: TextStyle(fontFamily: 'Poppins', fontSize: 40)),
        centerTitle: true,
        backgroundColor: const Color(0XFFFFE0B2),
      ),
      body: Container(
        decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
        padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onTap: () async {
                      await c.showTglDialog();

                      if (c.rangeDatePickerSupplier.isEmpty) {
                        // Jika kosong (pengguna tidak memilih tanggal), hentikan proses.
                        print("Tidak ada tanggal yang dipilih.");
                        return; // Keluar dari fungsi onTap
                      }

                      DateTime startDate = c.rangeDatePickerSupplier[0]!;
                      DateTime? endDate;
                      if (c.rangeDatePickerSupplier.length > 1) {
                        endDate = c.rangeDatePickerSupplier[1]!;
                        c.txtTglController.text =
                            "${c.indonesianDateFormat(startDate)} s/d ${c.indonesianDateFormat(endDate)}";
                      } else {
                        c.txtTglController.text = c.indonesianDateFormat(startDate);
                      }
                    },
                    controller: c.txtTglController,
                    readOnly: true,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: "Tanggal",
                      border: OutlineInputBorder(),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
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
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Obx(() {
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
                      selectedItem: c.uiSelectedSupplier.value,
                      itemAsString: (m) => "${m?['id_supplier']} - ${m?['nama_supplier']}",
                      onChanged: (myMap) async {
                        c.uiSelectedSupplier.value = myMap;
                        c.hasSearched.value = false;
                        c.dataFaktur.assignAll([]);
                      },
                      compareFn: (a, b) => a?['id_supplier'] == b?['id_supplier'],
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
                          fillColor: Colors.transparent,
                          floatingLabelBehavior: FloatingLabelBehavior.always,

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
                ),

                const SizedBox(width: 10),

                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // 1. Ambil ID dari state UI (pilihan dropdown terakhir)
                      final id = c.uiSelectedSupplier.value?['id_supplier']?.toString();

                      // 2. "Commit" atau simpan ID tersebut ke state utama
                      c.selectedSupplierId.value = id;

                      // 3. Panggil fetchFakturPembelian, yang akan menggunakan
                      //    selectedSupplierId.value yang sudah ter-update.
                      c.hasSearched.value = true;
                      c.fetchFakturPembelian();
                    },
                    icon: const Icon(Icons.search),
                    label: const Text(
                      "Tampil",
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, fontFamily: 'Poppins'),
                    ),
                  ),
                ),
              ],
            ),

            Obx(() {
              if (c.dataFaktur.isNotEmpty) {
                if (c.selectedSupplierId.value != null) {
                  int totalDataFaktur = c.dataFaktur.length;
                  Map selectedSupplier = c.suppliers.firstWhere(
                    (element) => element['id_supplier'].toString() == c.selectedSupplierId.value.toString(),
                  );

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Text(
                          "Supplier: ${selectedSupplier['nama_supplier']} - Total Data: $totalDataFaktur",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Text(
                          "Cetak Laporan - (${selectedSupplier['nama_supplier']})",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Text(
                        "Total Data: ${c.dataFaktur.length} - Seluruh Supplier",
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Text(
                        "Cetak Laporan",
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              }

              return SizedBox.shrink();
            }),

            const SizedBox(height: 20),

            Obx(() {
              if (c.dataFaktur.isNotEmpty) {
                return Expanded(
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: ListView.separated(
                      itemCount: c.dataFaktur.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = c.dataFaktur[index];

                        return ContainerDataFaktur(item: item);
                      },
                    ),
                  ),
                );
              } else {
                // 2. Jika data kosong, cek kenapa.
                if (c.hasSearched.isTrue) {
                  // Jika SUDAH mencari tapi hasilnya kosong.
                  return Center(
                    child: Text(
                      "Tidak ada data ditemukan untuk filter ini",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                } else {
                  // Jika BELUM mencari (misal, setelah mengubah supplier).
                  return Center(
                    child: Text(
                      "Silakan atur filter dan tekan 'Tampil'",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }
              }
            }),
          ],
        ),
      ),
    );
  }
}

class ContainerDataFaktur extends StatelessWidget {
  // ignore: prefer_typing_uninitialized_variables
  final item;
  const ContainerDataFaktur({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontSize: 13,
      color: Colors.grey.shade700,
      fontWeight: FontWeight.w600,
      height: 1.2,
    );
    final valueStyle = const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.2);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [BoxShadow(blurRadius: 10, offset: Offset(0, 2), color: Color(0x14000000))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KIRI: Informasi data (tetap Expanded + Column)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // No Faktur
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text("No Faktur :", style: labelStyle, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item['no_faktur'] ?? "-",
                        style: valueStyle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Id Form
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text("Id Form :", style: labelStyle, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "${item['id_form'] ?? '-'}",
                        style: valueStyle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Tanggal Form
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text("Tanggal Form :", style: labelStyle, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item['tanggal_form'] ?? "-",
                        style: valueStyle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Total
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text("Total :", style: labelStyle, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "${item['total'] ?? 0}",
                        style: valueStyle.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // KANAN: Tombol aksi (tetap Expanded + Row, tombol dibungkus Wrap agar rapi)
          Expanded(
            child: Align(
              alignment: Alignment.topRight,
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Tooltip(
                        message: 'Edit',
                        waitDuration: const Duration(milliseconds: 400),
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(40, 40),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Icon(Icons.edit, size: 20),
                        ),
                      ),
                      Tooltip(
                        message: 'Detail',
                        waitDuration: const Duration(milliseconds: 400),
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(40, 40),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Icon(Icons.visibility_outlined, size: 20),
                        ),
                      ),
                      Tooltip(
                        message: 'Print',
                        waitDuration: const Duration(milliseconds: 400),
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(40, 40),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Icon(Icons.print, size: 20),
                        ),
                      ),
                      Tooltip(
                        message: 'Void',
                        waitDuration: const Duration(milliseconds: 400),
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            minimumSize: const Size(40, 40),
                            padding: EdgeInsets.zero,
                            foregroundColor: Colors.red.shade600,
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Icon(Icons.block, size: 20),
                        ),
                      ),
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
}
