// ignore_for_file: unnecessary_import, prefer_interpolation_to_compose_strings

import 'dart:async';
import 'dart:math' as math;
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Project_SPA/function/our_drawer.dart';
import 'dart:developer';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:Project_SPA/owner/owner_controller.dart';
import 'package:Project_SPA/owner/owner_charts.dart';
import 'package:Project_SPA/owner/owner_utils.dart';

// Ini Parentnya. Init getx Disini
class OwnerPage extends StatefulWidget {
  OwnerPage({super.key}) {
    Get.lazyPut(() => OwnerPageController(), fenix: false);
  }

  @override
  State<OwnerPage> createState() => _OwnerPageState();
}

class _OwnerPageState extends State<OwnerPage> {
  bool _isReady = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // Kunci Orientasi
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Delay UI building. biar g ancur pas login. minimal 500, klo 100 kecepatan
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isReady = true;
        });
      }
    });
  }

  @override
  void dispose() {
    // Reset Kembali
    Get.find<OwnerPageController>().refreshLineChart();
    super.dispose();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Color(0XFFFFE0B2),
      body: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isReady ? IsiOwnerPage() : _buildLoadingScreen();
  }
}

class IsiOwnerPage extends StatefulWidget {
  const IsiOwnerPage({super.key});

  @override
  State<IsiOwnerPage> createState() => _IsiOwnerPageState();
}

class _IsiOwnerPageState extends State<IsiOwnerPage> {
  final ScrollController _scrollControllerTarget = ScrollController();

