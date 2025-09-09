import 'dart:async';
import 'dart:developer';

import 'package:Project_SPA/function/ip_address.dart';
import 'package:Project_SPA/function/token.dart';
import 'package:Project_SPA/kamar_terapis/addon_food.dart';
import 'package:Project_SPA/kamar_terapis/addon_paket.dart';
import 'package:Project_SPA/kamar_terapis/addon_paketproduk.dart';
import 'package:Project_SPA/resepsionis/main_resepsionis.dart';
import 'package:Project_SPA/ruang_tunggu/main_rt.dart';
import 'package:intl/intl.dart';
import 'package:Project_SPA/kamar_terapis/cust_end_sblm_waktunya.dart';
// import 'package:Project_SPA/kamar_terapis/jenis_add_on.dart';
import 'package:Project_SPA/kamar_terapis/main_kamar_terapis.dart';
import 'package:Project_SPA/kamar_terapis/terapis_confirm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:Project_SPA/kamar_terapis/terapis_mgr.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Project_SPA/resepsionis/transaksi_massage.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'addon_extend.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:Project_SPA/resepsionis/detail_paket_msg.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
// import 'package:idle_detector_wrapper/idle_detector_wrapper.dart';

class TerapisBekerja extends StatefulWidget {
  // final String roomTitle;
  // tes Komen argumen dari bawah
  // final String idTransaksi;
  // final String idDetailTransaksi;
  // final String kodeRuangan;
  // final int sumDurasi;
  // final String namaRuangan;
  // final String namaTerapis;
  // final List<dynamic> dataProduk;
  // final List<dynamic> dataPaket;

  TerapisBekerja({
    super.key,
    // required this.idTransaksi,
    // required this.idDetailTransaksi,
    // required this.kodeRuangan,
    // required this.sumDurasi,
    // required this.namaRuangan,
    // required this.namaTerapis,
    // required this.dataProduk,
    // required this.dataPaket,
  });

  @override
  State<TerapisBekerja> createState() => _TerapisBekerjaState();
}

class _TerapisBekerjaState extends State<TerapisBekerja> {
  // final List<String> items = [
  //   'Pijit Kepala',
  //   'Pijit Kaki',
  //   'Pijit Pantat',
  //   'Pijit Biji',
  // ];
  // tipe yang berbentuk .obs, ga perlu di dispose, klo yg d bwh ini didispose
  final RxInt? durasi = RxInt(0); // Make it RxInt
  final RxInt jam = RxInt(0);
  final RxInt menit = RxInt(0);
  final RxInt detik = RxInt(0);
  final RxBool _istimerunning = RxBool(false);
  final RxBool _triggerAddOnWktSlesai = RxBool(false);

  Timer? _timer;
  Timer? _apiSyncTimer;
  SharedPreferences? _prefs;
  Rx<DateTime> fixedTime = DateTime.now().obs;
  String idterapis2 = '';
  String idterapis3 = '';

  KamarTerapisMgr _kamarTerapisMgr = KamarTerapisMgr();

  @override
  void initState() {
    super.initState();
    // durasi?.value = 60 * widget.sumDurasi; // Initialize with sumDurasi
    // _startNewTimer();
    _initializeTimer();
    _loadSound();
  }

  Future<void> _initializeTimer() async {
    int sumDurasi = _kamarTerapisMgr.getData()['sumDurasi'];
    _prefs = await SharedPreferences.getInstance();

    // Try to load from API first
    bool apiLoaded = await _loadRemainingTimer();

    // Fallback to default if API fails
    if (!apiLoaded) {
      durasi?.value = 60 * sumDurasi;
      // durasi?.value = 60 * widget.sumDurasi;
    }

    _startNewTimer();
  }

  //Kalo ingin load data dari container yhang kita pilih sebelumnya

  // void _loaddata() async {
  //   _prefs = await SharedPreferences.getInstance();
  //   String savedtimerkey = 'start_timer_${widget.roomTitle}';
  //   final String? storedtimer = _prefs?.getString(savedtimerkey);

  //   if (storedtimer != null) {
  //     DateTime starttime = DateTime.parse(storedtimer);
  //     DateTime now = DateTime.now();finish
  //     int elapsedSeconds = now.difference(starttime).inSeconds;
  //     int remainingSeconds =
  //         (60 * 120) - elapsedSeconds; // Adjust duration accordingly

  //     setState(() {
  //       durasi = remainingSeconds > 0 ? remainingSeconds : 0;
  //       _istimerunning = durasi > 0;
  //       jam = durasi ~/ 3600;
  //       menit = (durasi % 3600) ~/ 60;
  //       detik = durasi % 60;
  //     });

  //     if (_istimerunning) {
  //       _startcountdown();
  //     }
  //   }
  // }

  //Start waktu baru
  void _startNewTimer() async {
    final now = DateTime.now();
    _prefs = await SharedPreferences.getInstance();
    await _prefs?.setString('new_timer_TerapisBekerja', now.toIso8601String());

    _istimerunning.value = true;

    _startcountdown();
    _startApiSyncTimer(); // Start API sync timer

    String namaTerapis = _kamarTerapisMgr.getData()['namaTerapis'];
    _namaTerapis.value = namaTerapis;

    getterapistambahan();
  }

  final RxInt timeSpent = RxInt(0);

  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> _loadSound() async {
    try {
      await _audioPlayer.setAsset('assets/audio/notifpanggilankerja.mp3');
      await _audioPlayer.setVolume(1.0);
    } catch (e) {
      debugPrint("Error loading sound: $e");
    }
  }

  int nowAttemptNotif = 0;
  int maxAttemptNotif = 1;
  Future<void> _playNotif() async {
    while (nowAttemptNotif < maxAttemptNotif) {
      try {
        // await Future.delayed(const Duration(milliseconds: 100)); // Give time for press animation
        if (_audioPlayer.playing) {
          await _audioPlayer.stop();
        }

        await _audioPlayer.seek(Duration.zero);
        await _audioPlayer.play();
      } catch (e) {
        debugPrint("Error playing sound: $e");
      }

      nowAttemptNotif++;
    }
  }

