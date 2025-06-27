import 'dart:async';
import 'dart:math' hide log;
import 'package:Project_SPA/owner/download_splash.dart';
import 'package:Project_SPA/resepsionis/detail_food_n_beverages.dart';
import 'package:Project_SPA/ruang_tunggu/main_rt.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:get/get.dart';
import 'dart:io'; // For file operations
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:Project_SPA/function/ip_address.dart';
import 'package:Project_SPA/function/our_drawer.dart';
import 'package:Project_SPA/office_boy/image_mgr.dart';
import 'package:Project_SPA/office_boy/main_ob.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dio/dio.dart';
import 'dart:developer';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';

class laporankomisi extends StatefulWidget {
  const laporankomisi({super.key});

  @override
  State<laporankomisi> createState() => _laporankomisiState();
}

class _laporankomisiState extends State<laporankomisi>
    with SingleTickerProviderStateMixin {
  RxString selectedvalue = DateTime.now().month.toString().obs;
  RxString selectedyearvalue = DateTime.now().year.toString().obs;
  RxList<Map<String, dynamic>> datakomisi = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> datakomisitahunan = <Map<String, dynamic>>[].obs;
  final formatnominal = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');
  int currentmonth = DateTime.now().month;
  int currentyear = DateTime.now().year;
  int pilihanbulan = 1;
  int pilihantahun = 1;
  late TabController _tabController;
  int selectedtabindex = 1;

  var dio = Dio();

  Future<void> getdatakomisi(bulan, tahun) async {
    try {
      print('ini jalan');
      var response = await dio.get(
        '${myIpAddr()}/cekkomisi/listkomisiowner',
        data: {'month': bulan, 'year': tahun},
      );
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "id_karyawan": item['id_karyawan'],
              "nama_karyawan": item['nama_karyawan'],
              "total_komisi": item['total_komisi'],
            };
          }).toList();
      setState(() {
        datakomisi.clear();
        datakomisi.assignAll(fetcheddata);
        datakomisi.refresh();
      });
    } catch (e) {
      log("Error di fn getdatakomisi : $e");
    }
  }

  Future<void> getdatakomisitahunan(tahun) async {
    try {
      print('ini jalan');
      var response = await dio.get(
        '${myIpAddr()}/cekkomisi/listkomisiownertahunan',
        data: {'year': tahun},
      );
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "id_karyawan": item['id_karyawan'],
              "nama_karyawan": item['nama_karyawan'],
              "total_komisi": item['total_komisi'],
            };
          }).toList();
      setState(() {
        datakomisitahunan.clear();
        datakomisitahunan.assignAll(fetcheddata);
        datakomisitahunan.refresh();
      });
    } catch (e) {
      log("Error di fn getdatakomisi : $e");
    }
  }

  @override
  void initState() {
    super.initState();
    pilihanbulan = currentmonth;
    pilihantahun = currentyear;
    getdatakomisi(currentmonth, currentyear);
    getdatakomisitahunan(currentyear);
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        selectedtabindex = _tabController.index;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          width: Get.width,
          height: Get.height,
          color: Color(0XFFFFE0B2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: EdgeInsets.only(top: 50),
                  child: Text(
                    'Laporan Komisi Terapis & Gro',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      height: 1,
                      fontSize: 50,
                    ),
                  ),
                ),
              ),
              selectedtabindex == 1
                  ? Container(
                    margin: EdgeInsets.only(top: 50),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Bulan : ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                            height: 1,
                            fontSize: 40,
                          ),
                        ),
                        Obx(
                          () => Container(
                            width: 140,
                            height: 55,
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.blue,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.red,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.grey[200],
                              ),
                              value: selectedvalue.value,
                              items:
                                  <String>[
                                    '1',
                                    '2',
                                    '3',
                                    '4',
                                    '5',
                                    '6',
                                    '7',
                                    '8',
                                    '9',
                                    '10',
                                    '11',
                                    '12',
                                  ].map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value == '1'
                                            ? 'Januari'
                                            : value == '2'
                                            ? 'Februari'
                                            : value == '3'
                                            ? 'Maret'
                                            : value == '4'
                                            ? 'April'
                                            : value == '5'
                                            ? 'Mei'
                                            : value == '6'
                                            ? 'Juni'
                                            : value == '7'
                                            ? 'Juli'
                                            : value == '8'
                                            ? 'Agustus'
                                            : value == '9'
                                            ? 'September'
                                            : value == '10'
                                            ? 'Oktober'
                                            : value == '11'
                                            ? 'September'
                                            : 'Desember',
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (String? newValue) {
                                selectedvalue.value = newValue!;
                                pilihanbulan = int.parse(newValue);
                                print(pilihanbulan);
                              },
                            ),
                          ),
                        ),
                        SizedBox(width: 20),
                        Text(
                          'Tahun : ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                            height: 1,
                            fontSize: 40,
                          ),
                        ),
                        Obx(
                          () => Container(
                            width: 140,
                            height: 55,
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.blue,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.red,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.grey[200],
                              ),
                              value: selectedyearvalue.value,
                              items:
                                  List.generate(
                                    DateTime.now().year - 2000 + 1,
                                    (index) => 2000 + index,
                                  ).map((int year) {
                                    return DropdownMenuItem<String>(
                                      value: year.toString(),
                                      child: Text(year.toString()),
                                    );
                                  }).toList(),
                              onChanged: (String? newValue) {
                                selectedyearvalue.value = newValue!;
                                pilihantahun = int.parse(newValue);
                                print(pilihantahun);
                              },
                            ),
                          ),
                        ),
                        SizedBox(width: 20),
                        Container(
                          width: 210,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              getdatakomisi(pilihanbulan, pilihantahun);
                              log(selectedtabindex.toString());
                            },
                            child: Text(
                              'Cek Komisi',
                              style: TextStyle(
                                fontSize: 30,
                                color: Colors.black,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFFCEFCB),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  : selectedtabindex == 0
                  ? Container(child: Text('harian'))
                  : Container(
                    margin: EdgeInsets.only(top: 50),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Tahun : ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                            height: 1,
                            fontSize: 40,
                          ),
                        ),
                        Obx(
                          () => Container(
                            width: 140,
                            height: 55,
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.blue,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.red,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.grey[200],
                              ),
                              value: selectedyearvalue.value,
                              items:
                                  List.generate(
                                    DateTime.now().year - 2000 + 1,
                                    (index) => 2000 + index,
                                  ).map((int year) {
                                    return DropdownMenuItem<String>(
                                      value: year.toString(),
                                      child: Text(year.toString()),
                                    );
                                  }).toList(),
                              onChanged: (String? newValue) {
                                selectedyearvalue.value = newValue!;
                                pilihantahun = int.parse(newValue);
                                print(pilihantahun);
                              },
                            ),
                          ),
                        ),
                        SizedBox(width: 20),
                        Container(
                          width: 210,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              getdatakomisitahunan(pilihantahun);
                              log(datakomisitahunan.toString());
                            },
                            child: Text(
                              'Cek Komisi',
                              style: TextStyle(
                                fontSize: 30,
                                color: Colors.black,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFFCEFCB),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              Center(
                child: DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 50),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        width: Get.width - 200,
                        height: 60,
                        child: TabBar(
                          controller: _tabController,
                          tabs: [
                            Tab(text: 'Harian'),
                            Tab(text: 'Bulanan'),
                            Tab(text: 'Tahunan'),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        width: Get.width - 200,
                        height: 350,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // ini tab 1
                            datakomisi.isEmpty
                                ? Center(
                                  child: Text(
                                    'Data komisi untuk bulan $pilihanbulan di tahun $pilihantahun tidak tersedia',
                                  ),
                                )
                                : ListView.builder(
                                  padding: EdgeInsets.only(top: 10),
                                  itemCount: datakomisi.length,
                                  itemBuilder: (context, index) {
                                    var item = datakomisi[index];
                                    return Container(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                margin: EdgeInsets.only(
                                                  left: 20,
                                                ),
                                                width: 60,
                                                child: Text(
                                                  item['id_karyawan'],
                                                  textAlign: TextAlign.left,
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontFamily: 'Poppins',
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 5),
                                              Container(
                                                child: Text(
                                                  '-',
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontFamily: 'Poppins',
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 15),
                                              Container(
                                                width: 75,
                                                child: Text(
                                                  item['nama_karyawan'],
                                                  textAlign: TextAlign.left,
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontFamily: 'Poppins',
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Container(
                                                  margin: EdgeInsets.only(
                                                    left: 20,
                                                    right: 10,
                                                  ),
                                                  width: 140,
                                                  child: Text(
                                                    formatnominal
                                                        .format(
                                                          item['total_komisi'],
                                                        )
                                                        .toString(),
                                                    textAlign: TextAlign.right,
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Divider(color: Colors.black),
                                        ],
                                      ),
                                    );
                                  },
                                ),

                            // ini tab 2
                            datakomisi.isEmpty
                                ? Center(
                                  child: Text(
                                    'Data komisi untuk bulan $pilihanbulan di tahun $pilihantahun tidak tersedia',
                                  ),
                                )
                                : ListView.builder(
                                  padding: EdgeInsets.only(top: 10),
                                  itemCount: datakomisi.length,
                                  itemBuilder: (context, index) {
                                    var item = datakomisi[index];
                                    return Container(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                margin: EdgeInsets.only(
                                                  left: 20,
                                                ),
                                                width: 60,
                                                child: Text(
                                                  item['id_karyawan'],
                                                  textAlign: TextAlign.left,
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontFamily: 'Poppins',
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 5),
                                              Container(
                                                child: Text(
                                                  '-',
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontFamily: 'Poppins',
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 15),
                                              Container(
                                                width: 75,
                                                child: Text(
                                                  item['nama_karyawan'],
                                                  textAlign: TextAlign.left,
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontFamily: 'Poppins',
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Container(
                                                  margin: EdgeInsets.only(
                                                    left: 20,
                                                    right: 10,
                                                  ),
                                                  width: 140,
                                                  child: Text(
                                                    formatnominal
                                                        .format(
                                                          item['total_komisi'],
                                                        )
                                                        .toString(),
                                                    textAlign: TextAlign.right,
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Divider(color: Colors.black),
                                        ],
                                      ),
                                    );
                                  },
                                ),

                            // ini tab 3
                            datakomisitahunan.isEmpty
                                ? Center(
                                  child: Text(
                                    'Data komisi untuk tahun $pilihantahun tidak tersedia',
                                  ),
                                )
                                : ListView.builder(
                                  padding: EdgeInsets.only(top: 10),
                                  itemCount: datakomisitahunan.length,
                                  itemBuilder: (context, index) {
                                    var item = datakomisitahunan[index];
                                    return Container(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                margin: EdgeInsets.only(
                                                  left: 20,
                                                ),
                                                width: 60,
                                                child: Text(
                                                  item['id_karyawan'],
                                                  textAlign: TextAlign.left,
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontFamily: 'Poppins',
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 5),
                                              Container(
                                                child: Text(
                                                  '-',
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontFamily: 'Poppins',
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 15),
                                              Container(
                                                width: 75,
                                                child: Text(
                                                  item['nama_karyawan'],
                                                  textAlign: TextAlign.left,
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontFamily: 'Poppins',
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Container(
                                                  margin: EdgeInsets.only(
                                                    left: 20,
                                                    right: 10,
                                                  ),
                                                  width: 140,
                                                  child: Text(
                                                    formatnominal
                                                        .format(
                                                          item['total_komisi'],
                                                        )
                                                        .toString(),
                                                    textAlign: TextAlign.right,
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Divider(color: Colors.black),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      drawer: OurDrawer(),
    );
  }
}
