// ignore_for_file: camel_case_types, prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:async';
import 'package:Project_SPA/kamar_terapis/terapis_confirm.dart';
import 'package:Project_SPA/resepsionis/detail_fnb_addon.dart';
import 'package:Project_SPA/resepsionis/store_locker.dart';
import 'package:Project_SPA/resepsionis/transaksi_massage.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:Project_SPA/resepsionis/jenis_transaksi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Project_SPA/function/ip_address.dart';
import 'dart:developer';

class BillingLocker extends StatefulWidget {
  const BillingLocker({super.key});

  @override
  State<BillingLocker> createState() => _BillingLockerState();
}

class _BillingLockerState extends State<BillingLocker> {
  var i = 1;

  var dio = Dio();

  int statusloker = 0;

  RxList<Map<String, dynamic>> databillinglocker = <Map<String, dynamic>>[].obs;

  final LockerManager _lockerManager = LockerManager();
  
  Future<void> getdatabillinglocker() async {
    try {
      var response = await dio.get('${myIpAddr()}/billinglocker/getdatalocker');
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "id_loker": item['id_loker'],
              "nomor_locker": item['nomor_locker'],
              "status": item['status'],
            };
          }).toList();
      setState(() {
        databillinglocker.clear();
        databillinglocker.assignAll(fetcheddata);
        databillinglocker.refresh();
      });
    } catch (e) {
      log("Error di fn Getdapaketmassage : $e");
    }
  }

  String formatIndonesianDate(DateTime date) {
    final months = [
      "Januari",
      "Februari",
      "Maret",
      "April",
      "Mei",
      "Juni",
      "Juli",
      "Agustus",
      "September",
      "Oktober",
      "November",
      "Desember",
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> updatedataloker(statusloker, nomor_locker) async {
    try {
      var response = await dio.put(
        '${myIpAddr()}/billinglocker/updatelocker',
        data: {"status": statusloker, "nomor_locker": nomor_locker},
      );
    } catch (e) {
      log("Error di fn Getdapaketmassage : $e");
    }
  }

  Future<void> refreshdatabillinglocker() async {
    await Future.delayed(Duration(seconds: 1));
    await getdatabillinglocker();
  }

  @override
  void initState() {
    refreshdatabillinglocker();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Billing Locker ${formatIndonesianDate(DateTime.now())}',
          style: TextStyle(fontSize: 50, fontFamily: 'Poppins'),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: IconButton(
            icon: Icon(Icons.arrow_back, size: 40), // Back Icon
            onPressed: () {
              Get.back(); // Navigate back
            },
          ),
        ),
        leadingWidth: 100,
        centerTitle: true,
        toolbarHeight: 130,
        backgroundColor: Color(0XFFFFE0B2),
        automaticallyImplyLeading: false,
      ),
      body: Container(
        padding: EdgeInsets.only(left: 10),
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
        child: SingleChildScrollView(
          child: Stack(
            children: [
              Column(
                children: [
                  Center(
                    child: Container(
                      // Asumsi Kalo Kontenny Banyak
                      height: Get.height - 150,
                      width: Get.width - 200,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Pake gridview builder daripada make row manual.
                            Obx(
                              () =>
                                  databillinglocker.isEmpty
                                      ? Center(
                                        child: Padding(
                                          padding: EdgeInsets.only(top: 150),
                                          child: CircularProgressIndicator(),
                                        ),
                                      )
                                      : GridView.builder(
                                        shrinkWrap:
                                            true, // Buat dia fit ke singlechild
                                        physics:
                                            const NeverScrollableScrollPhysics(), // jgn biarin gridviewscrollsendiri
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount:
                                                  5, // 4 Item dalam 1 Row
                                              crossAxisSpacing:
                                                  25, // Space Horizontal tiap item
                                              mainAxisSpacing:
                                                  25, // Space Vertical tiap item
                                              // Width to height ratio (e.g., width: 2, height: 3)
                                              childAspectRatio: 2 / 2,
                                            ),
                                        // Nanti Looping data disini
                                        itemCount: databillinglocker.length,
                                        itemBuilder: (context, index) {
                                          var item = databillinglocker[index];
                                          return Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onLongPress: () async {
                                                final nomorLocker =
                                                    item['nomor_locker'];

                                                try {
                                                  final response = await dio.get(
                                                    "${myIpAddr()}/fnb/latestidTrans/$nomorLocker",
                                                  );

                                                  final idTransaksi =
                                                      response
                                                          .data['id_transaksi'];

                                                  if (idTransaksi != null) {
                                                    // Optional: Store locker if still needed
                                                    _lockerManager.addLocker(
                                                      int.parse(nomorLocker),
                                                    );

                                                    Get.to(
                                                      () => DetailFnbAddon(
                                                        idTrans: idTransaksi,
                                                      ),
                                                    );
                                                    log(idTransaksi);
                                                  } else {
                                                    Get.snackbar(
                                                      "Tidak ditemukan",
                                                      "Belum ada transaksi untuk locker ini.",
                                                    );
                                                  }
                                                } catch (e) {
                                                  print(
                                                    "Error fetching transaksi: $e",
                                                  );
                                                  Get.snackbar(
                                                    "Error",
                                                    "Gagal mengambil transaksi.",
                                                  );
                                                }
                                              },

                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color:
                                                      item['status'] == 0
                                                          ? Color(0xFFEEEEEE)
                                                          : Color(0xFFA6FF8F),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      'Locker ${item['nomor_locker'].toString()}',
                                                      style: const TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 30,
                                                        fontFamily: 'Poppins',
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                        top: 0,
                                                      ),
                                                      child: Text(
                                                        item['status'] == 0
                                                            ? 'Not Occupied'
                                                            : 'Occupied',
                                                        style: const TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 16,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        // statusloker = item['status'];
                                                        // statusloker = 0;
                                                        // updatedataloker(
                                                        //   statusloker,
                                                        //   item['nomor_locker'],
                                                        // );

                                                        if (item['status'] ==
                                                            0) {
                                                          _lockerManager.addLocker(
                                                            int.parse(
                                                              item['nomor_locker'],
                                                            ),
                                                          );

                                                          Get.to(
                                                            () =>
                                                                JenisTransaksi(),
                                                          );
                                                        } else {
                                                          // Balikin Lg Ke Non-Occupied
                                                          updatedataloker(
                                                            0,
                                                            item['nomor_locker'],
                                                          );
                                                        }
                                                        refreshdatabillinglocker();
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            item['status'] == 0
                                                                ? Color(
                                                                  0xFFA6FF8F,
                                                                )
                                                                : Color(
                                                                  0xFFFF8282,
                                                                ),
                                                      ),
                                                      child: Text(
                                                        item['status'] == 0
                                                            ? 'Open'
                                                            : 'Close',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Container(
                  //   margin: EdgeInsets.only(top: 40),
                  //   height: 80,
                  //   width: 200,
                  //   child: ElevatedButton(
                  //     onPressed: () {
                  //       _resetlocker();
                  //     },
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: Colors.red,
                  //     ),
                  //     child: Text(
                  //       'Reset Locker',
                  //       style: TextStyle(
                  //         fontSize: 20,
                  //         color: Colors.black,
                  //         fontFamily: 'Poppins',
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  // SizedBox(height: 40),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class containertitle extends StatefulWidget {
  final String title;
  final int nomor;
  const containertitle({super.key, required this.title, required this.nomor});

  @override
  State<containertitle> createState() => _containerState();
}

class _containerState extends State<containertitle> {
  Color _buttonopencolor = Color(0xFFA6FF8F);
  Color _backgroundcolor = const Color(0xFFEEEEEE);
  String _buttontext = 'Open';
  int nomorbox = 1;
  SharedPreferences? _prefs;

  late String backgroundcolorkey;
  late String buttoncolorkey;
  late String buttontextkey;
  @override
  void initState() {
    super.initState();

    backgroundcolorkey = 'billing_background_${widget.title}';
    buttoncolorkey = 'button_color_${widget.title}';
    buttontextkey = 'button_text_${widget.title}';
    nomorbox = widget.nomor;
    _loadcolor();
  }

  _loadcolor() async {
    _prefs = await SharedPreferences.getInstance();
    final int? Storedbackgroundcolor = _prefs?.getInt(backgroundcolorkey);
    final int? Storedbuttoncolor = _prefs?.getInt(buttoncolorkey);
    final String? Storedbuttontext = _prefs?.getString(buttontextkey);

    setState(() {
      if (Storedbackgroundcolor != null) {
        _backgroundcolor = Color(Storedbackgroundcolor);
      }

      if (Storedbuttoncolor != null) {
        _buttonopencolor = Color(Storedbuttoncolor);
      }

      if (Storedbuttontext != null) {
        _buttontext = Storedbuttontext;
      }
    });
  }

  void openlaporan() {
    Get.dialog(
      AlertDialog(
        actions: [
          Container(
            width: Get.width - 100,
            height: Get.height - 100,
            padding: EdgeInsets.only(top: 20),
            child: ListView(
              children: [
                Center(
                  child: AutoSizeText(
                    'Laporan Billing locker $nomorbox',
                    style: TextStyle(fontSize: 40, fontFamily: 'Poppins'),
                  ),
                ),
                SizedBox(height: 30),
                Row(
                  children: [
                    Container(
                      width: 320,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AutoSizeText(
                          'No Transaksi',
                          style: TextStyle(fontSize: 35, fontFamily: 'Poppins'),
                        ),
                      ),
                    ),
                    Container(
                      width: 200,
                      margin: EdgeInsets.only(left: 20),
                      child: AutoSizeText(
                        'TB1001',
                        style: TextStyle(fontSize: 35, fontFamily: 'Poppins'),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 320,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AutoSizeText(
                          'Room',
                          style: TextStyle(fontSize: 35, fontFamily: 'Poppins'),
                        ),
                      ),
                    ),
                    Container(
                      width: 200,
                      margin: EdgeInsets.only(left: 20),
                      child: AutoSizeText(
                        'Room $nomorbox',
                        style: TextStyle(fontSize: 35, fontFamily: 'Poppins'),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 320,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AutoSizeText(
                          'Terapis',
                          style: TextStyle(fontSize: 35, fontFamily: 'Poppins'),
                        ),
                      ),
                    ),
                    Container(
                      width: 200,
                      margin: EdgeInsets.only(left: 20),
                      child: AutoSizeText(
                        'Yuni',
                        style: TextStyle(fontSize: 35, fontFamily: 'Poppins'),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 320,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AutoSizeText(
                          'Waktu Mulai',
                          style: TextStyle(fontSize: 35, fontFamily: 'Poppins'),
                        ),
                      ),
                    ),
                    Container(
                      width: 200,
                      margin: EdgeInsets.only(left: 20),
                      child: AutoSizeText(
                        '14 : 00 : 00',
                        style: TextStyle(fontSize: 35, fontFamily: 'Poppins'),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 320,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AutoSizeText(
                          'Waktu Selesai',
                          style: TextStyle(fontSize: 35, fontFamily: 'Poppins'),
                        ),
                      ),
                    ),
                    Container(
                      width: 200,
                      margin: EdgeInsets.only(left: 20),
                      child: AutoSizeText(
                        '16 : 00 : 00',
                        style: TextStyle(fontSize: 35, fontFamily: 'Poppins'),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 240,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: AutoSizeText(
                          'Jenis Paket',
                          style: TextStyle(fontSize: 35, fontFamily: 'Poppins'),
                        ),
                      ),
                    ),
                    Container(
                      width: Get.width - 500,
                      margin: EdgeInsets.only(left: 100),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 300,
                                  child: AutoSizeText(
                                    'Paket Pijit Kepala',
                                    style: TextStyle(
                                      fontSize: 35,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 200,
                                  child: AutoSizeText(
                                    'Rp. 100.000',
                                    style: TextStyle(
                                      fontSize: 35,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 120,
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.green,
                                    size: 50,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 300,
                                  child: AutoSizeText(
                                    'Paket Pijit Tangan',
                                    style: TextStyle(
                                      fontSize: 35,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 200,
                                  child: AutoSizeText(
                                    'Rp. 130.000',
                                    style: TextStyle(
                                      fontSize: 35,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 120,
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.green,
                                    size: 50,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 300,
                                  child: AutoSizeText(
                                    'Paket Pijit Kepala',
                                    style: TextStyle(
                                      fontSize: 35,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 200,
                                  child: AutoSizeText(
                                    'Rp. 150.000',
                                    style: TextStyle(
                                      fontSize: 35,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 120,
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.green,
                                    size: 50,
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
                Row(
                  children: [
                    Container(
                      width: 320,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AutoSizeText(
                          'Grand Total',
                          style: TextStyle(fontSize: 35, fontFamily: 'Poppins'),
                        ),
                      ),
                    ),
                    Container(
                      color: Colors.yellow,
                      width: 300,
                      margin: EdgeInsets.only(left: 20),
                      child: AutoSizeText(
                        'Rp. 380.000',
                        style: TextStyle(fontSize: 35, fontFamily: 'Poppins'),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 320,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AutoSizeText(
                          'Status Pembayaran',
                          style: TextStyle(fontSize: 35, fontFamily: 'Poppins'),
                        ),
                      ),
                    ),
                    Container(
                      width: 250,
                      margin: EdgeInsets.only(left: 20),
                      child: AutoSizeText(
                        'Belum Lunas',
                        style: TextStyle(fontSize: 35, fontFamily: 'Poppins'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _savestate() async {
    await _prefs?.setInt(backgroundcolorkey, _backgroundcolor.value);
    await _prefs?.setInt(buttoncolorkey, _buttonopencolor.value);
    await _prefs?.setString(buttontextkey, _buttontext);
  }

  // Timer? _timerState;

  void _openclick() {
    setState(() {
      if (_buttontext == 'Open') {
        _backgroundcolor = Color(0xFFA6FF8F);
        _buttonopencolor = Color(0xFFFF8282);
        _buttontext = 'Close';
        Get.to(() => (JenisTransaksi()));
      } else {
        _backgroundcolor = const Color(0xFFEEEEEE);
        _buttonopencolor = Color(0xFFA6FF8F);
        _buttontext = 'Open';
      }
      _savestate();
    });

    // _timerState = Timer(Duration(seconds: 1), () {
    //   Get.to(() => loginpage());
    // });
  }

  // @override
  // void dispose() {
  //   // TODO: implement dispose
  //   super.dispose();
  //   _timerState?.cancel();
  // }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        openlaporan();
      },
      child: Container(
        margin: EdgeInsets.only(left: 55, top: 100),
        decoration: BoxDecoration(
          border: Border.all(width: 1),
          color: _backgroundcolor,
        ),
        width: 150,
        height: 150,
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 20),
              child: Text('$nomorbox', style: TextStyle(fontSize: 50)),
            ),
            Container(
              margin: EdgeInsets.only(top: 0),
              width: 100,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _buttonopencolor,
                ),
                onPressed: _openclick,
                child: Text(_buttontext, style: TextStyle(fontSize: 20)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
