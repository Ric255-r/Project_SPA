import 'dart:developer';

import 'package:Project_SPA/admin/list_member.dart';
import 'package:Project_SPA/admin/listterapis.dart';
import 'package:Project_SPA/admin/pajak.dart';
import 'package:Project_SPA/admin/set_harga_vip.dart';
import 'package:Project_SPA/resepsionis/list_transaksi.dart';
// import 'package:Project_SPA/admin/list_transaksi.dart';
import 'package:Project_SPA/resepsionis/list_transaksi.dart';
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
import 'package:Project_SPA/admin/laporan_ob.dart';
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
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Project_SPA/resepsionis/billing_locker.dart';
import 'package:Project_SPA/resepsionis/jenis_transaksi.dart';
import 'package:Project_SPA/main.dart';

class AdminDrawer extends StatefulWidget {
  const AdminDrawer({super.key});

  @override
  State<AdminDrawer> createState() => _AdminDrawerState();
}

class _AdminDrawerState extends State<AdminDrawer> {
  var idKaryawan = "".obs;
  var namaKaryawan = "".obs;
  var jabatan = "".obs;
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _profileUser();
    _getHakAkses();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _scrollController.dispose();
    super.dispose();
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

  String capitalize(String? text) {
    if (text == null || text.isEmpty) return "Unknown"; // Handle null or empty
    return text[0].toUpperCase() + text.substring(1);
  }

  var dio = Dio();
  String _firstHakAkses = "";
  List<String> _listSecondHakAkses = [];

