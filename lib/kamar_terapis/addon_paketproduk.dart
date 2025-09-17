import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:Project_SPA/function/ip_address.dart';
import 'package:Project_SPA/function/token.dart';
import 'package:Project_SPA/kamar_terapis/terapis_bekerja.dart';
import 'package:Project_SPA/kamar_terapis/terapis_mgr.dart';
import 'package:Project_SPA/resepsionis/main_resepsionis.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:Project_SPA/resepsionis/store_locker.dart';
import 'package:get_storage/get_storage.dart';

class AddonPaketProdukController extends GetxController {
  final String idTrans;

  AddonPaketProdukController({required this.idTrans}) {
    _getLatestTrans();
  }

  final formatCurrency = new NumberFormat.currency(
    locale: "id_ID",
    decimalDigits: 0,
    symbol: 'Rp. ',
  );

  RxList<Map<String, dynamic>> dataJual = <Map<String, dynamic>>[].obs;

  void addToDataJual(Map<String, dynamic> newItem) {
    final existsIdx = dataJual.indexWhere(
      (item) => item['id_paket_msg'] == newItem['id_paket_msg'],
    );

    if (existsIdx != -1) {
      dataJual[existsIdx]['jlh'] += 1;
      dataJual[existsIdx]['harga_total'] =
          dataJual[existsIdx]['harga_paket_msg'] * dataJual[existsIdx]['jlh'];
    } else {
      dataJual.add({...newItem, 'harga_total': newItem['harga_paket_msg']});
    }

    dataJual.refresh();
  }

  double getHargaBeforeDisc() {
    double total = 0.0;
    for (var item in dataJual) {
      final harga = item['harga_total'] ?? item['harga_fnb'] ?? 0;
      total += (harga is int ? harga.toDouble() : harga);
    }

    return total;
  }

  KamarTerapisMgr _kamarTerapisMgr = KamarTerapisMgr();

  Future<void> _storeTrans() async {
    try {
      var data = {
        "id_transaksi": idTrans,
        "detail_trans": dataJual,
        "status": "unpaid",
        "jenis_pembayaran": true,
      };

      var response = await dio.post(
        '${myIpAddr()}/revisi/tambahpaket_produk',
        data: data,
      );

      if (response.statusCode == 200) {
        await _kamarTerapisMgr.updateDataProdukPaket(idTrans);
        Get.offAll(() => TerapisBekerja());
      }
      log("Isi data jual $data");
    } catch (e) {
      if (e is DioException) {
        log("Error penjelasan storeTrans ${e.response!.data}");
      }
      log("Error fn storeTrans $e");
    }
  }

  var storage = GetStorage();

  @override
  void onClose() {
    // TODO: implement onClose
    dataJual.close();
    _noLoker.close();
    super.onClose();
  }

  var dio = Dio();

  RxInt _noLoker = RxInt(-1);
  Future<void> _getLatestTrans() async {
    try {
      var response = await dio.get(
        '${myIpAddr()}/revisi/transaksi?id_transaksi=${idTrans}',
      );

      Map<String, dynamic> responseData = response.data;
      _noLoker.value = responseData['no_loker'];

      print("Isi no loker ${_noLoker.value}");
    } catch (e) {
      if (e is DioException) {
        log("Error di get latest Trans ${e.response!.data}");
      }

      log("Error $e");
    }
  }

  String idMember = '';
  RxList<Map<String, dynamic>> _activePromos = <Map<String, dynamic>>[].obs;
  RxBool isloadingpromo = true.obs;
  RxList<Map<String, dynamic>> dataproduk = <Map<String, dynamic>>[].obs;

  Future<void> getidmember() async {
    String idTransaksi = _kamarTerapisMgr.getData()['idTransaksi'];
    var idmemberresponse = await dio.get(
      '${myIpAddr()}/kamar_terapis/getidmember',
      data: {"id_transaksi": idTransaksi},
    );
    idMember = idmemberresponse.data[0]['id_member'];
  }

  Future<void> _checkMemberPromos(String id_member) async {
    try {
      var response = await dio.get(
        '${myIpAddr()}/history/historymember/$id_member',
      );
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
      isloadingpromo.value = false;
    } catch (e) {
      isloadingpromo.value = false;
      log("Error checking member promos: $e");
    }
  }

