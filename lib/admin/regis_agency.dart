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

class RegisAgency extends StatefulWidget {
  const RegisAgency({super.key});

  @override
  State<RegisAgency> createState() => _RegisAgencyState();
}

class _RegisAgencyState extends State<RegisAgency> {
  late final Dio dio;
  TextEditingController kode_agency = TextEditingController();
  TextEditingController nama_agency = TextEditingController();
  TextEditingController alamat = TextEditingController();
  TextEditingController no_telp = TextEditingController();
  TextEditingController nama_kota = TextEditingController();
  TextEditingController contact_person = TextEditingController();
  RxList<Map<String, dynamic>> data_agency = <Map<String, String>>[].obs;

  Future<void> inputdataagency() async {
    String kodeagency = kode_agency.text;
    String namaagency = nama_agency.text;

    try {
      var response2 = await dio.get('${myIpAddr()}/agency/getagency');

      log(response2.data.toString());

      data_agency.value =
          (response2.data as List)
              .map((item) => Map<String, String>.from(item))
              .toList();

      bool agencyexist = data_agency.any(
        (item) =>
            item['nama_agency'].toString().toLowerCase() ==
            namaagency.toLowerCase(),
      );

      bool kodeagencyexist = data_agency.any(
        (item) =>
            item['kode_agency'].toString().toLowerCase() ==
            kodeagency.toLowerCase(),
      );

      if (kodeagency != "" && namaagency != "") {
        if (!kodeagencyexist) {
          if (!agencyexist) {
            var response = await dio.post(
              '${myIpAddr()}/agency/daftaragency',
              data: {
                "kode_agency": kodeagency,
                "nama_agency": namaagency,
                "alamat": alamat.text,
                "no_telp": no_telp.text,
                "nama_kota": nama_kota.text,
                "contact_person": contact_person.text,
              },
            );
            log("data sukses tersimpan");
            CherryToast.success(
              title: Text('Agency $namaagency Saved Successfully!'),
            ).show(context);
            kode_agency.clear();
            nama_agency.clear();
            alamat.text = '';
            no_telp.text = '';
            nama_kota.text = '';
            contact_person.text = '';
          } else {
            log("data gagal tersimpan");
            CherryToast.error(
              title: Text('Agency $namaagency Already existed!'),
            ).show(context);
          }
        } else {
          CherryToast.error(
            title: Text('Kode Agency $kodeagency Already existed!'),
          ).show(context);
        }
      } else {
        log("data kosong");
        CherryToast.warning(
          title: Text('Data inputan tidak boleh kosong'),
        ).show(context);
      }
    } catch (e) {
      log("error: ${e.toString()}");
    }
  }

  @override
  void initState() {
    super.initState();
    dio = Dio();
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
                  'Daftar Agency',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 60, left: 5),
                padding: EdgeInsets.only(left: 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                height: 300,
                width: 700,
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.only(left: 22),
                          width: 200,
                          child: Text(
                            'Kode Agency :',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                            ),
                          ),
                        ),
                        Container(
                          width: 420,
                          height: 35,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(5)),
                            color: Colors.grey[300],
                          ),
                          child: TextField(
                            controller: kode_agency,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          width: 200,
                          padding: EdgeInsets.only(left: 12),
                          child: Text(
                            'Nama Agency :',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                            ),
                          ),
                        ),
                        Container(
                          width: 420,
                          height: 35,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(5)),
                            color: Colors.grey[300],
                          ),
                          child: TextField(
                            controller: nama_agency,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          width: 200,
                          padding: EdgeInsets.only(left: 82),
                          child: Text(
                            'Alamat :',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                            ),
                          ),
                        ),
                        Container(
                          width: 420,
                          height: 35,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(5)),
                            color: Colors.grey[300],
                          ),
                          child: TextField(
                            controller: alamat,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          width: 200,
                          padding: EdgeInsets.only(left: 81),
                          child: Text(
                            'No Telp :',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                            ),
                          ),
                        ),
                        Container(
                          width: 420,
                          height: 35,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(5)),
                            color: Colors.grey[300],
                          ),
                          child: TextField(
                            controller: no_telp,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.only(left: 42),
                          width: 200,
                          child: Text(
                            'Nama Kota :',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                            ),
                          ),
                        ),
                        Container(
                          width: 420,
                          height: 35,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(5)),
                            color: Colors.grey[300],
                          ),
                          child: TextField(
                            controller: nama_kota,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          width: 200,
                          child: Text(
                            'Contact Person :',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                            ),
                          ),
                        ),
                        Container(
                          width: 420,
                          height: 35,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(5)),
                            color: Colors.grey[300],
                          ),
                          child: TextField(
                            controller: contact_person,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Color(0XFFF6F7C4),
                ),
                height: 80,
                width: 200,
                child: TextButton(
                  onPressed: inputdataagency,
                  child: Text(
                    'Save',
                    style: TextStyle(color: Colors.black, fontSize: 40),
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
