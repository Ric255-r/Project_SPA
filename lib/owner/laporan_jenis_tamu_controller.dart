import 'dart:developer';
import 'dart:io';

import 'package:Project_SPA/function/ip_address.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';

class LaporanJenisTamuController extends GetxController {
  ScrollController scrollTglController = ScrollController();
  final dio = Dio();
  RxList laporanJenisTamu = <Map<String, dynamic>>[].obs;
  RxList<DateTime?> rangeDatePickerTamu = <DateTime?>[].obs;
  ScrollController laporanScrollController = ScrollController();
  final List<String> listJenisPilihan = const ['Showing', 'Pilih Bawah', 'Request', 'Rolling'];
  final RxnString selectedJenisPilihan = RxnString();
  final RxnString selectedStatus = RxnString();

  Future<void> getDataLaporanJenisTamu() async {
    try {
      var response = await dio.get(
        '${myIpAddr()}/laporan_jenis_tamu',
        queryParameters: {
          "start_date": formatDate(rangeDatePickerTamu[0], format: 'yyyy-MM-dd'),
          "end_date":
              rangeDatePickerTamu.length > 1
                  ? formatDate(rangeDatePickerTamu[1], format: 'yyyy-MM-dd')
                  : formatDate(rangeDatePickerTamu[0], format: 'yyyy-MM-dd'),
        },
      );

      if (response.statusCode == 200) {
        laporanJenisTamu.assignAll(List<Map<String, dynamic>>.from(response.data));

        log("Isi Laporan Jenis Tamu $laporanJenisTamu");
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception("Gagal di Dio ${e.response!.data}");
      }

      throw Exception("Error Get Data Laporan Jenis Tamu $e");
    }
  }

  Future<void> downloadLaporanJenisTamu() async {
    if (rangeDatePickerTamu.isEmpty) {
      CherryToast.info(
        title: const Text("Informasi"),
        description: const Text("Harap memilih tanggal terlebih dahulu"),
      ).show(Get.context!);
      return;
    }

    _showDownloadLoading();

    final startDate = formatDate(rangeDatePickerTamu[0], format: 'yyyy-MM-dd');
    final endDate =
        rangeDatePickerTamu.length > 1 ? formatDate(rangeDatePickerTamu[1], format: 'yyyy-MM-dd') : startDate;

    final fileName = 'laporan_jenis_tamu_${startDate}_$endDate.pdf';
    final savePath = '${Directory.systemTemp.path}/$fileName';

    try {
      await dio.download(
        '${myIpAddr()}/laporan_jenis_tamu/export_excel',
        savePath,
        queryParameters: {"start_date": startDate, "end_date": endDate},
      );

      log("Laporan jenis tamu diunduh ke $savePath");
      await OpenFile.open(savePath);
    } catch (e) {
      if (e is DioException) {
        Get.back();
        throw Exception("Gagal mengunduh laporan: ${e.response?.data ?? e.message}");
      }
      Get.back();
      throw Exception("Error download laporan jenis tamu: $e");
    }

    Get.back(); // close loading
  }

  String formatDate(dynamic dateStr, {String format = 'dd/MM/yyyy'}) {
    if (dateStr == null || dateStr.toString().isEmpty) return '';

    try {
      final parsedDate = DateTime.parse(dateStr.toString());
      return DateFormat(format).format(parsedDate);
    } catch (e) {
      return '';
    }
  }

  void showDialogTgl() {
    rangeDatePickerTamu.clear();

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
                      "Petunjuk : Anda bisa memilih lebih dari 1 Tanggal",
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
                          value: rangeDatePickerTamu,
                          onValueChanged: (dates) async {
                            rangeDatePickerTamu.assignAll(dates);
                            await getDataLaporanJenisTamu();

                            log("Isi Range Date Tamu $rangeDatePickerTamu");
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
            onPressed: () {
              Get.back();
            },
            child: const Text("SUBMIT"),
          ),
        ],
      ),
    ).then((_) {
      if (rangeDatePickerTamu.isEmpty) {
        // refreshData();
      }
    });
  }

  @override
  void onInit() {
    super.onInit();
  }

  void _showDownloadLoading() {
    Get.dialog(
      WillPopScope(onWillPop: () async => false, child: const Center(child: CircularProgressIndicator())),
      barrierDismissible: false,
    );
  }
}
