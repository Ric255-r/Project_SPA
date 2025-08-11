// ignore_for_file: unnecessary_import, prefer_interpolation_to_compose_strings

import 'dart:async';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/services.dart';
import 'package:Project_SPA/owner/download_splash.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:Project_SPA/function/ip_address.dart';
import 'package:Project_SPA/function/our_drawer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dio/dio.dart';
import 'dart:developer';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Model data utk Chart
class ChartData {
  final Color color; // warna piechart
  final double value; // nilai persentase
  final String label; // labek kategori, misal makanan
  final IconData? icon; // icon opsional

  ChartData({required this.color, required this.value, required this.label, this.icon});
}

// LineChart
class MonthlySales {
  final String month; // Nama bulan (Jan, Feb, dst)
  final double revenue; // Pendapatan bulanan

  MonthlySales(this.month, this.revenue);
}

class OwnerPageController extends GetxController {
  // Data COntoh buat piechart
  // final List<ChartData> pieChartData = [
  //   ChartData(color: Colors.blue, value: 35, label: 'Food', icon: Icons.fastfood),
  //   ChartData(color: Colors.green, value: 25, label: 'Transport', icon: Icons.directions_car),
  //   ChartData(color: Colors.orange, value: 20, label: 'Entertainment', icon: Icons.movie),
  //   ChartData(color: Colors.red, value: 20, label: 'Bills', icon: Icons.receipt),
  // ];

  // List<MonthlySales> monthlyData = [
  //   MonthlySales("Jan", 1000),
  //   MonthlySales("Feb", 3000),
  // ];

  // Data Contoh Buat Revenue LineChart
  RxList<MonthlySales> monthlyData = <MonthlySales>[].obs;
  RxList<ChartData> pieChartData = <ChartData>[].obs;

  var dio = Dio();

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    _getData();
  }

  final monthNames = {
    "01": "Jan",
    "02": "Feb",
    "03": "Mar",
    "04": "Apr",
    "05": "Mei",
    "06": "Jun",
    "07": "Jul",
    "08": "Aug",
    "09": "Sep",
    "10": "Okt",
    "11": "Nov",
    "12": "Des",
  };

  RxList<dynamic> _listLineChart = [].obs;
  RxList<dynamic> _monthlySales = [].obs;
  RxList<dynamic> _paketSales = [].obs;
  RxList<dynamic> _produkSales = [].obs;
  RxList<dynamic> _paketTerlaris = [].obs;

  Future<void> _getData() async {
    try {
      var response = await dio.get('${myIpAddr()}/main_owner/get_laporan');

      Map<String, dynamic> responseData = response.data;
      List<dynamic> lineChart = responseData['for_line_chart'];
      List<dynamic> paketTerlaris = responseData['paket_terlaris'];

      log("isi responseData $responseData");

      _listLineChart.assignAll(lineChart);
      _monthlySales.assignAll(responseData['monthly_sales']);
      _paketSales.assignAll(responseData['sum_paket']);
      _produkSales.assignAll(responseData['sum_produk']);
      _paketTerlaris.assignAll(paketTerlaris);

      monthlyData.clear();
      for (var i = 0; i < lineChart.length; i++) {
        String bulan = (lineChart[i]['bulan'] as String).split("-")[1];
        monthlyData.add(MonthlySales((monthNames[bulan] as String), (lineChart[i]['omset_jual'] as num).toDouble()));
      }

      pieChartData.clear();
      if (paketTerlaris.isNotEmpty) {
        // Calculate total sold for percentage calculation
        double totalSold = paketTerlaris.fold(0, (sum, item) => sum + (item['jumlah_terjual'] as num).toDouble());

        // Define a fixed color palette for up to 4 items
        final List<Color> colorPalette = [Colors.blue, Colors.green, Colors.orange, Colors.red];

        for (var i = 0; i < paketTerlaris.length; i++) {
          // Use modulo to cycle through colors if more than 4 items
          final color = colorPalette[i % colorPalette.length];

          double percentage = (paketTerlaris[i]['jumlah_terjual'] / totalSold) * 100;

          pieChartData.add(
            ChartData(
              color: color,
              value: percentage,
              label: paketTerlaris[i]['label'],
              icon: Icons.spa, // Optional: Add icons
            ),
          );
        }
      }
    } catch (e) {
      if (e is DioException) {
        log("Errr di ${e.response!.data}");
      }
    }
  }

  @override
  void onClose() {
    // TODO: implement onClose
    _monthlySales.close();
    _paketSales.close();
    _produkSales.close();

    super.onClose();
  }
}

