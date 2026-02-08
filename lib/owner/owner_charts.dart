// ignore_for_file: deprecated_member_use

import 'dart:math' as math;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'owner_controller.dart';
import 'owner_models.dart';
import 'owner_utils.dart';

class MonthlyRevenueChart extends StatelessWidget {
  final List<MonthlySales> salesData;
  final List<MonthlySales> targetSalesData;

  const MonthlyRevenueChart({super.key, required this.salesData, required this.targetSalesData});

  @override
  Widget build(BuildContext context) {
    if (salesData.isEmpty) {
      return const Center(child: Text('No data available'));
    }
    // salesData = Chart Omset, targetSalesData = chart Target Omset/Sales
    final minRevenueActual = salesData.map((e) => e.revenue).reduce((a, b) => a < b ? a : b);
    final maxRevenueActual = salesData.map((e) => e.revenue).reduce((a, b) => a > b ? a : b);

    final minTarget =
        targetSalesData.isEmpty
            ? minRevenueActual
            : targetSalesData.map((e) => e.revenue).reduce((a, b) => a < b ? a : b);
    final maxTarget =
        targetSalesData.isEmpty
            ? maxRevenueActual
            : targetSalesData.map((e) => e.revenue).reduce((a, b) => a > b ? a : b);

    final minAll = minRevenueActual < minTarget ? minRevenueActual : minTarget;
    final maxAll = maxRevenueActual > maxTarget ? maxRevenueActual : maxTarget;

    final yInterval = _calculateYInterval(minAll, maxAll);

    final minY = (minAll * 0.9).floorToDouble();
    final maxY = maxAll * 1.3;

    return AspectRatio(
      aspectRatio: 1.7,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, bottom: 16, right: 16, top: 5),
        child: LineChart(
          LineChartData(
            lineTouchData: LineTouchData(
              // Buat Tap LineChartnya
              touchTooltipData: LineTouchTooltipData(
                // tooltipBgColor: Colors.black87,
                tooltipRoundedRadius: 8,
                tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                tooltipMargin: 12,
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                // tooltipBorder tersedia di versi terbaru fl_chart; kalau error, hapus saja.
                tooltipBorder: const BorderSide(color: Colors.white24, width: 1),

                // tooltipRoundedRadius: 8,
                // fitInsideHorizontally: true,
                // fitInsideVertically: true,
                getTooltipItems: (List<LineBarSpot> touchedSpots) {
                  if (touchedSpots.isEmpty) return [];

                  // Petakan spot berdasarkan barIndex agar mudah diambil terurut
                  final Map<int, LineBarSpot> byIndex = {for (final s in touchedSpots) s.barIndex: s};

                  // Ambil X yang disentuh (anggap semua series share X yang sama)
                  final int x = touchedSpots.first.x.toInt();

                  // Ambil nilai omset (0) & target (1) jika ada
                  final double? actualY = byIndex[0]?.y;
                  final double? targetY = byIndex[1]?.y;

                  // Apakah omset sudah mencapai/melebihi target di titik ini?
                  final bool achieved = (actualY != null && targetY != null && actualY >= targetY);

                  // Nama bulan (opsional)
                  String? month;
                  if (x >= 0 && x < salesData.length) {
                    month = salesData[x].month;
                  }

                  // Tentukan urutan tetap: Omset(0) dulu, lalu Target(1) jika ada
                  final List<int> orderedIndexes = [0, 1].where((i) => byIndex.containsKey(i)).toList();

                  return orderedIndexes.map((i) {
                    final spot = byIndex[i]!;
                    final isActual = i == 0;
                    final label = isActual ? 'Omset Sales' : 'Target Sales';
                    final check = (isActual && achieved) ? ' ✅' : '';
                    final formatted = formatRupiah(spot.y);

                    final text =
                        month != null ? '$label$check\n$month: $formatted' : '$label$check: $formatted';

                    return LineTooltipItem(
                      text,
                      TextStyle(
                        color: isActual ? const Color.fromARGB(255, 36, 186, 255) : Colors.amberAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    );
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

                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(salesData[value.toInt()].month, style: const TextStyle(fontSize: 10)),
                    );
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
                      child: Text(
                        formatRupiahShort(value),
                        style: const TextStyle(fontSize: 8, overflow: TextOverflow.visible),
                        maxLines: 2,
                      ),
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
              // Garis Target Sales. Hidupkan Klo dia udh byr
              LineChartBarData(
                spots:
                    targetSalesData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.revenue);
                    }).toList(),
                isCurved: false,
                color: const Color.fromARGB(255, 213, 171, 46),
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

    if (range <= 1000000) return 200000; // Rp 200K interval
    if (range <= 5000000) return 500000; // Rp 500K interval
    if (range <= 20000000) return 2000000; // Rp 2M interval
    if (range <= 100000000) return 25000000; // Rp 20m Interval
    return 100000000; // Rp 100Jt interval for larger values
  }
}

class BarChartTop4Paket extends StatefulWidget {
  final List<ChartData> chartData;
  const BarChartTop4Paket({super.key, required this.chartData});

  @override
  State<BarChartTop4Paket> createState() => _BarChartTop4PaketState();
}

class _BarChartTop4PaketState extends State<BarChartTop4Paket> {
  final RxInt touchedIndex = (-1).obs;

  @override
  Widget build(BuildContext context) {
    if (widget.chartData.isEmpty) {
      return const Center(child: Text('Tidak ada data'));
    }

    final total = widget.chartData.fold<double>(0, (s, e) => s + e.value);
    final maxVal = widget.chartData.map((e) => e.value).fold<double>(0, (a, b) => a > b ? a : b);
    final maxY = (maxVal * 1.2).clamp(1.0, double.infinity); // headroom 20%
    final yInterval = _calcYInterval(maxY);

    // Lebar kanvas agar bisa discroll kalau item banyak
    final double barWidth = 14.0;
    // final double groupSpace = 18.0;
    // final double minCanvasWidth = widget.chartData.length * (barWidth + groupSpace) + 40;

    final barGroups = List.generate(widget.chartData.length, (i) {
      final data = widget.chartData[i];
      final isTouched = i == touchedIndex.value;
      return BarChartGroupData(
        x: i,
        barsSpace: 4,
        barRods: [
          BarChartRodData(
            toY: data.value,
            color: data.color,
            width: isTouched ? barWidth + 6 : barWidth,
            borderSide:
                isTouched ? BorderSide(color: Colors.black.withOpacity(0.2), width: 1) : BorderSide.none,
            borderRadius: BorderRadius.circular(6),
            rodStackItems: const [], // kalau mau stacked nanti tinggal isi
          ),
        ],
      );
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Kanvas chart yang bisa horizontal scroll kalau label/batang banyak
        Padding(
          padding: EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 16.0),
          child: SizedBox(
            height: 220, // atur sesuai layout kamu; bisa juga 100.w seperti sebelumnya
            width: Get.width,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                minY: 0,
                barGroups: barGroups,
                barTouchData: BarTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final data = widget.chartData[groupIndex];
                      final pct = total > 0 ? (data.value / total * 100) : 0;
                      return BarTooltipItem(
                        '${data.label.trim().toUpperCase()}.\n'
                        'Ratio: ${pct.toStringAsFixed(1)}%',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    if (!event.isInterestedForInteractions || response == null || response.spot == null) {
                      touchedIndex.value = -1;
                      return;
                    }
                    touchedIndex.value = response.spot!.touchedBarGroupIndex;
                  },
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: yInterval),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= widget.chartData.length) return const SizedBox.shrink();
                        final label = widget.chartData[idx].label;
                        // log("Width dari double infinity ${Get.width}");
                        return Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: SizedBox(
                            width: (Get.width - 50) / 4, // mainkan width disini
                            child: Text(
                              label.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 10),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 46,
                      interval: yInterval,
                      getTitlesWidget:
                          (value, meta) => Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: Text(_fmtNumber(value), style: const TextStyle(fontSize: 10)),
                          ),
                    ),
                  ),
                ),

                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    left: BorderSide(color: Colors.black12),
                    bottom: BorderSide(color: Colors.black12),
                  ),
                ),
                alignment: BarChartAlignment.spaceAround,
              ),
            ),
          ),
        ),

        // Legend custom
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: List.generate(widget.chartData.length, (i) {
            final d = widget.chartData[i];
            final pct = total > 0 ? (d.value / total * 100) : 0;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(color: d.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  '${d.label} (${pct.toStringAsFixed(1)}%)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  // Interval Y yang “rapi”
  double _calcYInterval(double maxY) {
    if (maxY <= 10) return 2;
    if (maxY <= 50) return 10;
    if (maxY <= 100) return 20;
    if (maxY <= 500) return 100;
    if (maxY <= 1000) return 200;
    if (maxY <= 5000) return 1000;
    if (maxY <= 10000) return 2000;
    return maxY / 5; // fallback 5 garis
  }

  // String _shortLabel(String s) {
  //   if (s.length <= 10) return s;
  //   return s.substring(0, 10) + '…';
  // }

  String _fmtNumber(num v) {
    // Format ringkas: 1.2K / 3.4Jt, dsb
    final d = v.toDouble();
    if (d >= 1000000) return '${(d / 1000000).toStringAsFixed(1)}Jt';
    if (d >= 1000) return '${(d / 1000).toStringAsFixed(1)}Rb';
    return d.toStringAsFixed(d % 1 == 0 ? 0 : 1);
  }
}

class TotalSalesHarianChart extends StatelessWidget {
  const TotalSalesHarianChart({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<OwnerPageController>();
    // ====== Data dari contohmu ======
    final List<HarianData> data = c.dataSalesHarian;

    // ====== Skala Y (dengan padding 20%) ======
    final double maxValue = data.map((e) => e.total.toDouble()).reduce(math.max);
    final double maxY = (maxValue * 1.2);
    final double interval = safeNiceInterval(maxY);

    // ====== Bar groups ======
    final barGroups = List.generate(data.length, (i) {
      final d = data[i];
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: d.total.toDouble(),
            width: 16,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
            // Sesuaikan warna bila mau
            color: Colors.blue,
          ),
        ],
      );
    });

    return SizedBox(
      height: 300,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                // Ghost: transparan, buat penyeimbang lebar tombol kanan
                Opacity(
                  opacity: 0,
                  child: SizedBox(
                    height: 25,
                    child: ElevatedButton(
                      onPressed: () {}, // dummy
                      child: const Text('Filter'),
                    ),
                  ),
                ),

                // Judul center
                Expanded(
                  child: Center(
                    child: Obx(() {
                      final dates = c.rangeDatePickerOmset;
                      String suffix = 'Per-Hari ini';
                      if (dates.isNotEmpty && dates[0] != null) {
                        final fmt = DateFormat('dd-MM-yyyy');
                        final start = dates[0]!;
                        final end = (dates.length > 1 && dates[1] != null) ? dates[1]! : start;
                        if (start == end) {
                          suffix = fmt.format(start);
                        } else {
                          suffix = '${fmt.format(start)} - ${fmt.format(end)}';
                        }
                      }
                      return Text(
                        'Total Sales Harian \n $suffix',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      );
                    }),
                  ),
                ),

                // Tombol kanan
                SizedBox(
                  height: 25,
                  child: ElevatedButton(
                    onPressed: () => c.showDialogFilterTargetHarian(),
                    child: const Text('Filter'),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: interval),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      bottom: BorderSide(color: Colors.black12, width: 1),
                      left: BorderSide(color: Colors.black12, width: 1),
                      right: BorderSide(color: Colors.transparent),
                      top: BorderSide(color: Colors.transparent),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                          return Obx(
                            () => Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(
                                hariInggrisKeIndonesia[data[idx].namaHari]!,
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 56,
                        interval: interval,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            child: Text(formatRupiahShort(value), style: const TextStyle(fontSize: 10)),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      tooltipMargin: 12,
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      tooltipBorder: const BorderSide(color: Colors.white24, width: 1),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final d = data[group.x.toInt()];
                        final title = d.namaHari;
                        // 1. Ubah string tanggal menjadi objek DateTime
                        final dateTime = DateTime.parse(d.tanggal);

                        // 2. Buat formatter untuk format output yang diinginkan
                        final outputFormat = DateFormat("dd-MM-yyyy");

                        // 3. Format objek DateTime menjadi string yang cantik
                        final subtitle = outputFormat.format(dateTime); // Gunakan .format()

                        final valueStr = rod.toY;
                        return BarTooltipItem(
                          '${hariInggrisKeIndonesia[title]}\n$subtitle\n${formatRupiah(valueStr)}',
                          const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                        );
                      },
                    ),
                  ),
                  minY: 0,
                  maxY: maxY,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PenjualanTerapisBarChart extends StatelessWidget {
  const PenjualanTerapisBarChart({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<OwnerPageController>();
    final data = c.dataPenjualanTerapis;

    if (data.isEmpty) return const SizedBox.shrink();

    final double maxValue = data.map((e) => e.total).reduce(math.max);
    final double maxY = (maxValue * 1.2).clamp(1.0, double.infinity);
    final double interval = safeNiceInterval(maxY);
    final double totalSum = data.fold<double>(0, (sum, item) => sum + item.total);

    const double barWidth = 16;
    const double groupSpace = 14;
    final double minCanvasWidth = data.length * (barWidth + groupSpace) + 40;
    final double canvasWidth = math.max(minCanvasWidth, MediaQuery.of(context).size.width - 40);

    final barGroups = List.generate(data.length, (i) {
      final d = data[i];
      return BarChartGroupData(
        x: i,
        barsSpace: 4,
        barRods: [
          BarChartRodData(
            toY: d.total,
            width: barWidth,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
            color: Colors.teal,
          ),
        ],
      );
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 260,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: canvasWidth,
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: interval),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      bottom: BorderSide(color: Colors.black12, width: 1),
                      left: BorderSide(color: Colors.black12, width: 1),
                      right: BorderSide(color: Colors.transparent),
                      top: BorderSide(color: Colors.transparent),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: SizedBox(
                              width: 70,
                              child: Text(
                                data[idx].namaKaryawan,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 10),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 56,
                        interval: interval,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 4.0, left: 10.0),
                            child: AutoSizeText(
                              formatRupiahShort(value),
                              style: const TextStyle(fontSize: 10),
                              maxFontSize: 10,
                              minFontSize: 8,
                              stepGranularity: 1,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      tooltipMargin: 12,
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final d = data[group.x.toInt()];
                        return BarTooltipItem(
                          '${d.namaKaryawan}\n${formatRupiah(rod.toY)}',
                          const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                        );
                      },
                    ),
                  ),
                  minY: 0,
                  maxY: maxY,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Total: ${formatRupiah(totalSum)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class KomisiTerapisBarChart extends StatelessWidget {
  const KomisiTerapisBarChart({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<OwnerPageController>();
    final data = c.dataKomisiTerapis;

    if (data.isEmpty) return const SizedBox.shrink();

    final double maxValue = data.map((e) => e.total).reduce(math.max);
    final double maxY = (maxValue * 1.2).clamp(1.0, double.infinity);
    final double interval = safeNiceInterval(maxY);
    final double totalSum = data.fold<double>(0, (sum, item) => sum + item.total);

    const double barWidth = 16;
    const double groupSpace = 14;
    final double minCanvasWidth = data.length * (barWidth + groupSpace) + 40;
    final double canvasWidth = math.max(minCanvasWidth, MediaQuery.of(context).size.width - 40);

    final barGroups = List.generate(data.length, (i) {
      final d = data[i];
      return BarChartGroupData(
        x: i,
        barsSpace: 4,
        barRods: [
          BarChartRodData(
            toY: d.total,
            width: barWidth,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
            color: Colors.orange,
          ),
        ],
      );
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 260,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: canvasWidth,
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: interval),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      bottom: BorderSide(color: Colors.black12, width: 1),
                      left: BorderSide(color: Colors.black12, width: 1),
                      right: BorderSide(color: Colors.transparent),
                      top: BorderSide(color: Colors.transparent),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: SizedBox(
                              width: 70,
                              child: Text(
                                data[idx].namaKaryawan,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 10),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 56,
                        interval: interval,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 4.0, left: 10.0),
                            child: AutoSizeText(
                              formatRupiahShort(value),
                              style: const TextStyle(fontSize: 10),
                              maxFontSize: 10,
                              minFontSize: 8,
                              stepGranularity: 1,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      tooltipMargin: 12,
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final d = data[group.x.toInt()];
                        return BarTooltipItem(
                          '${d.namaKaryawan}\n${formatRupiah(rod.toY)}',
                          const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                        );
                      },
                    ),
                  ),
                  minY: 0,
                  maxY: maxY,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Total Komisi: ${formatRupiah(totalSum)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// Kode Awal Pake PieChart. Sementara Di Taruh sini Aja gpp, Takut Dia berubah pikiran
class DynamicPieChart extends StatefulWidget {
  // parameter. diambil dari list pieChartData di OwnerPageState
  final List<ChartData> chartData;

  const DynamicPieChart({super.key, required this.chartData});

  @override
  // ignore: library_private_types_in_public_api
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
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
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
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(color: data.color, shape: BoxShape.circle),
                ),
                SizedBox(width: 8),
                Text(
                  '${data.label} (${data.value.toStringAsFixed(1)}%)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black),
                ),
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
        titleStyle: TextStyle(
          fontSize: fontSize.w - 7.w,
          fontWeight: FontWeight.bold,
          color: Colors.black,
          height: 1.2,
        ),
        badgeWidget: null,
        badgePositionPercentageOffset: 1.1,
      );
    });
  }
}
