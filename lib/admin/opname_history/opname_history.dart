// opname_history.dart
import 'package:Project_SPA/function/admin_drawer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:Project_SPA/function/ip_address.dart';

import 'opname_detail.dart';
import 'opname_report.dart';

class OpnameHistoryController extends GetxController {
  final dio = Dio();

  final RxList<Map<String, dynamic>> headers = <Map<String, dynamic>>[].obs;

  final RxBool isLoading = false.obs;
  final RxInt limit = 20.obs;
  final RxInt offset = 0.obs;
  final RxBool canNext = false.obs;
  final RxBool canPrev = false.obs;
  final RxInt totalShown = 0.obs;

  String get _base => myIpAddr().replaceAll(RegExp(r"/$"), "");
  String _ts() => DateTime.now().millisecondsSinceEpoch.toString();

  Options get _noCache => Options(
    headers: const {
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    },
  );

  @override
  void onInit() {
    super.onInit();
    fetchPage();
  }

  Future<void> fetchPage() async {
    isLoading.value = true;
    try {
      final res = await dio.get(
        '$_base/opname/gethistory',
        queryParameters: {'limit': limit.value, 'offset': offset.value, '_ts': _ts()},
        options: _noCache,
      );
      if (res.data is List) {
        final list = List<Map<String, dynamic>>.from(res.data);
        headers.assignAll(list);
        totalShown.value = list.length;
        canPrev.value = offset.value > 0;
        canNext.value = list.length >= limit.value; // sederhana
      } else {
        headers.clear();
        totalShown.value = 0;
        canPrev.value = offset.value > 0;
        canNext.value = false;
      }
    } catch (e) {
      final ctx = Get.context;
      if (ctx != null) {
        CherryToast.error(
          title: const Text('Gagal'),
          description: Text('Gagal memuat History: $e'),
        ).show(ctx);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshPage() async {
    await fetchPage();
  }

  void nextPage() {
    if (!canNext.value) return;
    offset.value += limit.value;
    fetchPage();
  }

  void prevPage() {
    if (!canPrev.value) return;
    offset.value = (offset.value - limit.value).clamp(0, 1 << 30);
    fetchPage();
  }

  String fmtDate(dynamic v) {
    // backend kolom 'tanggal' sudah datetime/str
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
}

class OpnameHistoryPage extends StatelessWidget {
  OpnameHistoryPage({super.key});

  final c = Get.put(OpnameHistoryController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE0B2),
      appBar: AppBar(
        title: const Text('History Stok Opname', style: TextStyle(fontFamily: 'Poppins', fontSize: 24)),
        backgroundColor: const Color(0xFFFFE0B2),
        actions: [
          IconButton(
            tooltip: 'Laporan Periode',
            icon: const Icon(Icons.assessment_outlined),
            onPressed: () => Get.to(() => OpnameReportPage()),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () async => c.refreshPage(),
          ),
        ],
      ),
      drawer: AdminDrawer(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [_pagerBar(), const SizedBox(height: 8), Expanded(child: _historyList())]),
        ),
      ),
    );
  }

  Widget _pagerBar() {
    return Obx(
      () => Row(
        children: [
          Text(
            'Offset: ${c.offset.value}  •  Limit: ${c.limit.value}  •  Tampil: ${c.totalShown.value}',
            style: const TextStyle(color: Colors.brown),
          ),
          const Spacer(),
          IconButton(
            onPressed: c.canPrev.value ? c.prevPage : null,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Sebelumnya',
          ),
          IconButton(
            onPressed: c.canNext.value ? c.nextPage : null,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Berikutnya',
          ),
        ],
      ),
    );
  }

  Widget _historyList() {
    return Obx(() {
      if (c.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (c.headers.isEmpty) {
        return const Center(child: Text('Belum ada History opname.'));
      }

      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: ListView.separated(
          itemCount: c.headers.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final h = c.headers[i];
            final id = h['id'];
            final tanggal = c.fmtDate(h['tanggal']);
            final note = h['note'] ?? '';
            final jBaris = h['jumlah_baris'] ?? 0;
            final delta = h['total_delta'] ?? 0;

            return ListTile(
              leading: CircleAvatar(child: Text('${i + 1}')),
              title: Text('Opname #$id • $tanggal', style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                'Baris: $jBaris • Δ Stok: $delta${delta is num ? "" : ""}'
                '${note.toString().trim().isEmpty ? "" : " • Catatan: $note"}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Get.to(() => OpnameDetailPage(opnameId: id)),
            );
          },
        ),
      );
    });
  }
}
