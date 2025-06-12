import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:Project_SPA/admin/main_admin.dart';
import 'package:Project_SPA/function/ip_address.dart';
import 'package:Project_SPA/function/me.dart';
import 'package:Project_SPA/function/our_drawer.dart';
import 'package:Project_SPA/function/token.dart';
import 'package:Project_SPA/kamar_terapis/main_kamar_terapis.dart';
import 'package:Project_SPA/kitchen/main_kitchen.dart';
import 'package:Project_SPA/komisi/main_komisi_pekerja.dart';
import 'package:Project_SPA/owner/main_owner.dart';
import 'package:Project_SPA/resepsionis/daftar_member.dart';
import 'package:Project_SPA/resepsionis/jenis_member.dart';
// import 'package:Project_SPA/resepsionis/list_transaksi2.dart';
import 'package:Project_SPA/resepsionis/scannerQR.dart';
import 'package:Project_SPA/resepsionis/transaksi_food.dart';
import 'package:Project_SPA/ruang_tunggu/main_rt.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Project_SPA/resepsionis/billing_locker.dart';
import 'package:get_storage/get_storage.dart';
import 'package:just_audio/just_audio.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'daftar_room.dart';
import 'package:Project_SPA/resepsionis/jenis_transaksi.dart';
import 'package:Project_SPA/main.dart';

class MainResepsionisController extends GetxController with WidgetsBindingObserver {
  WebSocketChannel? _channel;
  Timer? _timerWebSocket;
  Timer? _notifTimer; // macam settimeout, bikin retrigger
  bool _isWebSocketConnected = false;
  late StreamSubscription _socketSubscription;

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    WidgetsBinding.instance.addObserver(this); // tambah observer
    _connectToWebSocket();
    _profileUser();
    getDataTerapis();
    _loadSound();

