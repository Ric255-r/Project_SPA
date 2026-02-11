import 'dart:async';
import 'dart:developer';

import 'package:Project_SPA/function/ip_address.dart';
import 'package:Project_SPA/function/rupiah_formatter.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'owner_models.dart';

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
  RxList<MonthlySales> monthlyDataTarget = <MonthlySales>[].obs;
  // End Revenue LineChart
  RxList<ChartData> pieChartData = <ChartData>[].obs;
  // Variable Filters
  RxnString _selectedTahun = RxnString(null);
  RxnString _startMonth = RxnString(null);
  RxnString _startYear = RxnString(null);
  RxnString _endMonth = RxnString(null);
  RxnString _endYear = RxnString(null);
  RxnString _startMonthTargetOmset = RxnString(null);
  RxnString _startYearTargetOmset = RxnString(null);
  RxnString _endMonthTargetOmset = RxnString(null);
  RxnString _endYearTargetOmset = RxnString(null);
  int _nominalTargetOmset = 0;

  RxList<dynamic> _monthlySales = [].obs;
  RxList<dynamic> _paketSales = [].obs;
  RxList<dynamic> _produkSales = [].obs;
  RxList<dynamic> _paketTerlaris = [].obs;
  RxList<String> _tahunTransaksi = <String>[].obs;
  //  satu paket utk get target sales
  RxList<dynamic> dataTargetOmset = [].obs;
  RxList<dynamic> dataOmset = [].obs;
  RxList<String> tahunTransaksiTarget = <String>[].obs;
  RxList<int> listYear = List<int>.generate(100, (index) => 2020 + index).obs;
  RxList<DateTime?> rangeDatePickerOmset = <DateTime?>[].obs;
  // End 1 Paket Target Sales Bulanan

  // Var TargetSales Harian
  RxList<HarianData> dataSalesHarian = <HarianData>[].obs;
  RxBool isLoadingDataSalesHarian = false.obs;
  // End Data Target Sales Harian

  // Var Penjualan Terapis
  RxList<PenjualanTerapisData> dataPenjualanTerapis = <PenjualanTerapisData>[].obs;
  RxBool isLoadingPenjualanTerapis = false.obs;
  RxList<DateTime?> rangeDatePickerPenjualanTerapis = <DateTime?>[].obs;
  // End Penjualan Terapis

  // Var Komisi Terapis
  RxList<KomisiTerapisData> dataKomisiTerapis = <KomisiTerapisData>[].obs;
  RxBool isLoadingKomisiTerapis = false.obs;
  RxList<DateTime?> rangeDatePickerKomisiTerapis = <DateTime?>[].obs;
  // End Komisi Terapis

  RxList<dynamic> get monthlySalesRaw => _monthlySales;
  RxList<dynamic> get paketSalesRaw => _paketSales;
  RxList<dynamic> get produkSalesRaw => _produkSales;
  RxList<String> get tahunTransaksi => _tahunTransaksi;

  Future<void> refreshLineChart({String? startDate, String? endDate}) =>
      _getLineChart(startDate: startDate, endDate: endDate);

  var dio = Dio();

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    _getData();
    _getLineChart();
    _getDataTarget();
    _getDataTargetHarian();
    _getPenjualanTerapis();
    _getKomisiTerapis();
    log("${DateTime.now().month}".padLeft(2, "0"));
  }

  /// Hitung selisih bulan berbasis (tahun, bulan) — hari diabaikan.
  int monthDiff(DateTime start, DateTime end) {
    // Normalisasi ke awal bulan
    final s = DateTime(start.year, start.month);
    final e = DateTime(end.year, end.month);
    return (e.year - s.year) * 12 + (e.month - s.month);
  }

  /// Validasi range maksimal 12 bulan
  bool isRangeValid(DateTime start, DateTime end, {int maxMonths = 12}) {
    if (end.isBefore(start)) return false; // end harus >= start
    final diff = monthDiff(start, end); // selisih bulan
    return diff <= maxMonths; // ≤ 12 bulan diperbolehkan
  }

  DateTime _toYm(String y, String m) => DateTime(int.parse(y), int.parse(m));

  void showFilterLineChart() {
    Get.dialog(
      AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            children: [
              Text("Pilih Periode Awal"),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _startMonth.value,
                      onChanged: (String? value) {
                        _startMonth.value = value!;
                      },
                      items:
                          monthNames.entries.map((data) {
                            return DropdownMenuItem<String>(value: data.key, child: Text(data.value));
                          }).toList(),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _startYear.value,
                      onChanged: (String? value) {
                        _startYear.value = value!;
                      },
                      items:
                          _tahunTransaksi.map((String data) {
                            return DropdownMenuItem<String>(value: data, child: Text(data));
                          }).toList(),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              Text("Pilih Periode Akhir"),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _endMonth.value,
                      onChanged: (String? value) {
                        _endMonth.value = value!;
                      },
                      items:
                          monthNames.entries.map((data) {
                            return DropdownMenuItem<String>(value: data.key, child: Text(data.value));
                          }).toList(),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _endYear.value,
                      onChanged: (String? value) {
                        _endYear.value = value!;
                      },
                      items:
                          _tahunTransaksi.map((String data) {
                            return DropdownMenuItem<String>(value: data, child: Text(data));
                          }).toList(),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Cek Apa Sudah Pilih Semua
                  if (_startMonth.value == null ||
                      _startYear.value == null ||
                      _endMonth.value == null ||
                      _endYear.value == null) {
                    CherryToast.info(
                      title: Text(
                        "Perhatian!",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      description: Text('Pilih bulan & tahun untuk periode awal dan akhir.'),
                      animationDuration: const Duration(milliseconds: 3000),
                      autoDismiss: true,
                    ).show(Get.context!);
                    return;
                  }

                  // Build DateTime dari Dropdown
                  final start = _toYm(_startYear.value!, _startMonth.value!);
                  final end = _toYm(_endYear.value!, _endMonth.value!);
                  // 1️⃣ Cek tahun harus sama
                  if (start.year != end.year) {
                    CherryToast.warning(
                      title: const Text('Tidak Valid'),
                      description: const Text('Tahun awal dan tahun akhir harus sama.'),
                    ).show(Get.context!);
                    return;
                  }
                  // Validasi Range Maks 12 bln
                  if (!isRangeValid(start, end)) {
                    final selisih = monthDiff(start, end);
                    if (selisih < 0) {
                      CherryToast.warning(
                        title: const Text('Periode Bulan Terbalik'),
                        description: Text(' (sekarang: Selisih $selisih bulan).'),
                      ).show(Get.context!);
                    } else {
                      CherryToast.warning(
                        title: const Text('Range terlalu panjang'),
                        description: Text('Maksimal 12 bulan (sekarang: $selisih bulan).'),
                      ).show(Get.context!);
                    }
                    return; // matikan fungsi sesuai requirement
                  }

                  // Lolos Validasi? Format
                  final startStr =
                      '${start.year.toString().padLeft(4, '0')}-${start.month.toString().padLeft(2, '0')}';
                  final endStr =
                      '${end.year.toString().padLeft(4, '0')}-${end.month.toString().padLeft(2, '0')}';

                  _getLineChart(startDate: startStr, endDate: endStr).then((_) => Get.back());
                },
                child: Text("Filter!"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showDialogTargetSales({String modeDialog = "filter"}) {
    // Dialog di Target Sales
    Get.dialog(
      AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            children: [
              const Text("Pilih Periode Awal"),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _startMonthTargetOmset.value,
                      onChanged: (String? value) {
                        _startMonthTargetOmset.value = value!;
                      },
                      items:
                          monthNames.entries.map((data) {
                            return DropdownMenuItem<String>(value: data.key, child: Text(data.value));
                          }).toList(),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  // Ini Untuk Dropdown Tahun. Jika Filter,
                  // ambil tahun yg ada di table target_sales
                  if (modeDialog == "filter") ...[
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _startYearTargetOmset.value,
                        onChanged: (String? value) {
                          _startYearTargetOmset.value = value!;
                        },
                        items:
                            tahunTransaksiTarget.map<DropdownMenuItem<String>>((data) {
                              return DropdownMenuItem<String>(value: data, child: Text(data));
                            }).toList(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                        ),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: Obx(
                        () => DropdownButtonFormField<int>(
                          value:
                              _startYearTargetOmset.value != null
                                  ? int.tryParse(_startYearTargetOmset.value!)
                                  : null,
                          onChanged: (int? value) {
                            _startYearTargetOmset.value = value.toString();
                          },
                          items:
                              listYear.map((int year) {
                                return DropdownMenuItem<int>(value: year, child: Text(year.toString()));
                              }).toList(),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              if (modeDialog == "filter") ...[
                Text("Pilih Periode Akhir"),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _endMonthTargetOmset.value,
                        onChanged: (String? value) {
                          _endMonthTargetOmset.value = value!;
                        },
                        items:
                            monthNames.entries.map((data) {
                              return DropdownMenuItem<String>(value: data.key, child: Text(data.value));
                            }).toList(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _endYearTargetOmset.value,
                        onChanged: (String? value) {
                          _endYearTargetOmset.value = value!;
                        },
                        items:
                            tahunTransaksiTarget.map((String data) {
                              return DropdownMenuItem<String>(value: data, child: Text(data));
                            }).toList(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Cek Apa Sudah Pilih Semua
                    if (_startMonthTargetOmset.value == null ||
                        _startYearTargetOmset.value == null ||
                        _endMonthTargetOmset.value == null ||
                        _endYearTargetOmset.value == null) {
                      CherryToast.warning(
                        title: Text(
                          "Perhatian!",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        description: Text('Pilih bulan & tahun untuk periode awal dan akhir.'),
                        animationDuration: const Duration(milliseconds: 2000),
                        autoDismiss: true,
                      ).show(Get.context!);
                      return;
                    }

                    // Build DateTime dari Dropdown
                    final start = _toYm(_startYearTargetOmset.value!, _startMonthTargetOmset.value!);
                    final end = _toYm(_endYearTargetOmset.value!, _endMonthTargetOmset.value!);
                    // 1️⃣ Cek tahun harus sama
                    if (start.year != end.year) {
                      CherryToast.warning(
                        title: Text(
                          "Tidak Valid!",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        description: Text('Tahun Awal dan Tahun Akhir Harus Sama.'),
                        animationDuration: const Duration(milliseconds: 2000),
                        autoDismiss: true,
                      ).show(Get.context!);
                      return;
                    }
                    // Validasi Range Maks 12 bln
                    if (!isRangeValid(start, end)) {
                      final selisih = monthDiff(start, end);
                      if (selisih < 0) {
                        CherryToast.warning(
                          title: Text(
                            "Perhatian!",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          description: Text('Periode Bulan Terbalik. (sekarang: Selisih $selisih bulan).'),
                          animationDuration: const Duration(milliseconds: 2000),
                          autoDismiss: true,
                        ).show(Get.context!);
                      } else {
                        CherryToast.warning(
                          title: Text(
                            "Perhatian!",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          description: Text(
                            'Range terlalu panjang Maksimal 12 bulan (sekarang: $selisih bulan).',
                          ),
                          animationDuration: const Duration(milliseconds: 2000),
                          autoDismiss: true,
                        ).show(Get.context!);
                      }
                      return; // matikan fungsi sesuai requirement
                    }

                    // Lolos Validasi? Format
                    final startStr =
                        '${start.year.toString().padLeft(4, '0')}-${start.month.toString().padLeft(2, '0')}';
                    final endStr =
                        '${end.year.toString().padLeft(4, '0')}-${end.month.toString().padLeft(2, '0')}';

                    // Panggil Method
                    // _getLineChart(startDate: startStr, endDate: endStr).then((_) => Get.back());
                    _getDataTarget(
                      startMonth: start.month,
                      endMonth: end.month,
                      startYear: start.year,
                      endYear: end.year,
                    ).then((_) => Get.back());
                  },
                  child: Text("Filter!"),
                ),
              ] else ...[
                const Text("Input Target Sales"),
                const SizedBox(height: 20),

                TextField(
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[RupiahInputFormatter()], //
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Rp. ",
                    contentPadding: EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  ),
                  onChanged: (value) {
                    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                    _nominalTargetOmset = int.tryParse(digits) ?? 0;
                    log("Isi Nominal target Omset $_nominalTargetOmset");
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await _storeDataTarget();
                  },
                  child: Text("Simpan Perubahan"),
                ),
              ],
            ],
          ),
        ),
      ),
    ).then((_) {
      _startMonthTargetOmset.value = null;
      _startYearTargetOmset.value = null;
      _endMonthTargetOmset.value = null;
      _endYearTargetOmset.value = null;
      _nominalTargetOmset = 0;
    });
  }

  void showDialogPenjualanPerTerapis() {
    rangeDatePickerPenjualanTerapis.clear();
    final ScrollController scrollTglController = ScrollController();

    Get.dialog(
      AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        content: Builder(
          builder: (context) {
            final mq = MediaQuery.of(context);
            final isPortrait = mq.orientation == Orientation.landscape;

            // Tentukan ukuran dialog yang TEGAS (tight), responsif ke layar
            final maxDialogWidth = 500.0; // cap untuk tablet/layar lebar
            final dialogWidth = mq.size.width.clamp(0.0, maxDialogWidth);
            final dialogHeight = (isPortrait ? mq.size.height * 0.7 : mq.size.height * 0.8) - 110;

            return SizedBox(
              width: dialogWidth,
              height: dialogHeight, // <- TIGHT! tidak ada intrinsic ke anak
              child: Scrollbar(
                controller: scrollTglController,
                thumbVisibility: true,
                child: ListView(
                  // Penting: biarkan default (shrinkWrap: false)
                  controller: scrollTglController,
                  padding: const EdgeInsets.only(right: 4, bottom: 8),
                  children: [
                    const Text(
                      "Petunjuk : Anda bisa memilih lebih dari 1 Tanggal\nMaks 7 Hari",
                      style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),

                    // Isi lebar dialog
                    SizedBox(
                      width: double.infinity,
                      child: Obx(
                        () => CalendarDatePicker2(
                          config: CalendarDatePicker2Config(
                            calendarType: CalendarDatePicker2Type.range,
                            selectedDayHighlightColor: Colors.deepPurple,
                            selectedRangeHighlightColor: Colors.purpleAccent.withOpacity(0.2),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          ),
                          value: rangeDatePickerPenjualanTerapis,
                          onValueChanged: (dates) {
                            if (dates.length >= 2) {
                              final start = dates[0];
                              final end = dates[1];
                              final diffDays = end.difference(start).inDays.abs();
                              // Maks 7 hari (inklusif)
                              if (diffDays > 6) {
                                final cappedEnd = start.add(const Duration(days: 6));
                                rangeDatePickerPenjualanTerapis.assignAll([start, cappedEnd]);
                                CherryToast.warning(
                                  title: const Text(
                                    "Perhatian!",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  description: const Text("Maksimal 7 hari."),
                                  animationDuration: const Duration(milliseconds: 2000),
                                  autoDismiss: true,
                                ).show(Get.context!);
                                return;
                              }
                            }

                            rangeDatePickerPenjualanTerapis.assignAll(dates);
                            log("Isi Range Date $rangeDatePickerPenjualanTerapis");
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        actions: [
          ElevatedButton(
            onPressed: () async {
              String startDate = rangeDatePickerPenjualanTerapis[0].toString().split(" ")[0];
              String endDate = "";
              if (rangeDatePickerPenjualanTerapis.length > 1) {
                endDate = rangeDatePickerPenjualanTerapis[1].toString().split(" ")[0];
              } else {
                endDate = startDate;
              }
              await _getPenjualanTerapis(startDate: startDate, endDate: endDate);

              Get.back();
            },
            child: const Text("SUBMIT"),
          ),
        ],
      ),
    ).then((_) async {
      if (rangeDatePickerPenjualanTerapis.isEmpty) {
        await _getPenjualanTerapis();
      }
    });
  }

  void showDialogKomisiPerTerapis() {
    rangeDatePickerKomisiTerapis.clear();
    final ScrollController scrollTglController = ScrollController();

    Get.dialog(
      AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        content: Builder(
          builder: (context) {
            final mq = MediaQuery.of(context);
            final isPortrait = mq.orientation == Orientation.landscape;

            // Tentukan ukuran dialog yang TEGAS (tight), responsif ke layar
            final maxDialogWidth = 500.0; // cap untuk tablet/layar lebar
            final dialogWidth = mq.size.width.clamp(0.0, maxDialogWidth);
            final dialogHeight = (isPortrait ? mq.size.height * 0.7 : mq.size.height * 0.8) - 110;

            return SizedBox(
              width: dialogWidth,
              height: dialogHeight, // <- TIGHT! tidak ada intrinsic ke anak
              child: Scrollbar(
                controller: scrollTglController,
                thumbVisibility: true,
                child: ListView(
                  // Penting: biarkan default (shrinkWrap: false)
                  controller: scrollTglController,
                  padding: const EdgeInsets.only(right: 4, bottom: 8),
                  children: [
                    const Text(
                      "Petunjuk : Anda bisa memilih lebih dari 1 Tanggal\nMaks 7 Hari",
                      style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),

                    // Isi lebar dialog
                    SizedBox(
                      width: double.infinity,
                      child: Obx(
                        () => CalendarDatePicker2(
                          config: CalendarDatePicker2Config(
                            calendarType: CalendarDatePicker2Type.range,
                            selectedDayHighlightColor: Colors.deepPurple,
                            selectedRangeHighlightColor: Colors.purpleAccent.withOpacity(0.2),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          ),
                          value: rangeDatePickerKomisiTerapis,
                          onValueChanged: (dates) {
                            if (dates.length >= 2) {
                              final start = dates[0];
                              final end = dates[1];
                              final diffDays = end.difference(start).inDays.abs();
                              // Maks 7 hari (inklusif)
                              if (diffDays > 6) {
                                final cappedEnd = start.add(const Duration(days: 6));
                                rangeDatePickerKomisiTerapis.assignAll([start, cappedEnd]);
                                CherryToast.warning(
                                  title: const Text(
                                    "Perhatian!",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  description: const Text("Maksimal 7 hari."),
                                  animationDuration: const Duration(milliseconds: 2000),
                                  autoDismiss: true,
                                ).show(Get.context!);
                                return;
                              }
                            }

                            rangeDatePickerKomisiTerapis.assignAll(dates);
                            log("Isi Range Date $rangeDatePickerKomisiTerapis");
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        actions: [
          ElevatedButton(
            onPressed: () async {
              String startDate = rangeDatePickerKomisiTerapis[0].toString().split(" ")[0];
              String endDate = "";
              if (rangeDatePickerKomisiTerapis.length > 1) {
                endDate = rangeDatePickerKomisiTerapis[1].toString().split(" ")[0];
              } else {
                endDate = startDate;
              }
              await _getKomisiTerapis(startDate: startDate, endDate: endDate);

              Get.back();
            },
            child: const Text("SUBMIT"),
          ),
        ],
      ),
    ).then((_) async {
      if (rangeDatePickerKomisiTerapis.isEmpty) {
        await _getKomisiTerapis();
      }
    });
  }

  Future<void> _getLineChart({String? startDate, String? endDate}) async {
    print("Eksekusi GetLineChart");
    try {
      String url = '';
      if (startDate != null && endDate != null) {
        url = "${myIpAddr()}/main_owner/line_chart?start_date=$startDate&end_date=$endDate";
      } else {
        url = "${myIpAddr()}/main_owner/line_chart";
      }

      var response = await dio.get(url);
      Map<String, dynamic> responseData = response.data;

      List<dynamic> lineChart = responseData['for_line_chart'];
      List<dynamic> targetLineChart = responseData['line_chart_target'];

      monthlyData.clear();
      monthlyDataTarget.clear();
      for (var i = 0; i < lineChart.length; i++) {
        // Ini Buat For Line Chart,
        String bulan = (lineChart[i]['bulan'] as String).split("-")[1];
        monthlyData.add(
          MonthlySales((monthNames[bulan] as String), (lineChart[i]['omset_jual'] as num).toDouble()),
        );
        // krn Length datany sama, masukin aje ke for loop ini
        String bulanTarget = (targetLineChart[i]['periode'] as String).split("-")[1];
        monthlyDataTarget.add(
          MonthlySales(
            (monthNames[bulanTarget] as String),
            (targetLineChart[i]['target_omset'] as num).toDouble(),
          ),
        );
      }
    } catch (e) {
      log("Error di Get Line Chart ${e}");
    }
  }

  Future<void> _getData() async {
    try {
      var response = await dio.get('${myIpAddr()}/main_owner/get_laporan');

      Map<String, dynamic> responseData = response.data;
      List<dynamic> paketTerlaris = responseData['paket_terlaris'];

      _monthlySales.assignAll(responseData['monthly_sales']);
      _paketSales.assignAll(responseData['sum_paket']);
      _produkSales.assignAll(responseData['sum_produk']);
      _paketTerlaris.assignAll(paketTerlaris);
      _tahunTransaksi.assignAll((responseData['tahun_transaksi'] as List).map((el) => el.toString()));

      pieChartData.clear();
      if (paketTerlaris.isNotEmpty) {
        // Calculate total sold for percentage calculation
        double totalSold = paketTerlaris.fold(
          0,
          (sum, item) => sum + (item['jumlah_terjual'] as num).toDouble(),
        );

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

  Future<void> _getDataTarget({int? startMonth, int? endMonth, int? startYear, int? endYear}) async {
    try {
      DateTime now = DateTime.now(); // Get the current date and time
      int currentYear = now.year; // Extract the year
      startYear ??= currentYear; // if null get currentYear
      String yearParams = "?start_year=$startYear";

      if (endYear != null) {
        yearParams += "&end_year=$endYear";
      }

      var url = '${myIpAddr()}/main_owner/get_target_sales$yearParams';

      if (startMonth != null && endMonth != null) {
        url += "&start_month=$startMonth&end_month=$endMonth";
      } else {
        // Default Ambil Bulan Saat Ini
        url += "&start_month=${now.month}&end_month=${now.month}";
      }

      var response = await dio.get(url);
      Map<String, dynamic> responseData = response.data;
      dataTargetOmset.assignAll(responseData['get_sales_target']);
      dataOmset.assignAll(responseData['get_omset']);

      tahunTransaksiTarget.assignAll(
        (responseData['tahun_target'] as List).map((el) => el['year'].toString()),
      );
    } catch (e) {
      if (e is DioException) {
        log("Error di getDataTarget dio ${e.response!.data}");
      }

      log("Error di getDataTarget dio $e");
    }
  }

  Future<void> _getDataTargetHarian({String? startDate, String? endDate}) async {
    try {
      isLoadingDataSalesHarian.value = true;

      var url = '${myIpAddr()}/main_owner/sales_chart_harian';
      if (startDate != null && endDate != null) {
        url += "?start_date=$startDate&end_date=$endDate";
      }

      var response = await dio.get(url);
      Map<String, dynamic> responseData = response.data;

      dataSalesHarian.assignAll(
        (responseData['data'] as List).map((el) {
          return HarianData(el['nama_hari'], el['tanggal'], el['total']);
        }).toList(),
      );

      if (response.statusCode == 200) {
        isLoadingDataSalesHarian.value = false;
      }

      log("Isi dataSalesHarian Harian = $dataSalesHarian");
    } catch (e) {
      if (e is DioException) {
        if (e.response!.statusCode == 400) {
          rangeDatePickerOmset.clear();
          CherryToast.error(
            title: Text(
              "Error!",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
            ),
            description: Text(e.response!.data['message']!),
            animationDuration: const Duration(milliseconds: 2500),
            autoDismiss: true,
            onToastClosed: () {
              _getDataTargetHarian();
            },
          ).show(Get.context!);
        }

        log("Error di _getDataTargetHarian dio ${e.response!.data}");
      }

      log("Error di _getDataTargetHarian dio $e");
    }
  }

  Future<void> _getPenjualanTerapis({String? startDate, String? endDate}) async {
    try {
      isLoadingPenjualanTerapis.value = true;
      var url = '${myIpAddr()}/main_owner/get_graph_penjualan_terapis';
      if (startDate != null && endDate != null) {
        url += '?start_date=$startDate&end_date=$endDate';
      } else if (startDate != null) {
        url += '?start_date=$startDate';
      }

      var response = await dio.get(url);
      final dynamic body = response.data;
      final List<dynamic> items = body is List ? body : (body['data'] ?? <dynamic>[]);

      dataPenjualanTerapis.assignAll(
        items.map((el) {
          return PenjualanTerapisData(
            (el['nama_karyawan'] ?? '').toString(),
            (el['total'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList(),
      );
    } catch (e) {
      if (e is DioException) {
        log("Error di _getPenjualanTerapis dio ${e.response!.data}");
      }
      log("Error di _getPenjualanTerapis $e");
    } finally {
      isLoadingPenjualanTerapis.value = false;
    }
  }

  Future<void> _getKomisiTerapis({String? startDate, String? endDate}) async {
    try {
      isLoadingKomisiTerapis.value = true;
      var url = '${myIpAddr()}/main_owner/get_graph_komisi_terapis';
      if (startDate != null && endDate != null) {
        url += '?start_date=$startDate&end_date=$endDate';
      } else if (startDate != null) {
        url += '?start_date=$startDate';
      }

      var response = await dio.get(url);
      final dynamic body = response.data;
      final List<dynamic> items = body is List ? body : (body['data'] ?? <dynamic>[]);

      dataKomisiTerapis.assignAll(
        items.map((el) {
          return KomisiTerapisData(
            (el['nama_karyawan'] ?? '').toString(),
            (el['total'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList(),
      );
    } catch (e) {
      log("Error di _getKomisiTerapis $e");
    } finally {
      isLoadingKomisiTerapis.value = false;
    }
  }

  void showDialogFilterTargetHarian() {
    rangeDatePickerOmset.clear();
    final ScrollController scrollTglController = ScrollController();

    Get.dialog(
      AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        content: Builder(
          builder: (context) {
            final mq = MediaQuery.of(context);
            final isPortrait = mq.orientation == Orientation.landscape;

            // Tentukan ukuran dialog yang TEGAS (tight), responsif ke layar
            final maxDialogWidth = 500.0; // cap untuk tablet/layar lebar
            final dialogWidth = mq.size.width.clamp(0.0, maxDialogWidth);
            final dialogHeight = (isPortrait ? mq.size.height * 0.7 : mq.size.height * 0.8) - 110;

            return SizedBox(
              width: dialogWidth,
              height: dialogHeight, // <- TIGHT! tidak ada intrinsic ke anak
              child: Scrollbar(
                controller: scrollTglController,
                thumbVisibility: true,
                child: ListView(
                  // Penting: biarkan default (shrinkWrap: false)
                  controller: scrollTglController,
                  padding: const EdgeInsets.only(right: 4, bottom: 8),
                  children: [
                    const Text(
                      "Petunjuk : Anda bisa memilih lebih dari 1 Tanggal\nMaks 7 Hari",
                      style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),

                    // Isi lebar dialog
                    SizedBox(
                      width: double.infinity,
                      child: Obx(
                        () => CalendarDatePicker2(
                          config: CalendarDatePicker2Config(
                            calendarType: CalendarDatePicker2Type.range,
                            selectedDayHighlightColor: Colors.deepPurple,
                            selectedRangeHighlightColor: Colors.purpleAccent.withOpacity(0.2),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          ),
                          value: rangeDatePickerOmset,
                          onValueChanged: (dates) {
                            if (dates.length >= 2) {
                              final start = dates[0];
                              final end = dates[1];
                              final diffDays = end.difference(start).inDays.abs();
                              if (diffDays > 6) {
                                final cappedEnd = start.add(const Duration(days: 6));
                                rangeDatePickerOmset.assignAll([start, cappedEnd]);
                                CherryToast.warning(
                                  title: const Text(
                                    "Perhatian!",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  description: const Text("Maksimal 7 hari."),
                                  animationDuration: const Duration(milliseconds: 2000),
                                  autoDismiss: true,
                                ).show(Get.context!);
                                return;
                              }
                            }

                            rangeDatePickerOmset.assignAll(dates);
                            log("Isi Range Date $rangeDatePickerOmset");
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        actions: [
          ElevatedButton(
            onPressed: () async {
              // refreshData();
              if (rangeDatePickerOmset.isEmpty || rangeDatePickerOmset[0] == null) {
                CherryToast.warning(
                  title: const Text(
                    "Perhatian!",
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                  ),
                  description: const Text("Pilih tanggal terlebih dahulu."),
                  animationDuration: const Duration(milliseconds: 2000),
                  autoDismiss: true,
                ).show(Get.context!);
                return;
              }
              String startDate = rangeDatePickerOmset[0].toString().split(" ")[0];
              String endDate = "";
              if (rangeDatePickerOmset.length > 1) {
                endDate = rangeDatePickerOmset[1].toString().split(" ")[0];
              } else {
                endDate = startDate;
              }

              await _getDataTargetHarian(startDate: startDate, endDate: endDate);

              Get.back();
            },
            child: const Text("SUBMIT"),
          ),
        ],
      ),
    ).then((_) {
      scrollTglController.dispose();
      if (rangeDatePickerOmset.isEmpty) {
        _getDataTargetHarian();
      }
    });
  }

  Future<void> _storeDataTarget() async {
    try {
      var response = await dio.post(
        '${myIpAddr()}/main_owner/upsert_target_sales',
        data: {
          "month_number": _startMonthTargetOmset.value,
          "year": _startYearTargetOmset.value,
          "target_omset": _nominalTargetOmset,
        },
      );

      if (response.statusCode == 200) {
        await Future.wait([_getDataTarget(), _getLineChart()]);
        Get.back();

        CherryToast.info(
          title: Text(
            "Success!",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
          ),
          description: Text('Data Target Berhasil Disimpan'),
          animationDuration: const Duration(milliseconds: 2000),
          autoDismiss: true,
        ).show(Get.context!);
      }
    } catch (e) {
      if (e is DioException) {
        CherryToast.error(
          title: Text(
            "Error!",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
          ),
          description: Text('gagal storeDataTarget dioErr'),
          animationDuration: const Duration(milliseconds: 2000),
          autoDismiss: true,
        ).show(Get.context!);
        log("Error di storeDataTarget dio ${e.response!.data}");

        return;
      }

      CherryToast.error(
        title: Text(
          "Error!",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
        ),
        description: Text('gagal storeDataTarget '),
        animationDuration: const Duration(milliseconds: 2000),
        autoDismiss: true,
      ).show(Get.context!);
      log("Error di storeDataTarget $e");
    }
  }

  @override
  void onClose() {
    // TODO: implement onClose
    _monthlySales.close();
    _paketSales.close();
    _produkSales.close();
    try {
      _selectedTahun.close();
    } catch (_) {}
    try {
      _startMonth.close();
    } catch (_) {}
    try {
      _startYear.close();
    } catch (_) {}
    try {
      _endMonth.close();
    } catch (_) {}
    try {
      _endYear.close();
    } catch (_) {}
    try {
      _startMonthTargetOmset.close();
    } catch (_) {}
    try {
      _startYearTargetOmset.close();
    } catch (_) {}
    try {
      _endMonthTargetOmset.close();
    } catch (_) {}
    try {
      _endYearTargetOmset.close();
    } catch (_) {}
    super.onClose();
  }
}
