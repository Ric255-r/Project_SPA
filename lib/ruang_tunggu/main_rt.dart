import 'dart:convert';
import 'dart:async';
import 'package:Project_SPA/function/our_drawer.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:Project_SPA/function/ip_address.dart';
import 'dart:developer';
import 'package:get_storage/get_storage.dart';
import 'package:web_socket_channel/io.dart';
import 'package:just_audio/just_audio.dart';

var dio = Dio();

class ControllerPanggilanKerja extends GetxController {
  late IOWebSocketChannel channel;
  RxList<Map<String, dynamic>> datapanggilankerja = <Map<String, dynamic>>[].obs;

  var refreshtrigger = false.obs;
  Timer? notifytimer;
  Timer? _heartbeatws;
  final playeraudio = AudioPlayer();
  var activescreen = ''.obs;
  var showtoast = false.obs;

  @override
  void onInit() {
    super.onInit();
    connectWebSocket();
  }

  @override
  void onClose() {
    _heartbeatws?.cancel();
    playeraudio.dispose();
    notifytimer?.cancel();
    channel.sink.close();
    super.onClose();
  }

  void connectWebSocket() {
    var originalUrl = myIpAddr();
    var replacedUrl = originalUrl.replaceAll("http", "ws");
    var wsUri = Uri.parse("$replacedUrl/spv/ws-spv");
    channel = IOWebSocketChannel.connect(wsUri);
    log('websocket connected');

    _startheartbeat();

    channel.stream.listen(
      (message) async {
        notifytimer?.cancel();
        notifytimer = Timer(Duration(seconds: 1), () {
          log('received websocket message : $message');
          updateDataFromWebSocket(message);
          if (activescreen.value == 'ruang_tunggu') {
            playeraudio.stop();
            try {
              playeraudio.setAsset('assets/audio/f1sport.mp3').then((_) {
                playeraudio.play();
              });
            } catch (e) {
              log('player playing audio : $e');
            }
            showtoast.value = true;
          }
        });
      },
      onDone: () {
        log('ws spv done');
        _heartbeatws?.cancel();
      },
      onError: (error) {
        log('ws spv error');
        _heartbeatws?.cancel();
      },
    );
  }

  void _startheartbeat() {
    _heartbeatws = Timer.periodic(const Duration(seconds: 30), (timer) {
      final pingmsg = jsonEncode({"type": "ping"});
      channel.sink.add(pingmsg);
      log('send heartbeat to ws spv');
    });
  }

  void updateDataFromWebSocket(dynamic message) {
    log('raw socketdata : $message');
    List<Map<String, dynamic>> newdata = parseWebSocketData(message);
    log('parsed data:$newdata');
    for (var item in newdata) {
      var existingindex = datapanggilankerja.indexWhere((existing) => existing['id_panggilan'] == item['id_panggilan']);
      if (existingindex == -1) {
        datapanggilankerja.add(item);
      } else {
        var existingitem = datapanggilankerja[existingindex];
        if (existingitem['timestamp'] != item['timestamp']) {
          log('nambah data kedalam existing data');
          datapanggilankerja[existingindex] = item;
        } else {
          log('Ignore duplicate entry');
        }
      }
    }
    datapanggilankerja.refresh();
  }

  List<Map<String, dynamic>> parseWebSocketData(dynamic message) {
    try {
      var decodedata = jsonDecode(message);
      if (decodedata is List) {
        return decodedata.map((item) {
          return {"ruangan": item['ruangan'], "nama_terapis": item['nama_terapis'], "id_panggilan": item['id_panggilan'], "timestamp": item['timestamp']};
        }).toList();
      } else {
        print('websocket data is not a list : $decodedata');
        return [];
      }
    } catch (e) {
      print('Error parsing websocket data : $e');
      return [];
    }
  }

  Future<void> getdatapanggilankerja() async {
    try {
      var response = await dio.get('${myIpAddr()}/spv/getdatapanggilankerja');
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {"ruangan": item['ruangan'], "nama_terapis": item['nama_terapis'], "id_panggilan": item['id_panggilan']};
          }).toList();

