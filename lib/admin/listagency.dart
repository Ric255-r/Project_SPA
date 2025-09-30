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

class ListAgency extends StatefulWidget {
  const ListAgency({super.key});

  @override
  State<ListAgency> createState() => _ListAgencyState();
}

class _ListAgencyState extends State<ListAgency> {
  String? selectedagency;
  RxList<Map<String, dynamic>> data_agency = <Map<String, String>>[].obs;
  RxList<Map<String, dynamic>> data_agency_filter =
      <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> data_karyawan_agency =
      <Map<String, dynamic>>[].obs;
  var dio = Dio();
  RxString nama_agency = ''.obs;
  RxString kodeagency = ''.obs;
  RxString alamat = ''.obs;
  RxString notelp = ''.obs;
  RxString namakota = ''.obs;
  RxString contactperson = ''.obs;
  TextEditingController edit_kode_agency = TextEditingController();
  TextEditingController edit_nama_agency = TextEditingController();
  TextEditingController edit_alamat = TextEditingController();
  TextEditingController edit_no_telp = TextEditingController();
  TextEditingController edit_nama_kota = TextEditingController();
  TextEditingController edit_contact_person = TextEditingController();

  Future<void> getdataagency() async {
    try {
      var response2 = await dio.get('${myIpAddr()}/listagency/getdataagency');
      data_agency.value =
          (response2.data as List)
              .map((item) => Map<String, String>.from(item))
              .toList();

      log(data_agency.toString());
    } catch (e) {
      log("error di getdataagency: ${e.toString()}");
    }
  }

  Future<void> getdataagencyfilter(nama_agency_pilihan) async {
    try {
      var response2 = await dio.get(
        '${myIpAddr()}/listagency/getdataagencyfilter',
        data: {'nama_agency': nama_agency_pilihan},
      );
      data_agency_filter.value =
          (response2.data as List)
              .map((item) => Map<String, String>.from(item))
              .toList();

      log(data_agency_filter.toString());
    } catch (e) {
      log("error di getdataagency: ${e.toString()}");
    }
  }

  Future<void> getdatakaryawanagency(nama_agencypilihan) async {
    var responsedatakaryawan = await dio.get(
      '${myIpAddr()}/listagency/getdatakaryawanagency',
      data: {'nama_agency': nama_agencypilihan},
    );

    data_karyawan_agency.value =
        (responsedatakaryawan.data as List)
            .map((item) => Map<String, String>.from(item))
            .toList();
  }

  Future<void> updatedataagency(
    kode_agency_lama,
    kode_agency_baru,
    nama_agency_lama,
    nama_agency_baru,
    alamat_baru,
    notelp_baru,
    namakota_baru,
    contact_baru,
  ) async {
    try {
      var responseupdateagency = await dio.put(
        '${myIpAddr()}/listagency/updatedataagency',
        data: {
          'kode_agency_lama': kode_agency_lama,
          'kode_agency': kode_agency_baru,
          'nama_agency_lama': nama_agency_lama,
          'nama_agency': nama_agency_baru,
          'alamat': alamat_baru,
          'no_telp': notelp_baru,
          'nama_kota': namakota_baru,
          'contact_person': contact_baru,
        },
      );
    } catch (e) {
      log("error di updatedataagency: ${e.toString()}");
    }
  }

  Future<void> deleteagency(nama_agencypilihan) async {
    var responsedeleteagency = await dio.put(
      '${myIpAddr()}/listagency/hapusdataagency',
      data: {'nama_agency': nama_agencypilihan},
    );
  }