class OwnerPage extends StatefulWidget {
  const OwnerPage({super.key});

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
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);

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
    super.dispose();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(backgroundColor: Color(0XFFFFE0B2), body: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white))));
  }

  @override
  Widget build(BuildContext context) {
    return _isReady ? IsiOwnerPage() : _buildLoadingScreen();
  }
}

class IsiOwnerPage extends StatelessWidget {
  IsiOwnerPage({super.key}) {
    Get.lazyPut(() => OwnerPageController(), fenix: false);
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
    final double effectiveDesignWidth = isMobile ? tabletDesignWidth * mobileAdjustmentFactor : tabletDesignWidth;
    final double effectiveDesignHeight = isMobile ? tabletDesignHeight * mobileAdjustmentFactor : tabletDesignHeight;

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
                child: ClipRRect(borderRadius: BorderRadius.circular(50), child: Image.asset("assets/spa.jpg", height: 60.w)),
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
                height: MediaQuery.of(context).size.height + 360.w,
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
                            child: Text("Dashboard", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', height: 1, fontSize: 12.w)),
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
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                            // height: 90.w, // 90.w dari desain 660dp
                            width: double.infinity,
                            child: Obx(() {
                              // ambil data bulan saat ini
                              var currSales = c._monthlySales.firstWhere(
                                (item) => item['bulan'] == DateFormat('yyyy-MM').format(DateTime.now()),
                                orElse: () => {'omset_jual': 0.0},
                              );

                              // ambil bulan lalu
                              var prevSales = c._monthlySales.firstWhere(
                                (item) => item['bulan'] == DateFormat('yyyy-MM').format(DateTime(DateTime.now().year, DateTime.now().month - 1)),
                                orElse: () => {'omset_jual': 0.0},
                              );

                              // kalkulasi valuenya
                              var currSalesValue = currSales['omset_jual'] ?? 0.0;
                              var prevSalesValue = prevSales['omset_jual'] ?? 0.0;

                              // kalkulasi peningkatan persentase
                              double peningkatanPersen = 0.0;
                              if (prevSalesValue != 0) {
                                peningkatanPersen = ((currSalesValue - prevSalesValue) / prevSalesValue) * 100;
                              }

                              // format currency
                              final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp. ', decimalDigits: 0);

                              final formattedSales = currencyFormat.format(currSalesValue);

                              String statusText;
                              if (peningkatanPersen > 0) {
                                statusText = "Meningkat Sebesar ${peningkatanPersen.toStringAsFixed(0)}%";
                              } else if (peningkatanPersen < 0) {
                                statusText = "Menurun Sebesar ${peningkatanPersen.abs().toStringAsFixed(0)}% dari bulan lalu";
                              } else {
                                statusText = "Tidak Ada Perubahan";
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 20),
                                  Text("Current Monthly Sales", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 12.w)),
                                  SizedBox(height: 10),
                                  Text(formattedSales, style: TextStyle(fontFamily: 'Poppins', fontSize: 8.w)),
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
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                            // height: 90.w, // 90.w dari desain 660dp
                            width: double.infinity,
                            child: Obx(() {
                              // get current month data, asumsi data udh disortir berdasarkan bln
                              var currentPaketMonth = c._paketSales.firstWhere(
                                (item) => item['bulan'] == DateFormat('yyyy-MM').format(DateTime.now()),
                                orElse: () => {'omset_bulanan': 0.0},
                              );

                              // Ambil previous month
                              var previousPaketMonth = c._paketSales.firstWhere(
                                (item) => item['bulan'] == DateFormat('yyyy-MM').format(DateTime(DateTime.now().year, DateTime.now().month - 1)),
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
                              final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp. ', decimalDigits: 0);

                              final formattedSales = currencyFormat.format(currentPaket);

                              // tentukan status teks
                              String statusText;
                              if (peningkatanPersen > 0) {
                                statusText = "Meningkat Sebesar ${peningkatanPersen.toStringAsFixed(0)}%";
                              } else if (peningkatanPersen < 0) {
                                statusText = "Menurun Sebesar ${peningkatanPersen.abs().toStringAsFixed(0)}% dari bulan lalu";
                              } else {
                                statusText = "Tidak Ada Perubahan";
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 20),
                                  Text("Current Paket Sales", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 12.w)),
                                  SizedBox(height: 10),
                                  Text(formattedSales, style: TextStyle(fontFamily: 'Poppins', fontSize: 8.w)),
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
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                            // height: 90.w, // 90.w dari desain 660dp
                            width: double.infinity,
                            child: Obx(() {
                              // ambil data bulan saat ini
                              var currProdukMonth = c._produkSales.firstWhere(
                                (item) => item['bulan'] == DateFormat('yyyy-MM').format(DateTime.now()),
                                orElse: () => {'omset_bulanan': 0.0},
                              );

                              // ambil bulan lalu
                              var prevProdukMonth = c._produkSales.firstWhere(
                                (item) => item['bulan'] == DateFormat('yyyy-MM').format(DateTime(DateTime.now().year, DateTime.now().month - 1)),
                                orElse: () => {'omset_bulanan': 0.0},
                              );

                              // kalkulasi valuenya
                              var currProdukValue = currProdukMonth['omset_bulanan'] ?? 0.0;
                              var prevProdukValue = prevProdukMonth['omset_bulanan'] ?? 0.0;

                              // kalkulasi peningkatan persentase
                              double peningkatanPersen = 0.0;
                              if (prevProdukValue != 0) {
                                peningkatanPersen = ((currProdukValue - prevProdukValue) / prevProdukValue) * 100;
                              }

                              // format currency
                              final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp. ', decimalDigits: 0);

                              final formattedSales = currencyFormat.format(currProdukValue);

                              String statusText;
                              if (peningkatanPersen > 0) {
                                statusText = "Meningkat Sebesar ${peningkatanPersen.toStringAsFixed(0)}%";
                              } else if (peningkatanPersen < 0) {
                                statusText = "Menurun Sebesar ${peningkatanPersen.abs().toStringAsFixed(0)}% dari bulan lalu";
                              } else {
                                statusText = "Tidak Ada Perubahan";
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 20),
                                  Text("Current Produk Sales", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 12.w)),
                                  SizedBox(height: 10),
                                  Text(formattedSales, style: TextStyle(fontFamily: 'Poppins', fontSize: 8.w)),
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
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Container(
                            margin: const EdgeInsets.only(left: 10, right: 10),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                            height: isMobile ? 280.w : 300.w,
                            width: double.infinity,
                            child: Column(
                              children: [
                                SizedBox(height: 10.w),
                                Text('Pendapatan Bulanan (dalam ribuan)', style: TextStyle(fontSize: 12.w, fontWeight: FontWeight.bold, height: 1)),
                                Obx(() {
                                  if (c.monthlyData.isEmpty) {
                                    return CircularProgressIndicator();
                                  }

                                  return SizedBox(height: 250.w, width: double.infinity, child: MonthlyRevenueChart(salesData: c.monthlyData));
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
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.only(top: 20),
                            height: 300.w,
                            child: InteractiveViewer(
                              minScale: 0.5,
                              maxScale: 4.0,
                              child: Column(
                                children: [
                                  Text("Paket Terlaris", style: TextStyle(fontSize: 12.w, fontFamily: 'Poppins', height: 1, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 0.8.w),
                                  Obx(() {
                                    if (c.pieChartData.isEmpty) {
                                      return CircularProgressIndicator();
                                    }
                                    return Expanded(child: DynamicPieChart(chartData: c.pieChartData));
                                  }),
                                ],
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
          ),
        );
      },
    );

    // return
  }
}

class MonthlyRevenueChart extends StatelessWidget {
  final List<MonthlySales> salesData;

  List<double> targetSales = [
    1000000.0,
    1000000.0,
    1000000.0,
    1000000.0,
    1000000.0,
    1000000.0,
    1000000.0,
    1000000.0,
    8000000.0,
    80000000.0,
    1000000.0,
    1000000.0,
  ];

  MonthlyRevenueChart({super.key, required this.salesData});

  String formatRupiah(double amount) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return formatter.format(amount);
  }

  String formatRupiahShort(double amount) {
    if (amount >= 1000000) {
      return 'Rp${(amount / 1000000).toStringAsFixed(1)}Jt';
    } else if (amount >= 10000) {
      return 'Rp${(amount / 10000).toStringAsFixed(1)}Rb';
    } else {
      return formatRupiah(amount);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (salesData.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final minRevenueActual = salesData.map((e) => e.revenue).reduce((a, b) => a < b ? a : b);
    final maxRevenueActual = salesData.map((e) => e.revenue).reduce((a, b) => a > b ? a : b);

    final minTarget = targetSales.isEmpty ? minRevenueActual : targetSales.reduce((a, b) => a < b ? a : b);
    final maxTarget = targetSales.isEmpty ? maxRevenueActual : targetSales.reduce((a, b) => a > b ? a : b);

    final minAll = minRevenueActual < minTarget ? minRevenueActual : minTarget;
    final maxAll = maxRevenueActual > maxTarget ? maxRevenueActual : maxTarget;

    final yInterval = _calculateYInterval(minAll, maxAll);

    final minY = (minAll * 0.9).floorToDouble();
    final maxY = maxAll * 1.3;

    return AspectRatio(
      aspectRatio: 1.7,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LineChart(
          LineChartData(
            lineTouchData: LineTouchData(
              // Buat Tap LineChartnya
              touchTooltipData: LineTouchTooltipData(
                // tooltipBgColor: Colors.black87,
                tooltipRoundedRadius: 8,
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                getTooltipItems: (List<LineBarSpot> touchedSpots) {
                  // return touchedSpots.map((spot) {
                  //   final revenue = spot.y;
                  //   final formatted = formatRupiah(revenue);
                  //   return LineTooltipItem(formatted, const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold));
                  // }).toList();

                  return touchedSpots.map((spot) {
                    final isActual = spot.barIndex == 0; // 0: Actual, 1: Target
                    final label = isActual ? 'Actual Sales' : 'Target Sales';
                    final formatted = formatRupiah(spot.y);

                    // (Opsional) tampilkan juga nama bulan dari sumbu X:
                    String? month;
                    final x = spot.x.toInt();
                    if (x >= 0 && x < salesData.length) {
                      month = salesData[x].month;
                    }

                    final text = month != null ? '$label\n$month: $formatted' : '$label: $formatted';

                    return LineTooltipItem(text, TextStyle(color: isActual ? Colors.white : Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold));
                  }).toList();
                },
              ),
            ),
            gridData: FlGridData(show: true),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= salesData.length) return const Text('');

                    return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(salesData[value.toInt()].month, style: const TextStyle(fontSize: 10)));
                  },
                  reservedSize: 30,
                  interval: 1,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: Text(formatRupiahShort(value), style: const TextStyle(fontSize: 8, overflow: TextOverflow.visible), maxLines: 2),
                    );
                  },
                  reservedSize: 60, // Increased for better spacing
                  interval: yInterval,
                ),
              ),
            ),
            borderData: FlBorderData(show: true),
            minX: 0,
            maxX: salesData.length.toDouble() - 1,
            minY: minY,
            maxY: maxY,
            // minY: (minRevenue * 0.9).floorToDouble(),
            // maxY: maxRevenue * 1.3,
            lineBarsData: [
              LineChartBarData(
                spots:
                    salesData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.revenue);
                    }).toList(),
                isCurved: false,
                color: Colors.blue,
                barWidth: 3,
                belowBarData: BarAreaData(show: false),
                dotData: FlDotData(show: true),
              ),
              // Garis Target Sales
              LineChartBarData(
                spots:
                    targetSales.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value);
                    }).toList(),
                isCurved: false,
                color: Colors.red,
                barWidth: 2,
                dashArray: [8, 4], // biar putus-putus, bisa dihapus kalau mau solid
                belowBarData: BarAreaData(show: false),
                dotData: FlDotData(show: true), // kalau target gak perlu titik
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateYInterval(double minValue, double maxValue) {
    final range = maxValue - minValue;

    print(range);

    if (range <= 1000000) return 200000; // Rp 200K interval
    if (range <= 5000000) return 500000; // Rp 500K interval
    if (range <= 20000000) return 2000000; // Rp 2M interval
    if (range <= 100000000) return 25000000; // Rp 20m Interval
    return 100000000; // Rp 100Jt interval for larger values
  }
}

class DynamicPieChart extends StatefulWidget {
  // parameter. diambil dari list pieChartData di OwnerPageState
  final List<ChartData> chartData;

  const DynamicPieChart({Key? key, required this.chartData}) : super(key: key);

  @override
  _DynamicPieChartState createState() => _DynamicPieChartState();
}

class _DynamicPieChartState extends State<DynamicPieChart> {
  RxInt touchedIndex = RxInt(-1);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(4.0, 4.0, 4.0, 40.w),
          child: Container(
            margin: EdgeInsets.only(top: 40.w),
            width: 100.w,
            height: 100.w,
            child: Transform.scale(
              scale: 0.8.w,
              child: Obx(
                () => PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                          touchedIndex.value = -1;
                          return;
                        }
                        touchedIndex.value = pieTouchResponse.touchedSection!.touchedSectionIndex;
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: showingSection(),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Custom Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: List.generate(widget.chartData.length, (i) {
            final data = widget.chartData[i];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 16, height: 16, decoration: BoxDecoration(color: data.color, shape: BoxShape.circle)),
                SizedBox(width: 8),
                Text('${data.label} (${data.value.toStringAsFixed(1)}%)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black)),
              ],
            );
          }),
        ),
      ],
    );
  }

  List<PieChartSectionData> showingSection() {
    final itemCount = widget.chartData.length;
    if (itemCount == 0) {
      return [PieChartSectionData(color: Colors.grey, value: 100, title: '', radius: 50)];
    }
    final total = widget.chartData.fold<double>(0, (sum, item) => sum + item.value);
    return List.generate(itemCount, (i) {
      final isTouched = i == touchedIndex.value;
      final data = widget.chartData[i];
      final fontSize = isTouched ? 24.0.w : 20.0.w;
      final radius = isTouched ? 60.0 : 50.0;
      final percent = total > 0 ? (data.value / total * 100) : 0;
      if (itemCount == 1) {
        return PieChartSectionData(
          color: data.color,
          value: 100,
          title: '${percent.toStringAsFixed(1)}%',
          radius: radius,
          titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.black),
          badgeWidget: null,
        );
      }
      return PieChartSectionData(
        color: data.color,
        value: data.value,
        title: '${percent.toStringAsFixed(1)}%',

        radius: radius,
        titleStyle: TextStyle(fontSize: fontSize.w - 7.w, fontWeight: FontWeight.bold, color: Colors.black, height: 1.2),
        badgeWidget: null,
        badgePositionPercentageOffset: 1.1,
      );
    });
  }
}
