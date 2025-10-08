// ignore_for_file: unused_import

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:Project_SPA/admin/listpaket.dart';
import 'package:Project_SPA/admin/listpekerja.dart';
import 'package:Project_SPA/admin/listpromo.dart';
import 'package:Project_SPA/admin/regis_paket.dart';
import 'package:Project_SPA/admin/regis_pekerja.dart';
import 'package:Project_SPA/admin/regis_promo.dart';
import 'package:Project_SPA/admin/regis_room.dart';
import 'package:Project_SPA/admin/regis_users.dart';
import 'package:Project_SPA/function/admin_drawer.dart';
import 'package:Project_SPA/function/ip_address.dart';
import 'package:Project_SPA/function/our_drawer.dart';
import 'package:Project_SPA/owner/download_splash.dart';
import 'package:Project_SPA/resepsionis/rating.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:Project_SPA/function/me.dart';
import 'package:Project_SPA/function/token.dart';
import 'package:Project_SPA/main.dart';
// import 'package:printing/printing.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'printer_mgr_api.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart'; // This is crucial
// import 'package:thermal_printer/thermal_printer.dart';
import 'package:dartx/dartx.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';

class ListTransaksiController extends GetxController {
  RxList<Map<String, dynamic>> dataList = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> filteredList = <Map<String, dynamic>>[].obs;
  Timer? _debounce;
  Timer? _refreshTimer;
  ScrollController _scrollTglController = ScrollController();
  ScrollController singleChildController = ScrollController();

  RxList<DateTime?> rangeDatePickerOmset = <DateTime?>[].obs;
  RxList<dynamic> dataterapistambahan = [].obs;
  RxString namaterapis2 = ''.obs;
  RxString namaterapis3 = ''.obs;
  String idterapis2 = '';
  String idterapis3 = '';

