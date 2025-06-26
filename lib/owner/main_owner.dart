// ignore_for_file: unnecessary_import

import 'dart:async';
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

  Future<void> downloadExcel() async {
    Get.dialog(
      const DownloadSplash(),
      barrierDismissible: false, // Prevent user from dismissing by tapping outside
    );
    try {
      // final dir = await getApplicationDocumentsDirectory();
      final dir = await getDownloadsDirectory();
      final filePath = '${dir?.path}/datapenjualan_platinum.xlsx';

      await dio.download(
        '${myIpAddr()}/main_owner/export_excel',
        filePath,
        options: Options(responseType: ResponseType.bytes, headers: {'Accept': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'}),
      );

      // Close the loading dialog
      Get.back();

      // open downloaded file
      await OpenFile.open(filePath);
      print('File downloaded to: $filePath');
    } catch (e) {
      // Close the loading dialog
      Get.back();
      print('Error downloading file: $e');
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
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // Kunci Orientasi
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  }

  @override
  Widget build(BuildContext context) {
    return IsiOwnerPage();
  }
}

class IsiOwnerPage extends StatelessWidget {
  IsiOwnerPage({super.key}) {
    Get.put(OwnerPageController());
  }

  @override
  Widget build(BuildContext context) {
    // DynamicPieChart(chartData: pieChartData)
    final c = Get.find<OwnerPageController>();

    final mediaQueryData = MediaQuery.of(context);
    final double actualScreenWidth = mediaQueryData.size.width;
    // Screenwidth UI Kita
    final double referenceScreenWidth = 650.0;

    // calculate scale factor untuk ngefit ke screenwidth 650dp
    // jadi anggapannya nanti tu dia bkl ngescale app ini ke 650dp,
    //ga usah repot2 main screenwidth di developer mode
    final double scale = actualScreenWidth / referenceScreenWidth;

    return Transform.scale(
      scale: scale / 1.5,
      alignment: Alignment.center,
      child: SizedBox(
        width: referenceScreenWidth,
        height: mediaQueryData.size.height / scale,
        child: Scaffold(
          appBar: AppBar(
            toolbarHeight: 100,
            backgroundColor: Color(0XFFFFE0B2),
            title: Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 50),
                child: ClipRRect(borderRadius: BorderRadius.circular(50), child: Image.asset("assets/spa.jpg", height: 100)),
              ),
            ),
          ),
          drawer: OurDrawer(),
          body: SingleChildScrollView(
            child: Container(
              width: Get.width,
              padding: const EdgeInsets.only(top: 30, left: 20, right: 20),
              color: Color(0XFFFFE0B2),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(left: 10, right: 10),
                          height: 40,
                          width: double.infinity,
                          child: Text("Dashboard", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', height: 1, fontSize: 30)),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          alignment: Alignment.centerRight,
                          margin: const EdgeInsets.only(left: 10, right: 10),
                          height: 40,
                          width: double.infinity,
                          child: InkWell(
                            onTap: c.downloadExcel,
                            child: Text("Cetak Laporan", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', height: 1, fontSize: 20)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(left: 10, right: 10),
                          padding: const EdgeInsets.only(left: 15),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                          height: 150,
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
                                Text("Current Monthly Sales", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 18)),
                                SizedBox(height: 10),
                                Text(formattedSales, style: TextStyle(fontFamily: 'Poppins')),
                                SizedBox(height: 10),
                                Text(statusText, style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
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
                          height: 150,
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
                                Text("Current Paket Sales", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 18)),
                                SizedBox(height: 10),
                                Text(formattedSales, style: TextStyle(fontFamily: 'Poppins')),
                                SizedBox(height: 10),
                                Text(statusText, style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
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
                          height: 150,
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
                                Text("Current Produk Sales", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 18)),
                                SizedBox(height: 10),
                                Text(formattedSales, style: TextStyle(fontFamily: 'Poppins')),
                                SizedBox(height: 10),
                                Text(statusText, style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                              ],
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          margin: const EdgeInsets.only(left: 10, right: 10),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                          height: 280,
                          width: double.infinity,
                          child: Column(
                            children: [
                              const SizedBox(height: 10),
                              const Text('Pendapatan Bulanan (dalam ribuan)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1)),
                              Obx(() {
                                if (c.monthlyData.isEmpty) {
                                  return CircularProgressIndicator();
                                }

                                return SizedBox(height: 250, width: double.infinity, child: MonthlyRevenueChart(salesData: c.monthlyData));
                              }),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(
                          margin: const EdgeInsets.only(left: 10, right: 10),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.only(top: 20),
                          height: 280,
                          width: double.infinity,
                          child: Column(
                            children: [
                              Text("Paket Terlaris", style: TextStyle(fontSize: 20, fontFamily: 'Poppins', height: 1, fontWeight: FontWeight.bold)),
                              SizedBox(height: 30),
                              Obx(() {
                                if (c.pieChartData.isEmpty) {
                                  return CircularProgressIndicator();
                                }

                                return DynamicPieChart(chartData: c.pieChartData);
                              }),
                            ],
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
      ),
    );

    // return
  }
}

class MonthlyRevenueChart extends StatelessWidget {
  final List<MonthlySales> salesData;
  const MonthlyRevenueChart({super.key, required this.salesData});

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

    final minRevenue = salesData.map((e) => e.revenue).reduce((a, b) => a < b ? a : b);
    final maxRevenue = salesData.map((e) => e.revenue).reduce((a, b) => a > b ? a : b);

    final yInterval = _calculateYInterval(minRevenue, maxRevenue);

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
                  return touchedSpots.map((spot) {
                    final revenue = spot.y;
                    final formatted = formatRupiah(revenue);
                    return LineTooltipItem(formatted, const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold));
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
                  reservedSize: 50, // Increased for better spacing
                  interval: yInterval,
                ),
              ),
            ),
            borderData: FlBorderData(show: true),
            minX: 0,
            maxX: salesData.length.toDouble() - 1,
            minY: (minRevenue * 0.9).floorToDouble(),
            maxY: maxRevenue * 1.3,
            lineBarsData: [
              LineChartBarData(
                spots:
                    salesData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.revenue);
                    }).toList(),
                isCurved: true,
                color: Colors.blue,
                barWidth: 3,
                belowBarData: BarAreaData(show: false),
                dotData: FlDotData(show: true),
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
  // index piechart yg sedang d sentuh (getX). default valuenya -1;
  RxInt touchedIndex = RxInt(-1);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2, // rasio aspek 2:2
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        // pake obx utk update reactive
        child: Obx(
          () => PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  // handler klo piechart disentuh
                  if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                    touchedIndex.value = -1; // reset klo g ad sentuh
                    return;
                  }

                  // simpan index yg disentuh
                  touchedIndex.value = pieTouchResponse.touchedSection!.touchedSectionIndex;
                },
              ),
              borderData: FlBorderData(show: false), //sembunyikan border
              sectionsSpace: 2, // jarak antar bagian
              centerSpaceRadius: 40, // bulat tengah. 0 utk pie penuh
              sections: showingSection(), // bagan chart
            ),
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> showingSection() {
    final itemCount = widget.chartData.length;

    if (itemCount == 0) {
      return [PieChartSectionData(color: Colors.grey, value: 100, title: 'No Data', radius: 50)];
    }

    return List.generate(itemCount, (i) {
      final isTouched = i == touchedIndex.value;
      final data = widget.chartData[i];
      final fontSize = isTouched ? 18.0 : 14.0;
      final radius = isTouched ? 60.0 : 50.0;

      // Special handling for single item
      if (itemCount == 1) {
        return PieChartSectionData(
          color: data.color,
          value: 100, // Force 100% for single item
          title: '${data.label}\n(All Sales)',
          radius: radius,
          titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.black),
          badgeWidget: data.icon != null ? Icon(data.icon, size: isTouched ? 28 : 22) : null,
        );
      }

      // Handling for 2-4 items
      return PieChartSectionData(
        color: data.color,
        value: data.value,
        title: itemCount <= 4 ? '${data.label}\n${data.value.toStringAsFixed(0)}%' : '', // Hide labels if more than 4 items
        radius: radius,
        titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.black, height: 1.2),
        badgeWidget: itemCount <= 4 && data.icon != null ? Icon(data.icon, size: isTouched ? 24 : 18) : null,
        badgePositionPercentageOffset: 1.1,
      );
    });
  }
}
