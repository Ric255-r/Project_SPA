import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:Project_SPA/owner/download_splash.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:Project_SPA/function/ip_address.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

// NOTE: pastikan kamu sudah punya widget ini seperti di template komisi:
// import 'package:Project_SPA/widgets/download_splash.dart'; // contoh
// class DownloadSplash extends StatelessWidget { ... }

class OpnameReportController extends GetxController {
  final dio = Dio();

  final dateStart = Rxn<DateTime>();
  final dateEnd = Rxn<DateTime>();

  final RxBool isGenerating = false.obs;
  final RxBool isExporting = false.obs;
  final RxList<Map<String, dynamic>> rows = <Map<String, dynamic>>[].obs;

  String get _base => myIpAddr().replaceAll(RegExp(r"/$"), "");
  String _ts() => DateTime.now().millisecondsSinceEpoch.toString();

  Options get _noCache => Options(
    headers: const {
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    },
  );

  String fmtDate(DateTime? d) => d == null ? '-' : DateFormat('dd/MM/yyyy').format(d);
  String _yyyymmdd(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<void> pickStart(BuildContext ctx) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: ctx,
      initialDate: dateStart.value ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) dateStart.value = picked;
  }

  Future<void> pickEnd(BuildContext ctx) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: ctx,
      initialDate: dateEnd.value ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) dateEnd.value = picked;
  }

  Future<void> generate() async {
    final ctx = Get.context;
    if (dateStart.value == null || dateEnd.value == null) {
      if (ctx != null) {
        CherryToast.warning(
          title: const Text('Validasi'),
          description: const Text('Pilih tanggal mulai & akhir terlebih dahulu.'),
        ).show(ctx);
      }
      return;
    }
    if (dateStart.value!.isAfter(dateEnd.value!)) {
      if (ctx != null) {
        CherryToast.warning(
          title: const Text('Validasi'),
          description: const Text('Tanggal mulai tidak boleh setelah tanggal akhir.'),
        ).show(ctx);
      }
      return;
    }

    isGenerating.value = true;
    rows.clear();

    try {
      final res = await dio.get(
        '$_base/opname/gethistory',
        queryParameters: {'limit': 1000, 'offset': 0, '_ts': _ts()},
        options: _noCache,
      );
      final List all = (res.data is List) ? res.data : [];

      final start = DateTime(dateStart.value!.year, dateStart.value!.month, dateStart.value!.day, 0, 0, 0);
      final end = DateTime(dateEnd.value!.year, dateEnd.value!.month, dateEnd.value!.day, 23, 59, 59);

      final filteredIds = <int>[];
      for (final e in all) {
        final m = Map<String, dynamic>.from(e);
        final id = int.tryParse('${m['id']}');
        final tStr = '${m['tanggal']}';
        final t = DateTime.tryParse(tStr);
        if (id != null && t != null && !t.isBefore(start) && !t.isAfter(end)) {
          filteredIds.add(id);
        }
      }

      final agg = <String, Map<String, dynamic>>{};
      for (final id in filteredIds) {
        final det = await dio.get(
          '$_base/opname/getdetail',
          queryParameters: {'opname_id': id, '_ts': _ts()},
          options: _noCache,
        );
        if (det.data is! Map) continue;
        final details = det.data['details'];
        if (details is! List) continue;

        for (final r in details) {
          final m = Map<String, dynamic>.from(r);
          final nama = (m['nama'] ?? '').toString();
          final satuan = (m['satuan'] ?? '').toString();
          final sumber = (m['sumber'] ?? '').toString();
          final perubahan = int.tryParse('${m['perubahan'] ?? 0}') ?? 0;

          final key = '$nama|$satuan|$sumber';
          agg.putIfAbsent(
            key,
            () => {'nama': nama, 'satuan': satuan, 'sumber': sumber, 'plus': 0, 'minus': 0, 'net': 0},
          );

          if (perubahan >= 0) {
            agg[key]!['plus'] = (agg[key]!['plus'] as int) + perubahan;
          } else {
            agg[key]!['minus'] = (agg[key]!['minus'] as int) + (-perubahan);
          }
          agg[key]!['net'] = (agg[key]!['net'] as int) + perubahan;
        }
      }

      final out = agg.values.toList()..sort((a, b) => a['nama'].toString().compareTo(b['nama'].toString()));
      rows.assignAll(out);

      if (ctx != null) {
        CherryToast.success(
          title: const Text('Laporan Siap'),
          description: Text(
            'Periode ${fmtDate(dateStart.value)} s.d. ${fmtDate(dateEnd.value)}\n'
            'Jumlah item: ${rows.length}',
          ),
        ).show(ctx);
      }
    } catch (e) {
      if (ctx != null) {
        CherryToast.error(
          title: const Text('Gagal'),
          description: Text('Gagal membuat laporan: $e'),
        ).show(ctx);
      }
    } finally {
      isGenerating.value = false;
    }
  }

  // =========================
  // EXPORT EXCEL ala template exportkomisitahunan(...)
  // =========================
  Future<void> exportOpnamePdf(DateTime start, DateTime end) async {
    try {
      Get.dialog(const DownloadSplash(), barrierDismissible: false);

      final downloadsDir = await getDownloadsDirectory();
      final dirPath = downloadsDir!.path;
      final startStr = _yyyymmdd(start);
      final endStr = _yyyymmdd(end);
      final filepath = '$dirPath/Laporan_Opname_$startStr sampai $endStr.pdf';

      final url = '${myIpAddr()}/main_owner/export_excel_stok_opname';

      final response = await dio.download(
        url,
        filepath,
        queryParameters: {
          'start_date': startStr, // <-- sesuaikan dgn backend
          'end_date': endStr,
          // 'sumber': 'barang' // opsional
        },
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': 'application/pdf'}, // <-- minta PDF
        ),
      );

      Get.back();
      await OpenFile.open(filepath);
      log('PDF downloaded to $filepath  (status: ${response.statusCode})');
    } catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      log("Error di exportOpnamePdf : $e");
      CherryToast.error(
        title: const Text("Download Failed"),
        description: const Text("Gagal menyiapkan file PDF opname"),
      ).show(Get.context!);
    }
  }
}

