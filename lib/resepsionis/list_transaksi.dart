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
import 'package:Project_SPA/function/ip_address.dart';
import 'package:Project_SPA/function/our_drawer.dart';
import 'package:Project_SPA/resepsionis/rating.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:Project_SPA/function/me.dart';
import 'package:Project_SPA/function/token.dart';
import 'package:Project_SPA/main.dart';
// import 'package:printing/printing.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'printer_mgr.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart'; // This is crucial
// import 'package:thermal_printer/thermal_printer.dart';

class ListTransaksiController extends GetxController {
  RxList<Map<String, dynamic>> dataList = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> filteredList = <Map<String, dynamic>>[].obs;
  TextEditingController textcari = TextEditingController();
  Timer? _debounce;
  Timer? _refreshTimer;

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
  //   textcari.clear();
  //   _debounce?.cancel();
  //   _refreshTimer?.cancel();
  //   super.onClose();
  // }

  @override
  void onClose() {
    textcari.dispose();
    _txtSisaBayar.dispose();
    _txtJlhBayar.dispose();
    _txtKembalian.dispose();
    _namaAkun.dispose();
    _noRek.dispose();
    _namaBank.dispose();
    _debounce?.cancel();
    _refreshTimer?.cancel();
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
  RxInt omsetQris = 0.obs;

  Future<List<Map<String, dynamic>>> fetchData() async {
    try {
      final response = await dio.get(
        '${myIpAddr()}/listtrans/datatrans?hak_akses=${_hakAkses.value}',
      );

      if (response.statusCode == 200) {
        omsetCash.value = (response.data['total_cash'] as int);
        omsetDebit.value = (response.data['total_debit'] as int);
        omsetQris.value = (response.data['total_qris'] as int);

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
        double pjk =
            double.tryParse(firstRecord['pajak_msg'].toString()) ?? 0.0;
        double pjkFnb =
            double.tryParse(firstRecord['pajak_fnb'].toString()) ?? 0.0;

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
      print(response);

      Map<String, dynamic> responseData = response['data'];
      _hakAkses.value = responseData['hak_akses'];

      // storage.write("id_resepsionis", responseData['id_karyawan']);
      // storage.write("nama_resepsionis", responseData['nama_karyawan']);

      // namaKaryawan.value = responseData['nama_karyawan'];
      // jabatan.value = responseData['jabatan'];
    } catch (e) {
      log("Error di $e");
    }
  }

  void startAutoRefresh() {
    _refreshTimer?.cancel();

    _refreshTimer = Timer.periodic(Duration(seconds: 50), (timer) {
      refreshData();
      textcari.clear();
    });
  }

  Future<void> refreshData() async {
    try {
      final data = await fetchData();
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
      (item) => item['id_transaksi'].toString().toLowerCase().contains(
        query.toLowerCase(),
      ),
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

  void isibuttoneditruangan(BuildContext context, Map<String, dynamic> item) {
    TextEditingController nmRuangController = TextEditingController(
      text: item['nama_ruangan'],
    );
    TextEditingController lantaiController = TextEditingController(
      text: item['lantai'].toString(),
    );
    String? dropdownValue = item['jenis_ruangan'];

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            actions: [
              Container(
                width: Get.width - 350,
                height: Get.height - 350,
                child: ListView(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.zero,
                          child: Container(
                            margin: EdgeInsets.only(top: 80),
                            height: 140,
                            width: 200,
                            child: Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  SizedBox(height: 15),
                                  Text(
                                    'Nama Kamar :',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 18,
                                    ),
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    'Lantai :',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 18,
                                    ),
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    'Jenis Kamar :',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(top: 80),
                          height: 230,
                          width: 500,
                          child: Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 12),
                                Container(
                                  alignment: Alignment.centerLeft,
                                  width: 480,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.grey[300],
                                  ),
                                  child: TextField(
                                    controller: nmRuangController,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 13.5,
                                        horizontal: 10,
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                                SizedBox(height: 12),
                                Container(
                                  alignment: Alignment.centerLeft,
                                  width: 480,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.grey[300],
                                  ),
                                  child: TextField(
                                    keyboardType: TextInputType.number,
                                    inputFormatters: <TextInputFormatter>[
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    controller: lantaiController,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 13.5,
                                        horizontal: 10,
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                                SizedBox(height: 12),
                                Container(
                                  width: 480,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.grey[300],
                                  ),
                                  child: DropdownButton<String>(
                                    value: dropdownValue,
                                    isExpanded: true,
                                    icon: const Icon(Icons.arrow_drop_down),
                                    elevation: 16,
                                    style: const TextStyle(
                                      color: Colors.deepPurple,
                                    ),
                                    underline: SizedBox(),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    onChanged: (String? value) {
                                      setState(() {
                                        dropdownValue = value;
                                      });
                                    },
                                    items:
                                        listJenisRuang.map<
                                          DropdownMenuItem<String>
                                        >((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                value,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ),
                                SizedBox(height: 20),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    right: 170,
                                    top: 20,
                                  ),
                                  child: Center(
                                    child: SizedBox(
                                      height: 50,
                                      width: 120,
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.green,
                                        ),
                                        onPressed: () async {
                                          final response = await dio.put(
                                            '${myIpAddr()}/ListTransaksi/update_room/${item['id_ruangan'].toString()}',
                                            data: {
                                              "nama_ruangan":
                                                  nmRuangController.text,
                                              "lantai":
                                                  int.tryParse(
                                                    lantaiController.text,
                                                  ) ??
                                                  0,
                                              "jenis_ruangan": dropdownValue,
                                            },
                                          );
                                          if (response.statusCode == 200) {
                                            Get.back(result: "updated");
                                            await refreshData();
                                            textcari.clear();
                                            nmRuangController.clear();
                                            lantaiController.clear();
                                            dropdownValue = null;
                                            CherryToast.success(
                                              title: Text(
                                                'Data berhasil diupdate',
                                              ),
                                            ).show(context);
                                          }
                                        },
                                        child: Text(
                                          'Simpan',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String capitalize(String? text) {
    if (text == null || text.isEmpty) return "Unknown"; // Handle null or empty
    return text[0].toUpperCase() + text.substring(1);
  }

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp. ',
    decimalDigits: 0,
  );

  Future<Map<String, dynamic>> getDetailTrans(String idTrans) async {
    try {
      final response = await dio.get(
        '${myIpAddr()}/listtrans/detailtrans/${idTrans}',
      );

      if (response.statusCode == 200) {
        return (response.data as Map<String, dynamic>);
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

  void _fnFormatTotalBayar(String value) {
    // Hapus Non Digit Char
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

  void dialogPelunasan(
    String idTrans,
    int grandTotal,
    int jumlahBayar,
    int kembalian,
    String status,
  ) async {
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
    } else if (status == "done-unpaid-addon" ||
        (totalAddOnAll != 0 && status == "paid")) {
      _sisaBayar.value =
          totalAddOnAll; // Gunakan totalAddOnAll yang sudah termasuk pajak
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
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text("Sisa Bayar"),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: TextField(readOnly: true, controller: _txtSisaBayar),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text("Metode Bayar"),
                    ),
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
                      _txtJlhBayar.text = currencyFormatter.format(
                        _sisaBayar.value,
                      );
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
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
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
                            child: Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: Text("Kembalian"),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _txtKembalian,
                              readOnly: true,
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
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Nama Akun: ",
                              style: TextStyle(fontFamily: 'Poppins'),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: TextField(controller: _namaAkun),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Nomor Rekening: ",
                              style: TextStyle(fontFamily: 'Poppins'),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: TextField(controller: _noRek),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Nama Bank: ",
                              style: TextStyle(fontFamily: 'Poppins'),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Obx(
                              () => DropdownButtonFormField<String>(
                                value:
                                    c.selectedBank.value.isEmpty
                                        ? null
                                        : c.selectedBank.value,
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    c.selectedBank.value = newValue;
                                  }
                                },
                                items:
                                    c.bankList.map((String bank) {
                                      return DropdownMenuItem<String>(
                                        value: bank,
                                        child: Text(bank),
                                      );
                                    }).toList(),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 12,
                                  ),
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
                                  if (_txtJlhBayar.text == "" ||
                                      _txtJlhBayar.text.isEmpty) {
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

      var response = await dio.put(
        '${myIpAddr()}/massages/pelunasan',
        data: data,
      );

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

  // Alur awalnya Process dlu baru Print Receipt
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
        "id_item":
            dataAddOn[i]['id_fnb'] ??
            dataAddOn[i]['id_produk'] ??
            dataAddOn[i]['id_paket'],
        "nama_item":
            dataAddOn[i]['nama_fnb'] ??
            dataAddOn[i]['nama_produk'] ??
            dataAddOn[i]['nama_paket_msg'],
        "qty": dataAddOn[i]['qty'],
        "satuan": dataAddOn[i]['satuan'],
        "harga_item": dataAddOn[i]['harga_item'],
        "harga_total": dataAddOn[i]['harga_total'],
        "durasi": tipe == "fnb" ? "-" : dataAddOn[i]['durasi_awal'],
        "status": dataAddOn[i]['status'],
      };

      _combinedAddOn.add(data);
    }

    await _printReceiptViaLAN(
      mainTrans['id_transaksi'],
      mainTrans['disc'],
      mainTrans['jenis_pembayaran'],
      mainTrans['no_loker'],
      mainTrans['nama_tamu'],
      mainTrans['metode_pembayaran'],
      mainTrans['nama_bank'] ?? "-",
      mainTrans['pajak'],
      mainTrans['gtotal_stlh_pajak'],
      dataProduk,
      dataPaket,
      dataFood,
      dataFasilitas,
      _combinedAddOn,
      dataMember,
    );
  }

  Future<void> _printReceiptViaLAN(
    String idTrans,
    double disc,
    int jenisPembayaran,
    int noLoker,
    String namaTamu,
    String metodePembayaran,
    String namaBank,
    double pajak,
    int gTotalStlhPajak,
    List<dynamic> dataProduk,
    List<dynamic> dataPaket,
    List<dynamic> dataFood,
    List<dynamic> dataFasilitas,
    List<Map<String, dynamic>> combinedAddOn,
    List<dynamic> dataMemberFirstTime,
  ) async {
    // Set Ip Printer static
    const String printerIp = '192.168.1.30';
    const int printerPort = 9100; //biasanya

    try {
      final printer = NetworkPrinter(
        PaperSize.mm80,
        await CapabilityProfile.load(name: 'default'),
      );
      final PosPrintResult res = await printer.connect(
        printerIp,
        port: printerPort,
      );

      if (res == PosPrintResult.success) {
        // printer.text('Special characters: áéíóú', styles: PosStyles(codeTable: 'CP1252')); // Western European

        await PrinterHelper.printReceipt(
          idTrans: idTrans,
          disc: disc,
          jenisPembayaran: jenisPembayaran,
          noLoker: noLoker,
          namaTamu: namaTamu == "" ? "-" : namaTamu,
          metodePembayaran: metodePembayaran,
          namaBank: namaBank,
          pajak: pajak,
          gTotalStlhPajak: gTotalStlhPajak,
          printer: printer,
          dataProduk: dataProduk,
          dataPaket: dataPaket,
          dataFood: dataFood,
          dataFasilitas: dataFasilitas,
          combinedAddOn: combinedAddOn,
          dataMemberFirstTime: dataMemberFirstTime,
        );

        printer.disconnect();
      } else {
        Get.snackbar('Error', 'Gagal Konek Printer');
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal Printing $e');
    }
  }
  // End Print Via LAN

  // Print Via USB
  // Future<void> _processPrintViaUSB(data, String idTrans, double disc, int jenisPembayaran) async {}

  // Future<void> _printReceiptViaUSB(
  //   String idTrans,
  //   double disc,
  //   int jenisPembayaran,
  //   List<dynamic> dataProduk,
  //   List<dynamic> dataPaket,
  //   List<dynamic> dataFood,
  //   List<dynamic> dataFasilitas,
  //   List<Map<String, dynamic>> combinedAddOn,
  // ) async {
  //   final manager = PrinterManager.instance;

  //   PrinterDevice? selectedPrinter;

  //   // Cari Usb Printer
  //   final discovery = manager.discovery(type: PrinterType.usb);

  //   await for (final device in discovery) {
  //     print('🔍 Found USB printer: ${device.name} (${device.vendorId}:${device.productId})');
  //     selectedPrinter = device;
  //     break; // just pick the first for this example
  //   }

  //   if (selectedPrinter == null) {
  //     print('❌ No USB printer found');
  //     return;
  //   }

  //   final connected = await manager.connect(
  //     type: PrinterType.usb,
  //     model: UsbPrinterInput(
  //       name: selectedPrinter.name,
  //       productId: selectedPrinter.productId,
  //       vendorId: selectedPrinter.vendorId,
  //     ),
  //   );

  //   if (!connected) {
  //     print('❌ Failed to connect to printer');
  //     return;
  //   }

  //   final bytes = await PrinterHelperUSB.buildReceiptContent(
  //     idTrans: idTrans,
  //     disc: disc,
  //     jenisPembayaran: jenisPembayaran,
  //     dataProduk: dataProduk,
  //     dataPaket: dataPaket,
  //     dataFood: dataFood,
  //     dataFasilitas: dataFasilitas,
  //     combinedAddOn: combinedAddOn,
  //   );

  //   final success = await manager.send(type: PrinterType.usb, bytes: bytes);
  //   if (success) {
  //     print('✅ Print success!');
  //   } else {
  //     print('❌ Print failed!');
  //   }

  //   // Optional: disconnect
  //   await manager.disconnect(type: PrinterType.usb);
  // }

  void dialogDetail(String idTrans, double disc, int jenisPembayaran) async {
    final dataOri = await getDetailTrans(idTrans);
    List<dynamic> dataProduk = dataOri['detail_produk'];
    List<dynamic> dataPaket = dataOri['detail_paket'];
    List<dynamic> dataFood = dataOri['detail_food'];
    List<dynamic> dataFasilitas = dataOri['detail_fasilitas'];
    List<dynamic> dataMember = dataOri['detail_member'];
    log('dataMember: $dataMember');
    List<dynamic> dataAddOn = dataOri['all_addon'];
    List<Map<String, dynamic>> _combinedAddOn = [];
    _combinedAddOn.clear();

    int produkTotal = 0;
    int paketTotal = 0;
    int foodTotal = 0;
    int fasilitasTotal = 0;
    int memberTotal = 0;
    int addOnTotal = 0;

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
        "id_item":
            dataAddOn[i]['id_fnb'] ??
            dataAddOn[i]['id_produk'] ??
            dataAddOn[i]['id_paket'],
        "nama_item":
            dataAddOn[i]['nama_fnb'] ??
            dataAddOn[i]['nama_produk'] ??
            dataAddOn[i]['nama_paket_msg'],
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

    Get.dialog(
      AlertDialog(
        title: Center(
          child: Column(
            children: [Text("Detail Transaksi ${idTrans}"), Divider()],
          ),
        ),
        content: Container(
          height: Get.height - 100,
          width: Get.width - 200,
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (_combinedAddOn.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      top: 8,
                      bottom: 10,
                    ),
                    child: Text(
                      "AddOn Details",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Header Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            "Id & Nama Addon",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              "Qty",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Harga Satuan",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Total Harga",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Durasi (Menit)",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Status",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
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
                                  data['type'] != "fnb"
                                      ? "${data['durasi']} x ${data['qty']}"
                                      : "-",
                                  minFontSize: 8,
                                  maxLines: 1,
                                ),
                              ),
                              Expanded(
                                child: AutoSizeText(
                                  "${data['status']}",
                                  minFontSize: 8,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        width: double.infinity, // Take full width
                        padding: const EdgeInsets.only(
                          left: 10,
                          right: 30,
                          top: 20,
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Total Pembelian Addon ${disc > 0 && jenisPembayaran == 1 ? "(Sblm Disc)" : ""}:",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  currencyFormatter.format(addOnTotal),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            if (disc > 0 && jenisPembayaran == 1) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Diskon :",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    "${disc * 100}%",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Total Pembelian Addon (Stlh Disc):",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Builder(
                                    builder: (context) {
                                      var nominalDisc = paketTotal * disc;
                                      var paketStlhDisc =
                                          paketTotal - nominalDisc;

                                      return Text(
                                        currencyFormatter.format(paketStlhDisc),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
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
                    padding: const EdgeInsets.only(
                      left: 16,
                      top: 8,
                      bottom: 10,
                    ),
                    child: Text(
                      "Paket Details",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Header Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            "Id & Nama Paket",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              "Qty",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Harga Satuan",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Total Harga",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Durasi (Menit)",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Status",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
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
                                child: AutoSizeText(
                                  "${paket['status']}",
                                  minFontSize: 8,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        width: double.infinity, // Take full width
                        padding: const EdgeInsets.only(
                          left: 10,
                          right: 30,
                          top: 20,
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Total Pembelian Paket ${disc > 0 ? "(Sblm Disc)" : ""}:",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  currencyFormatter.format(paketTotal),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            if (disc > 0) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Diskon :",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    "${disc * 100}%",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Total Pembelian Paket (Stlh Disc):",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Builder(
                                    builder: (context) {
                                      var nominalDisc = paketTotal * disc;
                                      var paketStlhDisc =
                                          paketTotal - nominalDisc;

                                      return Text(
                                        currencyFormatter.format(paketStlhDisc),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
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
                    padding: const EdgeInsets.only(
                      left: 16,
                      top: 8,
                      bottom: 10,
                    ),
                    child: Text(
                      "Produk Details",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Header Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            "Id & Nama Produk",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              "Qty",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Harga Satuan",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Total Harga",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Durasi (Menit)",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Status",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
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
                                child: AutoSizeText(
                                  "${produk['status']}",
                                  minFontSize: 8,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        width: double.infinity, // Take full width
                        padding: const EdgeInsets.only(
                          left: 10,
                          right: 30,
                          top: 20,
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Total Pembelian Produk ${disc > 0 ? "(Sblm Disc)" : ""}:",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  currencyFormatter.format(produkTotal),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            if (disc > 0) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Diskon :",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    "${disc * 100}%",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Total Pembelian Produk (Stlh Disc):",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Builder(
                                    builder: (context) {
                                      var nominalDisc = produkTotal * disc;
                                      var produkStlhDisc =
                                          produkTotal - nominalDisc;

                                      return Text(
                                        currencyFormatter.format(
                                          produkStlhDisc,
                                        ),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
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
                    padding: const EdgeInsets.only(
                      left: 16,
                      top: 8,
                      bottom: 10,
                    ),
                    child: Text(
                      "Food Details",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Header Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            "Id & Nama Food",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              "Qty",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Harga Satuan",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Total Harga",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Status",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
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
                              Expanded(
                                child: AutoSizeText(
                                  "${food['status']}",
                                  minFontSize: 8,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        width: double.infinity, // Take full width
                        padding: const EdgeInsets.only(
                          left: 10,
                          right: 30,
                          top: 20,
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Total Pembelian Food ${disc > 0 ? "(Sblm Disc)" : ""}:",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  currencyFormatter.format(foodTotal),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            if (disc > 0) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Diskon :",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    "${disc * 100}%",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Total Pembelian Food (Stlh Disc):",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Builder(
                                    builder: (context) {
                                      var nominalDisc = foodTotal * disc;
                                      var foodStlhDisc =
                                          foodTotal - nominalDisc;

                                      return Text(
                                        currencyFormatter.format(foodStlhDisc),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
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
                    padding: const EdgeInsets.only(
                      left: 16,
                      top: 8,
                      bottom: 10,
                    ),
                    child: Text(
                      "Fasilitas Details",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Header Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            "Id & Nama Fasilitas",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              "Qty",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Harga Fasilitas",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Status",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
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
                              Expanded(
                                child: AutoSizeText(
                                  "${data['status']}",
                                  minFontSize: 8,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        width: double.infinity, // Take full width
                        padding: const EdgeInsets.only(
                          left: 10,
                          right: 30,
                          top: 20,
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Total Pembelian Fasilitas ${disc > 0 ? "(Sblm Disc)" : ""}:",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  currencyFormatter.format(fasilitasTotal),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            if (disc > 0) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Diskon :",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    "${disc * 100}%",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Total Pembelian Fasilitas (Stlh Disc):",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Builder(
                                    builder: (context) {
                                      var nominalDisc = fasilitasTotal * disc;
                                      var fasilitasStlhDisc =
                                          fasilitasTotal - nominalDisc;

                                      return Text(
                                        currencyFormatter.format(
                                          fasilitasStlhDisc,
                                        ),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
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
                    padding: const EdgeInsets.only(
                      left: 16,
                      top: 8,
                      bottom: 10,
                    ),
                    child: Text(
                      "Member Details",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Header Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            "Id & Nama Promo",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
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
                        Expanded(
                          child: Text(
                            "Harga Promo",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Status",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
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
                                  data?['sisa_kunjungan'] != null
                                      ? '${data!['sisa_kunjungan']} Kali'
                                      : '',
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
                                child: AutoSizeText(
                                  "${data['status']}",
                                  minFontSize: 8,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        width: double.infinity, // Take full width
                        padding: const EdgeInsets.only(
                          left: 10,
                          right: 30,
                          top: 20,
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Total Pembelian Member ${disc > 0 ? "(Sblm Disc)" : ""}:",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  currencyFormatter.format(memberTotal),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                if (disc > 0) ...[
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Diskon :",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        "${disc * 100}%",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Total Pembelian Member (Stlh Disc):",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Builder(
                                        builder: (context) {
                                          var nominalDisc = memberTotal * disc;
                                          var memberStlhDisc =
                                              memberTotal - nominalDisc;

                                          return Text(
                                            currencyFormatter.format(
                                              memberStlhDisc,
                                            ),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
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
}

class ListTransaksi extends StatelessWidget {
  ListTransaksi({super.key}) {
    Get.lazyPut<ListTransaksiController>(
      () => ListTransaksiController(),
      fenix: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ListTransaksiController>();

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
        width: Get.width,
        height: Get.height,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text(
                  'List Transaksi',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: 730),
                child: Row(
                  children: [
                    Container(
                      width: 250,
                      height: 40,
                      child: TextField(
                        controller: c.textcari,
                        onChanged: c.onSearchChange,
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
              Container(
                width: 900,
                height: 420,
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
                  child: Container(
                    width: 400,
                    child: Obx(() {
                      if (c._isNotFound.value) {
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
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Builder(
                                            builder: (context) {
                                              var teks =
                                                  "${item['id_transaksi']}";

                                              if (item['no_loker'] != -1) {
                                                teks +=
                                                    " - Loker: ${item['no_loker']}";
                                              }

                                              // teks += " (${item['metode_pembayaran']})";

                                              return Text(
                                                teks,
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        Expanded(
                                          // Use a single FutureBuilder to fetch the data once.
                                          child: FutureBuilder(
                                            future: c.getDetailTrans(
                                              item['id_transaksi'],
                                            ),
                                            builder: (context, snapshot) {
                                              // Handle the loading state
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    // Use SizedBox to maintain space while loading
                                                    SizedBox(
                                                      width: 24,
                                                      height: 24,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                          ),
                                                    ),
                                                    SizedBox(
                                                      width: 24,
                                                      height: 24,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                          ),
                                                    ),
                                                  ],
                                                );
                                              }

                                              // Handle the error state
                                              if (snapshot.hasError) {
                                                return Center(
                                                  child: Text(
                                                    'Error: ${snapshot.error}',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                );
                                              }

                                              // Handle the state where data is successfully loaded
                                              if (snapshot.hasData) {
                                                final dataOri = snapshot.data!;
                                                List<dynamic> dataAddOn =
                                                    dataOri['all_addon'];
                                                int totalAddOnAll = 0;

                                                // Calculate the total for all add-ons with tax, performed only once.
                                                if (item['total_addon'] != 0) {
                                                  for (var addon in dataAddOn) {
                                                    double pajak =
                                                        addon['type'] == 'fnb'
                                                            ? c.pajakFnb.value
                                                            : c.pajakMsg.value;
                                                    double nominalPjk =
                                                        addon['harga_total'] *
                                                        pajak;
                                                    double addOnSblmBulat =
                                                        addon['harga_total'] +
                                                        nominalPjk;
                                                    totalAddOnAll +=
                                                        (addOnSblmBulat / 1000)
                                                            .round() *
                                                        1000;
                                                  }
                                                }

                                                // Build the Row with the calculated data.
                                                return Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    // First child: Conditionally display the "Unpaid" status.
                                                    if (item['status'] ==
                                                            "unpaid" ||
                                                        item['status'] ==
                                                            'done-unpaid' ||
                                                        item['status'] ==
                                                            'done-unpaid-addon' ||
                                                        item['total_addon'] !=
                                                            0) ...[
                                                      Builder(
                                                        builder: (context) {
                                                          String teks;
                                                          int totalDanAddon =
                                                              item['gtotal_stlh_pajak'] +
                                                              totalAddOnAll;
                                                          int jlhBayar =
                                                              item['jumlah_bayar'] -
                                                              item['jumlah_kembalian'];

                                                          if (item['status'] ==
                                                                  "done-unpaid" ||
                                                              item['status'] ==
                                                                  "unpaid") {
                                                            teks =
                                                                "Belum Lunas: ${c.currencyFormatter.format(totalDanAddon - jlhBayar)}";
                                                          } else {
                                                            teks =
                                                                "Belum Lunas: ${c.currencyFormatter.format(totalAddOnAll)}";
                                                          }

                                                          return Text(
                                                            teks,
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Poppins',
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  Colors
                                                                      .red
                                                                      .shade700,
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
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Colors
                                                                .blue
                                                                .shade700,
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              }

                                              // Handle the case where there is no data
                                              return const Center(
                                                child: Text(
                                                  "No data available",
                                                ),
                                              );
                                            },
                                          ),
                                        ),
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
                                      ],
                                    ),

                                    SizedBox(height: 12),

                                    // Details section - left aligned
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        RichText(
                                          text: TextSpan(
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 14,
                                              color: Colors.grey.shade800,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: 'Disc: ',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              TextSpan(
                                                text:
                                                    '${(item['disc'] * 100).toInt()}%',
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          height: 16,
                                          width: 1,
                                          color: Colors.grey.shade400,
                                          margin: EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                        ),
                                        RichText(
                                          text: TextSpan(
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 14,
                                              color: Colors.grey.shade800,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: 'Jenis Transaksi: ',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              TextSpan(
                                                text: c.capitalize(
                                                  item['jenis_transaksi'],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          height: 16,
                                          width: 1,
                                          color: Colors.grey.shade400,
                                          margin: EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                        ),
                                        RichText(
                                          text: TextSpan(
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 14,
                                              color: Colors.grey.shade800,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: 'Kamar: ',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              TextSpan(
                                                text: item['nama_ruangan'],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          height: 16,
                                          width: 1,
                                          color: Colors.grey.shade400,
                                          margin: EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                        ),
                                        RichText(
                                          text: TextSpan(
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 14,
                                              color: Colors.grey.shade800,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: 'Jenis Tamu: ',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              TextSpan(
                                                text: item['jenis_tamu'],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          height: 16,
                                          width: 1,
                                          color: Colors.grey.shade400,
                                          margin: EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                        ),
                                        RichText(
                                          text: TextSpan(
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 14,
                                              color: Colors.grey.shade800,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: 'Status: ',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              TextSpan(
                                                text: c.capitalize(
                                                  item['status'] == 'unpaid' ||
                                                          item['status'] ==
                                                              "done-unpaid" ||
                                                          item['status'] ==
                                                              "done-unpaid-addon" ||
                                                          (item['total_addon'] !=
                                                                  0 &&
                                                              item['status'] ==
                                                                  "paid")
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

                                    Row(
                                      // mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Expanded(
                                          child: Builder(
                                            builder: (context) {
                                              var created_at =
                                                  item['created_at']
                                                      .toString()
                                                      .split("T");
                                              var tgl = created_at[0]
                                                  .toString()
                                                  .split("-");
                                              var jam = created_at[1];
                                              var tglIndo =
                                                  "${tgl[2]}-${tgl[1]}-${tgl[0]}";

                                              return Text(
                                                "Dibuat Pada: $tglIndo - $jam",
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        Expanded(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              IconButton(
                                                onPressed: () {
                                                  showCancelTransactionDialog(
                                                    context,
                                                    (password) {
                                                      // Do validation with the password
                                                      print(
                                                        "Password entered: $password",
                                                      );
                                                      // You can now validate password and cancel transaction here
                                                    },
                                                  );
                                                },
                                                icon: Icon(Icons.cancel),
                                              ),
                                              SizedBox(width: 10),
                                              ElevatedButton(
                                                onPressed: () {
                                                  log("isi item adalah $item");
                                                  c.dialogDetail(
                                                    item['id_transaksi'],
                                                    item['disc'],
                                                    item['jenis_pembayaran'],
                                                  );
                                                  // Add your button action here
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                    vertical: 12,
                                                  ),
                                                  backgroundColor:
                                                      Colors.blue.shade600,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                ),
                                                child: Text(
                                                  'Details',
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 10),

                                              ElevatedButton(
                                                onPressed: () {
                                                  Get.to(
                                                    () => Rating(
                                                      idTransaksi:
                                                          item['id_transaksi'],
                                                    ),
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                    vertical: 12,
                                                  ),
                                                  backgroundColor:
                                                      Colors.blue.shade600,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                ),
                                                child: Text(
                                                  'Rating',
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                              if ((item['total_addon'] != 0 &&
                                                      item['status'] ==
                                                          "paid") ||
                                                  item['status'] == 'unpaid' ||
                                                  item['status'] ==
                                                      'done-unpaid' ||
                                                  item['status'] ==
                                                      'done-unpaid-addon') ...[
                                                ElevatedButton(
                                                  onPressed: () {
                                                    // c.dialogDetail(
                                                    //     item['id_transaksi']);
                                                    // Add your button action here
                                                    log(
                                                      "Isi Item adalah $item",
                                                    );
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
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 24,
                                                          vertical: 12,
                                                        ),
                                                    backgroundColor:
                                                        Colors.blue.shade600,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Pelunasan',
                                                    style: TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontWeight:
                                                          FontWeight.w500,
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
                                                    log(
                                                      "Isi Item adalah $item",
                                                    );
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

                                                    var data = await c
                                                        .getDetailTrans(
                                                          item['id_transaksi'],
                                                        );

                                                    await c._processPrintViaLAN(
                                                      data,
                                                      item,
                                                    );
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 24,
                                                          vertical: 12,
                                                        ),
                                                    backgroundColor:
                                                        Colors.blue.shade600,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Cetak Struk',
                                                    style: TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
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
                width: Get.width - 180,
                child: Row(
                  children: [
                    // Label
                    const Expanded(
                      flex: 2, // Give more space to the label
                      child: Text(
                        "Omset Harian:",
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),

                    // Cash
                    Expanded(
                      child: Obx(
                        () => Text(
                          "Cash: ${c.currencyFormatter.format(c.omsetCash.value)}",
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),

                    // Debit
                    Expanded(
                      child: Obx(
                        () => Text(
                          "Debit: ${c.currencyFormatter.format(c.omsetDebit.value)}",
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),

                    // QRIS
                    Expanded(
                      child: Obx(
                        () => Text(
                          "QRIS: ${c.currencyFormatter.format(c.omsetQris.value)}",
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            color: Colors.purple[700],
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      drawer: OurDrawer(),
    );
  }
}

void showCancelTransactionDialog(
  BuildContext context,
  void Function(String) onConfirm,
) async {
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
                obscureText:
                    !isPasswordVisible.value, // Access value with .value
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: "Password",
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible.value
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
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
