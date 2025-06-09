import 'dart:developer';

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
import 'package:Project_SPA/function/admin_drawer.dart';
import 'package:Project_SPA/function/me.dart';
import 'package:Project_SPA/function/our_drawer.dart';
import 'package:Project_SPA/function/token.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Project_SPA/resepsionis/billing_locker.dart';
import 'package:Project_SPA/resepsionis/jenis_transaksi.dart';
import 'package:Project_SPA/main.dart';
import 'package:get_storage/get_storage.dart';

class MainAdmin extends StatefulWidget {
  const MainAdmin({super.key});

  @override
  State<MainAdmin> createState() => _MainAdminState();
}

class _MainAdminState extends State<MainAdmin> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _profileUser();
  }

  var namaKaryawan = "".obs;
  var jabatan = "".obs;

  Future<void> _profileUser() async {
    // Token Bentrok kalo Mode Debug. Kalo error sini, build apk di masing2 devices
    try {
      final prefs = await getTokenSharedPref();
      var response = await getMyData(prefs);
      log("Isi getMyData $response");

      Map<String, dynamic> responseData = response['data'];
      print(responseData);

      namaKaryawan.value = responseData['nama_karyawan'];
      jabatan.value = responseData['jabatan'];
    } catch (e) {
      log("Error di _profileUser main_admin $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(''),
        centerTitle: true,
        backgroundColor: Color(0XFFFFE0B2),
      ),
      body: Container(
        decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
        width: Get.width,
        height: Get.height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 250,
              width: 250,
              decoration: BoxDecoration(shape: BoxShape.circle),
              child: ClipOval(
                child: Image.asset('assets/spa.jpg', fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 30),
              child: Text(
                'PLATINUM',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      drawer: Obx(() {
        if (jabatan.value == "admin") {
          return AdminDrawer();
        } else {
          return OurDrawer();
        }
      }),
    );
  }
}
