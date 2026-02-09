// ignore_for_file: prefer_final_fields, use_super_parameters

import 'dart:async';
import 'dart:developer';

import 'package:Project_SPA/resepsionis/store_locker.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:Project_SPA/function/ip_address.dart';
import 'package:Project_SPA/function/token.dart';
import 'package:Project_SPA/resepsionis/main_resepsionis.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:just_audio/just_audio.dart';
import 'transaksi_massage.dart';
import 'package:Project_SPA/ruang_tunggu/main_rt.dart';

// class DetailPaketMassage extends StatelessWidget {
//   const DetailPaketMassage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(body: StfulPaketMassage());
//   }
// }

// Parent Widget. nama awalnya StfulPaketMassage
class DetailPaketMassage extends StatefulWidget {
  final String idTrans;
  final List<Map<String, dynamic>> activePromos;
  final String? idMember; // nullable param
  final String namaRoom;
  final String? statusTamu;

  DetailPaketMassage({
    Key? key,
    required this.idTrans,
    this.activePromos = const [],
    this.idMember,
    required this.namaRoom,
    required this.statusTamu,
  }) : super(key: key) {
    if (!Get.isRegistered<ControllerPekerja>()) {
      Get.lazyPut(() => ControllerPekerja(), fenix: false);
    }
  }

  @override
  State<DetailPaketMassage> createState() => _DetailPaketMassageState();
}

List<Map<String, dynamic>> _listHappyHour = [];
List<Map<String, dynamic>> listBonusItem = [];
// String? dropdownHappyHour;
RxnString dropdownHappyHour = RxnString(null);
List<String> jenisPembayaran = ["awal", "akhir"];
Map<String, int> selecteditemindex = {};

class _DetailPaketMassageState extends State<DetailPaketMassage> {
  final ControllerPekerja controllerPekerja = Get.find<ControllerPekerja>();

  var idtransaksi = "";
  var idterapis = "";
  var namaterapis = "";
  var namaruangan = "";
  var namaroom = '';
  var idterapis2 = "";
  var namaterapis2 = "";
  var idterapis3 = "";
  var namaterapis3 = "";
  String? nama;
  String? noHp;
  String? status;
  String? idMember;
  // var discSetelahPromo = 0;
  RxInt discSetelahPromo = 0.obs;
  RxString loadupdatetransaksi = 'belum'.obs;
  RxList<Map<String, dynamic>> hargavip = <Map<String, dynamic>>[].obs;

  Future<void> gethargavip() async {
    try {
      namaroom = controllerPekerja.getroom.value.substring(5);
      var response = await dio.get('${myIpAddr()}/ruangan/datahargavip', data: {"nama_ruangan": namaroom});

      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {"harga_vip": item['harga_ruangan']};
          }).toList();

