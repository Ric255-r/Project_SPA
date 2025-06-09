import 'dart:async';

import 'package:Project_SPA/kamar_terapis/main_kamar_terapis.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:get/get.dart';
import 'dart:io'; // For file operations
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:Project_SPA/admin/regis_promo.dart';
import 'package:Project_SPA/function/ip_address.dart';
import 'package:Project_SPA/function/me.dart';
import 'package:Project_SPA/office_boy/image_mgr.dart';
import 'package:Project_SPA/office_boy/laporan.dart';
import 'dart:developer';
import 'package:dio/dio.dart';

class MainOb extends StatefulWidget {
  final String idOb;
  final String namaOb;
  final int idRuangan;
  final String namaRuangan;
  const MainOb({
    super.key,
    required this.idOb,
    required this.namaOb,
    required this.idRuangan,
    required this.namaRuangan,
  });

  @override
  State<MainOb> createState() => _MainObState();
}

class _MainObState extends State<MainOb> {
  // Ini equivalent dgn variabel yg bs dimanipulasi dgn setstate
  // Utk Convert tipedata Rx ke tipedata biasa tinggal ambil datanya pake .value

  RxBool isBekerja = false.obs;
  Timer? countdownTimer;
  RxInt lamaWaktu = 0.obs;
  DateTime? startTime;
  RxString hourOnly = "".obs;
  int? idLaporan;

  // Class Custom di image_mgr.dart Utk Access Image
  GlobalImageManager _globalImageManager = GlobalImageManager();

  Future<void> captureImage() async {
    final picker = ImagePicker();

    final XFile? imageFile = await picker.pickImage(source: ImageSource.camera);

    if (imageFile != null) {
      // print("Image Captured ${imageFile.path}");
      // saveImageToStorage(File(imageFile.path));
      File storedImages = await saveImageToStorage(File(imageFile.path));

      // Masukkan Ke List yg global
      _globalImageManager.addImage(storedImages);

      print("Image saved: ${storedImages.path}");
      print("Total images captured: ${_globalImageManager.getImages().length}");
    } else {
      print("No Image Captured");
    }
  }

  void _displayCapturedImages() {
    for (var image in _globalImageManager.getImages()) {
      print("Image Path: ${image.path}");
    }
  }

  Future<File> saveImageToStorage(File image) async {
    // Ambil directory app
    var directory = await getApplicationDocumentsDirectory();
    var path = directory.path;

    // buat file di storage directory
    var fileName = "image_${DateTime.now().millisecondsSinceEpoch}.jpg";
    File newImage = File('$path/$fileName');

    await image.copy(newImage.path);

    print("Image Tersimpan di ${newImage.path}");
    return newImage;
  }

