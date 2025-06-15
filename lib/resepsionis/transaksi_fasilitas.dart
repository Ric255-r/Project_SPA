import 'dart:developer';

import 'package:Project_SPA/function/ip_address.dart';
import 'package:Project_SPA/function/token.dart';
import 'package:Project_SPA/resepsionis/daftar_member.dart';
import 'package:Project_SPA/resepsionis/main_resepsionis.dart';
import 'package:Project_SPA/resepsionis/scannerQR.dart';
import 'package:Project_SPA/resepsionis/store_locker.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'detail_food_n_beverages.dart';

const List<String> list = <String>['Umum', 'Member', 'VIP'];
String? dropdownjenistamu;
List<Map<String, dynamic>> _listNamaFasilitas = [];
String? dropdownNamaFasilitas;
List<String> _jenisPembayaran = ["awal", "akhir"];

class TransaksiFasilitas extends StatefulWidget {
  const TransaksiFasilitas({super.key});

  @override
  State<TransaksiFasilitas> createState() => _TransaksiFasilitasState();
}

class _TransaksiFasilitasState extends State<TransaksiFasilitas> {
  List<Map<String, dynamic>> _listHappyHour = [];
  String? dropdownHappyHour;
  var discSetelahPromo = 0;
  String selectedDisc = "";
  bool memberOrVip = false;

  var dio = Dio();
  var idTrans = "";
  LockerManager _lockerManager = LockerManager();
  TextEditingController _txtIdTrans = TextEditingController();
  TextEditingController _txtNoLocker = TextEditingController();
  TextEditingController _txtNamaTamu = TextEditingController();
  TextEditingController _txtNoHP = TextEditingController();
  TextEditingController _txtHargaFasilitas = TextEditingController();

  TextEditingController _dialogTxtTotalFormatted = TextEditingController();
  TextEditingController _totalBayarController = TextEditingController();
  TextEditingController _kembalianController = TextEditingController();
  var idFasilitas;
  int _dialogTxtTotalOri = 0;
  int _parsedTotalBayar = 0;
  int kembalian = 0;
  double? hrgStlhDisc;

  void _fnFormatTotalBayar(String value) {
    // Remove all non-digit characters
    String digits = value.replaceAll(RegExp(r'[^0-9]'), '');

    // Parse total bayar yang bentuk rupiah ke angka
    int numValue = int.tryParse(digits) ?? 0;
    _parsedTotalBayar = numValue;

    // Ambil Controller Yg Udh D Hitung
    String totalHrgFasilitas = _dialogTxtTotalFormatted.text;
    String withoutRp = totalHrgFasilitas.replaceAll("Rp ", "").replaceAll(".", ""); // "243.000"
    // End Ambil Controller

    int totalhargavalue = int.parse(withoutRp);
    _dialogTxtTotalOri = totalhargavalue;
    kembalian = numValue - _dialogTxtTotalOri.toInt();

    // Format kembali ke currency
    String formatted = currencyFormatter.format(numValue);
    String formattedKembali = currencyFormatter.format(kembalian);

    // Update controller tanpa trigger infinite loop
    _totalBayarController.value = TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
    _kembalianController.value = TextEditingValue(text: formattedKembali, selection: TextSelection.collapsed(offset: formattedKembali.length));
  }

  TextEditingController _namaAkun = TextEditingController();
  TextEditingController _noRek = TextEditingController();
  TextEditingController _namaBank = TextEditingController();

  Future<void> updatedataloker(statusloker, nomor_locker) async {
    try {
      var response = await dio.put('${myIpAddr()}/billinglocker/updatelocker', data: {"status": statusloker, "nomor_locker": nomor_locker});
    } catch (e) {
      log("Error di fn updatedataloker : $e");
    }
  }

