import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:Project_SPA/admin/listpaket.dart';
import 'package:Project_SPA/admin/listpekerja.dart';
import 'package:Project_SPA/admin/listpromo.dart';
import 'package:Project_SPA/admin/listroom.dart';
import 'package:Project_SPA/admin/listuser.dart';
import 'package:Project_SPA/admin/regis_locker.dart';
import 'package:Project_SPA/admin/regis_paket.dart';
import 'package:Project_SPA/admin/regis_pekerja.dart';
import 'package:Project_SPA/admin/regis_promo.dart';
import 'package:Project_SPA/admin/regis_room.dart';
import 'package:Project_SPA/admin/regis_users.dart';
import 'package:Project_SPA/function/admin_drawer.dart';
import 'package:Project_SPA/function/ip_address.dart';
import 'package:Project_SPA/kamar_terapis/terapis_bekerja.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:Project_SPA/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LaporanOB extends StatefulWidget {
  const LaporanOB({super.key});

  @override
  State<LaporanOB> createState() => _LaporanOBState();
}

class _LaporanOBState extends State<LaporanOB> {
  late Future<List<Map<String, dynamic>>> futureData;

  @override
  void initState() {
    super.initState();
    futureData = fetchData().then((data) {
      dataList = data;
      filteredList = data;
      return data;
    });
  }

  var dio = Dio();

  Timer? _debounce;

  List<Map<String, dynamic>> dataList = [];
  List<Map<String, dynamic>> filteredList = [];
  TextEditingController textcari = TextEditingController();

  Future<List<Map<String, dynamic>>> fetchData() async {
    try {
      final response = await Dio().get('${myIpAddr()}/laporan/laporanob');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception("Failed to load data: ${response.statusCode}");
      }
    } on DioException catch (e) {
      throw Exception("Dio error: ${e.message}");
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();

    textcari.dispose();
  }

  void dialogDetail(BuildContext context, Map<String, dynamic> item) {
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Center(
              child: Column(
                children: [
                  Text(
                    "Foto Laporan",
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 24),
                  ),
                  Divider(),
                ],
              ),
            ),
            content: SingleChildScrollView(
              child: Container(
                width: Get.width - 100,
                height: Get.height - 100,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: futureData,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    if (snapshot.hasData) {
                      // ✅ Decode foto_laporan
                      List<String> fotoList = [];
                      if (item['foto_laporan'] is String) {
                        try {
                          fotoList = List<String>.from(
                            jsonDecode(item['foto_laporan']),
                          );
                        } catch (e) {
                          return Text('Failed to decode foto_laporan');
                        }
                      } else if (item['foto_laporan'] is List) {
                        fotoList = List<String>.from(item['foto_laporan']);
                      }

                      if (fotoList.isEmpty) {
                        return Center(
                          child: Text('Tidak ada foto yang tersedia'),
                        );
                      }
                      // ✅ Use ListView.builder to display images
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: fotoList.length,
                        itemBuilder: (context, index) {
                          final imageUrl =
                              "${myIpAddr()}/images/${fotoList[index]}";
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.network(imageUrl),
                          );
                        },
                      );
                    }

