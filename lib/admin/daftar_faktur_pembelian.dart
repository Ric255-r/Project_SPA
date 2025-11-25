import 'dart:developer';

import 'package:Project_SPA/function/admin_drawer.dart';
import 'package:Project_SPA/function/ip_address.dart';
import 'package:Project_SPA/function/rupiah_formatter.dart';
import 'package:Project_SPA/owner/download_splash.dart';
import 'package:Project_SPA/resepsionis/detail_food_n_beverages.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

String formatrupiah(num amount) {
  final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  return formatter.format(amount);
}

String indonesianDateFormat(DateTime date) {
  return '${(date.day).toString().padLeft(2, '0')}-${(date.month).toString().padLeft(2, '0')}-${date.year}';
}

class HistoryPembelianController extends GetxController {
  RxList<DateTime?> rangeDatePickerSupplier = <DateTime?>[].obs;
  ScrollController scrollTglController = ScrollController();
  Dio dio = Dio();
  RxList<Map<String, dynamic>> suppliers = <Map<String, dynamic>>[].obs;
  RxnString selectedSupplierId = RxnString(null);
  TextEditingController txtTglController = TextEditingController();
  RxList<Map<String, dynamic>> dataFaktur = <Map<String, dynamic>>[].obs;
  // TAMBAHKAN INI: Variabel untuk "STATE UI" dropdown
  Rxn<Map<String, dynamic>> uiSelectedSupplier = Rxn(null);
  RxBool hasSearched = false.obs; // flag untuk trigger pas pencet btn tampil

  // --- TAMBAHANB VARIABEL BARU UNTUK MENAMPILKAN DIALOG ---
  RxBool isDetailLoading = false.obs;
  RxList<Map<String, dynamic>> detailFakturItems = <Map<String, dynamic>>[].obs;
  Rx<num> totalHargaDetailFaktur = Rx<num>(0);

  // Variabel untuk menyimpan TextController agar tidak hilang saat di-scroll
  List<TextEditingController> qtyControllers = [];
  List<TextEditingController> purchaseUnitControllers = [];
  List<TextEditingController> hargaControllers = [];

  // --- FUNGSI BARU UNTUK MENGHITUNG ULANG TOTAL ---
  void recalculateTotal() {
    double total = 0;
    for (var item in detailFakturItems) {
      total += (item['total'] ?? 0);
    }
    totalHargaDetailFaktur.value = total;
  }

