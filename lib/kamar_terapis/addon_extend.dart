import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:Project_SPA/function/ip_address.dart';
import 'package:Project_SPA/function/token.dart';
import 'package:Project_SPA/kamar_terapis/terapis_bekerja.dart';
import 'package:Project_SPA/kamar_terapis/terapis_mgr.dart';

class ExtendAddOnController extends GetxController {
  final String idDetailTransaksi;

  ExtendAddOnController({required this.idDetailTransaksi}) {
    // fungsiny kek initstate jadinya
    fetchDataPaketExtend();
  }

  ScrollController _scrollController = ScrollController();

  var dio = Dio();

  RxList<Map<String, dynamic>> _listPaketExtend = <Map<String, dynamic>>[].obs;

  Future<void> fetchDataPaketExtend() async {
    try {
      final response = await dio.get('${myIpAddr()}/extend/datapaketextend');

      // Ensure it's a list
      final List data = response.data as List;

      // Convert and update the observable list
      _listPaketExtend.assignAll(
        data.map((item) {
          return {
            "id_paket_extend": item['id_paket_extend'],
            "nama_paket_extend": item['nama_paket_extend'],
            "durasi_extend": item['durasi_extend'],
            "harga_extend": item['harga_extend'],
            "komisi_terapis": item['komisi_terapis'],
          };
        }).toList(),
      );
    } catch (e) {
      log("Error di fn Getdatapaketextend: $e");
    }
  }

  // Add these new variables utk penambahan data
  RxList<dynamic> _selectedListPaket = [].obs;
  RxList<dynamic> _selectedListProduk = [].obs;
  RxInt _extendTimer = 0.obs;
  RxInt _extendQty = 0.obs;
  TextEditingController _txtTimer = TextEditingController(text: "0");

  // Nampung yg kepilih sementara
  Rx<Map<String, dynamic>?> _tempSelectedItem = Rx<Map<String, dynamic>?>(null);
  RxBool _isItemConfirmed = false.obs;

  // Add these methods. Jgn d hapus
  // void selectItem(Map<String, dynamic> item) {
  //   _tempSelectedItem.value = item;
  //   _isItemConfirmed.value = false;

  //   // _txtTimer.text = _extendTimer.value.toString();
  //   _txtTimer.text = _extendQty.value.toString();
  // }

  // versi clean code. komen dlu krn ubah alur jd g kepake. jgn d hapus
  // void confirmSelection() {
  //   if (_tempSelectedItem.value == null) return;

  //   final item = {
  //     ..._tempSelectedItem.value!,
  //     "qty": _extendQty.value,
  //     "harga_total": _extendQty.value * _tempSelectedItem.value!['harga_extend'],
  //     "is_returned": 0,
  //     "extended_duration": _extendQty.value * _tempSelectedItem.value!['durasi_extend'],
  //     // "extended_duration": _extendTimer.value,
  //   };

  //   final isPaket = item['type'] == 'paket';
  //   final targetList = isPaket ? _selectedListPaket : _selectedListProduk;
  //   final idKey = isPaket ? 'id_paket' : 'id_produk';

  //   final exists = targetList.indexWhere((el) => el[idKey] == item[idKey]);

  //   if (exists != -1) {
  //     final existing = targetList[exists];
  //     // awal
  //     // final plusDuration = existing['extended_duration'] + _extendTimer.value;
  //     // final plusQty = (plusDuration / existing['durasi_awal']).toInt();
  //     // end awal
  //     final plusQty = existing['qty'] + _extendQty.value;
  //     final plusDuration = plusQty * existing['extended_duration'];

  //     targetList[exists] = {...existing, "qty": plusQty, "harga_total": existing['harga_extend'] * plusQty, "extended_duration": plusDuration};

  //     // Force update for GetX reactivity, krna update key saja ga work, triggernya adlh add / remove
  //     if (isPaket) {
  //       _selectedListPaket.assignAll([..._selectedListPaket]);
  //     } else {
  //       _selectedListProduk.assignAll([..._selectedListProduk]);
  //     }
  //   } else {
  //     targetList.add(item);
  //   }

  //   resetButton();
  //   _scrollToSection();

  //   log("Selected Paket: $_selectedListPaket");
  //   log("Selected Produk: $_selectedListProduk");
  // }
  // End Jgn dihapus

  void removeSelection(String mode, String isiId) {
    bool isPaket = mode == "paket";

    var targetList = isPaket ? _selectedListPaket : _selectedListProduk;
    var idKey = isPaket ? "id_paket" : "id_produk";

    var existsIdx = targetList.indexWhere((item) => item[idKey] == isiId);

    if (existsIdx != -1) {
      targetList.removeAt(existsIdx);
    }
  }

