import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:get/get.dart';
import 'package:Project_SPA/function/ip_address.dart';
import 'package:Project_SPA/function/me.dart';
import 'package:Project_SPA/function/our_drawer.dart';
import 'package:Project_SPA/function/token.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:dio/dio.dart';

class MainKitchen extends StatefulWidget {
  const MainKitchen({super.key});

  @override
  State<MainKitchen> createState() => _MainKitchenState();
}

class _MainKitchenState extends State<MainKitchen>
    with TickerProviderStateMixin {
  ScrollController _scrollControllerTab0 = ScrollController();
  ScrollController _scrollControllerTab1 = ScrollController();
  ScrollController _scrollControllerTab2 = ScrollController();
  // Tabcontroller utk mainkan index tabbar klo eksekusi fungsi
  late TabController _tabController;

  late WebSocketChannel _channel;
  Timer? _notifTimer; // macam settimeout, bikin retrigger

  Future<void> _connectToWebSocket() async {
    // replace http dengan ws
    var originalUrl = myIpAddr();
    var replacedUrl = originalUrl.replaceAll("http", "ws");

    // ambil endpoint dari router yg udh d buat
    var wsUri = Uri.parse("$replacedUrl/fnb/ws-kitchen");

    // Buat koneksi websocket
    _channel = IOWebSocketChannel.connect(wsUri);

    _channel.stream.listen(
      (message) async {
        _notifTimer?.cancel();
        _notifTimer = Timer(Duration(seconds: 1), () {
          final data = jsonDecode(message);
          for (var i = 0; i < 1; i++) {
            Get.dialog(
              WillPopScope(
                onWillPop: () async => false, // disable back button
                child: AlertDialog(
                  title: Center(child: Text("Pesanan Baru!")),
                  content: Container(
                    height: Get.height - 100,
                    width: Get.width - 200,
                    child: Center(
                      child: Text(
                        "Pesanan Masuk! ${data['id_transaksi']}",
                        style: TextStyle(fontSize: 30),
                      ),
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('OK'),
                      onPressed: () async {
                        await getPesanan();
                        _tabController.animateTo(0);

                        // if (mounted) {
                        //   setState(() {});
                        // }

                        Get.back();
                      },
                    ),
                  ],
                ),
              ),
              barrierDismissible: false, // disable tap diluar
            );
          }

          print(data);
        });
      },
      onError: (err) {
        log("Error Websocket $err");
      },
      onDone: () {
        log("Websocket Closed");
      },
    );
  }

  var dio = Dio();
  // RxInt activeTab = 0.obs;
  // Loading Tab Bar
  bool isLoading = false;

  RxList dataPesanan = [].obs;
  RxList<Map<String, dynamic>> dataDetailPesanan = <Map<String, dynamic>>[].obs;

  Future<void> getPesanan({String status = "pending"}) async {
    try {
      var response = await dio.get("${myIpAddr()}/kitchen/data?status=$status");

      List<dynamic> responseData = response.data;

      dataPesanan.clear();

      for (var i = 0; i < responseData.length; i++) {
        dataPesanan.add(responseData[i]);
      }

      print("Hasil Data Pesanan $dataPesanan");
    } catch (e) {
      if (e is DioException) {
        log("Error di getPesanan ${e.response!.data}");
      }
    }
  }

  var _openedIdTrans = "".obs;
  var _openedNamaRuangan = "".obs;
  var _openedIdBatch = "".obs;

  Future<void> _detailPesanan(
    String idTrans,
    String idBatch, {
    String status = "pending",
  }) async {
    try {
      print("Id Trans = $idTrans, status = $status");

      var response = await dio.get(
        "${myIpAddr()}/kitchen/detailTrans",
        queryParameters: {
          "id_transaksi": idTrans,
          "id_batch": idBatch,
          "status": status,
        },
      );

      List<dynamic> responseData = response.data;

      dataDetailPesanan.assignAll(
        responseData.map((e) => Map<String, dynamic>.from(e)).toList(),
      );

      print("Hasil Data  Pesanan $dataDetailPesanan");
    } catch (e) {
      log("Error di getPesanan $e");
    }
  }

  Future<void> _prosesPesanan(
    String status,
    String idTrans,
    String idBatch,
  ) async {
    try {
      var response = await dio.put(
        '${myIpAddr()}/kitchen/updatePesanan',
        data: {"id_transaksi": idTrans, "id_batch": idBatch, "status": status},
      );

      if (response.statusCode == 200) {
        if (status == "process") {
          await getPesanan(status: "process");

          _tabController.animateTo(1);
        } else if (status == "done") {
          await getPesanan(status: "done");

          _tabController.animateTo(2);
        }

        Get.back();
        log("Sukses Update");
      }
    } catch (e) {
      log("Gagal di proses pesanan $e");
    } finally {
      setState(() {});
    }
  }

  Timer? _timerWebSocket;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getPesanan();
    _profileUser();
    _tabController = TabController(length: 3, vsync: this);

    // Delay the WebSocket connection to avoid crashes
    _timerWebSocket = Timer(Duration(milliseconds: 1300), () {
      _connectToWebSocket();
    });
  }

  // Harus di Init ke variabel supaya shared_preferences nyala
  String _idKaryawan = '';
  Future<void> _profileUser() async {
    try {
      final pref = await getTokenSharedPref();
      var response = await getMyData(pref);

      if (response != null && response['data'] != null) {
        setState(() {
          _idKaryawan = response['data']['id_karyawan'];
        });
      }

      print("Nama: $_idKaryawan, Jabatan: Bla");
    } catch (e) {
      log("Error di main kitchen $e");
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _scrollControllerTab0.dispose();
    _scrollControllerTab1.dispose();
    _scrollControllerTab2.dispose();
    _channel.sink.close();
    _timerWebSocket?.cancel();
    _notifTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  RxMap<dynamic, dynamic> isLoadingDetail = {}.obs;

  void _showDialogKitchen(String status) async {
    isLoadingDetail[_openedIdTrans.value] = true;

    // Tarik data detail dlu bru buka modal. buat maksimal attempt 3x. utk refetch
    int maxRetries = 3;
    int retryDelayMs = 500;
    int attempt = 0;

    while (attempt < maxRetries) {
      await _detailPesanan(
        _openedIdTrans.value,
        _openedIdBatch.value,
        status: status,
      );

      if (dataDetailPesanan.isNotEmpty) {
        // setState(() {
        //   isLoadingDetail[idTransaksi] = false;
        // });
        isLoadingDetail[_openedIdTrans.value] = false;
        break; // Success: exit loop
      }

      attempt++;
      await Future.delayed(Duration(milliseconds: retryDelayMs));
    }

    // await _detailPesanan(status: status, idTransaksi);

    // Optionally handle if still empty
    if (dataDetailPesanan.isEmpty) {
      Get.snackbar(
        "Data Kosong",
        "Gagal mengambil detail pesanan. Silakan coba lagi.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.dialog(
      AlertDialog(
        title: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Spacer(),
                Text(
                  status == "pending"
                      ? "NEW TRANSACTION"
                      : status == "process"
                      ? "process"
                      : "READY TO SERVE",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
                Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    print('Close button pressed');
                    Get.back();
                  },
                ),
              ],
            ),
            Divider(),
          ],
        ),
        content: SizedBox(
          height: Get.height - 200,
          width: Get.width,
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      "No Transaksi",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(":"),
                  SizedBox(width: 10),
                  Expanded(
                    child: Obx(
                      () => Text(
                        "${_openedIdTrans.value}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      "Room",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(":"),
                  SizedBox(width: 10),
                  Expanded(
                    child: Obx(
                      () => Text(
                        "${_openedNamaRuangan.value}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  SizedBox(
                    width: 300,
                    child: Text(
                      "Nama Item",
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: Text(
                      "Jumlah",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(
                      "Satuan",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "Status",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 200,
                child: Obx(
                  () => ListView.builder(
                    itemCount: dataDetailPesanan.length,
                    itemBuilder: (context, index) {
                      var data = dataDetailPesanan[index];

                      // _openedIdTrans.value = data['id_transaksi'];
                      // _openedIdDetail.value = data['id_detail_transaksi'];
                      // _openedNamaRuangan.value = data['nama_ruangan'];

                      return Row(
                        children: [
                          SizedBox(
                            width: 300,
                            child: Text(
                              data['nama_fnb'],
                              style: TextStyle(
                                fontWeight: FontWeight.normal,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 180,
                            child: Text(
                              "x${data['qty']}",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.normal,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: Text(
                              data['satuan'],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.normal,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              status == "pending"
                                  ? "NEW TRANSACTION"
                                  : status == "process"
                                  ? "process"
                                  : "READY TO SERVE",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.normal,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              Divider(),
              // if status == pending awalnya. ak buang.
              Column(
                children: [
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.end,
                  //   children: [
                  //     Spacer(),
                  //     Spacer(),
                  //     Flexible(child: Icon(Icons.check)),
                  //     Expanded(
                  //       child: Text(
                  //         "Kirim Notifikasi Ke Ruangan",
                  //         textAlign: TextAlign.right,
                  //         style: TextStyle(fontFamily: 'Poppins'),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  if (status != "done")
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (status == "pending") {
                            await _prosesPesanan(
                              "process",
                              _openedIdTrans.value,
                              _openedIdBatch.value,
                            );
                          } else if (status == "process") {
                            await _prosesPesanan(
                              "done",
                              _openedIdTrans.value,
                              _openedIdBatch.value,
                            );
                          } else {
                            Get.back();
                          }
                        },
                        child: Text(
                          status == "pending"
                              ? "process"
                              : status == "process"
                              ? "Selesaikan Pesanan?"
                              : "Done",
                        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: Color(0XFFFFE0B2),
        title: Center(
          child: Padding(
            padding: const EdgeInsets.only(right: 5),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.asset("assets/spa.jpg", height: 100),
            ),
          ),
        ),
      ),
      drawer: OurDrawer(),
      body: Container(
        padding: const EdgeInsets.only(top: 20),
        height: Get.height,
        width: Get.width,
        decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
        child: Column(
          children: [
            Text(
              "KITCHEN",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20), //Spacing
            Expanded(
              // Expanded utk makan semua space dicolumn ini
              child: DefaultTabController(
                // length 3 = 3 Menu
                length: 3,
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(left: 40, right: 40),
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      // Wrap appbar di container utk control tingginya
                      height: 50, // height tabbar
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          onTap: (index) async {
                            // cegah klo proses API blm slesai
                            if (isLoading) return;

                            setState(() {
                              isLoading = true;
                            });

                            try {
                              switch (index) {
                                case 0:
                                  await getPesanan(status: "pending");
                                  break;
                                case 1:
                                  await getPesanan(status: "process");
                                  break;
                                case 2:
                                  await getPesanan(status: "done");
                                  break;
                              }
                            } finally {
                              setState(() {
                                isLoading = false;
                              });
                            }
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
                          tabs: [
                            Tab(text: "Pesanan Masuk"),
                            Tab(text: "Pesanan Diproses"),
                            Tab(text: "Pesanan Selesai"),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      // ambil semua remaining space utk content
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 40,
                          right: 40,
                          bottom: 20,
                        ),
                        child: TabBarView(
                          controller: _tabController,
                          physics:
                              const NeverScrollableScrollPhysics(), // disable sliding
                          children: [
                            // Konten1
                            _buildTabContent("pending", _scrollControllerTab0),
                            // Konten2
                            _buildTabContent("process", _scrollControllerTab1),
                            // Konten3
                            _buildTabContent("done", _scrollControllerTab2),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Buat widget reusable for tab content
  Widget _buildTabContent(String status, ScrollController scrollController) {
    return Container(
      padding: const EdgeInsets.only(top: 10, left: 40, right: 40),
      decoration: BoxDecoration(
        color: Colors.grey,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Obx(
        () => Scrollbar(
          thumbVisibility: true,
          controller: scrollController,
          child: ListView.builder(
            controller: scrollController,
            itemCount: dataPesanan.isEmpty ? 1 : dataPesanan.length,
            itemBuilder: (context, index) {
              if (dataPesanan.isEmpty) {
                return const Center(child: Text("No Data"));
              }

              var data = dataPesanan[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 10, right: 8),
                padding: const EdgeInsets.only(left: 10, right: 10),
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Pesanan ${data['id_transaksi']}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        fontSize: 20,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Room: ${data['nama_ruangan'] ?? '-'}",
                            style: const TextStyle(
                              fontSize: 24,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: () {
                                _openedNamaRuangan.value =
                                    data['nama_ruangan'] ?? "-";
                                _openedIdTrans.value = data['id_transaksi'];
                                _openedIdBatch.value = data['id_batch'];

                                _showDialogKitchen(status);
                              },
                              child:
                                  isLoadingDetail[data['id_transaksi']] == true
                                      ? const CircularProgressIndicator()
                                      : const Text("Detail"),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
