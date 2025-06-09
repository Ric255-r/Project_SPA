import 'dart:developer';

import 'package:Project_SPA/function/ip_address.dart';
import 'package:Project_SPA/function/token.dart';
import 'package:Project_SPA/kamar_terapis/main_kamar_terapis.dart';
import 'package:Project_SPA/kamar_terapis/terapis_bekerja.dart';
import 'package:Project_SPA/resepsionis/main_resepsionis.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:Project_SPA/kamar_terapis/terapis_mgr.dart';

class TerapisConfirmController extends GetxController {
  TerapisConfirmController() {
    // anggapannya kek initstate, buat di constructor manual
    _getLatestTrans();
  }

  RxBool isButtonReadyVisible = true.obs;
  RxBool isButtonStartVisible = false.obs;

  RxList<dynamic> _dataPaket = [].obs;
  RxList<dynamic> _dataProduk = [].obs;
  RxList<dynamic> _dataFood = [].obs;
  RxString _idTransaksi = "".obs;
  RxString _idTerapis = "".obs;
  RxString _namaTerapis = "".obs;
  RxString _namaRuangan = "".obs;
  RxString _kodeRuangan = "".obs;
  RxString _idDetailTransaksi = "".obs;
  RxBool _popScopeReady = false.obs;
  RxInt _sumDurasiMenit = 0.obs;

  var dio = Dio();
  Future<void> _getLatestTrans() async {
    try {
      final prefs = await getTokenSharedPref();

      var response = await dio.get(
        '${myIpAddr()}/kamar_terapis/latest_trans',
        options: Options(headers: {"Authorization": "Bearer " + prefs!}),
      );

      List<dynamic> responsePaket = response.data['data_paket'];
      List<dynamic> responseProduk = response.data['data_produk'];

      _dataPaket.assignAll(
        responsePaket.map((item) {
          if (_idTransaksi.value == "")
            _idTransaksi.value = item['id_transaksi'];
          if (_namaTerapis.value == "")
            _namaTerapis.value = item['nama_karyawan'];
          if (_namaRuangan.value == "")
            _namaRuangan.value = item['nama_ruangan'];
          if (_idTerapis.value == "") _idTerapis.value = item['id_terapis'];
          if (_kodeRuangan.value == "")
            _kodeRuangan.value = item['kode_ruangan'];
          if (_idDetailTransaksi.value == "")
            _idDetailTransaksi.value = item['id_detail_transaksi'];

          _sumDurasiMenit += item['total_durasi'];

          return {
            "id_paket": item['id_paket'],
            "nama_paket_msg": item['nama_paket_msg'],
            "total_durasi": item['total_durasi'],
            "deskripsi_paket": item['deskripsi_paket'],
            "id_transaksi": item['id_transaksi'],
            "tgl_transaksi": item['tgl_transaksi'],
            "status_detail": item['status_detail'],
            "is_addon": item['is_addon'],
          };
        }).toList(),
      );

      _dataProduk.assignAll(
        responseProduk.map((item) {
          if (_idTransaksi.value == "")
            _idTransaksi.value = item['id_transaksi'];
          if (_namaTerapis.value == "")
            _namaTerapis.value = item['nama_karyawan'];
          if (_namaRuangan.value == "")
            _namaRuangan.value = item['nama_ruangan'];
          if (_idTerapis.value == "") _idTerapis.value = item['id_terapis'];
          if (_kodeRuangan.value == "")
            _kodeRuangan.value = item['kode_ruangan'];
          if (_idDetailTransaksi.value == "")
            _idDetailTransaksi.value = item['id_detail_transaksi'];

          _sumDurasiMenit += item['total_durasi'];

          return {
            "id_produk": item['id_produk'],
            "nama_produk": item['nama_produk'],
            "total_durasi": item['total_durasi'],
            "id_transaksi": item['id_transaksi'],
            "tgl_transaksi": item['tgl_transaksi'],
            "status_detail": item['status_detail'],
            "is_addon": item['is_addon'],
          };
        }).toList(),
      );

      var response2 = await dio.get(
        '${myIpAddr()}/fnb/selected_food?id_trans=${_idTransaksi.value}',
        options: Options(headers: {"Authorization": "bearer " + prefs}),
      );

      List<dynamic> responseFood = response2.data;
      _dataFood.assignAll(
        responseFood.map((e) => Map<String, dynamic>.from(e)).toList(),
      );

      print("_getLatestTrans Bisa");
    } catch (e) {
      if (e is DioException) {
        log("Error di _getLatestTrans ${e.response!.data}");
      }
    }
  }