  void showDialogTgl() {
    rangeDatePickerOmset.clear();

    Get.dialog(
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
                controller: _scrollTglController,
                thumbVisibility: true,
                child: ListView(
                  // Penting: biarkan default (shrinkWrap: false)
                  controller: _scrollTglController,
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
                          value: rangeDatePickerOmset,
                          onValueChanged: (dates) {
                            rangeDatePickerOmset.assignAll(dates);
                            log("Isi Range Date $rangeDatePickerOmset");
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
            onPressed: () {
              refreshData();
              Get.back();
            },
            child: const Text("SUBMIT"),
          ),
        ],
      ),
    ).then((_) {
      if (rangeDatePickerOmset.isEmpty) {
        refreshData();
      }
    });
  }

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    _profileUser().then((_) {
      refreshData();
      startAutoRefresh();
      _getPajak();
    });
  }

  // @override
  // void onClose() {
  //   // TODO: implement onClose
  //   _debounce?.cancel();
  //   _refreshTimer?.cancel();
  //   super.onClose();
  // }

  @override
  void onClose() {
    _txtSisaBayar.dispose();
    _txtJlhBayar.dispose();
    _txtKembalian.dispose();
    _namaAkun.dispose();
    _noRek.dispose();
    _namaBank.dispose();
    _debounce?.cancel();
    _refreshTimer?.cancel();
    _scrollTglController.dispose();
    singleChildController.dispose();
    super.onClose();
  }

  String formatDate(dynamic dateStr, {String format = 'dd/MM/yyyy'}) {
    if (dateStr == null || dateStr.toString().isEmpty) return '';

    try {
      final parsedDate = DateTime.parse(dateStr.toString());
      return DateFormat(format).format(parsedDate);
    } catch (e) {
      return '';
    }
  }

  var dio = Dio();
  RxInt omsetCash = 0.obs;
  RxInt omsetDebit = 0.obs;
  RxInt omsetKredit = 0.obs;
  RxInt omsetQris = 0.obs;
  RxList<Map<String, dynamic>> dataCash = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> dataDebit = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> dataKredit = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> dataQris = <Map<String, dynamic>>[].obs;
  RxString tglNow = "".obs;

  Future<List<Map<String, dynamic>>> fetchData({bool isOwner = false}) async {
    try {
      String myUrl = '${myIpAddr()}/listtrans/datatrans?hak_akses=${_hakAkses.value}';

      if (isOwner) {
        List<dynamic> rangeDate = rangeDatePickerOmset;
        if (rangeDate.isNotEmpty) {
          String startDate = rangeDate[0].toString().split(" ")[0];
          myUrl += "&start_date=$startDate";

          if (rangeDate.length == 2) {
            String endDate = rangeDate[1].toString().split(" ")[0];
            myUrl += "&end_date=$endDate";
          }
        }
      }

      log("isi myUrl adalah $myUrl");

      final response = await dio.get(myUrl);

      if (response.statusCode == 200) {
        omsetCash.value = response.data['total_cash'] ?? 0;
        omsetDebit.value = response.data['total_debit'] ?? 0;
        omsetKredit.value = response.data['total_kredit'] ?? 0;
        omsetQris.value = response.data['total_qris'] ?? 0;
        tglNow.value = (response.data['tgl'] as String);

        dataCash.assignAll((response.data['data_cash'] as List).map((el) => {...el}));
        dataDebit.assignAll((response.data['data_debit'] as List).map((el) => {...el}));
        dataKredit.assignAll((response.data['data_kredit'] as List).map((el) => {...el}));
        dataQris.assignAll((response.data['data_qris'] as List).map((el) => {...el}));

        log("Isi Data Cash $dataCash");

        return List<Map<String, dynamic>>.from(response.data['main_data']);
      } else {
        throw Exception("Failed to load data: ${response.statusCode}");
      }
    } on DioException catch (e) {
      throw Exception("Dio error: ${e.response!.data}");
    }
  }

  RxDouble pajakMsg = 0.0.obs;
  RxDouble pajakFnb = 0.0.obs;

  Future<void> _getPajak() async {
    try {
      var response = await dio.get('${myIpAddr()}/pajak/getpajak');

      // Parse the first record (assumes response is a list of maps)
      List<dynamic> data = response.data;
      if (data.isNotEmpty) {
        var firstRecord = data[0];
        double pjk = double.tryParse(firstRecord['pajak_msg'].toString()) ?? 0.0;
        double pjkFnb = double.tryParse(firstRecord['pajak_fnb'].toString()) ?? 0.0;

        pajakMsg.value = pjk;
        pajakFnb.value = pjkFnb;
      } else {
        throw Exception("Empty data received");
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception("Error Get Pajak Dio ${e.response?.data}");
      }
      throw Exception("Error Get Pajak $e");
    }
  }

  RxString _hakAkses = "".obs;

  Future<void> _profileUser() async {
    try {
      final prefs = await getTokenSharedPref();
      var response = await getMyData(prefs);
      log("Isi Response Profile User listtransaksi $response");

      Map<String, dynamic> responseData = response['data'];
      _hakAkses.value = responseData['hak_akses'];

      // storage.write("id_resepsionis", responseData['id_karyawan']);
      // storage.write("nama_resepsionis", responseData['nama_karyawan']);

      // namaKaryawan.value = responseData['nama_karyawan'];
      // jabatan.value = responseData['jabatan'];
    } catch (e) {
      log("Error di profile user listtransaksi $e");
    }
  }

  void startAutoRefresh() {
    _refreshTimer?.cancel();

    _refreshTimer = Timer.periodic(Duration(seconds: 50), (timer) {
      refreshData();
    });
  }

  Future<void> refreshData() async {
    try {
      final data = await fetchData(isOwner: _hakAkses.value == "owner" || _hakAkses.value == "admin");
      // assign data yang sama utk dataList dengan filteredList
      dataList.assignAll(data);
      filteredList.assignAll(data);
    } catch (e) {
      log("Error di refresh data $e");
      Get.snackbar("Error", "Gagal Refresh Data");
    }

    print("Fungsi refreshData Dipanggil oninit");
  }

  RxBool _isNotFound = false.obs;
  void fnFilterList(String query) {
    if (query.isEmpty) {
      // reset balik ke full list pas empty
      filteredList.assignAll(dataList);
      // reset notFoundState
      _isNotFound.value = false;
      return;
    }

    final itemFilter = dataList.where(
      (item) => item['id_transaksi'].toString().toLowerCase().contains(query.toLowerCase()),
    );

    filteredList.assignAll(itemFilter);
    // ini bakal true klo user cari item yg g ad isinya
    _isNotFound.value = itemFilter.isEmpty;
  }

  // utk Debounce
  void onSearchChange(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(Duration(milliseconds: 500), () {
      fnFilterList(query);
    });
  }

  List<String> listJenisRuang = <String>['Fasilitas', 'Reguler', 'VIP'];
  String? dropdownValue;

  String capitalize(String? text) {
    if (text == null || text.isEmpty) return "Unknown"; // Handle null or empty
    return text[0].toUpperCase() + text.substring(1);
  }

  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp. ', decimalDigits: 0);

  Future<Map<String, dynamic>> getDetailTrans(String idTrans) async {
    try {
      final response = await dio.get('${myIpAddr()}/listtrans/detailtrans/${idTrans}');

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = response.data;
        return responseData;
      } else {
        throw Exception("Failed to load data detail: ${response.statusCode}");
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception("Gagal di Dio ${e.response!.data}");
      }

      return {};
    }
  }

  Future<Map<String, dynamic>> getTerapisData(String idTrans) async {
    try {
      final response = await dio.get('${myIpAddr()}/listtrans/data_terapis/${idTrans}');

      if (response.statusCode == 200) {
        return (response.data as Map<String, dynamic>);
      } else {
        throw Exception("Failed to load data terapis: ${response.statusCode}");
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception("Gagal di Dio ${e.response!.data}");
      }

      return {};
    }
  }

  List<dynamic>? allDataOmset;
  void showDialogOmset(String mode) {
    if (mode == "cash") {
      allDataOmset = dataCash;
    } else if (mode == "debit") {
      allDataOmset = dataDebit;
    } else if (mode == "kredit") {
      allDataOmset = dataKredit;
    } else if (mode == "qris") {
      allDataOmset = dataQris;
    }

    log("Isi data omset $allDataOmset");

    Get.dialog(
      AlertDialog(
        title: Center(
          child: Obx(() {
            String teksTgl = "";

            List<dynamic> rangeDate = rangeDatePickerOmset;
            if (rangeDate.isNotEmpty) {
              String startDate = rangeDate[0].toString().split(" ")[0];
              teksTgl += formatDate(startDate, format: "dd-MM-yyyy");

              if (rangeDate.length == 2) {
                String endDate = rangeDate[1].toString().split(" ")[0];
                teksTgl += " s/d ${formatDate(endDate, format: "dd-MM-yyyy")}";
              }
            } else {
              teksTgl = formatDate(tglNow.value, format: "dd-MM-yyyy");
            }

            return Text("Detail Omset ${capitalize(mode)} - $teksTgl");
          }),
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            width: Get.width - 200,
            child: Column(
              children: [
                Row(
                  children: [
                    if (mode == "cash") ...[
                      Expanded(child: Text("Id Transaksi")),
                      Expanded(child: Text("Metode Bayar")),
                      Expanded(child: Text("Jumlah Bayar", textAlign: TextAlign.right)),
                    ] else ...[
                      Expanded(child: Text("Id Transaksi")),
                      Expanded(child: Text("Metode Bayar")),
                      Expanded(child: Text("Nama Akun")),
                      Expanded(child: Text("No_Rek")),
                      Expanded(child: Text("Nama Bank")),
                      Expanded(child: Text("Jumlah Bayar", textAlign: TextAlign.right)),
                    ],
                  ],
                ),
                Divider(),
                Builder(
                  builder: (context) {
                    List<dynamic>? dataBCA;
                    List<dynamic>? dataBNI;
                    List<dynamic>? dataBRI;
                    List<dynamic>? dataMandiri;

                    // Ini Bkl Nampung Semua Widget
                    List<Widget> bankDataWidgets = [];
                    List<Widget> cashWidgets = [];

                    if (mode == "cash") {
                      // Handle only cash transactions
                      RxInt omsetCash = 0.obs;

                      if (allDataOmset != null && allDataOmset!.isNotEmpty) {
                        // Add cash header
                        cashWidgets.add(
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, bottom: 5.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text("CASH", style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(
                                  child: Obx(
                                    () => Text(
                                      "Total Cash: ${currencyFormatter.format(omsetCash.value)}",
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );

                        // Add cash transactions
                        for (var data in allDataOmset!) {
                          omsetCash.value += (data['jumlah_bayar'] as int);
                          cashWidgets.add(
                            Row(
                              children: [
                                Expanded(child: Text(data['id_transaksi'])),
                                Expanded(child: Text(data['metode_pembayaran'])),
                                Expanded(
                                  child: Text(
                                    currencyFormatter.format(data['jumlah_bayar']),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return Column(children: cashWidgets);
                      } else {
                        return Text("Tidak Ada Transaksi Cash");
                      }
                    } else {
                      dataBCA = allDataOmset?.where((el) => el['nama_bank'].toLowerCase() == "bca").toList();
                      dataBNI = allDataOmset?.where((el) => el['nama_bank'].toLowerCase() == "bni").toList();
                      dataBRI = allDataOmset?.where((el) => el['nama_bank'].toLowerCase() == "bri").toList();
                      dataMandiri =
                          allDataOmset?.where((el) => el['nama_bank'].toLowerCase() == "mandiri").toList();

                      RxInt omsetBCA = 0.obs;
                      RxInt omsetBNI = 0.obs;
                      RxInt omsetBRI = 0.obs;
                      RxInt omsetMandiri = 0.obs;

                      // BCA
                      if (dataBCA!.isNotEmpty) {
                        bankDataWidgets.add(
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, bottom: 5.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text("BCA", style: TextStyle(fontWeight: FontWeight.bold))),

                                Expanded(
                                  child: Obx(
                                    () => Text(
                                      "Total BCA : ${currencyFormatter.format(omsetBCA.value)}",
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );

                        for (var data in dataBCA) {
                          omsetBCA.value += (data['jumlah_bayar'] as int);

                          bankDataWidgets.add(
                            Row(
                              children: [
                                Expanded(child: Text(data['id_transaksi'])),
                                Expanded(child: Text(data['metode_pembayaran'])),
                                Expanded(child: Text(data['nama_akun'])),
                                Expanded(child: Text(data['no_rek'])),
                                Expanded(child: Text(data['nama_bank'])),
                                Expanded(
                                  child: Text(
                                    currencyFormatter.format(data['jumlah_bayar']),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                      // BNI
                      if (dataBNI!.isNotEmpty) {
                        bankDataWidgets.add(
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, bottom: 5.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text("BNI", style: TextStyle(fontWeight: FontWeight.bold))),

                                Expanded(
                                  child: Obx(
                                    () => Text(
                                      "Total BNI : ${currencyFormatter.format(omsetBNI.value)}",
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );

                        for (var data in dataBNI) {
                          omsetBNI.value += (data['jumlah_bayar'] as int);

                          bankDataWidgets.add(
                            Row(
                              children: [
                                Expanded(child: Text(data['id_transaksi'])),
                                Expanded(child: Text(data['metode_pembayaran'])),
                                Expanded(child: Text(data['nama_akun'])),
                                Expanded(child: Text(data['no_rek'])),
                                Expanded(child: Text(data['nama_bank'])),
                                Expanded(
                                  child: Text(
                                    currencyFormatter.format(data['jumlah_bayar']),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      }

                      // BRI
                      if (dataBRI!.isNotEmpty) {
                        bankDataWidgets.add(
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, bottom: 5.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text("BRI", style: TextStyle(fontWeight: FontWeight.bold))),

                                Expanded(
                                  child: Obx(
                                    () => Text(
                                      "Total BRI : ${currencyFormatter.format(omsetBRI.value)}",
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );

                        for (var data in dataBRI) {
                          omsetBRI.value += (data['jumlah_bayar'] as int);

                          bankDataWidgets.add(
                            Row(
                              children: [
                                Expanded(child: Text(data['id_transaksi'])),
                                Expanded(child: Text(data['metode_pembayaran'])),
                                Expanded(child: Text(data['nama_akun'])),
                                Expanded(child: Text(data['no_rek'])),
                                Expanded(child: Text(data['nama_bank'])),
                                Expanded(
                                  child: Text(
                                    currencyFormatter.format(data['jumlah_bayar']),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      }

                      // Mandiri
                      if (dataMandiri!.isNotEmpty) {
                        bankDataWidgets.add(
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, bottom: 5.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text("Mandiri", style: TextStyle(fontWeight: FontWeight.bold)),
                                ),

                                Expanded(
                                  child: Obx(
                                    () => Text(
                                      "Total Mandiri : ${currencyFormatter.format(omsetMandiri.value)}",
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );

                        for (var data in dataMandiri) {
                          omsetMandiri.value += (data['jumlah_bayar'] as int);

                          bankDataWidgets.add(
                            Row(
                              children: [
                                Expanded(child: Text(data['id_transaksi'])),
                                Expanded(child: Text(data['metode_pembayaran'])),
                                Expanded(child: Text(data['nama_akun'])),
                                Expanded(child: Text(data['no_rek'])),
                                Expanded(child: Text(data['nama_bank'])),
                                Expanded(
                                  child: Text(
                                    currencyFormatter.format(data['jumlah_bayar']),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    }

                    if (bankDataWidgets.isEmpty) {
                      return Text("Tidak Ada Transaksi");
                    }

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch, // pastikan rows stretch
                      children: bankDataWidgets,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _fnFormatTotalBayar(String value) {
    // Hapus Non Digit Charsisabayar
    String digit = value.replaceAll(RegExp(r'[^0-9]'), '');

    // parse total bayar yang bentuk
    int numValue = int.tryParse(digit) ?? 0;
    _jlhBayar.value = numValue;

    // Buat kembalian
    _kembalian.value = _jlhBayar.value - _sisaBayar.value;

    // format ke rp
    String formatted = currencyFormatter.format(numValue);
    String formattedKembali = currencyFormatter.format(_kembalian.value);

    _txtJlhBayar.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );

    _txtKembalian.value = TextEditingValue(
      text: formattedKembali,
      selection: TextSelection.collapsed(offset: formattedKembali.length),
    );
  }

  // utang yg msh blm dilunasin
  RxInt _sisaBayar = 0.obs;
  TextEditingController _txtSisaBayar = TextEditingController();
  // bentuk int dan bentuk controller utk formatting
  RxInt _jlhBayar = 0.obs;
  TextEditingController _txtJlhBayar = TextEditingController();
  // kembalian
  RxInt _kembalian = 0.obs;
  TextEditingController _txtKembalian = TextEditingController();
  // List Metode Bayar
  RxList<String> _metodeByr = <String>['cash', 'debit', 'kredit', 'qris'].obs;
  RxnString? _selectedMetode = RxnString(null);
  // data utk metode bank / qris
  TextEditingController _namaAkun = TextEditingController();
  TextEditingController _noRek = TextEditingController();
  TextEditingController _namaBank = TextEditingController();

  RxString selectedBank = ''.obs;
  final List<String> bankList = ['BCA', 'BNI', 'BRI', 'Mandiri'];

  void dialogPelunasan(String idTrans, int grandTotal, int jumlahBayar, int kembalian, String status) async {
    _selectedMetode?.value = _metodeByr.first;

    // new dari deepseek
    // detail transaksi utk mengetahui jenis_addon
    final dataOri = await getDetailTrans(idTrans);
    List<dynamic> dataAddOn = dataOri['all_addon'];

    // Hitung total dgn Pajak yg sesuai
    int totalAddOnAll = 0;
    for (var i in dataAddOn) {
      double pajak = i['type'] == 'fnb' ? pajakFnb.value : pajakMsg.value;
      double nominalPjk = i['harga_total'] * pajak;
      double hrgPjkSblmRound = i['harga_total'] + nominalPjk;

      // pembulatan ribuan
      int hrgPjkStlhRound = (hrgPjkSblmRound / 1000).round() * 1000;
      totalAddOnAll += hrgPjkStlhRound;
    }

    int totalDanAddon = grandTotal + totalAddOnAll;
    int jlhBayar = jumlahBayar - kembalian;

    if (status == "unpaid" || status == "done-unpaid") {
      _sisaBayar.value = totalDanAddon - jlhBayar;
    } else if (status == "done-unpaid-addon" || (totalAddOnAll != 0 && status == "paid")) {
      _sisaBayar.value = totalAddOnAll; // Gunakan totalAddOnAll yang sudah termasuk pajak
    }
    // end new

    // int totalDanAddon = grandTotal + paramsTtlAddOn;
    // int jlhBayar = jumlahBayar - kembalian;

    // if (status == "unpaid" || status == "done-unpaid") {
    //   _sisaBayar.value = totalDanAddon - jlhBayar;

    //   // Case kalo ganti paket dan dia udh payment d awal.
    //   // if (totalDanAddon > jlhBayar) {
    //   //   _sisaBayar.value = totalDanAddon - jlhBayar;
    //   // }
    // } else if (status == "done-unpaid-addon" || (paramsTtlAddOn != 0 && status == "paid")) {
    //   _sisaBayar.value = paramsTtlAddOn;
    // }

    _txtSisaBayar.text = currencyFormatter.format(_sisaBayar.value);

    Get.dialog(
      AlertDialog(
        title: Center(child: Text("Input Pelunasan")),
        content: Container(
          width: Get.width - 300,
          height: Get.height - 300,
          child: ListView(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Padding(padding: const EdgeInsets.only(top: 20), child: Text("Sisa Bayar")),
                  ),
                  Expanded(flex: 3, child: TextField(readOnly: true, controller: _txtSisaBayar)),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Padding(padding: const EdgeInsets.only(top: 20), child: Text("Metode Bayar")),
                  ),
                  Expanded(
                    flex: 3,
                    child: Obx(
                      () => DropdownButton<String>(
                        value: _selectedMetode!.value,
                        elevation: 16,
                        style: const TextStyle(color: Colors.deepPurple),
                        onChanged: (String? value) {
                          if (value != null) {
                            _selectedMetode!.value = value;
                          }
                        },
                        icon: SizedBox.shrink(),
                        items:
                            _metodeByr.map((item) {
                              return DropdownMenuItem<String>(
                                value: item,
                                child: AutoSizeText(item, minFontSize: 15),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text("Jumlah Bayar Konsumen"),
                    ),
                  ),
                  Obx(() {
                    if (_selectedMetode!.value != "cash") {
                      // samakan jlhbayar dgn sisabayar kalo dia debit/qris
                      _txtJlhBayar.text = currencyFormatter.format(_sisaBayar.value);
                    } else {
                      _txtJlhBayar.text = "";
                      _kembalian.value = 0;
                      _txtKembalian.text = "";
                    }

                    return Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _txtJlhBayar,
                        readOnly: _selectedMetode!.value != "cash",
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (value) {
                          _fnFormatTotalBayar(value);
                        },
                      ),
                    );
                  }),
                ],
              ),
              Obx(() {
                final c = Get.find<ListTransaksiController>();

                if (_selectedMetode!.value == "cash") {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Padding(padding: const EdgeInsets.only(top: 20), child: Text("Kembalian")),
                          ),
                          Expanded(flex: 3, child: TextField(controller: _txtKembalian, readOnly: true)),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (_txtJlhBayar.text == "" ||
                                      _txtJlhBayar.text.isEmpty ||
                                      _txtJlhBayar.text == "0") {
                                    return;
                                  }

                                  if (_kembalian.value < 0) {
                                    log("Kembalian  kurang dr 0");
                                    return;
                                  }

                                  await _storeTrans(Get.context!, idTrans);
                                  Get.back();
                                },
                                child: Text("Proses"),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                } else if (_selectedMetode!.value == 'debit' ||
                    _selectedMetode!.value == 'qris' ||
                    _selectedMetode!.value == 'kredit') {
                  return Column(
                    children: [
                      SizedBox(height: 20),
                      Row(
                        children: [
                          Text(
                            "Informasi Bank Pemilik",
                            style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(child: Text("Nama Akun: ", style: TextStyle(fontFamily: 'Poppins'))),
                          Expanded(flex: 3, child: TextField(controller: _namaAkun)),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(child: Text("Nomor Rekening: ", style: TextStyle(fontFamily: 'Poppins'))),
                          Expanded(flex: 3, child: TextField(controller: _noRek)),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(child: Text("Nama Bank: ", style: TextStyle(fontFamily: 'Poppins'))),
                          Expanded(
                            flex: 3,
                            child: Obx(
                              () => DropdownButtonFormField<String>(
                                value: c.selectedBank.value.isEmpty ? null : c.selectedBank.value,
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    c.selectedBank.value = newValue;
                                  }
                                },
                                items:
                                    c.bankList.map((String bank) {
                                      return DropdownMenuItem<String>(value: bank, child: Text(bank));
                                    }).toList(),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (_txtJlhBayar.text == "" || _txtJlhBayar.text.isEmpty) {
                                    return;
                                  }

                                  await _storeTrans(Get.context!, idTrans);
                                  Get.back();
                                },
                                child: Text("Proses"),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                } else {
                  return SizedBox.shrink();
                }
              }),
            ],
          ),
        ),
      ),
    ).then((_) {
      _txtJlhBayar.clear();
      _txtKembalian.clear();
      _txtSisaBayar.clear();
      _namaAkun.clear();
      _namaBank.clear();
      _noRek.clear();
    });
  }

  Future<void> cancelTransaksi(String idTrans, String password, context) async {
    try {
      var response = await dio.put(
        '${myIpAddr()}/listtrans/cancel_transaksi',
        data: {"id_trans": idTrans, "passwd": password},
        options: Options(contentType: Headers.jsonContentType, responseType: ResponseType.json),
      );

      if (response.statusCode == 200) {
        await refreshData();
        CherryToast.success(
          title: Text(" Berhasil Cancel"),
          toastDuration: Duration(seconds: 3),
        ).show(context);
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response!.statusCode == 401) {
          CherryToast.error(
            title: Text("Password SPV Salah"),
            toastDuration: Duration(seconds: 3),
          ).show(context);
        }
      }
      log("Error di fn CancelTransaksi ${e}");
    }
  }

  // versi pdf
  // void printStruk(Map<String, dynamic> data, String idTrans) async {
  //   final pdf = pw.Document();

  //   List<dynamic> dataAddOn = data['all_addon'];
  //   int addOnTotal = 0;
  //   List<Map<String, dynamic>> _combinedAddOn = [];

  //   for (var i = 0; i < dataAddOn.length; i++) {
  //     addOnTotal += (dataAddOn[i]['harga_total'] as int);

  //     var tipe = dataAddOn[i]['type'];
  //     var data = {
  //       "type": tipe,
  //       "id_detail_transaksi": dataAddOn[i]['id_detail_transaksi'],
  //       "id_transaksi": dataAddOn[i]['id_transaksi'],
  //       "id_item": dataAddOn[i]['id_fnb'] ?? dataAddOn[i]['id_produk'] ?? dataAddOn[i]['id_paket'],
  //       "nama_item": dataAddOn[i]['nama_fnb'] ?? dataAddOn[i]['nama_produk'] ?? dataAddOn[i]['nama_paket_msg'],
  //       "qty": dataAddOn[i]['qty'],
  //       "satuan": dataAddOn[i]['satuan'],
  //       "harga_item": dataAddOn[i]['harga_item'],
  //       "harga_total": dataAddOn[i]['harga_total'],
  //       "durasi": tipe == "fnb" ? "-" : dataAddOn[i]['durasi_awal'],
  //       "status": dataAddOn[i]['status'],
  //     };

  //     _combinedAddOn.add(data);
  //   }

  //   print("Isi data ${_combinedAddOn}");

  //   pdf.addPage(
  //     pw.Page(
  //       pageFormat: PdfPageFormat(58 * PdfPageFormat.mm, double.infinity), // 58mm POS,
  //       build: (pw.Context context) {
  //         return pw.Column(
  //           crossAxisAlignment: pw.CrossAxisAlignment.start,
  //           children: [
  //             pw.Center(
  //               child: pw.Text(
  //                 "STRUK TRANSAKSI",
  //                 style: pw.TextStyle(
  //                   fontSize: 16,
  //                   fontWeight: pw.FontWeight.bold,
  //                 ),
  //               ),
  //             ),
  //             pw.Center(
  //               child: pw.Text(
  //                 "ID TRANS: ${idTrans}",
  //                 style: pw.TextStyle(fontSize: 10),
  //               ),
  //             ),
  //             pw.SizedBox(height: 10),
  //             pw.Divider(),
  //             pw.Text(
  //               "Addon: ",
  //               style: pw.TextStyle(
  //                 fontWeight: pw.FontWeight.bold,
  //               ),
  //             ),
  //             pw.SizedBox(height: 5),
  //             pw.Row(
  //               children: [
  //                 pw.Expanded(
  //                   child: pw.Text(
  //                     "Item",
  //                     style: pw.TextStyle(
  //                       fontWeight: pw.FontWeight.bold,
  //                       fontSize: 10,
  //                     ),
  //                   ),
  //                 ),
  //                 pw.Expanded(
  //                   child: pw.Text(
  //                     "Qty",
  //                     textAlign: pw.TextAlign.right,
  //                     style: pw.TextStyle(
  //                       fontWeight: pw.FontWeight.bold,
  //                       fontSize: 10,
  //                     ),
  //                   ),
  //                 ),
  //                 pw.Expanded(
  //                   child: pw.Text(
  //                     "Harga",
  //                     textAlign: pw.TextAlign.right,
  //                     style: pw.TextStyle(
  //                       fontWeight: pw.FontWeight.bold,
  //                       fontSize: 10,
  //                     ),
  //                   ),
  //                 ),
  //                 pw.Expanded(
  //                   child: pw.Text(
  //                     "Total",
  //                     textAlign: pw.TextAlign.right,
  //                     style: pw.TextStyle(
  //                       fontWeight: pw.FontWeight.bold,
  //                       fontSize: 10,
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             ..._combinedAddOn.map(
  //               (item) {
  //                 return pw.Row(
  //                   children: [
  //                     pw.Expanded(
  //                       child: pw.Text(
  //                         item['nama_item'],
  //                         style: pw.TextStyle(fontSize: 9),
  //                       ),
  //                     ),
  //                     pw.Expanded(child: pw.Text("${item['qty']}", textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 9))),
  //                     pw.Expanded(child: pw.Text("${item['harga_item']}", textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 9))),
  //                     pw.Expanded(child: pw.Text("${item['harga_total']}", textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 9))),
  //                   ],
  //                 );
  //               },
  //             )
  //           ],
  //         );
  //       },
  //     ),
  //   );

  //   await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  // }

  Future<void> _storeTrans(BuildContext context, String idTrans) async {
    try {
      var data = {
        "id_transaksi": idTrans,
        // Ambil Value bersih dengan _sisaBayar.value
        "jumlah_bayar": _sisaBayar.value,
      };

      if (_selectedMetode!.value == "cash") {
        data['metode_pembayaran'] = "cash";
      } else if (_selectedMetode!.value == "qris") {
        data['metode_pembayaran'] = "qris";
      } else if (_selectedMetode!.value == "debit") {
        data['metode_pembayaran'] = "debit";
      } else if (_selectedMetode!.value == "kredit") {
        data['metode_pembayaran'] = "kredit";
      } else {
        data['metode_pembayaran'] = "unknown"; // fallback for unexpected values
      }
      if (_selectedMetode!.value != "cash") {
        data['nama_akun'] = _namaAkun.text;
        data['no_rek'] = _noRek.text;
        data['nama_bank'] = selectedBank.value;
      }

      var response = await dio.put('${myIpAddr()}/massages/pelunasan', data: data);

      if (response.statusCode == 200) {
        await refreshData();
        CherryToast.success(
          title: Text("Pelunasan Berhasil"),
          toastDuration: Duration(seconds: 3),
        ).show(context);
      }
      // log("Isi data jual $dataJual");
      log("Sukses SImpan $response");
    } catch (e) {
      if (e is DioException) {
        log("Error fn storeTrans ${e.response!.data}");
      }
    }
  }

  // // Alur awalnya Process dlu baru Print Receipt
  // Future<void> _processPrintViaLAN(data, Map<String, dynamic> mainTrans) async {
  //   List<dynamic> dataProduk = data['detail_produk'];
  //   List<dynamic> dataPaket = data['detail_paket'];
  //   List<dynamic> dataFood = data['detail_food'];
  //   List<dynamic> dataFasilitas = data['detail_fasilitas'];
  //   List<dynamic> dataAddOn = data['all_addon'];
  //   List<dynamic> dataMember = data['detail_member'];
  //   log("Isi data member $dataMember");
  //   List<Map<String, dynamic>> _combinedAddOn = [];
  //   _combinedAddOn.clear();

  //   for (var i = 0; i < dataAddOn.length; i++) {
  //     var tipe = dataAddOn[i]['type'];
  //     var data = {
  //       "type": tipe,
  //       "id_detail_transaksi": dataAddOn[i]['id_detail_transaksi'],
  //       "id_transaksi": dataAddOn[i]['id_transaksi'],
  //       "id_item": dataAddOn[i]['id_fnb'] ?? dataAddOn[i]['id_produk'] ?? dataAddOn[i]['id_paket'],
  //       "nama_item": dataAddOn[i]['nama_fnb'] ?? dataAddOn[i]['nama_produk'] ?? dataAddOn[i]['nama_paket_msg'],
  //       "qty": dataAddOn[i]['qty'],
  //       "satuan": dataAddOn[i]['satuan'],
  //       "harga_item": dataAddOn[i]['harga_item'],
  //       "harga_total": dataAddOn[i]['harga_total'],
  //       "durasi": tipe == "fnb" ? "-" : dataAddOn[i]['durasi_awal'],
  //       "status": dataAddOn[i]['status'],
  //     };

  //     _combinedAddOn.add(data);
  //   }

  //   await _printReceiptViaLAN(
  //     mainTrans['id_transaksi'],
  //     mainTrans['disc'],
  //     mainTrans['jenis_pembayaran'],
  //     mainTrans['no_loker'],
  //     mainTrans['nama_tamu'],
  //     mainTrans['metode_pembayaran'],
  //     mainTrans['nama_bank'] ?? "-",
  //     mainTrans['pajak'],
  //     mainTrans['gtotal_stlh_pajak'],
  //     dataProduk,
  //     dataPaket,
  //     dataFood,
  //     dataFasilitas,
  //     _combinedAddOn,
  //     dataMember,
  //   );
  // }

  // Future<void> _printReceiptViaLAN(
  //   String idTrans,
  //   double disc,
  //   int jenisPembayaran,
  //   int noLoker,
  //   String namaTamu,
  //   String metodePembayaran,
  //   String namaBank,
  //   double pajak,
  //   int gTotalStlhPajak,
  //   List<dynamic> dataProduk,
  //   List<dynamic> dataPaket,
  //   List<dynamic> dataFood,
  //   List<dynamic> dataFasilitas,
  //   List<Map<String, dynamic>> combinedAddOn,
  //   List<dynamic> dataMemberFirstTime,
  // ) async {
  //   // Set Ip Printer static
  //   const String printerIp = '192.168.1.77';
  //   const int printerPort = 9100; //biasanya

  //   try {
  //     final printer = NetworkPrinter(PaperSize.mm80, await CapabilityProfile.load(name: 'default'));
  //     final PosPrintResult res = await printer.connect(printerIp, port: printerPort);

  //     if (res == PosPrintResult.success) {
  //       // printer.text('Special characters: áéíóú', styles: PosStyles(codeTable: 'CP1252')); // Western European

  //       await PrinterHelper.printReceipt(
  //         idTrans: idTrans,
  //         disc: disc,
  //         jenisPembayaran: jenisPembayaran,
  //         noLoker: noLoker,
  //         namaTamu: namaTamu == "" ? "-" : namaTamu,
  //         metodePembayaran: metodePembayaran,
  //         namaBank: namaBank,
  //         pajak: pajak,
  //         gTotalStlhPajak: gTotalStlhPajak,
  //         printer: printer,
  //         dataProduk: dataProduk,
  //         dataPaket: dataPaket,
  //         dataFood: dataFood,
  //         dataFasilitas: dataFasilitas,
  //         combinedAddOn: combinedAddOn,
  //         dataMemberFirstTime: dataMemberFirstTime,
  //       );

  //       printer.disconnect();
  //     } else {
  //       Get.snackbar('Error', 'Gagal Konek Printer');
  //     }
  //   } catch (e) {
  //     Get.snackbar('Error', 'Gagal Printing $e');
  //   }
  // }
  // // End Print Via LAN

  Future<void> _processPrintViaLAN(data, Map<String, dynamic> mainTrans) async {
    List<dynamic> dataProduk = data['detail_produk'];
    List<dynamic> dataPaket = data['detail_paket'];
    List<dynamic> dataFood = data['detail_food'];
    List<dynamic> dataFasilitas = data['detail_fasilitas'];
    List<dynamic> dataAddOn = data['all_addon'];
    List<dynamic> dataMember = data['detail_member'];

    List<Map<String, dynamic>> _combinedAddOn = [];
    _combinedAddOn.clear();

    for (var i = 0; i < dataAddOn.length; i++) {
      var tipe = dataAddOn[i]['type'];
      var data = {
        "type": tipe,
        "id_detail_transaksi": dataAddOn[i]['id_detail_transaksi'],
        "id_transaksi": dataAddOn[i]['id_transaksi'],
        "id_item": dataAddOn[i]['id_fnb'] ?? dataAddOn[i]['id_produk'] ?? dataAddOn[i]['id_paket'],
        "nama_item":
            dataAddOn[i]['nama_fnb'] ?? dataAddOn[i]['nama_produk'] ?? dataAddOn[i]['nama_paket_msg'],
        "qty": dataAddOn[i]['qty'],
        "satuan": dataAddOn[i]['satuan'],
        "harga_item": dataAddOn[i]['harga_item'],
        "harga_total": dataAddOn[i]['harga_total'],
        "durasi": tipe == "fnb" ? "-" : dataAddOn[i]['durasi_awal'],
        "status": dataAddOn[i]['status'],
      };
      _combinedAddOn.add(data);
    }

    // Generate the receipt bytes
    final bytes = await PrinterHelper.generateReceipt(
      idTrans: mainTrans['id_transaksi'],
      disc: mainTrans['disc'],
      jenisPembayaran: mainTrans['jenis_pembayaran'],
      noLoker: mainTrans['no_loker'],
      namaTamu: mainTrans['nama_tamu'] == "" ? "-" : mainTrans['nama_tamu'],
      metodePembayaran: mainTrans['metode_pembayaran'],
      namaBank: mainTrans['nama_bank'] ?? "-",
      pajak: mainTrans['pajak'],
      gTotalStlhPajak: mainTrans['gtotal_stlh_pajak'],
      dataProduk: dataProduk,
      dataPaket: dataPaket,
      dataFood: dataFood,
      dataFasilitas: dataFasilitas,
      combinedAddOn: _combinedAddOn,
      dataMemberFirstTime: dataMember,
    );

    // Send to printer via your API
    await _sendToPrinter(bytes);
  }

  Future<void> _sendToPrinter(List<int> bytes) async {
    try {
      final response = await dio.post(
        '${myIpAddr()}/listtrans/print',
        data: Stream.fromIterable([bytes]),
        options: Options(contentType: 'application/octet-stream', responseType: ResponseType.json),
      );

      if (response.statusCode != 200) {
        Get.snackbar("Error", "Gagal Konek Printer ${response.data}", backgroundColor: Colors.white);
        throw Exception("Failed to print: ${response.statusCode}");
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal Kirim Ke printer $e", backgroundColor: Colors.white);
      log("Error sending to printer: $e");
      rethrow;
    }
  }

  Future<void> getterapistambahan(idtrans) async {
    try {
      namaterapis2.value = '';
      namaterapis3.value = '';
      var response3 = await dio.get(
        '${myIpAddr()}/kamar_terapis/dataterapistambahan',
        data: {"id_transaksi": idtrans},
      );

      List<dynamic> responseTerapis = response3.data;

      dataterapistambahan.assignAll(responseTerapis.map((e) => Map<String, dynamic>.from(e)).toList());

      if (idtrans != '') {
        if (dataterapistambahan.isNotEmpty) {
          namaterapis2.value = dataterapistambahan[0]['nama_karyawan'];
        } else {
          namaterapis2.value = '';
          idterapis2 = '';
        }

        if (dataterapistambahan.length > 1) {
          namaterapis3.value = dataterapistambahan[1]['nama_karyawan'];
        } else {
          namaterapis3.value = '';
          idterapis3 = '';
        }

        if (namaterapis2.value != '') {
          var responseterapis2 = await dio.get(
            '${myIpAddr()}/kamar_terapis/getidterapistambahan',
            data: {"nama_karyawan": namaterapis2.value},
          );

          idterapis2 = responseterapis2.data[0]['id_karyawan'];
        }

        if (namaterapis3.value != '') {
          var responseterapis3 = await dio.get(
            '${myIpAddr()}/kamar_terapis/getidterapistambahan',
            data: {"nama_karyawan": namaterapis3.value},
          );
          idterapis3 = responseterapis3.data[0]['id_karyawan'];
        }
      }
    } catch (e) {
      if (e is DioException) {
        log("Error di getdataterapistambahan ${e.response!.data}");
      }
    }
  }

  void dialogDetail(String idTrans, double disc, int jenisPembayaran, int isCancel) async {
    var fetchAll = await Future.wait([getDetailTrans(idTrans), getTerapisData(idTrans)]);
    final dataOri = fetchAll[0];
    final dataTerapis = fetchAll[1];

    List<dynamic> dataProduk = dataOri['detail_produk'];
    List<dynamic> dataPaket = dataOri['detail_paket'];
    List<dynamic> dataFood = dataOri['detail_food'];
    List<dynamic> dataFasilitas = dataOri['detail_fasilitas'];
    List<dynamic> dataMember = dataOri['detail_member'];
    List<dynamic> dataharga = dataOri['harga_ruangan'];
    log('dataMember: $dataMember');
    List<dynamic> dataAddOn = dataOri['all_addon'];
    List<Map<String, dynamic>> _combinedAddOn = [];
    _combinedAddOn.clear();

    log('isi data harga : ${dataharga}');

    int produkTotal = 0;
    int paketTotal = 0;
    int foodTotal = 0;
    int fasilitasTotal = 0;
    int memberTotal = 0;
    int addOnTotal = 0;
    int hargaroom = dataharga[0]['harga_vip'];

    for (var i = 0; i < dataProduk.length; i++) {
      produkTotal += (dataProduk[i]['harga_total'] as int);
    }
    for (var i = 0; i < dataPaket.length; i++) {
      if (dataPaket[i]['is_returned'] == 0) {
        paketTotal += (dataPaket[i]['harga_total'] as int);
      }
    }
    for (var i = 0; i < dataFood.length; i++) {
      foodTotal += (dataFood[i]['harga_total'] as int);
    }

    for (var i = 0; i < dataFasilitas.length; i++) {
      fasilitasTotal += (dataFasilitas[i]['harga_fasilitas'] as int);
    }

    for (var i = 0; i < dataMember.length; i++) {
      memberTotal += (dataMember[i]['harga_promo'] as int);
    }

    for (var i = 0; i < dataAddOn.length; i++) {
      addOnTotal += (dataAddOn[i]['harga_total'] as int);

      var tipe = dataAddOn[i]['type'];
      var data = {
        "type": tipe,
        "id_detail_transaksi": dataAddOn[i]['id_detail_transaksi'],
        "id_transaksi": dataAddOn[i]['id_transaksi'],
        "id_item": dataAddOn[i]['id_fnb'] ?? dataAddOn[i]['id_produk'] ?? dataAddOn[i]['id_paket'],
        "nama_item":
            dataAddOn[i]['nama_fnb'] ?? dataAddOn[i]['nama_produk'] ?? dataAddOn[i]['nama_paket_msg'],
        "qty": dataAddOn[i]['qty'],
        "satuan": dataAddOn[i]['satuan'],
        "harga_item": dataAddOn[i]['harga_item'],
        "harga_total": dataAddOn[i]['harga_total'],
        "durasi": tipe == "fnb" ? "-" : dataAddOn[i]['durasi_awal'],
        "status": dataAddOn[i]['status'],
      };

      _combinedAddOn.add(data);
    }

    print(_combinedAddOn);

    await getterapistambahan(idTrans);

    Get.dialog(
      AlertDialog(
        title: Center(child: Column(children: [Text("Detail Transaksi ${idTrans}"), Divider()])),
        content: Container(
          height: Get.height - 100,
          width: Get.width - 150,
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (dataTerapis.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, top: 8, bottom: 10),
                      child: Column(
                        // align children kekanan
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(mainAxisAlignment: MainAxisAlignment.start, children: [Text("Data Terapis")]),
                          SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start, // Align row contents to end
                            children: [
                              Text("Nama Terapis: "),
                              SizedBox(width: 8), // Add some spacing
                              Text(
                                '${dataTerapis['nama_karyawan']} ${namaterapis2.value == '' ? '' : ','} ${namaterapis2.value} ${namaterapis3.value == '' ? '' : ','} ${namaterapis3.value}',
                              ),
                            ],
                          ),
                          SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start, // Align row contents to end
                            children: [
                              Text("Kode Terapis: "),
                              SizedBox(width: 8), // Add some spacing
                              Text(
                                '${dataTerapis['id_terapis']} ${idterapis2 == '' ? '' : ','} ${idterapis2} ${idterapis3 == '' ? '' : ','} ${idterapis3}',
                              ),
                            ],
                          ),
                          SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start, // Align row contents to end
                            children: [
                              Text("Jam Datang: "),
                              SizedBox(width: 8), // Add some spacing
                              Text("${dataTerapis['jam_datang']} | "),
                              SizedBox(width: 8),
                              Text("Jam Mulai: "),
                              SizedBox(width: 8), // Add some spacing
                              Text("${dataTerapis['jam_mulai']} | "),
                              SizedBox(width: 8),
                              Text("Jam Selesai: "),
                              SizedBox(width: 8), // Add some spacing
                              Text("${dataTerapis['jam_selesai']} | "),
                              Text(
                                "Harga Room : ",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              SizedBox(width: 8),
                              Text(
                                "${currencyFormatter.format(hargaroom)}",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                if (_combinedAddOn.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 8, bottom: 10),
                    child: Text("AddOn Details", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  // Header Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text("Id & Nama Addon", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text("Qty", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        Expanded(child: Text("Harga Satuan", style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(child: Text("Total Harga", style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(
                          child: Text("Durasi (Menit)", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(child: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                  Divider(),

                  // 👇 Dynamic Content (No fixed height)
                  Column(
                    children: [
                      for (var data in _combinedAddOn)
                        Padding(
                          padding: const EdgeInsets.only(left: 10, right: 10),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: AutoSizeText(
                                  "${data['id_item']} - ${data['nama_item']}",
                                  minFontSize: 8,
                                  maxLines: 1,
                                ),
                              ),
                              Expanded(
                                child: AutoSizeText(
                                  "${data['qty']} ${data['satuan']}",
                                  minFontSize: 8,
                                  maxLines: 1,
                                ),
                              ),
                              Expanded(
                                child: AutoSizeText(
                                  "${currencyFormatter.format(data['harga_item'])}",
                                  minFontSize: 8,
                                  maxLines: 1,
                                ),
                              ),
                              Expanded(
                                child: AutoSizeText(
                                  "${currencyFormatter.format(data['harga_total'])}",
                                  minFontSize: 8,
                                  maxLines: 1,
                                ),
                              ),
                              Expanded(
                                child: AutoSizeText(
                                  data['type'] != "fnb" ? "${data['durasi']} x ${data['qty']}" : "-",
                                  minFontSize: 8,
                                  maxLines: 1,
                                ),
                              ),
                              Expanded(child: AutoSizeText("${data['status']}", minFontSize: 8, maxLines: 1)),
                            ],
                          ),
                        ),
                      Container(
                        width: double.infinity, // Take full width
                        padding: const EdgeInsets.only(left: 10, right: 30, top: 20),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Total Pembelian Addon ${disc > 0 && jenisPembayaran == 1 ? "(Sblm Disc)" : ""}:",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  currencyFormatter.format(addOnTotal),
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                            if (disc > 0 && jenisPembayaran == 1) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Diskon :",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    "${disc * 100}%",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Total Pembelian Addon (Stlh Disc):",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Builder(
                                    builder: (context) {
                                      var nominalDisc = paketTotal * disc;
                                      var paketStlhDisc = paketTotal - nominalDisc;

                                      return Text(
                                        currencyFormatter.format(paketStlhDisc),
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                  Divider(),
                ],
                if (dataPaket.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 8, bottom: 10),
                    child: Text("Paket Details", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  // Header Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text("Id & Nama Paket", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text("Qty", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        Expanded(child: Text("Harga Satuan", style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(child: Text("Total Harga", style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(
                          child: Text("Durasi (Menit)", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(child: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                  Divider(),

                  // 👇 Dynamic Content (No fixed height)
                  Column(
                    children: [
                      for (var paket in dataPaket)
                        Padding(
                          padding: const EdgeInsets.only(left: 10, right: 10),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: AutoSizeText(
                                  "${paket['id_paket']} - ${paket['nama_paket_msg']}",
                                  minFontSize: 8,
                                  maxLines: 1,
                                ),
                              ),
                              Expanded(
                                child: AutoSizeText(
                                  "${paket['qty']} ${paket['satuan']}",
                                  minFontSize: 8,
                                  maxLines: 1,
                                ),
                              ),
                              Expanded(
                                child: AutoSizeText(
                                  "${currencyFormatter.format(paket['harga_item'])}",
                                  minFontSize: 8,
                                  maxLines: 1,
                                ),
                              ),
                              Expanded(
                                child: AutoSizeText(
                                  "${currencyFormatter.format(paket['harga_total'])}",
                                  minFontSize: 8,
                                  maxLines: 1,
                                ),
                              ),
                              Expanded(
                                child: AutoSizeText(
                                  "${paket['durasi_awal']} x ${paket['qty']}",
                                  minFontSize: 8,
                                  maxLines: 1,
                                ),
                              ),
                              Expanded(
                                child: AutoSizeText("${paket['status']}", minFontSize: 8, maxLines: 1),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        width: double.infinity, // Take full width
                        padding: const EdgeInsets.only(left: 10, right: 30, top: 20),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Total Pembelian Paket ${disc > 0 ? "(Sblm Disc)" : ""}:",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  currencyFormatter.format(paketTotal),
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                            if (disc > 0) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Diskon :",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    "${disc * 100}%",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Total Pembelian Paket (Stlh Disc):",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Builder(
                                    builder: (context) {
                                      var nominalDisc = paketTotal * disc;
                                      var paketStlhDisc = (((paketTotal - nominalDisc) + 999) ~/ 1000) * 1000;

                                      print('isinya adalah $paketStlhDisc');

                                      return Text(
                                        currencyFormatter.format(paketStlhDisc),
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                  Divider(),
                ],
                if (dataProduk.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 8, bottom: 10),
                    child: Text("Produk Details", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  // Header Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text("Id & Nama Produk", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text("Qty", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        Expanded(child: Text("Harga Satuan", style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(child: Text("Total Harga", style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(
                          child: Text("Durasi (Menit)", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(child: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                  Divider(),

                  // 👇 Dynamic Content (No fixed height)
                  Column(
                    children: [
                      for (var produk in dataProduk)
                        Padding(
                          padding: const EdgeInsets.only(left: 10, right: 10),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: AutoSizeText(
                                  "${produk['id_produk']} - ${produk['nama_produk']}",
                                  minFontSize: 8,
                                  maxLines: 1,
                                ),
                              ),
                              Expanded(
                                child: AutoSizeText(
                                  "${produk['qty']} ${produk['satuan']}",
                                  minFontSize: 8,
                                  maxLines: 1,
                                ),
                              ),
                              Expanded(
                                child: AutoSizeText(
                                  "${currencyFormatter.format(produk['harga_item'])}",
                                  minFontSize: 8,
                                  maxLines: 1,
                                ),
                              ),
                              Expanded(
                                child: AutoSizeText(
                                  "${currencyFormatter.format(produk['harga_total'])}",
                                  minFontSize: 8,
                                  maxLines: 1,
                                ),
                              ),
                              Expanded(
                                child: AutoSizeText(
                                  "${produk['durasi_awal']} x ${produk['qty']}",
                                  minFontSize: 8,
                                  maxLines: 1,
                                ),
                              ),
                              Expanded(
                                child: AutoSizeText("${produk['status']}", minFontSize: 8, maxLines: 1),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        width: double.infinity, // Take full width
                        padding: const EdgeInsets.only(left: 10, right: 30, top: 20),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Total Pembelian Produk ${disc > 0 ? "(Sblm Disc)" : ""}:",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  currencyFormatter.format(produkTotal),
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                            if (disc > 0) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Diskon :",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    "${disc * 100}%",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Total Pembelian Produk (Stlh Disc):",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Builder(
                                    builder: (context) {
                                      var nominalDisc = produkTotal * disc;
                                      var produkStlhDisc = produkTotal - nominalDisc;

                                      return Text(
                                        currencyFormatter.format(produkStlhDisc),
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                  Divider(),
                ],
                if (dataFood.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 8, bottom: 10),
                    child: Text("Food Details", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  // Header Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text("Id & Nama Food", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text("Qty", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        Expanded(child: Text("Harga Satuan", style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(child: Text("Total Harga", style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(child: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                  Divider(),

                  // 👇 Dynamic Content (No fixed height)
                  Column(
                    children: [
                      for (var food in dataFood)
                        Padding(
                          padding: const EdgeInsets.only(left: 10, right: 10),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: AutoSizeText(
                                  "${food['id_fnb']} - ${food['nama_fnb']}",
                                  minFontSize: 8,
                                  maxLines: 1,
                                ),
                              ),
                              Expanded(
                                child: AutoSizeText(
                                  "${food['qty']} ${food['satuan']}",
                                  minFontSize: 8,
                                  maxLines: 1,
                                ),
                              ),
                              Expanded(
                                child: AutoSizeText(
                                  "${currencyFormatter.format(food['harga_item'])}",
                                  minFontSize: 8,
                                  maxLines: 1,
                                ),
                              ),
                              Expanded(
                                child: AutoSizeText(
                                  "${currencyFormatter.format(food['harga_total'])}",
                                  minFontSize: 8,
                                  maxLines: 1,
                                ),
                              ),
                              Expanded(child: AutoSizeText("${food['status']}", minFontSize: 8, maxLines: 1)),
                            ],
                          ),
                        ),
                      Container(
                        width: double.infinity, // Take full width
                        padding: const EdgeInsets.only(left: 10, right: 30, top: 20),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Total Pembelian Food ${disc > 0 ? "(Sblm Disc)" : ""}:",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  currencyFormatter.format(foodTotal),
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                            if (disc > 0) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Diskon :",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    "${disc * 100}%",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Total Pembelian Food (Stlh Disc):",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Builder(
                                    builder: (context) {
                                      var nominalDisc = foodTotal * disc;
                                      var foodStlhDisc = foodTotal - nominalDisc;

                                      return Text(
                                        currencyFormatter.format(foodStlhDisc),
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                  Divider(),
                ],
                if (dataFasilitas.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 8, bottom: 10),
                    child: Text("Fasilitas Details", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  // Header Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text("Id & Nama Fasilitas", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text("Qty", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        Expanded(
                          child: Text("Harga Fasilitas", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(child: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                  Divider(),

                  // 👇 Dynamic Content (No fixed height)
                  Column(
                    children: [
                      for (var data in dataFasilitas)
                        Padding(
                          padding: const EdgeInsets.only(left: 10, right: 10),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: AutoSizeText(
                                  "${data['id_fasilitas']} - ${data['nama_fasilitas']}",
                                  minFontSize: 8,
                                  maxLines: 1,
                                ),
                              ),
                              Expanded(
                                child: AutoSizeText(
                                  "${data['qty']} ${data['satuan']}",
                                  minFontSize: 8,
                                  maxLines: 1,
                                ),
                              ),
                              Expanded(
                                child: AutoSizeText(
                                  "${currencyFormatter.format(data['harga_fasilitas'])}",
                                  minFontSize: 8,
                                  maxLines: 1,
                                ),
                              ),
                              Expanded(child: AutoSizeText("${data['status']}", minFontSize: 8, maxLines: 1)),
                            ],
                          ),
                        ),
                      Container(
                        width: double.infinity, // Take full width
                        padding: const EdgeInsets.only(left: 10, right: 30, top: 20),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Total Pembelian Fasilitas ${disc > 0 ? "(Sblm Disc)" : ""}:",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  currencyFormatter.format(fasilitasTotal),
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                            if (disc > 0) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Diskon :",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    "${disc * 100}%",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Total Pembelian Fasilitas (Stlh Disc):",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Builder(
                                    builder: (context) {
                                      var nominalDisc = fasilitasTotal * disc;
                                      var fasilitasStlhDisc = fasilitasTotal - nominalDisc;

                                      return Text(
                                        currencyFormatter.format(fasilitasStlhDisc),
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                  Divider(),
                ],
                if (dataMember.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 8, bottom: 10),
                    child: Text("Member Details", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  // Header Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text("Id & Nama Promo", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              "Jumlah Kunjungan",
                              style: TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              "Kunjungan\nBerlaku Sampai",
                              style: TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              "Tahunan\nBerlaku Sampai",
                              style: TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        Expanded(child: Text("Harga Promo", style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(child: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                  Divider(),
                  // 👇 Dynamic Content (No fixed height)
                  Column(
                    children: [
                      for (var data in dataMember)
                        Padding(
                          padding: const EdgeInsets.only(left: 10, right: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 270,
                                height: 25,
                                child: AutoSizeText(
                                  "${data['kode_promo']} - ${data['nama_promo']}",
                                  minFontSize: 8,
                                  maxLines: 1,
                                ),
                              ),
                              SizedBox(width: 10),
                              Container(
                                width: 60,
                                height: 25,
                                child: AutoSizeText(
                                  data?['sisa_kunjungan'] != null ? '${data!['sisa_kunjungan']} Kali' : '',
                                  minFontSize: 8,
                                  maxLines: 1,
                                ),
                              ),
                              SizedBox(width: 50),
                              Container(
                                width: 90,
                                height: 25,
                                child: AutoSizeText(
                                  formatDate(data?['exp_kunjungan']),
                                  minFontSize: 8,
                                  maxLines: 1,
                                ),
                              ),
                              SizedBox(width: 35),
                              Container(
                                width: 90,
                                height: 25,
                                child: AutoSizeText(
                                  formatDate(data?['exp_tahunan']),
                                  minFontSize: 8,
                                  maxLines: 1,
                                ),
                              ),
                              SizedBox(width: 5),
                              Container(
                                width: 120,
                                height: 25,
                                child: AutoSizeText(
                                  "${currencyFormatter.format(data['harga_promo'])}",
                                  minFontSize: 8,
                                  maxLines: 1,
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                width: 70,
                                height: 25,
                                child: AutoSizeText("${data['status']}", minFontSize: 8, maxLines: 1),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        width: double.infinity, // Take full width
                        padding: const EdgeInsets.only(left: 10, right: 30, top: 20),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Total Pembelian Member ${disc > 0 ? "(Sblm Disc)" : ""}:",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  currencyFormatter.format(memberTotal),
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                if (disc > 0) ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Diskon :",
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      Text(
                                        "${disc * 100}%",
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Total Pembelian Member (Stlh Disc):",
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      Builder(
                                        builder: (context) {
                                          var nominalDisc = memberTotal * disc;
                                          var memberStlhDisc = memberTotal - nominalDisc;

                                          return Text(
                                            currencyFormatter.format(memberStlhDisc),
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextEditingController txtIdTransFnb = TextEditingController();

  Future<void> storeIdTransFnb(String idTrans) async {
    try {
      var response = await dio.put(
        '${myIpAddr()}/listtrans/update_fnb',
        data: {"current_id_trans": idTrans, "new_id_trans": txtIdTransFnb.text},
      );

      if (response.statusCode == 200) {
        await refreshData();
      }
    } catch (e) {
      if (e is DioException) {
        log("Error pada Dio storeIdTransFnb ${e.response!.data}");
      }

      log("Error Store idTrans Fnb $e");
    }
  }

  void showDialogFnb(String idTrans) {
    Get.dialog(
      AlertDialog(
        content: SizedBox(
          height: 50,
          child: Column(
            children: [
              TextField(
                controller: txtIdTransFnb,
                decoration: InputDecoration(hintText: "Masukkan Id Transaksi Tambahan"),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              await storeIdTransFnb(idTrans);
              txtIdTransFnb.clear();
              Get.back();
            },
            child: Text("Simpan"),
          ),
        ],
      ),
    );
  }

  Future<void> downloadExcel() async {
    Get.dialog(
      const DownloadSplash(),
      barrierDismissible: false, // Prevent user from dismissing by tapping outside
    );
    try {
      // final dir = await getApplicationDocumentsDirectory();
      final dir = await getDownloadsDirectory();
      final filePath = '${dir?.path}/datapenjualan_platinum.pdf';

      String url = '${myIpAddr()}/main_owner/export_excel?';

      if (_hakAkses.value == "owner") {
        List<dynamic> rangeDate = rangeDatePickerOmset;
        if (rangeDate.isNotEmpty) {
          String startDate = rangeDate[0].toString().split(" ")[0];
          url += "start_date=$startDate";

          if (rangeDate.length == 2) {
            String endDate = rangeDate[1].toString().split(" ")[0];
            url += "&end_date=$endDate";
          }
        }
      }

      await dio.download(
        url,
        filePath,
        options: Options(responseType: ResponseType.bytes, headers: {'Accept': 'application/pdf'}),
      );

      // Close the loading dialog
      Get.back();

      // open downloaded file
      await OpenFile.open(filePath);
      log('File downloaded to: $filePath');
    } catch (e) {
      // Close the loading dialog
      Get.back();
      log('Error downloading file: $e');
    }
  }
}

class ListTransaksi extends StatelessWidget {
  ListTransaksi({super.key});

  final c = Get.put(ListTransaksiController());

  @override
  Widget build(BuildContext context) {
    // LOGIKA YANG DIPERBAIKI: Gunakan 'shortestSide' untuk deteksi tipe perangkat
    // Ini tidak akan terpengaruh oleh rotasi layar.
    final bool isMobile = MediaQuery.of(context).size.shortestSide < 600;
    // =======================================================================

    // 1. Tentukan lebar desain dasar Anda
    // 660 ini lebar terkecil DP tablet yg kita patok.
    const double tabletDesignWidth = 660;
    const double tabletDesignHeight = 1024;

    // 2. Tentukan faktor penyesuaian untuk mobile.
    const double mobileAdjustmentFactor = 1.125; // UI akan 12.5% lebih kecil

    // 3. Hitung designSize yang efektif berdasarkan tipe perangkat
    final double effectiveDesignWidth =
        isMobile ? tabletDesignWidth * mobileAdjustmentFactor : tabletDesignWidth;

    final double effectiveDesignHeight =
        isMobile ? tabletDesignHeight * mobileAdjustmentFactor : tabletDesignHeight;

    return ScreenUtilInit(
      // 660 ini lebar dp terkecil yang kita patok
      designSize: Size(effectiveDesignWidth, effectiveDesignHeight),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            // title: Container(
            //   width: 30,
            //   height: 30,
            //   child: ClipOval(child: Image.asset('assets/spa.jpeg')),
            // ),
            elevation: 0,
            scrolledUnderElevation: 0,
            toolbarHeight: 30,
            centerTitle: true,
            backgroundColor: Color(0XFFFFE0B2),
          ),
          body: Container(
            decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
            width: double.infinity,
            height: MediaQuery.of(context).size.height,
            child: Scrollbar(
              thumbVisibility: true,
              thickness: 5.0.w,
              radius: Radius.circular(10),
              // controller: c.singleChildController,
              child: SingleChildScrollView(
                // controller: c.singleChildController,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Text(
                        'List Transaksi',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 20.w, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(
                      // margin: EdgeInsets.only(left: 730),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 200.w,
                            margin: EdgeInsets.only(right: 50.w),
                            height: 40,
                            child: TextField(
                              onChanged: (value) {
                                c.onSearchChange(value);
                              },
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Input Kode Transaksi',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    Obx(() {
                      if (c._hakAkses.value == "owner" || c._hakAkses.value == "admin") {
                        return Container(
                          alignment: Alignment.centerLeft,
                          margin: EdgeInsets.only(top: 5, bottom: 5, left: 50.w, right: 50.w),
                          width: MediaQuery.of(context).size.width,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text("Pilih Jangka Waktu: "),

                                  ElevatedButton(
                                    onPressed: () {
                                      c.showDialogTgl();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text("Pilih", style: TextStyle(height: 1)),
                                  ),
                                ],
                              ),

                              Container(
                                constraints: BoxConstraints(minWidth: 0, maxWidth: double.infinity),
                                margin: EdgeInsets.only(top: 10.w),
                                alignment: Alignment.centerRight,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: InkWell(
                                    onTap: c.downloadExcel,
                                    child: Text(
                                      "Cetak Laporan",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Poppins',
                                        height: 0.5.w,
                                        fontSize: 11.w,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return SizedBox.shrink();
                    }),

                    Obx(() {
                      String teks = "";
                      List<dynamic> rangeDate = c.rangeDatePickerOmset;
                      if (rangeDate.isNotEmpty) {
                        String startDate = rangeDate[0].toString().split(" ")[0];
                        teks += "Tanggal Mulai: ${c.formatDate(startDate, format: "dd-MM-yyyy")} ";
                        if (rangeDate.length == 2) {
                          String endDate = rangeDate[1].toString().split(" ")[0];
                          teks += "| Tanggal Akhir: ${c.formatDate(endDate, format: "dd-MM-yyyy")}";
                        }
                      } else {
                        return SizedBox.shrink();
                      }
                      return Container(
                        margin: EdgeInsets.only(bottom: 5, left: 50.w, right: 50.w),
                        alignment: Alignment.centerLeft,
                        child: Text(teks),
                      );
                    }),

                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(left: 50.w, right: 50.w, top: 10),
                      height: 360.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        color: Colors.white,
                      ),
                      child: Container(
                        margin: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(width: 1),
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: Obx(() {
                            if (c._isNotFound.value || c.filteredList.isEmpty) {
                              return const Center(child: Text("Tidak Ada Transaksi"));
                            }

                            return ListView.builder(
                              itemCount: c.filteredList.length,
                              itemBuilder: (context, index) {
                                var item = c.filteredList[index];
                                // Calculate totals
                                // double produkTotal = item['isi_detail_produk']
                                //     .fold(0.0, (sum, produk) {
                                //   return sum + (produk['harga_total'] ?? 0.0);
                                // });
                                // double paketTotal =
                                //     item['isi_detail_paket'].fold(0.0, (sum, paket) {
                                //   return sum + (paket['harga_total'] ?? 0.0);
                                // });

                                return Column(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.1),
                                            spreadRadius: 2,
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Header row
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Flexible(
                                                child: Builder(
                                                  builder: (context) {
                                                    var teks = "${item['id_transaksi']}";

                                                    if (item['no_loker'] != -1) {
                                                      teks += " - Loker: ${item['no_loker']}";
                                                    }

                                                    if (item['is_cancel'] == 1) {
                                                      teks += " - DIBATALKAN -";
                                                    }

                                                    if (item['jenis_transaksi'] == "fnb" &&
                                                        item['nama_tamu'] == "") {
                                                      return Row(
                                                        children: [
                                                          Text(
                                                            teks,
                                                            style: TextStyle(
                                                              fontFamily: 'Poppins',
                                                              fontSize: 10.w,
                                                              fontWeight: FontWeight.bold,
                                                              color:
                                                                  item['is_cancel'] == 1
                                                                      ? Colors.red
                                                                      : Colors.black,
                                                            ),
                                                          ),
                                                          SizedBox(width: 10.w),
                                                          ElevatedButton(
                                                            onPressed: () {
                                                              c.showDialogFnb(item['id_transaksi']);
                                                            },
                                                            style: ElevatedButton.styleFrom(
                                                              padding: const EdgeInsets.fromLTRB(
                                                                20,
                                                                5,
                                                                20,
                                                                5,
                                                              ),
                                                              minimumSize: Size.zero,
                                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                            ),
                                                            child: Text(
                                                              "- Input Id Transaksi Tambahan -",
                                                              style: TextStyle(height: 1),
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    } else {
                                                      teks +=
                                                          item['nama_tamu'] == ""
                                                              ? ""
                                                              : " / ${item['nama_tamu']}";
                                                    }

                                                    // teks += " (${item['metode_pembayaran']})";

                                                    return Text(
                                                      teks,
                                                      style: TextStyle(
                                                        fontFamily: 'Poppins',
                                                        fontSize: 10.w,
                                                        fontWeight: FontWeight.bold,
                                                        color:
                                                            item['is_cancel'] == 1
                                                                ? Colors.red
                                                                : Colors.black,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                              Expanded(
                                                // Use a single FutureBuilder to fetch the data once.
                                                // cara ori ku pindahkan paling bawah
                                                child: FutureBuilder(
                                                  future: c.getDetailTrans(item['id_transaksi']),
                                                  builder: (context, snapshot) {
                                                    // Handle the loading state
                                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                                      return Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          // Use SizedBox to maintain space while loading
                                                          SizedBox(
                                                            width: 24,
                                                            height: 24,
                                                            child: CircularProgressIndicator(strokeWidth: 2),
                                                          ),
                                                          SizedBox(
                                                            width: 24,
                                                            height: 24,
                                                            child: CircularProgressIndicator(strokeWidth: 2),
                                                          ),
                                                        ],
                                                      );
                                                    }

                                                    // Handle the error state
                                                    if (snapshot.hasError) {
                                                      return Center(
                                                        child: Text(
                                                          'Error: ${snapshot.error}',
                                                          style: TextStyle(color: Colors.red),
                                                        ),
                                                      );
                                                    }

                                                    // Handle the state where data is successfully loaded
                                                    if (snapshot.hasData) {
                                                      final dataOri = snapshot.data!;
                                                      List<dynamic> dataAddOn = dataOri['all_addon'];
                                                      int totalAddOnAll = 0;

                                                      // Calculate the total for all add-ons with tax, performed only once.
                                                      if (item['total_addon'] != 0) {
                                                        for (var addon in dataAddOn) {
                                                          double pajak =
                                                              addon['type'] == 'fnb'
                                                                  ? c.pajakFnb.value
                                                                  : c.pajakMsg.value;
                                                          double nominalPjk = addon['harga_total'] * pajak;
                                                          double addOnSblmBulat =
                                                              addon['harga_total'] + nominalPjk;
                                                          totalAddOnAll +=
                                                              (addOnSblmBulat / 1000).round() * 1000;
                                                        }
                                                      }

                                                      // Build the Row with the calculated data.
                                                      return Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          // First child: Conditionally display the "Unpaid" status.
                                                          if (item['status'] == "unpaid" ||
                                                              item['status'] == 'done-unpaid' ||
                                                              item['status'] == 'done-unpaid-addon' ||
                                                              item['total_addon'] != 0) ...[
                                                            Builder(
                                                              builder: (context) {
                                                                String teks;
                                                                int totalDanAddon =
                                                                    item['gtotal_stlh_pajak'] + totalAddOnAll;
                                                                int jlhBayar =
                                                                    item['jumlah_bayar'] -
                                                                    item['jumlah_kembalian'];

                                                                if (item['status'] == "done-unpaid" ||
                                                                    item['status'] == "unpaid") {
                                                                  teks =
                                                                      "Belum Lunas: ${c.currencyFormatter.format(totalDanAddon - jlhBayar)}";
                                                                } else {
                                                                  teks =
                                                                      "Belum Lunas: ${c.currencyFormatter.format(totalAddOnAll)}";
                                                                }

                                                                return Text(
                                                                  teks,
                                                                  style: TextStyle(
                                                                    fontFamily: 'Poppins',
                                                                    fontSize: 10.w,
                                                                    fontWeight: FontWeight.bold,
                                                                    color: Colors.red.shade700,
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ] else ...[
                                                            // Render an empty Text to maintain space if the condition is false.
                                                            Text(""),
                                                          ],

                                                          // Second child: Always display the final total.
                                                          Text(
                                                            'Total: ${c.currencyFormatter.format(item['gtotal_stlh_pajak'] + totalAddOnAll)}',
                                                            style: TextStyle(
                                                              fontFamily: 'Poppins',
                                                              fontSize: 10.w,
                                                              fontWeight: FontWeight.bold,
                                                              color:
                                                                  item['is_cancel'] == 1
                                                                      ? Colors.red
                                                                      : Colors.blue.shade700,
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    }

                                                    // Handle the case where there is no data
                                                    return const Center(child: Text("No data available"));
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),

                                          SizedBox(height: 12),

                                          // Details section - left aligned
                                          Wrap(
                                            spacing: 4.w,
                                            runSpacing: 4.w,
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            children: [
                                              RichText(
                                                text: TextSpan(
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 9.w,
                                                    color: Colors.grey.shade800,
                                                  ),
                                                  children: [
                                                    TextSpan(
                                                      text: 'Disc: ',
                                                      style: TextStyle(fontWeight: FontWeight.bold),
                                                    ),
                                                    TextSpan(text: '${(item['disc'] * 100).toInt()}%'),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                height: 16,
                                                width: 1,
                                                color: Colors.grey.shade400,
                                                margin: EdgeInsets.symmetric(horizontal: 4),
                                              ),
                                              RichText(
                                                text: TextSpan(
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 9.w,
                                                    color: Colors.grey.shade800,
                                                  ),
                                                  children: [
                                                    TextSpan(
                                                      text: 'Jenis Transaksi: ',
                                                      style: TextStyle(fontWeight: FontWeight.bold),
                                                    ),
                                                    TextSpan(text: c.capitalize(item['jenis_transaksi'])),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                height: 16,
                                                width: 1,
                                                color: Colors.grey.shade400,
                                                margin: EdgeInsets.symmetric(horizontal: 4),
                                              ),
                                              RichText(
                                                text: TextSpan(
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 9.w,
                                                    color: Colors.grey.shade800,
                                                  ),
                                                  children: [
                                                    TextSpan(
                                                      text: 'Kamar: ',
                                                      style: TextStyle(fontWeight: FontWeight.bold),
                                                    ),
                                                    TextSpan(text: item['nama_ruangan']),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                height: 16,
                                                width: 1,
                                                color: Colors.grey.shade400,
                                                margin: EdgeInsets.symmetric(horizontal: 4),
                                              ),
                                              RichText(
                                                text: TextSpan(
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 9.w,
                                                    color: Colors.grey.shade800,
                                                  ),
                                                  children: [
                                                    TextSpan(
                                                      text: 'Jenis Tamu: ',
                                                      style: TextStyle(fontWeight: FontWeight.bold),
                                                    ),
                                                    TextSpan(text: item['jenis_tamu']),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                height: 16,
                                                width: 1,
                                                color: Colors.grey.shade400,
                                                margin: EdgeInsets.symmetric(horizontal: 4),
                                              ),
                                              RichText(
                                                text: TextSpan(
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 9.w,
                                                    color: Colors.grey.shade800,
                                                  ),
                                                  children: [
                                                    TextSpan(
                                                      text: 'Status: ',
                                                      style: TextStyle(fontWeight: FontWeight.bold),
                                                    ),
                                                    TextSpan(
                                                      text: c.capitalize(
                                                        item['status'] == 'unpaid' ||
                                                                item['status'] == "done-unpaid" ||
                                                                item['status'] == "done-unpaid-addon" ||
                                                                (item['total_addon'] != 0 &&
                                                                    item['status'] == "paid")
                                                            ? "Belum Lunas"
                                                            : "Lunas",
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),

                                          SizedBox(height: 12),

                                          Container(
                                            width: double.infinity,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Flexible(
                                                  child: Builder(
                                                    builder: (context) {
                                                      var createdAt = item['created_at'].toString().split(
                                                        "T",
                                                      );
                                                      var tgl = createdAt[0].toString().split("-");
                                                      var jam = createdAt[1];
                                                      var tglIndo = "${tgl[2]}-${tgl[1]}-${tgl[0]}";

                                                      return Text(
                                                        "Dibuat Pada: $tglIndo - $jam",
                                                        style: TextStyle(
                                                          fontFamily: 'Poppins',
                                                          fontSize: 8.w,
                                                          wordSpacing: 0,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Align(
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                      children: [
                                                        Visibility(
                                                          visible: item['is_cancel'] == 0,
                                                          child: IconButton(
                                                            onPressed: () {
                                                              showCancelTransactionDialog(context, (
                                                                password,
                                                              ) async {
                                                                // Do validation with the password
                                                                print("Password entered: $password");
                                                                // You can now validate password and cancel transaction here
                                                                try {
                                                                  await c.cancelTransaksi(
                                                                    item['id_transaksi'],
                                                                    password,
                                                                    Get.context,
                                                                  );
                                                                } catch (e) {
                                                                  log(
                                                                    "Error di Button ShowCancelTransaction $e",
                                                                  );
                                                                }
                                                              });
                                                            },
                                                            icon: Icon(Icons.cancel),
                                                          ),
                                                        ),
                                                        SizedBox(width: 10),
                                                        ElevatedButton(
                                                          onPressed: () {
                                                            log("isi item adalah $item");
                                                            c.dialogDetail(
                                                              item['id_transaksi'],
                                                              item['disc'],
                                                              item['jenis_pembayaran'],
                                                              item['is_cancel'],
                                                            );
                                                            // Add your button action here
                                                          },
                                                          style: ElevatedButton.styleFrom(
                                                            padding: EdgeInsets.symmetric(
                                                              horizontal: 16.w,
                                                              vertical: 8.w,
                                                            ),
                                                            backgroundColor: Colors.blue.shade600,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                          ),
                                                          child: Text(
                                                            'Details',
                                                            style: TextStyle(
                                                              fontFamily: 'Poppins',
                                                              fontWeight: FontWeight.w500,
                                                              color: Colors.white,
                                                              fontSize: 8.w,
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(width: 10),

                                                        ElevatedButton(
                                                          onPressed: () {
                                                            Get.to(
                                                              () => Rating(idTransaksi: item['id_transaksi']),
                                                            );
                                                          },
                                                          style: ElevatedButton.styleFrom(
                                                            padding: EdgeInsets.symmetric(
                                                              horizontal: 16.w,
                                                              vertical: 8.w,
                                                            ),
                                                            backgroundColor: Colors.blue.shade600,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                          ),
                                                          child: Text(
                                                            'Rating',
                                                            style: TextStyle(
                                                              fontFamily: 'Poppins',
                                                              fontWeight: FontWeight.w500,
                                                              color: Colors.white,
                                                              fontSize: 8.w,
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(width: 10),
                                                        if ((item['total_addon'] != 0 &&
                                                                item['status'] == "paid") ||
                                                            item['status'] == 'unpaid' ||
                                                            item['status'] == 'done-unpaid' ||
                                                            item['status'] == 'done-unpaid-addon') ...[
                                                          ElevatedButton(
                                                            onPressed: () {
                                                              // c.dialogDetail(
                                                              //     item['id_transaksi']);
                                                              // Add your button action here
                                                              log("Isi Item adalah $item");
                                                              // int totalAddOnOri = item['total_addon'];
                                                              // var totalAddOnAll = 0;
                                                              // if (item['total_addon'] != 0) {
                                                              //   double desimalPjk = item['pajak'];
                                                              //   double nominalPjk = totalAddOnOri * desimalPjk;
                                                              //   // Pembulatan 1000
                                                              //   double addOnSblmBulat = totalAddOnOri + nominalPjk;
                                                              //   totalAddOnAll = (addOnSblmBulat / 1000).round() * 1000;
                                                              // }

                                                              c.dialogPelunasan(
                                                                item['id_transaksi'],
                                                                item['gtotal_stlh_pajak'],
                                                                item['jumlah_bayar'],
                                                                item['jumlah_kembalian'],
                                                                item['status'],
                                                              );
                                                            },
                                                            style: ElevatedButton.styleFrom(
                                                              padding: EdgeInsets.symmetric(
                                                                horizontal: 16.w,
                                                                vertical: 8.w,
                                                              ),
                                                              backgroundColor: Colors.blue.shade600,
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                            ),
                                                            child: Text(
                                                              'Pelunasan',
                                                              style: TextStyle(
                                                                fontFamily: 'Poppins',
                                                                fontWeight: FontWeight.w500,
                                                                color: Colors.white,
                                                              ),
                                                            ),
                                                          ),
                                                        ] else ...[
                                                          ElevatedButton(
                                                            onPressed: () async {
                                                              // c.dialogDetail(
                                                              //     item['id_transaksi']);
                                                              // Add your button action here
                                                              log("Isi Item adalah $item");
                                                              // c.dialogPelunasan(
                                                              //   item['id_transaksi'],
                                                              //   item['grand_total'],
                                                              //   item['total_addon'],
                                                              //   item['jumlah_bayar'],
                                                              //   item['jumlah_kembalian'],
                                                              //   item['status'],
                                                              // );
                                                              // Get.to(
                                                              //   () => StrukTrans(
                                                              //     idTrans: item['id_transaksi'],
                                                              //     disc: item['disc'],
                                                              //     jenisPembayaran: item['jenis_pembayaran'],
                                                              //     dataTransaksi: () async => await c.getDetailTrans(item['id_transaksi']),
                                                              //   ),
                                                              // );
                                                              // new
                                                              // var data = await c.getDetailTrans(item['id_transaksi']);
                                                              // c.printStruk(data, item['id_transaksi']);

                                                              var data = await c.getDetailTrans(
                                                                item['id_transaksi'],
                                                              );

                                                              await c._processPrintViaLAN(data, item);
                                                            },
                                                            style: ElevatedButton.styleFrom(
                                                              padding: EdgeInsets.symmetric(
                                                                horizontal: 14.w,
                                                                vertical: 8.w,
                                                              ),
                                                              backgroundColor: Colors.blue.shade600,
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                            ),
                                                            child: Text(
                                                              'Cetak Struk',
                                                              style: TextStyle(
                                                                fontFamily: 'Poppins',
                                                                fontWeight: FontWeight.w500,
                                                                color: Colors.white,
                                                                fontSize: 8.w,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                  ],
                                );
                              },
                            );
                          }),
                        ),
                      ),
                    ),

                    SizedBox(height: 10),

                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(horizontal: 50.w),
                      child: Row(
                        children: [
                          // Label
                          Expanded(
                            flex: 1, // Give more space to the label
                            child: Obx(() {
                              String teksHarian = "Harian";
                              if (c.rangeDatePickerOmset.isNotEmpty) {
                                teksHarian = "Keseluruhan";
                              }

                              return Text(
                                "Omset $teksHarian",
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10.w),
                              );
                            }),
                          ),

                          // Cash
                          Expanded(
                            child: InkWell(
                              onTap: () => c.showDialogOmset("cash"),
                              child: Obx(
                                () => Text(
                                  "Cash: ${c.currencyFormatter.format(c.omsetCash.value)}",
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w900,
                                    fontSize: 9.5.w,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Debit
                          Expanded(
                            child: InkWell(
                              onTap: () => c.showDialogOmset("debit"),
                              child: Obx(
                                () => Text(
                                  "Debit: ${c.currencyFormatter.format(c.omsetDebit.value)}",
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w900,
                                    fontSize: 9.5.w,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Kredit
                          Expanded(
                            child: InkWell(
                              onTap: () => c.showDialogOmset("kredit"),
                              child: Obx(
                                () => Text(
                                  "Kredit: ${c.currencyFormatter.format(c.omsetKredit.value)}",
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    color: const Color.fromARGB(255, 54, 109, 2),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 9.5.w,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Qris
                          Expanded(
                            child: InkWell(
                              onTap: () => c.showDialogOmset("qris"),
                              child: Obx(
                                () => Text(
                                  "Qris: ${c.currencyFormatter.format(c.omsetQris.value)}",
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    color: Colors.purple[700],
                                    fontWeight: FontWeight.w900,
                                    fontSize: 9.5.w,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 65),
                  ],
                ),
              ),
            ),
          ),
          drawer: Obx(() {
            if (c._hakAkses.value == "admin") {
              return AdminDrawer();
            } else {
              return OurDrawer();
            }
          }),
        );
      },
    );
  }
}

void showCancelTransactionDialog(BuildContext context, void Function(String) onConfirm) async {
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Use an RxBool for reactive state management with GetX
  final RxBool isPasswordVisible = false.obs;

  Get.dialog(
    AlertDialog(
      title: const Text("Batal Transaksi"),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Masukkan Password untuk membatalkan transaksi"),
            const SizedBox(height: 10),
            Obx(
              // Obx listens to changes in observable variables
              () => TextFormField(
                controller: passwordController,
                obscureText: !isPasswordVisible.value, // Access value with .value
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: "Password",
                  suffixIcon: IconButton(
                    icon: Icon(isPasswordVisible.value ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      isPasswordVisible.toggle(); // Toggle the RxBool value
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password tidak boleh kosong';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(), // Use Get.back() to close dialog
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Get.back(); // Close dialog
              onConfirm(passwordController.text); // Handle password
            }
          },
          child: const Text("Confirm"),
        ),
      ],
    ),
  );
}


  // Cara Caching. Minusnya Ntr Klo Update tktny g fungsi
  // Expanded(
  //   // Use a single FutureBuilder to fetch the data once.
  //   child: Builder(
  //     builder: (context) {
  //       // Gunakan data yang sudah di-cache
  //       final dataOri = c.detailTrans[item['id_transaksi']] ?? {};
  //       List<dynamic> dataAddOn = dataOri['all_addon'] ?? [];
  //       int totalAddOnAll = 0;

  //       // Calculate the total for all add-ons with tax, performed only once.
  //       if (item['total_addon'] != 0) {
  //         for (var addon in dataAddOn) {
  //           double pajak = addon['type'] == 'fnb' ? c.pajakFnb.value : c.pajakMsg.value;
  //           double nominalPjk = addon['harga_total'] * pajak;
  //           double addOnSblmBulat = addon['harga_total'] + nominalPjk;
  //           totalAddOnAll += (addOnSblmBulat / 1000).round() * 1000;
  //         }
  //       }

  //       // Build the Row with the calculated data.
  //       return Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [
  //           // First child: Conditionally display the "Unpaid" status.
  //           if (item['status'] == "unpaid" ||
  //               item['status'] == 'done-unpaid' ||
  //               item['status'] == 'done-unpaid-addon' ||
  //               item['total_addon'] != 0) ...[
  //             Builder(
  //               builder: (context) {
  //                 String teks;
  //                 int totalDanAddon = item['gtotal_stlh_pajak'] + totalAddOnAll;
  //                 int jlhBayar = item['jumlah_bayar'] - item['jumlah_kembalian'];

  //                 if (item['status'] == "done-unpaid" || item['status'] == "unpaid") {
  //                   teks = "Belum Lunas: ${c.currencyFormatter.format(totalDanAddon - jlhBayar)}";
  //                 } else {
  //                   teks = "Belum Lunas: ${c.currencyFormatter.format(totalAddOnAll)}";
  //                 }

  //                 return Text(
  //                   teks,
  //                   style: TextStyle(
  //                     fontFamily: 'Poppins',
  //                     fontSize: 16,
  //                     fontWeight: FontWeight.bold,
  //                     color: Colors.red.shade700,
  //                   ),
  //                 );
  //               },
  //             ),
  //           ] else ...[
  //             // Render an empty Text to maintain space if the condition is false.
  //             Text(""),
  //           ],

  //           // Second child: Always display the final total.
  //           Text(
  //             'Total: ${c.currencyFormatter.format(item['gtotal_stlh_pajak'] + totalAddOnAll)}',
  //             style: TextStyle(
  //               fontFamily: 'Poppins',
  //               fontSize: 16,
  //               fontWeight: FontWeight.bold,
  //               color: Colors.blue.shade700,
  //             ),
  //           ),
  //         ],
  //       );
  //     },
  //   ),
  // ),
  //  Cara Awal
  // Expanded(
  //   child: Row(
  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //     children: [
  //       if (item['status'] == "unpaid" ||
  //           item['status'] == 'done-unpaid' ||
  //           item['status'] == 'done-unpaid-addon' ||
  //           item['total_addon'] != 0) ...[

  //         // Pake widget builder buat bs anok fungsi
  //         Builder(
  //           builder: (context) {
  //             var teks = "";

  //             int totalAddOnOri = item['total_addon'];
  //             var totalAddOnAll = 0;
  //             if (item['total_addon'] != 0) {
  //               double desimalPjk = item['pajak'];
  //               double nominalPjk = totalAddOnOri * desimalPjk;
  //               // Pembulatan 1000
  //               double addOnSblmBulat = totalAddOnOri + nominalPjk;
  //               totalAddOnAll = (addOnSblmBulat / 1000).round() * 1000;
  //             }

  //             int totalDanAddon = item['gtotal_stlh_pajak'] + totalAddOnAll;
  //             int jlhBayar = item['jumlah_bayar'] - item['jumlah_kembalian'];

  //             if (item['status'] == "done-unpaid" || item['status'] == "unpaid") {
  //               teks = "Belum Lunas: ${c.currencyFormatter.format(totalDanAddon - jlhBayar)}";

  //               // Case kalo dia udh bayar, tp ganti paket yg lebih mahal
  //               // if (totalDanAddon > jlhBayar) {
  //               //   teks = "Belum Lunas: ${c.currencyFormatter.format(totalDanAddon - jlhBayar)}";
  //               // }
  //             } else {
  //               teks = "Belum Lunas: ${c.currencyFormatter.format(totalAddOnAll)}";
  //             }
  //             return Text(
  //               teks,
  //               style: TextStyle(
  //                 fontFamily: 'Poppins',
  //                 fontSize: 16,
  //                 fontWeight: FontWeight.bold,
  //                 color: Colors.red.shade700,
  //               ),
  //             );
  //           },
  //         ),
  //       ] else ...[
  //         Text(""),
  //       ],

  //       Builder(
  //         builder: (context) {
  //           int totalAddOnOri = item['total_addon'];
  //           var totalAddOnAll = 0;
  //           if (item['total_addon'] != 0) {
  //             double desimalPjk = item['pajak'];
  //             double nominalPjk = totalAddOnOri * desimalPjk;
  //             // Pembulatan 1000
  //             double addOnSblmBulat = totalAddOnOri + nominalPjk;
  //             totalAddOnAll = (addOnSblmBulat / 1000).round() * 1000;
  //           }

  //           return Text(
  //             'Total: ${c.currencyFormatter.format(item['gtotal_stlh_pajak'] + totalAddOnAll)}',
  //             style: TextStyle(
  //               fontFamily: 'Poppins',
  //               fontSize: 16,
  //               fontWeight: FontWeight.bold,
  //               color: Colors.blue.shade700,
  //             ),
  //           );
  //         },
  //       ),
  //     ],
  //   ),
  // ),