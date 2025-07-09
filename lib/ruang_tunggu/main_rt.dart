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
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:web_socket_channel/io.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_tts/flutter_tts.dart';

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

  int _reconnectattempt = 0;
  final int _maxreconnectattempt = 5;
  final Duration _reconnectdelay = Duration(seconds: 5);

  bool _isdisposed = false;

  @override
  void onInit() {
    super.onInit();
    connectWebSocket();
    _loadSoundMall();
  }

  @override
  void onClose() {
    _isdisposed = true;
    _heartbeatws?.cancel();
    playeraudio.dispose();
    notifytimer?.cancel();
    channel.sink.close();
    super.onClose();
  }

  final FlutterTts flutterTts = FlutterTts();

  Future<void> _loadSoundMall() async {
    try {
      await playeraudio.setAsset('assets/audio/conveniencestore.mp3');
      await playeraudio.setVolume(1.0);
    } catch (e) {
      debugPrint("Error loading sound: $e");
    }
  }

  String _convertNamaRuangan(String value) {
    String ditchedRoom = value.replaceAll("Room ", "");
    final numericValue = int.tryParse(ditchedRoom);

    // return integer jika sukses, else return string biasa
    return "Room ${numericValue ?? value}";
  }

  Future _speak(String namaTerapis, String namaRuangan) async {
    log('Starting _speak');
    try {
      for (var i = 0; i < 2; i++) {
        await Future.delayed(Duration(milliseconds: 500));
        if (playeraudio.playing) {
          await playeraudio.stop();
        }

        await playeraudio.seek(Duration.zero);
        await playeraudio.play();
      }

      await Future.delayed(Duration(seconds: 1));
      await playeraudio.stop();

      log('Configuring TTS...');
      await flutterTts.setLanguage("id-ID");
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.setVolume(1.0);
      log('Speaking...');
      await flutterTts.awaitSpeakCompletion(true);

      log('Speaking first message...');
      await flutterTts.speak("Panggilan Kepada $namaTerapis, Harap Menuju ${_convertNamaRuangan(namaRuangan)}");
      await Future.delayed(Duration(seconds: 1));

      log('Speaking reminder...');
      await flutterTts.speak("Sekali Lagi, Panggilan Kepada $namaTerapis, Harap Menuju  ${_convertNamaRuangan(namaRuangan)}");

      log('TTS finished');
      log('TTS spoken');
    } catch (e) {
      log('Error in _speak: $e');
    }
  }

  void connectWebSocket() {
    var originalUrl = myIpAddr();
    var replacedUrl = originalUrl.replaceAll("http", "ws");
    var wsUri = Uri.parse("$replacedUrl/spv/ws-spv");

    _heartbeatws?.cancel();

    try {
      channel = IOWebSocketChannel.connect(wsUri);
      log('websocket connected');
      _reconnectattempt = 0;

      channel.stream.listen(
        (message) async {
          notifytimer?.cancel();
          notifytimer = Timer(Duration(seconds: 1), () {
            log('received websocket message : $message');
            updateDataFromWebSocket(message);
            if (activescreen.value == 'ruang_tunggu') {
              // playeraudio.stop();
              // try {
              //   playeraudio.setAsset('assets/audio/conveniencestore.mp3').then((_) {
              //     playeraudio.play();
              //   });
              // } catch (e) {
              //   log('player playing audio : $e');
              // }
              showtoast.value = true;
            }
          });
        },
        onDone: () {
          log('ws spv done');
          _heartbeatws?.cancel();
          _attemptrecconect();
        },
        onError: (error) {
          log('ws spv error');
          _heartbeatws?.cancel();
          _attemptrecconect();
        },
      );

      channel.ready
          .then((_) {
            log('websocket connected successfull');
            _reconnectattempt = 0;
            _startheartbeat();
          })
          .catchError((error) {
            log('websocket fail to connect : $error');
            _attemptrecconect();
          });
    } catch (e) {
      log('failed to initiate websocket connection :$e');
      _attemptrecconect();
    }
  }

  void _attemptrecconect() {
    if (_isdisposed) return;
    if (_reconnectattempt < _maxreconnectattempt) {
      _reconnectattempt++;
      log('attempt recconecting ws');
      Future.delayed(_reconnectdelay, () {
        connectWebSocket();
      });
    } else {
      log('maximum attempt connect reached. stop connecting');
    }
  }

  void _startheartbeat() {
    if (_heartbeatws != null && _heartbeatws!.isActive) {
      _heartbeatws!.cancel();
    }
    _heartbeatws = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (channel != null && channel.sink != null && channel.stream != null && channel.closeCode == null) {
        final pingmsg = jsonEncode({"type": "ping"});
        channel.sink.add(pingmsg);
        log('send heartbeat to ws spv');
      } else {
        log('Websocket not opening for heartbeat, cancel timer');
        _heartbeatws?.cancel();
        _heartbeatws = null;
      }
    });
  }

  RxInt newestItemIndex = RxInt(-1);

  void updateDataFromWebSocket(dynamic message) {
    log('raw socketdata : $message');
    List<Map<String, dynamic>> newdata = parseWebSocketData(message);
    log('parsed data:$newdata');
    for (var item in newdata) {
      var existingindex = datapanggilankerja.indexWhere((existing) => existing['id_panggilan'] == item['id_panggilan']);
      if (existingindex == -1) {
        datapanggilankerja.add(item);
        // NgeScroll Ke Index Terakhir
        newestItemIndex.value = datapanggilankerja.length - 1;
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
        log("Isi decodedata $decodedata");

        // Ambil Index Terakhir utk data terbaru
        _speak(decodedata[decodedata.length - 1]['nama_terapis'], decodedata[decodedata.length - 1]['ruangan']);

        return decodedata.map((item) {
          return {"ruangan": item['ruangan'], "nama_terapis": item['nama_terapis'], "id_panggilan": item['id_panggilan'], "timestamp": item['timestamp']};
        }).toList();
      } else {
        log('websocket data is not a list : $decodedata');
        return [];
      }
    } catch (e) {
      log('Error parsing websocket data : $e');
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
  final ItemScrollController itemSctr = ItemScrollController();
  // ScrollController _scrollControllerLV = ScrollController();

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
    controllerPanggilanKerja.activescreen.value = 'ruang_tunggu';

    // Listen to changes in newestItemIndex
    // Used ever() from GetX to listen to changes in newestItemIndex
    // Now we only scroll when the index is valid (>= 0 and < list length)
    ever(controllerPanggilanKerja.newestItemIndex, (index) {
      if (index >= 0 && index < controllerPanggilanKerja.datapanggilankerja.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (itemSctr.isAttached) {
            itemSctr.scrollTo(index: index, duration: Duration(milliseconds: 500), curve: Curves.easeOut);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    Get.find<ControllerPanggilanKerja>().activescreen.value = 'not_ruang_tunggu';
    Get.delete<ControllerPanggilanKerja>(force: true);
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
              // Ak Ganti Scrollbar & ListView jadi ScrollConfiguration & ScrollablePositionedList
              child: ScrollConfiguration(
                behavior: _ScrollbarBehavior(),

                // thickness: 15,
                // radius: Radius.circular(20),
                // thumbVisibility: true,
                // controller: _scrollControllerLV,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Obx(() {
                    final controller = Get.find<ControllerPanggilanKerja>();

                    if (controller.datapanggilankerja.isEmpty) {
                      return Center(
                        child: Text(
                          "(∪.∪ )...zzz\nBelum Ada Panggilan",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                        ),
                      );
                    }

                    return ScrollablePositionedList.builder(
                      itemScrollController: itemSctr,
                      // controller: _scrollControllerLV,
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
                                // Redudant. ak Comment. krn RemoveWhere udh auto refresh list Rx
                                // controller.datapanggilankerja.refresh();
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

class _ScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return Scrollbar(controller: details.controller, thickness: 15, radius: Radius.circular(20), thumbVisibility: true, child: child);
  }
}
