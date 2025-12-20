import 'dart:developer';

import 'package:Project_SPA/function/ip_address.dart';
import 'package:Project_SPA/function/our_drawer.dart';
import 'package:Project_SPA/resepsionis/list_transaksi.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RatingController extends GetxController {
  final String idTransaksi;
  RatingController({required this.idTransaksi});
  var selectedRatings = {
    "pelayanan_terapis": RxnInt(null),
    "fasilitas": RxnInt(null),
    "pelayanan_keseluruhan": RxnInt(null),
  };

  void selectRating(String category, int index) {
    selectedRatings[category]?.value = index;
    checkAllRatingsSelected();

    print(selectedRatings);
  }

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    cekRating();
  }

  void checkAllRatingsSelected() {
    if (selectedRatings.values.every((rating) => rating.value != null)) {
      showThankYouDialog();
    }
  }

  var dio = Dio();
  RxBool isFirstTimeRate = true.obs;

  Future<void> cekRating() async {
    try {
      var response = await dio.get('${myIpAddr()}/listtrans/cek_rating?id_transaksi=$idTransaksi');
      Map<String, dynamic> responseData = response.data;

      isFirstTimeRate.value = responseData['is_first_time'];

      if (!isFirstTimeRate.value) {
        var data = responseData['data'];

        // krna valuenya bentuk rxInt, update spt ini
        selectedRatings['pelayanan_terapis']?.value = data['pelayanan_terapis'];
        selectedRatings['fasilitas']?.value = data['fasilitas'];
        selectedRatings['pelayanan_keseluruhan']?.value = data['pelayanan_keseluruhan'];
      }

      print(isFirstTimeRate.value);
    } catch (e) {
      if (e is DioException) {
        log("Error di cek Rating Dio ${e.response!.data}");
      }
      log("Error di cek Rating $e");
    }
  }

  Future<void> storeRating() async {
    try {
      // Konversi value dari Rx ke value biasa
      Map<String, dynamic> data = {
        "pelayanan_terapis": selectedRatings["pelayanan_terapis"]?.value,
        "fasilitas": selectedRatings["fasilitas"]?.value,
        "pelayanan_keseluruhan": selectedRatings["pelayanan_keseluruhan"]?.value,
        "id_transaksi": idTransaksi,
      };

      var response = await dio.post('${myIpAddr()}/listtrans/store_rating', data: data);

      if (response.statusCode == 200) {
        Get.back();
        Get.delete<RatingController>();
        Get.to(() => ListTransaksi());
      }
    } catch (e) {
      if (e is DioException) {
        log("Error di StoreRating ${e.response!.data}");
      }
    }
  }

  void showThankYouDialog() {
    Get.dialog(
      AlertDialog(
        title: Text("🎉 Terima Kasih! 🎉"),
        content: Text("Kami menghargai masukan Anda!"),
        actions: [
          TextButton(
            onPressed: () async {
              // Get.back();
              // Get.offAllNamed('/mainresepsionis');
              await storeRating();
            },
            child: Text("Close"),
          ),
        ],
      ),
    );
  }
}

class Rating extends StatelessWidget {
  var idTransaksi;

  Rating({super.key, this.idTransaksi}) {
    Get.lazyPut(() => RatingController(idTransaksi: idTransaksi), fenix: false);
  }

  final List<String> emojis = ["☹️", "😐", "😊"];