class OpnameReportPage extends StatelessWidget {
  OpnameReportPage({super.key});

  final c = Get.put(OpnameReportController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDE7),
      appBar: AppBar(
        title: const Text('Laporan Stok Opname', style: TextStyle(fontFamily: 'Poppins')),
        backgroundColor: const Color(0xFFFFE0B2),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [_filterBar(context), const SizedBox(height: 12), Expanded(child: _reportTable())],
          ),
        ),
      ),
    );
  }

  Widget _filterBar(BuildContext ctx) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Obx(
          () => Row(
            children: [
              Expanded(
                child: ListTile(
                  title: const Text('Tanggal Mulai'),
                  subtitle: Text(c.fmtDate(c.dateStart.value)),
                  leading: const Icon(Icons.date_range),
                  onTap: () => c.pickStart(ctx),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ListTile(
                  title: const Text('Tanggal Akhir'),
                  subtitle: Text(c.fmtDate(c.dateEnd.value)),
                  leading: const Icon(Icons.event),
                  onTap: () => c.pickEnd(ctx),
                ),
              ),
              const SizedBox(width: 8),
              // Tombol Generate
              ElevatedButton.icon(
                onPressed: c.isGenerating.value ? null : () => c.generate(),
                icon:
                    c.isGenerating.value
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.assessment),
                label: const Text('Generate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6D4C41),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 8),
              // Tombol Cetak Laporan (Excel) — panggil exportOpnameExcel ala template
              ElevatedButton.icon(
                onPressed:
                    (c.isGenerating.value || c.isExporting.value)
                        ? null
                        : () {
                          final ds = c.dateStart.value;
                          final de = c.dateEnd.value;
                          if (ds == null || de == null) {
                            CherryToast.warning(
                              title: const Text('Validasi'),
                              description: const Text('Pilih tanggal mulai & akhir terlebih dahulu.'),
                            ).show(Get.context!);
                            return;
                          }
                          c.exportOpnamePdf(ds, de);
                        },
                icon:
                    c.isExporting.value
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.file_download_outlined),
                label: const Text('Cetak Laporan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reportTable() {
    return Obx(() {
      if (c.isGenerating.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (c.rows.isEmpty) {
        return const Center(child: Text('Belum ada data. Pilih periode lalu tekan Generate.'));
      }

      final data = c.rows;
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingTextStyle: const TextStyle(fontWeight: FontWeight.bold),
            columns: const [
              DataColumn(label: Text('No')),
              DataColumn(label: Text('Nama')),
              DataColumn(label: Text('Satuan')),
              DataColumn(label: Text('Penambahan')),
              DataColumn(label: Text('Pengurangan')),
              DataColumn(label: Text('Net Δ')),
            ],
            rows: List<DataRow>.generate(data.length, (i) {
              final r = data[i];
              return DataRow(
                cells: [
                  DataCell(Text('${i + 1}')),
                  DataCell(Text('${r['nama']}')),
                  DataCell(Text('${r['satuan']}')),
                  DataCell(Text('${r['plus']}')),
                  DataCell(Text('${r['minus']}')),
                  DataCell(Text('${r['net']}')),
                ],
              );
            }),
          ),
        ),
      );
    });
  }
}
