import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:Project_SPA/function/ip_address.dart';
import 'package:Project_SPA/function/token.dart';
import 'package:intl/intl.dart';
import 'package:Project_SPA/resepsionis/main_resepsionis.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:just_audio/just_audio.dart';

// Parent Widget
class DetailFoodNBeverages extends StatefulWidget {
  final String idTrans;
  const DetailFoodNBeverages({super.key, required this.idTrans});

  @override
  State<DetailFoodNBeverages> createState() => _DetailFoodNBeveragesState();
}

List<String> listDisc = ["0%", "15%", "25%"];
Map<String, int> itemTapCounts = {};
String? retrieveindex = '';
RxList<Map<String, dynamic>> datafnb = <Map<String, dynamic>>[].obs;

class _DetailFoodNBeveragesState extends State<DetailFoodNBeverages> {
  String dropdownDisc = listDisc.first;

  // Like React state, passing props
  List<Map<String, dynamic>> dataJual = [];

  // Function to update `dataJual` (like React's `setState`)
  void addToDataJual(Map<String, dynamic> newItem) {
    setState(() {
      final existsIndex = dataJual.indexWhere((item) => item['id_fnb'] == newItem['id_fnb']);

      if (existsIndex != -1) {
        // Jika ad, update value
        dataJual[existsIndex]['jlh'] += 1;
        dataJual[existsIndex]['harga_total'] = dataJual[existsIndex]['harga_fnb'] * dataJual[existsIndex]['jlh'];
      } else {
        // Jika g ad, tambah item baru
        dataJual.add({...newItem, 'harga_total': newItem['harga_fnb']});
      }
    });

    // Cb Komen. Klo error, uncomment
    updateUIWithDiscount();
  }
  // End Passing Props dataJual

  final formatCurrency = new NumberFormat.currency(locale: "id_ID", decimalDigits: 0, symbol: 'Rp. ');

  // Fungsi Manipulasi Harga
  TextEditingController _dialogTxtTotalFormatted = TextEditingController();
  TextEditingController _totalBayarController = TextEditingController();
  TextEditingController _kembalianController = TextEditingController();

