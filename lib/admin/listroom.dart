import 'dart:async';
import 'dart:developer';
import 'package:Project_SPA/admin/laporan_ob.dart';
import 'package:Project_SPA/admin/listpaket.dart';
import 'package:Project_SPA/admin/listpekerja.dart';
import 'package:Project_SPA/admin/listpromo.dart';
import 'package:Project_SPA/admin/listuser.dart';
import 'package:Project_SPA/admin/regis_locker.dart';
import 'package:Project_SPA/admin/regis_paket.dart';
import 'package:Project_SPA/admin/regis_pekerja.dart';
import 'package:Project_SPA/admin/regis_promo.dart';
import 'package:Project_SPA/admin/regis_room.dart';
import 'package:Project_SPA/admin/regis_users.dart';
import 'package:Project_SPA/function/admin_drawer.dart';
import 'package:Project_SPA/function/ip_address.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:Project_SPA/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ListRoom extends StatefulWidget {
  const ListRoom({super.key});

  @override
  State<ListRoom> createState() => _ListRoomState();
}

class _ListRoomState extends State<ListRoom> {
  late final Dio dio;

  @override
  void initState() {
    super.initState();
    dio = Dio();
    futureData = fetchData();
    futureData.then((data) {
      setState(() {
        dataList = data;
        filteredList = dataList;
      });
    });
  }

  Future<void> refreshData() async {
    futureData = fetchData();
    List<Map<String, dynamic>> updatedData = await futureData;
    setState(() {
      dataList = updatedData;
      filteredList = dataList; // Ensures UI updates with fresh data
    });
  }

  Timer? _debounce;
  List<Map<String, dynamic>> dataList = [];
  List<Map<String, dynamic>> filteredList = [];
  String capitalize(String? text) {
    if (text == null || text.isEmpty) return "Unknown"; // Handle null or empty
    return text[0].toUpperCase() + text.substring(1);
  }