  @override
  Widget build(BuildContext context) {
    final c = Get.find<RatingController>();
    final shortest = MediaQuery.of(context).size.shortestSide;
    final bool isMobile = shortest < 600 || shortest > 700;
    log("isi Shortest Side ${MediaQuery.of(context).size.shortestSide}");
    // =======================================================================

    // 1. Tentukan lebar desain dasar Anda
    // 660 ini lebar terkecil DP tablet yg kita patok.
    const double tabletDesignWidth = 660;
    const double tabletDesignHeight = 1024;

    // 2. Tentukan faktor penyesuaian untuk mobile.
    const double mobileAdjustmentFactor = 1.25; // UI akan 25% lebih kecil

    // 3. Hitung designSize yang efektif berdasarkan tipe perangkat
    final double effectiveDesignWidth =
        isMobile ? tabletDesignWidth * mobileAdjustmentFactor : tabletDesignWidth;
    final double effectiveDesignHeight =
        isMobile ? tabletDesignHeight * mobileAdjustmentFactor : tabletDesignHeight;
    return isMobile
        ? WidgetRatingMobile()
        : Scaffold(
          drawer: OurDrawer(),
          appBar: AppBar(
            title: Text(
              'PLATINUM',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 30, fontWeight: FontWeight.bold),
            ),
            toolbarHeight: 100,
            centerTitle: true,
            backgroundColor: Color(0XFFFFE0B2),
          ),
          body: Container(
            height: Get.height,
            width: Get.width,
            decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 130),
                  child: Obx(() {
                    if (c.isFirstTimeRate.value) {
                      return Text(
                        'Berikan Rating Anda 🤗',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold),
                      );
                    } else {
                      return Text(
                        'Rating pada ${c.idTransaksi} Adalah: ',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold),
                      );
                    }
                  }),
                ),
                SizedBox(height: 20),
                _buildRatingCategory("pelayanan_terapis"),
                _buildRatingCategory("fasilitas"),
                _buildRatingCategory("pelayanan_keseluruhan"),
              ],
            ),
          ),
        );
  }

  Widget _buildRatingCategory(String category) {
    final c = Get.find<RatingController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 130, top: 20),
          child: Text(
            category,
            style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(right: 130, left: 130),
          child: Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(emojis.length, (index) {
                return GestureDetector(
                  onTap: () {
                    if (c.isFirstTimeRate.value) {
                      c.selectRating(category, index);
                    } else {
                      Get.snackbar("Error", "Tidak Dapat Mengubah");
                      return;
                    }
                  },
                  child: Container(
                    width: 200,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: c.selectedRatings[category]?.value == index ? Colors.greenAccent : Colors.white,
                    ),
                    child: Center(child: Text(emojis[index], style: TextStyle(fontSize: 60))),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

class WidgetRatingMobile extends StatelessWidget {
  final List<String> emojis = ["☹️", "😐", "😊"];

  @override
  Widget build(BuildContext context) {
    final c = Get.find<RatingController>();

    return Scaffold(
      drawer: OurDrawer(),
      appBar: AppBar(
        title: Text(
          'PLATINUM',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 30, fontWeight: FontWeight.bold),
        ),
        toolbarHeight: 100,
        centerTitle: true,
        backgroundColor: Color(0XFFFFE0B2),
      ),
      body: Container(
        height: Get.height,
        width: Get.width,
        decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 40),
              child: Obx(() {
                if (c.isFirstTimeRate.value) {
                  return Text(
                    'Berikan Rating Anda 🤗',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold),
                  );
                } else {
                  return Text(
                    'Rating pada ${c.idTransaksi} Adalah: ',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold),
                  );
                }
              }),
            ),
            SizedBox(height: 20),
            _buildRatingCategory("pelayanan_terapis", c),
            _buildRatingCategory("fasilitas", c),
            _buildRatingCategory("pelayanan_keseluruhan", c),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingCategory(String category, RatingController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 40, top: 20),
          child: Text(
            category,
            style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(right: 40, left: 40),
          child: Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(emojis.length, (index) {
                return GestureDetector(
                  onTap: () {
                    if (c.isFirstTimeRate.value) {
                      c.selectRating(category, index);
                    } else {
                      Get.snackbar("Error", "Tidak Dapat Mengubah");
                    }
                  },
                  child: Container(
                    width: 200,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: c.selectedRatings[category]?.value == index ? Colors.greenAccent : Colors.white,
                    ),
                    child: Center(child: Text(emojis[index], style: TextStyle(fontSize: 60))),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
