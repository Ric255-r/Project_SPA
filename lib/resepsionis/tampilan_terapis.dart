import 'dart:developer';

import 'package:Project_SPA/function/ip_address.dart';
import 'package:Project_SPA/function/our_drawer.dart';
import 'package:Project_SPA/resepsionis/transaksi_fasilitas.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:Project_SPA/resepsionis/transaksi_food.dart';
import 'package:Project_SPA/resepsionis/transaksi_massage.dart';

class TampilanTerapis extends StatefulWidget {
  const TampilanTerapis({super.key});

  @override
  State<TampilanTerapis> createState() => _TampilanTerapisState();
}

class _TampilanTerapisState extends State<TampilanTerapis> {
  var dio = Dio();
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
                                            return Container(
                                              decoration: BoxDecoration(
                                                color:
                                                    item['is_occupied'] == 0
                                                        ? Color(0xFFA6FF8F)
                                                        : Color(0xFFFF8282),
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
