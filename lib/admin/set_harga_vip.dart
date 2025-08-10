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

class SetHargaVip extends StatefulWidget {
  const SetHargaVip({super.key});

  @override
  State<SetHargaVip> createState() => _SetHargaVipState();
}

class _SetHargaVipState extends State<SetHargaVip> {
  late final Dio dio;
  TextEditingController hargavip = TextEditingController();
  RxList<Map<String, dynamic>> datahargavip = <Map<String, dynamic>>[].obs;

  Future<void> getdatahargavip() async {
    try {
      var response = await dio.get('${myIpAddr()}/ruangan/datahargavip');
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {"harga_vip": item['harga_vip']};
          }).toList();

      datahargavip.clear();
      datahargavip.assignAll(fetcheddata);
      datahargavip.refresh();

      if (datahargavip.isNotEmpty) {
        hargavip.text = datahargavip[0]['harga_vip'].toString();
      }
    } catch (e) {
      log("Error di fn getdatahargavip : $e");
    }
  }

  Future<void> updatehargavip() async {
    try {
      var response = await dio.put(
        '${myIpAddr()}/ruangan/updatehargavip',
        data: {"harga_baru_vip": hargavip.text},
      );
      CherryToast.success(
        title: Text('Sukses'),
        description: Text('Harga VIP Berhasil Di Update'),
      ).show(context);
    } catch (e) {
      log("Error di fn getdatahargavip : $e");
      CherryToast.error(
        title: Text('Gagal'),
        description: Text('Harga VIP Gagal Di Update'),
      ).show(context);
    }
  }

  @override
  void initState() {
    super.initState();
    dio = Dio();
    getdatahargavip();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                  'Set Harga Room VIP',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 150, left: 50),
                padding: EdgeInsets.only(left: 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                height: 80,
                width: 700,
                child: Row(
                  children: [
                    Container(
                      child: Text(
                        'Harga Ruangan VIP :',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 30),
                      ),
                    ),
                    SizedBox(width: 20),
                    Container(
                      width: 300,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        color: Colors.grey[300],
                      ),
                      child: TextField(
                        controller: hargavip,
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 25),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 60),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Color(0XFFF6F7C4),
                ),
                height: 60,
                width: 200,
                child: TextButton(
                  onPressed: updatehargavip,
                  child: Text(
                    'Update',
                    style: TextStyle(color: Colors.black, fontSize: 30),
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