      setState(() {
        hargavip.assignAll(fetcheddata);
      });
    } catch (e) {
      log("Error di fn getstatusruangan : $e");
    }
  }

  @override
  void initState() {
    super.initState();
    getDataHappyHour();
    gethargavip();
    dropdownHappyHour.value = null;
    itemTapCounts.clear();

    // Listen kalo ad perubahan pada discSetelahPromo
    ever(discSetelahPromo, (disc) {
      log("Value discSetelahPromo Berubah Ke $disc");
      updateUIWithDiscount();
    });
  }

  List<Map<String, dynamic>> dataJual = []; // Like React state, passing props

  // Function to update `dataJual` (like React's `setState`)
  void addToDataJual(Map<String, dynamic> newItem) {
    setState(() {
      final existsIdx = dataJual.indexWhere((item) => item['id_paket_msg'] == newItem['id_paket_msg']);

      if (existsIdx != -1) {
        dataJual[existsIdx]['jlh'] = (dataJual[existsIdx]['jlh'] as num).toInt() + 1;
        dataJual[existsIdx]['harga_total'] =
            ((dataJual[existsIdx]['harga_paket_msg'] as num) * (dataJual[existsIdx]['jlh'] as num)).toInt();
      } else {
        dataJual.add({...newItem, 'harga_total': newItem['harga_paket_msg']});
      }

      log('isi data jual : $dataJual');

      checkpaketadapromoitem(newItem['id_paket_msg']).then((_) {
        log(listBonusItem.toString());
        if (listBonusItem.isNotEmpty) {
          final existbonusitemidx = dataJual.indexWhere(
            (item) => item['nama_paket_msg'] == listBonusItem[0]['nama_fnb'],
          );

          if (existbonusitemidx != -1) {
            dataJual[existbonusitemidx]['jlh'] =
                (dataJual[existbonusitemidx]['jlh'] as num).toInt() + listBonusItem[0]['qty'];
          } else {
            dataJual.add({
              "id_paket_msg": listBonusItem[0]['id_fnb'],
              'nama_paket_msg': listBonusItem[0]['nama_fnb'],
              'jlh': listBonusItem[0]['qty'],
              'satuan': 'Paket',
              'durasi_awal': 0,
              'harga_paket_msg': 0,
              'harga_total': 0,
              'is_addon': false,
              'detail_paket': '',
            });
          }
        }
      });
    });
  }

  Future<void> checkpaketadapromoitem(idPaket) async {
    try {
      var response = await dio.get(
        '${myIpAddr()}/massages/checkpaketadapromoitem',
        data: {"id_paket_msg": idPaket},
      );

      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "id_fnb": item["id_fnb"],
              "id_paket_msg": item["id_paket"],
              "nama_fnb": item["nama_fnb"],
              "qty": item["qty"],
            };
          }).toList();

      log('ini fetchnya : $fetcheddata');
      setState(() {
        listBonusItem.assignAll(fetcheddata);
      });
    } catch (e) {
      log("Error di fn Get Data Terapis $e");
    }
  }

  final formatCurrency = NumberFormat.currency(locale: "id_ID", decimalDigits: 0, symbol: 'Rp. ');

  double getHargaBeforeDisc() {
    double total = 0.0;
    for (var item in dataJual) {
      final harga = item['harga_total'] ?? item['harga_fnb'] ?? 0;
      total += (harga is int ? harga.toDouble() : harga);
    }

    return total;
  }

  Map<String, double> getHargaAfterDisc() {
    double totalBefore = getHargaBeforeDisc();
    // Diskon hanya berlaku untuk item massage (id_paket_msg diawali "M")
    double totalEligibleDisc = dataJual.fold(0.0, (sum, item) {
      final idPaket = item['id_paket_msg']?.toString() ?? '';
      if (idPaket.isNotEmpty && idPaket[0] == "M") {
        final harga = item['harga_total'] ?? item['harga_fnb'] ?? 0;
        return sum + (harga is int ? harga.toDouble() : harga);
      }
      return sum;
    });

    double doubleDisc = discSetelahPromo.value / 100;

    double jlhPotongan = totalEligibleDisc * doubleDisc;
    double totalStlhDisc = totalBefore - jlhPotongan;

    if (hargavip.isNotEmpty) {
      totalStlhDisc += hargavip[0]["harga_vip"];
    } else {
      log('kosong harga vip');
    }

    // tak boleh disini. error. kupisah ke updateUIWithDiscount()
    // setState(() {
    //   _dialogTxtTotalFormatted.text = formatCurrency.format(totalStlhDisc);
    //   _dialogTxtTotalOri = totalStlhDisc;
    // });

    return {
      "potongan": jlhPotongan,
      "sblm_disc": totalBefore,
      "stlh_disc": totalStlhDisc,
      "desimal_persen": doubleDisc,
    };
  }

  // Fungsi Manipulasi Harga
  TextEditingController _dialogTxtTotalFormatted = TextEditingController();
  TextEditingController _totalBayarController = TextEditingController();
  TextEditingController _kembalianController = TextEditingController();

  double _dialogTxtTotalOri = 0;
  int _parsedTotalBayar = 0;
  int kembalian = 0;
  RxInt hrgStlhPjk = 0.obs;
  RxDouble desimalPjk = (0.0).obs;

  void _fnFormatTotalBayar(String value) {
    // Remove all non-digit characters
    String digits = value.replaceAll(RegExp(r'[^0-9]'), '');

    // Parse total bayar yang bentuk rupiah ke angka
    int numValue = int.tryParse(digits) ?? 0;
    _parsedTotalBayar = numValue;

    // kembalian = numValue - _dialogTxtTotalOri.toInt();
    kembalian = numValue - hrgStlhPjk.value.toInt();

    // Format kembali ke currency
    String formatted = formatCurrency.format(numValue);
    String formattedKembali = formatCurrency.format(kembalian);

    // Update controller tanpa trigger infinite loop
    _totalBayarController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );

    _kembalianController.value = TextEditingValue(
      text: formattedKembali,
      selection: TextSelection.collapsed(offset: formattedKembali.length),
    );
  }

  // Buat Plus Minus
  // void changeHrg() {
  //   getHargaAfterDisc();

  //   setState(() {});
  // }

  // Utk Update pas pilih dropdown disc
  void updateUIWithDiscount() {
    final result = getHargaAfterDisc();
    setState(() {
      _dialogTxtTotalFormatted.text = formatCurrency.format((result["stlh_disc"]! / 1000).round() * 1000);
      _dialogTxtTotalOri = (result["stlh_disc"]! / 1000).round() * 1000;
    });
  }

  Future<void> getDataHappyHour() async {
    try {
      var response = await dio.get(
        '${myIpAddr()}/listpromo/getdatapromohappyhourdisc',
        queryParameters: {
          'statusTamu': widget.statusTamu, // "Umum", "Member", or "VIP"
        },
      );

      setState(() {
        final rawData = response.data as List;

        if (rawData.isEmpty) {
          _listHappyHour = [];
        } else {
          _listHappyHour =
              rawData.map((item) {
                return {
                  "kode_promo": item["kode_promo"],
                  "nama_promo": item["nama_promo"],
                  "disc": item["disc"],
                };
              }).toList();
        }
      });
    } catch (e) {
      log("Error di fn Get Data Terapis $e");
    }
  }

  TextEditingController _namaAkun = TextEditingController();
  TextEditingController _noRek = TextEditingController();
  TextEditingController _namaBank = TextEditingController();

  RxString varJenisPembayaran = jenisPembayaran.first.obs;

  RxnString _selectedBank = RxnString(null);
  final RxList<String> _bankList = ['BCA', 'BNI', 'BRI', 'Mandiri'].obs;

  Future<void> _storeTrans() async {
    try {
      loadupdatetransaksi.value = 'belum';
      Get.dialog(
        AlertDialog(
          title: Center(child: Text('Loading')),
          content: SizedBox(width: 100, height: 100, child: Center(child: CircularProgressIndicator())),
        ),
      );
      var rincian = getHargaAfterDisc();
      var token = await getTokenSharedPref();
      var data = {
        "id_transaksi": widget.idTrans,
        "total_harga": rincian['sblm_disc'],
        "disc": rincian['desimal_persen'],
        "harga_vip": hargavip[0]['harga_vip'],
        // grandtotal disini blm termasuk pembulatan. ak bulatin d bwh
        // "grand_total": rincian['stlh_disc'],
        // "gtotal_stlh_pajak": hrgStlhPjk.value,
        // "jumlah_bayar": _parsedTotalBayar,
        "detail_trans": dataJual,
        "id_member": widget.idMember ?? "",
      };

      if (varJenisPembayaran.value == "awal") {
        // false = awal
        data['jenis_pembayaran'] = false;
        data['status'] = "paid";

        if (isCash) {
          data['metode_pembayaran'] = "cash";
          // _parsedTotalBayar = ini input manual, misal dia bayar ga mungkin nilainya bulat.
          data['jumlah_bayar'] = _parsedTotalBayar;
        } else {
          if (isQris) {
            data['metode_pembayaran'] = "qris";
          } else if (isKredit) {
            data['metode_pembayaran'] = "kredit";
          } else {
            data['metode_pembayaran'] = "debit";
          }
          data['jumlah_bayar'] = hrgStlhPjk.value;
          data['nama_akun'] = _namaAkun.text;
          data['no_rek'] = _noRek.text;
          data['nama_bank'] = _selectedBank.value;
        }
      } else {
        // Panggil Ini Krn Ga lewat dialog
        await _getPajak();
        double nominalPjk = rincian['stlh_disc']! * desimalPjk.value;
        double hrgPjkSblmRound = rincian['stlh_disc']! + nominalPjk;

        // Pembulatan ke ribuan terdekat
        hrgStlhPjk.value = (hrgPjkSblmRound / 1000).round() * 1000;

        data['jenis_pembayaran'] = true;
        data['status'] = "unpaid";
      }

      data['grand_total'] = (rincian['stlh_disc']! / 1000).round() * 1000;
      data['pajak'] = desimalPjk.value;
      data["gtotal_stlh_pajak"] = hrgStlhPjk.value;

      var response = await dio.post(
        '${myIpAddr()}/massages/store',
        options: Options(headers: {"Authorization": "Bearer $token"}),
        data: data,
      );

      loadupdatetransaksi.value = 'sukses';

      if (!mounted) return;
      CherryToast.success(
        title: Text(
          "Transaksi Sukses!",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
        ),
        animationDuration: const Duration(milliseconds: 2000),
        autoDismiss: true,
      ).show(context);

      log("Isi data jual $dataJual");
      log("Sukses SImpan $response");
    } catch (e) {
      if (!mounted) return;
      CherryToast.error(
        title: Text(
          "Transaksi Gagal!",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
        ),
        animationDuration: const Duration(milliseconds: 2000),
        autoDismiss: true,
      ).show(context);
      if (e is DioException) {
        log("Error fnStoreTrans Dio ${e.response!.data}");
      }
      log("Error fn storeTrans $e");
    }
  }

  Future<void> updatedataloker(statusLocker, nomorLocker) async {
    try {
      await dio.put(
        '${myIpAddr()}/billinglocker/updatelocker',
        data: {"status": statusLocker, "nomor_locker": nomorLocker},
      );
    } catch (e) {
      log("Error di fn updatedataloker : $e");
    }
  }

  Future<void> daftapanggilankerja(namaruangan, namaterapis) async {
    try {
      await dio.post(
        '${myIpAddr()}/spv/daftarpanggilankerja',
        data: {"ruangan": namaruangan, "nama_terapis": namaterapis},
      );
      log("data sukses tersimpan");
    } catch (e) {
      log("error: ${e.toString()}");
    }
  }

  Future<void> daftarruangtunggu(idtransaksi, namaruangan, idterapis, namaterapis) async {
    try {
      await dio.post(
        '${myIpAddr()}/spv/daftarruangtunggu',
        data: {
          "id_transaksi": idtransaksi,
          "nama_ruangan": namaruangan,
          "id_terapis": idterapis,
          "nama_terapis": namaterapis,
        },
      );
      log("data sukses tersimpan");
    } catch (e) {
      log("error: ${e.toString()}");
    }
  }

  Future<void> postterapis2(idtransaksi, idterapis2, idterapis3) async {
    try {
      await dio.post(
        '${myIpAddr()}/massages/saveterapis',
        data: {"id_transaksi": idtransaksi, "idterapis2": idterapis2, "idterapis3": idterapis3},
      );
    } catch (e) {
      log("error: ${e.toString()}");
    }
  }

  @override
  void dispose() {
    _namaAkun.dispose();
    _namaBank.dispose();
    _noRek.dispose();
    super.dispose();
  }

  bool isCash = true;
  bool isDebit = false;
  bool isQris = false;
  bool isKredit = false;

  Future<void> _getPajak() async {
    try {
      var response = await dio.get('${myIpAddr()}/pajak/getpajak');

      // Parse the first record (assumes response is a list of maps)
      List<dynamic> data = response.data;
      if (data.isNotEmpty) {
        var firstRecord = data[0];
        double pjk = double.tryParse(firstRecord['pajak_msg'].toString()) ?? 0.0;

        desimalPjk.value = pjk;
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

  void panggilsemuaterapis() async {
    daftapanggilankerja(namaruangan, namaterapis);

    if (namaterapis2 != '') {
      await Future.delayed(const Duration(seconds: 20));
      daftapanggilankerja(namaruangan, namaterapis2);
    }

    if (namaterapis3 != '') {
      await Future.delayed(const Duration(seconds: 20));
      daftapanggilankerja(namaruangan, namaterapis3);
    }
  }

  bool _isHappyHourSelectionRequired() {
    return _listHappyHour.isNotEmpty && dropdownHappyHour.value == null;
  }

  Future<bool> _showHappyHourReminder() async {
    final completer = Completer<bool>();

    Get.defaultDialog(
      title: 'Promo Happy Hour',
      middleText: 'Silakan pilih promo Happy Hour terlebih dahulu.',
      textCancel: 'Kembali. Pilih Diskon',
      textConfirm: 'Yakin. Tanpa Diskon!',
      barrierDismissible: false,
      onConfirm: () {
        if (!completer.isCompleted) {
          completer.complete(true);
        }
        Get.back();
      },
      onCancel: () {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
    );

    return completer.future;
  }

  void _showDialogConfirmPayment(BuildContext context) async {
    await _getPajak();
    if (!mounted) return;

    List<String> metodeByr = ["cash", "debit", "kredit", "qris"];
    String dropdownValue = metodeByr.first;
    int statusLocker = 0;
    final LockerManager lockerInput = LockerManager();
    int inputlocker = lockerInput.getLocker();

    updateUIWithDiscount();
    // Hitung Harga Setelah Pajak & Pembulatan
    double nominalPjk = _dialogTxtTotalOri * desimalPjk.value;
    double hrgPjkSblmRound = _dialogTxtTotalOri + nominalPjk;

    // Pembulatan ke ribuan terdekat
    hrgStlhPjk.value = (hrgPjkSblmRound / 1000).round() * 1000;
    // Panggil fnTotalBayar biar bs negatif
    _fnFormatTotalBayar("Rp. 0");
    // End Hitung

    showDialog(
      context: context,
      builder: (BuildContext context) {
        // pake statefulbuilder klo dlm dialog
        // bool _initialized = false;

        return StatefulBuilder(
          builder: (context, setState) {
            // if (!_initialized) {
            //   _initialized = true;
            //   WidgetsBinding.instance.addPostFrameCallback((_) {
            //     _fnFormatTotalBayar("Rp. 0");
            //   });
            // }

            return AlertDialog(
              title: Text("Pembayaran", textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Poppins')),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  // height: MediaQuery.of(context).size.height - 300,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: Text("Total Harga: ", style: TextStyle(fontFamily: 'Poppins')),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: TextField(controller: _dialogTxtTotalFormatted, readOnly: true),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text("Pajak: ", style: TextStyle(fontFamily: 'Poppins')),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Obx(
                              () => TextField(
                                controller: TextEditingController(text: "${(desimalPjk.value * 100)}%"),
                                readOnly: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text("Harga Setelah Pajak: ", style: TextStyle(fontFamily: 'Poppins')),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Obx(() {
                              return TextField(
                                controller: TextEditingController(
                                  text: formatCurrency.format(hrgStlhPjk.value),
                                ),
                                readOnly: true,
                              );
                            }),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text("Metode Pembayaran: ", style: TextStyle(fontFamily: 'Poppins')),
                          ),
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
                                    return DropdownMenuItem(
                                      value: value,
                                      child: AutoSizeText(value, minFontSize: 20),
                                    );
                                  }).toList(),
                            ),
                          ),
                        ],
                      ),
                      if (isCash)
                        Column(
                          children: [
                            SizedBox(height: 30),
                            Row(
                              children: [
                                Text(
                                  "Rincian Biaya",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                                ),
                              ],
                            ),
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
                                    keyboardType: TextInputType.number,
                                    // decoration: InputDecoration(
                                    //   hintText: "Rp. 0",
                                    // ),
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
                                Expanded(
                                  flex: 3,
                                  child: TextField(controller: _kembalianController, readOnly: true),
                                ),
                              ],
                            ),
                          ],
                        ),
                      if (!isCash)
                        Column(
                          children: [
                            SizedBox(height: 30),
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
                                Expanded(
                                  child: Text("Nomor Rekening: ", style: TextStyle(fontFamily: 'Poppins')),
                                ),
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
                                      value: _selectedBank.value,
                                      onChanged: (String? value) {
                                        _selectedBank.value = value!;
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
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // if(_kembalianController.text)
                    if (isCash) {
                      String cleaned = _totalBayarController.text.replaceAll("Rp. ", "");

                      String cleanedtotalbayar = cleaned.replaceAll('.', '');

                      log(_totalBayarController.text);
                      log(cleanedtotalbayar);

                      if (_totalBayarController.text == "" ||
                          _totalBayarController.text.isEmpty ||
                          int.tryParse(cleanedtotalbayar)! < 0) {
                        return;
                      }
                    }

                    if (kembalian < 0) {
                      CherryToast.error(
                        title: Text(
                          "Jumlah Bayar Kurang",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        animationDuration: const Duration(milliseconds: 1500),
                        autoDismiss: true,
                      ).show(context);
                    } else {
                      _storeTrans().then((_) async {
                        statusLocker = statusLocker == 0 ? 1 : 0;
                        updatedataloker(statusLocker, inputlocker);
                        idtransaksi = controllerPekerja.getnotrans.value;
                        namaruangan = controllerPekerja.getroom.value;
                        idterapis = controllerPekerja.getidterapis.value;
                        namaterapis = controllerPekerja.getnamaterapis.value;
                        idterapis2 = controllerPekerja.getidterapis2.value;
                        idterapis3 = controllerPekerja.getidterapis3.value;
                        namaterapis2 = controllerPekerja.getnamaterapis2.value;
                        namaterapis3 = controllerPekerja.getnamaterapis3.value;

                        if (idterapis3 == '') {
                          idterapis3 = 'noterapis';
                        }

                        if (idterapis2 == '') {
                          idterapis2 = 'noterapis';
                        }

                        if (controllerPekerja.statusshowing.value != 'pressed') {
                          panggilsemuaterapis();
                        }
                        daftarruangtunggu(idtransaksi, namaruangan, idterapis, namaterapis);

                        if (idterapis2 != 'noterapis') {
                          daftarruangtunggu(idtransaksi, namaruangan, idterapis2, namaterapis2);
                        }

                        if (idterapis3 != 'noterapis') {
                          daftarruangtunggu(idtransaksi, namaruangan, idterapis3, namaterapis3);
                        }

                        if (idterapis2 != 'noterapis' || idterapis3 != 'noterapis') {
                          postterapis2(idtransaksi, idterapis2, idterapis3);
                        }

                        controllerPekerja.getidterapis.value = '';
                        controllerPekerja.getidterapis2.value = '';
                        controllerPekerja.getidterapis3.value = '';
                        controllerPekerja.getnamaterapis.value = '';
                        controllerPekerja.getnamaterapis2.value = '';
                        controllerPekerja.getnamaterapis3.value = '';

                        if (loadupdatetransaksi.value == 'sukses') {
                          Get.offAll(() => MainResepsionis());
                        }
                      });
                    }
                  },
                  child: Text("Proses Pembayaran", style: TextStyle(fontFamily: 'Poppins')),
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

  var dio = Dio();

  @override
  Widget build(BuildContext context) {
    final discountData = getHargaAfterDisc();

    int statusLocker = 0;
    final LockerManager lockerInput = LockerManager();
    int inputlocker = lockerInput.getLocker();

    var storage = GetStorage();

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
          child: ListView(
            children: [
              Column(
                children: [
                  SizedBox(height: 30),
                  Text(
                    "Massage",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Column(
                children: [
                  // Child Widget, Ini Utk Terima Fungsi addToDataJual
                  // SizedBox(
                  //   height: 400,
                  //   child: IsiPaketMassages(onAddItem: addToDataJual),
                  // ),
                  SizedBox(
                    height: 410,
                    child: DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 20, left: 40, right: 40),
                            width: Get.width - 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                              child: TabBar(
                                onTap: (index) {
                                  log("Tab Aktif Sekarang $index");
                                },
                                indicator: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                ),
                                indicatorSize: TabBarIndicatorSize.tab,
                                labelColor: Colors.black,
                                unselectedLabelColor: Colors.black38,
                                labelStyle: TextStyle(fontWeight: FontWeight.bold),
                                tabs: const [Tab(text: "Paketan"), Tab(text: "Produk")],
                              ),
                            ),
                          ),
                          Container(
                            height: 335,
                            width: Get.width - 200,
                            margin: const EdgeInsets.only(left: 40, right: 40),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                              ),
                            ),
                            child: TabBarView(
                              children: [
                                // Konten 1
                                Container(
                                  width: Get.width - 200,
                                  padding: const EdgeInsets.only(left: 10, top: 20, right: 10),
                                  // child: IsiPaketMassages(
                                  //   onAddItem: addToDataJual,
                                  // ),
                                  child: MassageItemGrid(
                                    apiEndpoint: '/massages/paket',
                                    defaultUnit: 'Paket',
                                    icon: Icons.spa,
                                    onAddItem: (item) {
                                      // Check if this package has a promo
                                      final promoExists = widget.activePromos.any(
                                        (promo) => promo['nama_promo'] == item['nama_paket_msg'],
                                      );

                                      if (promoExists) {
                                        // Create a mutable copy of the item to modify its price
                                        Map<String, dynamic> promoItem = Map.from(item);
                                        promoItem['harga_paket_msg'] = 0;
                                        promoItem['harga_total'] = 0; // Also set total price to 0
                                        addToDataJual(promoItem);
                                        CherryToast.success(
                                          title: Text(
                                            "Promo 'Kunjungan' Applied: ${item['nama_paket_msg']}!",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                          animationDuration: const Duration(milliseconds: 2000),
                                          autoDismiss: true,
                                        ).show(context);
                                      } else {
                                        addToDataJual(item);
                                      }
                                    },
                                    activePromos: widget.activePromos, // Pass promos to MassageItemGrid
                                  ),
                                ),
                                // Konten 2 - Massage Produk (assuming no promo applies here for now)
                                Container(
                                  width: Get.width - 200,
                                  padding: const EdgeInsets.only(left: 10, top: 20, right: 10),
                                  child: MassageItemGrid(
                                    apiEndpoint: '/massages/produk',
                                    defaultUnit: 'Pcs',
                                    icon: Icons.spa,
                                    onAddItem: addToDataJual,
                                    activePromos:
                                        const [], // Promos don't apply to products based on current logic
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.only(left: 10, top: 15),
                    // height: Get.height - 145,
                    width: Get.width - 200,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: AutoSizeText(
                                "No Loker",
                                minFontSize: 15,
                                style: TextStyle(fontFamily: 'Poppins'),
                              ),
                            ),
                            Flexible(
                              child: AutoSizeText(
                                ": ",
                                minFontSize: 15,
                                style: TextStyle(fontFamily: 'Poppins'),
                              ),
                            ),
                            Expanded(
                              flex: 6,
                              child: AutoSizeText(
                                "${lockerInput.getLocker()}",
                                minFontSize: 15,
                                style: TextStyle(fontFamily: 'Poppins'),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: AutoSizeText(
                                "Resepsionis",
                                minFontSize: 15,
                                style: TextStyle(fontFamily: 'Poppins'),
                              ),
                            ),
                            Flexible(
                              child: AutoSizeText(
                                ": ",
                                minFontSize: 15,
                                style: TextStyle(fontFamily: 'Poppins'),
                              ),
                            ),
                            Expanded(
                              flex: 6,
                              child: AutoSizeText(
                                storage.read('nama_karyawan'),
                                minFontSize: 15,
                                style: TextStyle(fontFamily: 'Poppins'),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: AutoSizeText(
                                "Room",
                                minFontSize: 15,
                                style: TextStyle(fontFamily: 'Poppins'),
                              ),
                            ),
                            Flexible(
                              child: AutoSizeText(
                                ": ",
                                minFontSize: 15,
                                style: TextStyle(fontFamily: 'Poppins'),
                              ),
                            ),
                            Expanded(
                              flex: 6,
                              child: AutoSizeText(
                                widget.namaRoom,
                                minFontSize: 15,
                                style: TextStyle(fontFamily: 'Poppins'),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: AutoSizeText(
                                "Promo",
                                minFontSize: 15,
                                style: TextStyle(fontFamily: 'Poppins'),
                              ),
                            ),
                            Flexible(
                              child: AutoSizeText(
                                ": ",
                                minFontSize: 15,
                                style: TextStyle(fontFamily: 'Poppins'),
                              ),
                            ),
                            Expanded(
                              flex: 6,
                              child: Row(
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: SizedBox(
                                      width: 300,
                                      child: Obx(
                                        () => DropdownButton<String>(
                                          value: dropdownHappyHour.value,
                                          isExpanded: true,
                                          icon: const Icon(Icons.arrow_drop_down),
                                          elevation: 16,
                                          style: const TextStyle(color: Colors.deepPurple),
                                          underline: SizedBox(),
                                          padding: EdgeInsets.symmetric(horizontal: 10),
                                          onChanged: (String? value) async {
                                            var selectedPromo = _listHappyHour.firstWhere(
                                              (item) => item['nama_promo'] == value,
                                              orElse: () => {"kode_promo": "", "nama_promo": "", "disc": 0},
                                            );

                                            discSetelahPromo.value =
                                                int.tryParse(selectedPromo['disc'].toString()) ?? 0;
                                            dropdownHappyHour.value = value;

                                            // setState(() {
                                            //   dropdownHappyHour = value;
                                            //   discSetelahPromo = selectedPromo['disc'];
                                            // });
                                          },
                                          items:
                                              _listHappyHour.map<DropdownMenuItem<String>>((item) {
                                                return DropdownMenuItem<String>(
                                                  value: item['nama_promo'], // Use ID as value
                                                  child: Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: Text(
                                                      item['nama_promo'].toString(), // Display category name
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontFamily: 'Poppins',
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, size: 18),
                                    onPressed: () {
                                      // setState(() {
                                      //   dropdownHappyHour.value = null;
                                      //   discSetelahPromo.value = 0;
                                      //   getHargaAfterDisc();
                                      // });
                                      dropdownHappyHour.value = null;
                                      discSetelahPromo.value = 0;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Center(
                          child: Row(
                            children: [
                              Expanded(child: Text("Nama Item", style: TextStyle(fontFamily: 'Poppins'))),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 18),
                                  child: Text("Jumlah", style: TextStyle(fontFamily: 'Poppins')),
                                ),
                              ),
                              Expanded(child: Text("Satuan", style: TextStyle(fontFamily: 'Poppins'))),
                              Expanded(child: Text("Harga", style: TextStyle(fontFamily: 'Poppins'))),
                              Expanded(child: Text("Total", style: TextStyle(fontFamily: 'Poppins'))),
                              Flexible(child: Text("")),
                            ],
                          ),
                        ),
                        // Ini Juga Child Component. Derajatnya
                        DataTransaksiMassages(
                          dataJual: dataJual,
                          onChangeHrg: () {
                            getHargaAfterDisc();
                            setState(() {});
                          },
                          datapromo: widget.activePromos,
                        ),
                        Divider(),
                        Row(
                          children: [
                            Expanded(child: Text("")),
                            Expanded(child: Text("")),
                            Expanded(child: Text("")),
                            Expanded(child: Text("Jumlah", style: TextStyle(fontFamily: 'Poppins'))),
                            Expanded(
                              child: Text(
                                formatCurrency.format(discountData['sblm_disc']),
                                style: TextStyle(fontFamily: 'Poppins'),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(child: Text("")),
                            Expanded(child: Text("")),
                            Expanded(child: Text("")),
                            Expanded(child: Text("Disc", style: TextStyle(fontFamily: 'Poppins'))),
                            Expanded(
                              child: Text(
                                formatCurrency.format(discountData['potongan']),
                                style: TextStyle(fontFamily: 'Poppins'),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(child: Text("")),
                            Expanded(child: Text("")),
                            Expanded(child: Text("")),
                            Expanded(child: Text("VIP", style: TextStyle(fontFamily: 'Poppins'))),
                            Expanded(
                              child: Text(
                                hargavip.isNotEmpty
                                    ? formatCurrency.format(hargavip[0]["harga_vip"])
                                    : formatCurrency.format(0),
                                style: TextStyle(fontFamily: 'Poppins'),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(child: Text("")),
                            Expanded(child: Text("")),
                            Expanded(child: Text("")),
                            Expanded(child: Text("Total", style: TextStyle(fontFamily: 'Poppins'))),
                            Expanded(
                              child: Text(
                                formatCurrency.format((discountData['stlh_disc']! / 1000).round() * 1000),
                                style: TextStyle(fontFamily: 'Poppins'),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 10),
                      ],
                    ),
                  ),

                  SizedBox(height: 10),

                  SizedBox(
                    width: MediaQuery.of(context).size.width - 200,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Jenis Pembayaran", style: TextStyle(fontFamily: 'Poppins')),
                                    SizedBox(
                                      width: 170,
                                      child: Obx(
                                        () => DropdownButton<String>(
                                          value: varJenisPembayaran.value,
                                          isExpanded: true,
                                          elevation: 18,
                                          style: const TextStyle(color: Colors.deepPurple),
                                          onChanged: (String? value) {
                                            // dipanggil kalo user select item
                                            // setState(() {
                                            //   varJenisPembayaran.value = value!;
                                            // });
                                            varJenisPembayaran.value = value!;
                                            log("Jenis Pembayaran skrg ${varJenisPembayaran.value}");
                                          },
                                          icon: Icon(Icons.arrow_drop_down_circle),
                                          items:
                                              jenisPembayaran.map<DropdownMenuItem<String>>((String value) {
                                                return DropdownMenuItem(
                                                  value: value,
                                                  child: Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: AutoSizeText(
                                                      "Pembayaran di $value",
                                                      minFontSize: 15,
                                                      style: TextStyle(fontFamily: 'Poppins'),
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
                            ),
                            Obx(() {
                              if (varJenisPembayaran.value == "awal") {
                                return Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        if (_isHappyHourSelectionRequired()) {
                                          bool isConfirmed = await _showHappyHourReminder();

                                          if (!isConfirmed) {
                                            return;
                                          }
                                        }

                                        _showDialogConfirmPayment(Get.context!);
                                      },
                                      child: Text(
                                        "Konfirmasi Pembayaran",
                                        style: TextStyle(fontFamily: 'Poppins'),
                                      ),
                                    ),
                                  ),
                                );
                              } else {
                                return Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        if (_isHappyHourSelectionRequired()) {
                                          bool isConfirmed = await _showHappyHourReminder();

                                          if (!isConfirmed) {
                                            return;
                                          }
                                        }

                                        _storeTrans().then((_) {
                                          statusLocker = statusLocker == 0 ? 1 : 0;
                                          updatedataloker(statusLocker, inputlocker);

                                          idtransaksi = controllerPekerja.getnotrans.value;
                                          namaruangan = controllerPekerja.getroom.value;
                                          idterapis = controllerPekerja.getidterapis.value;
                                          idterapis2 = controllerPekerja.getidterapis2.value;
                                          idterapis3 = controllerPekerja.getidterapis3.value;
                                          namaterapis = controllerPekerja.getnamaterapis.value;
                                          namaterapis2 = controllerPekerja.getnamaterapis2.value;
                                          namaterapis3 = controllerPekerja.getnamaterapis3.value;

                                          if (idterapis3 == '') {
                                            idterapis3 = 'noterapis';
                                          }

                                          if (idterapis2 == '') {
                                            idterapis2 = 'noterapis';
                                          }

                                          if (controllerPekerja.statusshowing.value != 'pressed') {
                                            panggilsemuaterapis();
                                          }

                                          daftarruangtunggu(idtransaksi, namaruangan, idterapis, namaterapis);

                                          if (idterapis2 != 'noterapis') {
                                            daftarruangtunggu(
                                              idtransaksi,
                                              namaruangan,
                                              idterapis2,
                                              namaterapis2,
                                            );
                                          }

                                          if (idterapis3 != 'noterapis') {
                                            daftarruangtunggu(
                                              idtransaksi,
                                              namaruangan,
                                              idterapis3,
                                              namaterapis3,
                                            );

                                            if (idterapis2 != 'noterapis' || idterapis3 != 'noterapis') {
                                              postterapis2(idtransaksi, idterapis2, idterapis3);
                                            }

                                            controllerPekerja.getidterapis.value = '';
                                            controllerPekerja.getidterapis2.value = '';
                                            controllerPekerja.getidterapis3.value = '';
                                            controllerPekerja.getnamaterapis.value = '';
                                            controllerPekerja.getnamaterapis2.value = '';
                                            controllerPekerja.getnamaterapis3.value = '';
                                          }

                                          if (loadupdatetransaksi.value == 'sukses') {
                                            Get.offAll(() => MainResepsionis());
                                          }
                                        });
                                      },
                                      child: Text(
                                        "Simpan Transaksi",
                                        style: TextStyle(fontFamily: 'Poppins'),
                                      ),
                                    ),
                                  ),
                                );
                              }
                            }),
                            // if (varJenisPembayaran == "awal")
                            //   Expanded(
                            //     child: Align(
                            //       alignment: Alignment.centerRight,
                            //       child: ElevatedButton(
                            //         onPressed: () {
                            //           _showDialogConfirmPayment(context);
                            //         },
                            //         child: Text("Konfirmasi Pembayaran", style: TextStyle(fontFamily: 'Poppins')),
                            //       ),
                            //     ),
                            //   ),
                            // if (varJenisPembayaran == "akhir")
                            //   Expanded(
                            //     child: Align(
                            //       alignment: Alignment.centerRight,
                            //       child: ElevatedButton(
                            //         onPressed: () {
                            //           _storeTrans().then((_) {
                            //             statusloker = statusloker == 0 ? 1 : 0;
                            //             updatedataloker(statusloker, inputlocker);

                            //             idtransaksi = controllerPekerja.getnotrans.value;
                            //             namaruangan = controllerPekerja.getroom.value;
                            //             idterapis = controllerPekerja.getidterapis.value;
                            //             namaterapis = controllerPekerja.getnamaterapis.value;

                            //             if (controllerPekerja.statusshowing.value != 'pressed') {
                            //               daftapanggilankerja(namaruangan, namaterapis);
                            //             }
                            //             daftarruangtunggu(idtransaksi, namaruangan, idterapis, namaterapis);
                            //             Get.offAll(() => MainResepsionis());
                            //           });
                            //         },
                            //         child: Text("Simpan Transaksi", style: TextStyle(fontFamily: 'Poppins')),
                            //       ),
                            //     ),
                            //   ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Kombinasi antara IsiPaket dan IsiProduk.
// kodeny kukomen dibawah utk referensi
//. yg membedakan hanya endpoint.
// keyvalue dari isiproduk disamakan dengan isipaket
class MassageItemGrid extends StatefulWidget {
  final String apiEndpoint;
  final String defaultUnit;
  final IconData icon;
  final Function(Map<String, dynamic>) onAddItem;
  final List<Map<String, dynamic>> activePromos;
  final String? idMember;

  const MassageItemGrid({
    super.key,
    required this.apiEndpoint,
    required this.defaultUnit,
    required this.icon,
    required this.onAddItem,
    this.activePromos = const [],
    this.idMember,
  });

  @override
  State<MassageItemGrid> createState() => _MassageItemGridState();
}

Map<String, int> itemTapCounts = {};
String? retrieveindex = '';
RxList<Map<String, dynamic>> dataproduk = <Map<String, dynamic>>[].obs;

class _MassageItemGridState extends State<MassageItemGrid> {
  String? idMember;
  ScrollController _scrollController = ScrollController();
  RxList<Map<String, dynamic>> items = <Map<String, dynamic>>[].obs;
  RxList<bool> _itemTapStates = <bool>[].obs;
  var dio = Dio();

  final formatCurrency = NumberFormat.currency(locale: "id_ID", decimalDigits: 0, symbol: 'Rp. ');
  final AudioPlayer _audioPlayer = AudioPlayer();

  // set awal loading true, kalo datanya udh kefetch maka false
  RxBool isLoading = true.obs;

  Future<void> _getMenu() async {
    try {
      var response = await dio.get('${myIpAddr()}${widget.apiEndpoint}');
      // log("$response");
      items.assignAll(
        (response.data as List).map((item) {
          // jadi key disini di generalisir pakai key dari tabel paket.
          // kemudian tabel produk ni nanti menyesuaikan dengan key tabel paket.
          // if disini jika key dari tabel produk null, maka ambil key dari tabel_paket
          return {
            "id_paket_msg": item['id_produk'] ?? item['id_paket_msg'],
            "nama_paket_msg": item['nama_produk'] ?? item['nama_paket_msg'],
            "harga_paket_msg": item['harga_produk'] ?? item['harga_paket_msg'],
            "detail_paket": item['detail_paket'] ?? "-",
            "durasi_awal": item['durasi'],
            // "status": "unpaid",
            "is_addon": false,
          };
        }).toList(),
      );

      // setState(() {
      //   items =
      //       (response.data as List).map((item) {
      //         // jadi key disini di generalisir pakai key dari tabel paket.
      //         // kemudian tabel produk ni nanti menyesuaikan dengan key tabel paket.
      //         // if disini jika key dari tabel produk null, maka ambil key dari tabel_paket
      //         return {
      //           "id_paket_msg": item['id_produk'] ?? item['id_paket_msg'],
      //           "nama_paket_msg": item['nama_produk'] ?? item['nama_paket_msg'],
      //           "harga_paket_msg": item['harga_produk'] ?? item['harga_paket_msg'],
      //           "detail_paket": item['detail_paket'] ?? "-",
      //           "durasi_awal": item['durasi'],
      //           // "status": "unpaid",
      //           "is_addon": false,
      //         };
      //       }).toList();

      //   isLoading = false;
      // });
    } catch (e) {
      // setState(() {
      //   isLoading = false;
      // });
      log("Error in ${widget.apiEndpoint}: $e");
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _getMenu().then((_) {
      _itemTapStates.assignAll(List.filled(items.length, false));
      idMember = widget.idMember;

      _loadSound();
    });
    getdataproduk();
    retrieveindex = '';
  }

  Future<void> _loadSound() async {
    try {
      await _audioPlayer.setAsset('assets/audio/clicksound.mp3');
      await _audioPlayer.setVolume(1.0); // Max volume (range: 0.0 to 1.0)
    } catch (e) {
      debugPrint("Error loading sound: $e");
    }
  }

  Future<void> _playClickSound() async {
    try {
      // await Future.delayed(const Duration(milliseconds: 100)); // Give time for press animation

      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint("Error playing sound: $e");
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> getdataproduk() async {
    try {
      var response = await dio.get('${myIpAddr()}/listproduk/getdataproduk');
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "id_produk": item['id_produk'],
              "nama_produk": item['nama_produk'],
              "harga_produk": item['harga_produk'],
              "stok_produk": item['stok_produk'],
              "durasi": item['durasi'],
              "tipe_komisi": item['tipe_komisi'],
              "nominal_komisi": item['nominal_komisi'],
              "tipe_komisi_gro": item['tipe_komisi_gro'],
              "nominal_komisi_gro": item['nominal_komisi_gro'],
            };
          }).toList();
      // setState(() {
      // dataproduk.clear();
      // dataproduk.assignAll(fetcheddata);
      // dataproduk.refresh();
      // });
      dataproduk.assignAll(fetcheddata);
    } catch (e) {
      log("Error di fn getdatafnb : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      thumbVisibility: true,
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Container(
          // height: MediaQuery.of(context).size.height + 140,
          width: MediaQuery.of(context).size.width - 200,
          padding: const EdgeInsets.only(right: 10),
          child: Column(
            children: [
              Obx(() {
                if (isLoading.value) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else {
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 30,
                      mainAxisSpacing: 25,
                      childAspectRatio: 2 / 1.5,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      double displayPrice = item['harga_paket_msg'].toDouble();
                      final promoExists = widget.activePromos.any(
                        (promo) => promo['nama_promo'] == item['nama_paket_msg'],
                      );

                      if (promoExists) {
                        displayPrice = 0.0; // Set display price to 0 if promo applies
                      }
                      int sisakunjungan = 0;
                      int sisastok = 0;
                      String kondisilebih = '';
                      String tipepaket = '';

                      return Obx(() {
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (_) {
                            _itemTapStates[index] = true;
                            _itemTapStates.refresh();
                          },
                          onTapUp: (_) async {
                            await _playClickSound();
                            if (!mounted) return;
                            // Lepaskan Animasi
                            _itemTapStates[index] = false;
                            _itemTapStates.refresh();
                            // End Lepaskan Animasi

                            if (promoExists) {
                              String itemname = item['nama_paket_msg'];
                              // selecteditemindex[itemname] = index;
                              // retrieveindex = selecteditemindex[itemname];
                              retrieveindex = itemname;
                              for (var promo in widget.activePromos.where(
                                (p) => p['nama_paket_msg'] == item['nama_paket_msg'],
                              )) {
                                sisakunjungan = int.tryParse(promo['sisa_kunjungan'].toString()) ?? 0;
                              }
                              if (retrieveindex != null && itemTapCounts.containsKey(retrieveindex)) {
                                itemTapCounts[retrieveindex!] = itemTapCounts[retrieveindex]! + 1;
                              } else if (retrieveindex != null) {
                                itemTapCounts[retrieveindex!] = 1;
                              }

                              log('sisa kunjungan : $sisakunjungan ');
                              log('tapped : ${itemTapCounts[retrieveindex]}');

                              if (retrieveindex != null) {
                                if (itemTapCounts[retrieveindex]! > sisakunjungan) {
                                  kondisilebih = 'benar';
                                } else {
                                  kondisilebih = 'salah';
                                }
                              }

                              if (kondisilebih == 'salah') {
                                widget.onAddItem({
                                  "id_paket_msg": item['id_paket_msg'],
                                  "nama_paket_msg": item['nama_paket_msg'],
                                  "detail_paket": item['detail_paket'],
                                  "jlh": 1,
                                  "satuan": widget.defaultUnit,
                                  "harga_paket_msg": item['harga_paket_msg'],
                                  "harga_total": item['harga_paket_msg'],
                                  "durasi_awal": item['durasi_awal'],
                                  // "status": "unpaid",
                                  "is_addon": false,
                                });
                              } else {
                                CherryToast.error(
                                  title: Text('Error'),
                                  description: Text('melebihi pemakaian'),
                                ).show(context);
                              }
                            } else {
                              for (var produk in dataproduk.where(
                                (p) => p['nama_produk'] == item['nama_paket_msg'],
                              )) {
                                sisastok = int.tryParse(produk['stok_produk'].toString()) ?? 0;
                                tipepaket = 'produk';
                              }

                              if (tipepaket == 'produk') {
                                String itemname = item['nama_paket_msg'];
                                // selecteditemindex[itemname] = index;
                                // retrieveindex = selecteditemindex[itemname];
                                retrieveindex = itemname;
                                if (retrieveindex != null && itemTapCounts.containsKey(retrieveindex)) {
                                  itemTapCounts[retrieveindex!] = itemTapCounts[retrieveindex]! + 1;
                                } else if (retrieveindex != null) {
                                  itemTapCounts[retrieveindex!] = 1;
                                }
                                log('counter : $itemTapCounts');
                                if (sisastok == 0) {
                                  CherryToast.error(
                                    title: Text('Error'),
                                    description: Text('Stok sudah kosong'),
                                  ).show(context);
                                } else if (retrieveindex != null) {
                                  if (itemTapCounts[retrieveindex]! > sisastok) {
                                    CherryToast.error(
                                      title: Text('Error'),
                                      description: Text('Penggunaan item melebihi stok'),
                                    ).show(context);
                                  } else {
                                    widget.onAddItem({
                                      "id_paket_msg": item['id_paket_msg'],
                                      "nama_paket_msg": item['nama_paket_msg'],
                                      "detail_paket": item['detail_paket'],
                                      "jlh": 1,
                                      "satuan": widget.defaultUnit,
                                      "harga_paket_msg": item['harga_paket_msg'],
                                      "harga_total": item['harga_paket_msg'],
                                      "durasi_awal": item['durasi_awal'],
                                      // "status": "unpaid",
                                      "is_addon": false,
                                    });
                                  }
                                }
                              } else {
                                widget.onAddItem({
                                  "id_paket_msg": item['id_paket_msg'],
                                  "nama_paket_msg": item['nama_paket_msg'],
                                  "detail_paket": item['detail_paket'],
                                  "jlh": 1,
                                  "satuan": widget.defaultUnit,
                                  "harga_paket_msg": item['harga_paket_msg'],
                                  "harga_total": item['harga_paket_msg'],
                                  "durasi_awal": item['durasi_awal'],
                                  // "status": "unpaid",
                                  "is_addon": false,
                                });
                              }
                            }
                          },
                          onTapCancel: () {
                            _itemTapStates[index] = false;
                            _itemTapStates.refresh();
                          },
                          child: Transform.scale(
                            scale: _itemTapStates[index] ? 0.8 : 1.0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 64, 97, 55),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(widget.icon, size: 50, color: Colors.white),
                                  Text(
                                    item['nama_paket_msg'],
                                    style: const TextStyle(color: Colors.white, fontSize: 16),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    formatCurrency.format(displayPrice),
                                    style: const TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      });
                    },
                  );
                }
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class DataTransaksiMassages extends StatefulWidget {
  final Function onChangeHrg;
  final List dataJual;
  final List<Map<String, dynamic>> datapromo;

  const DataTransaksiMassages({
    super.key,
    required this.dataJual,
    required this.onChangeHrg,
    required this.datapromo,
  });

  @override
  State<DataTransaksiMassages> createState() => _DataTransaksiMassagesState();
}

class _DataTransaksiMassagesState extends State<DataTransaksiMassages> {
  final formatCurrency = NumberFormat.currency(locale: "id_ID", decimalDigits: 0, symbol: 'Rp. ');

  Future<void> checkpaketadapromoitem(idPaket) async {
    try {
      var response = await dio.get(
        '${myIpAddr()}/massages/checkpaketadapromoitem',
        data: {"id_paket_msg": idPaket},
      );

      setState(() {
        listBonusItem =
            (response.data as List).map((item) {
              return {"id_fnb": item["id_fnb"], "nama_fnb": item["nama_fnb"], "qty": item["qty"]};
            }).toList();
      });
    } catch (e) {
      log("Error di fn check paket ada promo $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: widget.dataJual.length,
        itemBuilder: (context, index) {
          int sisakunjungan = 0;
          int sisastok = 0;
          String kondisilebih = '';
          String tipepaket = '';
          return Row(
            children: [
              Expanded(child: AutoSizeText(widget.dataJual[index]['nama_paket_msg'], minFontSize: 15)),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove, size: 18),
                      onPressed: () async {
                        setState(() {
                          final promoExists = widget.datapromo.any(
                            (promo) => promo['nama_promo'] == widget.dataJual[index]['nama_paket_msg'],
                          );

                          if (promoExists) {
                            for (var promo in widget.datapromo.where(
                              (p) => p['nama_paket_msg'] == widget.dataJual[index]['nama_paket_msg'],
                            )) {
                              sisakunjungan = int.tryParse(promo['sisa_kunjungan'].toString()) ?? 0;
                            }
                            String itemname = widget.dataJual[index]['nama_paket_msg'];
                            // retrieveindex = selecteditemindex[itemname];
                            retrieveindex = itemname;

                            if (retrieveindex != null && itemTapCounts.containsKey(retrieveindex)) {
                              if (retrieveindex != null && itemTapCounts[retrieveindex]! <= 1) {
                                itemTapCounts[retrieveindex!] = 1;
                              } else if (retrieveindex != null &&
                                  itemTapCounts[retrieveindex]! >= sisakunjungan) {
                                if (sisakunjungan == 1) {
                                  itemTapCounts[retrieveindex!] = 1;
                                } else {
                                  itemTapCounts[retrieveindex!] = sisakunjungan - 1;
                                }
                              } else if (retrieveindex != null) {
                                itemTapCounts[retrieveindex!] = itemTapCounts[retrieveindex]! - 1;
                              }
                            } else if (retrieveindex != null) {
                              itemTapCounts[retrieveindex!] = 1;
                            }
                            log('tapped : $itemTapCounts');
                          } else {
                            for (var produk in dataproduk.where(
                              (p) => p['nama_produk'] == widget.dataJual[index]['nama_paket_msg'],
                            )) {
                              sisastok = int.tryParse(produk['stok_produk'].toString()) ?? 0;
                              tipepaket = 'produk';
                            }

                            if (tipepaket == 'produk') {
                              String itemname = widget.dataJual[index]['nama_paket_msg'];
                              // retrieveindex = selecteditemindex[itemname];
                              retrieveindex = itemname;

                              if (retrieveindex != null && itemTapCounts.containsKey(retrieveindex)) {
                                if (retrieveindex != null && itemTapCounts[retrieveindex]! <= 1) {
                                  itemTapCounts[retrieveindex!] = 1;
                                } else if (retrieveindex != null &&
                                    itemTapCounts[retrieveindex]! >= sisastok) {
                                  if (sisastok == 1) {
                                    itemTapCounts[retrieveindex!] = 1;
                                  } else {
                                    itemTapCounts[retrieveindex!] = sisastok - 1;
                                  }
                                } else if (retrieveindex != null) {
                                  itemTapCounts[retrieveindex!] = itemTapCounts[retrieveindex]! - 1;
                                }
                              } else if (retrieveindex != null) {
                                itemTapCounts[retrieveindex!] = 1;
                              }
                              log('tapped : $itemTapCounts');
                            }
                          }
                          if (widget.dataJual[index]['id_paket_msg'][0] == 'F') {
                            CherryToast.error(
                              title: Text('Error'),
                              description: Text('Item bonus tidak dapat dikurangkan manual'),
                            ).show(context);
                          }
                        });

                        if (widget.dataJual[index]['id_paket_msg'][0] == 'F') {
                          return;
                        }

                        await checkpaketadapromoitem(widget.dataJual[index]['id_paket_msg']);
                        if (!mounted) return;

                        setState(() {
                          if (listBonusItem.isNotEmpty) {
                            final existbonusitemidx = widget.dataJual.indexWhere(
                              (item) => item['nama_paket_msg'] == listBonusItem[0]['nama_fnb'],
                            );

                            if (existbonusitemidx != -1) {
                              if (widget.dataJual[existbonusitemidx]['jlh'] > listBonusItem[0]['qty'] &&
                                  widget.dataJual[index]['jlh'] > 1) {
                                widget.dataJual[existbonusitemidx]['jlh'] =
                                    (widget.dataJual[existbonusitemidx]['jlh'] as num).toInt() -
                                    listBonusItem[0]['qty'];
                              }
                            }
                          }
                          if (widget.dataJual[index]['jlh'] > 1) {
                            widget.dataJual[index]['jlh']--;
                            // Update Harga Total Juga
                            widget.dataJual[index]['harga_total'] =
                                widget.dataJual[index]['harga_paket_msg'] * widget.dataJual[index]['jlh'];
                          }
                        });

                        widget.onChangeHrg();
                      },
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: AutoSizeText("${widget.dataJual[index]['jlh']}", minFontSize: 15),
                    ),
                    IconButton(
                      icon: Icon(Icons.add, size: 18),
                      onPressed: () async {
                        setState(() {
                          final promoExists = widget.datapromo.any(
                            (promo) => promo['nama_promo'] == widget.dataJual[index]['nama_paket_msg'],
                          );

                          if (promoExists) {
                            for (var promo in widget.datapromo.where(
                              (p) => p['nama_paket_msg'] == widget.dataJual[index]['nama_paket_msg'],
                            )) {
                              sisakunjungan = int.tryParse(promo['sisa_kunjungan'].toString()) ?? 0;
                            }
                            String itemname = widget.dataJual[index]['nama_paket_msg'];
                            // retrieveindex = selecteditemindex[itemname];
                            retrieveindex = itemname;

                            if (retrieveindex != null && itemTapCounts.containsKey(retrieveindex)) {
                              itemTapCounts[retrieveindex!] = itemTapCounts[retrieveindex]! + 1;
                            } else if (retrieveindex != null) {
                              itemTapCounts[retrieveindex!] = 1;
                            }

                            if (retrieveindex != null) {
                              if (itemTapCounts[retrieveindex]! > sisakunjungan) {
                                kondisilebih = 'benar';
                              } else {
                                kondisilebih = 'salah';
                              }
                            }
                          }

                            if (kondisilebih == 'benar') {
                              CherryToast.error(
                                title: Text('Error'),
                                description: Text('melebihi pemakaian'),
                              ).show(context);
                            } else {
                            for (var produk in dataproduk.where(
                              (p) => p['nama_produk'] == widget.dataJual[index]['nama_paket_msg'],
                            )) {
                              sisastok = int.tryParse(produk['stok_produk'].toString()) ?? 0;
                              tipepaket = 'produk';
                            }

                            if (tipepaket == 'produk') {
                              String itemname = widget.dataJual[index]['nama_paket_msg'];
                              // selecteditemindex[itemname] = index;
                              // retrieveindex = selecteditemindex[itemname];
                              retrieveindex = itemname;
                              if (retrieveindex != null && itemTapCounts.containsKey(retrieveindex)) {
                                itemTapCounts[retrieveindex!] = itemTapCounts[retrieveindex]! + 1;
                              } else if (retrieveindex != null) {
                                itemTapCounts[retrieveindex!] = 1;
                              }
                              log('counter : $itemTapCounts');
                              if (sisastok == 0) {
                                CherryToast.error(
                                  title: Text('Error'),
                                  description: Text('Stok sudah kosong'),
                                ).show(context);
                              } else if (retrieveindex != null) {
                                if (itemTapCounts[retrieveindex]! > sisastok) {
                                  CherryToast.error(
                                    title: Text('Error'),
                                    description: Text('Penggunaan item melebihi stok'),
                                  ).show(context);
                                } else {
                                  widget.dataJual[index]['jlh']++;
                                  // Update Harga Total Juga
                                  widget.dataJual[index]['harga_total'] =
                                      widget.dataJual[index]['harga_paket_msg'] *
                                      widget.dataJual[index]['jlh'];
                                }
                              }
                            } else {
                              if (widget.dataJual[index]['id_paket_msg'][0] == 'F') {
                                CherryToast.error(
                                  title: Text('Error'),
                                  description: Text('Item bonus tidak dapat ditambahkan manual'),
                                ).show(context);
                              }
                            }
                          }

                          log(promoExists.toString());
                          log('tapped : $itemTapCounts');
                        });

                        if (widget.dataJual[index]['id_paket_msg'][0] == 'F') {
                          return;
                        }

                        if (kondisilebih == 'benar') {
                          return;
                        }

                        await checkpaketadapromoitem(widget.dataJual[index]['id_paket_msg']);
                        if (!mounted) return;

                        setState(() {
                          if (listBonusItem.isNotEmpty) {
                            final existbonusitemidx = widget.dataJual.indexWhere(
                              (item) => item['nama_paket_msg'] == listBonusItem[0]['nama_fnb'],
                            );

                            if (existbonusitemidx != -1) {
                              widget.dataJual[existbonusitemidx]['jlh'] =
                                  (widget.dataJual[existbonusitemidx]['jlh'] as num).toInt() +
                                  listBonusItem[0]['qty'];
                            }
                          }
                          widget.dataJual[index]['jlh']++;
                          // Update Harga Total Juga
                          widget.dataJual[index]['harga_total'] =
                              widget.dataJual[index]['harga_paket_msg'] * widget.dataJual[index]['jlh'];
                        });

                        widget.onChangeHrg();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(child: AutoSizeText(widget.dataJual[index]['satuan'], minFontSize: 15)),
              Expanded(
                child: AutoSizeText(
                  formatCurrency.format(widget.dataJual[index]['harga_paket_msg']),
                  minFontSize: 15,
                ),
              ),
              Expanded(
                child: Text(
                  formatCurrency.format(widget.dataJual[index]['harga_total']),
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(Icons.delete_forever_outlined, size: 18),
                        onPressed: () async {
                          // Guard against stale index when list already changed
                          if (index < 0 || index >= widget.dataJual.length) return;

                          // Snapshot current item to avoid range errors if the list mutates later
                          final currentItem = Map<String, dynamic>.from(widget.dataJual[index]);
                          final currentNamaPaket = currentItem['nama_paket_msg'];
                          final currentIdPaket = (currentItem['id_paket_msg'] ?? '').toString();
                          final currentQty = (currentItem['jlh'] as num?)?.toInt() ?? 0;

                          setState(() {
                            final promoExists = widget.datapromo.any(
                              (promo) => promo['nama_promo'] == currentNamaPaket,
                            );

                            if (promoExists) {
                              if (retrieveindex != null) {
                                String itemname = currentNamaPaket;
                                // retrieveindex = selecteditemindex[itemname];
                                retrieveindex = itemname;

                                itemTapCounts[retrieveindex!] = 0;
                              }
                            } else {
                              for (var produk in dataproduk.where(
                                (p) => p['nama_produk'] == currentNamaPaket,
                              )) {
                                sisastok = int.tryParse(produk['stok_produk'].toString()) ?? 0;
                                tipepaket = 'produk';
                              }

                              if (tipepaket == 'produk') {
                                String itemname = currentNamaPaket;
                                // selecteditemindex[itemname] = index;
                                // retrieveindex = selecteditemindex[itemname];
                                retrieveindex = itemname;
                                itemTapCounts[retrieveindex!] = 0;
                              }
                            }
                            if (currentIdPaket.startsWith('F')) {
                              CherryToast.error(
                                title: Text('Error'),
                                description: Text('Item bonus tidak dapat dihapus manual'),
                              ).show(context);
                            }
                          });

                          if (currentIdPaket.startsWith('F')) {
                            return;
                          }

                          await checkpaketadapromoitem(currentIdPaket);
                          if (!mounted) return;

                          setState(() {
                            if (listBonusItem.isNotEmpty) {
                              final existbonusitemidx = widget.dataJual.indexWhere(
                                (item) => item['nama_paket_msg'] == listBonusItem[0]['nama_fnb'],
                              );

                              if (existbonusitemidx != -1) {
                                if (widget.dataJual[existbonusitemidx]['jlh'] > listBonusItem[0]['qty'] &&
                                    currentQty > 1) {
                                  log(currentQty.toString());
                                  widget.dataJual[existbonusitemidx]['jlh'] =
                                      (widget.dataJual[existbonusitemidx]['jlh'] as num).toInt() -
                                      listBonusItem[0]['qty'] * currentQty;
                                }

                                if (widget.dataJual[existbonusitemidx]['jlh'] <= listBonusItem[0]['qty']) {
                                  widget.dataJual.removeAt(existbonusitemidx);
                                }
                              }
                            }

                            final removeIdx = widget.dataJual.indexWhere(
                              (item) =>
                                  item['id_paket_msg'] == currentIdPaket &&
                                  item['nama_paket_msg'] == currentNamaPaket,
                            );
                            if (removeIdx != -1) {
                              widget.dataJual.removeAt(removeIdx);
                            }
                          });

                          widget.onChangeHrg();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}



// Kode awal. udah diganti sama MassageItemGrid
// class IsiPaketMassages extends StatefulWidget {
//   final Function(Map<String, dynamic>) onAddItem;

//   const IsiPaketMassages({super.key, required this.onAddItem});

//   @override
//   State<IsiPaketMassages> createState() => _IsiPaketMassagesState();
// }

// class _IsiPaketMassagesState extends State<IsiPaketMassages> {
//   ScrollController _scrollController = ScrollController();

//   List<Map<String, dynamic>> items = [];
//   List<bool> _itemTapStates = [];

//   var dio = Dio();

//   Future<void> _getMenu() async {
//     try {
//       var response = await dio.get('${myIpAddr()}/massages/paket');

//       setState(() {
//         items = (response.data as List).map((item) {
//           return {
//             "id_paket_msg": item['id_paket_msg'],
//             "nama_paket_msg": item['nama_paket_msg'],
//             "harga_paket_msg": item['harga_paket_msg'],
//             "detail_paket": item['detail_paket']
//           };
//         }).toList();
//       });
//     } catch (e) {
//       log("Error di fn Get Menu paket massage $e");
//     }
//   }

//   final formatCurrency = new NumberFormat.currency(
//       locale: "id_ID", decimalDigits: 0, symbol: 'Rp. ');

//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//     _getMenu().then((_) {
//       // Params 1 = Panjang isi data, Params 2 isi datanya. isi semuanya false;
//       _itemTapStates = List.filled(items.length, false);
//     });
//   }

//   @override
//   void dispose() {
//     // TODO: implement dispose
//     _scrollController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scrollbar(
//       thumbVisibility: true,
//       controller: _scrollController,
//       child: SingleChildScrollView(
//         controller: _scrollController,
//         child: Container(
//           // Asumsi Kalo Kontenny Banyak
//           height: MediaQuery.of(context).size.height + 40,
//           width: MediaQuery.of(context).size.width - 200,
//           padding: const EdgeInsets.only(
//             right: 10,
//           ),
//           child: Column(
//             children: [
//               // Pake gridview builder daripada make row manual.
//               GridView.builder(
//                 shrinkWrap: true, // Buat dia fit ke singlechild
//                 physics:
//                     const NeverScrollableScrollPhysics(), // jgn biarin gridviewscrollsendiri
//                 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 4, // 4 Item dalam 1 Row
//                   crossAxisSpacing: 30, // Space Horizontal tiap item
//                   mainAxisSpacing: 25, // Space Vertical tiap item
//                   // Width to height ratio (e.g., width: 2, height: 3)
//                   childAspectRatio: 2 / 1.5,
//                 ),
//                 // Nanti Looping data disini
//                 itemCount: items.length,
//                 itemBuilder: (context, index) {
//                   // Utk Animasi Dipencet
//                   var item = items[index];

//                   return GestureDetector(
//                     onTapDown: (_) {
//                       setState(() {
//                         _itemTapStates[index] = true;
//                       });
//                     },
//                     onTapUp: (_) {
//                       widget.onAddItem({
//                         // "nama": items[index]['name'],
//                         // "jlhbrg": 1,
//                         // "satuan": "Paket",
//                         // "harga": "Rp. ${index + 1}0.000",

//                         "id_paket_msg": item['id_paket_msg'],
//                         "nama_paket_msg": item['nama_paket_msg'],
//                         "detail_paket": item['detail_paket'],
//                         "jlh": 1,
//                         "satuan": "Paket",
//                         "harga_paket_msg": item['harga_paket_msg'],
//                         "harga_total": item['harga_paket_msg']
//                       });

//                       setState(() {
//                         _itemTapStates[index] = false;
//                       });
//                     },
//                     onTapCancel: () {
//                       setState(() {
//                         _itemTapStates[index] = false;
//                       });
//                     },
//                     child: Transform.scale(
//                       scale: _itemTapStates[index] ? 0.8 : 1.0,
//                       child: Container(
//                         decoration: BoxDecoration(
//                           color: const Color.fromARGB(255, 64, 97, 55),
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(
//                               Icons.handshake,
//                               size: 50,
//                               color: Colors.white,
//                             ),
//                             Text(
//                               item['nama_paket_msg'],
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 16,
//                               ),
//                             ),
//                             Text(
//                               "${formatCurrency.format(item['harga_paket_msg'])}",
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 16,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class IsiProdukMassages extends StatefulWidget {
//   final Function(Map<String, dynamic>) onAddItem;
//   const IsiProdukMassages({super.key, required this.onAddItem});

//   @override
//   State<IsiProdukMassages> createState() => _IsiProdukMassagesState();
// }

// class _IsiProdukMassagesState extends State<IsiProdukMassages> {
//   ScrollController _scrollController = ScrollController();

//   List<Map<String, dynamic>> items = [];
//   List<bool> _itemTapStates = [];

//   var dio = Dio();

//   // Untuk yang produk, sesuaikan nama keynya dengan nama paket,
//   // karena anggapannya nanti digabung jadi 1 struk.
//   // jadi harus menyesuaikan key valuenya.
//   // tapi valuenya tetap diambil dari kolom tabel produk
//   Future<void> _getMenu() async {
//     try {
//       var response = await dio.get('${myIpAddr()}/massages/produk');

//       setState(() {
//         items = (response.data as List).map((item) {
//           return {
//             "id_paket_msg": item['id_produk'],
//             "nama_paket_msg": item['nama_produk'],
//             "harga_paket_msg": item['harga_produk'],
//             "detail_paket": "-"
//           };
//         }).toList();
//       });

//       log("Isi Produk di getMenu adalah $items");
//     } catch (e) {
//       log("Error di fn Get Menu produk massage $e");
//     }
//   }

//   final formatCurrency = new NumberFormat.currency(
//       locale: "id_ID", decimalDigits: 0, symbol: 'Rp. ');

//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//     _getMenu().then((_) {
//       _itemTapStates = List.filled(items.length, false);
//     });
//   }

//   @override
//   void dispose() 
//     // TODO: implement dispose
//     _scrollController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scrollbar(
//       thumbVisibility: true,
//       controller: _scrollController,
//       child: SingleChildScrollView(
//         controller: _scrollController,
//         child: Container(
//           // Asumsi Kalo Kontenny Banyak
//           height: MediaQuery.of(context).size.height + 40,
//           width: MediaQuery.of(context).size.width - 200,
//           padding: const EdgeInsets.only(
//             right: 10,
//           ),
//           child: Column(
//             children: [
//               // Pake gridview builder daripada make row manual.
//               GridView.builder(
//                 shrinkWrap: true, // Buat dia fit ke singlechild
//                 physics:
//                     const NeverScrollableScrollPhysics(), // jgn biarin gridviewscrollsendiri
//                 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 4, // 4 Item dalam 1 Row
//                   crossAxisSpacing: 30, // Space Horizontal tiap item
//                   mainAxisSpacing: 25, // Space Vertical tiap item
//                   // Width to height ratio (e.g., width: 2, height: 3)
//                   childAspectRatio: 2 / 1.5,
//                 ),
//                 // Nanti Looping data disini
//                 itemCount: items.length,
//                 itemBuilder: (context, index) {
//                   var item = items[index];
//                   print(item);
//                   // Utk Animasi Dipencet
//                   return GestureDetector(
//                     onTapDown: (_) {
//                       setState(() {
//                         _itemTapStates[index] = true;
//                       });
//                     },
//                     onTapUp: (_) {
//                       widget.onAddItem({
//                         "id_paket_msg": item['id_paket_msg'],
//                         "nama_paket_msg": item['nama_paket_msg'],
//                         "detail_paket": item['detail_paket'],
//                         "jlh": 1,
//                         "satuan": "Pcs",
//                         "harga_paket_msg": item['harga_paket_msg'],
//                         "harga_total": item['harga_paket_msg']
//                       });

//                       setState(() {
//                         _itemTapStates[index] = false;
//                       });
//                     },
//                     onTapCancel: () {
//                       setState(() {
//                         _itemTapStates[index] = false;
//                       });
//                     },
//                     child: Transform.scale(
//                       scale: _itemTapStates[index] ? 0.8 : 1.0,
//                       child: Container(
//                         decoration: BoxDecoration(
//                           color: const Color.fromARGB(255, 64, 97, 55),
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(
//                               Icons.handshake,
//                               size: 50,
//                               color: Colors.white,
//                             ),
//                             Text(
//                               item['nama_paket_msg'],
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 16,
//                               ),
//                             ),
//                             Text(
//                               "${formatCurrency.format(item['harga_paket_msg'])}",
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 16,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