  Future<void> _deleteProgress() async {
    try {
      var response = await dio.delete(
        '${myIpAddr()}/kamar_terapis/delete_progress?id_transaksi=${_idTransaksi.value}&id_terapis=${_idTerapis.value}',
      );

      if (response.statusCode == 200) {
        log("Sukses Hapus Data");
      }
    } catch (e) {
      if (e is DioException) {
        log("Error Di fn _deleteProgress ${e.response!.data}");
      }
    }
  }

  int trialAttempt = 0;
  int maxAttempt = 1;
  Future<void> _postJamDatang() async {
    try {
      final now = DateTime.now();
      final formattedTime = '${now.hour}:${now.minute}:${now.second}';

      var response = await dio.post(
        '${myIpAddr()}/kamar_terapis/ins_datang',
        data: {
          "id_transaksi": _idTransaksi.value,
          "id_terapis": _idTerapis.value,
          "jam_datang": formattedTime,
        },
      );

      if (response.statusCode == 200) {
        toggleButtons();

        // Get.delete<MainResepsionisController>();

        _popScopeReady.value = true;

        log("Berhasil Store Jam Datang");
      }
    } catch (e) {
      if (e is DioException) {
        while (trialAttempt < maxAttempt) {
          _postJamDatang();
          trialAttempt++;
        }
        log("Error di post jam datang ${e.response!.data}");
      }
    }
  }

  Future<void> _updateJamMulai() async {
    try {
      final prefs = await getTokenSharedPref();
      final now = DateTime.now();
      final formattedTime = '${now.hour}:${now.minute}:${now.second}';

      var response = await dio.put(
        '${myIpAddr()}/kamar_terapis/update_mulai',
        options: Options(headers: {"Authorization": "Bearer " + prefs!}),
        data: {
          "id_transaksi": _idTransaksi.value,
          "id_terapis": _idTerapis.value,
          "jam_mulai": formattedTime,
          "sum_durasi_menit": _sumDurasiMenit.value,
        },
      );

      if (response.statusCode == 200) {
        log("Berhasil Update Jam Mulai");
      }
    } catch (e) {
      if (e is DioException) {
        log("Error di update jam Mulai ${e.response!.data}");
      }
    }
  }

  void toggleButtons() {
    isButtonReadyVisible.value = false;
    isButtonStartVisible.value = true;
  }

  KamarTerapisMgr _kamarTerapisMgr = KamarTerapisMgr();
}

