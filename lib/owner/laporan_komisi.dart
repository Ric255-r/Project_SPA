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

class laporankomisi extends StatefulWidget {
  const laporankomisi({super.key});

  @override
  State<laporankomisi> createState() => _laporankomisiState();
}

class _laporankomisiState extends State<laporankomisi>
    with SingleTickerProviderStateMixin {
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
  int selectedtabindex = 1;

  var dio = Dio();

  Future<void> getdatakomisi(bulan, tahun) async {
    try {
      print('ini jalan');
      var response = await dio.get(
        '${myIpAddr()}/cekkomisi/listkomisiowner',
        data: {'month': bulan, 'year': tahun},
      );
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "id_karyawan": item['id_karyawan'],
              "nama_karyawan": item['nama_karyawan'],
              "total_komisi": item['total_komisi'],
            };
          }).toList();
      setState(() {
        datakomisi.clear();
        datakomisi.assignAll(fetcheddata);
        datakomisi.refresh();
      });
    } catch (e) {
      log("Error di fn getdatakomisi : $e");
    }
  }

  Future<void> exportkomisibulanan(bulan, tahun) async {
    try {
      print('ini jalan');
      Get.dialog(const DownloadSplash(), barrierDismissible: false);
      final dir = await getDownloadsDirectory();
      final filepath = '${dir!.path}/data komisi bulan $bulan tahun $tahun.pdf';
      String url = '${myIpAddr()}/main_owner/export_excel_komisi_bulanan';
      var response = await dio.download(
        url,
        filepath,
        queryParameters: {'month': bulan, 'year': tahun},
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': 'application/pdf'},
        ),
      );

      Get.back();

      await OpenFile.open(filepath);
      log('file downloaded to $filepath');
    } catch (e) {
      Get.back();
      log("Error di fn getdatakomisibulanan : $e");
      Get.snackbar("Download Failed", "Gagal menyiapkan file komisi terapis");
    }
  }

  Future<void> exportkomisigrobulanan(bulan, tahun) async {
    try {
      print('ini jalan');
      Get.dialog(const DownloadSplash(), barrierDismissible: false);
      final dir = await getDownloadsDirectory();
      final filepath =
          '${dir!.path}/data komisi terapis bulan $bulan tahun $tahun.pdf';
      String url = '${myIpAddr()}/main_owner/export_excel_komisi_bulanan_gro';
      var response = await dio.download(
        url,
        filepath,
        queryParameters: {'month': bulan, 'year': tahun},
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': 'application/pdf'},
        ),
      );

      Get.back();

      await OpenFile.open(filepath);
      log('file downloaded to $filepath');
    } catch (e) {
      Get.back();
      log("Error di fn getdatakomisibulanan : $e");
      Get.snackbar("Download Failed", "Gagal menyiapkan file komisi GRO");
    }
  }

  Future<void> getdatakomisitahunan(tahun) async {
    try {
      print('ini jalan');
      var response = await dio.get(
        '${myIpAddr()}/cekkomisi/listkomisiownertahunan',
        data: {'year': tahun},
      );
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "id_karyawan": item['id_karyawan'],
              "nama_karyawan": item['nama_karyawan'],
              "total_komisi": item['total_komisi'],
            };
          }).toList();
      setState(() {
        datakomisitahunan.clear();
        datakomisitahunan.assignAll(fetcheddata);
        datakomisitahunan.refresh();
      });
    } catch (e) {
      log("Error di fn getdatakomisi : $e");
    }
  }

  Future<void> getdatakomisiharian(tanggalawal, tanggalakhir) async {
    try {
      print('ini jalan');
      var response = await dio.get(
        '${myIpAddr()}/cekkomisi/listkomisiownerharian',
        data: {'startdate': tanggalawal, 'enddate': tanggalakhir},
      );
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "id_karyawan": item['id_karyawan'],
              "nama_karyawan": item['nama_karyawan'],
              "total_komisi": item['total_komisi'],
            };
          }).toList();
      setState(() {
        datakomisiharian.clear();
        datakomisiharian.assignAll(fetcheddata);
        datakomisiharian.refresh();
      });
    } catch (e) {
      log("Error di fn getdatakomisi : $e");
    }
  }

  DateTime? _getdateonly(DateTime? dateTime) {
    if (dateTime == null) {
      return null;
    }

    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  @override
  void initState() {
    super.initState();
    pilihanbulan = currentmonth;
    pilihantahun = currentyear;
    getdatakomisi(currentmonth, currentyear);
    getdatakomisitahunan(currentyear);
    _tabController = TabController(length: 3, initialIndex: 1, vsync: this);
    _tabController.addListener(() {
      setState(() {
        selectedtabindex = _tabController.index;
      });
    });
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
        isMobile
            ? tabletDesignWidth * mobileAdjustmentFactor
            : tabletDesignWidth;
    final double effectiveDesignHeight =
        isMobile
            ? tabletDesignHeight * mobileAdjustmentFactor
            : tabletDesignHeight;

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
                'Laporan Komisi Terapis & Gro',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  height: 1,
                  fontSize: 30.w,
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
                selectedtabindex == 1
                    ? Container(
                      width: 1100.w,
                      height: 100.w,
                      margin: EdgeInsets.only(top: 50.w),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: EdgeInsets.only(top: 0.w),
                                height: 50,
                                alignment: Alignment.topCenter,
                                child: Text(
                                  'Bulan : ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                    height: 1,
                                    fontSize: 20.w,
                                  ),
                                ),
                              ),
                              Obx(
                                () => Container(
                                  margin: EdgeInsets.only(top: 0.w),
                                  width: 140.w,
                                  height: 55.w,
                                  child: DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.only(
                                        top: 0.w,
                                        bottom: 0.w,
                                        left: 10.w,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.blue,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.red,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[200],
                                    ),
                                    value: selectedvalue.value,
                                    style: TextStyle(
                                      fontSize: 15.w,
                                      color: Colors.black,
                                    ),
                                    items:
                                        <String>[
                                          '1',
                                          '2',
                                          '3',
                                          '4',
                                          '5',
                                          '6',
                                          '7',
                                          '8',
                                          '9',
                                          '10',
                                          '11',
                                          '12',
                                        ].map((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(
                                              value == '1'
                                                  ? 'Januari'
                                                  : value == '2'
                                                  ? 'Februari'
                                                  : value == '3'
                                                  ? 'Maret'
                                                  : value == '4'
                                                  ? 'April'
                                                  : value == '5'
                                                  ? 'Mei'
                                                  : value == '6'
                                                  ? 'Juni'
                                                  : value == '7'
                                                  ? 'Juli'
                                                  : value == '8'
                                                  ? 'Agustus'
                                                  : value == '9'
                                                  ? 'September'
                                                  : value == '10'
                                                  ? 'Oktober'
                                                  : value == '11'
                                                  ? 'September'
                                                  : 'Desember',
                                            ),
                                          );
                                        }).toList(),
                                    onChanged: (String? newValue) {
                                      selectedvalue.value = newValue!;
                                      pilihanbulan = int.parse(newValue);
                                      print(pilihanbulan);
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(width: 20),
                              Container(
                                margin: EdgeInsets.only(top: 0.w),
                                height: 50,
                                alignment: Alignment.topCenter,
                                child: Text(
                                  'Tahun : ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                    height: 1,
                                    fontSize: 20.w,
                                  ),
                                ),
                              ),
                              Obx(
                                () => Container(
                                  margin: EdgeInsets.only(top: 0.w),
                                  width: 140.w,
                                  height: 55.w,
                                  child: DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.only(
                                        top: 0.w,
                                        bottom: 0.w,
                                        left: 10.w,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.blue,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.red,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[200],
                                    ),
                                    value: selectedyearvalue.value,
                                    style: TextStyle(
                                      fontSize: 15.w,
                                      color: Colors.black,
                                    ),
                                    items:
                                        List.generate(
                                          DateTime.now().year - 2000 + 1,
                                          (index) => 2000 + index,
                                        ).map((int year) {
                                          return DropdownMenuItem<String>(
                                            value: year.toString(),
                                            child: Text(year.toString()),
                                          );
                                        }).toList(),
                                    onChanged: (String? newValue) {
                                      selectedyearvalue.value = newValue!;
                                      pilihantahun = int.parse(newValue);
                                      print(pilihantahun);
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(width: 20),
                              Container(
                                margin: EdgeInsets.only(top: 0.w),
                                width: 160.w,
                                height: 35.w,
                                child: ElevatedButton(
                                  onPressed: () {
                                    getdatakomisi(pilihanbulan, pilihantahun);
                                    log(selectedtabindex.toString());
                                  },
                                  child: Text(
                                    'Cek Komisi',
                                    style: TextStyle(
                                      fontSize: 20.w,
                                      color: Colors.black,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFFFCEFCB),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                margin: EdgeInsets.only(top: 0.w),
                                width: 175.w,
                                height: 35.w,
                                child: ElevatedButton(
                                  onPressed: () {
                                    exportkomisibulanan(
                                      pilihanbulan,
                                      pilihantahun,
                                    );
                                  },
                                  child: Text(
                                    'Cetak Komisi Terapis',
                                    style: TextStyle(
                                      fontSize: 15.w,
                                      color: Colors.black,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFFFCEFCB),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Container(
                                margin: EdgeInsets.only(top: 0.w),
                                width: 175.w,
                                height: 35.w,
                                child: ElevatedButton(
                                  onPressed: () {
                                    exportkomisigrobulanan(
                                      pilihanbulan,
                                      pilihantahun,
                                    );
                                  },
                                  child: Text(
                                    'Cetak Komisi Gro',
                                    style: TextStyle(
                                      fontSize: 15.w,
                                      color: Colors.black,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFFFCEFCB),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                    : selectedtabindex == 0
                    ? Container(
                      margin: EdgeInsets.only(top: 50.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              final results = await showDialog(
                                context: context,
                                builder: (context) {
                                  List<DateTime?> tempdate = List.from(
                                    _rangedatepickervalue,
                                  );
                                  return Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: SingleChildScrollView(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 16.w,
                                          horizontal: 16.w,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              'Silahkan pilih rentang tanggal',
                                            ),
                                            SizedBox(height: 15.w),
                                            CalendarDatePicker2(
                                              config: CalendarDatePicker2Config(
                                                calendarType:
                                                    CalendarDatePicker2Type
                                                        .range,
                                                selectedDayHighlightColor:
                                                    Colors.deepPurple,
                                                dayTextStyle: TextStyle(
                                                  fontSize: 15.w,
                                                ),
                                              ),
                                              value: tempdate,
                                              onValueChanged: (dates) {
                                                tempdate =
                                                    dates
                                                        .map(
                                                          (d) =>
                                                              _getdateonly(d),
                                                        )
                                                        .toList();
                                              },
                                            ),
                                            SizedBox(height: 15.w),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                TextButton(
                                                  child: const Text('Cancel'),
                                                  onPressed:
                                                      () =>
                                                          Navigator.of(
                                                            context,
                                                          ).pop(),
                                                ),
                                                const SizedBox(width: 8),
                                                TextButton(
                                                  child: const Text('OK'),
                                                  onPressed:
                                                      () => Navigator.of(
                                                        context,
                                                      ).pop(tempdate),
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
                                          .map(
                                            (date) =>
                                                _getdateonly(date) as DateTime?,
                                          )
                                          .toList();

                                  _rangedatepickervalue.assignAll(
                                    cleanedResults,
                                  );

                                  startdate =
                                      _rangedatepickervalue[0]
                                          ?.toIso8601String()
                                          .split('T')
                                          .first ??
                                      '';
                                  enddate =
                                      _rangedatepickervalue.length > 1
                                          ? _rangedatepickervalue[1]
                                                  ?.toIso8601String()
                                                  .split('T')
                                                  .first ??
                                              ''
                                          : startdate;

                                  getdatakomisiharian(startdate, enddate);

                                  print(
                                    'ini adalah isi data harian $datakomisiharian',
                                  );
                                }
                              });
                            },
                            child: Text(
                              'Pilih Tanggal',
                              style: TextStyle(fontSize: 20.w),
                            ),
                          ),
                          SizedBox(width: 20),
                          Obx(
                            () => Container(
                              child: Text(
                                _rangedatepickervalue.isEmpty
                                    ? 'Pilihan tanggal : - '
                                    : 'Pilihan tanggal : ${startdate} - ${enddate}',
                                style: TextStyle(fontSize: 20.w),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    : Container(
                      margin: EdgeInsets.only(top: 50.w),
                      width: 1100.w,
                      height: 45.w,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: EdgeInsets.only(top: 0.w),
                            height: 50,
                            alignment: Alignment.topCenter,
                            child: Text(
                              'Tahun : ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                                height: 1,
                                fontSize: 20.w,
                              ),
                            ),
                          ),
                          Obx(
                            () => Container(
                              margin: EdgeInsets.only(top: 0.w),
                              width: 140.w,
                              height: 55.w,
                              child: DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.only(
                                    top: 0.w,
                                    bottom: 0.w,
                                    left: 10.w,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.blue,
                                      width: 2.w,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.red,
                                      width: 2.w,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                ),
                                value: selectedyearvalue.value,
                                style: TextStyle(
                                  fontSize: 15.w,
                                  color: Colors.black,
                                ),
                                items:
                                    List.generate(
                                      DateTime.now().year - 2000 + 1,
                                      (index) => 2000 + index,
                                    ).map((int year) {
                                      return DropdownMenuItem<String>(
                                        value: year.toString(),
                                        child: Text(year.toString()),
                                      );
                                    }).toList(),
                                onChanged: (String? newValue) {
                                  selectedyearvalue.value = newValue!;
                                  pilihantahun = int.parse(newValue);
                                  print(pilihantahun);
                                },
                              ),
                            ),
                          ),
                          SizedBox(width: 20),
                          Container(
                            margin: EdgeInsets.only(top: 0.w),
                            width: 160.w,
                            height: 35.w,
                            child: ElevatedButton(
                              onPressed: () {
                                getdatakomisitahunan(pilihantahun);
                                log(datakomisitahunan.toString());
                              },
                              child: Text(
                                'Cek Komisi',
                                style: TextStyle(
                                  fontSize: 20.w,
                                  color: Colors.black,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFFCEFCB),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                Center(
                  child: DefaultTabController(
                    length: 3,
                    child: Column(
                      children: [
                        Container(
                          margin: EdgeInsets.only(top: 30),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10),
                            ),
                          ),
                          width: Get.width - 200,
                          height: 50.w,
                          child: TabBar(
                            controller: _tabController,
                            tabs: [
                              Tab(text: 'Harian'),
                              Tab(text: 'Bulanan'),
                              Tab(text: 'Tahunan'),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                          ),
                          width: Get.width - 200,
                          height: 350.w,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // ini tab 1
                              datakomisiharian.isEmpty
                                  ? startdate == ''
                                      ? Center(
                                        child: Text(
                                          'Silahkan pilih tanggal terlebih dahulu',
                                        ),
                                      )
                                      : Center(
                                        child: Text(
                                          'Data komisi untuk tanggal $startdate sampai dengan $enddate tidak tersedia',
                                        ),
                                      )
                                  : ListView.builder(
                                    padding: EdgeInsets.only(top: 10),
                                    itemCount: datakomisiharian.length,
                                    itemBuilder: (context, index) {
                                      var item = datakomisiharian[index];
                                      return Container(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  margin: EdgeInsets.only(
                                                    left: 20,
                                                  ),
                                                  width: 60,
                                                  child: Text(
                                                    item['id_karyawan'],
                                                    textAlign: TextAlign.left,
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 5),
                                                Container(
                                                  child: Text(
                                                    '-',
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 15),
                                                Container(
                                                  width: 75,
                                                  child: Text(
                                                    item['nama_karyawan'],
                                                    textAlign: TextAlign.left,
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Container(
                                                    margin: EdgeInsets.only(
                                                      left: 20,
                                                      right: 10,
                                                    ),
                                                    width: 140,
                                                    child: Text(
                                                      formatnominal
                                                          .format(
                                                            item['total_komisi'],
                                                          )
                                                          .toString(),
                                                      textAlign:
                                                          TextAlign.right,
                                                      style: TextStyle(
                                                        fontSize: 20,
                                                        fontFamily: 'Poppins',
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Divider(color: Colors.black),
                                          ],
                                        ),
                                      );
                                    },
                                  ),

                              // ini tab 2
                              datakomisi.isEmpty
                                  ? Center(
                                    child: Text(
                                      'Data komisi untuk bulan $pilihanbulan di tahun $pilihantahun tidak tersedia',
                                    ),
                                  )
                                  : ListView.builder(
                                    padding: EdgeInsets.only(top: 10),
                                    itemCount: datakomisi.length,
                                    itemBuilder: (context, index) {
                                      var item = datakomisi[index];
                                      return Container(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  margin: EdgeInsets.only(
                                                    left: 20,
                                                  ),
                                                  width: 60,
                                                  child: Text(
                                                    item['id_karyawan'],
                                                    textAlign: TextAlign.left,
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 5),
                                                Container(
                                                  child: Text(
                                                    '-',
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 15),
                                                Container(
                                                  width: 75,
                                                  child: Text(
                                                    item['nama_karyawan'],
                                                    textAlign: TextAlign.left,
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Container(
                                                    margin: EdgeInsets.only(
                                                      left: 20,
                                                      right: 10,
                                                    ),
                                                    width: 140,
                                                    child: Text(
                                                      formatnominal
                                                          .format(
                                                            item['total_komisi'],
                                                          )
                                                          .toString(),
                                                      textAlign:
                                                          TextAlign.right,
                                                      style: TextStyle(
                                                        fontSize: 20,
                                                        fontFamily: 'Poppins',
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Divider(color: Colors.black),
                                          ],
                                        ),
                                      );
                                    },
                                  ),

                              // ini tab 3
                              datakomisitahunan.isEmpty
                                  ? Center(
                                    child: Text(
                                      'Data komisi untuk tahun $pilihantahun tidak tersedia',
                                    ),
                                  )
                                  : ListView.builder(
                                    padding: EdgeInsets.only(top: 10),
                                    itemCount: datakomisitahunan.length,
                                    itemBuilder: (context, index) {
                                      var item = datakomisitahunan[index];
                                      return Container(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  margin: EdgeInsets.only(
                                                    left: 20,
                                                  ),
                                                  width: 60,
                                                  child: Text(
                                                    item['id_karyawan'],
                                                    textAlign: TextAlign.left,
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 5),
                                                Container(
                                                  child: Text(
                                                    '-',
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 15),
                                                Container(
                                                  width: 75,
                                                  child: Text(
                                                    item['nama_karyawan'],
                                                    textAlign: TextAlign.left,
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Container(
                                                    margin: EdgeInsets.only(
                                                      left: 20,
                                                      right: 10,
                                                    ),
                                                    width: 140,
                                                    child: Text(
                                                      formatnominal
                                                          .format(
                                                            item['total_komisi'],
                                                          )
                                                          .toString(),
                                                      textAlign:
                                                          TextAlign.right,
                                                      style: TextStyle(
                                                        fontSize: 20,
                                                        fontFamily: 'Poppins',
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Divider(color: Colors.black),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
