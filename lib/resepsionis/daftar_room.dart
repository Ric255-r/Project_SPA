// ignore_for_file: camel_case_types, prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:async';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:Project_SPA/function/ip_address.dart';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

class daftarRoom extends StatefulWidget {
  const daftarRoom({super.key});

  @override
  State<daftarRoom> createState() => _daftarRoomState();
}

class _daftarRoomState extends State<daftarRoom> {
  RxList<Map<String, dynamic>> dataruangan = <Map<String, dynamic>>[].obs;
  var dio = Dio();
  var statusruangan = 0;

  SharedPreferences? _prefs;
  Timer? _timer;
  int durasi = 0; //kalo mau lanjut dari container buat 0
  int jam = 0;
  int menit = 0;
  int detik = 0;
  bool _istimerunning = false;
  RxMap<dynamic, dynamic> durasimap = {}.obs;

  // void _startNewTimer() async {
  //   final now = DateTime.now();
  //   _prefs = await SharedPreferences.getInstance();
  //   await _prefs?.setString('new_timer_TerapisBekerja', now.toIso8601String());

  //   setState(() {
  //     _istimerunning = true;
  //   });

  //   _startcountdown();
  // }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startcountdown() {
    _timer?.cancel(); // Ensure we stop previous timers
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      durasimap.value = durasimap.map((koderuangan, remainingtime) {
        if (remainingtime > 0) {
          return MapEntry(koderuangan, remainingtime - 1);
        }
        return MapEntry(koderuangan, remainingtime);
      });
      _istimerunning = true;
    });
  }

  Future<void> getdataruangan() async {
    try {
      var response = await dio.get('${myIpAddr()}/ruangan/getdataruangan');
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "kode_ruangan": item['kode_ruangan'],
              "nama_ruangan": item['nama_ruangan'],
              "status": item['status'],
              "sum_durasi_menit": item['sum_durasi_menit'],
            };
          }).toList();
      setState(() {
        dataruangan.clear();
        dataruangan.assignAll(fetcheddata);
        dataruangan.refresh();
      });
    } catch (e) {
      log("Error di fn Getdapaketmassage : $e");
    }
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

  Future<void> refreshdataruangan() async {
    await Future.delayed(Duration(seconds: 1));
    await getdataruangan();
  }

  String capitalize(String? text) {
    if (text == null || text.isEmpty) return "Unknown"; // Handle null or empty
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  void initState() {
    refreshdataruangan().then((_) {
      log(dataruangan.toString());

      if (dataruangan.isNotEmpty) {
        for (var item in dataruangan) {
          durasimap[item['kode_ruangan']] =
              (item['sum_durasi_menit'] * 60 ?? 0);
        }
      }
    });
    super.initState();
    log(dataruangan.toString());

    _startcountdown();
  }

  var i = 1;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: AutoSizeText(
                'Daftar Room',
                style: TextStyle(fontSize: 50, fontFamily: 'Poppins'),
              ),
            ),
            SizedBox(width: 50),
            GestureDetector(
              onTap: () {
                refreshdataruangan().then((_) {
                  log(dataruangan.toString());

                  if (dataruangan.isNotEmpty) {
                    for (var item in dataruangan) {
                      durasimap[item['kode_ruangan']] =
                          (item['sum_durasi_menit'] * 60 ?? 0);
                    }
                  }
                });
              },
              child: Icon(Icons.refresh_sharp, size: 60),
            ),
          ],
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 30),
          child: IconButton(
            icon: Icon(Icons.arrow_back, size: 40), // Back Icon
            onPressed: () {
              Get.back(); // Navigate back
            },
          ),
        ),
        toolbarHeight: 90,
        backgroundColor: Color(0XFFFFE0B2),
        leadingWidth: 100,
      ),

      body: Container(
        padding: EdgeInsets.only(left: 10),
        height: Get.height,
        width: Get.width,
        decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
        child: SingleChildScrollView(
          child: Stack(
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 20),
                      // Asumsi Kalo Kontenny Banyak
                      height: Get.height - 150,
                      width: Get.width - 200,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Pake gridview builder daripada make row manual.
                            Obx(
                              () =>
                                  dataruangan.isEmpty
                                      ? Center(
                                        child: Padding(
                                          padding: EdgeInsets.only(top: 150),
                                          child: CircularProgressIndicator(),
                                        ),
                                      )
                                      : Obx(
                                        () => GridView.builder(
                                          shrinkWrap:
                                              true, // Buat dia fit ke singlechild
                                          physics:
                                              const NeverScrollableScrollPhysics(), // jgn biarin gridviewscrollsendiri
                                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount:
                                                5, // 4 Item dalam 1 Row
                                            crossAxisSpacing:
                                                25, // Space Horizontal tiap item
                                            mainAxisSpacing:
                                                25, // Space Vertical tiap item
                                            // Width to height ratio (e.g., width: 2, height: 3)
                                            childAspectRatio: 3 / 3,
                                          ),
                                          // Nanti Looping data disini
                                          itemCount: dataruangan.length,
                                          itemBuilder: (context, index) {
                                            var item = dataruangan[index];
                                            var idruangan =
                                                item['kode_ruangan'];

                                            return Obx(() {
                                              var remainingtime =
                                                  durasimap[idruangan] ?? 0;

                                              int jam = remainingtime ~/ 3600;
                                              int menit =
                                                  (remainingtime % 3600) ~/ 60;

                                              int detik = remainingtime % 60;
                                              return Container(
                                                decoration: BoxDecoration(
                                                  color:
                                                      item['status'] ==
                                                                  'occupied' &&
                                                              menit >= 10
                                                          ? Color(0xFFFF8282)
                                                          : item['status'] ==
                                                                  'occupied' &&
                                                              menit < 10 &&
                                                              menit >= 0 &&
                                                              detik > 0 &&
                                                              jam == 0
                                                          ? Colors.orange
                                                          : item['status'] ==
                                                              'aktif'
                                                          ? Color(0xFFA6FF8F)
                                                          : jam == 0 &&
                                                              menit == 0 &&
                                                              detik == 0 &&
                                                              item['status'] ==
                                                                  'maintenance'
                                                          ? Colors.cyan
                                                          : Colors.orange,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      item['nama_ruangan']
                                                          .toString(),
                                                      style: const TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 30,
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                        top: 0,
                                                      ),
                                                      child: Text(
                                                        jam == 0 &&
                                                                menit == 0 &&
                                                                detik == 0 &&
                                                                item['status'] ==
                                                                    'occupied'
                                                            ? capitalize(
                                                              'occupied',
                                                            )
                                                            : capitalize(
                                                              item['status'],
                                                            ),
                                                        style: const TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),

                                                    Container(
                                                      child: AutoSizeText(
                                                        _istimerunning
                                                            ? '$jam : ${menit.toString().padLeft(2, '0')} : ${detik.toString().padLeft(2, '0')} '
                                                            : '$jam : ${menit.toString().padLeft(2, '0')} : ${detik.toString().padLeft(2, '0')} ',
                                                        style: TextStyle(
                                                          fontSize: 20,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            });
                                          },
                                        ),
                                      ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 50),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// class roomtitle extends StatefulWidget {
//   final String title;
//   final int nomor;
//   const roomtitle({super.key, required this.title, required this.nomor});

//   @override
//   State<roomtitle> createState() => _roomState();
// }

// class _roomState extends State<roomtitle> {
//   Color _backgroundcolor = const Color(0xFFEEEEEE);
//   int nomorbox = 1;
//   SharedPreferences? _prefs;
//   Timer? _timer;
//   int durasi = 0;
//   int jam = 0;
//   int menit = 0;
//   int detik = 0;
//   bool _istimerunning = false;

//   late String backgroundcolorkey;
//   late String savedtimerkey;

//   @override
//   void initState() {
//     super.initState();
//     backgroundcolorkey =
//         'room_background_${widget.title}'; // variabel untuk menentukan warna background yang mana sesuai ttile
//     savedtimerkey =
//         'start_timer_${widget.title}'; //variabel untuk menentukan waktu container yang akan disimpan sesuai title
//     nomorbox = widget.nomor;
//     _loaddata();
//   }

//   void _loaddata() async {
//     _prefs = await SharedPreferences.getInstance();
//     final int? Storedbackgroundcolor = _prefs?.getInt(
//       backgroundcolorkey,
//     ); // variabel simpan data yang diambil dari backgroundcolorkey
//     final String? storedtimer = _prefs?.getString(
//       savedtimerkey,
//     ); // variabel simpan data yang diambil dari waktu mulai container

//     if (storedtimer != null) {
//       //Kalau variabel storedtimer tidak kosong alias ada waktu yang tersimpan
//       DateTime starttime = DateTime.parse(
//         storedtimer,
//       ); //memasukkan data waktu storedtimer yang awalnya berupa string ke varianbel startime berupa waktu
//       //ambil jam pada perangkat untuk menyesuaikan pengurangan waktu
//       DateTime now = DateTime.now();
//       //menentukan berapa lama detik yang sudah terlewatkan sesuai dengan perangkat
//       int elapsedSeconds = now.difference(starttime).inSeconds;
//       // Calculate remaining waktu
//       int remainingSeconds = int.parse("10") - elapsedSeconds;

//       setState(() {
//         durasi =
//             remainingSeconds > 0
//                 ? remainingSeconds
//                 : 0; //simpan remainingsecond ke durasi dan lakukan pengecekan pada remaining second untuk simpan ke durasi
//         _istimerunning =
//             durasi > 0; //kalo durasi lebih dari 0, set istimerunning jadi true
//         _backgroundcolor =
//             durasi > 0
//                 ? Colors.green
//                 : Colors
//                     .red; //kalo durasi lebih dari 0 set warna background jadi hijau, kalo 0 set background jadi merah
//       });

//       if (_istimerunning) {
//         //ngecek apakah ada waktu yang berjalan
//         _resumetime(); //jalankan function resumetime
//       } else if (Storedbackgroundcolor != null) {
//         setState(() {
//           _backgroundcolor = Color(Storedbackgroundcolor);
//         });
//       }
//     }
//   }

//   void _starttimer() async {
//     final now = DateTime.now();
//     await _prefs?.setString(savedtimerkey, now.toIso8601String());
//     setState(() {
//       _istimerunning = true;
//       durasi = int.parse("10");
//       _backgroundcolor = Colors.green;
//     });
//     _resumetime();
//   }

//   void _resumetime() {
//     _timer
//         ?.cancel(); //matikan waktu yang udah di set sebelumnya untuk set waktu baru
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (durasi > 0) {
//         setState(() {
//           durasi--; //mengurangi 1 setiap waktu yang ditentukan
//           jam = durasi ~/ 3600; //pecah detik ke jam
//           menit = (durasi % 3600) ~/ 60; //pecah detik kemenit
//           detik = durasi % 60;
//         });
//       } else {
//         _timer?.cancel(); //kalo durasi waktunya udah 0, timernya dimatikan
//         setState(() {
//           _istimerunning = false; //
//           _backgroundcolor =
//               Colors.red; // Timer selesai, ganti warna jadi merah
//         });
//       }
//     });
//   }

//   void _openclick() {
//     setState(() {
//       if (!_istimerunning) {
//         _starttimer();
//       }
//     });
//   }

  // @override
  // void dispose() {
  //   _timer?.cancel();
  //   super.dispose();
  // }

//   void _resetTimer() async {
//     await _prefs?.remove(savedtimerkey); // Remove stored time
//     await _prefs?.remove(backgroundcolorkey); // Remove stored background color

//     setState(() {
//       _istimerunning = false;
//       durasi = 0;
//       jam = 0;
//       menit = 0;
//       detik = 0;
//       _backgroundcolor = const Color(
//         0xFFEEEEEE,
//       ); // Reset to default background color
//     });

//     _timer?.cancel(); // Stop any running timer
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 205,
//       height: 250,
//       child: GestureDetector(
//         onDoubleTap: () {
//           _resetTimer();
//         }, // reset timer ketika diklik 2 kali, hanya untuk presentasi
//         child: Container(
//           margin: EdgeInsets.only(left: 55, top: 100),
//           decoration: BoxDecoration(
//             border: Border.all(width: 0),
//             color: _backgroundcolor,
//             borderRadius: BorderRadius.all(Radius.circular(20)),
//           ),
//           child: InkWell(
//             onTap: _openclick,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Center(
//                   child: Container(
//                     margin: EdgeInsets.only(top: 20),
//                     child: Icon(Icons.room_service, size: 45),
//                   ),
//                 ),
//                 Center(
//                   child: Container(
//                     margin: EdgeInsets.only(top: 0),
//                     padding: EdgeInsets.only(top: 5),
//                     child: Text(
//                       'Room $nomorbox',
//                       style: TextStyle(fontSize: 20, fontFamily: 'Poppins'),
//                     ),
//                   ),
//                 ),
//                 Center(
//                   child: Container(
//                     child: AutoSizeText(
//                       _istimerunning
//                           ? '$jam : ${menit.toString().padLeft(2, '0')} : ${detik.toString().padLeft(2, '0')} '
//                           : '$jam : ${menit.toString().padLeft(2, '0')} : ${detik.toString().padLeft(2, '0')} ',
//                       style: TextStyle(
//                         fontSize: 30,
//                         fontWeight: FontWeight.bold,
//                         fontFamily: 'Poppins',
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
