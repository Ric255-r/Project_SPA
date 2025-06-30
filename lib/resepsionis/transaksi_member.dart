import 'dart:developer';

import 'package:Project_SPA/function/ip_address.dart';
import 'package:Project_SPA/function/token.dart';
import 'package:Project_SPA/resepsionis/daftar_member.dart';
import 'package:Project_SPA/resepsionis/main_resepsionis.dart';
import 'package:Project_SPA/resepsionis/scannerQR.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'detail_food_n_beverages.dart';

List<String> _jenisPembayaran = ["awal", "akhir"];

class TransaksiMember extends StatefulWidget {
  const TransaksiMember({super.key});

  @override
  State<TransaksiMember> createState() => _TransaksiMemberState();
}

class _TransaksiMemberState extends State<TransaksiMember> {
  bool memberOrVip = false;

  var dio = Dio();
  var idTrans = "";
  TextEditingController _txtIdTrans = TextEditingController();
  TextEditingController _txtNamaPaket = TextEditingController();
  TextEditingController _txtHargaPaketKunjungan = TextEditingController();
  TextEditingController _txtHargaPaketTahunan = TextEditingController();
  TextEditingController _txtJenisTamu = TextEditingController();
  TextEditingController _txtNamaTamu = TextEditingController();
  TextEditingController _txtLimitKunjungan = TextEditingController();
  TextEditingController _txtNoHP = TextEditingController();
  TextEditingController _txtTotalHarga = TextEditingController();

  TextEditingController _dialogTxtTotalFormatted = TextEditingController();
  TextEditingController _totalBayarController = TextEditingController();
  TextEditingController _kembalianController = TextEditingController();
  String idMember = "";

  List<Map<String, dynamic>> _listNamaPaket = [];
  String? dropdownNamaPaket;
  List<Map<String, dynamic>> _listNamaTahunan = [];
  String? dropdownNamaPaketTahunan;
  List<String> _listJenisTrans = <String>['Massage', 'Fasilitas'];
  String? dropdownJenisTrans;
  var kodePromo;
  var limitKunjungan;
  var limitPromo;
  var tahunKeHariLimitPromoKunjungan;
  var jangkaTahun;
  var tahunKeHariJangkaTahun;
  var totalHarga;