  void _startcountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (durasi?.value != null && durasi!.value > 0) {
        // hitung mundur durasi
        durasi?.value--; // Update Rx value

        // utk simpan waktu udh kebuang brp banyak. case utk ganti paket
        timeSpent.value++;
        // end simpan waktu
        _updateTimeComponents();

        if (durasi!.value <= 600) {
          _playNotif();
        }
      } else {
        // _timer?.cancel();
        // _istimerunning.value = false;
        // _apiSyncTimer?.cancel();

        // // panggil api utk delete waktu sementara disini.
        // _deleteWaktuTemp();
      }
    });
  }

  void _updateTimeComponents() {
    jam.value = durasi!.value ~/ 3600;
    menit.value = (durasi!.value % 3600) ~/ 60;
    detik.value = durasi!.value % 60;
  }

  // Call API every 1 minute to sync timer
  void _startApiSyncTimer() {
    _apiSyncTimer?.cancel(); // Cancel previous timer if exists
    _apiSyncTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      await _updateSisaTimer();

      _kamarTerapisMgr.setLimitChange();
    });
  }

  RxInt savedMinutes = 0.obs;
  Future<bool> _loadRemainingTimer() async {
    try {
      String idTransaksi = _kamarTerapisMgr.getData()['idTransaksi'];

      final response = await dio.get(
        '${myIpAddr()}/kamar_terapis/get_remaining_time',
        queryParameters: {
          "id_transaksi": idTransaksi,
          // "id_transaksi": widget.idTransaksi,
        },
      );

      // Kalo Return False, maka dia default ambil dari widget.sumDurasi
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        if (data.length == 0 || data.isEmpty) return false;

        // Ambil Menit Yg Udh Kesimpan
        // int savedMinutes = data[0];
        savedMinutes.value = data[0];
        String jamMulai = data[1];
        final parsedTime = DateFormat("HH:mm:ss").parse(jamMulai);
        final now = DateTime.now();

        fixedTime.value = DateTime(
          now.year,
          now.month,
          now.day,
          parsedTime.hour,
          parsedTime.minute,
          parsedTime.second,
        );

        // Utk Set Waktu Selesai
        _triggerAddOnWktSlesai.value = true;

        log(
          "🕒 fixedTime updated from API: ${fixedTime.value.toIso8601String()}",
        );

        durasi?.value = savedMinutes.value * 60;
        return true;
      }
    } catch (e) {
      log("Error loading timer: $e");
    }
    return false;
  }

  Future<void> _updateSisaTimer() async {
    try {
      String idTransaksi = _kamarTerapisMgr.getData()['idTransaksi'];

      var response = await dio.put(
        '${myIpAddr()}/kamar_terapis/update_menit',
        data: {
          // "id_transaksi": widget.idTransaksi,
          "id_transaksi": idTransaksi,
          "sum_durasi_menit": (durasi!.value ~/ 60),
        },
      );

      if (response.statusCode == 200) {
        log("Berhasil Update Waktu ${durasi!.value}");
      }
    } catch (e) {
      if (e is DioException) {
        log("Error ${e.response!.data}");
      }
    }
  }

  Future<void> _updateTunda() async {
    try {
      String idTransaksi = _kamarTerapisMgr.getData()['idTransaksi'];

      var response = await dio.put(
        '${myIpAddr()}/kamar_terapis/tunda',
        data: {
          // "id_transaksi": widget.idTransaksi,
          "id_transaksi": idTransaksi,
        },
      );

      if (response.statusCode == 200) {
        log("Berhasil Update Tunda");
      }
    } catch (e) {
      if (e is DioException) {
        log("Error Tunda ${e.response!.data}");
      }
    }
  }

  void _checkAndNavigate() async {
    if (durasi?.value != null && durasi!.value > 600) {
      Get.offAll(() => CustEndSblmWaktunya());
      _timer?.cancel();
      _apiSyncTimer?.cancel();
      _istimerunning.value = false;
    } else {
      bool result = await _kamarTerapisMgr.setSelesai();
      if (result) {
        // Get.offAll(() => TerapisConfirm());
        _timer?.cancel();
        _istimerunning.value = false;
        _apiSyncTimer?.cancel();

        // panggil api utk delete waktu sementara disini.
        _deleteWaktuTemp();
      } else {
        log("Error di fn _checkAndNavigate");
      }
    }
  }

  Future<void> getterapistambahan() async {
    try {
      String idTransaksi = _kamarTerapisMgr.getData()['idTransaksi'];
      namaterapis2.value = '';
      namaterapis3.value = '';
      var response3 = await dio.get(
        '${myIpAddr()}/kamar_terapis/dataterapistambahan',
        data: {"id_transaksi": idTransaksi},
      );

      List<dynamic> responseTerapis = response3.data;

      dataterapistambahan.assignAll(
        responseTerapis.map((e) => Map<String, dynamic>.from(e)).toList(),
      );

      log(dataterapistambahan[0].toString());
      if (idTransaksi != '') {
        if (dataterapistambahan.isNotEmpty) {
          namaterapis2.value = dataterapistambahan[0]['nama_karyawan'];
        }

        if (dataterapistambahan.length > 1) {
          namaterapis3.value = dataterapistambahan[1]['nama_karyawan'];
        }
      }

      if (namaterapis2.value != '') {
        var responseterapis2 = await dio.get(
          '${myIpAddr()}/kamar_terapis/getidterapistambahan',
          data: {"nama_karyawan": namaterapis2.value},
        );

        idterapis2 = responseterapis2.data[0]['id_karyawan'];
      }

      if (namaterapis3.value != '') {
        var responseterapis3 = await dio.get(
          '${myIpAddr()}/kamar_terapis/getidterapistambahan',
          data: {"nama_karyawan": namaterapis3.value},
        );
        idterapis3 = responseterapis3.data[0]['id_karyawan'];
      }
    } catch (e) {
      if (e is DioException) {
        log("Error di getdataterapistambahan ${e.response!.data}");
      }
    }
  }

  Future<void> setstatusterapisttambahan() async {
    try {
      var response = await dio.put(
        '${myIpAddr()}/kamar_terapis/setstatusterapistambahan',
        data: {
          "namaterapis2": namaterapis2.value,
          "namaterapis3": namaterapis3.value,
        },
      );
    } catch (e) {
      if (e is DioException) {
        log("Error di setstatusterapistambahan ${e.response}");
      }
    }
  }

  Future<void> _deleteWaktuTemp() async {
    try {
      String idTransaksi = _kamarTerapisMgr.getData()['idTransaksi'];

      var response = await dio.delete(
        '${myIpAddr()}/kamar_terapis/delete_waktu',
        data: {"id_transaksi": idTransaksi},
      );

      if (response.statusCode == 200) {
        log("Berhasil Delete waktu di db");

        await Future.delayed(Duration(seconds: 1));
        // if (Get.isRegistered<MainResepsionisController>()) {
        //   Get.delete<MainResepsionisController>();
        // }
        // Get.put(MainResepsionisController());

        Get.offAll(() => MainKamarTerapis());
      }
    } catch (e) {
      if (e is DioException) {
        log("Error di deletewaktutemp ${e.response!.data}");
      }
    }
  }

  Future<void> inputkomisi() async {
    String idTransaksi = _kamarTerapisMgr.getData()['idTransaksi'];
    String namaTerapis = _kamarTerapisMgr.getData()['namaTerapis'];
    List<dynamic>? datapaket = _kamarTerapisMgr.getData()['dataPaket'];
    List<dynamic>? dataproduk = _kamarTerapisMgr.getData()['dataProduk'];
    double komisi = 0;
    double komisigro = 0;
    Set<String> processedTransaction = {};
    Set<String> processedTransactionProduk = {};
    log(dataproduk.toString());
    List<String> namapaketlist =
        datapaket!.map((item) => item['nama_paket_msg'].toString()).toList();

    List<String> namaproduklist =
        dataproduk!.map((item) => item['nama_produk'].toString()).toList();

    List<String> idproduklist =
        dataproduk!.map((item) => item['id_produk'].toString()).toList();

    if (namapaketlist.length > 0) {
      for (int i = 0; i < namapaketlist.length; i++) {
        await Future.delayed(Duration(seconds: 1));

        var response2 = await dio.get(
          '${myIpAddr()}/komisi/getkomisipaket',
          data: {"nama_paket": namapaketlist[i]},
        );

        if (response2.data.isEmpty) {
          response2 = await dio.get(
            '${myIpAddr()}/komisi/getkomisiextend',
            data: {"nama_paket": namapaketlist[i]},
          );
        }

        var datanominalkomisi = response2.data[0]['nominal_komisi'];

        var datatipekomisi = response2.data[0]['tipe_komisi'];

        var datanominalkomisigro = response2.data[0]['nominal_komisi_gro'] ?? 0;

        var datatipekomisigro = response2.data[0]['tipe_komisi_gro'];
        var datahargapaket = response2.data[0]['harga_paket_msg'];

        var response3 = await dio.get(
          '${myIpAddr()}/komisi/getidpaket',
          data: {"nama_paket_msg": namapaketlist[i]},
        );

        if (response3.data.isEmpty) {
          response3 = await dio.get(
            '${myIpAddr()}/komisi/getidextend',
            data: {"nama_paket_msg": namapaketlist[i]},
          );
        }

        var dataidmsg = response3.data[0]['id_paket_msg'];

        var response4 = await dio.get(
          '${myIpAddr()}/komisi/getqtypaket',
          data: {"id_transaksi": idTransaksi, "id_paket": dataidmsg},
        );

        List<int> qtyList =
            (response4.data['qty'] as List<dynamic>)
                .map((item) => int.tryParse(item.toString()) ?? 0)
                .toList();

        List<int> statusList =
            (response4.data['status_addon'] as List<dynamic>)
                .map((item) => int.tryParse(item.toString()) ?? 0)
                .toList();

        String transactionKey = '${idTransaksi}_${dataidmsg}';

        if (!processedTransaction.contains(transactionKey)) {
          processedTransaction.add(transactionKey);

          //Pengulanan perhitungan komisi, di detail transaksi paket, ada kemugnkinan beberapa field memiliki nama paket yang sama sehigga harus dilakukan pengulangan seperti ini
          for (int i = 0; i < qtyList.length; i++) {
            var qty = qtyList[i];
            var status = statusList[i];

            if (datatipekomisi == 0) {
              komisi += datahargapaket * qty * datanominalkomisi / 100;
            } else {
              komisi += qty * datanominalkomisi;
            }

            if (status == 0) {
              if (datatipekomisigro == 0) {
                log('harga paket : $datahargapaket');
                log('qty paket : $qty');
                log('nominal komisi gro : ${datatipekomisigro / 100}');
                komisigro += datahargapaket * qty * datanominalkomisigro / 100;
              } else {
                log('harga paket : $datahargapaket');
                log('qty paket : $qty');
                log('nominal komisi gro : $datatipekomisigro');
                komisigro += qty * datanominalkomisigro;
              }
            }
          }
        }
      }
    }

    if (namaproduklist.length > 0) {
      for (int i = 0; i < namaproduklist.length; i++) {
        var response2 = await dio.get(
          '${myIpAddr()}/komisi/getkomisiproduk',
          data: {"nama_produk": namaproduklist[i]},
        );
        var datanominalkomisiproduk = response2.data[0]['nominal_komisi'];
        var datatipekomisiproduk = response2.data[0]['tipe_komisi'];
        var datanominalkomisiprodukgro =
            response2.data[0]['nominal_komisi_gro'];
        var datatipekomisiprodukgro = response2.data[0]['tipe_komisi_gro'];
        var datahargaproduk = response2.data[0]['harga_produk'];

        var response4 = await dio.get(
          '${myIpAddr()}/komisi/getqtyproduk',
          data: {"id_transaksi": idTransaksi, "id_produk": idproduklist[i]},
        );

        List<int> qtyListProduk =
            (response4.data['qty'] as List<dynamic>)
                .map((item) => int.tryParse(item.toString()) ?? 0)
                .toList();

        List<int> statuslistproduk =
            (response4.data['status_addon'] as List<dynamic>)
                .map((item) => int.tryParse(item.toString()) ?? 0)
                .toList();

        String transactionKeyProduk = '${idTransaksi}_${idproduklist[i]}';

        if (!processedTransactionProduk.contains(transactionKeyProduk)) {
          processedTransactionProduk.add(transactionKeyProduk);

          for (int i = 0; i < qtyListProduk.length; i++) {
            var qty = qtyListProduk[i];
            var status = statuslistproduk[i];

            if (datatipekomisiproduk == 0) {
              komisi += datahargaproduk * qty * datanominalkomisiproduk / 100;
            } else {
              komisi += qty * datanominalkomisiproduk;
            }

            if (status == 0) {
              if (datatipekomisiprodukgro == 0) {
                komisigro +=
                    datahargaproduk * qty * datanominalkomisiprodukgro / 100;
              } else {
                komisigro += qty * datanominalkomisiprodukgro;
              }
            }
          }
        }
      }
    }

    if (namapaketlist.length > 0 || namaproduklist.length > 0) {
      var response5 = await dio.get(
        '${myIpAddr()}/komisi/getidterapis',
        data: {"nama_karyawan": namaTerapis},
      );

      var response6 = await dio.get(
        '${myIpAddr()}/komisi/getidgro',
        data: {"id_transaksi": idTransaksi},
      );

      var idTerapis = response5.data[0]['id_karyawan'];

      var idGro = response6.data[0]['id_gro'];

      try {
        var response = await dio.post(
          '${myIpAddr()}/komisi/daftarkomisipekerja',
          data: {
            "id_karyawan": idTerapis,
            "id_transaksi": idTransaksi,
            "nominal_komisi": komisi,
          },
        );

        log(idterapis2.toString());
        log(idterapis3.toString());

        if (idterapis2 != '') {
          var komisiterapis2 = await dio.post(
            '${myIpAddr()}/komisi/daftarkomisipekerja',
            data: {
              "id_karyawan": idterapis2,
              "id_transaksi": idTransaksi,
              "nominal_komisi": komisi,
            },
          );
        }

        if (idterapis3 != '') {
          var komisiterapis3 = await dio.post(
            '${myIpAddr()}/komisi/daftarkomisipekerja',
            data: {
              "id_karyawan": idterapis3,
              "id_transaksi": idTransaksi,
              "nominal_komisi": komisi,
            },
          );
        }

        var responsee = await dio.post(
          '${myIpAddr()}/komisi/daftarkomisipekerja',
          data: {
            "id_karyawan": idGro,
            "id_transaksi": idTransaksi,
            "nominal_komisi": komisigro,
          },
        );

        log("data sukses tersimpan");
      } catch (e) {
        log("error: ${e.toString()}");
      }
    }
  }

  RxList<Map<String, dynamic>> _listTerapis = <Map<String, dynamic>>[].obs;
  RxString _idCurrentTerapis = "".obs;
  RxString _idTargetTerapis = "".obs;
  RxList<dynamic> dataterapistambahan = [].obs;
  RxString namaterapis2 = ''.obs;
  RxString namaterapis3 = ''.obs;

  RxString _namaTerapis = "".obs;

  Future<void> _getTerapis() async {
    try {
      var response = await dio.get('${myIpAddr()}/listpekerja/dataterapis');

      List<dynamic> responseData = response.data;

      _listTerapis.assignAll(responseData.map((item) => {...item}));
      log("${_listTerapis}");
    } catch (e) {
      log("Error Get Data Terapis $e");
    }
  }

  RxList<Map<String, dynamic>> _listRuangan = <Map<String, dynamic>>[].obs;
  RxString _kodeCurrentRuangan = "".obs;
  RxString _kodeTargetRuangan = "".obs;

  Future<void> _getRuangan() async {
    try {
      _kodeCurrentRuangan.value = _kamarTerapisMgr.getData()['kodeRuangan'];

      var response = await dio.get('${myIpAddr()}/listroom/dataroom');

      _listRuangan.assignAll(
        (response.data as List).map((el) {
          return {
            "id_ruangan": el['id_ruangan'],
            // id karyawan disini id akun ke tabel users
            "id_karyawan": el['id_karyawan'],
            "nama_ruangan": el['nama_ruangan'],
            "lantai": el['lantai'],
            "jenis_ruangan": el['jenis_ruangan'],
            "status": el['status'],
          };
        }).toList(),
      );
    } catch (e) {
      if (e is DioException) {
        log("Error Pada Saat get Ruangan ${e.response!.data}");
      }
    }
  }

  Future<void> daftapanggilankerja(namaruangan, namaterapis) async {
    try {
      var response = await dio.post(
        '${myIpAddr()}/spv/daftarpanggilankerja',
        data: {"ruangan": namaruangan, "nama_terapis": namaterapis},
      );
      log("data sukses tersimpan");
    } catch (e) {
      log("error: ${e.toString()}");
    }
  }

  Future<void> daftarruangtunggu(
    idtransaksi,
    namaruangan,
    idterapis,
    namaterapis,
  ) async {
    try {
      var response = await dio.post(
        '${myIpAddr()}/spv/daftarruangtunggu',
        data: {
          "id_transaksi": idtransaksi,
          "nama_ruangan": namaruangan,
          "id_terapis": idterapis,
          "nama_terapis": namaterapis,
        },
      );
      log("data sukses tersimpan");
    } catch (e) {
      log("error: ${e.toString()}");
    }
  }

  Future<void> _updateRuangan() async {
    try {
      String idTransaksi = _kamarTerapisMgr.getData()['idTransaksi'];

      var response = await dio.put(
        '${myIpAddr()}/revisi/ruangan',
        data: {
          "id_transaksi": idTransaksi,
          "prev_kode_ruangan": _kodeCurrentRuangan.value,
          "new_kode_ruangan": _kodeTargetRuangan.value,
        },
      );

      if (response.statusCode == 200) {
        // _listTerapis.map((item) {
        //   if (item['id_karyawan'] == _idTargetTerapis.value) {
        //     _namaTerapis.value = item['nama_karyawan'];
        //     _idCurrentTerapis.value = _idTargetTerapis.value;
        //     _idTargetTerapis.value = "";
        //   }
        // });
        // if (Get.isRegistered<MainResepsionisController>()) {
        //   Get.delete<MainResepsionisController>();
        // }
        // Get.put(MainResepsionisController());
        Get.offAll(() => MainKamarTerapis());
      }
    } catch (e) {
      if (e is DioException) {
        log("Error updateTerapis ${e.response!.data}");
      }
    }
  }

  void _showDialogRoom() async {
    await _getRuangan();

    Get.dialog(
      AlertDialog(
        title: const Center(
          child: Text(
            "List Room Tersedia",
            style: TextStyle(fontFamily: 'Poppins'),
          ),
        ),
        content: SizedBox(
          height: Get.height - 200,
          width: Get.width,
          child: ListView(
            children: [
              Obx(
                () => GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 30,
                    mainAxisSpacing: 25,
                    childAspectRatio: 2 / 1.5,
                  ),
                  itemCount: _listRuangan.length,
                  itemBuilder: (context, index) {
                    var data = _listRuangan[index];
                    // int noRoom = index + 1;
                    // Kondisi Ecek2 buat room penuh
                    bool isFull =
                        data['status'] == "maintenance" ||
                        data['status'] == "occupied";

                    return InkWell(
                      onTap: () async {
                        if (isFull) {
                          CherryToast.error(
                            title: Text(
                              "Ruangan Sedang ${data['status']}!",
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
                        } else {
                          // setState(() {
                          //   try {
                          //     // Attempt to access txtRoom directly (if in the same widget)
                          //     txtRoom.text = "Room ${data['nama_ruangan']}";
                          //     _idRuangan = data['id_ruangan'];
                          //   } catch (e) {
                          //     print(
                          //       "Error: txtRoom is not directly accessible here. Ensure it's properly managed by GetX.",
                          //     );
                          //   }
                          // });
                          // id_karyawan ini adlaah kode ruangan utk login.
                          _kodeTargetRuangan.value = data['id_karyawan'];
                          await _updateRuangan();
                          Get.back();
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              isFull
                                  ? const Color.fromARGB(255, 238, 5, 40)
                                  : const Color.fromARGB(255, 64, 97, 55),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.door_back_door,
                              size: 50,
                              color: Colors.white,
                            ),
                            Text(
                              "Room ${data['nama_ruangan']}",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            if (_kamarTerapisMgr.getData()['kodeRuangan'] ==
                                data['id_karyawan'])
                              Text(
                                "(Saat Ini)",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _getCurrentTransaksi() async {
    try {
      String idTransaksi = _kamarTerapisMgr.getData()['idTransaksi'];

      var response = await dio.get(
        '${myIpAddr()}/revisi/transaksi?id_transaksi=$idTransaksi',
      );

      Map<String, dynamic> responseData = response.data;

      _idCurrentTerapis.value = responseData['id_terapis'];
    } catch (e) {
      if (e is DioException) {
        log("Error Get Current Terapis ${e.response!.data}");
      }
    }
  }

  Future<void> _updateTerapis() async {
    try {
      String idTransaksi = _kamarTerapisMgr.getData()['idTransaksi'];

      var response = await dio.put(
        '${myIpAddr()}/revisi/terapis?id_transaksi=$idTransaksi',
        data: {
          "current_terapis": _idCurrentTerapis.value,
          "new_terapis": _idTargetTerapis.value,
        },
      );

      if (response.statusCode == 200) {
        // _listTerapis.map((item) {
        //   if (item['id_karyawan'] == _idTargetTerapis.value) {
        //     _namaTerapis.value = item['nama_karyawan'];
        //     _idCurrentTerapis.value = _idTargetTerapis.value;
        //     _idTargetTerapis.value = "";
        //   }
        // });
        // if (Get.isRegistered<MainResepsionisController>()) {
        //   Get.delete<MainResepsionisController>();
        // }
        // Get.put(MainResepsionisController());
        Get.offAll(() => MainKamarTerapis());
      }
    } catch (e) {
      if (e is DioException) {
        log("Error updateTerapis ${e.response!.data}");
      }
    }
  }

  Future<void> panggilob() async {
    try {
      String idTransaksi = _kamarTerapisMgr.getData()['idTransaksi'];
      var response = await dio.put(
        '${myIpAddr()}/kamar_terapis/panggilob',
        data: {"id_transaksi": idTransaksi},
      );
    } catch (e) {
      log("Error di panggilob : $e");
    }
  }

  void _showdialogterapis() async {
    await Future.wait([_getTerapis(), _getCurrentTransaksi()]);

    Get.dialog(
      AlertDialog(
        title: Center(
          child: Text(
            "Choose Therapist",
            style: TextStyle(fontFamily: 'Poppins'),
          ),
        ),
        content: Container(
          width: Get.width,
          height: Get.height - 200,
          child: SingleChildScrollView(
            child: Obx(
              () => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 30,
                  mainAxisSpacing: 25,
                  childAspectRatio: 2 / 1.5,
                ),
                itemCount: _listTerapis.length,
                itemBuilder: (context, index) {
                  var data = _listTerapis[index];
                  bool isOccupied = data['is_occupied'] == 1;
                  String idroom = _kamarTerapisMgr.getData()['namaRuangan'];
                  String idtransaksi =
                      _kamarTerapisMgr.getData()['idTransaksi'];

                  return InkWell(
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    onTap: () async {
                      if (isOccupied) {
                        CherryToast.error(
                          title: Text(
                            "${data['nama_karyawan']} Is Occupied!",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          animationDuration: const Duration(milliseconds: 1500),
                          autoDismiss: true,
                        ).show(Get.context!); // Use Get.context!
                      } else {
                        try {
                          _idTargetTerapis.value = data['id_karyawan'];
                          await _updateTerapis();

                          daftapanggilankerja(
                            "Room " + idroom,
                            data['nama_karyawan'],
                          );

                          if (Get.isRegistered<ControllerPanggilanKerja>()) {
                            Get.delete<ControllerPanggilanKerja>();
                          }
                          var c = Get.put(ControllerPanggilanKerja());
                          c.refreshDataPanggilanKerja();

                          daftarruangtunggu(
                            idtransaksi,
                            "Room " + idroom,
                            data['id_karyawan'],
                            data['nama_karyawan'],
                          );
                          Get.back();
                        } catch (e) {
                          log("Error Inkwell pas update terapis $e");
                        }
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(top: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color:
                            isOccupied
                                ? const Color.fromARGB(255, 238, 5, 40)
                                : const Color.fromARGB(255, 35, 195, 144),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(
                                top: 20,
                                left: 12,
                                right: 12,
                              ),
                              child: Text(
                                '${data['id_karyawan']}',
                                style: TextStyle(fontSize: 30),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 10),
                                  Text(
                                    "${data['nama_karyawan']}",
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  if (data['id_karyawan'] ==
                                      _idCurrentTerapis.value)
                                    Text(
                                      "(Saat ini)",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'Poppins',
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                ],
                              ),
                            ),
                          ],
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
    );
  }

  void _showdialogrevisi() {
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Color(0XFFFFE0B2),
            content: Container(
              decoration: BoxDecoration(
                color: Color(0XFFFFE0B2),
                border: Border.all(color: Color(0XFFFFE0B2), width: 1),
              ),
              width: Get.width,
              height: Get.height - 330,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () {
                      var permit = _kamarTerapisMgr.getLimitChange();
                      if (permit) {
                        _showdialogterapis();
                      } else {
                        Get.snackbar(
                          'Error',
                          'Lewat 15 Menit. tidak Bisa Lagi',
                        );
                      }
                    },
                    child: iconaction(
                      icon: Icons.person,
                      title: 'Ganti Terapis',
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      _showDialogRoom();
                    },
                    child: iconaction(
                      icon: Icons.production_quantity_limits,
                      title: 'Ganti Ruangan',
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      var permit = _kamarTerapisMgr.getLimitChange();
                      if (permit) {
                        // jika controller sudah diregister, maka delete. supaya instanceny fresh
                        if (Get.isRegistered<GantiPaketController>()) {
                          Get.delete<GantiPaketController>();
                        }
                        // Put ulang
                        var controller = Get.put(
                          GantiPaketController(timeSpent: timeSpent.value),
                        );
                        // get current paket dlu br tembak ke btn gantipaket
                        controller
                            ._getCurrentPaket()
                            .then((_) {
                              controller.buttongantipaket();
                            })
                            .catchError((onError) {
                              log("Error di getcurrentpaket $onError");
                            });
                      } else {
                        Get.snackbar(
                          'Error',
                          'Lewat 15 Menit. tidak Bisa Lagi',
                        );
                      }
                    },
                    child: iconaction(
                      icon: Icons.menu_book_outlined,
                      title: 'Ganti Paket',
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      String idTransaksi =
                          _kamarTerapisMgr.getData()['idTransaksi'];
                      String namaRuangan =
                          _kamarTerapisMgr.getData()['namaRuangan'];
                      Get.to(
                        () => AddonPaketProduk(
                          idTrans: idTransaksi,
                          namaRuangan: namaRuangan,
                        ),
                      );
                    },
                    child: iconaction(
                      icon: Icons.meeting_room,
                      title: 'Tambah Paket / Produk',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _apiSyncTimer?.cancel();

    durasi?.close(); // Important: Dispose Rx variables
    jam.close();
    menit.close();
    detik.close();
    _istimerunning.close();
    _triggerAddOnWktSlesai.close();
    fixedTime.close();
    savedMinutes.close();
    _listTerapis.close();
    _idCurrentTerapis.close();
    _idTargetTerapis.close();
    _namaTerapis.close();
    super.dispose();
  }

  var dio = Dio();

  ScrollController scrollListOrderan = ScrollController();

  @override
  Widget build(BuildContext context) {
    var globalData = _kamarTerapisMgr.getData();

    return Scaffold(
      body: WillPopScope(
        onWillPop: () async {
          // bool? result = await Get.dialog(
          //   AlertDialog(
          //     title: const Text("Keluar"),
          //     content: const Text(
          //       "Apakah Yakin ingin Keluar? Progress anda akan ditunda",
          //     ),
          //     actions: [
          //       ElevatedButton(
          //         onPressed: () {
          //           Get.back(result: false);
          //         },
          //         child: Text("No"),
          //       ),
          //       ElevatedButton(
          //         onPressed: () async {
          //           try {
          //             await _updateTunda();
          //             Get.back(result: true); // Close dialog first
          //             // if (Get.isRegistered<MainResepsionisController>()) {
          //             //   Get.delete<MainResepsionisController>();
          //             // }
          //             // Get.put(MainResepsionisController());
          //             Get.offAll(() => MainKamarTerapis());
          //           } catch (e) {
          //             Get.back(result: false);
          //             log("Error $e");
          //           }
          //         },
          //         child: Text("Yes"),
          //       ),
          //     ],
          //   ),
          // );
          // return result ?? false;
          return false;
        },
        child: Container(
          color: Color(0XFFFFE0B2),
          width: Get.width,
          height: Get.height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: Get.height * 0.15,
                width: Get.width,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 25, left: 30, right: 100),
                      child: ElevatedButton(
                        onPressed: panggilob,
                        child: Text(
                          'Panggil OB',
                          style: TextStyle(fontSize: 20, fontFamily: 'Poppins'),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.only(left: 100),
                        alignment: Alignment.center,
                        child: AutoSizeText(
                          'Sisa Waktu',
                          style: TextStyle(fontSize: 60, fontFamily: 'Poppins'),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        alignment: Alignment.topRight,
                        padding: EdgeInsets.only(right: 10, top: 10),
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(100)),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/spa.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Center(
                child: Container(
                  height: 180,
                  child: Obx(
                    () => AutoSizeText(
                      _istimerunning.value
                          ? '${jam.value} : ${menit.value.toString().padLeft(2, '0')} : ${detik.value.toString().padLeft(2, '0')} '
                          : '${jam.value} : ${menit.value.toString().padLeft(2, '0')} : ${detik.value.toString().padLeft(2, '0')} ',
                      style: TextStyle(fontSize: 180, fontFamily: 'Poppins'),
                    ),
                  ),
                ),
              ),
              Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {
                        Get.to(
                          ExtendAddOn(
                            idDetailTransaksi: globalData['idDetailTransaksi'],

                            // idDetailTransaksi: widget.idDetailTransaksi,
                          ),
                        );
                      },
                      child: iconaction(
                        icon: Icons.timer,
                        title: 'Extends Jam',
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Get.to(FoodAddOn());
                      },
                      child: iconaction(
                        icon: Icons.local_dining_rounded,
                        title: 'Food & Beverages',
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        _showdialogrevisi();
                      },
                      child: iconaction(
                        icon: Icons.meeting_room,
                        title: 'Revisi',
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Get.dialog(
                          AlertDialog(
                            title: Text('Confirm'),
                            content: Text('Selesaikan pelayanan?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Get.back();
                                },
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Get.back();
                                  inputkomisi();
                                  _checkAndNavigate();

                                  if (namaterapis2.value != '' ||
                                      namaterapis3.value != '') {
                                    setstatusterapisttambahan();
                                    log('jalankan');
                                  }

                                  namaterapis2.value = '';
                                  namaterapis3.value = '';
                                },
                                child: Text('Confirm'),
                              ),
                            ],
                          ),
                          barrierDismissible: false,
                        );
                      },
                      child: iconaction(icon: Icons.check, title: 'Finish'),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Container(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          child: Row(
                            children: [
                              Container(
                                width: 230,
                                padding: EdgeInsets.only(left: 10),
                                child: Text(
                                  'Waktu Mulai',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Container(
                                child: Text(
                                  '-',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              SizedBox(width: 15),
                              Container(
                                width: 160,
                                child: Obx(() {
                                  String formattedTime =
                                      "${fixedTime.value.hour.toString().padLeft(2, '0')} :"
                                      "${fixedTime.value.minute.toString().padLeft(2, '0')} :"
                                      "${fixedTime.value.second.toString().padLeft(2, '0')}";

                                  return Text(
                                    '$formattedTime',
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontFamily: 'Poppins',
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                width: 230,
                                padding: EdgeInsets.only(left: 10),
                                child: Text(
                                  'Waktu Selesai',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Container(
                                child: Text(
                                  '-',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              SizedBox(width: 15),
                              Container(
                                width: 160,
                                child: Obx(() {
                                  final DateTime FixedTimeEnd = fixedTime.value
                                      .add(
                                        Duration(
                                          minutes:
                                              _triggerAddOnWktSlesai.isTrue
                                                  ? savedMinutes.value
                                                  : globalData['sumDurasi'],
                                          // minutes: widget.sumDurasi,
                                        ),
                                      );

                                  String formattedTimeEnd =
                                      "${FixedTimeEnd.hour.toString().padLeft(2, '0')} :"
                                      "${FixedTimeEnd.minute.toString().padLeft(2, '0')} :"
                                      "${FixedTimeEnd.second.toString().padLeft(2, '0')}";

                                  return Text(
                                    '$formattedTimeEnd',
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontFamily: 'Poppins',
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              margin: EdgeInsets.only(left: 10, top: 0),
                              width: 460,
                              height: 90,
                              decoration: BoxDecoration(
                                color: Color(0xFF333333).withOpacity(0.4),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
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
                                        child: Text(
                                          'Y',
                                          style: TextStyle(fontSize: 25),
                                        ),
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(
                                            top: 7,
                                            left: 20,
                                          ),
                                          child: Text(
                                            'Room ${globalData['namaRuangan']}',
                                            style: TextStyle(
                                              fontSize: 25,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(left: 20),
                                          child: Obx(
                                            () => Text(
                                              'Terapis : ${_namaTerapis.value} ${namaterapis2.value == '' ? '' : ','} ${namaterapis2.value} ${namaterapis3.value == '' ? '' : ','} ${namaterapis3.value}',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      margin: EdgeInsets.only(left: 20, top: 10),
                      width: 580,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Color(0xFF333333).withOpacity(0.4),
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(top: 10, left: 10, bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'List Orderan :',
                              style: TextStyle(
                                height: 1,
                                fontSize: 30,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            SizedBox(
                              height: 120,
                              width: double.infinity,
                              child: Scrollbar(
                                thumbVisibility: true,
                                thickness: 8.0,
                                radius: const Radius.circular(10),
                                controller: scrollListOrderan,
                                child: ListView(
                                  controller: scrollListOrderan,
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    if ((globalData['dataPaket'] as List)
                                        .isNotEmpty) ...[
                                      for (var (i, item)
                                          in (globalData['dataPaket'] as List)
                                              .indexed)
                                        isitekslist(
                                          '${i + 1}. ${item['nama_paket_msg']} ${item['is_addon'] == 1 ? '+ (${item['total_durasi']})' : ''}',
                                        ),
                                    ],
                                    if ((globalData['dataProduk'] as List)
                                        .isNotEmpty) ...[
                                      for (var (i, item)
                                          in (globalData['dataProduk'] as List)
                                              .indexed)
                                        isitekslist(
                                          '${i + 1 + (globalData['dataPaket'] as List).length}. ${item['nama_produk']} ${item['is_addon'] == 1 ? '+ (${item['total_durasi']})' : ''}',
                                        ),
                                    ],
                                    if ((globalData['dataFood'] as List)
                                        .isNotEmpty) ...[
                                      for (var (i, item)
                                          in (globalData['dataFood'] as List)
                                              .indexed)
                                        isitekslist(
                                          '${i + 1 + (globalData['dataPaket'] as List).length + (globalData['dataProduk'] as List).length}. ${item['nama_fnb']} ${item['is_addon'] == 1 ? '+ (${item['qty']} Pcs)' : ''}',
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
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

class iconaction extends StatelessWidget {
  const iconaction({super.key, required this.icon, required this.title});
  final icon;
  final title;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 30),
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        border: Border.all(width: 0, color: Colors.white),
        borderRadius: BorderRadius.all(Radius.circular(30)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(child: Icon(icon, size: 150)),
          Container(
            child: Text(title, style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }
}

class GantiPaketController extends GetxController {
  final int timeSpent;
  GantiPaketController({required this.timeSpent});

  var dio = Dio();
  KamarTerapisMgr _kamarTerapisMgr = KamarTerapisMgr();

  var formatter = NumberFormat.currency(
    locale: "en_ID",
    symbol: "Rp. ",
    decimalDigits: 0,
  );

  RxList<Map<String, dynamic>> _listCurrentPaket = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> _listAllPaket = <Map<String, dynamic>>[].obs;

  Future<void> _getCurrentPaket() async {
    try {
      String idTrans = _kamarTerapisMgr.getData()['idTransaksi'];
      var token = await getTokenSharedPref();

      var response = await dio.get(
        '${myIpAddr()}/kamar_terapis/latest_trans?id_trans=$idTrans',
        options: Options(headers: {"Authorization": "bearer " + token!}),
      );

      List<dynamic> responsePaket = response.data['data_paket'];
      // log("Isi Response Paket $responsePaket");

      _listCurrentPaket.assignAll(
        responsePaket.map((el) => Map<String, dynamic>.from(el)).toList(),
      );

      log("Isi List Current Paket $_listCurrentPaket");
    } catch (e) {
      if (e is DioException) {
        throw Exception("Error getCurrentPaket ${e.response!.data}");
      }
    }
  }

  Future<void> _getAllPaket() async {
    try {
      var response = await dio.get('${myIpAddr()}/massages/paket');

      List<dynamic> responsePaket = response.data;

      _listAllPaket.assignAll(
        responsePaket.map((el) => Map<String, dynamic>.from(el)).toList(),
      );
    } catch (e) {
      if (e is DioException) {
        throw Exception("Error pas GetAllPaket ${e.response!.data}");
      }
    }
  }

  RxString _currentIdDetail = "".obs;
  Future<void> _storeGantiPaket(String newIdPaket) async {
    String idTransaksi = _kamarTerapisMgr.getData()['idTransaksi'];
    var newData =
        _listAllPaket.where((el) => el['id_paket_msg'] == newIdPaket).toList();

    var data = {
      "id_transaksi": idTransaksi,
      "id_detail_diretur": _currentIdDetail.value,
      "alasan_retur": "ganti_paket",
      "time_spent": timeSpent,
      "item_pengganti": {...newData[0]},
    };

    try {
      var response = await dio.put(
        '${myIpAddr()}/kamar_terapis/retur_paket',
        data: data,
      );

      if (response.statusCode == 200) {
        print("Bla sukses");
        await _kamarTerapisMgr.updateDataProdukPaket(idTransaksi);
        Get.offAll(() => TerapisBekerja());
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception("Error di Store Gantipaket ${e.response!.data}");
      }
    }
  }

  void buttongantipaket() async {
    Get.dialog(
      AlertDialog(
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            width: Get.width - 100,
            height: Get.height - 110,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        'Paket Awal Anda',
                        style: TextStyle(fontSize: 30),
                      ),
                    ),
                  ),
                  Obx(
                    () => Column(
                      children:
                          _listCurrentPaket.map((data) {
                            // log("Isi data _ListCurrentPaket $data");
                            // Jika harga_total paket == 0 maka member
                            if (data['is_addon'] == 1) {
                              return Visibility(
                                // Tampilin Yg Kodenya Massage Saja
                                visible: data['id_paket'][0] == "M",
                                child: isibuttongantipaket(
                                  data['nama_paket_msg'],
                                  data['id_detail_transaksi'],
                                  // _listCurrentPaket.indexOf(data),
                                  is_addon: true,
                                  total_durasi: data['total_durasi'],
                                  isMember: data['harga_total'] == 0,
                                ),
                              );
                            } else {
                              return Visibility(
                                // Tampilin Yg Kodenya Massage Saja
                                visible: data['id_paket'][0] == "M",
                                child: isibuttongantipaket(
                                  data['nama_paket_msg'],
                                  data['id_detail_transaksi'],
                                  // _listCurrentPaket.indexOf(data),
                                  isMember: data['harga_total'] == 0,
                                ),
                              );
                            }
                          }).toList(),
                    ),
                  ),
                  // Obx(
                  //   () => isibuttongantipaket(paketcontroller.pilihanpaket[0], 0),
                  // ),
                  // Obx(
                  //   () => isibuttongantipaket(paketcontroller.pilihanpaket[1], 1),
                  // ),
                  // Obx(
                  //   () => isibuttongantipaket(paketcontroller.pilihanpaket[2], 2),
                  // ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget isibuttongantipaket(
    tekspaket,
    idDetail, {
    bool is_addon = false,
    int total_durasi = 0,
    bool isMember = false,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 600,
              child:
                  is_addon
                      ? isitekslist(
                        tekspaket + " (${total_durasi} Menit) AddOn",
                      )
                      : isitekslist(tekspaket),
            ),
            InkWell(
              onTap: () {
                if (isMember) {
                  CherryToast.error(
                    title: Text(
                      "Tidak Boleh Ganti Paket Member",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    animationDuration: const Duration(milliseconds: 1500),
                    autoDismiss: true,
                  ).show(Get.context!); // Use Get.context!
                  return;
                }
                _currentIdDetail.value = idDetail;
                pilihpaket(tekspaket);

                print("Isi ID Detil $idDetail");
                print("Isi currentIdDetail ${_currentIdDetail.value}");
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  color: Colors.green.withOpacity(0.3),
                ),
                width: 200,
                child: Center(
                  child: Text('Ganti Paket', style: TextStyle(fontSize: 30)),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
      ],
    );
  }

  void pilihpaket(nama_paket) async {
    await _getAllPaket();

    ScrollController _scrollController = ScrollController();
    Get.dialog(
      AlertDialog(
        actions: [
          Container(
            width: Get.width - 150,
            height: Get.height - 150,
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.only(top: 10),
                height: Get.height - 100,
                child: Scrollbar(
                  thumbVisibility: true,
                  controller: _scrollController,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Obx(() {
                      // Ambil Current Data dlu, Cocokkan dgn IdDetail Current
                      var currDetail =
                          _listCurrentPaket
                              .where(
                                (el) =>
                                    el['id_detail_transaksi'] ==
                                    _currentIdDetail.value,
                              )
                              .toList();

                      // Ambil data paket kaya harga dll di listAllPaket
                      var currPaket =
                          _listAllPaket
                              .where(
                                (el) =>
                                    el['id_paket_msg'] ==
                                    currDetail[0]['id_paket'],
                              )
                              .toList();

                      // kemudian filter paket yg lebih mahal dr paket sblmny
                      var lebihMahal =
                          _listAllPaket
                              .where(
                                (el) =>
                                    el['harga_paket_msg'] >=
                                    currPaket[0]['harga_paket_msg'],
                              )
                              .toList();

                      return GridView.builder(
                        controller: _scrollController,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3, // 3 item 1 row
                              crossAxisSpacing:
                                  60, // space horizontal tiap item
                              mainAxisSpacing: 25, // space vertical tiap item

                              childAspectRatio: 20 / 12,
                            ),
                        // awalnya berdasarkan _listAllPaket
                        itemCount: lebihMahal.length,
                        itemBuilder: (context, idx) {
                          var data = lebihMahal[idx];
                          bool current = nama_paket == data['nama_paket_msg'];

                          return InkWell(
                            onTap: () async {
                              if (current) {
                                Get.snackbar("Error", "Paket Saat Ini");
                              } else {
                                // paketcontroller.pilihanpaket[index] =
                                //     'Item ${paketindex + 1}';
                                await _storeGantiPaket(data['id_paket_msg']);
                                Get.back();
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    current
                                        ? const Color.fromARGB(255, 206, 8, 8)
                                        : const Color.fromARGB(255, 64, 97, 55),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.feed_outlined,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                  Text(
                                    "${data['nama_paket_msg']}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    "${formatter.format(data['harga_paket_msg'])}\n ${data['durasi']} Menit",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (current)
                                    Text(
                                      "(Saat Ini)",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// class GantiPaket extends StatelessWidget {
//   GantiPaket({super.key}) {
//     Get.put(GantiPaketController());
//   }

//   @override
//   Widget build(BuildContext context) {
//     final c = Get.find<GantiPaketController>();
//     return Text("Hai");
//   }
// }

Widget isitekslist(isi) {
  return Text(isi, style: TextStyle(fontSize: 28, fontFamily: 'Poppins'));
}

// class Paketcontroller extends GetxController {
//   var pilihanpaket = <String>["Item 7", "Item 2", "Item 3"].obs;
// }

// final Paketcontroller paketcontroller = Get.put(Paketcontroller());
