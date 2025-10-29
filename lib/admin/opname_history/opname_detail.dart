// opname_detail.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:Project_SPA/function/ip_address.dart';

class OpnameDetailController extends GetxController {
  final dio = Dio();

  final int opnameId;
  OpnameDetailController(this.opnameId);

  final RxMap<String, dynamic> header = <String, dynamic>{}.obs;
  final RxList<Map<String, dynamic>> details = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  String get _base => myIpAddr().replaceAll(RegExp(r"/$"), "");
  String _ts() => DateTime.now().millisecondsSinceEpoch.toString();

  Options get _noCache => Options(headers: const {
    'Cache-Control': 'no-cache, no-store, must-revalidate',
    'Pragma': 'no-cache',
    'Expires': '0',
  });

  @override
  void onInit() {
    super.onInit();
    fetchDetail();
  }

  String fmtDate(dynamic v) {
    try {
      if (v == null) return '-';
      if (v is String) {
        final dt = DateTime.tryParse(v);
        if (dt != null) return DateFormat('dd/MM/yyyy HH:mm').format(dt);
        return v;
      }
      if (v is DateTime) {
        return DateFormat('dd/MM/yyyy HH:mm').format(v);
      }
    } catch (_) {}
    return v?.toString() ?? '-';
  }

  Future<void> fetchDetail() async {
    isLoading.value = true;
    try {
      final res = await dio.get(
        '$_base/opname/getdetail',
        queryParameters: {'opname_id': opnameId, '_ts': _ts()},
        options: _noCache,
      );
      if (res.data is Map) {
        final m = Map<String, dynamic>.from(res.data);
        header.assignAll(m['header'] ?? {});
        final d = m['details'];
        if (d is List) {
          details.assignAll(List<Map<String, dynamic>>.from(d));
        } else {
          details.clear();
        }
      } else {
        header.clear();
        details.clear();
      }
    } catch (e) {
      final ctx = Get.context;
      if (ctx != null) {
        CherryToast.error(
          title: const Text('Gagal'),
          description: Text('Gagal mengambil detail: $e'),
        ).show(ctx);
      }
    } finally {
      isLoading.value = false;
    }
  }

  int get totalBaris => details.length;
  int get totalDelta => details.fold<int>(0, (a, b) => a + (int.tryParse('${b['perubahan']}') ?? 0));
}

class OpnameDetailPage extends StatelessWidget {
  final int opnameId;
  OpnameDetailPage({super.key, required this.opnameId});

  late final OpnameDetailController c = Get.put(OpnameDetailController(opnameId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      appBar: AppBar(
        title: Text('Detail Opname #$opnameId', style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: const Color(0xFFFFE0B2),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () async => c.fetchDetail(),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (c.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (c.header.isEmpty) {
            return const Center(child: Text('Data tidak ditemukan'));
          }

          final h = c.header;
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _headerCard(h),
                const SizedBox(height: 12),
                _summaryBar(),
                const SizedBox(height: 8),
                Expanded(child: _detailTable()),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _headerCard(Map<String, dynamic> h) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tanggal: ${c.fmtDate(h['tanggal'])}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Catatan: ${h['note'] ?? '-'}'),
            const SizedBox(height: 4),
            Text('Opname ID: ${h['id']}'),
          ],
        ),
      ),
    );
  }

  Widget _summaryBar() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Obx(() => Row(
          children: [
            const Icon(Icons.list_alt),
            const SizedBox(width: 8),
            Text('Baris: ${c.totalBaris}'),
            const SizedBox(width: 16),
            Text('Total Δ Stok: ${c.totalDelta}'),
          ],
        )),
      ),
    );
  }

  Widget _detailTable() {
    final rows = c.details;
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
            DataColumn(label: Text('Stok Awal')),
            DataColumn(label: Text('Perubahan')),
            DataColumn(label: Text('Stok Akhir')),
            DataColumn(label: Text('Waktu')),
          ],
          rows: List<DataRow>.generate(rows.length, (i) {
            final r = rows[i];
            return DataRow(cells: [
              DataCell(Text('${i + 1}')),
              DataCell(Text('${r['nama'] ?? ''}')),
              DataCell(Text('${r['satuan'] ?? ''}')),
              DataCell(Text('${r['stok_awal'] ?? 0}')),
              DataCell(Text('${r['perubahan'] ?? 0}')),
              DataCell(Text('${r['stok_akhir'] ?? 0}')),
              DataCell(Text(DateFormat('dd/MM/yyyy HH:mm').format(
                DateTime.tryParse('${r['created_at']}') ?? DateTime.now(),
              ))),
            ]);
          }),
        ),
      ),
    );
  }
}