  RxInt _sumDurasiMenit = 0.obs;

  KamarTerapisMgr _kamarTerapisMgr = KamarTerapisMgr();

  Future<void> _storeAddOn() async {
    try {
      String idTrans = _kamarTerapisMgr.getData()['idTransaksi'];
      var response = await dio.post(
        '${myIpAddr()}/extend/save_addon',
        data: {
          "id_transaksi": idTrans,
          // "id_detail_transaksi": idDetailTransaksi,
          "detail_paket": _selectedListPaket,
        },
      );

      if (response.statusCode == 200) {
        await _kamarTerapisMgr.updateDataProdukPaket(idTrans);
        Get.offAll(() => TerapisBekerja());
      }
    } catch (e) {
      log("Error di ${e}");
    }
  }

  final GlobalKey _detailHarga = GlobalKey();

  void _scrollToSection() {
    final context = _detailHarga.currentContext;
    if (context != null) {
      // kalkulasi posisi widget
      Scrollable.ensureVisible(
        context,
        duration: Duration(seconds: 1), // smooth scrolling
        curve: Curves.easeInOut,
      );
    }
  }

  void resetButton() {
    _isItemConfirmed.value = true;
    _tempSelectedItem.value = null;
    _extendTimer.value = 0;
    _txtTimer.text = "0";
    _extendQty.value = 0;
  }

  String idMember = '';
  RxList<Map<String, dynamic>> _activePromos = <Map<String, dynamic>>[].obs;

  // Future<void> getidmember() async {
  //   String idTransaksi = _kamarTerapisMgr.getData()['idTransaksi'];
  //   var idmemberresponse = await dio.get(

  //     '${myIpAddr()}/kamar_terapis/getidmember',
  //     data: {"id_transaksi": idTransaksi},
  //   );
  //   idMember = idmemberresponse.data[0]['id_member'];
  // }

  Future<void> _checkMemberPromos(String id_member) async {
    try {
      var response = await dio.get('${myIpAddr()}/history/historymember/$id_member');
      final now = DateTime.now();

      _activePromos.assignAll(
        (response.data as List)
            .where((promo) {
              final expKunjungan = promo['exp_kunjungan'];
              if (expKunjungan != null && expKunjungan.isNotEmpty) {
                final expDate = DateTime.tryParse(expKunjungan);
                if (expDate != null) {
                  return expDate.isAfter(now); // Only include if not expired
                }
              }
              return false; // Skip invalid or expired promo
            })
            .map((promo) {
              return {
                'kode_promo': promo['kode_promo'],
                'nama_promo': promo['nama_promo'],
                'nama_paket_msg': promo['nama_paket_msg'],
                'sisa_kunjungan': promo['sisa_kunjungan'],
                'exp_kunjungan': promo['exp_kunjungan'],
                'exp_tahunan': promo['exp_tahunan'],
              };
            })
            .toList(),
      );
    } catch (e) {
      log("Error checking member promos: $e");
    }
  }

  @override
  void onInit() {
    super.onInit();
    // getidmember().then((_) {});
    // log('id member : $idMember');
    // Future.delayed(Duration(seconds: 1), () {
    //   _checkMemberPromos(idMember);
    // });
  }

  @override
  void onClose() {
    // TODO: implement onClose
    _scrollController.dispose();
    _txtTimer.dispose();
    super.onClose();
  }
}

