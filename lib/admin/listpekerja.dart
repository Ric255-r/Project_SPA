import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:Project_SPA/admin/laporan_ob.dart';
import 'package:Project_SPA/admin/listpaket.dart';
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
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';

class Listpekerja extends StatefulWidget {
  const Listpekerja({super.key});

  @override
  State<Listpekerja> createState() => _ListpekerjaState();
}

class _ListpekerjaState extends State<Listpekerja> {
  late final Dio dio;

  @override
  void initState() {
    super.initState();
    dio = Dio();
    futureData = fetchData();
    futureData.then((data) {
      setState(() {
        dataList = data;
        filteredList = data;
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
  TextEditingController textcari = TextEditingController();

  Future<List<Map<String, dynamic>>> fetchData() async {
    try {
      final response = await dio.get('${myIpAddr()}/listpekerja/datapekerja');

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

  void openKontrakFile(String kontrakPath) async {
    final baseUrl = 'http://192.168.1.67:5500/listpekerja';
    String fileName =
        kontrakPath.contains(',') ? kontrakPath.split(',')[0] : kontrakPath;

    final fullUrl = '$baseUrl/kontrak/$fileName';
    final encodedUrl = Uri.encodeFull(fullUrl);

    if (Platform.isAndroid) {
      final intent = AndroidIntent(
        action: 'action_view',
        data: encodedUrl,
        package: 'com.android.chrome', // ← Force Chrome
      );
      await intent.launch();
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();

    textcari.dispose();
  }

  void isibuttoneditpekerja(BuildContext context, Map<String, dynamic> item) {
    TextEditingController namaController = TextEditingController(
      text: item['nama_karyawan'],
    );
    TextEditingController nikController = TextEditingController(
      text: item['nik'],
    );
    TextEditingController noHpController = TextEditingController(
      text: item['no_hp'],
    );
    TextEditingController alamatController = TextEditingController(
      text: item['alamat'],
    );
    String? dropdownStatus = item['status'];
    String? dropdownJK = item['jk'];
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Container(
                width: Get.width - 250,
                height: Get.height - 250,
                child: ListView(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 50),
                          child: Container(
                            height: 315,
                            width: 200,

                            child: Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  SizedBox(height: 15),
                                  Text(
                                    'Nama :',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    'NIK :',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    'No HP :',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    'Jenis Kelamin :',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    'Alamat :',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    'Status :',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 15),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 55),
                          child: Container(
                            height: 370,
                            width: 500,
                            child: Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 8),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    width: 480,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey[300],
                                    ),
                                    child: TextField(
                                      keyboardType: TextInputType.text,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'^[a-zA-Z]+$'),
                                        ),
                                      ],
                                      controller: namaController,
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
                                  SizedBox(height: 8),
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
                                      controller: nikController,
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
                                  SizedBox(height: 8),
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
                                      controller: noHpController,
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
                                  SizedBox(height: 8),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    width: 480,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey[300],
                                    ),
                                    child: DropdownButton<String>(
                                      value: dropdownJK,
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
                                          dropdownJK = value;
                                        });
                                      },
                                      items:
                                          listJK.map<DropdownMenuItem<String>>((
                                            String value,
                                          ) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  value,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontFamily: 'Poppins',
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    width: 480,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey[300],
                                    ),
                                    child: TextField(
                                      controller: alamatController,
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
                                  SizedBox(height: 8),
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
                                          listStatus.map<
                                            DropdownMenuItem<String>
                                          >((String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  value,
                                                  style: TextStyle(
                                                    fontSize: 14,
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
                                    padding: const EdgeInsets.only(
                                      right: 60,
                                      top: 30,
                                    ),
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
                                              '${myIpAddr()}/listpekerja/update_pekerja/${item['id_karyawan']}',
                                              data: {
                                                "nama_karyawan":
                                                    namaController.text,
                                                "nik": nikController.text,
                                                "no_hp": noHpController.text,
                                                "alamat": alamatController.text,
                                                "jk": dropdownJK,
                                                "status": dropdownStatus,
                                              },
                                            );
                                            if (response.statusCode == 200) {
                                              Get.back(result: "updated");
                                              await refreshData();
                                              textcari.clear();
                                              namaController.clear();
                                              nikController.clear();
                                              noHpController.clear();
                                              alamatController.clear();
                                              dropdownStatus = null;
                                              dropdownJK = null;
                                              CherryToast.success(
                                                title: Text(
                                                  'Data berhasil diupdate',
                                                ),
                                              ).show(context);
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
  Widget build(BuildContext context) {
    return Scaffold(
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
                  'List Pekerja',
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
                                    return item['nama_karyawan']
                                        .toString()
                                        .toLowerCase()
                                        .contains(query.toLowerCase());
                                  }).toList();
                            });
                          });
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Input Nama',
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
                          margin: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(width: 1),
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 100,
                                        margin: EdgeInsets.only(
                                          left: 20,
                                          top: 5,
                                          bottom: 0,
                                          right: 5,
                                        ),
                                        child: Text(
                                          'Kode ',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 5),
                                        child: Container(
                                          width: 160,
                                          child: Text(
                                            item['id_karyawan'] ?? "Unknown",
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
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 100,
                                        margin: EdgeInsets.only(
                                          left: 20,
                                          top: 3,
                                          bottom: 0,
                                          right: 5,
                                        ),
                                        child: Text(
                                          'Nama ',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 3),
                                        child: Container(
                                          width: 370,
                                          child: Text(
                                            item['nama_karyawan'] ?? "Unknown",
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
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 100,
                                        margin: EdgeInsets.only(
                                          left: 20,
                                          top: 5,
                                          bottom: 0,
                                          right: 5,
                                        ),
                                        child: Text(
                                          'NoHp ',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 3),
                                        child: Container(
                                          width: 370,
                                          child: Text(
                                            item['no_hp'] ?? "Unknown",
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
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 100,
                                        margin: EdgeInsets.only(
                                          left: 20,
                                          top: 5,
                                          bottom: 0,
                                          right: 5,
                                        ),
                                        child: Text(
                                          'Alamat ',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 3),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(width: 1),
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(10),
                                            ),
                                          ),
                                          width: 400,
                                          child: AutoSizeText(
                                            item['alamat'] ?? "Unknown",
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
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 100,
                                        margin: EdgeInsets.only(
                                          left: 20,
                                          top: 10,
                                          bottom: 0,
                                          right: 5,
                                        ),
                                        child: Text(
                                          'Kontrak ',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 100,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            final kontrak = item['kontrak_img'];

                                            if (kontrak == null ||
                                                kontrak.isEmpty) {
                                              CherryToast.warning(
                                                title: Text(
                                                  'Kontrak tidak ada',
                                                ),
                                              ).show(context);
                                            } else {
                                              openKontrakFile(kontrak);
                                            }
                                          },
                                          child: Text('View'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 100,

                                        margin: EdgeInsets.only(
                                          left: 20,
                                          top: 5,
                                          bottom: 0,
                                          right: 5,
                                        ),
                                        child: Text(
                                          'NIK ',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 5),
                                        child: Container(
                                          width: 200,
                                          child: Text(
                                            item['nik'] ?? "Unknown",
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
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 100,
                                        margin: EdgeInsets.only(
                                          left: 20,
                                          top: 3,
                                          bottom: 0,
                                          right: 5,
                                        ),
                                        child: Text(
                                          'JK ',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 3),
                                        child: Container(
                                          width: 200,
                                          child: Text(
                                            item['jk'] ?? "Unknown",
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
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 100,
                                        margin: EdgeInsets.only(
                                          left: 20,
                                          top: 5,
                                          bottom: 0,
                                          right: 5,
                                        ),
                                        child: Text(
                                          'Jabatan ',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 3),
                                        child: Container(
                                          width: 160,
                                          child: Text(
                                            item['jabatan'] ?? "Unknown",
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
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 100,
                                        margin: EdgeInsets.only(
                                          left: 20,
                                          top: 3,
                                          bottom: 0,
                                          right: 5,
                                        ),
                                        child: Text(
                                          'Status ',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 3),
                                        child: Container(
                                          width: 160,
                                          child: Text(
                                            item['status'] ?? "Unknown",
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
                                    children: [
                                      Container(
                                        margin: EdgeInsets.only(left: 20),
                                        width: 100,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            isibuttoneditpekerja(context, item);
                                            setState(() {});
                                          },

                                          child: Text('Edit'),
                                        ),
                                      ),
                                      Container(
                                        margin: EdgeInsets.only(left: 20),
                                        width: 100,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Get.dialog(
                                              AlertDialog(
                                                title: Text('Confirm'),
                                                content: Text(
                                                  'Yakin menghapus data?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Get.back();
                                                    },
                                                    child: Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () async {
                                                      final response = await dio
                                                          .delete(
                                                            '${myIpAddr()}/listpekerja/delete_pekerja/${item['id_karyawan']}',
                                                            data: {},
                                                          );
                                                      if (response.statusCode ==
                                                          200) {
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
                                          child: Text('Delete'),
                                        ),
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
}
