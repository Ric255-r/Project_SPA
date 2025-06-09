import 'dart:developer';
import 'package:Project_SPA/admin/laporan_ob.dart';
import 'package:Project_SPA/admin/listpaket.dart';
import 'package:Project_SPA/admin/listpekerja.dart';
import 'package:Project_SPA/admin/listpromo.dart';
import 'package:Project_SPA/admin/listroom.dart';
import 'package:Project_SPA/admin/listuser.dart';
import 'package:Project_SPA/admin/regis_paket.dart';
import 'package:Project_SPA/admin/regis_pekerja.dart';
import 'package:Project_SPA/admin/regis_promo.dart';
import 'package:Project_SPA/admin/regis_room.dart';
import 'package:Project_SPA/admin/regis_users.dart';
import 'package:Project_SPA/function/admin_drawer.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:Project_SPA/resepsionis/billing_locker.dart';
import 'package:Project_SPA/resepsionis/jenis_transaksi.dart';
import 'package:Project_SPA/main.dart';
import 'package:dio/dio.dart';
import 'package:Project_SPA/function/ip_address.dart';

class RegisLocker extends StatefulWidget {
  const RegisLocker({super.key});

  @override
  State<RegisLocker> createState() => _RegisLockerState();
}

class _RegisLockerState extends State<RegisLocker> {
  TextEditingController controller_nomor_locker = TextEditingController();

  RxList<Map<String, dynamic>> datalastnolocker = <Map<String, dynamic>>[].obs;
  var dio = Dio();

  Future<void> getlastnolocker() async {
    try {
      var response = await dio.get('${myIpAddr()}/locker/getlastnolocker');
      controller_nomor_locker.text = response.toString();
      nilaiLoker = int.parse(controller_nomor_locker.text) - 1;
    } catch (e) {
      log("Error di fn getlastnolocker : $e");
    }
  }

  int nilaiLoker = 0;
  Future<void> deleteLatestLoker(BuildContext context) async {
    try {
      var response = await dio.delete('${myIpAddr()}/locker/deletelast');

      if (response.statusCode == 200) {
        CherryToast.success(
          title: Text('Locker ${nilaiLoker} berhasil dihapus!'),
        ).show(context);
      } else {
        CherryToast.warning(
          title: Text(response.data['message'] ?? 'Failed to delete.'),
        ).show(context);
      }
    } catch (e) {
      CherryToast.error(title: Text("Locker gagal dihapus!")).show(context);
    }
  }

  Future<void> inputdatanolocker() async {
    try {
      var response = await dio.post('${myIpAddr()}/locker/daftarlocker');
      log("response : ${response.data}");
      log("sukses");
    } catch (e) {
      log("error: ${e.toString()}");
    }
  }

  Future<void> refreshdatanolocker() async {
    await Future.delayed(Duration(seconds: 1));
    await getlastnolocker();
  }

  @override
  void initState() {
    refreshdatanolocker();
    super.initState();
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
        width: Get.width,
        height: Get.height,
        color: Color(0XFFFFE0B2),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(shape: BoxShape.circle),
                child: ClipOval(
                  child: Image.asset('assets/spa.jpg', fit: BoxFit.cover),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text(
                  'Daftar Locker',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: Container(
                  height: 200,
                  width: 710,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.zero,
                            child: Container(
                              height: 60,
                              width: 200,
                              decoration: BoxDecoration(color: Colors.white),
                              child: Padding(
                                padding: EdgeInsets.only(right: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    SizedBox(height: 15),
                                    Text(
                                      'Nomor Locker :',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 0),
                            child: Container(
                              height: 60,
                              width: 500,
                              decoration: BoxDecoration(color: Colors.white),
                              child: Padding(
                                padding: EdgeInsets.only(left: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 12),
                                    Container(
                                      alignment: Alignment.centerLeft,
                                      width: 480,
                                      height: 35,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.grey[300],
                                      ),
                                      child: TextField(
                                        readOnly: true,
                                        controller: controller_nomor_locker,
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 12,
                                            horizontal: 10,
                                          ),
                                        ),

                                        style: TextStyle(
                                          fontSize: 20,
                                          fontFamily: 'Poppins',
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
                      SizedBox(height: 30),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Color(0XFFF6F7C4),
                            ),
                            height: 70,
                            width: 300,
                            child: TextButton(
                              onPressed: () {
                                inputdatanolocker();
                                CherryToast.success(
                                  title: Text(
                                    'Locker ${controller_nomor_locker.text} berhasil disimpan!',
                                  ),
                                ).show(context);
                                refreshdatanolocker();
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.black,
                              ),
                              child: Text(
                                'Simpan',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 20),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.redAccent,
                            ),
                            height: 70,
                            width: 300,
                            child: TextButton(
                              onPressed: () {
                                deleteLatestLoker(context);
                                refreshdatanolocker();
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.black,
                              ),
                              child: Text(
                                'Hapus',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontFamily: 'Poppins',
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
            ],
          ),
        ),
      ),
      drawer: AdminDrawer(),
    );
  }
}