    // Init AwesomeNotif
    AwesomeNotifications().initialize(
      null, // null for default icon
      [
        NotificationChannel(
          channelKey: 'basic_channel_kamar',
          channelName: 'Notifikasi Kamar',
          // channelGroupKey: "kamar_terapis",
          groupKey: "kamar_terapis",
          channelShowBadge: true,
          channelDescription: 'Notification channel for basic tests',
          defaultColor: Color(0xFF9D50DD),
          ledColor: Colors.white,
          groupAlertBehavior: GroupAlertBehavior.Children, // Important for stacking
          importance: NotificationImportance.High, // Ensure high importance untuk event Tap
        ),
      ],
      debug: true, //
    );
  }

  @override
  void onClose() {
    // TODO: implement onClose
    _disconnectWebSocket();

    // Cancel Timer WS
    _notifTimer?.cancel();
    _timerWebSocket?.cancel();
    // End Cancel
    WidgetsBinding.instance.removeObserver(this);
    KodeTerapisController?.dispose();
    dropdownNamaTerapis.value = null;
    _audioPlayer.dispose();
    // namaKaryawan.close();
    // jabatan.close();
    // _listNamaTerapis.close();

    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // TODO: implement didChangeAppLifecycleState
    super.didChangeAppLifecycleState(state);
    log("Lifecycle Main_Resepsionis $state");

    if (state == AppLifecycleState.resumed) {
      if (!_isWebSocketConnected) {
        log("App Resumed, WebSocket not connect, Reconnecting...");
        _connectToWebSocket(); // Safe connect
      }
    } else if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // Close dlu, lalu reconnect ulg pas resume biar fresh
      if (_isWebSocketConnected) {
        log("App Paused/Inactive. Close Websocket");
        _channel?.sink.close();
        _isWebSocketConnected = false;
        _timerWebSocket?.cancel();
        _notifTimer?.cancel();
      }
    }
  }

  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> _loadSound() async {
    try {
      await _audioPlayer.setAsset('assets/audio/kamarselesai.mp3');
      await _audioPlayer.setVolume(1.0);
    } catch (e) {
      debugPrint("Error loading sound: $e");
    }
  }

  Future<void> _playNotifSelesai() async {
    try {
      // await Future.delayed(const Duration(milliseconds: 100)); // Give time for press animation

      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint("Error playing sound: $e");
    }
  }

  Future<void> _connectToWebSocket() async {
    // Cancel any existing reconnection timer to prevent multiple attempts
    _timerWebSocket?.cancel();

    // close existing connection jika ada
    await _disconnectWebSocket();
    // if (_channel != null) {
    //   await _channel!.sink.close();
    //   _channel = null;
    // }

    // skip jika ud konek
    if (_isWebSocketConnected) return;

    // mesti replace dari http ke ws. krn myIpAddr ini ada http.
    var originalUrl = myIpAddr();
    var replacedUrl = originalUrl.replaceAll("http", "ws");

    var wsUri = Uri.parse("$replacedUrl/kamar_terapis/ws-kamar");

    // buat konek websocket
    try {
      // await _channel?.sink.close();
      _channel = IOWebSocketChannel.connect(wsUri);
      _isWebSocketConnected = true; // Set connected flag to true
      log("WebSocket MainResepsionis connected successfully.");
    } catch (e) {
      log("Failed to connect to WebSocketResepsionis: $e");
      // _isWebSocketConnected = false;
      // // Optionally, set a timer to retry connection after a delay
      // _timerWebSocket = Timer(Duration(seconds: 5), () => _connectToWebSocket());
      reconnectToWebSocket();
      return; // Exit if connection fails
    }

    void triggerNotif(Map<String, dynamic> data) {
      // init awesome notification

      int idNotif = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      String title = "";
      String body = data['message'];

      if (data['status'] == "ganti_paket") {
        title = "Penggantian Paket";
      } else if (data['status'] == "extend_waktu") {
        title = "Perpanjang Waktu";
      } else if (data['status'] == "ganti_terapis") {
        title = "Penggantian Terapis";
      } else if (data['status'] == "ganti_ruangan") {
        title = "Penggantian Ruangan";
      } else if (data['status'] == "tambah_paket_produk") {
        title = "Penambahan Paket/produk";
      } else if (data['status'] == "terapis_tiba") {
        title = "Terapis Tiba";
      } else if (data['status'] == "kamar_selesai") {
        title = "Selesai Massage";

        _playNotifSelesai();
      }

      AwesomeNotifications().createNotification(
        content: NotificationContent(id: idNotif, channelKey: 'basic_channel_kamar', title: title, body: body, groupKey: "kamar_terapis"), //
      );

      // Event ketika dipencet. initialize setelah websocket jalan
      AwesomeNotifications().setListeners(
        onActionReceivedMethod: (ReceivedAction receivedAct) async {
          // Handle Notif di Tap
          if (receivedAct.id == idNotif) {
            // Notif dengan Id ke Random dipencet
            log("Notif $idNotif dipencet");

            // Untuk pindah menu ke bagian riwayat
            // key disini untuk force rebuild menu2. incase notif muncul, lalu user tap & posisi user di menu riwayat/history
          }
        },
      );

      CherryToast.info(
        title: Text(title, style: TextStyle(color: Colors.black)),
        action: Text(body, style: TextStyle(color: Colors.black)),
        autoDismiss: true,
        actionHandler: () {
          // Handle tap action
        },
      ).show(Get.context!);
    }

    // ambil pesan dr Server
    _socketSubscription = _channel!.stream.listen(
      (message) async {
        _notifTimer?.cancel();
        _notifTimer = Timer(Duration(seconds: 1), () {
          final data = jsonDecode(message);

          triggerNotif(data);
        });
      },
      onError: (err) {
        log("Websocket Resepsionis error: $err");
        reconnectToWebSocket();
      },
      onDone: () {
        log("Websocket Resepsionis Closed");
        reconnectToWebSocket();
      },
    );
  }

  void reconnectToWebSocket() {
    _isWebSocketConnected = false; // Update flag on error
    _timerWebSocket?.cancel(); // Cancel any existing reconnection timer
    _timerWebSocket = Timer(Duration(seconds: 5), () => _connectToWebSocket()); // Attempt to reconnect
  }

  Future<void> _disconnectWebSocket() async {
    await _channel?.sink.close();
    _channel = null;
    _isWebSocketConnected = false;
    _socketSubscription.cancel();
  }

  var storage = GetStorage();
  var namaKaryawan = "".obs;
  var jabatan = "".obs;
  RxList<Map<String, dynamic>> _listNamaTerapis = <Map<String, dynamic>>[].obs;

  var dio = Dio();

  Future<void> getDataTerapis() async {
    try {
      var response = await dio.get('${myIpAddr()}/absen/dataTerapis');
      _listNamaTerapis.value =
          (response.data as List).map((item) {
            return {"id_karyawan": item["id_karyawan"], "nama_karyawan": item["nama_karyawan"]};
          }).toList();
    } catch (e) {
      log("Error di fn Get Data Terapis $e");
    }
  }

  Future<void> clearDataTerapis() async {
    final response = await dio.delete('${myIpAddr()}/absen/delete_absen');
    if (response.statusCode == 200) {
      CherryToast.success(title: Text('Data berhasil dibersihkan')).show(Get.context!);
      Get.back();
    }
  }

  Future<void> _profileUser() async {
    // Token Bentrok kalo Mode Debug. Kalo error sini, build apk di masing2 devices
    try {
      final prefs = await getTokenSharedPref();
      var response = await getMyData(prefs);
      log("Isi getMyData $response");

      Map<String, dynamic> responseData = response['data'];
      print(responseData);

      namaKaryawan.value = responseData['nama_karyawan'];
      jabatan.value = responseData['jabatan'];

      storage.write('nama_karyawan', responseData['nama_karyawan']);
      storage.write('jabatan', responseData['jabatan']);
    } catch (e) {
      log("Error di _profileUser $e");
    }
  }

  List<String> extractDataTerapis = [];
  TextEditingController KodeTerapisController = TextEditingController();
  RxnString dropdownNamaTerapis = RxnString(null);

  void openDialog() {
    Get.dialog(
      AlertDialog(
        title: Center(child: const Text('Absensi')),
        actions: [
          SingleChildScrollView(
            physics: NeverScrollableScrollPhysics(),
            child: Container(
              width: 600,
              height: 200,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.zero,
                        child: Container(
                          margin: EdgeInsets.only(top: 10),

                          height: 100,
                          width: 200,
                          child: Padding(
                            padding: EdgeInsets.only(right: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                SizedBox(height: 15),
                                Text('Kode Terapis :', style: TextStyle(fontFamily: 'Poppins', fontSize: 18)),
                                SizedBox(height: 15),
                                Text('Nama Terapis :', style: TextStyle(fontFamily: 'Poppins', fontSize: 18)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 10),

                        height: 110,
                        width: 380,
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
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.grey[300]),
                                child: TextField(
                                  readOnly: true,
                                  controller: KodeTerapisController,
                                  decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 13.5, horizontal: 10)),
                                  style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                ),
                              ),
                              SizedBox(height: 12),
                              Container(
                                width: 380,
                                height: 30,
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.grey[300]),
                                child: Obx(
                                  () => DropdownButton<String>(
                                    value: dropdownNamaTerapis!.value,
                                    isExpanded: true,
                                    icon: const Icon(Icons.arrow_drop_down),
                                    elevation: 16,
                                    style: const TextStyle(color: Colors.deepPurple),
                                    underline: SizedBox(),
                                    padding: EdgeInsets.symmetric(horizontal: 10),
                                    onChanged: (String? value) {
                                      dropdownNamaTerapis!.value = value!;
                                      // Find the corresponding id_karyawan

                                      var selectedTerapis = _listNamaTerapis.firstWhere(
                                        (item) => item['nama_karyawan'] == value,
                                        orElse: () => {"id_karyawan": "", "nama_karyawan": ""},
                                      );
                                      KodeTerapisController.text = selectedTerapis['id_karyawan'] ?? "";
                                    },
                                    items:
                                        _listNamaTerapis.map<DropdownMenuItem<String>>((item) {
                                          return DropdownMenuItem<String>(
                                            value: item['nama_karyawan'], // Use ID as value
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                item['nama_karyawan'].toString(), // Display category name
                                                style: const TextStyle(fontSize: 18, fontFamily: 'Poppins'),
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
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 50,
                        width: 120,
                        child: TextButton(
                          style: TextButton.styleFrom(backgroundColor: Colors.green),
                          onPressed: () async {
                            final response = await dio.post('${myIpAddr()}/absen/post_absenterapis', data: {"id_karyawan": KodeTerapisController.text});
                            if (response.statusCode == 200) {
                              KodeTerapisController.clear();
                              dropdownNamaTerapis.value = null;
                              CherryToast.success(title: Text('Terapis berhasil diabsen')).show(Get.context!);
                            }
                          },

                          child: Text('Absen', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, color: Colors.white)),
                        ),
                      ),
                      SizedBox(width: 40),
                      SizedBox(
                        height: 50,
                        width: 120,
                        child: TextButton(
                          style: TextButton.styleFrom(backgroundColor: Colors.green),
                          onPressed: () {
                            Get.dialog(
                              AlertDialog(
                                title: Text('Confirm'),
                                content: Text('Yakin menghapus data?'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Get.back();
                                    },
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(onPressed: clearDataTerapis, child: Text('Confirm')),
                                ],
                              ),
                              barrierDismissible: false,
                            );
                          },
                          child: Text('Clear', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, color: Colors.white)),
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

class MainResepsionis extends StatelessWidget {
  MainResepsionis({super.key}) {
    if (!Get.isRegistered<MainResepsionisController>()) {
      Get.put(MainResepsionisController(), permanent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<MainResepsionisController>();

    return Scaffold(
      drawer: OurDrawer(),
      appBar: AppBar(title: Text('PLATINUM', style: TextStyle(fontSize: 60, fontFamily: 'Poppins')), centerTitle: true, backgroundColor: Color(0XFFFFE0B2)),
      body: Container(
        decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 90, right: 90, top: 150),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Get.to(BillingLocker());
                    },
                    child: Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.white), color: Colors.white, borderRadius: BorderRadius.circular(15)),
                      height: 250,
                      width: 200,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.doorbell_rounded, size: 180),
                          Text('Billing', style: TextStyle(fontSize: 20, fontFamily: 'Poppins')),
                          Text('Locker', style: TextStyle(fontSize: 20, fontFamily: 'Poppins')),
                        ],
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      Get.to(daftarRoom());
                    },
                    child: Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.white), color: Colors.white, borderRadius: BorderRadius.circular(15)),
                      height: 250,
                      width: 200,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.door_back_door_rounded, size: 180),
                          Text('Daftar', style: TextStyle(fontSize: 20, fontFamily: 'Poppins')),
                          Text('Room', style: TextStyle(fontSize: 20, fontFamily: 'Poppins')),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Get.to(() => (TransaksiFood()));
                    },
                    child: Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.white), color: Colors.white, borderRadius: BorderRadius.circular(15)),
                      height: 250,
                      width: 200,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.food_bank_rounded, size: 180),
                          Text('Food &', style: TextStyle(fontSize: 20, fontFamily: 'Poppins')),
                          Text('Beverages', style: TextStyle(fontSize: 20, fontFamily: 'Poppins')),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Get.to(() => (JenisMember()));
                    },
                    child: Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.white), color: Colors.white, borderRadius: BorderRadius.circular(15)),
                      height: 250,
                      width: 200,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [Icon(Icons.local_activity_rounded, size: 180), Text('Member', style: TextStyle(fontSize: 20, fontFamily: 'Poppins'))],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(flex: 1, child: Container()),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black), color: Colors.grey),
                  width: 400,
                  height: 100,
                  child: Row(
                    children: [
                      Padding(padding: EdgeInsets.only(left: 30)),
                      Container(
                        decoration: BoxDecoration(border: Border.all(), shape: BoxShape.circle),
                        width: 80,
                        height: 80,

                        child: CircleAvatar(
                          child: Obx(
                            () => Text(
                              c.namaKaryawan.value.isNotEmpty ? c.namaKaryawan.value[0].toUpperCase() : "?",
                              style: TextStyle(fontSize: 50, fontFamily: 'Poppins'),
                            ),
                          ),
                        ),
                      ),
                      Obx(
                        () => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 20),
                              child: Text(c.namaKaryawan.value, style: TextStyle(fontSize: 30, color: Colors.white, fontFamily: 'Poppins')),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 20),
                              child: Text(c.jabatan.value, style: TextStyle(fontSize: 30, color: Colors.white, fontFamily: 'Poppins')),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 90),
                  child: Container(
                    width: 200,
                    height: 100,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), border: Border.all(), color: Colors.lightGreenAccent),
                    child: TextButton(
                      onPressed: () {
                        c.openDialog();
                        c.dropdownNamaTerapis.value = null;
                        c.KodeTerapisController.clear();
                      },

                      child: Text('Absensi', style: TextStyle(fontSize: 30, fontFamily: 'Poppins', color: Colors.black)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
