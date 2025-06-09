import 'package:Project_SPA/resepsionis/detail_food_n_beverages.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:get/get.dart';
import 'package:Project_SPA/function/ip_address.dart';
import 'package:Project_SPA/kamar_terapis/terapis_bekerja.dart';
import 'package:Project_SPA/kamar_terapis/terapis_mgr.dart';
import 'package:dio/dio.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'dart:developer';

class FoodAddOnController extends GetxController {
  FoodAddOnController() {
    _getMenu();
  }

  KamarTerapisMgr _kamarTerapisMgr = KamarTerapisMgr();
  var dio = Dio();

  RxList<Map<String, dynamic>> dataMenu = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> selectedDataMenu = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> datafnb = <Map<String, dynamic>>[].obs;

  void addItem(Map<String, dynamic> newItem) {
    final existsIndex = selectedDataMenu.indexWhere(
      (item) => item['id_fnb'] == newItem['id_fnb'],
    );

    if (existsIndex != -1) {
      var data = selectedDataMenu[existsIndex];
      data['jlh'] += 1;
      data['harga_total'] = data['harga_fnb'] * data['jlh'];
    } else {
      selectedDataMenu.add({
        ...newItem,
        'harga_total': newItem['harga_fnb'],
        'is_addon': 1,
      });
    }

    // force refresh obs variable
    selectedDataMenu.refresh();

    print(selectedDataMenu);
  }

  void removeItem(String id_fnb) {
    var exists = selectedDataMenu.indexWhere(
      (item) => item['id_fnb'] == id_fnb,
    );

    if (exists != -1) {
      selectedDataMenu.removeAt(exists);
    }
  }

  Future<void> _getMenu() async {
    try {
      var response = await dio.get('${myIpAddr()}/fnb/menu');

      List<dynamic> responseData = response.data;

      dataMenu.assignAll(
        responseData.map((item) => item as Map<String, dynamic>).toList(),
      );

      log("isi data menu $dataMenu");
    } catch (e) {
      log("Error di fn Get Menu $e");
    }
  }

  Future<void> _postData() async {
    try {
      var data = _kamarTerapisMgr.getData();

      var response = await dio.post(
        '${myIpAddr()}/fnb/store_addon',
        data: {
          "id_transaksi": data['idTransaksi'],
          "detail_trans": selectedDataMenu,
        },
      );

      if (response.statusCode == 200) {
        _kamarTerapisMgr.updateFood(data['idTransaksi']);
        await Future.delayed(Duration(milliseconds: 300));

        selectedDataMenu.clear();
        Get.offAll(() => TerapisBekerja());
      }
    } catch (e) {
      log("Error di fn Post Data $e");
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

      datafnb.clear();
      datafnb.assignAll(fetcheddata);
      datafnb.refresh();
      isloading = true;
    } catch (e) {
      isloading = true;
      log("Error di fn getdatafnb : $e");
    }
  }

  @override
  void onInit() {
    super.onInit();
    isloading = false;
    getdatafnb();
  }
}

Map<String, int> itemTapCounts = {};
String? retrieveindex = '';
bool isloading = false;

// ignore: must_be_immutable
class FoodAddOn extends StatefulWidget {
  FoodAddOn({super.key}) {
    Get.put(FoodAddOnController());
  }

  @override
  State<FoodAddOn> createState() => _FoodAddOnState();
}