  String varJenisPembayaran = _jenisPembayaran.first;
  Future<void> getDataFasilitas() async {
    try {
      var response = await dio.get('${myIpAddr()}/fasilitas/getfasilitas');
      setState(() {
        _listNamaFasilitas =
            (response.data as List).map((item) {
              return {"id_fasilitas": item["id_fasilitas"], "nama_fasilitas": item["nama_fasilitas"], "harga_fasilitas": item["harga_fasilitas"]};
            }).toList();
      });
    } catch (e) {
      log("Error di fn Get Data Terapis $e");
    }
  }

  Future<void> _createDraftLastTrans() async {
    try {
      var token = await getTokenSharedPref();
      print(token);

      // pake method post. jadi alurny post dlu id transaksi ke tabel, lalu update
      var response = await dio.post('${myIpAddr()}/id_trans/createDraft', options: Options(headers: {"Authorization": "Bearer " + token!}));

      var newId = response.data['id_transaksi'];
      log("New Transaction ID: $newId");

      setState(() {
        idTrans = newId;
        _txtIdTrans.text = idTrans;
        _txtNoLocker.text = _lockerManager.getLocker().toString();
      });
    } catch (e) {
      log("Error GetLastId $e");
    }
  }

  Future<void> _updateLastTrans() async {
    try {
      var token = await getTokenSharedPref();
      print(token);

      var response = await dio.put(
        '${myIpAddr()}/id_trans/updateDraft/${idTrans}',
        options: Options(headers: {"Authorization": "Bearer " + token!}),
        data: {"jenis_tamu": dropdownjenistamu, "no_loker": int.parse(_txtNoLocker.text), "mode": "for_fasilitas"},
      );

      log("Update Draft $response");
    } catch (e) {
      log("Error di Update Draft $e");
    }
  }

  Future<void> removeIdDraft() async {
    try {
      var token = await getTokenSharedPref();
      print(token);

      var response = await dio.delete('${myIpAddr()}/id_trans/deleteDraftId/${idTrans}', options: Options(headers: {"Authorization": "Bearer " + token!}));

      log("Delete Draft $response");
    } catch (e) {
      log("Error di Delete Draft $e");
    }
  }

  String? idMember;
  double harga = 0.0;