  void setPekerjaStart() async {
    isBekerja.value = true;

    startTime = DateTime.now();
    hourOnly.value =
        "${startTime?.hour.toString().padLeft(2, '0')}:"
        "${startTime?.minute.toString().padLeft(2, '0')}:"
        "${startTime?.second.toString().padLeft(2, '0')}";

    await _storeWaktu(hourOnly.value);

    // Cancel Timer Yang Exists
    countdownTimer?.cancel();

    // Start Timer Baru
    countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      // Execute jika isBekerja = true
      if (isBekerja.value) {
        lamaWaktu.value++;
        // Cek timer
        // print("Time elapsed: ${formatDuration(lamaWaktu)} seconds");
        // print("Timer started at: $hourOnly");
      } else {
        timer.cancel(); // Stop the timer if isBekerja is false

        // Reset CountDown Timer
        lamaWaktu.value = 0;
        countdownTimer?.cancel();
        countdownTimer = null;
      }
    });
  }

  var dio = Dio();

  Future<void> _storeWaktu(String startTime) async {
    try {
      var response = await dio.post(
        '${myIpAddr()}/ob/store_waktu',
        data: {
          "id_ruangan": widget.idRuangan,
          "id_karyawan": widget.idOb,
          "jam_mulai": startTime,
        },
      );

      if (response.statusCode == 200) {
        log("Berhasil Store Waktu OB");
        setState(() {
          idLaporan = response.data['last_id'];
        });

        print("Id Laporannya adalah $idLaporan");
      }
    } catch (e) {
      log("Error di fn storeWaktu $e");
    }
  }

  Future<void> _deleteProgress() async {
    try {
      var query = "id_laporan=${idLaporan}&id_karyawan=${widget.idOb}";

      var response = await dio.delete(
        '${myIpAddr()}/ob/delete_progress?$query',
      );

      if (response.statusCode == 200) {
        log("Berhasil Delete Waktu OB");
      }
    } catch (e) {
      log("Error di fn deleteProgress $e");
    }
  }

  // Map<String, dynamic> _isiDataPekerja = {};
  // Future<void> _profileUser() async {
  //   try {
  //     var response = await getMyData(widget.myToken);

  //     if (response != null && response['data'] != null) {
  //       setState(() {
  //         _isiDataPekerja = response['data'];
  //       });
  //     }

  //     print("Isi response di MainOb : $response");
  //   } catch (e) {
  //     log("Error di main kitchen $e");
  //   }
  // }

  // RxList<dynamic> listRoom = [].obs;
  // RxString _selectedIdRoom = "".obs;

  // Future<void> _getListRuangan() async {
  //   try {
  //     var response = await dio.get('${myIpAddr()}/ob/list_room');

  //     List<dynamic> responseData = response.data;

  //     listRoom.clear();

  //     for (var i = 0; i < responseData.length; i++) {
  //       listRoom.add(responseData[i]);
  //     }

  //     log("Isi List Room${listRoom}");
  //   } catch (e) {
  //     log("Error get Data Ruangan $e");
  //   }
  // }

  // Store Ke Db utk Func Ini
  RxString jamSelesai = "".obs;
  // GlobalImageManager _imageManager = GlobalImageManager();

  Future<void> setPekerjaDone({required String status}) async {
    isBekerja.value = false;

    if (startTime != null) {
      // calculate end time
      final endTime = startTime!.add(Duration(seconds: lamaWaktu.value));

      jamSelesai.value =
          "${endTime.hour.toString().padLeft(2, '0')}:"
          "${endTime.minute.toString().padLeft(2, '0')}:"
          "${endTime.second.toString().padLeft(2, '0')}";

      print("Jam Selesai Adalah ${jamSelesai.value}");

      try {
        var response = await dio.put(
          '${myIpAddr()}/ob/done_bekerja',
          data: {
            "id_laporan": idLaporan,
            "id_ruangan": widget.idRuangan,
            "id_karyawan": widget.idOb,
            "jam_mulai": hourOnly.value,
            "jam_selesai": jamSelesai.value,
            "status": status
          },
        );

        if (response.statusCode == 200) {
          log("Berhasil Update Status OB");
          // Bersihkan Image Manager
          _globalImageManager.clearAllData();

          Get.offAll(MainKamarTerapis());
        }
      } catch (e) {
        log("Error Update waktu $e");
      }
    } else {
      log("Start Time Null, ga bs update");
    }

    // print(lamaWaktu);
    // print(hourOnly);
  }

  String formatDuration(RxInt seconds) {
    final duration = Duration(seconds: seconds.value);
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final secs = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$secs";
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // _getListRuangan();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (isBekerja.isTrue) {
        return WillPopScope(
          onWillPop: () async {
            bool? result = await Get.dialog(
              AlertDialog(
                title: const Text("Keluar Menu?"),
                content: const Text(
                  "Apakah Yakin Ingin Keluar?. Timer anda akan dihapus",
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Get.back(result: false);
                    },
                    child: Text("No"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await _deleteProgress();
                      Get.back(result: true);
                    },
                    child: Text("Yes"),
                  ),
                ],
              ),
            );

            return result ?? false;
          },
          child: _konten(),
        );
      } else {
        return _konten();
      }
    });
  }

  Widget _konten() {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: Color(0XFFFFE0B2),
        title: Center(
          child: Padding(
            padding: const EdgeInsets.only(right: 50),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.asset("assets/spa.jpg", height: 100),
            ),
          ),
        ),
      ),
      body: Container(
        height: Get.height,
        width: Get.width,
        decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
        child: Column(
          children: [
            Container(
              height: 200,
              padding: const EdgeInsets.only(top: 30, left: 30),
              margin: const EdgeInsets.only(top: 30, left: 60, right: 60),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 18, 19, 19).withOpacity(0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: SizedBox(
                      height: 100,
                      width: 100,
                      child: CircleAvatar(child: Text("A")),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 30),
                      child: Obx(() {
                        if (lamaWaktu.value != 0) {
                          // var index = listRoom.indexWhere((room) {
                          //   return room['id_ruangan'].toString() ==
                          //       _selectedIdRoom.value;
                          // });

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Room : ${widget.namaRuangan}",
                                style: TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                  height: 1.4,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              Text(
                                "Office Boy : ${widget.namaOb}",
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  height: 1.4,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              Text(
                                "Waktu Mulai : ${hourOnly.value} ",
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  height: 1.4,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              Text(
                                "Lama Pengerjaan :  ${formatDuration(lamaWaktu)} ",
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  height: 1.4,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Room : ${widget.namaRuangan}",
                                style: TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                  height: 1.4,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              Text(
                                "Office Boy : ${widget.namaOb}",
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  height: 1.4,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              Text(
                                "Waktu Mulai : - ",
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  height: 1.4,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              Text(
                                "Lama Pengerjaan :  - ",
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  height: 1.4,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          );
                        }
                      }),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.only(left: 60, right: 60),
              // Mesti Wrap dengan Obx klo mw bikin dia terubah
              child: Obx(() {
                return Align(
                  alignment: Alignment.centerRight,
                  child:
                      isBekerja.isFalse
                          ? ElevatedButton(
                            onPressed: () {
                              setPekerjaStart();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.8),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              minimumSize: Size(120, 120),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.door_back_door, size: 80),
                                Text(
                                  "Mulai Bekerja",
                                  style: TextStyle(fontFamily: 'Poppins'),
                                ),
                              ],
                            ),
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  await captureImage();

                                  _displayCapturedImages();

                                  Get.to(
                                    () => Lapor(
                                      idLaporan: idLaporan!,
                                      idOb: widget.idOb,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(
                                    0.8,
                                  ),
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  minimumSize: Size(120, 120),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.camera, size: 80),
                                    Text(
                                      "Foto\nRuangan",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontFamily: 'Poppins'),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 40),
                                child: ElevatedButton(
                                  onPressed: () async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Pilih Status Kamar', style: TextStyle(fontFamily: 'Poppins')),
        content: Text(
          'Apakah Anda ingin mengatur status kamar menjadi Aktif atau Maintenance?',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              setPekerjaDone(status: 'aktif'); // Call with "aktif"
            },
            child: Text('Aktif'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              setPekerjaDone(status: 'maintenance'); // Call with "maintenance"
            },
            child: Text('Maintenance'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cancel
            },
            child: Text('Batal'),
          ),
        ],
      );
    },
  );
},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white.withOpacity(
                                      0.8,
                                    ),
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    minimumSize: Size(120, 120),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.check, size: 80),
                                      Text(
                                        "Selesai",
                                        style: TextStyle(fontFamily: 'Poppins'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
