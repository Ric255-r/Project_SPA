import 'dart:developer';

import 'package:Project_SPA/office_boy/hp_ob.dart';
import 'package:Project_SPA/owner/laporan_komisi.dart';
import 'package:Project_SPA/resepsionis/list_transaksi.dart';
import 'package:Project_SPA/resepsionis/rating.dart';
import 'package:Project_SPA/resepsionis/tampilan_terapis.dart';
import 'package:flutter/material.dart';
import 'package:Project_SPA/admin/main_admin.dart';
import 'package:Project_SPA/function/ip_address.dart';
import 'package:Project_SPA/function/me.dart';
import 'package:Project_SPA/function/token.dart';
import 'package:Project_SPA/kamar_terapis/main_kamar_terapis.dart';
import 'package:Project_SPA/kitchen/main_kitchen.dart';
import 'package:Project_SPA/komisi/main_komisi_pekerja.dart';
import 'package:Project_SPA/owner/main_owner.dart';
import 'package:Project_SPA/resepsionis/main_resepsionis.dart';
import 'package:Project_SPA/ruang_tunggu/main_rt.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dio/dio.dart';

class OurDrawer extends StatefulWidget {
  const OurDrawer({super.key});

  @override
  State<OurDrawer> createState() => _OurDrawerState();
}

class _OurDrawerState extends State<OurDrawer> {
  var idKaryawan = "".obs;
  var namaKaryawan = "".obs;
  var jabatan = "".obs;

  ScrollController _scrollBarController = ScrollController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _profileUser();
    _getHakAkses();
  }

  Future<void> _profileUser() async {
    try {
      final prefs = await getTokenSharedPref();
      var response = await getMyData(prefs);

      Map<String, dynamic> responseData = response['data'];
      log("Profil Drawer $responseData");

      idKaryawan.value = responseData['id_karyawan'];
      namaKaryawan.value = responseData['nama_karyawan'];
      jabatan.value = responseData['jabatan'];
    } catch (e) {
      log("Error di Drawer $e");
    }
  }

  var dio = Dio();
  String _firstHakAkses = "";
  List<String> _listSecondHakAkses = [];

  Future<void> _getHakAkses() async {
    try {
      final prefs = await getTokenSharedPref();
      var response = await dio.get(
        '${myIpAddr()}/hak_akses',
        options: Options(headers: {"Authorization": "bearer " + prefs!}),
      );

      setState(() {
        Map<String, dynamic> resData = response.data;
        // Definisikan Hak Akses Masing2
        _firstHakAkses = resData['nama_hakakses'];
        List<dynamic> secHakAkses = resData['second_hakakses'];

        _listSecondHakAkses.clear();
        for (var i = 0; i < secHakAkses.length; i++) {
          _listSecondHakAkses.add(secHakAkses[i]['nama_hakakses']);
        }
      });

      print(_firstHakAkses);
      print(_listSecondHakAkses);

      log("Hasil Second Hak Akses $_listSecondHakAkses");
    } catch (e) {
      log("Error Get Hak Akses Drawer $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          SizedBox(
            // awal height = 210
            height: 200,
            child: Obx(
              () => DrawerHeader(
                decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
                child: UserAccountsDrawerHeader(
                  decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
                  accountName: Text(
                    namaKaryawan.value,
                    style: TextStyle(color: Colors.black),
                  ),
                  accountEmail: Text(jabatan.value),
                  currentAccountPictureSize: Size.square(50),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.amberAccent,
                    child: Text(
                      idKaryawan.value,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: Get.height - 270,
            width: double.infinity,
            child: Scrollbar(
              thumbVisibility: true,
              controller: _scrollBarController,
              child: ListView(
                controller: _scrollBarController,
                children: [
                  if (_listSecondHakAkses.contains("resepsionis") ||
                      _firstHakAkses == "resepsionis") ...[
                    ListTile(
                      leading: const Icon(Icons.room),
                      title: const Text(
                        'Menu Awal Resepsionis',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                      onTap: () {
                        Get.to(() => MainResepsionis());
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.list_rounded),
                      title: const Text(
                        'List Transaksi',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                      onTap: () {
                        Get.offAll(() => ListTransaksi());
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.person_2),
                      title: const Text(
                        'List Terapis',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                      onTap: () {
                        Get.offAll(() => TampilanTerapis());
                      },
                    ),
                  ],

                  if (_listSecondHakAkses.contains("spv") ||
                      _firstHakAkses == "spv")
                    ListTile(
                      leading: const Icon(Icons.room),
                      title: const Text(
                        'Ruang Tunggu Terapis',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                      onTap: () {
                        Get.to(() => MainRt());
                      },
                    ),
                  if (_listSecondHakAkses.contains("ruangan") ||
                      _firstHakAkses == "ruangan")
                    ListTile(
                      leading: const Icon(Icons.room_service),
                      title: const Text(
                        'Kamar Terapis',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                      onTap: () {
                        Get.to(() => MainKamarTerapis());
                      },
                    ),
                  if (_listSecondHakAkses.contains("ob") ||
                      _firstHakAkses == "ob")
                    ListTile(
                      leading: const Icon(Icons.room_service),
                      title: const Text(
                        'Menu Utama',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                      onTap: () {
                        Get.to(() => Hp_Ob());
                      },
                    ),
                  if (_listSecondHakAkses.contains("admin") ||
                      _firstHakAkses == "admin")
                    ListTile(
                      leading: const Icon(Icons.admin_panel_settings_rounded),
                      title: const Text(
                        'Admin',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                      onTap: () {
                        Get.to(() => MainAdmin());
                      },
                    ),

                  if (_listSecondHakAkses.contains("kitchen") ||
                      _firstHakAkses == "kitchen")
                    ListTile(
                      leading: const Icon(Icons.admin_panel_settings_rounded),
                      title: const Text(
                        'Kitchen',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                      onTap: () {
                        Get.to(() => MainKitchen());
                      },
                    ),
                  if (_listSecondHakAkses.contains("admin") ||
                      _firstHakAkses == "admin")
                    ListTile(
                      leading: const Icon(Icons.admin_panel_settings_rounded),
                      title: const Text(
                        'Komisi Pekerja',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                      onTap: () {
                        Get.to(() => PageKomisiPekerja());
                      },
                    ),
                  if (_firstHakAkses == "owner") ...[
                    ListTile(
                      leading: const Icon(Icons.admin_panel_settings_rounded),
                      title: const Text(
                        'Owner',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                      onTap: () {
                        Get.to(() => OwnerPage());
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.admin_panel_settings_rounded),
                      title: const Text(
                        'Admin',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                      onTap: () {
                        Get.to(() => MainAdmin());
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.room),
                      title: const Text(
                        'Menu Awal Resepsionis',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                      onTap: () {
                        Get.offAll(() => MainResepsionis());
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.list_rounded),
                      title: const Text(
                        'List Transaksi',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                      onTap: () {
                        Get.offAll(() => ListTransaksi());
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.safety_check),
                      title: const Text(
                        'Komisi Terapis',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                      onTap: () {
                        Get.offAll(() => laporankomisi());
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),

          Expanded(
            child: Container(),
          ), // Pushes the Log Out ListTile to the bottom
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text(
              'Log Out',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            onTap: () async {
              // Krna ak buat permanen, jd paksa hapus
              Get.delete<MainResepsionisController>(force: true);
              await fnLogout();
            },
          ),
        ],
      ),
    );
  }
}