  Future<List<Map<String, dynamic>>> fetchData() async {
    try {
      final response = await dio.get('${myIpAddr()}/listroom/dataroom');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception("Failed to load data: ${response.statusCode}");
      }
    } on DioException catch (e) {
      throw Exception("Dio error: ${e.message}");
    }
  }

  late Future<List<Map<String, dynamic>>> futureData;

  List<String> listJenisRuang = <String>['Fasilitas', 'Reguler', 'VIP'];
  final List<String> _listStatus = <String>[
    'aktif',
    // 'non aktif',
    'occupied',
    'maintenance',
  ];
  String? dropdownValue;
  String? dropdownStatus;
  TextEditingController textcari = TextEditingController();
  void isibuttoneditruangan(BuildContext context, Map<String, dynamic> item) {
    TextEditingController kodeRuangController = TextEditingController();
    TextEditingController nmRuangController = TextEditingController(
      text: item['nama_ruangan'],
    );
    TextEditingController lantaiController = TextEditingController(
      text: item['lantai'].toString(),
    );
    String? dropdownValue = item['jenis_ruangan'];
    String? dropdownStatus = item['status'];

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Container(
                width: Get.width - 350,
                height: Get.height - 350,
                child: ListView(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.zero,
                          child: Container(
                            margin: EdgeInsets.only(top: 80),
                            height: 170,
                            width: 200,
                            child: Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  SizedBox(height: 15),
                                  Text(
                                    'Nama Kamar :',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 18,
                                    ),
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    'Lantai :',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 18,
                                    ),
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    'Jenis Kamar :',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 18,
                                    ),
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    'Status :',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(top: 80),
                          height: 250,
                          width: 500,
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
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.grey[300],
                                  ),
                                  child: TextField(
                                    controller: nmRuangController,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 13.5,
                                        horizontal: 10,
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                                SizedBox(height: 12),
                                Container(
                                  alignment: Alignment.centerLeft,
                                  width: 480,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.grey[300],
                                  ),
                                  child: TextField(
                                    keyboardType: TextInputType.number,
                                    inputFormatters: <TextInputFormatter>[
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    controller: lantaiController,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 13.5,
                                        horizontal: 10,
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                                SizedBox(height: 12),
                                Container(
                                  width: 480,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.grey[300],
                                  ),
                                  child: DropdownButton<String>(
                                    value: dropdownValue,
                                    isExpanded: true,
                                    icon: const Icon(Icons.arrow_drop_down),
                                    elevation: 16,
                                    style: const TextStyle(
                                      color: Colors.deepPurple,
                                    ),
                                    underline: SizedBox(),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    onChanged: (String? value) {
                                      setState(() {
                                        dropdownValue = value;
                                      });
                                    },
                                    items:
                                        listJenisRuang.map<
                                          DropdownMenuItem<String>
                                        >((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                value,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ),
                                SizedBox(height: 12),
                                Container(
                                  alignment: Alignment.centerLeft,
                                  width: 480,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.grey[300],
                                  ),
                                  child: DropdownButton<String>(
                                    value: dropdownStatus,
                                    isExpanded: true,
                                    icon: const Icon(Icons.arrow_drop_down),
                                    elevation: 14,
                                    style: const TextStyle(
                                      color: Colors.deepPurple,
                                    ),
                                    underline: SizedBox(),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    onChanged: (String? value) {
                                      setState(() {
                                        dropdownStatus = value;
                                      });
                                    },
                                    items:
                                        _listStatus.map<
                                          DropdownMenuItem<String>
                                        >((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                value,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ),
                                SizedBox(height: 20),
                                Padding(
                                  padding: const EdgeInsets.only(right: 170),
                                  child: Center(
                                    child: SizedBox(
                                      height: 50,
                                      width: 120,
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.green,
                                        ),
                                        onPressed: () async {
                                          final response = await dio.put(
                                            '${myIpAddr()}/listroom/update_room/${item['id_ruangan'].toString()}',
                                            data: {
                                              "nama_ruangan":
                                                  nmRuangController.text,
                                              "lantai":
                                                  int.tryParse(
                                                    lantaiController.text,
                                                  ) ??
                                                  0,
                                              "jenis_ruangan": dropdownValue,
                                              "status": dropdownStatus,
                                            },
                                          );
                                          if (response.statusCode == 200) {
                                            CherryToast.success(
                                              title: Text(
                                                'Data berhasil diupdate',
                                              ),
                                            ).show(context);
                                            Get.back(result: "updated");
                                            refreshData().then((_) {
                                              textcari.clear();
                                              nmRuangController.clear();
                                              lantaiController.clear();
                                              dropdownValue = null;
                                            });
                                          }
                                        },

                                        child: Text(
                                          'Simpan',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
        },
      ),
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    textcari.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: Container(
        //   width: 30,
        //   height: 30,
        //   child: ClipOval(child: Image.asset('assets/spa.jpeg')),
        // ),
        elevation: 0,
        scrolledUnderElevation: 0,
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
                  'List Ruangan',
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
                          _debounce = Timer(Duration(milliseconds: 1000), () {
                            // Adjust debounce delay here
                            setState(() {
                              filteredList =
                                  dataList.where((item) {
                                    return item['nama_ruangan']
                                        .toString()
                                        .toLowerCase()
                                        .contains(query.toLowerCase());
                                  }).toList();
                            });
                          });
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Input Ruangan',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 108),
                child: Row(
                  children: [
                    Container(
                      width: 110,
                      child: Text(
                        "Kode",
                        style: TextStyle(fontSize: 25, fontFamily: 'Poppins'),
                      ),
                    ),
                    Container(
                      width: 120,
                      child: Text(
                        "Nama",
                        style: TextStyle(fontSize: 25, fontFamily: 'Poppins'),
                      ),
                    ),
                    Container(
                      width: 80,
                      child: Text(
                        "Lantai",
                        style: TextStyle(fontSize: 25, fontFamily: 'Poppins'),
                      ),
                    ),
                    Container(
                      width: 140,
                      child: Center(
                        child: Text(
                          "Jenis",
                          style: TextStyle(fontSize: 25, fontFamily: 'Poppins'),
                        ),
                      ),
                    ),
                    Container(
                      width: 180,
                      child: Center(
                        child: Text(
                          "Status",
                          style: TextStyle(fontSize: 25, fontFamily: 'Poppins'),
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
                  future: futureData,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(),
                      ); // Loading state
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text("Error: ${snapshot.error}"),
                      ); // Error state
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                          margin: EdgeInsets.only(
                            top: 10,
                            bottom: 10,
                            left: 5,
                            right: 5,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(width: 1),
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                margin: EdgeInsets.only(left: 10),

                                width: 80,
                                child: Text(
                                  item['id_karyawan'],
                                  style: TextStyle(
                                    fontSize: 25,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.only(left: 20),
                                width: 140,

                                child: Text(
                                  item['nama_ruangan'],
                                  style: TextStyle(
                                    fontSize: 25,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Container(
                                width: 20,

                                child: Text(
                                  item['lantai']?.toString() ?? "Unknown",
                                  style: TextStyle(
                                    fontSize: 25,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              SizedBox(width: 35),
                              Container(
                                width: 135,

                                child: Center(
                                  child: Text(
                                    item['jenis_ruangan'],
                                    style: TextStyle(
                                      fontSize: 25,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 5),
                              Container(
                                width: 180,
                                child: Center(
                                  child: Text(
                                    capitalize(item['status']),
                                    style: TextStyle(
                                      fontSize: 25,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () {
                                  isibuttoneditruangan(context, item);
                                  setState(() {});
                                },
                                child: Text(
                                  'Edit',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Container(
                                margin: EdgeInsets.only(left: 10),
                                width: 120,
                                child: ElevatedButton(
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
                                          TextButton(
                                            onPressed: () async {
                                              final response = await dio.delete(
                                                '${myIpAddr()}/listroom/delete_room/${item['id_ruangan'].toString()}',
                                                data: {},
                                              );
                                              if (response.statusCode == 200) {
                                                await refreshData();
                                                dropdownJK = null;
                                                textcari.clear();
                                                CherryToast.success(
                                                  title: Text(
                                                    'Data berhasil dihapus',
                                                  ),
                                                ).show(context);
                                                Get.back();
                                              }
                                            },
                                            child: Text('Confirm'),
                                          ),
                                        ],
                                      ),
                                      barrierDismissible: false,
                                    );
                                  },
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
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
}