  int _dialogTxtTotalOri = 0;
  int _parsedTotalBayar = 0;
  int kembalian = 0;
  void _fnFormatTotalBayar(String value) {
    // Remove all non-digit characters
    String digits = value.replaceAll(RegExp(r'[^0-9]'), '');

    // Parse total bayar yang bentuk rupiah ke angka
    int numValue = int.tryParse(digits) ?? 0;
    _parsedTotalBayar = numValue;

    String totalhargavalue = totalHarga.replaceAll("Rp ", "").replaceAll('.', '');
    _dialogTxtTotalOri = int.parse(totalhargavalue);
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

  String varJenisPembayaran = "awal";
  Future<void> getDataPromoKunjungan() async {
    try {
      var response = await dio.get('${myIpAddr()}/transmember/getpaket');
      setState(() {
        _listNamaPaket =
            (response.data as List).map((item) {
              return {
                "kode_promo": item["kode_promo"],
                "nama_promo": item["nama_promo"],
                "harga_promo": item["harga_promo"],
                "limit_kunjungan": item["limit_kunjungan"],
                "limit_promo": item['limit_promo'],
              };
            }).toList();
        log(_listNamaPaket.toString());
      });
    } catch (e) {
      log("Error di fn Get Data Promo Kunjungan $e");
    }
  }

  Future<void> getDataPromoTahunan() async {
    try {
      var response = await dio.get('${myIpAddr()}/transmember/gettahunan');
      setState(() {
        _listNamaTahunan =
            (response.data as List).map((item) {
              return {
                "kode_promo": item["kode_promo"],
                "nama_promo": item["nama_promo"],
                "harga_promo": item["harga_promo"],
                "jangka_tahun": item["jangka_tahun"],
              };
            }).toList();
      });
    } catch (e) {
      log("Error di fn Get Data Promo Tahunan $e");
    }
  }

  void _updateFields(String nama, String noHp, String status, String id_member) {
    setState(() {
      _txtNamaTamu.text = nama;
      _txtNoHP.text = noHp;
      _txtJenisTamu.text = status;
      idMember = id_member;
    });
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
        data: {"jenis_tamu": _txtJenisTamu.text, "mode": "for_member"},
      );

      log("Update Draft $response");
    } catch (e) {
      log("Error di Update Draft $e");
    }
  }

  Future<bool> removeIdDraft() async {
    try {
      var token = await getTokenSharedPref();
      print(token);

      var response = await dio.delete('${myIpAddr()}/id_trans/deleteDraftId/${idTrans}', options: Options(headers: {"Authorization": "Bearer " + token!}));

      if (response.statusCode == 200) {
        log("Delete Draft $response");
        return true;
      }

      return false;
    } catch (e) {
      log("Error di Delete Draft $e");
      return false;
    }
  }

  String? _selectedBank;
  final List<String> _bankList = ['BCA', 'BNI', 'BRI', 'Mandiri'];

  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  bool isCash = true;
  bool isDebit = false;
  bool isQris = false;
  bool isKredit = false;

  void _showDialogConfirmPayment(BuildContext context) {
    String totalhargavalue = totalHarga.replaceAll("Rp ", "").replaceAll('.', '');
    List<String> metodeByr = ["cash", "debit", "kredit", "qris"];
    String dropdownValue = metodeByr.first;
    bool totalbayarenabled = true;
    bool namaakunenabled = true;
    bool nomorrekeningenabled = true;
    bool namabankenabled = true;

    Future<void> _storeTransKunjungan() async {
      try {
        var token = await getTokenSharedPref();
        var data = {
          "id_member": idMember,
          "id_transaksi": _txtIdTrans.text,
          "kode_promo": kodePromo,
          "harga": int.parse(totalhargavalue),
          "no_hp": int.parse(_txtNoHP.text),
          "nama_tamu": _txtNamaTamu.text,
          "limit_kunjungan": limitKunjungan,
          "exp_kunjungan": DateTime.now().add(Duration(days: tahunKeHariLimitPromoKunjungan)).toIso8601String(),
        };

        // Always payment now ("awal")
        if (isCash) {
          data['metode_pembayaran'] = "cash";
          data['jumlah_bayar'] = _parsedTotalBayar;
        } else {
          if (isQris) {
            data['metode_pembayaran'] = "qris";
          } else if (isKredit) {
            data['metode_pembayaran'] = "kredit";
          } else {
            data['metode_pembayaran'] = "debit";
          }
          data['jumlah_bayar'] = int.parse(totalhargavalue);
          data['nama_akun'] = _namaAkun.text;
          data['no_rek'] = _noRek.text;
          data['nama_bank'] = _selectedBank;
        }

        data['total_harga'] = int.parse(totalhargavalue);
        data['grand_total'] = int.parse(totalhargavalue);

        var response = await dio.post('${myIpAddr()}/transmember/storekunjungan', options: Options(headers: {"Authorization": "Bearer $token"}), data: data);

        log("Payment successful: ${response.data}");
        log(idMember);
        // Show success message
        CherryToast.success(
          title: Text("Transaksi Sukses!", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
        ).show(context);

        // Navigate back after successful payment
        Get.offAll(() => MainResepsionis());
      } on DioError catch (e) {
        log("Payment failed: ${e.response?.data}");
        log(_namaAkun.text);
        CherryToast.error(
          title: Text("Transaksi Gagal!", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
          description: Text(e.response?.data['message'] ?? "Please try again"),
        ).show(context);
      } catch (e) {
        log("Unexpected error: $e");
        CherryToast.error(
          title: Text("Error", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
          description: Text("An unexpected error occurred"),
        ).show(context);
      }
    }

    Future<void> _storeTransTahunan() async {
      try {
        var token = await getTokenSharedPref();
        var data = {
          "id_member": idMember,
          "id_transaksi": _txtIdTrans.text,
          "kode_promo": kodePromo,
          "harga": int.parse(totalhargavalue),
          "no_hp": _txtNoHP.text,
          "nama_tamu": _txtNamaTamu.text,
          "exp_tahunan": DateTime.now().add(Duration(days: tahunKeHariJangkaTahun)).toIso8601String(),
        };

        // Always payment now ("awal")
        if (isCash) {
          data['metode_pembayaran'] = "cash";
          data['jumlah_bayar'] = _parsedTotalBayar;
        } else {
          if (isQris) {
            data['metode_pembayaran'] = "qris";
          } else if (isKredit) {
            data['metode_pembayaran'] = "kredit";
          } else {
            data['metode_pembayaran'] = "debit";
          }
          data['jumlah_bayar'] = int.parse(totalhargavalue);
          data['nama_akun'] = _namaAkun.text;
          data['no_rek'] = _noRek.text;
          data['nama_bank'] = _selectedBank;
        }

        data['total_harga'] = int.parse(totalhargavalue);
        data['grand_total'] = int.parse(totalhargavalue);

        var response = await dio.post('${myIpAddr()}/transmember/storetahunan', options: Options(headers: {"Authorization": "Bearer $token"}), data: data);

        log("Payment successful: ${response.data}");
        log(idMember);
        // Show success message
        CherryToast.success(
          title: Text("Payment Successful", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
        ).show(context);

        // Navigate back after successful payment
        Get.offAll(() => MainResepsionis());
      } on DioError catch (e) {
        log("Payment failed: ${e.response?.data}");
        CherryToast.error(
          title: Text("Payment Failed", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
          description: Text(e.response?.data['message'] ?? "Please try again"),
        ).show(context);
      } catch (e) {
        log("Unexpected error: $e");
        CherryToast.error(
          title: Text("Error", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
          description: Text("An unexpected error occurred"),
        ).show(context);
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        // pake statefulbuilder klo dlm dialog
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Pembayaran", textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Poppins')),
              content: MediaQuery.removeViewInsets(
                context: context,
                removeBottom: false,
                child: SingleChildScrollView(
                  child: Container(
                    width: MediaQuery.of(context).size.width,

                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Padding(padding: const EdgeInsets.only(top: 20), child: Text("Total Harga: ", style: TextStyle(fontFamily: 'Poppins'))),
                            ),
                            Expanded(flex: 3, child: TextField(controller: _txtTotalHarga, readOnly: true)),
                          ],
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
                                      case "cash":
                                        isCash = true;
                                        isDebit = false;
                                        isQris = false;
                                        isKredit = false;
                                        break;
                                      case "debit":
                                        isDebit = true;
                                        isCash = false;
                                        isQris = false;
                                        isKredit = false;
                                        break;

                                      case "qris":
                                        isQris = true;
                                        isCash = false;
                                        isDebit = false;
                                        isKredit = false;
                                        break;

                                      case "kredit":
                                        isQris = false;
                                        isCash = false;
                                        isDebit = false;
                                        isKredit = true;
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
                                    Expanded(
                                      flex: 3,
                                      child: DropdownButtonFormField<String>(
                                        value: _selectedBank,
                                        onChanged: (String? Value) {
                                          setState(() {
                                            _selectedBank = Value!;
                                          });
                                        },
                                        items:
                                            _bankList.map((String bank) {
                                              return DropdownMenuItem<String>(value: bank, child: Text(bank));
                                            }).toList(),
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
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
                          if (dropdownJenisTrans == "Massage") {
                            _storeTransKunjungan().then((_) {
                              Get.offAll(() => MainResepsionis());
                            });
                          } else if (dropdownJenisTrans == "Fasilitas") {
                            _storeTransTahunan().then((_) {
                              Get.offAll(() => MainResepsionis());
                            });
                          } else {
                            CherryToast.error(
                              title: Text(
                                "Pilih Jenis Transaksi Terlebih Dahulu",
                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                              ),
                              animationDuration: const Duration(milliseconds: 1500),
                              autoDismiss: true,
                            ).show(context);
                          }
                        }
                      },
                      child: Text("Konfirmasi Pembayaran", style: TextStyle(fontFamily: 'Poppins')),
                    ),
                  ),
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
        isKredit = false;
        _totalBayarController.clear();
        _kembalianController.clear();
      });
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    dropdownNamaPaket = null;
    _txtHargaPaketKunjungan.dispose();
    _txtIdTrans.dispose();
    _txtLimitKunjungan.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    getDataPromoKunjungan();
    _createDraftLastTrans();
    getDataPromoTahunan();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool isDeleted = await removeIdDraft();
        return isDeleted;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Transaksi Member', style: TextStyle(fontSize: 60, fontFamily: 'Poppins')),
          leading: Padding(
            padding: const EdgeInsets.only(left: 30),
            child: IconButton(
              icon: Icon(Icons.arrow_back, size: 40), // Back Icon
              onPressed: () async {
                bool isDeleted = await removeIdDraft();
                if (isDeleted) Get.back(); // Navigate back
              },
            ),
          ),
          leadingWidth: 100,
          centerTitle: true,
          toolbarHeight: 130,
          backgroundColor: Color(0XFFFFE0B2),
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
            width: Get.width,
            height: Get.height - 155,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 600,
                  height: 600,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 380,
                            width: 200,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(top: 10),
                                  child: Text('No Transaksi : ', style: TextStyle(fontSize: 22, fontFamily: 'Poppins')),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(top: 25),
                                  child: Text('Jenis Transaksi : ', style: TextStyle(fontSize: 22, fontFamily: 'Poppins')),
                                ),
                                Padding(padding: EdgeInsets.only(top: 25), child: Text('Jenis Tamu : ', style: TextStyle(fontSize: 22, fontFamily: 'Poppins'))),
                                Padding(padding: EdgeInsets.only(top: 25), child: Text('Nama Tamu : ', style: TextStyle(fontSize: 22, fontFamily: 'Poppins'))),
                                Padding(padding: EdgeInsets.only(top: 25), child: Text('No HP : ', style: TextStyle(fontSize: 22, fontFamily: 'Poppins'))),
                                Padding(padding: EdgeInsets.only(top: 25), child: Text('Nama Paket : ', style: TextStyle(fontSize: 22, fontFamily: 'Poppins'))),
                                Padding(padding: EdgeInsets.only(top: 25), child: Text('Harga : ', style: TextStyle(fontSize: 22, fontFamily: 'Poppins'))),
                              ],
                            ),
                          ),
                          SizedBox(width: 20),
                          Container(
                            height: 400,
                            width: 370,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(left: 10, top: 7),
                                  child: Container(
                                    width: 350,
                                    height: 50,
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white),
                                    child: TextField(
                                      controller: _txtIdTrans,
                                      readOnly: true,
                                      decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10)),
                                      style: TextStyle(fontSize: 22, fontFamily: 'Poppins'),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 10, top: 7),
                                  child: Container(
                                    alignment: Alignment.centerLeft,
                                    width: 350,
                                    height: 50,
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white),
                                    child: DropdownButton<String>(
                                      value: dropdownJenisTrans,
                                      isExpanded: true,
                                      icon: const Icon(Icons.arrow_drop_down),
                                      elevation: 16,
                                      style: const TextStyle(color: Colors.deepPurple),
                                      underline: SizedBox(),
                                      padding: EdgeInsets.symmetric(horizontal: 10),
                                      onChanged: (String? value) {
                                        setState(() {
                                          dropdownJenisTrans = value;
                                        });
                                      },
                                      items:
                                          _listJenisTrans.map<DropdownMenuItem<String>>((String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(value, style: TextStyle(fontSize: 18, fontFamily: 'Poppins')),
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
                                      controller: _txtJenisTamu,
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
                                if (dropdownJenisTrans == null)
                                  Padding(
                                    padding: EdgeInsets.only(left: 10, top: 7),
                                    child: Container(
                                      width: 350,
                                      height: 50,
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white),
                                      child: TextField(
                                        readOnly: true,
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                                        ),
                                        style: TextStyle(fontSize: 22, fontFamily: 'Poppins'),
                                      ),
                                    ),
                                  ),
                                if (dropdownJenisTrans == "Massage")
                                  Padding(
                                    padding: EdgeInsets.only(left: 10, top: 7),
                                    child: Container(
                                      width: 350,
                                      height: 50,
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white),
                                      child: DropdownButton<String>(
                                        value: dropdownNamaPaket,
                                        isExpanded: true,
                                        icon: const Icon(Icons.arrow_drop_down),
                                        elevation: 16,
                                        style: const TextStyle(color: Colors.deepPurple),
                                        underline: SizedBox(),
                                        padding: EdgeInsets.symmetric(horizontal: 10),
                                        onChanged: (String? value) {
                                          setState(() {
                                            dropdownNamaPaket = value;
                                            // Find the corresponding id_karyawan
                                            var selectedPaket = _listNamaPaket.firstWhere(
                                              (item) => item['nama_promo'] == value,
                                              orElse: () => {"nama_promo": "", "harga_promo": 0},
                                            );
                                            _txtHargaPaketKunjungan.text = currencyFormatter.format(selectedPaket['harga_promo']);
                                            totalHarga = _txtHargaPaketKunjungan.text;
                                            _txtTotalHarga.text = currencyFormatter.format(selectedPaket['harga_promo']);
                                            kodePromo = selectedPaket['kode_promo'];
                                            limitKunjungan = selectedPaket['limit_kunjungan'];
                                            limitPromo = selectedPaket['limit_promo'];
                                            tahunKeHariLimitPromoKunjungan = limitPromo * 365;
                                          });
                                        },
                                        items:
                                            _listNamaPaket.map<DropdownMenuItem<String>>((item) {
                                              return DropdownMenuItem<String>(
                                                value: item['nama_promo'], // Use ID as value
                                                child: Align(
                                                  alignment: Alignment.centerLeft,
                                                  child: Text(
                                                    item['nama_promo'].toString(), // Display category name
                                                    style: const TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                      ),
                                    ),
                                  ),
                                if (dropdownJenisTrans == "Fasilitas")
                                  Padding(
                                    padding: EdgeInsets.only(left: 10, top: 7),
                                    child: Container(
                                      width: 350,
                                      height: 50,
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white),
                                      child: DropdownButton<String>(
                                        value: dropdownNamaPaketTahunan,
                                        isExpanded: true,
                                        icon: const Icon(Icons.arrow_drop_down),
                                        elevation: 16,
                                        style: const TextStyle(color: Colors.deepPurple),
                                        underline: SizedBox(),
                                        padding: EdgeInsets.symmetric(horizontal: 10),
                                        onChanged: (String? value) {
                                          setState(() {
                                            dropdownNamaPaketTahunan = value;
                                            // Find the corresponding id_karyawan
                                            var selectedTahunan = _listNamaTahunan.firstWhere(
                                              (item) => item['nama_promo'] == value,
                                              orElse: () => {"nama_promo": "", "harga_promo": 0},
                                            );
                                            _txtHargaPaketTahunan.text = currencyFormatter.format(selectedTahunan['harga_promo']);
                                            totalHarga = _txtHargaPaketTahunan.text;
                                            _txtTotalHarga.text = currencyFormatter.format(selectedTahunan['harga_promo']);
                                            kodePromo = selectedTahunan['kode_promo'];
                                            jangkaTahun = selectedTahunan['jangka_tahun'];
                                            tahunKeHariJangkaTahun = jangkaTahun * 365;
                                          });
                                        },
                                        items:
                                            _listNamaTahunan.map<DropdownMenuItem<String>>((item) {
                                              return DropdownMenuItem<String>(
                                                value: item['nama_promo'], // Use ID as value
                                                child: Align(
                                                  alignment: Alignment.centerLeft,
                                                  child: Text(
                                                    item['nama_promo'].toString(), // Display category name
                                                    style: const TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                      ),
                                    ),
                                  ),
                                if (dropdownJenisTrans == null)
                                  Padding(
                                    padding: EdgeInsets.only(left: 10, top: 7),
                                    child: Container(
                                      width: 350,
                                      height: 50,
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white),
                                      child: TextField(
                                        readOnly: true,
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                                        ),
                                        style: TextStyle(fontSize: 22, fontFamily: 'Poppins'),
                                      ),
                                    ),
                                  ),
                                if (dropdownJenisTrans == "Massage")
                                  Padding(
                                    padding: EdgeInsets.only(left: 10, top: 7),
                                    child: Container(
                                      width: 350,
                                      height: 50,
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white),
                                      child: TextField(
                                        readOnly: true,
                                        controller: _txtHargaPaketKunjungan,
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                                        ),
                                        style: TextStyle(fontSize: 22, fontFamily: 'Poppins'),
                                      ),
                                    ),
                                  ),
                                if (dropdownJenisTrans == "Fasilitas")
                                  Padding(
                                    padding: EdgeInsets.only(left: 10, top: 7),
                                    child: Container(
                                      width: 350,
                                      height: 50,
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white),
                                      child: TextField(
                                        readOnly: true,
                                        controller: _txtHargaPaketTahunan,
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                                        ),
                                        style: TextStyle(fontSize: 22, fontFamily: 'Poppins'),
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
                                if (_txtIdTrans.text.isEmpty ||
                                    dropdownJenisTrans == null ||
                                    _txtJenisTamu.text.isEmpty ||
                                    _txtNamaTamu.text.isEmpty ||
                                    _txtNoHP.text.isEmpty ||
                                    (dropdownJenisTrans == "Massage" && dropdownNamaPaket == null) ||
                                    (dropdownJenisTrans == "Fasilitas" && dropdownNamaPaketTahunan == null)) {
                                  CherryToast.warning(
                                    title: Text(
                                      "Harap Mengisi Semua Kolom",
                                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                                    ),
                                    animationDuration: Duration(milliseconds: 1500),
                                    autoDismiss: true,
                                  ).show(context);
                                } else {
                                  _updateLastTrans();
                                  _showDialogConfirmPayment(context);
                                }
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
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => QRScannerScreen(onScannedData: _updateFields)));
                              },
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