class ExtendAddOn extends StatelessWidget {
  // Parameter utk d passing ke Controller
  final String idDetailTransaksi;
  // Constructor Stless
  ExtendAddOn({super.key, required this.idDetailTransaksi}) {
    Get.put(ExtendAddOnController(idDetailTransaksi: idDetailTransaksi));
  }
  int displayPrice = 0;
  int displayPrice2 = 0;
  int displayDurasi = 0;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ExtendAddOnController>();

    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text("Add On (+)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40, fontFamily: 'Poppins'))),
        backgroundColor: Color(0XFFFFE0B2),
      ),
      body: PopScope(
        canPop: true,
        onPopInvoked: (didPop) {
          if (didPop) print("Ngepop nah");
          c.resetButton();
          c._selectedListPaket.clear();
          c._selectedListProduk.clear();
        },
        child: Container(
          height: Get.height,
          width: Get.width,
          padding: const EdgeInsets.only(left: 80, right: 80),
          decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                Text("Pilih Paket Yang Ingin DI Extend", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'Poppins')),
                SizedBox(height: 30),
                Container(
                  height: 300,
                  child: Scrollbar(
                    thumbVisibility: true,
                    controller: c._scrollController,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Obx(
                        () => GridView.builder(
                          controller: c._scrollController,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3, // 3 item 1 row
                            crossAxisSpacing: 50, // space horizontal tiap item
                            mainAxisSpacing: 20, // space vertical tiap item

                            childAspectRatio: 25 / 14,
                          ),
                          itemCount: c._listPaketExtend.length,
                          itemBuilder: (context, index) {
                            final item = c._listPaketExtend[index];
                            RxBool _isTapped = false.obs;
                            displayPrice = int.parse(item['harga_extend'].toString());

                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapDown: (_) async {
                                _isTapped.value = true;

                                displayPrice = int.parse(item['harga_extend'].toString());
                                displayDurasi = int.parse(item['durasi_extend'].toString());

                                log('price : $displayPrice');
                                log('durasi : $displayDurasi');
                              },
                              onTapUp: (_) async {
                                await Future.delayed(const Duration(milliseconds: 100));
                                _isTapped.value = false;

                                final harga = int.tryParse(item['harga_extend'].toString()) ?? 0;
                                final durasi = item['durasi_extend'] ?? 0;

                                // Clear any previous selections
                                c._selectedListPaket.clear();

                                // Add only the selected item
                                c._selectedListPaket.add({
                                  'id_paket': item['id_paket_extend'],
                                  'nama_paket_extend': item['nama_paket_extend'],
                                  'qty': 1,
                                  'durasi_extend': durasi,
                                  'hrg_item': harga,
                                  'harga_total': harga,
                                });

                                // Optionally set default timer/qty
                                if (c._extendQty.value == 0) {
                                  c._extendQty.value = 1;
                                  c._txtTimer.text = c._extendQty.value.toString();
                                }

                                log("Isi selectedPaket ${c._selectedListPaket}");
                              },

                              onTapCancel: () {
                                _isTapped.value = false;
                              },
                              child: Obx(
                                () => Transform.scale(
                                  scale: _isTapped.isTrue ? 0.82 : 1.0,
                                  child: Container(
                                    decoration: BoxDecoration(color: const Color.fromARGB(255, 64, 97, 55), borderRadius: BorderRadius.circular(20)),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(item['type'] == "paket" ? Icons.spa : Icons.shopping_bag, size: 50, color: Colors.white),
                                        Text(item['nama_paket_extend'], style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Poppins')),
                                        Text("Rp. $displayPrice", style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Poppins')),
                                        if (item['durasi_extend'] != null)
                                          Text(
                                            "${item['durasi_extend']} Menit",
                                            style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Poppins'),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20),
                Text("List Pesanan: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'Poppins')),
                Container(
                  height: 200,
                  key: c._detailHarga,
                  child: SingleChildScrollView(
                    child: Obx(() {
                      var totalPaket = 0;
                      for (var i = 0; i < c._selectedListPaket.length; i++) {
                        totalPaket += c._selectedListPaket[i]['harga_total'] as int;
                        c._selectedListPaket[i]['harga_extend'];
                      }

                      return Column(
                        children: [
                          if (c._selectedListPaket.isNotEmpty) ...[
                            for (var item in c._selectedListPaket)
                              Builder(
                                builder: (context) {
                                  final promoExists = c._activePromos.any((promo) => promo['nama_promo'] == item['nama_paket_extend']);
                                  if (promoExists) {
                                    displayPrice2 = 0; // Set display price to 0 if promo applies
                                  } else {
                                    displayPrice2 = int.parse(item['hrg_item'].toString());
                                  }
                                  return Row(
                                    children: [
                                      Expanded(child: Text("${item['nama_paket_extend']}", style: TextStyle(fontFamily: 'Poppins'))),
                                      Expanded(
                                        child: Text(
                                          "${item['qty']} x ${item['durasi_extend']} Menit",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontFamily: 'Poppins'),
                                        ),
                                      ),
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Expanded(child: Text("Rp. $displayPrice2", textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Poppins'))),
                                            Expanded(
                                              child: TextButton(
                                                onPressed: () {
                                                  c.removeSelection("paket", item['id_paket']);
                                                },
                                                child: Text("X", textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Poppins')),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                          ],
                          SizedBox(height: 20),
                          Divider(),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(child: Text("")),
                              Expanded(child: Text("Total Add On: ", textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Poppins'))),
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(child: Text("Rp. ${totalPaket}", textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Poppins'))),
                                    Expanded(child: Text("")),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, minimumSize: Size(100, 40)),
                              onPressed: () async {
                                await c._storeAddOn();
                              },
                              child: Text("Proses", style: TextStyle(color: Colors.black, fontFamily: 'Poppins')),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