  Future<void> _getHakAkses() async {
    try {
      final prefs = await getTokenSharedPref();
      var response = await dio.get('${myIpAddr()}/hak_akses', options: Options(headers: {"Authorization": "bearer " + prefs!}));

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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: EdgeInsets.zero,
              children: [
                SizedBox(
                  height: 200,
                  child: Obx(
                    () => DrawerHeader(
                      padding: EdgeInsets.zero,
                      margin: EdgeInsets.zero,
                      decoration: const BoxDecoration(color: Color(0XFFFFE0B2)),
                      child: Theme(
                        data: ThemeData().copyWith(dividerTheme: DividerThemeData(color: Colors.transparent)),
                        child: UserAccountsDrawerHeader(
                          decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
                          accountName: Text(namaKaryawan.value, style: TextStyle(color: Colors.black, fontFamily: 'Poppins', fontSize: 25)),
                          accountEmail: Text(
                            capitalize((jabatan.value == null || jabatan.value.isEmpty) ? _firstHakAkses : jabatan.value),
                            style: TextStyle(color: Colors.black, fontFamily: 'Poppins', fontSize: 20),
                          ),
                          currentAccountPictureSize: Size.square(60),
                          currentAccountPicture: CircleAvatar(
                            backgroundColor: Colors.amberAccent,
                            child: Text(capitalize(idKaryawan.value), style: TextStyle(fontFamily: 'Poppins')),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.zero,
                  margin: EdgeInsets.zero,
                  child: Theme(
                    data: ThemeData().copyWith(
                      dividerColor: Colors.transparent,
                      expansionTileTheme: ExpansionTileThemeData(
                        backgroundColor: Color(0XFFFFE0B2),
                        collapsedBackgroundColor: Color(0XFFFFE0B2),
                        tilePadding: EdgeInsets.zero,
                      ),
                    ),
                    child: ExpansionTile(
                      title: Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Text('Pendaftaran', style: TextStyle(fontSize: 30, fontFamily: 'Poppins')),
                      ),
                      children: [
                        Material(
                          color: Colors.white,
                          child: ListTile(
                            title: const Text('Daftar Pekerja', style: TextStyle(fontFamily: 'Poppins')),
                            onTap: () {
                              Get.to(() => RegisPekerja());
                            },
                          ),
                        ),
                        Material(
                          color: Colors.white,
                          child: ListTile(
                            title: const Text('Daftar Paket', style: TextStyle(fontFamily: 'Poppins')),
                            onTap: () {
                              Get.to(() => RegisPaket());
                            },
                          ),
                        ),
                        Material(
                          color: Colors.white,
                          child: ListTile(
                            title: const Text('Daftar Ruangan', style: TextStyle(fontFamily: 'Poppins')),
                            onTap: () {
                              Get.to(() => RegisRoom());
                            },
                          ),
                        ),
                        Material(
                          color: Colors.white,
                          child: ListTile(
                            title: const Text('Daftar Promo', style: TextStyle(fontFamily: 'Poppins')),
                            onTap: () {
                              Get.to(() => RegisPromo());
                            },
                          ),
                        ),
                        Material(
                          color: Colors.white,
                          child: ListTile(
                            title: const Text('Daftar Users', style: TextStyle(fontFamily: 'Poppins')),
                            onTap: () {
                              Get.to(() => RegisUser());
                            },
                          ),
                        ),
                        Material(
                          color: Colors.white,
                          child: ListTile(
                            title: const Text('Daftar Locker', style: TextStyle(fontFamily: 'Poppins')),
                            onTap: () {
                              Get.to(() => RegisLocker());
                            },
                          ),
                        ),
                        Material(
                          color: Colors.white,
                          child: ListTile(
                            title: const Text('Pajak', style: TextStyle(fontFamily: 'Poppins')),
                            onTap: () {
                              Get.to(() => Pajak());
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.zero,
                  margin: EdgeInsets.zero,
                  child: Theme(
                    data: ThemeData().copyWith(
                      dividerColor: Colors.transparent,
                      expansionTileTheme: ExpansionTileThemeData(
                        backgroundColor: Color(0XFFFFE0B2),
                        collapsedBackgroundColor: Color(0XFFFFE0B2),
                        tilePadding: EdgeInsets.zero,
                      ),
                    ),
                    child: ExpansionTile(
                      title: Padding(padding: const EdgeInsets.only(left: 20), child: Text('List Data', style: TextStyle(fontSize: 30, fontFamily: 'Poppins'))),
                      children: [
                        Material(
                          color: Colors.white,
                          child: ListTile(
                            title: const Text('List Pekerja', style: TextStyle(fontFamily: 'Poppins')),
                            onTap: () {
                              Get.to(() => Listpekerja());
                            },
                          ),
                        ),
                        Material(
                          color: Colors.white,
                          child: ListTile(
                            title: const Text('List Paket', style: TextStyle(fontFamily: 'Poppins')),
                            onTap: () {
                              Get.to(() => Listpaket());
                            },
                          ),
                        ),
                        Material(
                          color: Colors.white,
                          child: ListTile(
                            title: const Text('List Ruangan', style: TextStyle(fontFamily: 'Poppins')),
                            onTap: () {
                              Get.to(() => ListRoom());
                            },
                          ),
                        ),
                        Material(
                          color: Colors.white,
                          child: ListTile(
                            title: const Text('List Promo', style: TextStyle(fontFamily: 'Poppins')),
                            onTap: () {
                              Get.to(() => Listpromo());
                            },
                          ),
                        ),
                        Material(
                          color: Colors.white,
                          child: ListTile(
                            title: const Text('List Users', style: TextStyle(fontFamily: 'Poppins')),
                            onTap: () {
                              Get.to(() => ListUser());
                            },
                          ),
                        ),
                        Material(
                          color: Colors.white,
                          child: ListTile(
                            title: const Text('List Member', style: TextStyle(fontFamily: 'Poppins')),
                            onTap: () {
                              Get.to(() => ListMember());
                            },
                          ),
                        ),
                        Material(
                          color: Colors.white,
                          child: ListTile(
                            title: const Text('List Terapis', style: TextStyle(fontFamily: 'Poppins')),
                            onTap: () {
                              Get.to(() => ListTerapis());
                            },
                          ),
                        ),
                        Material(
                          color: Colors.white,
                          child: ListTile(
                            title: const Text('Set Harga VIP', style: TextStyle(fontFamily: 'Poppins')),
                            onTap: () {
                              Get.to(() => SetHargaVip());
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.zero,
                  margin: EdgeInsets.zero,
                  child: Theme(
                    data: ThemeData().copyWith(
                      dividerColor: Colors.transparent,
                      expansionTileTheme: ExpansionTileThemeData(
                        backgroundColor: Color(0XFFFFE0B2),
                        collapsedBackgroundColor: Color(0XFFFFE0B2),
                        tilePadding: EdgeInsets.zero,
                      ),
                    ),
                    child: ExpansionTile(
                      title: Padding(padding: const EdgeInsets.only(left: 20), child: Text('Transaksi', style: TextStyle(fontSize: 30, fontFamily: 'Poppins'))),
                      children: [
                        Material(
                          color: Colors.white,
                          child: ListTile(
                            title: const Text('Detail Transaksi', style: TextStyle(fontFamily: 'Poppins')),
                            onTap: () {
                              Get.off(() => ListTransaksi());
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.zero,
                  margin: EdgeInsets.zero,
                  child: Theme(
                    data: ThemeData().copyWith(
                      dividerColor: Colors.transparent,
                      expansionTileTheme: ExpansionTileThemeData(
                        backgroundColor: Color(0XFFFFE0B2),
                        collapsedBackgroundColor: Color(0XFFFFE0B2),
                        tilePadding: EdgeInsets.zero,
                      ),
                    ),
                    child: ExpansionTile(
                      title: Padding(padding: const EdgeInsets.only(left: 20), child: Text('Laporan', style: TextStyle(fontSize: 30, fontFamily: 'Poppins'))),
                      children: [
                        Material(
                          color: Colors.white,
                          child: ListTile(
                            title: const Text('Laporan OB', style: TextStyle(fontFamily: 'Poppins')),
                            onTap: () {
                              Get.to(() => LaporanOB());
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_firstHakAkses == "owner") ...[
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings_rounded),
                    title: const Text('Owner', style: TextStyle(fontFamily: 'Poppins')),
                    onTap: () {
                      Get.to(() => OwnerPage());
                    },
                  ),
                ],
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log Out', style: TextStyle(fontFamily: 'Poppins')),
            onTap: () async {
              await fnLogout();
            },
          ),
        ],
      ),
    );
  }
}