  Future<void> getdataproduk() async {
    try {
      var response = await dio.get('${myIpAddr()}/listproduk/getdataproduk');
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "id_produk": item['id_produk'],
              "nama_produk": item['nama_produk'],
              "harga_produk": item['harga_produk'],
              "stok_produk": item['stok_produk'],
              "durasi": item['durasi'],
              "tipe_komisi": item['tipe_komisi'],
              "nominal_komisi": item['nominal_komisi'],
              "tipe_komisi_gro": item['tipe_komisi_gro'],
              "nominal_komisi_gro": item['nominal_komisi_gro'],
            };
          }).toList();
      dataproduk.assignAll(fetcheddata);
    } catch (e) {
      log("Error di fn getdatafnb : $e");
    }
  }

  @override
  void onInit() {
    super.onInit();
    getdataproduk();
    getidmember();
    Future.delayed(Duration(seconds: 1), () {
      log('id member : $idMember');
      _checkMemberPromos(idMember);
    });

    Future.delayed(Duration(seconds: 2), () {
      log('promo : ${_activePromos}');
    });
    itemTapCounts.clear();
  }
}

// Parent Widget. nama awalnya StfulPaketMassage
class AddonPaketProduk extends StatelessWidget {
  final String idTrans;
  final String namaRuangan;