  @override
  void initState() {
    super.initState();
    getdataagency();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shortest = MediaQuery.of(context).size.shortestSide;
    final bool isMobile = shortest < 600 || shortest > 700;
    log("isi Shortest Side ${MediaQuery.of(context).size.shortestSide}");
    // =======================================================================

    // 1. Tentukan lebar desain dasar Anda
    // 660 ini lebar terkecil DP tablet yg kita patok.
    const double tabletDesignWidth = 660;
    const double tabletDesignHeight = 1024;

    // 2. Tentukan faktor penyesuaian untuk mobile.
    const double mobileAdjustmentFactor = 1.25; // UI akan 25% lebih kecil

    // 3. Hitung designSize yang efektif berdasarkan tipe perangkat
    final double effectiveDesignWidth =
        isMobile
            ? tabletDesignWidth * mobileAdjustmentFactor
            : tabletDesignWidth;
    final double effectiveDesignHeight =
        isMobile
            ? tabletDesignHeight * mobileAdjustmentFactor
            : tabletDesignHeight;

    return isMobile
        ? WidgetListAgencyMobile()
        : Scaffold(
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
          body: SingleChildScrollView(
            child: Obx(
              () =>
                  data_agency.isNotEmpty
                      ? Container(
                        decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
                        width: Get.width,
                        height: Get.height,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Text(
                                  'List Agency',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Center(
                                child: Container(
                                  margin: EdgeInsets.only(top: 10),
                                  alignment: Alignment.centerLeft,
                                  width: Get.width - 100,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(width: 1),
                                    color: Colors.white,
                                  ),
                                  child: DropdownButton<String>(
                                    value: selectedagency,
                                    hint: Text('Select Agency'),
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
                                        selectedagency = value;
                                        getdataagencyfilter(
                                          selectedagency,
                                        ).then((_) {
                                          nama_agency.value =
                                              data_agency_filter[0]['nama_agency']
                                                  .toString();
                                          kodeagency.value =
                                              data_agency_filter[0]['kode_agency']
                                                  .toString();
                                          alamat.value =
                                              data_agency_filter[0]['alamat']
                                                  .toString();
                                          notelp.value =
                                              data_agency_filter[0]['no_telp']
                                                  .toString();
                                          namakota.value =
                                              data_agency_filter[0]['nama_kota']
                                                  .toString();
                                          contactperson.value =
                                              data_agency_filter[0]['contact_person']
                                                  .toString();
                                        });
                                        getdatakaryawanagency(selectedagency);
                                      });
                                    },
                                    items:
                                        data_agency.map<
                                          DropdownMenuItem<String>
                                        >((agency) {
                                          final namaagency =
                                              agency['nama_agency']
                                                  ?.toString() ??
                                              '';
                                          final kodeagency =
                                              agency['kode_agency']
                                                  ?.toString() ??
                                              '';
                                          return DropdownMenuItem<String>(
                                            value: namaagency,
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                '$kodeagency - $namaagency',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ),
                              ),
                              Center(
                                child: Container(
                                  margin: EdgeInsets.only(top: 20),
                                  width: Get.width - 100,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    border: Border.all(width: 1),
                                    color: Colors.white,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                  ),
                                  child: Obx(
                                    () => Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 130,
                                              margin: EdgeInsets.only(
                                                left: 10,
                                                top: 5,
                                              ),
                                              child: Text(
                                                'Kode Agency ',
                                                style: TextStyle(fontSize: 17),
                                              ),
                                            ),
                                            Container(
                                              margin: EdgeInsets.only(
                                                left: 20,
                                                top: 5,
                                              ),
                                              child: Text(
                                                ': ',
                                                style: TextStyle(fontSize: 17),
                                              ),
                                            ),
                                            Container(
                                              margin: EdgeInsets.only(
                                                left: 10,
                                                top: 5,
                                              ),
                                              child: Text(
                                                kodeagency.value.toString(),
                                                style: TextStyle(fontSize: 17),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Container(
                                              width: 130,
                                              margin: EdgeInsets.only(
                                                left: 10,
                                                top: 5,
                                              ),
                                              child: Text(
                                                'Nama Agency ',
                                                style: TextStyle(fontSize: 17),
                                              ),
                                            ),
                                            Container(
                                              margin: EdgeInsets.only(
                                                left: 20,
                                                top: 5,
                                              ),
                                              child: Text(
                                                ': ',
                                                style: TextStyle(fontSize: 17),
                                              ),
                                            ),
                                            Container(
                                              margin: EdgeInsets.only(
                                                left: 10,
                                                top: 5,
                                              ),
                                              child: Text(
                                                nama_agency.value.toString(),
                                                style: TextStyle(fontSize: 17),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Container(
                                              width: 130,
                                              margin: EdgeInsets.only(
                                                left: 10,
                                                top: 5,
                                              ),
                                              child: Text(
                                                'Alamat ',
                                                style: TextStyle(fontSize: 17),
                                              ),
                                            ),
                                            Container(
                                              margin: EdgeInsets.only(
                                                left: 20,
                                                top: 5,
                                              ),
                                              child: Text(
                                                ': ',
                                                style: TextStyle(fontSize: 17),
                                              ),
                                            ),
                                            Container(
                                              margin: EdgeInsets.only(
                                                left: 10,
                                                top: 5,
                                              ),
                                              child: Text(
                                                alamat.value.toString(),
                                                style: TextStyle(fontSize: 17),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Container(
                                              width: 130,
                                              margin: EdgeInsets.only(
                                                left: 10,
                                                top: 5,
                                              ),
                                              child: Text(
                                                'No Telp ',
                                                style: TextStyle(fontSize: 17),
                                              ),
                                            ),
                                            Container(
                                              margin: EdgeInsets.only(
                                                left: 20,
                                                top: 5,
                                              ),
                                              child: Text(
                                                ': ',
                                                style: TextStyle(fontSize: 17),
                                              ),
                                            ),
                                            Container(
                                              margin: EdgeInsets.only(
                                                left: 10,
                                                top: 5,
                                              ),
                                              child: Text(
                                                notelp.value.toString(),
                                                style: TextStyle(fontSize: 17),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Container(
                                              width: 130,
                                              margin: EdgeInsets.only(
                                                left: 10,
                                                top: 5,
                                              ),
                                              child: Text(
                                                'Nama Kota ',
                                                style: TextStyle(fontSize: 17),
                                              ),
                                            ),
                                            Container(
                                              margin: EdgeInsets.only(
                                                left: 20,
                                                top: 5,
                                              ),
                                              child: Text(
                                                ': ',
                                                style: TextStyle(fontSize: 17),
                                              ),
                                            ),
                                            Container(
                                              margin: EdgeInsets.only(
                                                left: 10,
                                                top: 5,
                                              ),
                                              child: Text(
                                                namakota.value.toString(),
                                                style: TextStyle(fontSize: 17),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Container(
                                              width: 130,
                                              margin: EdgeInsets.only(
                                                left: 10,
                                                top: 5,
                                              ),
                                              child: Text(
                                                'Contact Person ',
                                                style: TextStyle(fontSize: 17),
                                              ),
                                            ),
                                            Container(
                                              margin: EdgeInsets.only(
                                                left: 20,
                                                top: 5,
                                              ),
                                              child: Text(
                                                ': ',
                                                style: TextStyle(fontSize: 17),
                                              ),
                                            ),
                                            Container(
                                              margin: EdgeInsets.only(
                                                left: 10,
                                                top: 5,
                                              ),
                                              child: Text(
                                                contactperson.value.toString(),
                                                style: TextStyle(fontSize: 17),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Center(
                                child: Container(
                                  margin: EdgeInsets.only(top: 10),
                                  width: Get.width - 100,
                                  height: 50,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Center(
                                        child: Container(
                                          margin: EdgeInsets.only(right: 240),
                                          child: Text(
                                            'Daftar Karyawan',
                                            style: TextStyle(
                                              fontSize: 25,
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 60,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          border: Border.all(width: 1),
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(5),
                                          ),
                                          color: Colors.white,
                                        ),
                                        child: IconButton(
                                          onPressed: () {
                                            edit_kode_agency.text =
                                                kodeagency.value;
                                            edit_nama_agency.text =
                                                nama_agency.value;
                                            edit_alamat.text = alamat.value;
                                            edit_no_telp.text = notelp.value;
                                            edit_nama_kota.text =
                                                namakota.value;
                                            edit_contact_person.text =
                                                contactperson.value;
                                            editagency();
                                          },
                                          icon: Icon(Icons.edit, size: 25),
                                        ),
                                      ),
                                      SizedBox(width: 20),
                                      Container(
                                        width: 60,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          border: Border.all(width: 1),
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(5),
                                          ),
                                          color: Colors.white,
                                        ),
                                        child: IconButton(
                                          onPressed: () {
                                            deleteagencydialog();
                                          },
                                          icon: Icon(Icons.delete, size: 25),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Center(
                                child: Container(
                                  margin: EdgeInsets.only(top: 10),
                                  width: Get.width - 100,
                                  height: 450,
                                  decoration: BoxDecoration(
                                    border: Border.all(width: 1),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                    color: Colors.white,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            margin: EdgeInsets.only(
                                              left: 10,
                                              top: 10,
                                            ),
                                            width: 150,
                                            child: Center(
                                              child: Text(
                                                'Kode Karyawan',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Container(
                                            margin: EdgeInsets.only(top: 10),
                                            width: 150,
                                            child: Center(
                                              child: Text(
                                                'Nama Karyawan',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Container(
                                            margin: EdgeInsets.only(top: 10),
                                            width: 150,
                                            child: Center(
                                              child: Text(
                                                'Jabatan',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Container(
                                            margin: EdgeInsets.only(top: 10),
                                            width: 150,
                                            child: Center(
                                              child: Text(
                                                'Jenis Kelamin',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Container(
                                            margin: EdgeInsets.only(top: 10),
                                            width: 150,
                                            child: Center(
                                              child: Text(
                                                'No Telp',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Obx(
                                        () =>
                                            data_karyawan_agency.isNotEmpty
                                                ? Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.all(
                                                          Radius.circular(10),
                                                        ),
                                                  ),
                                                  width: Get.width - 100,
                                                  height: 417,
                                                  child: ListView.builder(
                                                    itemCount:
                                                        data_karyawan_agency
                                                            .length,
                                                    itemBuilder: (
                                                      context,
                                                      index,
                                                    ) {
                                                      var item =
                                                          data_karyawan_agency[index];
                                                      return Container(
                                                        child: Column(
                                                          children: [
                                                            Row(
                                                              children: [
                                                                Container(
                                                                  margin:
                                                                      EdgeInsets.only(
                                                                        left:
                                                                            10,
                                                                        top: 10,
                                                                      ),
                                                                  width: 150,
                                                                  child: Center(
                                                                    child: Text(
                                                                      item['id_karyawan']
                                                                          .toString(),
                                                                      style: TextStyle(
                                                                        fontFamily:
                                                                            'Poppins',
                                                                        fontSize:
                                                                            15,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  width: 10,
                                                                ),
                                                                Container(
                                                                  margin:
                                                                      EdgeInsets.only(
                                                                        top: 10,
                                                                      ),
                                                                  width: 150,
                                                                  child: Center(
                                                                    child: Text(
                                                                      item['nama_karyawan']
                                                                          .toString(),
                                                                      style: TextStyle(
                                                                        fontFamily:
                                                                            'Poppins',
                                                                        fontSize:
                                                                            15,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  width: 10,
                                                                ),
                                                                Container(
                                                                  margin:
                                                                      EdgeInsets.only(
                                                                        top: 10,
                                                                      ),
                                                                  width: 150,
                                                                  child: Center(
                                                                    child: Text(
                                                                      item['jabatan']
                                                                          .toString(),
                                                                      style: TextStyle(
                                                                        fontFamily:
                                                                            'Poppins',
                                                                        fontSize:
                                                                            15,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  width: 10,
                                                                ),
                                                                Container(
                                                                  margin:
                                                                      EdgeInsets.only(
                                                                        top: 10,
                                                                      ),
                                                                  width: 150,
                                                                  child: Center(
                                                                    child: Text(
                                                                      item['jk']
                                                                          .toString(),
                                                                      style: TextStyle(
                                                                        fontFamily:
                                                                            'Poppins',
                                                                        fontSize:
                                                                            15,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  width: 10,
                                                                ),
                                                                Container(
                                                                  margin:
                                                                      EdgeInsets.only(
                                                                        top: 10,
                                                                      ),
                                                                  width: 150,
                                                                  child: Center(
                                                                    child: Text(
                                                                      item['no_hp']
                                                                          .toString(),
                                                                      style: TextStyle(
                                                                        fontFamily:
                                                                            'Poppins',
                                                                        fontSize:
                                                                            15,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  width: 10,
                                                                ),
                                                              ],
                                                            ),
                                                            Divider(
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                )
                                                : Center(
                                                  child: Container(
                                                    margin: EdgeInsets.only(
                                                      top: 180,
                                                    ),
                                                    child: Text(
                                                      'Tidak ada data karyawan agency',
                                                    ),
                                                  ),
                                                ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 100),
                            ],
                          ),
                        ),
                      )
                      : Container(
                        color: Color(0XFFFFE0B2),
                        child: Center(child: CircularProgressIndicator()),
                      ),
            ),
          ),
          drawer: AdminDrawer(),
        );
  }

  void editagency() {
    Get.dialog(
      AlertDialog(
        content: Container(
          width: Get.width - 400,
          height: Get.height - 380,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.only(left: 22),
                    width: 150,
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Kode Agency :',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 15),
                    ),
                  ),
                  SizedBox(width: 10),
                  Container(
                    width: 500,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                      color: Colors.white,
                    ),
                    child: TextField(
                      controller: edit_kode_agency,
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 15),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 6.0,
                          vertical: 12,
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
                    padding: EdgeInsets.only(left: 22),
                    width: 150,
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Nama Agency :',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 15),
                    ),
                  ),
                  SizedBox(width: 10),
                  Container(
                    width: 500,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                      color: Colors.white,
                    ),
                    child: TextField(
                      controller: edit_nama_agency,
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 15),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 6.0,
                          vertical: 12,
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
                    padding: EdgeInsets.only(left: 22),
                    width: 150,
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Alamat :',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 15),
                    ),
                  ),
                  SizedBox(width: 10),
                  Container(
                    width: 500,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                      color: Colors.white,
                    ),
                    child: TextField(
                      controller: edit_alamat,
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 15),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 6.0,
                          vertical: 12,
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
                    padding: EdgeInsets.only(left: 22),
                    width: 150,
                    alignment: Alignment.centerRight,
                    child: Text(
                      'No Telp :',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 15),
                    ),
                  ),
                  SizedBox(width: 10),
                  Container(
                    width: 500,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                      color: Colors.white,
                    ),
                    child: TextField(
                      controller: edit_no_telp,
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 15),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 6.0,
                          vertical: 12,
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
                    padding: EdgeInsets.only(left: 22),
                    width: 150,
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Nama Kota :',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 15),
                    ),
                  ),
                  SizedBox(width: 10),
                  Container(
                    width: 500,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                      color: Colors.white,
                    ),
                    child: TextField(
                      controller: edit_nama_kota,
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 15),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 6.0,
                          vertical: 12,
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
                    padding: EdgeInsets.only(left: 22),
                    width: 150,
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Contact Person :',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 15),
                    ),
                  ),
                  SizedBox(width: 10),
                  Container(
                    width: 500,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                      color: Colors.white,
                    ),
                    child: TextField(
                      controller: edit_contact_person,
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 15),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 6.0,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                  ),
                  width: 50,
                  height: 50,
                  child: IconButton(
                    onPressed: () {
                      updatedataagency(
                        kodeagency.value,
                        edit_kode_agency.text,
                        nama_agency.value,
                        edit_nama_agency.text,
                        edit_alamat.text,
                        edit_no_telp.text,
                        edit_nama_kota.text,
                        edit_kode_agency.text,
                      ).then((_) {
                        selectedagency = null;
                        data_agency_filter.clear();
                        data_karyawan_agency.clear();
                        nama_agency.value = '';
                        kodeagency.value = '';
                        alamat.value = '';
                        notelp.value = '';
                        namakota.value = '';
                        contactperson.value = '';
                        getdataagency();
                        Get.back();
                      });
                    },
                    icon: Icon(Icons.save, size: 30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void deleteagencydialog() {
    Get.dialog(
      AlertDialog(
        content: Container(
          width: Get.width - 600,
          height: Get.height - 550,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  child: Text(
                    'Yakin ingin menghapus Agency $selectedagency ?',
                    style: TextStyle(fontSize: 20, fontFamily: 'Poppins'),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 60,
                      child: IconButton(
                        onPressed: () {
                          deleteagency(selectedagency).then((_) {
                            selectedagency = null;
                            data_agency_filter.clear();
                            data_karyawan_agency.clear();
                            nama_agency.value = '';
                            kodeagency.value = '';
                            alamat.value = '';
                            notelp.value = '';
                            namakota.value = '';
                            contactperson.value = '';
                            getdataagency();
                            Get.back();
                          });
                        },
                        icon: Icon(Icons.check_box, size: 50),
                      ),
                    ),
                    Container(
                      width: 100,
                      height: 60,
                      child: IconButton(
                        onPressed: () {
                          Get.back();
                        },
                        icon: Icon(Icons.cancel, size: 50),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WidgetListAgencyMobile extends StatefulWidget {
  const WidgetListAgencyMobile({super.key});

  @override
  State<WidgetListAgencyMobile> createState() => _WidgetListAgencyMobileState();
}

class _WidgetListAgencyMobileState extends State<WidgetListAgencyMobile> {
  String? selectedagency;
  RxList<Map<String, dynamic>> data_agency = <Map<String, String>>[].obs;
  RxList<Map<String, dynamic>> data_agency_filter =
      <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> data_karyawan_agency =
      <Map<String, dynamic>>[].obs;
  var dio = Dio();
  RxString nama_agency = ''.obs;
  RxString kodeagency = ''.obs;
  RxString alamat = ''.obs;
  RxString notelp = ''.obs;
  RxString namakota = ''.obs;
  RxString contactperson = ''.obs;
  TextEditingController edit_kode_agency = TextEditingController();
  TextEditingController edit_nama_agency = TextEditingController();
  TextEditingController edit_alamat = TextEditingController();
  TextEditingController edit_no_telp = TextEditingController();
  TextEditingController edit_nama_kota = TextEditingController();
  TextEditingController edit_contact_person = TextEditingController();

  Future<void> getdataagency() async {
    try {
      var response2 = await dio.get('${myIpAddr()}/listagency/getdataagency');
      data_agency.value =
          (response2.data as List)
              .map((item) => Map<String, String>.from(item))
              .toList();

      log(data_agency.toString());
    } catch (e) {
      log("error di getdataagency: ${e.toString()}");
    }
  }

  Future<void> getdataagencyfilter(nama_agency_pilihan) async {
    try {
      var response2 = await dio.get(
        '${myIpAddr()}/listagency/getdataagencyfilter',
        data: {'nama_agency': nama_agency_pilihan},
      );
      data_agency_filter.value =
          (response2.data as List)
              .map((item) => Map<String, String>.from(item))
              .toList();

      log(data_agency_filter.toString());
    } catch (e) {
      log("error di getdataagency: ${e.toString()}");
    }
  }

  Future<void> getdatakaryawanagency(nama_agencypilihan) async {
    var responsedatakaryawan = await dio.get(
      '${myIpAddr()}/listagency/getdatakaryawanagency',
      data: {'nama_agency': nama_agencypilihan},
    );

    data_karyawan_agency.value =
        (responsedatakaryawan.data as List)
            .map((item) => Map<String, String>.from(item))
            .toList();
  }

  Future<void> updatedataagency(
    kode_agency_lama,
    kode_agency_baru,
    nama_agency_lama,
    nama_agency_baru,
    alamat_baru,
    notelp_baru,
    namakota_baru,
    contact_baru,
  ) async {
    try {
      var responseupdateagency = await dio.put(
        '${myIpAddr()}/listagency/updatedataagency',
        data: {
          'kode_agency_lama': kode_agency_lama,
          'kode_agency': kode_agency_baru,
          'nama_agency_lama': nama_agency_lama,
          'nama_agency': nama_agency_baru,
          'alamat': alamat_baru,
          'no_telp': notelp_baru,
          'nama_kota': namakota_baru,
          'contact_person': contact_baru,
        },
      );
    } catch (e) {
      log("error di updatedataagency: ${e.toString()}");
    }
  }

  Future<void> deleteagency(nama_agencypilihan) async {
    var responsedeleteagency = await dio.put(
      '${myIpAddr()}/listagency/hapusdataagency',
      data: {'nama_agency': nama_agencypilihan},
    );
  }

  @override
  void initState() {
    super.initState();
    getdataagency();
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
          child: Obx(
            () =>
                data_agency.isNotEmpty
                    ? Container(
                      decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
                      width: Get.width,
                      height: Get.height,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                'List Agency',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Center(
                              child: Container(
                                margin: EdgeInsets.only(top: 10),
                                alignment: Alignment.centerLeft,
                                width: Get.width - 100,
                                height: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(width: 1),
                                  color: Colors.white,
                                ),
                                child: DropdownButton<String>(
                                  value: selectedagency,
                                  hint: Text('Select Agency'),
                                  isExpanded: true,
                                  icon: const Icon(Icons.arrow_drop_down),
                                  elevation: 14,
                                  style: const TextStyle(
                                    color: Colors.deepPurple,
                                  ),
                                  underline: SizedBox(),
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  onChanged: (String? value) {
                                    setState(() {
                                      selectedagency = value;
                                      getdataagencyfilter(selectedagency).then((
                                        _,
                                      ) {
                                        nama_agency.value =
                                            data_agency_filter[0]['nama_agency']
                                                .toString();
                                        kodeagency.value =
                                            data_agency_filter[0]['kode_agency']
                                                .toString();
                                        alamat.value =
                                            data_agency_filter[0]['alamat']
                                                .toString();
                                        notelp.value =
                                            data_agency_filter[0]['no_telp']
                                                .toString();
                                        namakota.value =
                                            data_agency_filter[0]['nama_kota']
                                                .toString();
                                        contactperson.value =
                                            data_agency_filter[0]['contact_person']
                                                .toString();
                                      });
                                      getdatakaryawanagency(selectedagency);
                                    });
                                  },
                                  items:
                                      data_agency.map<DropdownMenuItem<String>>(
                                        (agency) {
                                          final namaagency =
                                              agency['nama_agency']
                                                  ?.toString() ??
                                              '';
                                          final kodeagency =
                                              agency['kode_agency']
                                                  ?.toString() ??
                                              '';
                                          return DropdownMenuItem<String>(
                                            value: namaagency,
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                '$kodeagency - $namaagency',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ).toList(),
                                ),
                              ),
                            ),
                            Center(
                              child: Container(
                                margin: EdgeInsets.only(top: 20),
                                width: Get.width - 100,
                                height: 180,
                                decoration: BoxDecoration(
                                  border: Border.all(width: 1),
                                  color: Colors.white,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                ),
                                child: Obx(
                                  () => Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 130,
                                            margin: EdgeInsets.only(
                                              left: 10,
                                              top: 5,
                                            ),
                                            child: Text(
                                              'Kode Agency ',
                                              style: TextStyle(fontSize: 17),
                                            ),
                                          ),
                                          Container(
                                            margin: EdgeInsets.only(
                                              left: 20,
                                              top: 5,
                                            ),
                                            child: Text(
                                              ': ',
                                              style: TextStyle(fontSize: 17),
                                            ),
                                          ),
                                          Container(
                                            margin: EdgeInsets.only(
                                              left: 10,
                                              top: 5,
                                            ),
                                            child: Text(
                                              kodeagency.value.toString(),
                                              style: TextStyle(fontSize: 17),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            width: 130,
                                            margin: EdgeInsets.only(
                                              left: 10,
                                              top: 5,
                                            ),
                                            child: Text(
                                              'Nama Agency ',
                                              style: TextStyle(fontSize: 17),
                                            ),
                                          ),
                                          Container(
                                            margin: EdgeInsets.only(
                                              left: 20,
                                              top: 5,
                                            ),
                                            child: Text(
                                              ': ',
                                              style: TextStyle(fontSize: 17),
                                            ),
                                          ),
                                          Container(
                                            margin: EdgeInsets.only(
                                              left: 10,
                                              top: 5,
                                            ),
                                            child: Text(
                                              nama_agency.value.toString(),
                                              style: TextStyle(fontSize: 17),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            width: 130,
                                            margin: EdgeInsets.only(
                                              left: 10,
                                              top: 5,
                                            ),
                                            child: Text(
                                              'Alamat ',
                                              style: TextStyle(fontSize: 17),
                                            ),
                                          ),
                                          Container(
                                            margin: EdgeInsets.only(
                                              left: 20,
                                              top: 5,
                                            ),
                                            child: Text(
                                              ': ',
                                              style: TextStyle(fontSize: 17),
                                            ),
                                          ),
                                          Container(
                                            margin: EdgeInsets.only(
                                              left: 10,
                                              top: 5,
                                            ),
                                            child: Text(
                                              alamat.value.toString(),
                                              style: TextStyle(fontSize: 17),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            width: 130,
                                            margin: EdgeInsets.only(
                                              left: 10,
                                              top: 5,
                                            ),
                                            child: Text(
                                              'No Telp ',
                                              style: TextStyle(fontSize: 17),
                                            ),
                                          ),
                                          Container(
                                            margin: EdgeInsets.only(
                                              left: 20,
                                              top: 5,
                                            ),
                                            child: Text(
                                              ': ',
                                              style: TextStyle(fontSize: 17),
                                            ),
                                          ),
                                          Container(
                                            margin: EdgeInsets.only(
                                              left: 10,
                                              top: 5,
                                            ),
                                            child: Text(
                                              notelp.value.toString(),
                                              style: TextStyle(fontSize: 17),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            width: 130,
                                            margin: EdgeInsets.only(
                                              left: 10,
                                              top: 5,
                                            ),
                                            child: Text(
                                              'Nama Kota ',
                                              style: TextStyle(fontSize: 17),
                                            ),
                                          ),
                                          Container(
                                            margin: EdgeInsets.only(
                                              left: 20,
                                              top: 5,
                                            ),
                                            child: Text(
                                              ': ',
                                              style: TextStyle(fontSize: 17),
                                            ),
                                          ),
                                          Container(
                                            margin: EdgeInsets.only(
                                              left: 10,
                                              top: 5,
                                            ),
                                            child: Text(
                                              namakota.value.toString(),
                                              style: TextStyle(fontSize: 17),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            width: 130,
                                            margin: EdgeInsets.only(
                                              left: 10,
                                              top: 5,
                                            ),
                                            child: Text(
                                              'Contact Person ',
                                              style: TextStyle(fontSize: 17),
                                            ),
                                          ),
                                          Container(
                                            margin: EdgeInsets.only(
                                              left: 20,
                                              top: 5,
                                            ),
                                            child: Text(
                                              ': ',
                                              style: TextStyle(fontSize: 17),
                                            ),
                                          ),
                                          Container(
                                            margin: EdgeInsets.only(
                                              left: 10,
                                              top: 5,
                                            ),
                                            child: Text(
                                              contactperson.value.toString(),
                                              style: TextStyle(fontSize: 17),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Center(
                              child: Container(
                                margin: EdgeInsets.only(top: 10),
                                width: Get.width - 100,
                                height: 50,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Center(
                                      child: Container(
                                        margin: EdgeInsets.only(right: 110),
                                        child: Text(
                                          'Daftar Karyawan',
                                          style: TextStyle(
                                            fontSize: 25,
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 60,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        border: Border.all(width: 1),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(5),
                                        ),
                                        color: Colors.white,
                                      ),
                                      child: IconButton(
                                        onPressed: () {
                                          edit_kode_agency.text =
                                              kodeagency.value;
                                          edit_nama_agency.text =
                                              nama_agency.value;
                                          edit_alamat.text = alamat.value;
                                          edit_no_telp.text = notelp.value;
                                          edit_nama_kota.text = namakota.value;
                                          edit_contact_person.text =
                                              contactperson.value;
                                          editagency();
                                        },
                                        icon: Icon(Icons.edit, size: 25),
                                      ),
                                    ),
                                    SizedBox(width: 20),
                                    Container(
                                      width: 60,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        border: Border.all(width: 1),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(5),
                                        ),
                                        color: Colors.white,
                                      ),
                                      child: IconButton(
                                        onPressed: () {
                                          deleteagencydialog();
                                        },
                                        icon: Icon(Icons.delete, size: 25),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Center(
                              child: Container(
                                margin: EdgeInsets.only(top: 10),
                                width: Get.width - 100,
                                height: 450,
                                decoration: BoxDecoration(
                                  border: Border.all(width: 1),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                  color: Colors.white,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          margin: EdgeInsets.only(
                                            top: 10,
                                            left: 20,
                                          ),
                                          width: 125,
                                          child: Center(
                                            child: Text(
                                              'Kode Karyawan',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 20),
                                        Container(
                                          margin: EdgeInsets.only(top: 10),
                                          width: 135,
                                          child: Center(
                                            child: Text(
                                              'Nama Karyawan',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 20),
                                        Container(
                                          margin: EdgeInsets.only(top: 10),
                                          width: 75,
                                          child: Center(
                                            child: Text(
                                              'Jabatan',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 20),
                                        Container(
                                          margin: EdgeInsets.only(top: 10),
                                          width: 115,
                                          child: Center(
                                            child: Text(
                                              'Jenis Kelamin',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 45),
                                        Container(
                                          margin: EdgeInsets.only(top: 10),
                                          width: 65,
                                          child: Center(
                                            child: Text(
                                              'No Telp',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Obx(
                                      () =>
                                          data_karyawan_agency.isNotEmpty
                                              ? Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                        Radius.circular(10),
                                                      ),
                                                ),
                                                width: Get.width - 100,
                                                height: 417,
                                                child: ListView.builder(
                                                  itemCount:
                                                      data_karyawan_agency
                                                          .length,
                                                  itemBuilder: (
                                                    context,
                                                    index,
                                                  ) {
                                                    var item =
                                                        data_karyawan_agency[index];
                                                    return Container(
                                                      child: Column(
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Container(
                                                                margin:
                                                                    EdgeInsets.only(
                                                                      left: 50,
                                                                      top: 10,
                                                                    ),
                                                                width: 50,
                                                                child: Center(
                                                                  child: Text(
                                                                    item['id_karyawan']
                                                                        .toString(),
                                                                    style: TextStyle(
                                                                      fontFamily:
                                                                          'Poppins',
                                                                      fontSize:
                                                                          15,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                width: 70,
                                                              ),
                                                              Container(
                                                                margin:
                                                                    EdgeInsets.only(
                                                                      top: 10,
                                                                    ),
                                                                width: 120,
                                                                child: Center(
                                                                  child: Text(
                                                                    item['nama_karyawan']
                                                                        .toString(),
                                                                    style: TextStyle(
                                                                      fontFamily:
                                                                          'Poppins',
                                                                      fontSize:
                                                                          15,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                width: 15,
                                                              ),
                                                              Container(
                                                                margin:
                                                                    EdgeInsets.only(
                                                                      top: 10,
                                                                    ),
                                                                width: 100,
                                                                child: Center(
                                                                  child: Text(
                                                                    item['jabatan']
                                                                        .toString(),
                                                                    style: TextStyle(
                                                                      fontFamily:
                                                                          'Poppins',
                                                                      fontSize:
                                                                          15,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                width: 10,
                                                              ),
                                                              Container(
                                                                margin:
                                                                    EdgeInsets.only(
                                                                      top: 10,
                                                                    ),

                                                                width: 115,
                                                                child: Center(
                                                                  child: Text(
                                                                    item['jk']
                                                                        .toString(),
                                                                    style: TextStyle(
                                                                      fontFamily:
                                                                          'Poppins',
                                                                      fontSize:
                                                                          15,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                width: 10,
                                                              ),
                                                              Container(
                                                                margin:
                                                                    EdgeInsets.only(
                                                                      top: 10,
                                                                    ),
                                                                width: 130,
                                                                child: Center(
                                                                  child: Text(
                                                                    item['no_hp']
                                                                        .toString(),
                                                                    style: TextStyle(
                                                                      fontFamily:
                                                                          'Poppins',
                                                                      fontSize:
                                                                          15,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                width: 10,
                                                              ),
                                                            ],
                                                          ),
                                                          Divider(
                                                            color: Colors.black,
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              )
                                              : Center(
                                                child: Container(
                                                  margin: EdgeInsets.only(
                                                    top: 180,
                                                  ),
                                                  child: Text(
                                                    'Tidak ada data karyawan agency',
                                                  ),
                                                ),
                                              ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 100),
                          ],
                        ),
                      ),
                    )
                    : Container(
                      color: Color(0XFFFFE0B2),
                      child: Center(child: CircularProgressIndicator()),
                    ),
          ),
        ),
      ),
      drawer: AdminDrawer(),
    );
  }

  void editagency() {
    Get.dialog(
      AlertDialog(
        content: Container(
          width: Get.width - 150,
          height: Get.height - 410,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.only(left: 22),
                    width: 150,
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Kode Agency :',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 15),
                    ),
                  ),
                  SizedBox(width: 10),
                  Container(
                    width: 500,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                      color: Colors.grey[300],
                    ),
                    child: TextField(
                      controller: edit_kode_agency,
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 15),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 6.0,
                          vertical: 12,
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
                    padding: EdgeInsets.only(left: 22),
                    width: 150,
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Nama Agency :',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 15),
                    ),
                  ),
                  SizedBox(width: 10),
                  Container(
                    width: 500,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                      color: Colors.grey[300],
                    ),
                    child: TextField(
                      controller: edit_nama_agency,
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 15),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 6.0,
                          vertical: 12,
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
                    padding: EdgeInsets.only(left: 22),
                    width: 150,
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Alamat :',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 15),
                    ),
                  ),
                  SizedBox(width: 10),
                  Container(
                    width: 500,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                      color: Colors.grey[300],
                    ),
                    child: TextField(
                      controller: edit_alamat,
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 15),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 6.0,
                          vertical: 12,
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
                    padding: EdgeInsets.only(left: 22),
                    width: 150,
                    alignment: Alignment.centerRight,
                    child: Text(
                      'No Telp :',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 15),
                    ),
                  ),
                  SizedBox(width: 10),
                  Container(
                    width: 500,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                      color: Colors.grey[300],
                    ),
                    child: TextField(
                      controller: edit_no_telp,
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 15),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 6.0,
                          vertical: 12,
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
                    padding: EdgeInsets.only(left: 22),
                    width: 150,
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Nama Kota :',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 15),
                    ),
                  ),
                  SizedBox(width: 10),
                  Container(
                    width: 500,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                      color: Colors.grey[300],
                    ),
                    child: TextField(
                      controller: edit_nama_kota,
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 15),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 6.0,
                          vertical: 12,
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
                    padding: EdgeInsets.only(left: 22),
                    width: 150,
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Contact Person :',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 15),
                    ),
                  ),
                  SizedBox(width: 10),
                  Container(
                    width: 500,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                      color: Colors.grey[300],
                    ),
                    child: TextField(
                      controller: edit_contact_person,
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 15),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 6.0,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                  ),
                  width: 50,
                  height: 50,
                  child: IconButton(
                    onPressed: () {
                      updatedataagency(
                        kodeagency.value,
                        edit_kode_agency.text,
                        nama_agency.value,
                        edit_nama_agency.text,
                        edit_alamat.text,
                        edit_no_telp.text,
                        edit_nama_kota.text,
                        edit_kode_agency.text,
                      ).then((_) {
                        selectedagency = null;
                        data_agency_filter.clear();
                        data_karyawan_agency.clear();
                        nama_agency.value = '';
                        kodeagency.value = '';
                        alamat.value = '';
                        notelp.value = '';
                        namakota.value = '';
                        contactperson.value = '';
                        getdataagency();
                        Get.back();
                      });
                    },
                    icon: Icon(Icons.save, size: 30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void deleteagencydialog() {
    Get.dialog(
      AlertDialog(
        content: Container(
          width: Get.width - 300,
          height: Get.height - 600,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  child: Text(
                    'Yakin ingin menghapus Agency $selectedagency ?',
                    style: TextStyle(fontSize: 20, fontFamily: 'Poppins'),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 60,
                      child: IconButton(
                        onPressed: () {
                          deleteagency(selectedagency).then((_) {
                            selectedagency = null;
                            data_agency_filter.clear();
                            data_karyawan_agency.clear();
                            nama_agency.value = '';
                            kodeagency.value = '';
                            alamat.value = '';
                            notelp.value = '';
                            namakota.value = '';
                            contactperson.value = '';
                            getdataagency();
                            Get.back();
                          });
                        },
                        icon: Icon(Icons.check_box, size: 50),
                      ),
                    ),
                    Container(
                      width: 100,
                      height: 60,
                      child: IconButton(
                        onPressed: () {
                          Get.back();
                        },
                        icon: Icon(Icons.cancel, size: 50),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
