// Singleton instance

import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:Project_SPA/function/ip_address.dart';
import 'package:Project_SPA/function/token.dart';

class KamarTerapisMgr {
  // single instance
  static final KamarTerapisMgr _instance = KamarTerapisMgr._internal();

  factory KamarTerapisMgr() {
    return _instance;
  }

  // buat Constructor Privat
  KamarTerapisMgr._internal();

  // buat variabel utk nampung data
  String? idTransaksi;
  String? idDetailTransaksi;
  String? kodeRuangan;
  int? sumDurasi;
  String? namaRuangan;
  String? namaTerapis;
  List<dynamic>? dataProduk;
  List<dynamic>? dataPaket;
  List<dynamic> dataFood = [];
  int limitMenitChange = 15;

  void setData(Map<String, dynamic> items) {
    // log("Hasil isi data ${items}");

    idTransaksi = items['idTransaksi'];
    idDetailTransaksi = items['idDetailTransaksi'];
    kodeRuangan = items['kodeRuangan'];
    sumDurasi = items['sumDurasi'];
    namaRuangan = items['namaRuangan'];
    namaTerapis = items['namaTerapis'];
    dataProduk = items['dataProduk'];
    dataPaket = items['dataPaket'];
    dataFood = items['dataFood'];
  }

  void setFood(List<dynamic> items) {
    dataFood.clear();
    dataFood.addAll(items);
  }

  Future<void> updateDataProdukPaket(String idTrans) async {
    try {
      final prefs = await getTokenSharedPref();

      var response = await Dio().get(
        '${myIpAddr()}/kamar_terapis/latest_trans?id_trans=$idTrans',
        options: Options(headers: {"Authorization": "bearer " + prefs!}),
      );

      List<dynamic> responsePaket = response.data['data_paket'];
      List<dynamic> responseProduk = response.data['data_produk'];

      dataPaket!.clear();
      dataPaket!.addAll(
        responsePaket.map((item) {
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

      dataProduk!.clear();
      dataProduk!.addAll(
        responseProduk.map((item) {
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

      // log("Isi Response Datanya adalah ${dataPaket}");
      // log("Isi Response Datanya adalah ${dataProduk}");
    } catch (e) {
      if (e is DioException) {
        log("Error Dio ${e.response!.data}");
      }

      log("Error lain $e");
    }
  }

  Future<bool> updateFood(String idTrans) async {
    try {
      final prefs = await getTokenSharedPref();

      var response = await Dio().get('${myIpAddr()}/fnb/selected_food?id_trans=$idTrans', options: Options(headers: {"Authorization": "bearer " + prefs!}));

      List<dynamic> responseData = response.data;

      if (response.statusCode == 200) {
        dataFood.clear();
        dataFood.addAll(responseData);
        return true;
      }

      return false;
    } catch (e) {
      if (e is DioException) {
        log("Error Dio ${e.response!.data}");
      }

      log("Error lain $e");
      return false;
    }
  }

  Future<bool> setSelesai({bool cepatSelesai = false, String alasan = ""}) async {
    try {
      var url = '${myIpAddr()}/kamar_terapis/selesai';

      if (cepatSelesai) {
        url = '${myIpAddr()}/kamar_terapis/selesai?selesai_awal=$alasan';
      }

      var response = await Dio().put(url, data: {"id_transaksi": idTransaksi});

      if (response.statusCode == 200) {
        resetLimitChange();
        return true;
      }

      return false;
    } catch (e) {
      if (e is DioException) {
        log("Error di Selesaikan ${e.response!.data}");
      }

      return false;
    }
  }

  void clearAllData() {
    idTransaksi = "";
    idDetailTransaksi = "";
    kodeRuangan = "";
    sumDurasi = 0;
    namaRuangan = "";
    namaTerapis = "";
    dataProduk = [];
    dataPaket = [];
    dataFood = [];

    log("Clear All Data terapis_mgr");
  }

  // Method getDatImage
  Map<String, dynamic> getData() {
    return {
      "idTransaksi": idTransaksi,
      "idDetailTransaksi": idDetailTransaksi,
      "kodeRuangan": kodeRuangan,
      "sumDurasi": sumDurasi,
      "namaRuangan": namaRuangan,
      "namaTerapis": namaTerapis,
      "dataProduk": dataProduk,
      "dataPaket": dataPaket,
      "dataFood": dataFood,
    };
  }

  bool getLimitChange() {
    return limitMenitChange > 0;
  }

  void setLimitChange() {
    if (limitMenitChange > 0) limitMenitChange -= 1;
    print("Sisa Menit Utk Ganti Paket dll $limitMenitChange");
  }

  void resetLimitChange() {
    limitMenitChange = 15;
  }
}