      for (var item in fetcheddata) {
        var existingindex = datapanggilankerja.indexWhere((existing) => existing['id_panggilan'] == item['id_panggilan']);
        if (existingindex == -1) {
          datapanggilankerja.add(item);
        } else {
          datapanggilankerja[existingindex] = item;
        }
      }
      datapanggilankerja.refresh();
    } catch (e) {
      log("Error di fn Getdatapanggilankerja : $e");
    }
  }

  Future<void> deletepanggilankerja(id_panggilan) async {
    try {
      var response = await dio.delete('${myIpAddr()}/spv/deletepanggilankerja', data: {"id_panggilan": id_panggilan});
    } catch (e) {
      log("Error di fn deletepanggilankerja : $e");
    }
  }

  Future<void> refreshDataPanggilanKerja() async {
    await Future.delayed(Duration(milliseconds: 500));
    await getdatapanggilankerja();
    refreshtrigger.value = !refreshtrigger.value;
  }
}

class MainRt extends StatefulWidget {
  MainRt({super.key}) {
    if (!Get.isRegistered<ControllerPanggilanKerja>()) {
      Get.lazyPut(() => ControllerPanggilanKerja(), fenix: false);
    }
  }

  @override
  State<MainRt> createState() => _MainRtState();
}

class _MainRtState extends State<MainRt> {
  ScrollController _scrollControllerLV = ScrollController();

  final ControllerPanggilanKerja controllerPanggilanKerja = Get.find<ControllerPanggilanKerja>();

  RxList<Map<String, dynamic>> datapanggilankerja = <Map<String, dynamic>>[].obs;

  Future<void> deletepanggilankerja(id_panggilan) async {
    try {
      var response = await dio.delete('${myIpAddr()}/spv/deletepanggilankerja', data: {"id_panggilan": id_panggilan});
    } catch (e) {
      log("Error di fn deletepanggilankerja : $e");
    }
  }

  @override
  void initState() {
    super.initState();
    controllerPanggilanKerja.refreshDataPanggilanKerja();
    Get.find<ControllerPanggilanKerja>().activescreen.value = 'ruang_tunggu';
  }

  @override
  void dispose() {
    Get.find<ControllerPanggilanKerja>().activescreen.value = 'not_ruang_tunggu';
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0XFFFFE0B2),
        title: Center(
          child: Padding(
            padding: const EdgeInsets.only(right: 50),
            child: Text("PANGGILAN KERJA", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
          ),
        ),
      ),
      drawer: OurDrawer(),
      body: Container(
        height: Get.height,
        width: Get.width,
        decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
        child: Column(
          children: [
            Container(
              height: Get.height - 150,
              width: Get.width - 100,
              margin: const EdgeInsets.only(left: 40, right: 40),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white),
              child: Scrollbar(
                thickness: 15,
                radius: Radius.circular(20),
                thumbVisibility: true,
                controller: _scrollControllerLV,
                child: Padding(
                  padding: const EdgeInsets.only(left: 40, right: 40),
                  child: Obx(() {
                    final controller = Get.find<ControllerPanggilanKerja>();
                    return ListView.builder(
                      controller: _scrollControllerLV,
                      itemCount: controller.datapanggilankerja.length,
                      itemBuilder: (context, index) {
                        var item = controller.datapanggilankerja[index];
                        return Column(
                          children: [
                            SizedBox(height: 70),
                            Text(item['nama_terapis'], style: TextStyle(fontSize: 100, height: 1, fontFamily: 'Poppins')),
                            Text(item['ruangan'], style: TextStyle(fontSize: 110, height: 1, fontFamily: 'Poppins')),
                            SizedBox(height: 40),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 168, 232, 170),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                minimumSize: Size(100, 100),
                              ),
                              onPressed: () {
                                log(item['id_panggilan'].toString());
                                controller.datapanggilankerja.removeWhere((element) => element['id_panggilan'] == item['id_panggilan']);
                                deletepanggilankerja(item['id_panggilan']);
                                controller.datapanggilankerja.refresh();
                              },
                              child: Column(
                                children: [Icon(Icons.check, size: 50), SizedBox(height: 10), Text("Confirm", style: TextStyle(fontFamily: 'Poppins'))],
                              ),
                            ),
                            SizedBox(height: 80),
                          ],
                        );
                      },
                    );
                  }),
                ),
              ),
            ),

            Container(
              margin: const EdgeInsets.only(top: 20, right: 50),
              alignment: Alignment.centerRight,
              child: Text("PLATINUM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30)),
            ),
            Obx(() {
              if (Get.find<ControllerPanggilanKerja>().showtoast.value) {
                Future.delayed(Duration.zero, () {
                  CherryToast.success(title: Text('Panggilan Kerja Masuk')).show(context);
                  Get.find<ControllerPanggilanKerja>().showtoast.value = false;
                });
              }
              return SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }
}