class TerapisConfirm extends StatelessWidget {
  TerapisConfirm({super.key}) {
    // Buat Trigger Controller
    Get.put(TerapisConfirmController());
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TerapisConfirmController>();

    // Buat Widget Konten Utama
    Widget content = Scaffold(
      body: Container(
        width: Get.width,
        height: Get.height,
        decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 20),
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(width: 0, color: Colors.black),
                borderRadius: BorderRadius.all(Radius.circular(200)),
              ),
              child: ClipOval(
                child: Image(
                  image: AssetImage('assets/spa.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              width: Get.width * 0.75,
              height: Get.height * 0.32,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(
                    () => Text(
                      'Detail Pesanan : ${c._idTransaksi.value}',
                      style: TextStyle(fontSize: 30, fontFamily: 'Poppins'),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 5.0,
                      horizontal: 10.0,
                    ),
                    width: Get.width,
                    height: 160,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Obx(() {
                            if (c._dataPaket.isNotEmpty) {
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          "Id & Nama Paket",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          "Durasi (Menit)",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          "Deskripsi Paket",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          "Tgl Transaksi",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      Flexible(
                                        child: Text(
                                          "Is Add On",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  for (var item in c._dataPaket)
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            "${item['id_paket']} - ${item['nama_paket_msg']}",
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            "${item['total_durasi']} Menit",
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            "${item['deskripsi_paket']}",
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            "${(item['tgl_transaksi'] as String).split("T")[0]}",
                                          ),
                                        ),
                                        Flexible(
                                          child: SizedBox(
                                            height:
                                                24, // Fixed height matching text
                                            child: Icon(
                                              item['is_addon'] == 1
                                                  ? Icons.check
                                                  : Icons.cancel,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              );
                            } else {
                              return Text("");
                            }
                          }),
                          Obx(() {
                            if (c._dataProduk.isNotEmpty) {
                              return Column(
                                children: [
                                  SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "Id & Nama Produk",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          "Durasi (Menit)",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          "Tanggal Transaksi",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          "Is Add On",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  for (var item in c._dataProduk)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            "${item['id_produk']} - ${item['nama_produk']}",
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            "${item['total_durasi']} Menit",
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            "${(item['tgl_transaksi'] as String).split("T")[0]}",
                                          ),
                                        ),
                                        Flexible(
                                          child: SizedBox(
                                            height:
                                                24, // Fixed height matching text
                                            child: Icon(
                                              item['is_addon'] == 1
                                                  ? Icons.check
                                                  : Icons.cancel,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              );
                            } else {
                              return Text("");
                            }
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Stack(
              children: [
                Obx(() {
                  return c.isButtonReadyVisible.value
                      ? GestureDetector(
                        onTap: () {
                          // c.isButtonReadyVisible.value = false;
                          // c.isButtonStartVisible.value = true;

                          if (c._dataPaket.isEmpty &&
                              c._dataProduk.isEmpty &&
                              c._dataFood.isEmpty) {
                            CherryToast.error(
                              title: Text(
                                "Tidak Ada Data",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              animationDuration: const Duration(
                                milliseconds: 1500,
                              ),
                              autoDismiss: true,
                            ).show(Get.context!); // Use Get.context!
                            return;
                          }

                          c._postJamDatang();
                        },
                        child: Container(
                          margin: EdgeInsets.only(top: 15),
                          width: Get.width * 0.75,
                          height: Get.height * 0.267,
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white),
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              height: 170,
                              width: 150,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(top: 10),
                                    child: Icon(Icons.check_rounded, size: 120),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(top: 1),
                                    child: Text(
                                      'Ready',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                      : const SizedBox();
                }),
                Obx(() {
                  return c.isButtonStartVisible.value
                      ? Container(
                        width: Get.width * 0.75,
                        height: Get.height * 0.267,
                        child: Align(
                          alignment: Alignment.topRight,
                          child: GestureDetector(
                            onTap: () {
                              c._updateJamMulai().then((_) async {
                                await Future.delayed(
                                  Duration(milliseconds: 500),
                                );

                                c._kamarTerapisMgr.setData({
                                  "idTransaksi": c._idTransaksi.value,
                                  "idDetailTransaksi":
                                      c._idDetailTransaksi.value,
                                  "kodeRuangan": c._kodeRuangan.value,
                                  "sumDurasi": c._sumDurasiMenit.value,
                                  "namaRuangan": c._namaRuangan.value,
                                  "namaTerapis": c._namaTerapis.value,
                                  "dataProduk": c._dataProduk,
                                  "dataPaket": c._dataPaket,
                                  "dataFood": c._dataFood,
                                });

                                Get.to(() => TerapisBekerja());

                                // Get.to(
                                //   () => TerapisBekerja(
                                //     idTransaksi: c._idTransaksi.value,
                                //     idDetailTransaksi:
                                //         c._idDetailTransaksi.value,
                                //     kodeRuangan: c._kodeRuangan.value,
                                //     sumDurasi: c._sumDurasiMenit.value,
                                //     namaRuangan: c._namaRuangan.value,
                                //     namaTerapis: c._namaTerapis.value,
                                //     dataProduk: c._dataProduk,
                                //     dataPaket: c._dataPaket,
                                //   ),
                                // );
                              });
                            },
                            child: Container(
                              margin: EdgeInsets.only(top: 15),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white),
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              height: 170,
                              width: 150,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(Icons.timer_rounded, size: 120),
                                  Padding(
                                    padding: EdgeInsets.only(top: 1),
                                    child: Text(
                                      'Start',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                      : const SizedBox();
                }),
              ],
            ),
            Row(
              children: [
                Container(
                  width: 450,
                  height: 81,
                  decoration: BoxDecoration(
                    color: Color(0xFF333333).withOpacity(0.4),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                  child: Container(
                    padding: EdgeInsets.only(left: 20),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(),
                            shape: BoxShape.circle,
                          ),
                          width: 70,
                          height: 70,
                          child: CircleAvatar(
                            child: Text('Y', style: TextStyle(fontSize: 25)),
                          ),
                        ),
                        Obx(
                          () => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(top: 7, left: 20),
                                child: Text(
                                  'Room : ${c._namaRuangan.value}',
                                  style: TextStyle(
                                    fontSize: 25,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 20),
                                child: Text(
                                  'Terapis : ${c._namaTerapis.value}',
                                  style: TextStyle(
                                    fontSize: 25,
                                    fontFamily: 'Poppins',
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
              ],
            ),
          ],
        ),
      ),
    );

    return Obx(
      () =>
          c._popScopeReady.value
              ? WillPopScope(
                child: content,
                onWillPop: () async {
                  bool? result = await Get.dialog(
                    AlertDialog(
                      title: const Text("Keluar Menu?"),
                      content: const Text(
                        "Apakah Yakin Ingin Keluar? Progress anda Akan Dihapus",
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () {
                            Get.back(result: false);
                          },
                          child: Text("No"),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            await c._deleteProgress();
                            Get.back(result: true);
                          },
                          child: Text("Yes"),
                        ),
                      ],
                    ),
                  );
                  return result ?? false;
                },
              )
              : content,
    );
  }
}