  void scanMember() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => QRScannerScreen(
              onScannedData: (nama, nohp, status, id_member) {
                setState(() {
                  idMember = id_member;
                  dropdownjenistamu = status;
                  _txtNamaTamu.text = nama;
                  _txtNoHP.text = nohp;
                });
              },
            ),
      ),
    );
  }

  Future<bool> checkPromoTahunan(String idMember) async {
    try {
      final response = await dio.get('${myIpAddr()}/transmember/checkpromo', queryParameters: {'id_member': idMember});
      if (response.statusCode == 200) {
        final data = response.data;
        return data['has_promo'] == true;
      }
    } catch (e) {
      print("Error checking promo: $e");
    }
    return false;
  }

  Future<void> getDataHappyHour() async {
    try {
      var response = await dio.get(
        '${myIpAddr()}/listpromo/getdatapromohappyhourdisc',
        queryParameters: {
          'statusTamu': dropdownjenistamu, // "Umum", "Member", or "VIP"
        },
      );

      setState(() {
        _listHappyHour =
            (response.data as List).map((item) {
              return {"kode_promo": item["kode_promo"], "nama_promo": item["nama_promo"], "disc": item["disc"]};
            }).toList();
      });
    } catch (e) {
      log("Error di fn Get Data Terapis $e");
    }
  }

  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  bool isCash = true;
  bool isDebit = false;
  bool isQris = false;
  double desimalPjk = 0;

  Future<void> _getPajak() async {
    try {
      var response = await dio.get('${myIpAddr()}/pajak/getpajak');

      // Parse the first record (assumes response is a list of maps)
      List<dynamic> data = response.data;
      if (data.isNotEmpty) {
        var firstRecord = data[0];
        double pjk = double.tryParse(firstRecord['pajak_msg'].toString()) ?? 0.0;

        desimalPjk = pjk;
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

  Future<void> _storeTrans() async {
    try {
      // var rincian = getHargaAfterDisc();
      var token = await getTokenSharedPref();
      var data = {
        "id_transaksi": _txtIdTrans.text,
        "id_fasilitas": idFasilitas,
        "harga": _dialogTxtTotalOri,
        if (idMember != null) "id_member": idMember,
        "nama_tamu": _txtNamaTamu.text,
        "no_hp": _txtNoHP.text,
      };

      double nominalDisc = hrgStlhDisc! * (discSetelahPromo / 100);
      double hrgSblmDisc = hrgStlhDisc! - nominalDisc;

      if (varJenisPembayaran == "awal") {
        // false = awal
        data['jenis_pembayaran'] = false;
        data['status'] = "paid";

        if (isCash) {
          data['metode_pembayaran'] = "cash";
          data['jumlah_bayar'] = _parsedTotalBayar;
          data['total_harga'] = hrgSblmDisc;
          data['grand_total'] = hrgStlhDisc!;
        } else {
          data['metode_pembayaran'] = isQris ? "qris" : "debit";
          data['total_harga'] = hrgSblmDisc;
          data['jumlah_bayar'] = hrgStlhDisc!;
          data['grand_total'] = hrgStlhDisc!;
          data['nama_akun'] = _namaAkun.text;
          data['no_rek'] = _noRek.text;
          data['nama_bank'] = _namaBank.text;
        }
      } else {
        data['jenis_pembayaran'] = true;
        data['status'] = "unpaid";
        data['total_harga'] = hrgSblmDisc;
        data['grand_total'] = hrgStlhDisc!;
      }

      var response = await dio.post('${myIpAddr()}/fasilitas/store', options: Options(headers: {"Authorization": "Bearer " + token!}), data: data);
      CherryToast.success(
        title: Text("Transaksi Sukses!", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
        animationDuration: const Duration(milliseconds: 2000),
        autoDismiss: true,
      ).show(context);
      log("Sukses SImpan $response");
    } catch (e) {
      CherryToast.error(
        title: Text("Transaksi Gagal!", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
        animationDuration: const Duration(milliseconds: 2000),
        autoDismiss: true,
      ).show(context);
      log("Error fn storeTrans $e");
    }
  }

  void _showDialogConfirmPayment(BuildContext context) async {
    await _getPajak();

    List<String> metodeByr = ["Cash", "Debit", "QRIS"];
    String dropdownValue = metodeByr.first;
    int statusloker = 0;
    final LockerManager LockerInput = LockerManager();
    int inputlocker = LockerInput.getLocker();
    bool totalbayarenabled = true;
    bool namaakunenabled = true;
    bool nomorrekeningenabled = true;
    bool namabankenabled = true;

    // Rumus Total
    double nominalDisc = harga.toInt() * (discSetelahPromo / 100);
    hrgStlhDisc = harga.toInt() - nominalDisc;

    double nominalPjk = hrgStlhDisc! * desimalPjk;
    double hrgPjkSblmRound = hrgStlhDisc! + nominalPjk;
    // Pembulatan Stlh Pjk
    int totalStlhRound = (hrgPjkSblmRound / 1000).round() * 1000;
    _dialogTxtTotalFormatted.text = currencyFormatter.format(totalStlhRound);
    // End Rumus Total

    showDialog(
      context: context,
      builder: (BuildContext context) {
        // pake statefulbuilder klo dlm dialog
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Pembayaran", textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Poppins')),
              content: SingleChildScrollView(
                child: Container(
                  width: Get.width,
                  height: Get.height - 300,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text("Disc: ", style: TextStyle(fontFamily: 'Poppins'))),
                          Expanded(flex: 3, child: Text("$selectedDisc %", style: TextStyle(fontFamily: 'Poppins'))),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          children: [
                            Expanded(child: Text("Total Harga: ", style: TextStyle(fontFamily: 'Poppins'))),
                            Expanded(flex: 3, child: TextField(controller: _dialogTxtTotalFormatted, readOnly: true)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(child: Text("Metode Pembayaran: ", style: TextStyle(fontFamily: 'Poppins'))),
                          Expanded(
                            flex: 3,
                            child: DropdownButton<String>(
                              value: dropdownValue,
                              elevation: 16,
                              style: const TextStyle(color: Colors.deepPurple),
                              onChanged: (String? value) {
                                // dipanggil kalo user select metode byr
                                setState(() {
                                  switch (value) {
                                    case "Cash":
                                      isCash = true;
                                      isDebit = false;
                                      isQris = false;
                                      break;
                                    case "Debit":
                                      isDebit = true;
                                      isCash = false;
                                      isQris = false;
                                      break;

                                    case "QRIS":
                                      isQris = true;
                                      isCash = false;
                                      isDebit = false;
                                      break;
                                  }
                                  _totalBayarController.clear();
                                  _kembalianController.clear();
                                  kembalian = 0;

                                  dropdownValue = value!;
                                });
                              },
                              icon: SizedBox.shrink(),
                              items:
                                  metodeByr.map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem(value: value, child: AutoSizeText(value, minFontSize: 20));
                                  }).toList(),
                            ),
                          ),
                        ],
                      ),
                      if (varJenisPembayaran == "awal")
                        if (isCash)
                          Column(
                            children: [
                              SizedBox(height: 30),
                              Row(children: [Text("Rincian Biaya", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'))]),
                              Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 20),
                                      child: Text("Total Bayar: ", style: TextStyle(fontFamily: 'Poppins')),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: TextField(
                                      controller: _totalBayarController,
                                      enabled: totalbayarenabled,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(hintText: "Rp. 0"),
                                      onChanged: (value) {
                                        _fnFormatTotalBayar(value);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 20),
                                      child: Text("Kembalian: ", style: TextStyle(fontFamily: 'Poppins')),
                                    ),
                                  ),
                                  Expanded(flex: 3, child: TextField(controller: _kembalianController, readOnly: true)),
                                ],
                              ),
                            ],
                          ),
                      if (varJenisPembayaran == "awal")
                        if (!isCash)
                          Column(
                            children: [
                              SizedBox(height: 30),
                              Row(children: [Text("Informasi Bank Pemilik", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'))]),
                              Row(
                                children: [
                                  Expanded(child: Text("Nama Akun: ", style: TextStyle(fontFamily: 'Poppins'))),
                                  Expanded(flex: 3, child: TextField(controller: _namaAkun, enabled: namaakunenabled)),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(child: Text("Nomor Rekening: ", style: TextStyle(fontFamily: 'Poppins'))),
                                  Expanded(flex: 3, child: TextField(controller: _noRek, enabled: nomorrekeningenabled)),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(child: Text("Nama Bank: ", style: TextStyle(fontFamily: 'Poppins'))),
                                  Expanded(flex: 3, child: TextField(controller: _namaBank, enabled: namabankenabled)),
                                ],
                              ),
                            ],
                          ),
                    ],
                  ),
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Jenis Pembayaran", style: TextStyle(fontFamily: 'Poppins')),
                            Container(
                              width: 200,
                              height: 40,
                              child: DropdownButton<String>(
                                value: varJenisPembayaran,
                                isExpanded: true,
                                elevation: 18,
                                style: const TextStyle(color: Colors.deepPurple),
                                onChanged: (String? value) {
                                  // dipanggil kalo user select item
                                  setState(() {
                                    varJenisPembayaran = value!;

                                    if (varJenisPembayaran == 'akhir') {
                                      totalbayarenabled = false;
                                      namaakunenabled = false;
                                      nomorrekeningenabled = false;
                                      namabankenabled = false;
                                    } else {
                                      totalbayarenabled = true;
                                      namaakunenabled = true;
                                      nomorrekeningenabled = true;
                                      namabankenabled = true;
                                    }
                                  });

                                  print("Jenis Pembayaran skrg $varJenisPembayaran");
                                },
                                icon: Icon(Icons.arrow_drop_down_circle),
                                items:
                                    _jenisPembayaran.map<DropdownMenuItem<String>>((String value) {
                                      return DropdownMenuItem(
                                        value: value,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: AutoSizeText("Pembayaran di" + value, minFontSize: 15, style: TextStyle(fontFamily: 'Poppins')),
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (varJenisPembayaran == "awal")
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () {
                              if (kembalian < 0) {
                                CherryToast.error(
                                  title: Text("Jumlah Bayar Kurang", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                                  animationDuration: const Duration(milliseconds: 1500),
                                  autoDismiss: true,
                                ).show(context);
                              } else {
                                _storeTrans().then((_) {
                                  statusloker = statusloker == 0 ? 1 : 0;
                                  updatedataloker(statusloker, inputlocker);
                                  Get.offAll(() => MainResepsionis());
                                });
                              }
                            },
                            child: Text("Konfirmasi Pembayaran", style: TextStyle(fontFamily: 'Poppins')),
                          ),
                        ),
                      ),
                    if (varJenisPembayaran == "akhir")
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () {
                              _storeTrans().then((_) {
                                statusloker = statusloker == 0 ? 1 : 0;
                                updatedataloker(statusloker, inputlocker);
                                Get.offAll(() => MainResepsionis());
                              });
                            },
                            child: Text("Simpan Transaksi", style: TextStyle(fontFamily: 'Poppins')),
                          ),
                        ),
                      ),
                    // TextButton(
                    //   onPressed: () {
                    //     if (kembalian < 0) {
                    //       CherryToast.error(
                    //         title: Text(
                    //           "Jumlah Bayar Kurang",
                    //           style: TextStyle(
                    //             color: Colors.black,
                    //             fontWeight: FontWeight.bold,
                    //             fontFamily: 'Poppins',
                    //           ),
                    //         ),
                    //         animationDuration: const Duration(
                    //           milliseconds: 1500,
                    //         ),
                    //         autoDismiss: true,
                    //       ).show(context);
                    //     } else {
                    //       _storeTrans().then((_) {
                    //         statusloker = statusloker == 0 ? 1 : 0;
                    //         updatedataloker(statusloker, inputlocker);
                    //         Get.offAll(() => MainResepsionis());
                    //       });
                    //     }
                    //   },
                    //   child: Text(
                    //     "Proses Pembayaran",
                    //     style: TextStyle(fontFamily: 'Poppins'),
                    //   ),
                    // ),
                  ],
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      setState(() {
        // Panggil Fungsi disini
        isCash = true;
        isDebit = false;
        isQris = false;
        _totalBayarController.clear();
        _kembalianController.clear();
      });
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    dropdownNamaFasilitas = null;
    dropdownjenistamu = null;
    dropdownHappyHour = null;
    _txtHargaFasilitas.dispose();
    _txtIdTrans.dispose();
    _txtNoLocker.dispose();
    _txtNamaTamu.dispose();
    _txtNoHP.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState

    _createDraftLastTrans();
    getDataFasilitas();
    getDataHappyHour();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await removeIdDraft();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: IconButton(
              icon: Icon(Icons.arrow_back, size: 40), // Back Icon
              onPressed: () async {
                await removeIdDraft();
                Get.back(); // Navigate back
              },
            ),
          ),
          title: Text('Transaksi Fasilitas', style: TextStyle(fontSize: 60, fontFamily: 'Poppins')),
          centerTitle: true,
          leadingWidth: 100,
          toolbarHeight: 100,
          backgroundColor: Color(0XFFFFE0B2),
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
            width: Get.width,
            height: Get.height - 125,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 600,
                  height: 600,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 435,
                            width: 200,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(top: 10),
                                  child: Text('No Transaksi : ', style: TextStyle(fontSize: 22, fontFamily: 'Poppins')),
                                ),

                                Padding(padding: EdgeInsets.only(top: 25), child: Text('No Locker : ', style: TextStyle(fontSize: 22, fontFamily: 'Poppins'))),

                                Padding(padding: EdgeInsets.only(top: 25), child: Text('Jenis Tamu : ', style: TextStyle(fontSize: 22, fontFamily: 'Poppins'))),
                                Padding(padding: EdgeInsets.only(top: 25), child: Text('Nama Tamu : ', style: TextStyle(fontSize: 22, fontFamily: 'Poppins'))),
                                Padding(padding: EdgeInsets.only(top: 25), child: Text('No HP : ', style: TextStyle(fontSize: 22, fontFamily: 'Poppins'))),
                                Padding(
                                  padding: EdgeInsets.only(top: 25),
                                  child: Text('Nama Fasilitas : ', style: TextStyle(fontSize: 22, fontFamily: 'Poppins')),
                                ),
                                Padding(padding: EdgeInsets.only(top: 25), child: Text('Harga : ', style: TextStyle(fontSize: 22, fontFamily: 'Poppins'))),
                                Padding(padding: EdgeInsets.only(top: 25), child: Text('Promo : ', style: TextStyle(fontSize: 22, fontFamily: 'Poppins'))),
                              ],
                            ),
                          ),
                          Container(
                            height: 456,
                            width: 370,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(left: 10, top: 7),
                                  child: Container(
                                    width: 350,
                                    height: 50,
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white),
                                    child: TextField(
                                      readOnly: true,
                                      controller: _txtIdTrans,
                                      decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10)),
                                      style: TextStyle(fontSize: 22),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(left: 10, top: 7),
                                  child: Container(
                                    width: 350,
                                    height: 50,
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white),
                                    child: TextField(
                                      controller: _txtNoLocker,
                                      decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10)),
                                      style: TextStyle(fontSize: 22),
                                    ),
                                  ),
                                ),

                                Padding(
                                  padding: EdgeInsets.only(left: 10, top: 7),
                                  child: Container(
                                    width: 350,
                                    height: 50,
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white),
                                    child: DropdownButton<String>(
                                      value: dropdownjenistamu,
                                      icon: const Icon(Icons.arrow_drop_down),
                                      isExpanded: true,
                                      elevation: 16,
                                      style: const TextStyle(color: Colors.deepPurple),
                                      underline: SizedBox(),
                                      padding: EdgeInsets.symmetric(horizontal: 10),
                                      onChanged: (String? value) {
                                        setState(() {
                                          dropdownjenistamu = value;
                                        });
                                      },
                                      items:
                                          list.map<DropdownMenuItem<String>>((String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Align(alignment: Alignment.centerLeft, child: Text(value, style: TextStyle(fontSize: 22))),
                                            );
                                          }).toList(),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(left: 10, top: 7),
                                  child: Container(
                                    width: 350,
                                    height: 50,
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white),
                                    child: TextField(
                                      maxLines: 1,
                                      controller: _txtNamaTamu,
                                      readOnly: true,
                                      keyboardType: TextInputType.text,
                                      textInputAction: TextInputAction.done,
                                      textAlign: TextAlign.start,
                                      scrollPhysics: BouncingScrollPhysics(),
                                      decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.only(left: 10, bottom: 7)),
                                      style: TextStyle(fontSize: 22, fontFamily: 'Poppins'),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(left: 10, top: 7),
                                  child: Container(
                                    width: 350,
                                    height: 50,
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white),
                                    child: TextField(
                                      controller: _txtNoHP,
                                      readOnly: true,
                                      decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10)),
                                      style: TextStyle(fontSize: 22, fontFamily: 'Poppins'),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(left: 10, top: 7),
                                  child: Container(
                                    width: 350,
                                    height: 50,
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white),
                                    child: DropdownButton<String>(
                                      value: dropdownNamaFasilitas,
                                      isExpanded: true,
                                      icon: const Icon(Icons.arrow_drop_down),
                                      elevation: 16,
                                      style: const TextStyle(color: Colors.deepPurple),
                                      underline: SizedBox(),
                                      padding: EdgeInsets.symmetric(horizontal: 10),
                                      onChanged: (String? value) async {
                                        var selectedFasilitas = _listNamaFasilitas.firstWhere(
                                          (item) => item['nama_fasilitas'] == value,
                                          orElse: () => {"id_fasilitas": "", "nama_fasilitas": "", "harga_fasilitas": 0},
                                        );

                                        if (idMember != null) {
                                          final hasTahunanPromo = await checkPromoTahunan(idMember!);

                                          setState(() {
                                            dropdownNamaFasilitas = value;
                                            harga = hasTahunanPromo ? 0 : selectedFasilitas['harga_fasilitas'].toDouble();
                                            idFasilitas = selectedFasilitas['id_fasilitas'];
                                            _txtHargaFasilitas.text = currencyFormatter.format(harga);
                                          });
                                        } else {
                                          setState(() {
                                            dropdownNamaFasilitas = value;
                                            harga = selectedFasilitas['harga_fasilitas'].toDouble();
                                            idFasilitas = selectedFasilitas['id_fasilitas'];
                                            _txtHargaFasilitas.text = currencyFormatter.format(harga);
                                          });
                                        }
                                      },
                                      items:
                                          _listNamaFasilitas.map<DropdownMenuItem<String>>((item) {
                                            return DropdownMenuItem<String>(
                                              value: item['nama_fasilitas'], // Use ID as value
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  item['nama_fasilitas'].toString(), // Display category name
                                                  style: const TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(left: 10, top: 7),
                                  child: Container(
                                    width: 350,
                                    height: 50,
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white),
                                    child: TextField(
                                      controller: _txtHargaFasilitas,
                                      decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10)),
                                      style: TextStyle(fontSize: 22),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(left: 10, top: 7),
                                  child: Container(
                                    width: 350,
                                    height: 50,
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white),
                                    child: DropdownButton<String>(
                                      value: dropdownHappyHour,
                                      icon: const Icon(Icons.arrow_drop_down),
                                      isExpanded: true,
                                      elevation: 16,
                                      style: const TextStyle(color: Colors.deepPurple),
                                      underline: SizedBox(),
                                      padding: EdgeInsets.symmetric(horizontal: 10),
                                      onChanged: (String? value) async {
                                        var selectedPromo = _listHappyHour.firstWhere(
                                          (item) => item['nama_promo'] == value,
                                          orElse: () => {"kode_promo": "", "nama_promo": "", "disc": 0},
                                        );
                                        setState(() {
                                          dropdownHappyHour = value;
                                          discSetelahPromo = selectedPromo['disc'];
                                          selectedDisc = discSetelahPromo.toString();
                                        });
                                      },
                                      items:
                                          _listHappyHour.map<DropdownMenuItem<String>>((item) {
                                            return DropdownMenuItem<String>(
                                              value: item['nama_promo'], // Use ID as value
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  item['nama_promo'].toString(), // Display category name
                                                  style: const TextStyle(fontSize: 16, fontFamily: 'Poppins'),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: Color(0XFFF6F7C4)),
                            height: 80,
                            width: 280,
                            child: TextButton(
                              onPressed: () {
                                _updateLastTrans();
                                _showDialogConfirmPayment(context);
                              },
                              style: TextButton.styleFrom(foregroundColor: Colors.black),
                              child: Text('Bayar', style: TextStyle(fontSize: 30, fontFamily: 'Poppins')),
                            ),
                          ),
                          SizedBox(width: 30),
                          Container(
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: Color(0XCCCDFADB)),
                            height: 80,
                            width: 280,
                            child: TextButton(
                              onPressed: scanMember,
                              style: TextButton.styleFrom(foregroundColor: Colors.black),
                              child: Text('SCAN QR', style: TextStyle(fontSize: 30, fontFamily: 'Poppins')),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