  double _dialogTxtTotalOri = 0;
  RxInt _dialogTxtTotalStlhPjk = 0.obs;
  int _parsedTotalBayar = 0;
  int kembalian = 0;
  void _fnFormatTotalBayar(String value) {
    // Remove all non-digit characters
    String digits = value.replaceAll(RegExp(r'[^0-9]'), '');

    // Parse total bayar yang bentuk rupiah ke angka
    int numValue = int.tryParse(digits) ?? 0;
    _parsedTotalBayar = numValue;

    // Ini Harga setelah pajak
    kembalian = numValue - _dialogTxtTotalStlhPjk.value;

    // ini harga sebelum pajak
    // kembalian = numValue - _dialogTxtTotalOri.toInt();

    // Format kembali ke currency
    String formatted = formatCurrency.format(numValue);
    String formattedKembali = formatCurrency.format(kembalian);

    // Update controller tanpa trigger infinite loop
    _totalBayarController.value = TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));

    _kembalianController.value = TextEditingValue(text: formattedKembali, selection: TextSelection.collapsed(offset: formattedKembali.length));
  }

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
    int selectedDisc = listDisc.indexOf(dropdownDisc);

    // Convert to List<double>
    List<double> doubleDisc =
        listDisc.map((percentStr) {
          return double.parse(percentStr.replaceAll('%', '')) / 100;
        }).toList();

    double jlhPotongan = totalBefore * doubleDisc[selectedDisc];
    double totalStlhDisc = totalBefore - jlhPotongan;

    // tak boleh disini. error. kupisah ke updateUIWithDiscount()
    // setState(() {
    //   _dialogTxtTotalFormatted.text = formatCurrency.format(totalStlhDisc);
    //   _dialogTxtTotalOri = totalStlhDisc;
    // });

    return {"potongan": jlhPotongan, "sblm_disc": totalBefore, "stlh_disc": totalStlhDisc, "desimal_persen": doubleDisc[selectedDisc]};
  }

  // Utk Update pas pilih dropdown disc
  void updateUIWithDiscount() {
    final result = getHargaAfterDisc();
    setState(() {
      _dialogTxtTotalFormatted.text = formatCurrency.format(result["stlh_disc"]!);
      _dialogTxtTotalOri = result["stlh_disc"]!;
    });
  }

  // Manipulasi tinggi Item utk IsiFoodNBeverages. Props drilling juga
  double heightIsiData = 350;
  void adjustHeightData(int lengthData) {
    setState(() {
      heightIsiData = lengthData > 4 ? 350.0 : 150.0;
    });
  }
  // End Manipulasi tinggi item

  @override
  void dispose() {
    // TODO: implement dispose
    _dialogTxtTotalFormatted.dispose();
    _totalBayarController.dispose();
    _kembalianController.dispose();
    _namaAkun.dispose();
    _noRek.dispose();
    _namaBank.dispose();
    super.dispose();
  }

  RxBool isCash = true.obs;
  RxBool isDebit = false.obs;
  RxBool isQris = false.obs;
  TextEditingController _namaAkun = TextEditingController();
  TextEditingController _noRek = TextEditingController();
  TextEditingController _namaBank = TextEditingController();

  RxDouble desimalPjk = 0.0.obs;
  Future<void> _getPajak() async {
    try {
      var response = await dio.get('${myIpAddr()}/pajak/getpajak');

      // Parse the first record (assumes response is a list of maps)
      List<dynamic> data = response.data;
      if (data.isNotEmpty) {
        var firstRecord = data[0];
        double pjk = double.tryParse(firstRecord['pajak_fnb'].toString()) ?? 0.0;

        desimalPjk.value = pjk;
      } else {
        throw Exception("Empty data received");
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception("Error Get Pajak Dio ${e.response?.data}");
      }
      throw Exception("Error Get Pajak $e");
    }
  }

  void _showDialogConfirmPayment(BuildContext context) async {
    await _getPajak();
    log("Isi Desimal Pajak Fnb = ${desimalPjk.value}");

    List<String> metodeByr = ["Cash", "Debit", "QRIS"];
    RxString dropdownByr = metodeByr.first.obs;

    Get.dialog(
      AlertDialog(
        title: Text("Pembayaran", textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Poppins')),
        content: SingleChildScrollView(
          child: SizedBox(
            width: Get.width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: Padding(padding: const EdgeInsets.only(top: 20), child: Text("Harga: ", style: TextStyle(fontFamily: 'Poppins')))),
                    Expanded(flex: 3, child: TextField(controller: _dialogTxtTotalFormatted, readOnly: true)),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: Padding(padding: const EdgeInsets.only(top: 5), child: Text("Pajak: ", style: TextStyle(fontFamily: 'Poppins')))),
                    Obx(
                      () =>
                          Expanded(flex: 3, child: TextField(controller: TextEditingController(text: "${(desimalPjk.value * 100).toInt()}%"), readOnly: true)),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: Padding(padding: const EdgeInsets.only(top: 5), child: Text("Total Harga: ", style: TextStyle(fontFamily: 'Poppins')))),
                    Obx(() {
                      double nominalPjk = _dialogTxtTotalOri * desimalPjk.value;
                      double txtPjkBlmRound = _dialogTxtTotalOri + nominalPjk;

                      // Bulatkan ke ribuan terdekat
                      _dialogTxtTotalStlhPjk.value = (txtPjkBlmRound / 1000).round() * 1000;

                      return Expanded(
                        flex: 3,
                        child: TextField(controller: TextEditingController(text: formatCurrency.format(_dialogTxtTotalStlhPjk.value)), readOnly: true),
                      );
                    }),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: Text("Metode Pembayaran: ", style: TextStyle(fontFamily: 'Poppins'))),
                    Expanded(
                      flex: 3,
                      child: Obx(
                        () => DropdownButton<String>(
                          value: dropdownByr.value,
                          elevation: 16,
                          style: const TextStyle(color: Colors.deepPurple),
                          onChanged: (String? val) {
                            // dipanggil kalo user select metode byr
                            switch (val) {
                              case "Cash":
                                isCash.value = true;
                                isDebit.value = false;
                                isQris.value = false;
                                break;
                              case "Debit":
                                isDebit.value = true;
                                isCash.value = false;
                                isQris.value = false;
                                break;

                              case "QRIS":
                                isQris.value = true;
                                isCash.value = false;
                                isDebit.value = false;
                                break;
                            }

                            _totalBayarController.clear();
                            _kembalianController.clear();
                            kembalian = 0;

                            dropdownByr.value = val!;
                          },
                          icon: SizedBox.shrink(),
                          items:
                              metodeByr.map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem(value: value, child: AutoSizeText(value, minFontSize: 20));
                              }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                Obx(() {
                  if (isCash.value) {
                    return Column(
                      children: [
                        SizedBox(height: 30),
                        Row(children: [Text("Rincian Biaya", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'))]),
                        Row(
                          children: [
                            Expanded(
                              child: Padding(padding: const EdgeInsets.only(top: 20), child: Text("Total Bayar: ", style: TextStyle(fontFamily: 'Poppins'))),
                            ),
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: _totalBayarController,
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
                              child: Padding(padding: const EdgeInsets.only(top: 20), child: Text("Kembalian: ", style: TextStyle(fontFamily: 'Poppins'))),
                            ),
                            Expanded(flex: 3, child: TextField(controller: _kembalianController, readOnly: true)),
                          ],
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      SizedBox(height: 30),
                      Row(children: [Text("Informasi Bank Pemilik", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'))]),
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
                          Expanded(flex: 3, child: TextField(controller: _namaBank)),
                        ],
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (isCash.value) {
                if (_totalBayarController.text == "" ||
                    _totalBayarController.text.isEmpty ||
                    _totalBayarController.text == "0") {
                  return;
                }
              }

              if (kembalian < 0) {
                CherryToast.error(
                  title: Text("Jumlah Bayar Kurang", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                  animationDuration: const Duration(milliseconds: 1500),
                  autoDismiss: true,
                ).show(context);
              } else {
                _storeTrans().then((_) {
                  Get.offAll(() => MainResepsionis());
                });
              }
            },
            child: Text("Proses Pembayaran", style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    ).then((_) {
      isCash.value = true;
      isDebit.value = false;
      isQris.value = false;
      _totalBayarController.clear();
      _kembalianController.clear();
      _namaAkun.clear();
      _noRek.clear();
      _namaBank.clear();
    });
  }

  var dio = Dio();

  Future<void> _storeTrans() async {
    try {
      var rincian = getHargaAfterDisc();
      var token = await getTokenSharedPref();
      var data = {
        "id_transaksi": widget.idTrans,
        "total_harga": rincian['sblm_disc'],
        "disc": rincian['desimal_persen'],
        "grand_total": rincian['stlh_disc'],
        "jumlah_bayar": _parsedTotalBayar,
        "detail_trans": dataJual,
      };

      if (isCash.value) {
        data['metode_pembayaran'] = "cash";
        data['jumlah_bayar'] = _parsedTotalBayar;
      } else {
        data['metode_pembayaran'] = isQris.value ? "qris" : "debit";
        data['jumlah_bayar'] = _dialogTxtTotalStlhPjk.value;
        data['nama_akun'] = _namaAkun.text;
        data['no_rek'] = _noRek.text;
        data['nama_bank'] = _namaBank.text;
      }

      data['pajak'] = desimalPjk.value;
      data['gtotal_stlh_pajak'] = _dialogTxtTotalStlhPjk.value;

      var response = await dio.post('${myIpAddr()}/fnb/store', options: Options(headers: {"Authorization": "Bearer " + token!}), data: data);
      log("Isi data jual $dataJual");
      log("Sukses SImpan $response");
      CherryToast.success(
        title: Text("Transaksi Sukses!", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
        animationDuration: const Duration(milliseconds: 2000),
        autoDismiss: true,
      ).show(context);
    } catch (e) {
      if (e is DioException) {
        log("Error fn storeTrans ${e.response!.data}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  Stack(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 15, top: 15),
                          child: IconButton(
                            icon: Icon(Icons.arrow_back, size: 40), // Back Icon
                            onPressed: () {
                              Get.back(); // Navigate back
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 30),
                      Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 25),
                          child: Text(
                            "Food & Beverages",
                            style: TextStyle(color: Colors.black, fontSize: 30, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 30),
              Column(
                children: [
                  // Child Widget, Ini Utk Terima Fungsi addToDataJual
                  SizedBox(height: heightIsiData, child: IsiFoodNBeverages(onAddItem: addToDataJual, onHeightLength: adjustHeightData)),
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.only(left: 10, top: 15),
                    height: Get.height - 250,
                    width: Get.width - 200,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(flex: 1, child: AutoSizeText("No Loker", minFontSize: 18, style: TextStyle(fontFamily: 'Poppins'))),
                            Flexible(child: AutoSizeText(" : ", minFontSize: 18, style: TextStyle(fontFamily: 'Poppins'))),
                            Expanded(flex: 6, child: AutoSizeText("1", minFontSize: 18, style: TextStyle(fontFamily: 'Poppins'))),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(flex: 1, child: AutoSizeText("Resepsionis", minFontSize: 18, style: TextStyle(fontFamily: 'Poppins'))),
                            Flexible(child: AutoSizeText(" : ", minFontSize: 18, style: TextStyle(fontFamily: 'Poppins'))),
                            Expanded(flex: 6, child: AutoSizeText("Yuni", minFontSize: 18, style: TextStyle(fontFamily: 'Poppins'))),
                          ],
                        ),
                        SizedBox(height: 10),
                        Center(
                          child: Row(
                            children: [
                              Expanded(child: Text("Nama Item", style: TextStyle(fontFamily: 'Poppins'))),
                              Expanded(
                                child: Padding(padding: const EdgeInsets.only(left: 18), child: Text("Jumlah", style: TextStyle(fontFamily: 'Poppins'))),
                              ),
                              Expanded(child: Text("Satuan", style: TextStyle(fontFamily: 'Poppins'))),
                              Expanded(child: Text("Harga", style: TextStyle(fontFamily: 'Poppins'))),
                              Expanded(child: Text("Total", style: TextStyle(fontFamily: 'Poppins'))),
                              Flexible(child: Text("")),
                            ],
                          ),
                        ),
                        // Ini Juga Child Component. Derajatnya
                        DataTransaksiFood(dataJual: dataJual, onChangeHrg: updateUIWithDiscount),
                        Divider(),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: Text("")),
                            Expanded(child: Text("")),
                            Expanded(child: Text("")),
                            Expanded(child: Text("Jumlah", style: TextStyle(fontFamily: 'Poppins'))),
                            Expanded(child: Text("${formatCurrency.format(getHargaBeforeDisc())}", style: TextStyle(fontFamily: 'Poppins'))),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(child: Text("")),
                            Expanded(child: Text("")),
                            Expanded(child: Text("")),
                            Expanded(child: Text("Total", style: TextStyle(fontFamily: 'Poppins'))),
                            Expanded(child: Text("${formatCurrency.format(getHargaAfterDisc()['stlh_disc'])}", style: TextStyle(fontFamily: 'Poppins'))),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 10),

                  Container(
                    width: MediaQuery.of(context).size.width - 200,
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () {
                              _showDialogConfirmPayment(context);
                            },
                            child: Text("Konfirmasi Pembayaran", style: TextStyle(fontFamily: 'Poppins')),
                          ),
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

class IsiFoodNBeverages extends StatefulWidget {
  final Function(Map<String, dynamic>) onAddItem;
  // onHeightLength mainkan function tinggi data.
  final Function(int) onHeightLength;

  const IsiFoodNBeverages({super.key, required this.onAddItem, required this.onHeightLength});

  @override
  State<IsiFoodNBeverages> createState() => _IsiFoodNBeveragesState();
}

class _IsiFoodNBeveragesState extends State<IsiFoodNBeverages> {
  ScrollController _scrollController = ScrollController();
  var dio = Dio();

  List<Map<String, dynamic>> dataMenu = [];

  Future<void> _getMenu() async {
    try {
      var token = await getTokenSharedPref();

      var response = await dio.get('${myIpAddr()}/fnb/menu', options: Options(headers: {"Authorization": "Bearer " + token!}));

      setState(() {
        dataMenu =
            (response.data as List).map((item) {
              return {
                'id_fnb': item['id_fnb'],
                'kategori': item['kategori'],
                'nama_fnb': item['nama_fnb'],
                'status_fnb': item['status_fnb'],
                'harga_fnb': item['harga_fnb'],
              };
            }).toList();
      });

      // Call this once, after menu is loaded. utk adjust tinggi gridview builder
      widget.onHeightLength(dataMenu.length);

      // log("Response Menu $dataMenu");
    } catch (e) {
      log("Error di fn Get Menu $e");
    }
  }

  Future<void> getdatafnb() async {
    try {
      var response = await dio.get('${myIpAddr()}/listfnb/getdatafnb');
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "id_fnb": item['id_fnb'],
              "id_kategori": item['id_kategori'],
              "nama_fnb": item['nama_fnb'],
              "harga_fnb": item['harga_fnb'],
              "stok_fnb": item['stok_fnb'],
              "status_fnb": item['status_fnb'],
              "nama_kategori": item['nama_kategori'],
            };
          }).toList();
      setState(() {
        datafnb.clear();
        datafnb.assignAll(fetcheddata);
        datafnb.refresh();
      });
    } catch (e) {
      log("Error di fn getdatafnb : $e");
    }
  }

  // Utk Animasi Dipencet
  List<bool> _itemTapStates = [];

  @override
  void initState() {
    // TODO: implement initState

    super.initState();
    _getMenu().then((_) {
      // Init Tap States
      // Params 1 = Panjang isi data, Params 2 isi datanya. isi semuanya false;
      _itemTapStates = List.filled(dataMenu.length, false);
      _loadSound();
    });
    getdatafnb();
    itemTapCounts.clear();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _scrollController.dispose();
    super.dispose();
  }

  AudioPlayer _audioPlayer = AudioPlayer();

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
  Widget build(BuildContext context) {
    // final List<Map<String, dynamic>> items = List.generate(14, (index) {
    //   return {
    //     "name": "Item ${index + 1}",
    //     "price": "Rp. ${(index + 1) * 10}.000",
    //     "icon": Icons.fastfood,
    //   };
    // });

    // Cegah biar g error
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   widget.onHeightLength(dataMenu.length);
    // });

    return Scrollbar(
      thumbVisibility: true,
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Container(
          // Asumsi Kalo Kontenny Banyak
          // height: dataMenu.length > 5 ? Get.height + 40 : 150.0,
          width: Get.width - 200,
          child: Column(
            children: [
              // Pake gridview builder daripada make row manual.
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 30,
                  mainAxisSpacing: 25,
                  childAspectRatio: 2 / 1.5,
                ),
                itemCount: dataMenu.length,
                itemBuilder: (context, index) {
                  final item = dataMenu[index];
                  bool isPressed = false; // Local state for each item
                  int sisastok = 0;
                  return StatefulBuilder(
                    builder: (context, setState) {
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (_) => setState(() => isPressed = true),
                        onTapUp: (_) async {
                          await _playClickSound();

                          await Future.delayed(const Duration(milliseconds: 100)); // Give time for press animation
                          setState(() => isPressed = false);

                          for (var fnb in datafnb.where((p) => p['nama_fnb'] == item['nama_fnb'])) {
                            sisastok = int.tryParse(fnb['stok_fnb'].toString()) ?? 0;
                          }

                          String itemname = item['nama_fnb'];

                          retrieveindex = itemname;
                          if (retrieveindex != null && itemTapCounts.containsKey(retrieveindex)) {
                            itemTapCounts[retrieveindex!] = itemTapCounts[retrieveindex]! + 1;
                          } else if (retrieveindex != null) {
                            itemTapCounts[retrieveindex!] = 1;
                          }
                          log('counter : $itemTapCounts');

                          if (sisastok == 0) {
                            CherryToast.error(title: Text('Error'), description: Text('Stok sudah kosong')).show(context);
                          } else if (retrieveindex != null) {
                            if (itemTapCounts[retrieveindex]! > sisastok) {
                              CherryToast.error(title: Text('Error'), description: Text('Penggunaan item melebihi stok')).show(context);
                            } else {
                              widget.onAddItem({
                                "id_fnb": item['id_fnb'],
                                "kategori": item['kategori'],
                                "nama_fnb": item['nama_fnb'],
                                "status_fnb": item['status_fnb'],
                                "jlh": 1,
                                "satuan": "PCS",
                                "harga_fnb": item['harga_fnb'],
                                "harga_total": item['harga_fnb'],
                              });
                            }
                          }
                        },
                        onTapCancel: () => setState(() => isPressed = false),
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 100),
                          curve: Curves.easeOut,
                          scale: isPressed ? 0.85 : 1.0,
                          child: Container(
                            decoration: BoxDecoration(color: const Color.fromARGB(255, 64, 97, 55), borderRadius: BorderRadius.circular(20)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.fastfood, size: 50, color: Colors.white),
                                Text(item['nama_fnb'], style: const TextStyle(color: Colors.white, fontSize: 16)),
                                Text("Rp. ${item['harga_fnb']}", style: const TextStyle(color: Colors.white, fontSize: 16)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DataTransaksiFood extends StatefulWidget {
  final List dataJual;
  final Function onChangeHrg;

  const DataTransaksiFood({super.key, required this.dataJual, required this.onChangeHrg});

  @override
  State<DataTransaksiFood> createState() => _DataTransaksiFoodState();
}

class _DataTransaksiFoodState extends State<DataTransaksiFood> {
  final formatCurrency = new NumberFormat.currency(locale: "id_ID", decimalDigits: 0, symbol: 'Rp. ');

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: widget.dataJual.length,
        itemBuilder: (context, index) {
          int sisastok = 0;
          return Row(
            children: [
              Expanded(child: AutoSizeText(widget.dataJual[index]['nama_fnb'], minFontSize: 15)),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove, size: 18),
                      onPressed: () {
                        setState(() {
                          for (var produk in datafnb.where((p) => p['nama_fnb'] == widget.dataJual[index]['nama_fnb'])) {
                            sisastok = int.tryParse(produk['stok_fnb'].toString()) ?? 0;
                          }
                          String itemname = widget.dataJual[index]['nama_fnb'];
                          retrieveindex = itemname;

                          if (retrieveindex != null && itemTapCounts.containsKey(retrieveindex)) {
                            if (retrieveindex != null && itemTapCounts[retrieveindex]! <= 1) {
                              itemTapCounts[retrieveindex!] = 1;
                            } else if (retrieveindex != null && itemTapCounts[retrieveindex]! >= sisastok) {
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

                          if (widget.dataJual[index]['jlh'] > 1) {
                            widget.dataJual[index]['jlh']--;
                            // Update Harga Total Juga
                            widget.dataJual[index]['harga_total'] = widget.dataJual[index]['harga_fnb'] * widget.dataJual[index]['jlh'];
                          }
                        });

                        // kalo mw trigger function, tambah kurung ().
                        widget.onChangeHrg();
                      },
                    ),
                    Container(padding: EdgeInsets.symmetric(horizontal: 8), child: AutoSizeText("${widget.dataJual[index]['jlh']}", minFontSize: 15)),
                    IconButton(
                      icon: Icon(Icons.add, size: 18),
                      onPressed: () {
                        setState(() {
                          for (var produk in datafnb.where((p) => p['nama_fnb'] == widget.dataJual[index]['nama_fnb'])) {
                            sisastok = int.tryParse(produk['stok_fnb'].toString()) ?? 0;
                          }
                          String itemname = widget.dataJual[index]['nama_fnb'];
                          retrieveindex = itemname;
                          if (retrieveindex != null && itemTapCounts.containsKey(retrieveindex)) {
                            itemTapCounts[retrieveindex!] = itemTapCounts[retrieveindex]! + 1;
                          } else if (retrieveindex != null) {
                            itemTapCounts[retrieveindex!] = 1;
                          }
                          log('counter : $itemTapCounts');
                          if (sisastok == 0) {
                            CherryToast.error(title: Text('Error'), description: Text('Stok sudah kosong')).show(context);
                          } else if (retrieveindex != null) {
                            if (itemTapCounts[retrieveindex]! > sisastok) {
                              CherryToast.error(title: Text('Error'), description: Text('Penggunaan item melebihi stok')).show(context);
                            } else {
                              widget.dataJual[index]['jlh']++;
                              // Update Harga Total Juga
                              widget.dataJual[index]['harga_total'] = widget.dataJual[index]['harga_fnb'] * widget.dataJual[index]['jlh'];
                            }
                          }
                        });

                        widget.onChangeHrg();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(child: AutoSizeText(widget.dataJual[index]['satuan'], minFontSize: 15)),
              Expanded(child: AutoSizeText("${formatCurrency.format(widget.dataJual[index]['harga_fnb'])}", minFontSize: 15)),
              Expanded(child: Text("${formatCurrency.format(widget.dataJual[index]['harga_total'])}", style: TextStyle(fontFamily: 'Poppins'))),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(Icons.delete, size: 18),
                        onPressed: () {
                          setState(() {
                            for (var produk in datafnb.where((p) => p['nama_fnb'] == widget.dataJual[index]['nama_fnb'])) {
                              sisastok = int.tryParse(produk['stok_fnb'].toString()) ?? 0;
                            }
                            if (retrieveindex != null) {
                              String itemname = widget.dataJual[index]['nama_fnb'];
                              retrieveindex = itemname;
                              itemTapCounts[retrieveindex!] = 0;
                            }

                            widget.dataJual.removeAt(index);
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
