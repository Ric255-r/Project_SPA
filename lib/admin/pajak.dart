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

class Pajak extends StatefulWidget {
  const Pajak({super.key});

  @override
  State<Pajak> createState() => _PajakState();
}

class _PajakState extends State<Pajak> {
  TextEditingController controller_pajak_msg = TextEditingController();
  TextEditingController controller_pajak_fnb = TextEditingController();
  var dio = Dio();

  Future<List<Map<String, dynamic>>> getPajak() async {
    try {
      var response = await dio.get('${myIpAddr()}/pajak/getpajak');

      if (response.statusCode == 200) {
        List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(
          response.data,
        );

        if (data.isNotEmpty) {
          var first = data[0];

          if (first.containsKey('pajak_fnb')) {
            double pajakFnb =
                double.tryParse(first['pajak_fnb'].toString()) ?? 0.0;
            controller_pajak_fnb.text =
                pajakFnb == 0.0 ? '0' : (pajakFnb * 100).toStringAsFixed(0);
          }

          if (first.containsKey('pajak_msg')) {
            double pajakMsg =
                double.tryParse(first['pajak_msg'].toString()) ?? 0.0;
            controller_pajak_msg.text =
                pajakMsg == 0.0 ? '0' : (pajakMsg * 100).toStringAsFixed(0);
          }
        }

        return data;
      } else {
        throw Exception("Failed to load data: ${response.statusCode}");
      }
    } on DioException catch (e) {
      throw Exception("Dio error: ${e.message}");
    }
  }

  Future<void> updatePajak() async {
    try {
      // Convert from 35 → 0.35
      double pajakMsgValue = double.parse(controller_pajak_msg.text) / 100;
      double pajakFnbValue = double.parse(controller_pajak_fnb.text) / 100;
      var response = await dio.put(
        '${myIpAddr()}/pajak/updatepajak',
        data: {"pajak_msg": pajakMsgValue, "pajak_fnb": pajakFnbValue},
      );

      if (response.statusCode == 200) {
        CherryToast.success(
          title: Text("Pajak berhasil diupdate!"),
        ).show(context);
        log("Update success: ${response.data}");
      } else {
        CherryToast.error(title: Text("Pajak gagal diupdate!")).show(context);
        log("Update failed: ${response.statusCode}");
      }
    } catch (e) {
      log("Error in updatePajak: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    getPajak();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(''),
        toolbarHeight: 40,
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
              Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Text(
                      'Pajak',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Center(
                child: Container(
                  height: 300,
                  width: 600,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: Container(
                              height: 105,
                              width: 200,
                              decoration: BoxDecoration(color: Colors.white),
                              child: Padding(
                                padding: EdgeInsets.only(right: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    SizedBox(height: 15),
                                    Text(
                                      'Pajak Massage :',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 20,
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    Text(
                                      'Pajak F&B :',
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
                            padding: const EdgeInsets.only(top: 20),
                            child: Container(
                              height: 105,
                              width: 400,
                              decoration: BoxDecoration(color: Colors.white),
                              child: Padding(
                                padding: EdgeInsets.only(left: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Container(
                                          alignment: Alignment.centerLeft,
                                          width: 330,
                                          height: 35,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            color: Colors.grey[300],
                                          ),
                                          child: TextField(
                                            controller: controller_pajak_msg,
                                            keyboardType: TextInputType.number,
                                            inputFormatters:
                                                <TextInputFormatter>[
                                                  FilteringTextInputFormatter
                                                      .digitsOnly,
                                                ],
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
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
                                        Text(
                                          ' %',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 25,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Container(
                                          alignment: Alignment.centerLeft,
                                          width: 330,
                                          height: 35,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            color: Colors.grey[300],
                                          ),
                                          child: TextField(
                                            controller: controller_pajak_fnb,
                                            keyboardType: TextInputType.number,
                                            inputFormatters:
                                                <TextInputFormatter>[
                                                  FilteringTextInputFormatter
                                                      .digitsOnly,
                                                ],
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
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
                                        Text(
                                          ' %',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 25,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 30),
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Color(0XFFF6F7C4),
                          ),
                          height: 70,
                          width: 300,
                          child: TextButton(
                            onPressed: updatePajak,
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
