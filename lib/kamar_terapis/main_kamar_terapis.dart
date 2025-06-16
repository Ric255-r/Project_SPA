import 'dart:collection';

import 'package:Project_SPA/function/ip_address.dart';
import 'package:Project_SPA/function/me.dart';
import 'package:Project_SPA/function/our_drawer.dart';
import 'package:Project_SPA/function/token.dart';
import 'package:Project_SPA/office_boy/main_ob.dart';
import 'package:Project_SPA/resepsionis/main_resepsionis.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:Project_SPA/kamar_terapis/terapis_confirm.dart';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';

class MainKamarTerapis extends StatefulWidget {
  const MainKamarTerapis({super.key});

  @override
  State<MainKamarTerapis> createState() => _MainKamarTerapisState();
}

class _MainKamarTerapisState extends State<MainKamarTerapis> {
  // TextEditingController _idKaryawan = TextEditingController();
  // TextEditingController _passwd = TextEditingController();
  // Harus di Init ke variabel supaya shared_preferences nyala
  // String _idAkunRuangan = '';
  int _idRuangan = 0;
  String _namaRuangan = '';

  var dio = Dio();

  Future<void> _verifikasiOb() async {
    try {
      var response = await dio.post(
        '${myIpAddr()}/kamar_terapis/verif',
        data: {
          "id_karyawan": _dropdownAkunOb.value,
          // "passwd": _passwd.text,
        },
      );

      if (response.statusCode == 200) {
        // _idKaryawan.clear();
        // _passwd.clear();
        Get.back(); // Close the dialog

        log("Isi Respon $response");

        Get.to(
          () => MainOb(
            idOb: response.data['data_user']['id_karyawan'],
            namaOb: response.data['data_user']['nama_karyawan'],
            // idAkunRuangan: _idAkunRuangan,
            idRuangan: _idRuangan,
            namaRuangan: _namaRuangan,
          ),
        );
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response!.statusCode == 404) {
          Get.snackbar("Error", "Akun Tidak Ditemukan");
        } else if (e.response!.statusCode == 401) {
          Get.snackbar("Error", "Password Salah");
        } else {
          Get.snackbar("Error", "Gagal Login fnverif_mainkamarterapis.dart");
        }
      }
      log("Error Di Verif Akun $e");
    }
  }

  RxString _dropdownAkunOb = "".obs;
  RxList<Map<String, dynamic>> _dataOb = <Map<String, dynamic>>[].obs;

  Future<void> _getDataOb() async {
    try {
      var response = await dio.get('${myIpAddr()}/kamar_terapis/data_ob');
      _dataOb.value =
          (response.data as List).map<Map<String, dynamic>>((el) {
            return {
              "id_karyawan": el['id_karyawan'].toString(),
              "hak_akses": el['hak_akses'].toString(),
              "nama_hakakses": el['nama_hakakses'].toString(),
              "nama_karyawan": el['nama_karyawan'].toString(),
            };
          }).toList();
    } catch (e) {
      log("Error Get Data Ob $e");
    }
  }

  void _dialogOb() async {
    await _getDataOb();

    Get.dialog(
      AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Spacer(),
            const Text("Pilih Akun Anda!", style: TextStyle(fontSize: 20)),
            const Spacer(),
            IconButton(
              onPressed: () {
                Get.back();
              },
              icon: const Icon(Icons.cancel),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: 250,
              minWidth: Get.width - 300,
            ),
            child: Obx(() {
              if (_dataOb.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              // Create a new list with default option + fetched data
              final allOptions = [
                {'id_karyawan': '', 'nama_karyawan': 'Pilih Data Anda Dahulu'},
                ..._dataOb,
              ];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Id User:"),
                  SizedBox(height: 10),
                  SizedBox(
                    width: Get.width - 300,
                    child: DropdownMenu<String>(
                      width: Get.width - 300,
                      initialSelection:
                          '', // Default to empty (our "Select item first")
                      onSelected: (String? value) {
                        if (value?.isNotEmpty ?? false) {
                          // Only update if not default
                          _dropdownAkunOb.value = value!;
                        }
                      },
                      dropdownMenuEntries:
                          allOptions.map((item) {
                            return DropdownMenuEntry<String>(
                              value: item['id_karyawan'],
                              label:
                                  "${item['id_karyawan']} - ${item['nama_karyawan']}",
                              // Disable default option
                              enabled: item['id_karyawan'].isNotEmpty,
                            );
                          }).toList(),
                    ),
                  ),
                  SizedBox(height: 10),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        _verifikasiOb();
                      },
                      child: Text("Konfirmasi"),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  // void _dialogLogin(String mode) {
  //   Get.dialog(
  //     AlertDialog(
  //       title: Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [
  //           Spacer(),
  //           Text(
  //             "Masukkan Akun Anda!",
  //             style: TextStyle(fontSize: 20),
  //           ),
  //           Spacer(),
  //           IconButton(
  //             onPressed: () {
  //               _idKaryawan.clear();
  //               _passwd.clear();

  //               Get.back();
  //             },
  //             icon: Icon(Icons.cancel),
  //           )
  //         ],
  //       ),
  //       content: SingleChildScrollView(
  //         child: Container(
  //           height: Get.height - 400,
  //           width: Get.width - 450,
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text("Id User: "),
  //               TextField(
  //                 controller: _idKaryawan,
  //               ),
  //               SizedBox(
  //                 height: 15,
  //               ),
  //               Text("Password: "),
  //               TextField(
  //                 controller: _passwd,
  //                 obscureText: true,
  //               ),
  //               SizedBox(
  //                 height: 15,
  //               ),
  //               Center(
  //                 child: ElevatedButton(
  //                   onPressed: () {
  //                     _verifikasi(mode);
  //                   },
  //                   child: Text("Login"),
  //                 ),
  //               )
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   ).then((_) {
  //     _idKaryawan.clear();
  //     _passwd.clear();
  //   });
  // }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Get.delete<MainResepsionisController>(force: true);
    _profileRuangan();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    // _idKaryawan.dispose();
    // _passwd.dispose();
    super.dispose();
  }

  var _token = "";

  Future<void> _profileRuangan() async {
    try {
      final token = await getTokenSharedPref();
      var response = await getMyData(token);
      print("Isi Response Ruangan $response");

      // log("Isi Responsenya $response");

      if (response != null && response['data'] != null) {
        setState(() {
          // ini PK auto increment dr tabel ruangan
          _idRuangan = response['data']['id_ruangan'];
          // id disini adlh akun utk ruangan. misalkan KT001 (Kamarterapis)
          // _idAkunRuangan = response['data']['id_karyawan'];
          _namaRuangan = response['data']['nama_ruangan'];
          _token = token!;
        });
      }

      // print("Id Ruangan: $_idAkunRuangan, Nama Ruangan: $_namaRuangan  ");
    } catch (e) {
      log("Error di main kamar terapis $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(""),
        toolbarHeight: 50,
        backgroundColor: Color(0XFFFFE0B2),
      ),
      body: Container(
        decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
        width: Get.width,
        height: Get.height,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 5),
              child: Text(
                'PLATINUM',
                style: TextStyle(
                  fontSize: 60,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 40),
              child: Text(
                "Pilih Jenis Aktivitas",
                style: TextStyle(fontSize: 30, fontFamily: 'Poppins'),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 60, left: 220, right: 220),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Get.to(() => TerapisConfirm());
                      // _dialogLogin("terapis");
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      height: 300,
                      width: 250,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 68),
                            child: Icon(
                              FontAwesomeIcons.handHoldingHeart,
                              size: 140,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: Text(
                              'Terapis',
                              style: TextStyle(
                                fontSize: 26,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _dialogOb();
                      // _dialogLogin("ob");
                      // Get.to(() => MainOb(
                      //   myToken: _token,
                      // ),);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      height: 300,
                      width: 250,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.cleaning_services_rounded, size: 200),
                          Text(
                            'Office Boy',
                            style: TextStyle(
                              fontSize: 26,
                              fontFamily: 'Poppins',
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
      drawer: OurDrawer(),
    );
  }
}
