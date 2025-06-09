import 'dart:convert';

import 'package:Project_SPA/function/our_drawer.dart';
import 'package:Project_SPA/main.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Project_SPA/function/ip_address.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:async';
import 'dart:developer';
import 'package:dio/dio.dart';

class Hp_Ob extends StatefulWidget {
  Hp_Ob({super.key});

  @override
  State<Hp_Ob> createState() => _Hp_ObState();
}

class _Hp_ObState extends State<Hp_Ob> with WidgetsBindingObserver {
  ScrollController _scrollControllerLV = ScrollController();
  late WebSocketChannel _channel;
  Timer? _timerWebSocket;
  Timer? notiftimer;
  bool _isconnected = false;
  RxList<Map<String, dynamic>> dataruanganbersihkan = <Map<String, dynamic>>[].obs;
  var dio = Dio();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    startbackgroundservice();
    _initializenotif();
    _initwebsocket();
    refreshruanganbersihkan();
    // Timer.periodic(Duration(seconds: 10), (timer) {
    //   if (_isconnected) {
    //     _channel.sink.add(jsonEncode({"ping": "keep-alive"}));
    //   }
    // });
  }

  void _initializenotif() {
    // init AwesomeNotifications
    // AwesomeNotifications().initialize(
    //   null, // null for default icon
    //   [
    //     NotificationChannel(
    //       channelKey: 'basic_channel',
    //       channelName: 'Basic notifications',
    //       channelDescription: 'Notification channel for basic tests',
    //       defaultColor: Color(0xFF9D50DD),
    //       ledColor: Colors.white,
    //       importance:
    //           NotificationImportance
    //               .High, // Ensure high importance untuk event Tap
    //     ),
    //   ],
    //   debug: true,
    // );

    AwesomeNotifications().setListeners(onActionReceivedMethod: onNotificationTap);
    // // Event ketika dipencet. initialize setelah websocket jalan
    // AwesomeNotifications().setListeners(
    //   onActionReceivedMethod: (ReceivedAction receivedAct) async {
    //     // Handle Notif di Tap
    //     if (receivedAct.id == 10) {
    //       // Notif dengan Id ke 10 dipencet
    //       print("Notif 10 dipencet");
    //     }
    //   },
    // );
  }

  void _initwebsocket() {
    _timerWebSocket = Timer(Duration(milliseconds: 1300), () {
      _connectToWebSocket();
    });
  }

  Future<void> _connectToWebSocket() async {
    try {
      // mesti replace dari http ke ws. krn myIpAddr ini ada http.
      var originalUrl = myIpAddr();
      var replacedUrl = originalUrl.replaceAll("http", "ws");

      // ambil endpoint route websocket yg udh dibuat
      var wsUri = Uri.parse("$replacedUrl/kamar_terapis/ws-ob");
      log(wsUri.toString());
      // buat koneksi websocket
      _channel = IOWebSocketChannel.connect(wsUri);
      _isconnected = true;
      log('websocket OB connected');

      // kombinasi dari AwesomeNotifications dan cherry_toast
      // return data status ini isinya Sukses, Ditolak, dan Pending.
      // Hasil Translate dari triggerNotif Websocket Screen2.dart
      void triggerNotif(String namaroom) {
        int idnotification = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: idnotification,
            channelKey: 'basic_channel',
            title: 'Room $namaroom',
            body: 'Ruangan $namaroom perlu dibersihkan, harap segera dibersihkan',
            groupKey: "Cleaning Request",
          ),
          actionButtons: [NotificationActionButton(key: 'DiSMISS', label: 'Dismiss', autoDismissible: true)],
        );

        // Ini dari cherry_toast. bukan punya awesome_notification
        if (mounted && WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
          CherryToast.info(
            title: Text('Room $namaroom', style: TextStyle(color: Colors.black)),
            action: Text('Ruangan $namaroom perlu dibersihkan, harap segera dibersihkan', style: TextStyle(color: Colors.black)),
          ).show(context);
        }
      }

      // ambil pesan dari server
      _channel.stream.listen(
        (message) async {
          notiftimer?.cancel();
          notiftimer = Timer(Duration(seconds: 1), () {
            final data = jsonDecode(message);

            triggerNotif(data['nama_ruangan'].last.toString());
            setState(() {
              log('nama ruangan : ${data['nama_ruangan']}');
              List<Map<String, dynamic>> fetcheddata =
                  (data['nama_ruangan'] as List).map((item) {
                    return {"nama_ruangan": item.toString()};
                  }).toList();
              dataruanganbersihkan.clear();
              dataruanganbersihkan.assignAll(fetcheddata);
              dataruanganbersihkan.refresh();
            });
          });
          // parse message yg akan datang. asumsinya json.
        },
        onError: (err) {
          print("Websocket error: $err");
        },
        onDone: () {
          _isconnected = false;
          log("Websocket Closed");

          if (mounted) {
            Timer(Duration(seconds: 2), _connectToWebSocket);
          }
        },
      );
    } catch (e) {
      _isconnected = false;
      log('Connection error: $e');

      if (mounted) {
        Timer(Duration(seconds: 3), _connectToWebSocket);
      }
    }

    void sendmessage(dynamic message) {
      if (!_isconnected) {
        log("WebSocket disconnected, attempting reconnection...");
        _connectToWebSocket();
      } else {
        _channel.sink.add(message);
      }
    }

    @override
    void dispose() {
      _timerWebSocket?.cancel();
      notiftimer?.cancel();
      super.dispose();
    }

    @override
    void didchangeapplifecyclestate(AppLifecycleState state) {
      super.didChangeAppLifecycleState(state);

      if (state == AppLifecycleState.resumed) {
        if (!_isconnected) {
          _connectToWebSocket();
        }
      }
    }
  }

  Future<void> getdataruanganbersihkan() async {
    try {
      var response = await dio.get('${myIpAddr()}/ob/ruanganbersihkan');
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {"nama_ruangan": item['nama_ruangan']};
          }).toList();
      setState(() {
        dataruanganbersihkan.clear();
        dataruanganbersihkan.assignAll(fetcheddata);
        dataruanganbersihkan.refresh();
      });
    } catch (e) {
      log("Error di fn Getdatapaketmassage : $e");
    }
  }

  Future<void> confirmob(nama_ruangan) async {
    try {
      var response = await dio.delete('${myIpAddr()}/ob/confirmkerjaanob', data: {"nama_ruangan": nama_ruangan});
    } catch (e) {
      log("Error di fn confirmkerjaanob : $e");
    }
  }

  Future<void> refreshruanganbersihkan() async {
    await Future.delayed(Duration(seconds: 1));
    await getdataruanganbersihkan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: OurDrawer(),
      appBar: AppBar(
        title: Text('PLATINUM', style: TextStyle(fontFamily: 'Poppins', fontSize: 30, fontWeight: FontWeight.bold)),
        toolbarHeight: 100,
        centerTitle: true,
        backgroundColor: Color(0XFFFFE0B2),
      ),
      body: Container(
        height: Get.height,
        width: Get.width,
        decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
        child: Column(
          children: [
            SizedBox(height: 30),
            Container(
              height: Get.height - 250,
              width: Get.width - 50,
              margin: const EdgeInsets.only(left: 40, right: 40),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white),
              child: Scrollbar(
                thickness: 15,
                radius: Radius.circular(20),
                thumbVisibility: true,
                controller: _scrollControllerLV,
                child: Padding(
                  padding: const EdgeInsets.only(left: 40, right: 40),
                  child: ListView.builder(
                    controller: _scrollControllerLV,
                    itemCount: dataruanganbersihkan.length,
                    itemBuilder: (context, index) {
                      var item = dataruanganbersihkan[index];
                      return Column(
                        children: [
                          SizedBox(height: 70),
                          Text("Cleaning", style: TextStyle(fontSize: 40, height: 1, fontFamily: 'Poppins')),
                          Text(item['nama_ruangan'].toString(), style: TextStyle(fontSize: 40, height: 1, fontFamily: 'Poppins')),
                          SizedBox(height: 40),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 168, 232, 170),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              minimumSize: Size(100, 100),
                            ),
                            onPressed: () {
                              confirmob(item['nama_ruangan']);
                              refreshruanganbersihkan();
                            },
                            child: Column(
                              children: [Icon(Icons.check, size: 50), SizedBox(height: 10), Text("Confirm", style: TextStyle(fontFamily: 'Poppins'))],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