  Future<void> showDetailDialog(Map<String, dynamic> faktur) async {
    // 1. Set loading jadi true dan kosongkan list lama
    isDetailLoading.value = true;
    detailFakturItems.clear();
    totalHargaDetailFaktur.value = 0;

    // 2. Tampilkan dialog SEGERA. Isinya akan reaktif.
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Detail Faktur", style: TextStyle(fontWeight: FontWeight.bold)),
                Obx(
                  () => Text(
                    "Total: ${formatrupiah(totalHargaDetailFaktur.value)}",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            Text(
              // ignore: prefer_interpolation_to_compose_strings
              "No Faktur Supplier: " + faktur['no_faktur'],
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
        content: Obx(() {
          // Tampilkan loading spinner jika sedang mengambil data
          if (isDetailLoading.isTrue) {
            return SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
          }

          // Tampilkan list item jika data sudah ada
          if (detailFakturItems.isEmpty) {
            return Text("Tidak ada item detail untuk faktur ini.");
          }

          // Untuk format angka
          final currencyFormat = NumberFormat.decimalPattern('id_ID');

          return SizedBox(
            width: Get.width * 0.8, // Agar dialog tidak terlalu lebar
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: detailFakturItems.length,
              itemBuilder: (context, index) {
                final item = detailFakturItems[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(
                      "${item['id_item'] ?? '-'} - ${item['nama_item'] ?? '-'}",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Qty: ${item['qty_purchase']} (${item['purchase_unit']}) x Rp ${currencyFormat.format(item['harga_per_purchase_unit'] ?? 0)}",
                    ),
                    trailing: Text(
                      "Rp ${currencyFormat.format(item['total'] ?? 0)}",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple, fontSize: 18),
                    ),
                  ),
                );
              },
            ),
          );
        }),
        actions: [TextButton(onPressed: () => Get.back(), child: const Text("TUTUP"))],
      ),
      // Mencegah dialog tertutup saat disentuh di luar area
      barrierDismissible: false,
    );

    // 3. Ambil data dari API setelah dialog muncul
    try {
      final idForm = faktur['id_form'];
      final response = await dio.get('${myIpAddr()}/pembelian/detail_faktur_pembelian?id_form=$idForm');

      final List<dynamic> responseData = response.data;

      detailFakturItems.assignAll(responseData.map((e) => e as Map<String, dynamic>).toList());
      recalculateTotal();
    } catch (e) {
      log("Gagal mengambil detail faktur: $e");
      // Opsional: Tampilkan pesan error dengan Get.snackbar
      Get.snackbar('Error', 'Gagal memuat detail data.');
    } finally {
      // 4. Pastikan loading disetel ke false setelah selesai
      isDetailLoading.value = false;
    }
  }

  // --- FUNGSI BARU: DIALOG VERSI EDIT ---
  Future<void> showEditDialog(Map<String, dynamic> faktur) async {
    isDetailLoading.value = true;
    detailFakturItems.clear();
    totalHargaDetailFaktur.value = 0;

    // Bersihkan controller lama sebelum digunakan lagi
    for (var controller in qtyControllers) {
      controller.dispose();
    }
    for (var controller in hargaControllers) {
      controller.dispose();
    }
    qtyControllers.clear();
    hargaControllers.clear();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Detail Faktur", style: TextStyle(fontWeight: FontWeight.bold)),
                Obx(
                  () => Text(
                    "Total: ${formatrupiah(totalHargaDetailFaktur.value)}",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            Text(
              // ignore: prefer_interpolation_to_compose_strings
              "No Faktur Supplier: " + faktur['no_faktur'],
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
        content: Obx(() {
          if (isDetailLoading.isTrue) {
            return SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
          }
          if (detailFakturItems.isEmpty) {
            return Text("Tidak ada item detail.");
          }

          return SizedBox(
            width: Get.width * 0.8,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: detailFakturItems.length,
              itemBuilder: (context, index) {
                final item = detailFakturItems[index];
                final currencyFormat = NumberFormat.decimalPattern('id_ID');

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${item['id_item']} - ${item['nama_item']}",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            // TextField untuk Qty
                            Expanded(
                              child: TextField(
                                controller: qtyControllers[index],
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Qty',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            // Purchase Unit
                            SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: purchaseUnitControllers[index],
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Satuan',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            // TextField untuk Harga Beli
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: hargaControllers[index],
                                keyboardType: TextInputType.number,
                                inputFormatters: <TextInputFormatter>[RupiahInputFormatter()],
                                decoration: InputDecoration(
                                  labelText: 'Harga Beli',
                                  prefixText: 'Rp ',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            "Total: Rp ${currencyFormat.format(item['total'] ?? 0)}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text("BATAL")),
          ElevatedButton(
            onPressed: () {
              // Panggil fungsi simpan
              saveFakturChanges(faktur['id_form']);
            },
            child: Text("SIMPAN"),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    // --- Ambil data dan BUAT TEXTEDITINGCONTROLLER ---
    try {
      final idForm = faktur['id_form'];
      final response = await dio.get('${myIpAddr()}/pembelian/detail_faktur_pembelian?id_form=$idForm');
      final List<dynamic> responseData = response.data;

      for (var data in responseData) {
        final itemMap = data as Map<String, dynamic>;

        // Buat controller untuk setiap item
        final qtyController = TextEditingController(text: itemMap['qty_purchase'].toString());
        final purchaseUnitController = TextEditingController(text: itemMap['purchase_unit']);
        final hargaController = TextEditingController(text: itemMap['harga_per_purchase_unit'].toString());

        // Tambahkan listener untuk update otomatis
        void updateItemTotal() {
          // 1. Ambil teks mentah dari controller
          final rawQtyText = qtyController.text;
          final rawHargaText = hargaController.text;

          // 2. Bersihkan teks dari karakter non-digit (titik, koma, dll.)
          final cleanQtyString = rawQtyText.replaceAll(RegExp(r'[^0-9]'), '');
          final cleanHargaString = rawHargaText.replaceAll(RegExp(r'[^0-9]'), '');

          // 3. Parsing string yang sudah bersih. Jika gagal, hasilnya 0.
          final qty = int.tryParse(cleanQtyString) ?? 0;
          final harga = int.tryParse(cleanHargaString) ?? 0;
          // --- AKHIR PERUBAHAN ---

          itemMap['qty_purchase'] = qty;
          itemMap['purchase_unit'] = purchaseUnitController.text;
          itemMap['harga_per_purchase_unit'] = harga;
          itemMap['total'] = qty * harga;
          // Refresh list agar UI terupdate & hitung ulang grand total
          detailFakturItems.refresh();
          recalculateTotal();
        }

        qtyController.addListener(updateItemTotal);
        hargaController.addListener(updateItemTotal);
        purchaseUnitController.addListener(updateItemTotal);

        qtyControllers.add(qtyController);
        purchaseUnitControllers.add(purchaseUnitController);
        hargaControllers.add(hargaController);
        detailFakturItems.add(itemMap);
      }
      recalculateTotal();
    } catch (e) {
      log("Gagal mengambil detail faktur: $e");
      Get.snackbar('Error', 'Gagal memuat detail data.');
    } finally {
      isDetailLoading.value = false;
    }
  }

  // --- FUNGSI BARU UNTUK MENGIRIM PERUBAHAN KE API ---
  Future<void> saveFakturChanges(String idForm) async {
    try {
      // Tampilkan loading overlay
      Get.dialog(Center(child: CircularProgressIndicator()), barrierDismissible: false);

      // Siapkan data untuk dikirim
      final List<Map<String, dynamic>> updatedItems = [];
      for (var item in detailFakturItems) {
        updatedItems.add({
          "id_item": item['id_item'],
          "qty_purchase": item['qty_purchase'],
          "harga_per_purchase_unit": item['harga_per_purchase_unit'],
        });
      }

      final payload = {"id_form": idForm, "items": updatedItems};

      // Kirim ke API
      await dio.put('${myIpAddr()}/pembelian/update_detail_faktur', data: payload);

      Get.back(); // Tutup loading overlay
      Get.back(); // Tutup dialog edit
      Get.snackbar('Sukses', 'Data faktur berhasil diperbarui!');

      // Refresh data di halaman utama
      fetchFakturPembelian();
    } catch (e) {
      Get.back(); // Tutup loading overlay
      log("Gagal menyimpan perubahan: $e");
      Get.snackbar('Error', 'Gagal menyimpan perubahan.');
    }
  }

  void pelunasanFaktur(String idForm) {
    Get.defaultDialog(
      title: "Konfirmasi Pelunasan",
      titleStyle: TextStyle(fontSize: 20),
      middleText: "Anda Yakin Ingin Melunasi Faktur Ini",
      textConfirm: "Ya, Lanjutkan",
      textCancel: "Batal",
      confirmTextColor: Colors.white,
      onConfirm: () async {
        Get.back();

        try {
          // KIRIM ULANG dengan objek FormData yang BARU
          await dio.put('${myIpAddr()}/pembelian/pelunasan_pembelian/$idForm');

          CherryToast.info(title: const Text("Faktur berhasil dilunasi")).show(Get.context!);

          fetchFakturPembelian();
        } catch (e) {
          log("Error saat mengirim ulang: $e");
          CherryToast.error(title: const Text("Terjadi Kesalahan")).show(Get.context!);
        }
      },
      onCancel: () {
        Get.back();
      },
    );
  }

  void cancelFaktur(String idForm) {
    Get.defaultDialog(
      title: "Konfirmasi Pembatalan",
      titleStyle: TextStyle(fontSize: 20),
      middleText: "Anda Yakin Ingin Membatalkan Faktur Ini",
      textConfirm: "Ya, Lanjutkan",
      textCancel: "Batal",
      confirmTextColor: Colors.white,
      onConfirm: () async {
        Get.back();

        try {
          // KIRIM ULANG dengan objek FormData yang BARU
          await dio.put('${myIpAddr()}/pembelian/cancel_pembelian/$idForm');

          CherryToast.info(title: const Text("Faktur berhasil Dibatalkan")).show(Get.context!);

          fetchFakturPembelian();
        } catch (e) {
          log("Error saat mengirim ulang: $e");
          CherryToast.error(title: const Text("Terjadi Kesalahan")).show(Get.context!);
        }
      },
      onCancel: () {
        Get.back();
      },
    );
  }

  Future<void> cetakLaporan() async {
    Get.dialog(
      const DownloadSplash(),
      barrierDismissible: true, // Prevent user from dismissing by tapping outside
    );

    try {
      final dir = await getDownloadsDirectory();
      final filePath = '${dir?.path}/history_datapembelian.pdf';

      // 1. Tentukan URL dasar (tanpa query parameter)
      String url = '${myIpAddr()}/main_owner/export_excel_history_pembelian';

      // 2. Buat Map untuk menampung query parameters
      final Map<String, dynamic> queryParams = {};

      if (rangeDatePickerSupplier.isNotEmpty) {
        List<dynamic> rangeDate = rangeDatePickerSupplier;
        if (rangeDate.isNotEmpty) {
          String startDate = rangeDate[0].toString().split(" ")[0];
          queryParams['start_date'] = startDate;

          if (rangeDate.length == 2) {
            String endDate = rangeDate[1].toString().split(" ")[0];
            queryParams['end_date'] = endDate;
          }
        }
      }

      if (selectedSupplierId.value != null) {
        queryParams['id_supplier'] = selectedSupplierId.value;
      }

      // 3. Masukkan Map ke parameter queryParameters di dio
      await dio.download(
        url,
        filePath,
        queryParameters: queryParams, // <--- Perubahan di sini
        options: Options(responseType: ResponseType.bytes, headers: {'Accept': 'application/pdf'}),
      );

      Get.back();

      // open downloaded file
      await OpenFile.open(filePath);
      log('File downloaded to: $filePath');
    } catch (e) {
      if (e is DioException) {
        log("Error di fn cetakLaporan DioException : ${e.response?.data['message']}");
      }
      log("Error di fn cetakLaporan : $e");
    }
  }

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
    try {
      totalHargaDetailFaktur.close();
    } catch (_) {}

    try {
      for (var controller in qtyControllers) {
        controller.dispose();
      }
      for (var controller in hargaControllers) {
        controller.dispose();
      }
    } catch (_) {}
    super.onClose();
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

class HistoryPembelian extends StatelessWidget {
  HistoryPembelian({super.key});

  final c = Get.put(HistoryPembelianController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History Pembelian', style: TextStyle(fontFamily: 'Poppins', fontSize: 40)),
        centerTitle: true,
        backgroundColor: const Color(0XFFFFE0B2),
      ),
      drawer: AdminDrawer(),
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
                            "${indonesianDateFormat(startDate)} s/d ${indonesianDateFormat(endDate)}";
                      } else {
                        c.txtTglController.text = indonesianDateFormat(startDate);
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
                int totalHargaFaktur = c.dataFaktur
                    .map((el) => el['total'])
                    .reduce((value, element) => value + element);

                if (c.selectedSupplierId.value != null) {
                  int panjangDataFaktur = c.dataFaktur.length;
                  // int totalDataFakturTerbayar = c.dataFaktur.where((element) => element['status'] == 'Lunas').length;

                  Map selectedSupplier = c.suppliers.firstWhere(
                    (element) => element['id_supplier'].toString() == c.selectedSupplierId.value.toString(),
                  );

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Supplier: ${selectedSupplier['nama_supplier']} - Total Data: $panjangDataFaktur",
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              "Total Pembelian: ${formatrupiah(totalHargaFaktur)}",
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: TextButton(
                          onPressed: c.cetakLaporan,
                          style: TextButton.styleFrom(),

                          child: Text("Cetak Laporan - (${selectedSupplier['nama_supplier']})"),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Total Data: ${c.dataFaktur.length} - Seluruh Supplier",
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            "Total Pembelian: ${formatrupiah(totalHargaFaktur)}",
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: TextButton(
                        onPressed: c.cetakLaporan,
                        child: const Text(
                          "Cetak Laporan",
                          style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w600),
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
    final c = Get.find<HistoryPembelianController>();

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
                      child: Builder(
                        builder: (context) {
                          DateTime tanggalForm = DateTime.parse(item['tanggal_form']);
                          return Text(
                            indonesianDateFormat(tanggalForm),
                            style: valueStyle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
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
                        formatrupiah(item['total'] ?? 0),
                        style: valueStyle.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text("Status: ", style: labelStyle, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item['cancel_at'] != null
                            ? 'Dibatalkan Pada ${indonesianDateFormat(DateTime.parse(item['cancel_at']))}'
                            : item['paid_at'] == null
                            ? 'Belum Lunas'
                            : 'Lunas Pada ${indonesianDateFormat(DateTime.parse(item['paid_at']))}',
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
                      if (item['cancel_at'] == null && item['paid_at'] == null)
                        Tooltip(
                          message: 'Edit',
                          waitDuration: const Duration(milliseconds: 400),
                          child: ElevatedButton(
                            onPressed: () {
                              c.showEditDialog(item);
                            },
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
                          onPressed: () {
                            c.showDetailDialog(item);
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(40, 40),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Icon(Icons.visibility_outlined, size: 20),
                        ),
                      ),

                      if (item['cancel_at'] == null)
                        Tooltip(
                          message: 'Void',
                          waitDuration: const Duration(milliseconds: 400),
                          child: TextButton(
                            onPressed: () {
                              c.cancelFaktur(item['id_form']);
                            },
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

                      if (item['paid_at'] == null)
                        Tooltip(
                          message: 'Lunaskan',
                          waitDuration: const Duration(milliseconds: 400),
                          child: TextButton(
                            onPressed: () {
                              c.pelunasanFaktur(item['id_form']);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.green,
                              minimumSize: const Size(40, 40),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Icon(Icons.check, size: 20, color: Colors.green),
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
