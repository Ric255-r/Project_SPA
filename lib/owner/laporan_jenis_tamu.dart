import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'laporan_jenis_tamu_controller.dart';

class LaporanJenisTamu extends StatelessWidget {
  LaporanJenisTamu({super.key});

  final c = Get.put(LaporanJenisTamuController());
  static const bg = Color(0xFFFFE0B2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 30,
        centerTitle: true,
        backgroundColor: bg,
        title: Text(
          'Laporan Jenis Tamu',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 40, right: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),

              Row(
                children: [
                  Text("Pilih Periode"),
                  SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () {
                      c.showDialogTgl();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text("Pilih", style: TextStyle(height: 1)),
                  ),
                ],
              ),

              SizedBox(height: 10),

              Obx(() {
                String teks = "";
                List<dynamic> rangeDate = c.rangeDatePickerTamu;
                if (rangeDate.isNotEmpty) {
                  String startDate = rangeDate[0].toString().split(" ")[0];
                  teks += "Tanggal Mulai: ${c.formatDate(startDate, format: "dd-MM-yyyy")} ";
                  if (rangeDate.length == 2) {
                    String endDate = rangeDate[1].toString().split(" ")[0];
                    teks += "| Tanggal Akhir: ${c.formatDate(endDate, format: "dd-MM-yyyy")}";
                  }
                }

                if (c.rangeDatePickerTamu.isEmpty) {
                  return SizedBox.shrink();
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(teks),
                    Container(
                      constraints: BoxConstraints(minWidth: 0, maxWidth: double.infinity),
                      alignment: Alignment.centerRight,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: () {
                            Get.dialog(
                              AlertDialog(
                                title: const Text("Cetak Laporan"),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "Lewati Filter jika ingin mencetak semua transaksi",
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      Obx(
                                        () => DropdownButtonFormField<String>(
                                          value: c.selectedStatus.value,
                                          decoration: const InputDecoration(labelText: "Status Transaksi"),
                                          items: const [
                                            DropdownMenuItem(value: 'unpaid', child: Text('Belum Lunas')),
                                            DropdownMenuItem(value: 'paid_done', child: Text('Lunas')),
                                            DropdownMenuItem(value: 'void', child: Text('VOID')),
                                          ],
                                          onChanged: (val) => c.selectedStatus.value = val,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Obx(
                                        () => DropdownButtonFormField<String>(
                                          value: c.selectedJenisPilihan.value,
                                          decoration: const InputDecoration(
                                            labelText: "Pilih Jenis Pilihan Tamu",
                                          ),
                                          items:
                                              c.listJenisPilihan
                                                  .map(
                                                    (e) => DropdownMenuItem<String>(value: e, child: Text(e)),
                                                  )
                                                  .toList(),
                                          onChanged: (val) => c.selectedJenisPilihan.value = val,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
                                  ElevatedButton(
                                    onPressed: () {
                                      Get.back();
                                      c.downloadLaporanJenisTamu();
                                    },
                                    child: const Text("Download"),
                                  ),
                                ],
                              ),
                            ).then((_) {
                              c.selectedJenisPilihan.value = null;
                              c.selectedStatus.value = null;
                            });
                          },
                          child: Text(
                            "Cetak Laporan",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                              fontSize: 15,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),

              SizedBox(height: 20),

              DefaultTabController(
                length: 3,
                initialIndex: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Material(
                      color: Colors.white,
                      child: TabBar(
                        labelColor: Colors.deepPurple,
                        unselectedLabelColor: Colors.black54,
                        indicatorColor: Colors.deepPurple,
                        tabs: const [Tab(text: "Umum"), Tab(text: "VIP"), Tab(text: "Member")],
                      ),
                    ),
                    SizedBox(
                      height: 500,
                      child: Container(
                        color: Colors.white,
                        child: TabBarView(
                          children: const [
                            _TransactionsList(jenis: "Umum"),
                            _TransactionsList(jenis: "VIP"),
                            _TransactionsList(jenis: "Member"),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionsList extends StatelessWidget {
  final String jenis;
  const _TransactionsList({required this.jenis});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LaporanJenisTamuController>();
    final idr = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Obx(() {
      if (controller.rangeDatePickerTamu.isEmpty) {
        return const Center(child: Text("Harap Memilih Tanggal Terlebih Dahulu"));
      }

      final data =
          controller.laporanJenisTamu
              .where((e) => (e['jenis_tamu'] ?? '').toString().toLowerCase() == jenis.toLowerCase())
              .toList();

      if (data.isEmpty) {
        return const Center(child: Text("Data tidak tersedia"));
      }

      final total = data.fold<num>(0, (sum, item) {
        final val = _toNum(item['gtotal_stlh_pajak']);
        return val != null ? sum + val : sum;
      });

      final countTransaction = data.length;

      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Jenis Tamu: $jenis", style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    "Total Transaksi:  ${idr.format(total)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Jumlah Transaksi: $countTransaction",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                controller: controller.laporanScrollController,
                child: ListView.separated(
                  controller: controller.laporanScrollController,
                  itemCount: data.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = data[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${index + 1}."),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Id Transaksi: ${item['id_transaksi'] ?? '-'}",
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),
                                  Text("Jenis Transaksi: ${item['jenis_transaksi'] ?? '-'}"),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Total Transaksi (Setelah Disc): ${_formatIdr(idr, item['gtotal_stlh_pajak'])}",
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

num? _toNum(dynamic value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '');
}

String _formatIdr(NumberFormat idr, dynamic value) {
  final num? parsed = _toNum(value);
  return parsed != null ? idr.format(parsed) : '-';
}