  AddonPaketProduk({
    super.key,
    required this.idTrans,
    required this.namaRuangan,
  }) {
    // Get.put(AddonPaketProdukController(idTrans: idTrans));

    Get.lazyPut<AddonPaketProdukController>(
      () => AddonPaketProdukController(idTrans: idTrans),
      fenix: false,
    );
  }
  KamarTerapisMgr _kamarTerapisMgr = KamarTerapisMgr();
  @override
  Widget build(BuildContext context) {
    var c = Get.find<AddonPaketProdukController>();

    var globalData = _kamarTerapisMgr.getData();

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: Get.height,
          width: Get.width,
          decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
          child: ListView(
            children: [
              Column(
                children: [
                  SizedBox(height: 30),
                  const Text(
                    "Massage",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Column(
                children: [
                  SizedBox(
                    height: 410,
                    child: DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(
                              top: 20,
                              left: 40,
                              right: 40,
                            ),
                            width: Get.width - 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                              child: TabBar(
                                onTap: (index) {
                                  print("Tab Aktif Sekarang $index");
                                },
                                indicator: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                ),
                                indicatorSize: TabBarIndicatorSize.tab,
                                labelColor: Colors.black,
                                unselectedLabelColor: Colors.black38,
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                tabs: const [
                                  Tab(text: "Paketan"),
                                  Tab(text: "Produk"),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            height: 335,
                            width: Get.width - 200,
                            margin: const EdgeInsets.only(left: 40, right: 40),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                              ),
                            ),
                            child: TabBarView(
                              children: [
                                // Konten 1
                                Container(
                                  width: Get.width - 200,
                                  padding: const EdgeInsets.only(
                                    left: 10,
                                    top: 20,
                                    right: 10,
                                  ),
                                  // child: IsiPaketMassages(
                                  //   onAddItem: addToDataJual,
                                  // ),
                                  child: MassageItemGrid(
                                    apiEndpoint: '/massages/paket',
                                    defaultUnit: 'Paket',
                                    icon: Icons.spa,
                                    onAddItem: c.addToDataJual,
                                  ),
                                ),
                                // Konten 2
                                Container(
                                  width: Get.width - 200,
                                  padding: const EdgeInsets.only(
                                    left: 10,
                                    top: 20,
                                    right: 10,
                                  ),
                                  // child: IsiProdukMassages(
                                  //   onAddItem: addToDataJual,
                                  // ),
                                  child: MassageItemGrid(
                                    apiEndpoint: '/massages/produk',
                                    defaultUnit: 'Pcs',
                                    icon: Icons.shopping_bag,
                                    onAddItem: c.addToDataJual,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.only(left: 10, top: 15),
                    height: Get.height - 250,
                    width: Get.width - 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: AutoSizeText(
                                "No Loker",
                                minFontSize: 15,
                                style: TextStyle(fontFamily: 'Poppins'),
                              ),
                            ),
                            Flexible(
                              child: AutoSizeText(
                                ": ",
                                minFontSize: 15,
                                style: TextStyle(fontFamily: 'Poppins'),
                              ),
                            ),
                            Expanded(
                              flex: 6,
                              child: Obx(
                                () => AutoSizeText(
                                  "${c._noLoker.value}",
                                  // "${LockerInput.getLocker()}",
                                  minFontSize: 15,
                                  style: TextStyle(fontFamily: 'Poppins'),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: AutoSizeText(
                                "Room",
                                minFontSize: 15,
                                style: TextStyle(fontFamily: 'Poppins'),
                              ),
                            ),
                            Flexible(
                              child: AutoSizeText(
                                ": ",
                                minFontSize: 15,
                                style: TextStyle(fontFamily: 'Poppins'),
                              ),
                            ),
                            Expanded(
                              flex: 6,
                              child: AutoSizeText(
                                globalData['namaRuangan'],
                                minFontSize: 15,
                                style: TextStyle(fontFamily: 'Poppins'),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Divider(),

                        Center(
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Nama Item",
                                  style: TextStyle(fontFamily: 'Poppins'),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 18),
                                  child: Text(
                                    "Jumlah",
                                    style: TextStyle(fontFamily: 'Poppins'),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "Satuan",
                                  style: TextStyle(fontFamily: 'Poppins'),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "Harga",
                                  style: TextStyle(fontFamily: 'Poppins'),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "Total",
                                  style: TextStyle(fontFamily: 'Poppins'),
                                ),
                              ),
                              Flexible(child: Text("")),
                            ],
                          ),
                        ),
                        // Ini Juga Child Component. Derajatnya
                        DataTransaksiMassages(dataJual: c.dataJual),
                        Divider(),
                        Row(
                          children: [
                            Expanded(child: Text("")),
                            Expanded(child: Text("")),
                            Expanded(child: Text("")),
                            Expanded(
                              child: Text(
                                "Total Add On",
                                style: TextStyle(fontFamily: 'Poppins'),
                              ),
                            ),
                            Expanded(
                              child: Obx(() {
                                var harga = c.getHargaBeforeDisc();
                                var formatted = c.formatCurrency.format(harga);
                                return Text(
                                  "${formatted}",
                                  // "${formatCurrency.format(discountData['stlh_disc'])}",
                                  style: TextStyle(fontFamily: 'Poppins'),
                                );
                              }),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    width: MediaQuery.of(context).size.width - 200,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: () {
                                    c._storeTrans().then((_) async {
                                      // await updatedataloker();
                                      await Future.delayed(
                                        Duration(milliseconds: 500),
                                      );

                                      // Get.offAll(() => MainResepsionis());
                                    });
                                  },
                                  child: Text(
                                    "Simpan Transaksi",
                                    style: TextStyle(fontFamily: 'Poppins'),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Kombinasi antara IsiPaket dan IsiProduk.
// kodeny kukomen dibawah utk referensi
//. yg membedakan hanya endpoint.
// keyvalue dari isiproduk disamakan dengan isipaket

Map<String, int> itemTapCounts = {};
String? retrieveindex = '';
Map<String, int> selecteditemindex = {};

class MassageItemGrid extends StatefulWidget {
  final String apiEndpoint;
  final String defaultUnit;
  final IconData icon;
  final Function(Map<String, dynamic>) onAddItem;

  const MassageItemGrid({
    super.key,
    required this.apiEndpoint,
    required this.defaultUnit,
    required this.icon,
    required this.onAddItem,
  });

  @override
  State<MassageItemGrid> createState() => _MassageItemGridState();
}

class _MassageItemGridState extends State<MassageItemGrid> {
  ScrollController _scrollController = ScrollController();
  RxList<Map<String, dynamic>> items = <Map<String, dynamic>>[].obs;

  var dio = Dio();

  final formatCurrency = NumberFormat.currency(
    locale: "id_ID",
    decimalDigits: 0,
    symbol: 'Rp. ',
  );

  // set awal loading true, kalo datanya udh kefetch maka false
  RxBool isLoading = true.obs;

  Future<void> _getMenu() async {
    try {
      var response = await dio.get('${myIpAddr()}${widget.apiEndpoint}');
      // log("$response");

      List<dynamic> responseData = response.data;
      items.assignAll(
        responseData.map((item) {
          return {
            "id_paket_msg": item['id_produk'] ?? item['id_paket_msg'],
            "nama_paket_msg": item['nama_produk'] ?? item['nama_paket_msg'],
            "harga_paket_msg": item['harga_produk'] ?? item['harga_paket_msg'],
            "detail_paket": item['detail_paket'] ?? "-",
            "durasi_awal": item['durasi'],
            "status": "unpaid",
            "is_addon": true,
          };
        }).toList(),
      );

      Future.delayed(const Duration(seconds: 1), () {
        isLoading.value = false;
      });
    } catch (e) {
      Future.delayed(const Duration(seconds: 1), () {
        isLoading.value = false;
      });

      log("Error in ${widget.apiEndpoint}: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _getMenu();
    retrieveindex = '';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    isLoading.close();
    items.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ap = Get.find<AddonPaketProdukController>();
    return Scrollbar(
      thumbVisibility: true,
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Container(
          // height: MediaQuery.of(context).size.height + 40,
          width: MediaQuery.of(context).size.width - 200,
          padding: const EdgeInsets.only(right: 10),
          child: Obx(
            () => Column(
              children: [
                if (isLoading.isTrue && ap.isloadingpromo.isTrue)
                  Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 30,
                          mainAxisSpacing: 25,
                          childAspectRatio: 2 / 1.5,
                        ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      int displayPrice = 0;
                      final promoExists = ap._activePromos.any(
                        (promo) =>
                            promo['nama_promo'] == item['nama_paket_msg'],
                      );
                      if (promoExists) {
                        displayPrice = 0;
                      } else {
                        displayPrice = item['harga_paket_msg'];
                      }
                      int sisakunjungan = 0;
                      int sisastok = 0;
                      String kondisilebih = '';
                      String tipepaket = '';
                      RxBool isPressed = false.obs;
                      return Obx(
                        () => GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (_) => isPressed.value = true,
                          onTapUp: (_) async {
                            await Future.delayed(
                              const Duration(milliseconds: 100),
                            ); // Give time for press animation
                            isPressed.value = false;

                            if (promoExists) {
                              String itemname = items[index]['nama_paket_msg'];
                              retrieveindex = itemname;
                              for (var promo in ap._activePromos.where(
                                (p) =>
                                    p['nama_paket_msg'] ==
                                    item['nama_paket_msg'],
                              )) {
                                sisakunjungan =
                                    int.tryParse(
                                      promo['sisa_kunjungan'].toString(),
                                    ) ??
                                    0;
                              }
                              if (retrieveindex != null &&
                                  itemTapCounts.containsKey(retrieveindex)) {
                                itemTapCounts[retrieveindex!] =
                                    itemTapCounts[retrieveindex]! + 1;
                              } else if (retrieveindex != null) {
                                itemTapCounts[retrieveindex!] = 1;
                              }

                              log('sisa kunjungan : $sisakunjungan ');
                              log('tapped : ${itemTapCounts[retrieveindex]}');

                              if (retrieveindex != null) {
                                if (itemTapCounts[retrieveindex]! >
                                    sisakunjungan) {
                                  kondisilebih = 'benar';
                                } else {
                                  kondisilebih = 'salah';
                                }
                              }

                              if (kondisilebih == 'salah') {
                                Map<String, dynamic> itemToAdd = Map.from(item);
                                if (promoExists) {
                                  itemToAdd['harga_paket_msg'] = 0;
                                  itemToAdd['harga_total'] = 0;
                                }
                                widget.onAddItem({
                                  "id_paket_msg": item['id_paket_msg'],
                                  "nama_paket_msg": item['nama_paket_msg'],
                                  "detail_paket": item['detail_paket'],
                                  "jlh": 1,
                                  "satuan": widget.defaultUnit,
                                  "harga_paket_msg": displayPrice,
                                  "harga_total": item['harga_paket_msg'],
                                  "durasi_awal": item['durasi_awal'],
                                  "status": "unpaid",
                                  "is_addon": true,
                                });
                              } else {
                                CherryToast.error(
                                  title: Text('Error'),
                                  description: Text('melebihi pemakaian'),
                                ).show(context);
                              }
                            } else {
                              for (var produk in ap.dataproduk.where(
                                (p) =>
                                    p['nama_produk'] == item['nama_paket_msg'],
                              )) {
                                sisastok =
                                    int.tryParse(
                                      produk['stok_produk'].toString(),
                                    ) ??
                                    0;
                                tipepaket = 'produk';
                              }

                              if (tipepaket == 'produk') {
                                String itemname = item['nama_paket_msg'];
                                // selecteditemindex[itemname] = index;
                                // retrieveindex = selecteditemindex[itemname];
                                retrieveindex = itemname;
                                if (retrieveindex != null &&
                                    itemTapCounts.containsKey(retrieveindex)) {
                                  itemTapCounts[retrieveindex!] =
                                      itemTapCounts[retrieveindex]! + 1;
                                } else if (retrieveindex != null) {
                                  itemTapCounts[retrieveindex!] = 1;
                                }
                                log('counter : $itemTapCounts');
                                if (sisastok == 0) {
                                  CherryToast.error(
                                    title: Text('Error'),
                                    description: Text('Stok sudah kosong'),
                                  ).show(context);
                                } else if (retrieveindex != null) {
                                  if (itemTapCounts[retrieveindex]! >
                                      sisastok) {
                                    CherryToast.error(
                                      title: Text('Error'),
                                      description: Text(
                                        'Penggunaan item melebihi stok',
                                      ),
                                    ).show(context);
                                  } else {
                                    widget.onAddItem({
                                      "id_paket_msg": item['id_paket_msg'],
                                      "nama_paket_msg": item['nama_paket_msg'],
                                      "detail_paket": item['detail_paket'],
                                      "jlh": 1,
                                      "satuan": widget.defaultUnit,
                                      "harga_paket_msg": displayPrice,
                                      "harga_total": item['harga_paket_msg'],
                                      "durasi_awal": item['durasi_awal'],
                                      "status": "unpaid",
                                      "is_addon": true,
                                    });
                                  }
                                }
                              } else {
                                widget.onAddItem({
                                  "id_paket_msg": item['id_paket_msg'],
                                  "nama_paket_msg": item['nama_paket_msg'],
                                  "detail_paket": item['detail_paket'],
                                  "jlh": 1,
                                  "satuan": widget.defaultUnit,
                                  "harga_paket_msg": displayPrice,
                                  "harga_total": item['harga_paket_msg'],
                                  "durasi_awal": item['durasi_awal'],
                                  "status": "unpaid",
                                  "is_addon": true,
                                });
                              }
                            }
                            // else {
                            //   widget.onAddItem({
                            //     "id_paket_msg": item['id_paket_msg'],
                            //     "nama_paket_msg": item['nama_paket_msg'],
                            //     "detail_paket": item['detail_paket'],
                            //     "jlh": 1,
                            //     "satuan": widget.defaultUnit,
                            //     "harga_paket_msg": displayPrice,
                            //     "harga_total": item['harga_paket_msg'],
                            //     "durasi_awal": item['durasi_awal'],
                            //     "status": "unpaid",
                            //     "is_addon": true,
                            //   });
                            // }
                          },
                          onTapCancel: () => isPressed.value = false,
                          child: Transform.scale(
                            scale: isPressed.isTrue ? 0.8 : 1.0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 64, 97, 55),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    widget.icon,
                                    size: 50,
                                    color: Colors.white,
                                  ),
                                  Text(
                                    item['nama_paket_msg'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    formatCurrency.format(displayPrice),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DataTransaksiMassages extends StatelessWidget {
  final RxList dataJual;

  DataTransaksiMassages({super.key, required this.dataJual});

  final formatCurrency = new NumberFormat.currency(
    locale: "id_ID",
    decimalDigits: 0,
    symbol: 'Rp. ',
  );

  @override
  Widget build(BuildContext context) {
    final ap = Get.find<AddonPaketProdukController>();
    return SizedBox(
      height: 220,
      child: Obx(
        () => ListView.builder(
          shrinkWrap: true,
          itemCount: dataJual.length,
          itemBuilder: (context, index) {
            int sisakunjungan = 0;
            int sisastok = 0;
            String kondisilebih = '';
            String tipepaket = '';
            return Row(
              children: [
                Expanded(
                  child: AutoSizeText(
                    dataJual[index]['nama_paket_msg'],
                    minFontSize: 15,
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove, size: 18),
                        onPressed: () {
                          final promoExists = ap._activePromos.any(
                            (promo) =>
                                promo['nama_promo'] ==
                                dataJual[index]['nama_paket_msg'],
                          );

                          if (promoExists) {
                            for (var promo in ap._activePromos.where(
                              (p) =>
                                  p['nama_paket_msg'] ==
                                  dataJual[index]['nama_paket_msg'],
                            )) {
                              sisakunjungan =
                                  int.tryParse(
                                    promo['sisa_kunjungan'].toString(),
                                  ) ??
                                  0;
                            }
                            String itemname = dataJual[index]['nama_paket_msg'];
                            retrieveindex = itemname;
                            if (retrieveindex != null &&
                                itemTapCounts.containsKey(retrieveindex)) {
                              if (retrieveindex != null &&
                                  itemTapCounts[retrieveindex]! <= 1) {
                                itemTapCounts[retrieveindex!] = 1;
                              } else if (retrieveindex != null &&
                                  itemTapCounts[retrieveindex]! >=
                                      sisakunjungan) {
                                if (sisakunjungan == 1) {
                                  itemTapCounts[retrieveindex!] = 1;
                                } else {
                                  itemTapCounts[retrieveindex!] =
                                      sisakunjungan - 1;
                                }
                              } else if (retrieveindex != null) {
                                itemTapCounts[retrieveindex!] =
                                    itemTapCounts[retrieveindex]! - 1;
                              }
                            } else if (retrieveindex != null) {
                              itemTapCounts[retrieveindex!] = 1;
                            }
                            log('tapped : $itemTapCounts');
                          } else {
                            for (var produk in ap.dataproduk.where(
                              (p) =>
                                  p['nama_produk'] ==
                                  dataJual[index]['nama_paket_msg'],
                            )) {
                              sisastok =
                                  int.tryParse(
                                    produk['stok_produk'].toString(),
                                  ) ??
                                  0;
                              tipepaket = 'produk';
                            }

                            if (tipepaket == 'produk') {
                              String itemname =
                                  dataJual[index]['nama_paket_msg'];
                              // retrieveindex = selecteditemindex[itemname];
                              retrieveindex = itemname;

                              if (retrieveindex != null &&
                                  itemTapCounts.containsKey(retrieveindex)) {
                                if (retrieveindex != null &&
                                    itemTapCounts[retrieveindex]! <= 1) {
                                  itemTapCounts[retrieveindex!] = 1;
                                } else if (retrieveindex != null &&
                                    itemTapCounts[retrieveindex]! >= sisastok) {
                                  if (sisastok == 1) {
                                    itemTapCounts[retrieveindex!] = 1;
                                  } else {
                                    itemTapCounts[retrieveindex!] =
                                        sisastok - 1;
                                  }
                                } else if (retrieveindex != null) {
                                  itemTapCounts[retrieveindex!] =
                                      itemTapCounts[retrieveindex]! - 1;
                                }
                              } else if (retrieveindex != null) {
                                itemTapCounts[retrieveindex!] = 1;
                              }
                              log('tapped : $itemTapCounts');
                            }
                          }

                          if (dataJual[index]['jlh'] > 1) {
                            dataJual[index]['jlh']--;
                            // Update Harga Total Juga
                            dataJual[index]['harga_total'] =
                                dataJual[index]['harga_paket_msg'] *
                                dataJual[index]['jlh'];
                          }

                          dataJual.refresh();

                          // widget.onChangeHrg();
                        },
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: AutoSizeText(
                          "${dataJual[index]['jlh']}",
                          minFontSize: 15,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add, size: 18),
                        onPressed: () {
                          final promoExists = ap._activePromos.any(
                            (promo) =>
                                promo['nama_promo'] ==
                                dataJual[index]['nama_paket_msg'],
                          );

                          if (promoExists) {
                            for (var promo in ap._activePromos.where(
                              (p) =>
                                  p['nama_paket_msg'] ==
                                  dataJual[index]['nama_paket_msg'],
                            )) {
                              sisakunjungan =
                                  int.tryParse(
                                    promo['sisa_kunjungan'].toString(),
                                  ) ??
                                  0;
                            }
                            String itemname = dataJual[index]['nama_paket_msg'];
                            retrieveindex = itemname;
                            if (retrieveindex != null &&
                                itemTapCounts.containsKey(retrieveindex)) {
                              itemTapCounts[retrieveindex!] =
                                  itemTapCounts[retrieveindex]! + 1;
                            } else if (retrieveindex != null) {
                              itemTapCounts[retrieveindex!] = 1;
                            }

                            if (retrieveindex != null) {
                              if (itemTapCounts[retrieveindex]! >
                                  sisakunjungan) {
                                kondisilebih = 'benar';
                              } else {
                                kondisilebih = 'salah';
                              }
                            }
                          }
                          if (kondisilebih == 'benar') {
                            CherryToast.error(
                              title: Text('Error'),
                              description: Text('melebihi pemakaian'),
                            ).show(context);
                          } else {
                            for (var produk in ap.dataproduk.where(
                              (p) =>
                                  p['nama_produk'] ==
                                  dataJual[index]['nama_paket_msg'],
                            )) {
                              sisastok =
                                  int.tryParse(
                                    produk['stok_produk'].toString(),
                                  ) ??
                                  0;
                              tipepaket = 'produk';
                            }

                            if (tipepaket == 'produk') {
                              String itemname =
                                  dataJual[index]['nama_paket_msg'];
                              // selecteditemindex[itemname] = index;
                              // retrieveindex = selecteditemindex[itemname];
                              retrieveindex = itemname;
                              if (retrieveindex != null &&
                                  itemTapCounts.containsKey(retrieveindex)) {
                                itemTapCounts[retrieveindex!] =
                                    itemTapCounts[retrieveindex]! + 1;
                              } else if (retrieveindex != null) {
                                itemTapCounts[retrieveindex!] = 1;
                              }
                              log('counter : $itemTapCounts');
                              if (sisastok == 0) {
                                CherryToast.error(
                                  title: Text('Error'),
                                  description: Text('Stok sudah kosong'),
                                ).show(context);
                              } else if (retrieveindex != null) {
                                if (itemTapCounts[retrieveindex]! > sisastok) {
                                  CherryToast.error(
                                    title: Text('Error'),
                                    description: Text(
                                      'Penggunaan item melebihi stok',
                                    ),
                                  ).show(context);
                                } else {
                                  dataJual[index]['jlh']++;
                                  // Update Harga Total Juga
                                  dataJual[index]['harga_total'] =
                                      dataJual[index]['harga_paket_msg'] *
                                      dataJual[index]['jlh'];
                                }
                              }
                            } else {
                              dataJual[index]['jlh']++;
                              // Update Harga Total Juga
                              dataJual[index]['harga_total'] =
                                  dataJual[index]['harga_paket_msg'] *
                                  dataJual[index]['jlh'];
                            }
                          }
                          log(promoExists.toString());
                          log('tapped : $itemTapCounts');

                          dataJual.refresh();
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: AutoSizeText(
                    dataJual[index]['satuan'],
                    minFontSize: 15,
                  ),
                ),
                Expanded(
                  child: AutoSizeText(
                    "${formatCurrency.format(dataJual[index]['harga_paket_msg'])}",
                    minFontSize: 15,
                  ),
                ),
                Expanded(
                  child: Text(
                    "${formatCurrency.format(dataJual[index]['harga_total'])}",
                    style: TextStyle(fontFamily: 'Poppins'),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(Icons.delete, size: 18),
                          onPressed: () {
                            final promoExists = ap._activePromos.any(
                              (promo) =>
                                  promo['nama_promo'] ==
                                  dataJual[index]['nama_paket_msg'],
                            );

                            if (promoExists) {
                              if (retrieveindex != null) {
                                String itemname =
                                    dataJual[index]['nama_paket_msg'];
                                retrieveindex = itemname;

                                itemTapCounts[retrieveindex!] = 0;
                              }
                            } else {
                              for (var produk in ap.dataproduk.where(
                                (p) =>
                                    p['nama_produk'] ==
                                    dataJual[index]['nama_paket_msg'],
                              )) {
                                sisastok =
                                    int.tryParse(
                                      produk['stok_produk'].toString(),
                                    ) ??
                                    0;
                                tipepaket = 'produk';
                              }

                              if (tipepaket == 'produk') {
                                String itemname =
                                    dataJual[index]['nama_paket_msg'];
                                // selecteditemindex[itemname] = index;
                                // retrieveindex = selecteditemindex[itemname];
                                retrieveindex = itemname;
                                itemTapCounts[retrieveindex!] = 0;
                              }
                            }
                            dataJual.removeAt(index);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
