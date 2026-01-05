import 'dart:developer';

import 'package:Project_SPA/function/ip_address.dart';
import 'package:Project_SPA/function/our_drawer.dart';
import 'package:Project_SPA/resepsionis/transaksi_fasilitas.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'dart:async';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:Project_SPA/resepsionis/transaksi_food.dart';
import 'package:Project_SPA/resepsionis/transaksi_massage.dart';

class ListTerapis extends StatefulWidget {
  const ListTerapis({super.key});

  @override
  State<ListTerapis> createState() => _ListTerapisState();
}

class _ListTerapisState extends State<ListTerapis> {
  var dio = Dio();
  Timer? _refreshTimer;
  RxList<Map<String, dynamic>> dataTerapis = <Map<String, dynamic>>[].obs;
  Future<void> getdataTerapis() async {
    try {
      var response = await dio.get(
        '${myIpAddr()}/listpekerja/dataTampilanTerapis',
      );
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "id_karyawan": item['id_karyawan'],
              "nama_karyawan": item['nama_karyawan'],
              "status": item['status'],
              "is_occupied": item['is_occupied'],
            };
          }).toList();
      setState(() {
        dataTerapis.assignAll(fetcheddata);
      });
    } catch (e) {
      log("Error di fn Getdapaketmassage : $e");
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getdataTerapis();
    _refreshTimer = Timer.periodic(Duration(seconds: 40), (timer) {
      getdataTerapis();
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _refreshTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: OurDrawer(),
      appBar: AppBar(
        title: Text(
          'PLATINUM',
          style: TextStyle(fontSize: 60, fontFamily: 'Poppins'),
        ),
        centerTitle: true,
        toolbarHeight: 80,
        backgroundColor: Color(0XFFFFE0B2),
        automaticallyImplyLeading: false,
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
                                  dataTerapis.isEmpty
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
                                                8, // 4 Item dalam 1 Row
                                            crossAxisSpacing:
                                                10, // Space Horizontal tiap item
                                            mainAxisSpacing:
                                                10, // Space Vertical tiap item
                                            // Width to height ratio (e.g., width: 2, height: 3)
                                            childAspectRatio: 1,
                                          ),
                                          // Nanti Looping data disini
                                          itemCount: dataTerapis.length,
                                          itemBuilder: (context, index) {
                                            var item = dataTerapis[index];
                                            bool isOccupied =
                                                item['is_occupied'] == 1;

                                            return GestureDetector(
                                              onTap: () {
                                                if (isOccupied) {
                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (
                                                          context,
                                                        ) => AlertDialog(
                                                          title: Text(
                                                            "Selesaikan Terapis?",
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed:
                                                                  () =>
                                                                      Navigator.of(
                                                                        context,
                                                                      ).pop(),
                                                              child: Text(
                                                                "Tidak",
                                                              ),
                                                            ),
                                                            TextButton(
                                                              onPressed: () async {
                                                                try {
                                                                  // Call API to update is_occupied in the database
                                                                  final response = await dio.post(
                                                                    '${myIpAddr()}/listpekerja/update_occupied',
                                                                    data: {
                                                                      'id_karyawan':
                                                                          item['id_karyawan'],
                                                                      'is_occupied':
                                                                          0,
                                                                    },
                                                                  );

                                                                  if (response
                                                                          .statusCode ==
                                                                      200) {
                                                                    // Update UI if backend update is successful
                                                                    dataTerapis[index]['is_occupied'] =
                                                                        0;
                                                                    dataTerapis
                                                                        .refresh();
                                                                    await getdataTerapis();
                                                                    Navigator.of(
                                                                  context,
                                                                ).pop();
                                                              } else {
                                                                // Show error if backend failed
                                                                CherryToast.error(
                                                                  title: const Text("Gagal"),
                                                                  description: const Text("Gagal menyelesaikan terapis."),
                                                                ).show(Get.context!);
                                                              }
                                                            } catch (e) {
                                                              CherryToast.error(
                                                                title: const Text("Error"),
                                                                description: Text("Terjadi kesalahan: $e"),
                                                              ).show(Get.context!);
                                                            }
                                                          },
                                                          child: Text("Ya"),
                                                        ),
                                                      ],
                                                        ),
                                                  );
                                                }
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color:
                                                      isOccupied
                                                          ? Color(0xFFFF8282)
                                                          : Color(0xFFA6FF8F),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      item['id_karyawan'],
                                                      style: const TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 28,
                                                        fontFamily: 'Poppins',
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                        top: 0,
                                                      ),
                                                      child: Text(
                                                        item['nama_karyawan'],
                                                        style: const TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 25,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
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
            ],
          ),
        ),
      ),
    );
  }
}