                    return Text("No data available.");
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.shortestSide < 600;
    return isMobile
        ? WidgetLaporanObMobile()
        : Scaffold(
          appBar: AppBar(
            title: Text(''),
            toolbarHeight: 30,
            centerTitle: true,
            backgroundColor: Color(0XFFFFE0B2),
          ),
          body: Container(
            decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
            width: Get.width,
            height: Get.height,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Text(
                      'Laporan OB',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 730),
                    child: Row(
                      children: [
                        Container(
                          width: 250,
                          height: 40,
                          child: TextField(
                            controller: textcari,
                            onChanged: (query) {
                              if (_debounce != null) {
                                _debounce!.cancel();
                              }
                              _debounce = Timer(
                                Duration(milliseconds: 1000),
                                () {
                                  // Adjust debounce delay here
                                  setState(() {
                                    filteredList =
                                        dataList.where((item) {
                                          return item['created_at']
                                              .toString()
                                              .toLowerCase()
                                              .contains(query.toLowerCase());
                                        }).toList();
                                  });
                                },
                              );
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Input Tanggal',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    width: 900,
                    height: 470,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      color: Colors.white,
                    ),
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: fetchData(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(),
                          ); // Loading state
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text("Error: ${snapshot.error}"),
                          ); // Error state
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return Center(
                            child: Text("No data available"),
                          ); // No data state
                        }

                        return ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final item = filteredList[index];
                            return Container(
                              margin: EdgeInsets.all(10),
                              height: 148,
                              decoration: BoxDecoration(
                                border: Border.all(width: 1),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 180,
                                            margin: EdgeInsets.only(
                                              left: 20,
                                              top: 5,
                                              bottom: 0,
                                              right: 5,
                                            ),
                                            child: Text(
                                              'Kode OB ',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 5,
                                            ),
                                            child: Container(
                                              width: 130,
                                              child: Text(
                                                item['id_karyawan'] ??
                                                    "Unknown",
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 180,
                                            margin: EdgeInsets.only(
                                              left: 20,
                                              top: 3,
                                              bottom: 0,
                                              right: 5,
                                            ),
                                            child: Text(
                                              'Nama Ruang ',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 3,
                                            ),
                                            child: Container(
                                              width: 130,
                                              child: Text(
                                                item['nama_ruangan'] ??
                                                    "Unknown",
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 180,
                                            margin: EdgeInsets.only(
                                              left: 20,
                                              top: 5,
                                              bottom: 5,
                                              right: 5,
                                            ),
                                            child: Text(
                                              'Tanggal Laporan ',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 5,
                                            ),
                                            child: Container(
                                              width: 130,
                                              child: Text(
                                                item['formatted_date'] ??
                                                    "Unknown",
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 180,
                                            margin: EdgeInsets.only(
                                              left: 20,
                                              top: 5,
                                              bottom: 5,
                                              right: 5,
                                            ),
                                            child: Text(
                                              'Status Laporan ',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 5,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  item['is_solved'] == 1
                                                      ? Icons.check_circle
                                                      : Icons.cancel,
                                                  color:
                                                      item['is_solved'] == 1
                                                          ? Colors.green
                                                          : Colors.red,
                                                  size: 24,
                                                ),
                                                SizedBox(width: 5),
                                                Text(
                                                  item['is_solved'] == 1
                                                      ? 'Terselesaikan'
                                                      : 'Belum Selesai',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontFamily: 'Poppins',
                                                    color:
                                                        item['is_solved'] == 1
                                                            ? Colors.green
                                                            : Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 130,

                                                margin: EdgeInsets.only(
                                                  left: 20,
                                                  top: 5,
                                                  bottom: 0,
                                                  right: 5,
                                                ),
                                                child: Text(
                                                  'Keterangan ',
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontFamily: 'Poppins',
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 5,
                                                  left: 20,
                                                ),
                                                child: Container(
                                                  width: 370,
                                                  height: 100,
                                                  color: Colors.grey[50],
                                                  child: TextFormField(
                                                    initialValue:
                                                        item['laporan'] ??
                                                        "Unknown",
                                                    keyboardType:
                                                        TextInputType.multiline,
                                                    maxLines: 6,
                                                    decoration: InputDecoration(
                                                      border:
                                                          OutlineInputBorder(),
                                                      contentPadding:
                                                          EdgeInsets.all(8),
                                                    ),
                                                    readOnly: true,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          Row(
                                            children: [
                                              Column(
                                                children: [
                                                  Container(
                                                    margin: EdgeInsets.only(
                                                      top: 28,
                                                      left: 4,
                                                    ),
                                                    width: 117,
                                                    height: 50,
                                                    child: ElevatedButton(
                                                      onPressed: () {
                                                        dialogDetail(
                                                          context,
                                                          item,
                                                        );
                                                      },
                                                      child: Text('Detail'),
                                                    ),
                                                  ),
                                                  Container(
                                                    margin: EdgeInsets.only(
                                                      top: 10,
                                                      left: 4,
                                                    ),
                                                    width: 117,
                                                    height: 50,
                                                    child: ElevatedButton(
                                                      onPressed: () async {
                                                        final idLaporan =
                                                            item['id_laporan'];
                                                        final currentStatus =
                                                            item['is_solved'];

                                                        try {
                                                          final response =
                                                              await Dio().put(
                                                                '${myIpAddr()}/laporan/updatelaporanob/$idLaporan',
                                                              );

                                                          if (response
                                                                  .statusCode ==
                                                              200) {
                                                            CherryToast.success(
                                                              title: Text(
                                                                'Berhasil',
                                                              ),
                                                              description: Text(
                                                                currentStatus ==
                                                                        1
                                                                    ? 'Status laporan diubah ke ❌ Belum Selesai'
                                                                    : 'Status laporan diubah ke ✅ Selesai',
                                                              ),
                                                            ).show(context);

                                                            setState(() {
                                                              item['is_solved'] =
                                                                  currentStatus ==
                                                                          1
                                                                      ? 0
                                                                      : 1;
                                                            });
                                                          }
                                                        } catch (e) {
                                                          if (e
                                                              is DioException) {
                                                            log(
                                                              "Error Update ${e.response!.data}",
                                                            );
                                                          }
                                                          CherryToast.error(
                                                            title: Text(
                                                              'Gagal',
                                                            ),
                                                            description: Text(
                                                              'Gagal mengubah status laporan',
                                                            ),
                                                          ).show(context);
                                                        }
                                                      },
                                                      child: Text(
                                                        'Edit Status',
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              // Container(
                                              //   margin: EdgeInsets.only(left: 20),
                                              //   width: 100,
                                              //   child: ElevatedButton(
                                              //     onPressed: () {
                                              //       Get.dialog(
                                              //         AlertDialog(
                                              //           title: Text('Confirm'),
                                              //           content: Text(
                                              //             'Yakin menghapus data?',
                                              //           ),
                                              //           actions: [
                                              //             TextButton(
                                              //               onPressed: () {
                                              //                 Get.back();
                                              //               },
                                              //               child: Text('Cancel'),
                                              //             ),
                                              //             TextButton(
                                              //               onPressed: () async {
                                              //                 final response =
                                              //                     await dio.delete(
                                              //                       '${myIpAddr()}/LaporanOB/delete_pekerja/${item['id_karyawan']}',
                                              //                       data: {},
                                              //                     );
                                              //                 if (response
                                              //                         .statusCode ==
                                              //                     200) {
                                              //                   await refreshData();
                                              //                   dropdownJK = null;
                                              //                   textcari.clear();
                                              //                   CherryToast.success(
                                              //                     title: Text(
                                              //                       'Data berhasil dihapus',
                                              //                     ),
                                              //                   ).show(context);
                                              //                   Get.back();
                                              //                 }
                                              //               },
                                              //               child: Text('Confirm'),
                                              //             ),
                                              //           ],
                                              //         ),
                                              //         barrierDismissible: false,
                                              //       );
                                              //     },
                                              //     child: Text('Delete'),
                                              //   ),
                                              // ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          drawer: AdminDrawer(),
        );
  }

  Widget WidgetLaporanObMobile() {
    return Text('Ini Mobile');
  }
}