  @override
  void dispose() {
    _scrollControllerTarget.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // DynamicPieChart(chartData: pieChartData)
    final c = Get.find<OwnerPageController>();

    // LOGIKA YANG DIPERBAIKI: Gunakan 'shortestSide' untuk deteksi tipe perangkat
    // Ini tidak akan terpengaruh oleh rotasi layar.
    final bool isMobile = MediaQuery.of(context).size.shortestSide < 600;
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
        isMobile ? tabletDesignWidth * mobileAdjustmentFactor : tabletDesignWidth;
    final double effectiveDesignHeight =
        isMobile ? tabletDesignHeight * mobileAdjustmentFactor : tabletDesignHeight;

    int currSalesMethod() {
      // ambil data sales bulan saat ini
      var currSales = c.monthlySalesRaw.firstWhere(
        (item) => item['bulan'] == DateFormat('yyyy-MM').format(DateTime.now()),
        orElse: () => {'omset_jual': 0},
      );

      return currSales['omset_jual'] ?? 0;
    }

    return ScreenUtilInit(
      designSize: Size(effectiveDesignWidth, effectiveDesignHeight),
      minTextAdapt: true,
      splitScreenMode: true,
      // Penting: Gunakan 'builder' untuk membangun UI Anda.
      // 'builder' memastikan context yang diteruskan ke Scaffold sudah "sadar" akan ScreenUtil.
      builder: (context, child) {
        // Scaffold dan seluruh isinya sekarang bisa menggunakan .w, .h, .sp
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 60.w,
            backgroundColor: Color(0XFFFFE0B2),
            title: Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 50),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.asset("assets/spa.jpg", height: 60.w),
                ),
              ),
            ),
          ),
          drawer: OurDrawer(),
          body: InteractiveViewer(
            // Optional: Customize initial scale, min/max scale
            minScale: 0.5,
            maxScale: 4.0,
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 30, left: 20, right: 20),
                color: Color(0XFFFFE0B2),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(left: 10, right: 10),
                            height: 20.w,
                            width: double.infinity,
                            child: Text(
                              "Dashboard",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                                height: 1,
                                fontSize: 12.w,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5.w),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(left: 10, right: 10),
                            padding: const EdgeInsets.only(left: 15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            // height: 90.w, // 90.w dari desain 660dp
                            width: double.infinity,
                            child: Obx(() {
                              // ambil bulan lalu
                              var prevSales = c.monthlySalesRaw.firstWhere(
                                (item) =>
                                    item['bulan'] ==
                                    DateFormat(
                                      'yyyy-MM',
                                    ).format(DateTime(DateTime.now().year, DateTime.now().month - 1)),
                                orElse: () => {'omset_jual': 0},
                              );

                              // kalkulasi valuenya
                              var currSalesValue = currSalesMethod();
                              var prevSalesValue = prevSales['omset_jual'] ?? 0;

                              // kalkulasi peningkatan persentase
                              double peningkatanPersen = 0.0;
                              if (prevSalesValue != 0) {
                                peningkatanPersen =
                                    ((currSalesValue - prevSalesValue) / prevSalesValue) * 100;
                              }

                              // format currency
                              final currencyFormat = NumberFormat.currency(
                                locale: 'id_ID',
                                symbol: 'Rp. ',
                                decimalDigits: 0,
                              );

                              final formattedSales = currencyFormat.format(currSalesValue);

                              String statusText;
                              if (peningkatanPersen > 0) {
                                statusText = "Meningkat Sebesar ${peningkatanPersen.toStringAsFixed(0)}%";
                              } else if (peningkatanPersen < 0) {
                                statusText =
                                    "Menurun Sebesar ${peningkatanPersen.abs().toStringAsFixed(0)}% dari bulan lalu";
                              } else {
                                statusText = "Tidak Ada Perubahan";
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 20),
                                  Text(
                                    "Current Total Monthly Sales",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11.w,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    formattedSales,
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 8.w),
                                  ),
                                  SizedBox(height: 10),
                                  AutoSizeText(
                                    statusText,
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 10.sp),
                                    // Force the text to stay on a single line.
                                    maxLines: 1,
                                    // Optional: Set a minimum font size to maintain readability.
                                    minFontSize: 8,
                                    // Optional: What to do if the text still overflows at its minimum size.
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 10),
                                ],
                              );
                            }),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(left: 10, right: 10),
                            padding: const EdgeInsets.only(left: 15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            // height: 90.w, // 90.w dari desain 660dp
                            width: double.infinity,
                            child: Obx(() {
                              // get current month data, asumsi data udh disortir berdasarkan bln
                              var currentPaketMonth = c.paketSalesRaw.firstWhere(
                                (item) => item['bulan'] == DateFormat('yyyy-MM').format(DateTime.now()),
                                orElse: () => {'omset_bulanan': 0.0},
                              );

                              // Ambil previous month
                              var previousPaketMonth = c.paketSalesRaw.firstWhere(
                                (item) =>
                                    item['bulan'] ==
                                    DateFormat(
                                      'yyyy-MM',
                                    ).format(DateTime(DateTime.now().year, DateTime.now().month - 1)),
                                orElse: () => {'omset_bulanan': 0.0},
                              );

                              // calculate values
                              var currentPaket = currentPaketMonth['omset_bulanan'] ?? 0.0;
                              var previousPaket = previousPaketMonth['omset_bulanan'] ?? 0.0;

                              // calculate peningkatan persentase (handle pembagian)
                              double peningkatanPersen = 0.0;
                              if (previousPaket != 0) {
                                peningkatanPersen = ((currentPaket - previousPaket) / previousPaket) * 100;
                              }

                              // format currency
                              final currencyFormat = NumberFormat.currency(
                                locale: 'id_ID',
                                symbol: 'Rp. ',
                                decimalDigits: 0,
                              );

                              final formattedSales = currencyFormat.format(currentPaket);

                              // tentukan status teks
                              String statusText;
                              if (peningkatanPersen > 0) {
                                statusText = "Meningkat Sebesar ${peningkatanPersen.toStringAsFixed(0)}%";
                              } else if (peningkatanPersen < 0) {
                                statusText =
                                    "Menurun Sebesar ${peningkatanPersen.abs().toStringAsFixed(0)}% dari bulan lalu";
                              } else {
                                statusText = "Tidak Ada Perubahan";
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 20),
                                  Text(
                                    "Current Paket Sales",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.w,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    formattedSales,
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 8.w),
                                  ),
                                  SizedBox(height: 10),
                                  AutoSizeText(
                                    statusText,
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 10.sp),
                                    // Force the text to stay on a single line.
                                    maxLines: 1,
                                    // Optional: Set a minimum font size to maintain readability.
                                    minFontSize: 8,
                                    // Optional: What to do if the text still overflows at its minimum size.
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 10),
                                ],
                              );
                            }),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(left: 10, right: 10),
                            padding: const EdgeInsets.only(left: 15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            // height: 90.w, // 90.w dari desain 660dp
                            width: double.infinity,
                            child: Obx(() {
                              // ambil data bulan saat ini
                              var currProdukMonth = c.produkSalesRaw.firstWhere(
                                (item) => item['bulan'] == DateFormat('yyyy-MM').format(DateTime.now()),
                                orElse: () => {'omset_bulanan': 0.0},
                              );

                              // ambil bulan lalu
                              var prevProdukMonth = c.produkSalesRaw.firstWhere(
                                (item) =>
                                    item['bulan'] ==
                                    DateFormat(
                                      'yyyy-MM',
                                    ).format(DateTime(DateTime.now().year, DateTime.now().month - 1)),
                                orElse: () => {'omset_bulanan': 0.0},
                              );

                              // kalkulasi valuenya
                              var currProdukValue = currProdukMonth['omset_bulanan'] ?? 0.0;
                              var prevProdukValue = prevProdukMonth['omset_bulanan'] ?? 0.0;

                              // kalkulasi peningkatan persentase
                              double peningkatanPersen = 0.0;
                              if (prevProdukValue != 0) {
                                peningkatanPersen =
                                    ((currProdukValue - prevProdukValue) / prevProdukValue) * 100;
                              }

                              // format currency
                              final currencyFormat = NumberFormat.currency(
                                locale: 'id_ID',
                                symbol: 'Rp. ',
                                decimalDigits: 0,
                              );

                              final formattedSales = currencyFormat.format(currProdukValue);

                              String statusText;
                              if (peningkatanPersen > 0) {
                                statusText = "Meningkat Sebesar ${peningkatanPersen.toStringAsFixed(0)}%";
                              } else if (peningkatanPersen < 0) {
                                statusText =
                                    "Menurun Sebesar ${peningkatanPersen.abs().toStringAsFixed(0)}% dari bulan lalu";
                              } else {
                                statusText = "Tidak Ada Perubahan";
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 20),
                                  Text(
                                    "Current Produk Sales",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.w,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    formattedSales,
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 8.w),
                                  ),
                                  SizedBox(height: 10),
                                  AutoSizeText(
                                    statusText,
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 10.sp),
                                    // Force the text to stay on a single line.
                                    maxLines: 1,
                                    // Optional: Set a minimum font size to maintain readability.
                                    minFontSize: 8,
                                    // Optional: What to do if the text still overflows at its minimum size.
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 10),
                                ],
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.w),

                    Obx(
                      () => Container(
                        margin: const EdgeInsets.only(left: 10, right: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        child:
                            c.isLoadingDataSalesHarian.value
                                ? Center(
                                  // Gunakan Center agar posisinya rapi
                                  child: Transform.scale(scale: 0.55, child: CircularProgressIndicator()),
                                )
                                : TotalSalesHarianChart(),
                      ),
                    ),
                    SizedBox(height: 12.w),

                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(left: 10, right: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.only(top: 20, bottom: 10),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 100),
                                        child: Obx(() {
                                          final dates = c.rangeDatePickerPenjualanTerapis;
                                          String suffix = 'Per-Hari ini';
                                          if (dates.isNotEmpty && dates[0] != null) {
                                            final fmt = DateFormat('dd-MM-yyyy');
                                            final start = dates[0]!;
                                            final end =
                                                (dates.length > 1 && dates[1] != null) ? dates[1]! : start;
                                            if (start == end) {
                                              suffix = fmt.format(start);
                                            } else {
                                              suffix = '${fmt.format(start)} - ${fmt.format(end)}';
                                            }
                                          }
                                          return Text(
                                            'Rank Omset Sales Per Terapis \n $suffix',
                                            style: TextStyle(
                                              fontSize: 11.w,
                                              fontWeight: FontWeight.bold,
                                              height: 1.2,
                                              fontFamily: 'Poppins',
                                            ),
                                            textAlign: TextAlign.center,
                                          );
                                        }),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(right: 15),
                                      child: SizedBox(
                                        height: 20.w, // samain dengan fontSize Text kiri
                                        width: 80.w,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            c.showDialogPenjualanPerTerapis();
                                          },
                                          child: Text("Filter"),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 8.w),
                                Obx(() {
                                  if (c.isLoadingPenjualanTerapis.value) {
                                    return const SizedBox(
                                      height: 260,
                                      child: Center(child: CircularProgressIndicator()),
                                    );
                                  }
                                  if (c.dataPenjualanTerapis.isEmpty) {
                                    return const SizedBox(
                                      height: 260,
                                      child: Center(child: Text('Tidak ada data')),
                                    );
                                  }
                                  return const PenjualanTerapisBarChart();
                                }),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 10.w),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(left: 10, right: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.only(top: 20, bottom: 10),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 100),
                                        child: Obx(() {
                                          final dates = c.rangeDatePickerKomisiTerapis;
                                          String suffix = 'Per-Hari ini';
                                          if (dates.isNotEmpty && dates[0] != null) {
                                            final fmt = DateFormat('dd-MM-yyyy');
                                            final start = dates[0]!;
                                            final end =
                                                (dates.length > 1 && dates[1] != null) ? dates[1]! : start;
                                            if (start == end) {
                                              suffix = fmt.format(start);
                                            } else {
                                              suffix = '${fmt.format(start)} - ${fmt.format(end)}';
                                            }
                                          }
                                          return Text(
                                            'Rank Komisi Terapis \n $suffix',
                                            style: TextStyle(
                                              fontSize: 11.w,
                                              fontWeight: FontWeight.bold,
                                              height: 1.2,
                                              fontFamily: 'Poppins',
                                            ),
                                            textAlign: TextAlign.center,
                                          );
                                        }),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(right: 15),
                                      child: SizedBox(
                                        height: 20.w, // samain dengan fontSize Text kiri
                                        width: 80.w,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            c.showDialogKomisiPerTerapis();
                                          },
                                          child: Text("Filter"),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 8.w),
                                Obx(() {
                                  if (c.isLoadingKomisiTerapis.value) {
                                    return const SizedBox(
                                      height: 260,
                                      child: Center(child: CircularProgressIndicator()),
                                    );
                                  }
                                  if (c.dataKomisiTerapis.isEmpty) {
                                    return const SizedBox(
                                      height: 260,
                                      child: Center(child: Text('Tidak ada data')),
                                    );
                                  }
                                  return const KomisiTerapisBarChart();
                                }),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 10.w),
                    Container(
                      margin: const EdgeInsets.only(left: 10, right: 10),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // header: title centered + button di kanan
                          SizedBox(height: 4),
                          Row(
                            children: [
                              // Centered title
                              SizedBox(width: 210),
                              Expanded(
                                child: Text(
                                  'Target Sales Bulanan',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11.w,
                                    fontWeight: FontWeight.w700,
                                    height: 1,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 25,
                                child: ElevatedButton(
                                  onPressed: () {
                                    c.showDialogTargetSales();
                                  },
                                  child: const Text('Filter'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 25,
                                child: ElevatedButton(
                                  onPressed: () {
                                    c.showDialogTargetSales(modeDialog: "upsert");
                                  },
                                  child: const Text('Edit Target Sales'),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Obx(() {
                            final list = c.dataTargetOmset; // RxList (dynamic)

                            if (list.isEmpty) return const Text('Tidak ada data');

                            return SizedBox(
                              height: c.dataOmset.length > 1 ? 170 : 140,
                              child: Scrollbar(
                                controller: _scrollControllerTarget,
                                thumbVisibility: true,
                                thickness: 4.0,
                                radius: Radius.circular(10),
                                child: ListView.builder(
                                  controller: _scrollControllerTarget,
                                  itemCount: math.min(
                                    c.dataTargetOmset.length,
                                    math.min(c.dataOmset.length, c.dataOmsetBerjalan.length),
                                  ),
                                  itemBuilder: (context, index) {
                                    var item = c.dataTargetOmset[index];
                                    var itemOmset = c.dataOmset[index];
                                    var itemOmsetBerjalan = c.dataOmsetBerjalan[index];
                                    double persentase = (itemOmset['omset'] / item['target_omset']) * 100;

                                    DateTime now = DateTime.now();
                                    int totalHari = DateTime(item['year'], item['month_number'] + 1, 0).day;

                                    int hariBerjalan = 0;

                                    if (item['month_number'] == now.month && item['year'] == now.year) {
                                      hariBerjalan = now.day;
                                    } else if (item['month_number'] < now.month && item['year'] == now.year) {
                                      hariBerjalan = totalHari;
                                    }

                                    double targetBulanan = double.tryParse("${item['target_omset']}") ?? 0.0;

                                    double targetHarianKumulatif =
                                        totalHari == 0 ? 0 : (targetBulanan / totalHari) * hariBerjalan;

                                    // 🔥 PAKAI OMSET BERJALAN DI SINI
                                    double omsetBerjalan =
                                        double.tryParse("${itemOmsetBerjalan['omset_berjalan']}") ?? 0.0;

                                    double persentaseHarian =
                                        targetHarianKumulatif == 0
                                            ? 0
                                            : (omsetBerjalan / targetHarianKumulatif) * 100;
                                    return Container(
                                      padding: const EdgeInsets.only(right: 10),
                                      child: Column(
                                        children: [
                                          // baris info singkat (opsional, boleh kamu isi dinamis)
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Omset Bulan ${item['month_name']} - ${item['year']}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                formatRupiah(double.tryParse("${itemOmset['omset']}") ?? 0.0),
                                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Target bulan ${item['month_name']} - ${item['year']}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                formatRupiah(
                                                  double.tryParse("${item['target_omset']}") ?? 0.0,
                                                ),
                                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),

                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Persentase Capaian Target ',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                persentase.isInfinite
                                                    ? "-"
                                                    : "${persentase.toStringAsFixed(2)}%",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      persentase.isInfinite
                                                          ? Colors.black
                                                          : persentase >= 100
                                                          ? Colors.green
                                                          : Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Target Harian s/d tanggal ${hariBerjalan}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                formatRupiah(targetHarianKumulatif),
                                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),

                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Persentase Target Harian',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                targetHarianKumulatif == 0
                                                    ? "-"
                                                    : "${persentaseHarian.toStringAsFixed(2)}%",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      persentaseHarian.isInfinite
                                                          ? Colors.black
                                                          : persentaseHarian >= 100
                                                          ? Colors.green
                                                          : Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 10),
                                          const Divider(),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          }),

                          // const Spacer(),

                          // // garis tipis biar rapi (opsional)
                          // const Divider(height: 1),

                          // const SizedBox(height: 8),

                          // // baris info singkat (opsional, boleh kamu isi dinamis)
                          // Row(
                          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          //   children: [
                          //     Text(
                          //       'Omset Bulan Ini (${c.monthNames["${DateTime.now().month}".padLeft(2, "0")]} - ${DateTime.now().year})',
                          //       style: TextStyle(
                          //         fontSize: 14,
                          //         color: Colors.black,
                          //         fontWeight: FontWeight.bold,
                          //       ),
                          //     ),
                          //     Obx(
                          //       () => Text(
                          //         formatRupiah(double.tryParse("${currSalesMethod()}") ?? 0.0),
                          //         style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          //       ),
                          //     ),
                          //   ],
                          // ),
                          // Row(
                          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          //   children: [
                          //     Text(
                          //       'Target bulan ini (${c.monthNames["${DateTime.now().month}".padLeft(2, "0")]} - ${DateTime.now().year})',
                          //       style: TextStyle(
                          //         fontSize: 14,
                          //         color: Colors.black,
                          //         fontWeight: FontWeight.bold,
                          //       ),
                          //     ),
                          //     Obx(
                          //       () => Text(
                          //         formatRupiah(double.tryParse("${c.targetOmsetBulanIni.value}") ?? 0.0),
                          //         style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          //       ),
                          //     ),
                          //   ],
                          // ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.w),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Container(
                            margin: const EdgeInsets.only(left: 10, right: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            width: double.infinity,
                            child: Column(
                              children: [
                                SizedBox(height: 10.w),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 100),
                                        child: Text(
                                          'Pendapatan Bulanan',
                                          style: TextStyle(
                                            fontSize: 11.w,
                                            fontWeight: FontWeight.bold,
                                            height: 1,
                                            fontFamily: 'Poppins',
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(right: 15),
                                      child: SizedBox(
                                        height: 20.w, // samain dengan fontSize Text kiri
                                        width: 80.w,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            c.showFilterLineChart();
                                          },
                                          child: Text("Filter"),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Container(
                                            height: 10,
                                            width: 10,
                                            margin: const EdgeInsets.only(right: 10),
                                            decoration: BoxDecoration(
                                              color: Colors.amber,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          Text("Target Sales", style: TextStyle(fontSize: 12)),
                                          const SizedBox(width: 30),

                                          Container(
                                            height: 10,
                                            width: 10,
                                            margin: const EdgeInsets.only(right: 10),
                                            decoration: BoxDecoration(
                                              color: Colors.blue,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          Text("Omset Sales", style: TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                Obx(() {
                                  if (c.monthlyData.isEmpty) {
                                    return CircularProgressIndicator();
                                  }

                                  return SizedBox(
                                    height: 250.w,
                                    width: double.infinity,
                                    child: MonthlyRevenueChart(
                                      salesData: c.monthlyData,
                                      targetSalesData: c.monthlyDataTarget,
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 10.w),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Container(
                            margin: const EdgeInsets.only(left: 10, right: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.only(top: 20),
                            height: 300.w,
                            child: InteractiveViewer(
                              minScale: 0.5,
                              maxScale: 4.0,
                              child: Column(
                                children: [
                                  Text(
                                    "Top 4 Paket Terlaris (Dalam %)",
                                    style: TextStyle(
                                      fontSize: 12.w,
                                      fontFamily: 'Poppins',
                                      height: 1,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 0.8.w),
                                  Obx(() {
                                    if (c.pieChartData.isEmpty) {
                                      return CircularProgressIndicator();
                                    }
                                    return Expanded(child: BarChartTop4Paket(chartData: c.pieChartData));
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20.w),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    // return
  }
}