class _FoodAddOnState extends State<FoodAddOn> {
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    itemTapCounts.clear();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<FoodAddOnController>();
    int sisastok = 0;

    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            "Add On (+)",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 40,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        backgroundColor: Color(0XFFFFE0B2),
      ),
      body: PopScope(
        canPop: true,
        onPopInvoked: (didPop) {
          if (didPop) c.selectedDataMenu.clear();
        },
        child: Container(
          height: Get.height,
          width: Get.width,
          padding: const EdgeInsets.only(left: 80, right: 80),
          decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                Text(
                  "Food & Beverages",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 30),
                Container(
                  height: 250,
                  child: Scrollbar(
                    thumbVisibility: true,
                    controller: _scrollController,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Obx(
                        () => GridView.builder(
                          controller: _scrollController,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3, // 3 item 1 row
                                crossAxisSpacing:
                                    60, // space horizontal tiap item
                                mainAxisSpacing: 25, // space vertical tiap item

                                childAspectRatio: 20 / 12,
                              ),
                          itemCount: c.dataMenu.length,
                          itemBuilder: (context, index) {
                            RxBool _isTapped = false.obs;
                            var item = c.dataMenu[index];
                            int sisastok = 0;

                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapDown: (_) {
                                _isTapped.value = true;
                              },
                              onTapUp: (_) async {
                                await Future.delayed(
                                  const Duration(milliseconds: 100),
                                );
                                for (var fnb in c.datafnb.where(
                                  (p) => p['nama_fnb'] == item['nama_fnb'],
                                )) {
                                  sisastok =
                                      int.tryParse(
                                        fnb['stok_fnb'].toString(),
                                      ) ??
                                      0;
                                }
                                log('sisa stok : $sisastok');
                                String itemname = item['nama_fnb'];

                                retrieveindex = itemname;
                                if (retrieveindex != null &&
                                    itemTapCounts.containsKey(retrieveindex)) {
                                  itemTapCounts[retrieveindex!] =
                                      itemTapCounts[retrieveindex]! + 1;
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
                                  if (itemTapCounts[retrieveindex]! >
                                      sisastok) {
                                    CherryToast.error(
                                      title: Text('Error'),
                                      description: Text(
                                        'Penggunaan item melebihi stok',
                                      ),
                                    ).show(context);
                                  } else {
                                    c.addItem({
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
                                _isTapped.value = false;
                              },
                              onTapCancel: () {
                                _isTapped.value = false;
                              },
                              child: Obx(
                                () => Transform.scale(
                                  scale: _isTapped.isTrue ? 0.80 : 1.0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                        255,
                                        64,
                                        97,
                                        55,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.food_bank,
                                          size: 50,
                                          color: Colors.white,
                                        ),
                                        Text(
                                          "${item['nama_fnb']}",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                        Text(
                                          "Rp. ${item['harga_fnb']}",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 30),
                Text(
                  "List Pesanan: ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(
                  height: 100,
                  child: SingleChildScrollView(
                    child: Obx(() {
                      if (c.selectedDataMenu.isEmpty) return Text("");

                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text("Nama Item")),
                              Expanded(
                                child: Text(
                                  "Jumlah",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontFamily: 'Poppins'),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "Harga Satuan",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontFamily: 'Poppins'),
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "Harga Total",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontFamily: 'Poppins'),
                                      ),
                                    ),
                                    Expanded(child: Text("")),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          for (var item in c.selectedDataMenu)
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "${item['nama_fnb']}",
                                    style: TextStyle(fontFamily: 'Poppins'),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    "x${item['jlh']}",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontFamily: 'Poppins'),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    "Rp. ${item['harga_fnb']}",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontFamily: 'Poppins'),
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "Rp. ${item['harga_total']}",
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: TextButton(
                                          onPressed: () {
                                            for (var fnb in datafnb.where(
                                              (p) =>
                                                  p['nama_fnb'] ==
                                                  item['nama_fnb'],
                                            )) {
                                              sisastok =
                                                  int.tryParse(
                                                    fnb['stok_fnb'].toString(),
                                                  ) ??
                                                  0;
                                            }
                                            if (retrieveindex != null) {
                                              String itemname =
                                                  item['nama_fnb'];
                                              retrieveindex = itemname;
                                              itemTapCounts[retrieveindex!] = 0;
                                            }
                                            c.removeItem(item['id_fnb']);
                                          },
                                          child: Text(
                                            "X",
                                            textAlign: TextAlign.right,
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              height: 1.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      );
                    }),
                  ),
                ),
                Divider(),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(child: Text("")),
                    Expanded(
                      child: Text(
                        "Total Add On: ",
                        textAlign: TextAlign.right,
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Obx(() {
                              var sum = 0;
                              for (
                                var i = 0;
                                i < c.selectedDataMenu.length;
                                i++
                              ) {
                                sum +=
                                    c.selectedDataMenu[i]['harga_total'] as int;
                              }
                              return Text(
                                "Rp. ${sum}",
                                textAlign: TextAlign.right,
                                style: TextStyle(fontFamily: 'Poppins'),
                              );
                            }),
                          ),
                          Expanded(child: Text("")),
                        ],
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      minimumSize: Size(100, 40),
                    ),
                    onPressed: () async {
                      await c._postData();
                    },
                    child: Text(
                      "Proses",
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
