import 'package:Project_SPA/kamar_terapis/main_kamar_terapis.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Project_SPA/kamar_terapis/terapis_mgr.dart';
import 'package:Project_SPA/resepsionis/transaksi_food.dart';
import 'package:Project_SPA/resepsionis/transaksi_massage.dart';
import 'package:cherry_toast/cherry_toast.dart';

class CustEndSblmWaktunyaController extends GetxController {
  KamarTerapisMgr _kamarTerapisMgr = KamarTerapisMgr();
}

class CustEndSblmWaktunya extends StatelessWidget {
  CustEndSblmWaktunya({super.key}) {
    // Get.put(CustEndSblmWaktunyaController());
    Get.lazyPut<CustEndSblmWaktunyaController>(() => CustEndSblmWaktunyaController(), fenix: false);
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CustEndSblmWaktunyaController>();

    return Scaffold(
      body: PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (!didPop) {
            Get.snackbar("Error", "Wajib Pilih Alasan!");
          }
        },
        child: Container(
          decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
          width: Get.width,
          height: Get.height,
          child: Column(
            children: [
              Padding(padding: EdgeInsets.only(top: Get.height * 0.1), child: Text('PLATINUM', style: TextStyle(fontSize: 60))),
              Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                  child: Column(
                    children: [
                      Text("Alasan Menyelesaikan Paket", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                      Text("Sebelum Waktunya :", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 30, left: 240, right: 240),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        bool result = await c._kamarTerapisMgr.setSelesai(cepatSelesai: true, alasan: "Atas_Permintaan_Tamu");

                        if (result) {
                          Get.offAll(() => MainKamarTerapis());
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(border: Border.all(color: Colors.white), color: Colors.white, borderRadius: BorderRadius.circular(15)),
                        height: 180,
                        width: 250,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('1.', style: TextStyle(fontSize: 30)),
                              Text('Atas Permintaan', style: TextStyle(fontSize: 28, fontFamily: 'Poppins')),
                              Text('Tamu', style: TextStyle(fontSize: 28, fontFamily: 'Poppins')),
                            ],
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        bool result = await c._kamarTerapisMgr.setSelesai(cepatSelesai: true, alasan: "Tamu_Complain");

                        if (result) {
                          Get.offAll(() => MainKamarTerapis());
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(border: Border.all(color: Colors.white), color: Colors.white, borderRadius: BorderRadius.circular(15)),
                        height: 180,
                        width: 250,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 33),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text('2.', style: TextStyle(fontSize: 28, fontFamily: 'Poppins')),
                                Text('Tamu Komplain', style: TextStyle(fontSize: 28, fontFamily: 'Poppins')),
                              ],
                            ),
                          ),
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
