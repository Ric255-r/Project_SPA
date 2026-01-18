// ignore_for_file: sort_child_properties_last, curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:math' hide log;
import 'package:Project_SPA/owner/download_splash.dart';
import 'package:Project_SPA/resepsionis/detail_food_n_beverages.dart';
import 'package:Project_SPA/ruang_tunggu/main_rt.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:dartx/dartx_io.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'dart:io'; // For file operations
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:Project_SPA/function/ip_address.dart';
import 'package:Project_SPA/function/our_drawer.dart';
import 'package:Project_SPA/office_boy/image_mgr.dart';
import 'package:Project_SPA/office_boy/main_ob.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dio/dio.dart';
import 'dart:developer';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:cherry_toast/cherry_toast.dart';

class laporanpilihanterapis extends StatefulWidget {
  const laporanpilihanterapis({super.key});

  @override
  State<laporanpilihanterapis> createState() => _laporanpilihanterapisState();
}

class _laporanpilihanterapisState extends State<laporanpilihanterapis> with SingleTickerProviderStateMixin {
  RxString selectedvalue = DateTime.now().month.toString().obs;
  RxString selectedyearvalue = DateTime.now().year.toString().obs;
  RxList<Map<String, dynamic>> datakomisi = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> datakomisitahunan = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> datakomisiharian = <Map<String, dynamic>>[].obs;
  final formatnominal = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');
  RxList<DateTime?> _rangedatepickervalue = <DateTime?>[].obs;
  String startdate = '';
  String enddate = '';
  int currentmonth = DateTime.now().month;
  int currentyear = DateTime.now().year;
  int pilihanbulan = 1;
  int pilihantahun = 1;
  late TabController _tabController;

  RxInt total = 0.obs;
  RxInt totalharian = 0.obs;
  RxInt totaltahunan = 0.obs;
  int sum = 0;

  var dio = Dio();

  String? selectedagencybulanan;
  String? selectedagencytahunan;
  String? selectedagencyharian;
  String isitekscetakkomisibulanan = 'Cetak Komisi Gro';
  String isitekscetakkomisiharian = 'Cetak Komisi Gro';
  String isitekscetakkomisitahunan = 'Cetak Komisi Gro';
  RxList<Map<String, dynamic>> data_agency = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> _listNamaTerapis = <Map<String, dynamic>>[].obs;
  RxnString selectedidterapis = RxnString();

  DateTime? _getdateonly(DateTime? dateTime) {
    if (dateTime == null) {
      return null;
    }

    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  Future<void> getDataTerapis() async {
    try {
      var response = await dio.get('${myIpAddr()}/absen/dataTerapis');

      final List<Map<String, dynamic>> data =
          (response.data as List).map((item) {
            return {"id_karyawan": item["id_karyawan"].toString(), "nama_karyawan": item["nama_karyawan"]};
          }).toList();

      _listNamaTerapis.assignAll([
        {"id_karyawan": "all", "nama_karyawan": "Semua Terapis"},
        ...data,
      ]);
    } catch (e) {
      log("Error di fn Get Data Terapis $e");
    }
  }

  Future<void> exportlaporankerjaterapis(startdate, enddate, id_terapis) async {
    try {
      print('ini jalan');
      Get.dialog(const DownloadSplash(), barrierDismissible: false);
      final filepath;
      final dir = await getDownloadsDirectory();
      filepath = '${dir!.path}/data laporan kerja terapis tanggal $startdate - $enddate.pdf';

      String url = '${myIpAddr()}/main_owner/export_excel_laporankerjaterapis';
      var response = await dio.download(
        url,
        filepath,
        queryParameters: {'start_date': startdate, 'end_date': enddate, 'pilihan_terapis': id_terapis},
        options: Options(responseType: ResponseType.bytes, headers: {'Accept': 'application/pdf'}),
      );

      Get.back();

      await OpenFile.open(filepath);
      log('file downloaded to $filepath');
    } catch (e) {
      Get.back();
      log("Error di fn export laporan kerja terapis : $e");
      CherryToast.error(
        title: const Text("Download Failed"),
        description: const Text("Gagal menyiapkan file laporan kerja terapis"),
      ).show(Get.context!);
    }
  }

  @override
  void initState() {
    super.initState();
    getDataTerapis();
  }

  @override
  Widget build(BuildContext context) {
    // LOGIKA YANG DIPERBAIKI: Gunakan 'shortestSide' untuk deteksi tipe perangkat
    // Ini tidak akan terpengaruh oleh rotasi layar.
    final bool isMobile = MediaQuery.of(context).size.shortestSide < 600;
    // =======================================================================

    // 1. Tentukan lebar desain dasar Anda
    // 660 ini lebar terkecil DP tablet yg kita patok.
    const double tabletDesignWidth = 673;
    const double tabletDesignHeight = 1078;

    // 2. Tentukan faktor penyesuaian untuk mobile.
    const double mobileAdjustmentFactor = 1.25; // UI akan 25% lebih kecil

    // 3. Hitung designSize yang efektif berdasarkan tipe perangkat
    final double effectiveDesignWidth =
        isMobile ? tabletDesignWidth * mobileAdjustmentFactor : tabletDesignWidth;
    final double effectiveDesignHeight =
        isMobile ? tabletDesignHeight * mobileAdjustmentFactor : tabletDesignHeight;

    return ScreenUtilInit(
      designSize: Size(effectiveDesignWidth, effectiveDesignHeight),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Color(0XFFFFE0B2),
            title: Container(
              width: Get.width,
              alignment: Alignment.center,
              margin: EdgeInsets.only(right: 40),
              child: Text(
                'Laporan Kerja Terapis',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  height: 1,
                  fontSize: 20.w,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          backgroundColor: Color(0XFFFFE0B2),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(top: 50.w),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            onPressed: () async {
                              final results = await showDialog(
                                context: context,
                                builder: (context) {
                                  List<DateTime?> tempdate = List.from(_rangedatepickervalue);
                                  return Dialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    child: SingleChildScrollView(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(vertical: 16.w, horizontal: 16.w),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('Silahkan pilih rentang tanggal'),
                                            SizedBox(height: 15.w),
                                            CalendarDatePicker2(
                                              config: CalendarDatePicker2Config(
                                                calendarType: CalendarDatePicker2Type.range,
                                                selectedDayHighlightColor: Colors.deepPurple,
                                                dayTextStyle: TextStyle(fontSize: 15.w),
                                              ),
                                              value: tempdate,
                                              onValueChanged: (dates) {
                                                tempdate = dates.map((d) => _getdateonly(d)).toList();
                                              },
                                            ),
                                            SizedBox(height: 15.w),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                TextButton(
                                                  child: const Text('Cancel'),
                                                  onPressed: () => Navigator.of(context).pop(),
                                                ),
                                                const SizedBox(width: 8),
                                                TextButton(
                                                  child: const Text('OK'),
                                                  onPressed: () => Navigator.of(context).pop(tempdate),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ).then((results) {
                                if (results != null) {
                                  final List<DateTime?> cleanedResults =
                                      (results as List)
                                          .map((date) => _getdateonly(date) as DateTime?)
                                          .toList();

                                  _rangedatepickervalue.assignAll(cleanedResults);

                                  startdate =
                                      _rangedatepickervalue[0]?.toIso8601String().split('T').first ?? '';
                                  enddate =
                                      _rangedatepickervalue.length > 1
                                          ? _rangedatepickervalue[1]?.toIso8601String().split('T').first ?? ''
                                          : startdate;
                                }
                              });
                            },
                            child: Text('Pilih Tanggal', style: TextStyle(fontSize: 15.w)),
                          ),
                          SizedBox(width: 20),
                          Obx(
                            () => Container(
                              child: Text(
                                _rangedatepickervalue.isEmpty
                                    ? 'Pilihan tanggal : - '
                                    : 'Pilihan tanggal : ${startdate} - ${enddate}',
                                style: TextStyle(fontSize: 15.w),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.w),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 200.w,
                            height: 50.w,
                            child: Obx(
                              () => DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: "Pilih Terapis",
                                  border: OutlineInputBorder(),
                                ),
                                value: selectedidterapis.value,
                                items:
                                    _listNamaTerapis.map((terapis) {
                                      return DropdownMenuItem<String>(
                                        value: terapis['id_karyawan'],
                                        child: Text(terapis['nama_karyawan']),
                                      );
                                    }).toList(),
                                onChanged: (value) {
                                  selectedidterapis.value = value!;
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.w),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            margin: EdgeInsets.only(top: 0.w),
                            width: 160.w,
                            height: 35.w,
                            child: ElevatedButton(
                              onPressed: () async {
                                await exportlaporankerjaterapis(startdate, enddate, selectedidterapis.value);
                              },
                              child: Text(
                                'Cetak Laporan',
                                style: TextStyle(fontSize: 15.w, color: Colors.black),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFFCEFCB),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20.w),
              ],
            ),
          ),

          drawer: OurDrawer(),
        );
      },
    );
  }
}
