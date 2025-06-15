import 'dart:developer';
import 'package:Project_SPA/admin/laporan_ob.dart';
import 'package:Project_SPA/admin/listpaket.dart';
import 'package:Project_SPA/admin/listpekerja.dart';
import 'package:Project_SPA/admin/listpromo.dart';
import 'package:Project_SPA/admin/listroom.dart';
import 'package:Project_SPA/admin/listuser.dart';
import 'package:Project_SPA/admin/regis_locker.dart';
import 'package:Project_SPA/admin/regis_paket.dart';
import 'package:Project_SPA/admin/regis_pekerja.dart';
import 'package:Project_SPA/admin/regis_promo.dart';
import 'package:Project_SPA/admin/regis_room.dart';
import 'package:Project_SPA/admin/regis_users.dart';
import 'package:Project_SPA/function/admin_drawer.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:Project_SPA/resepsionis/billing_locker.dart';
import 'package:Project_SPA/resepsionis/jenis_transaksi.dart';
import 'package:Project_SPA/main.dart';
import 'package:dio/dio.dart';
import 'package:Project_SPA/function/ip_address.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';

class RegisPromo extends StatefulWidget {
  const RegisPromo({super.key});

  @override
  State<RegisPromo> createState() => _RegisPromoState();
}

class _RegisPromoState extends State<RegisPromo> {
  var hargaSatuan = 0.0.obs;
  var limitKunjungan = 1.obs;
  RxDouble hargaPromo = 0.0.obs;
  var diskonPaket = 0.0.obs;

  final TextEditingController _textController = TextEditingController();
  final TextEditingController controller_kode_promo = TextEditingController();
  final TextEditingController controller_nama_promo = TextEditingController();
  final TextEditingController controller_diskon_promo = TextEditingController();
  final TextEditingController controller_jam_mulai = TextEditingController();
  final TextEditingController controller_menit_mulai = TextEditingController();
  final TextEditingController controller_jam_selesai = TextEditingController();
  final TextEditingController controller_menit_selesai =
      TextEditingController();

  final TextEditingController controller_kode_promo_kunjungan =
      TextEditingController();
  final TextEditingController controller_nama_promo_kunjungan =
      TextEditingController();
  final TextEditingController controller_hargasatuan = TextEditingController();
  final TextEditingController controller_limit_promo = TextEditingController();
  final TextEditingController controller_limit_kunjungan =
      TextEditingController();
  final TextEditingController controller_diskon_paket = TextEditingController();
  final TextEditingController controller_harga_promo_kunjungan =
      TextEditingController();

  final TextEditingController controller_kode_promo_tahunan =
      TextEditingController();
  final TextEditingController controller_nama_promo_tahunan =
      TextEditingController();
  final TextEditingController controller_jangka_tahunan =
      TextEditingController();
  final TextEditingController controller_harga_promo_tahunan =
      TextEditingController();
  List<Map<String, dynamic>> _listNamaPaket = [];
  String? dropdownNamaPaket;

  var dio = Dio();
  bool _isSecondContainerOnTop = false;
  bool _isThirdContainerOnTop = false;
  bool _isFirstContainerOnTop = true;

  Color _FirstbuttonColor = Colors.blue;
  Color _SecondbuttonColor = Colors.white;
  Color _ThirdbuttonColor = Colors.white;

  bool isUmumChecked = false;
  bool isMemberChecked = false;
  bool isVIPChecked = false;
  bool isSeninChecked = false;
  bool isSelasaChecked = false;
  bool isRabuChecked = false;
  bool isKamisChecked = false;
  bool isJumatChecked = false;
  bool isSabtuChecked = false;
  bool isMingguChecked = false;

  int? _selectedRadio;

  List<dynamic> kode_promo = [];

  int valuesenin = 0;
  int valueselasa = 0;
  int valuerabu = 0;
  int valuekamis = 0;
  int valuejumat = 0;
  int valuesabtu = 0;
  int valueminggu = 0;
  int valueumum = 0;
  int valuevip = 0;
  int valuemember = 0;

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _textController.clear();
  }

  @override
  void initState() {
    // TODO: implement initState
    getDataPaket();
    hargaPromo.value = 0;
    dropdownNamaPaket = null;
    super.initState();
  }

  void _moveSecondContainerToTop() {
    setState(() {
      _isSecondContainerOnTop = true;
      _isFirstContainerOnTop = false;
      _isThirdContainerOnTop = false;
    });
  }

  void _moveFirstContainerToTop() {
    setState(() {
      _isSecondContainerOnTop = false;
      _isFirstContainerOnTop = true;
      _isThirdContainerOnTop = false;
    });
  }

  void _moveThirdContainerToTop() {
    setState(() {
      _isSecondContainerOnTop = false;
      _isThirdContainerOnTop = true;
      _isFirstContainerOnTop = false;
    });
  }

  void _toggleButtonColors({required int buttonIndex}) {
    setState(() {
      if (buttonIndex == 1) {
        _FirstbuttonColor = Colors.blue;
        _SecondbuttonColor = Colors.white;
        _ThirdbuttonColor = Colors.white;
      } else if (buttonIndex == 2) {
        _FirstbuttonColor = Colors.white;
        _SecondbuttonColor = Colors.blue;
        _ThirdbuttonColor = Colors.white;
      } else if (buttonIndex == 3) {
        _FirstbuttonColor = Colors.white;
        _SecondbuttonColor = Colors.white;
        _ThirdbuttonColor = Colors.blue;
      }
    });
  }

  int selectedDurasi = 0;

  Future<void> getDataPaket() async {
    try {
      var response = await dio.get(
        '${myIpAddr()}/listmassage/getdatapaketmassage',
      );
      setState(() {
        _listNamaPaket =
            (response.data as List).map((item) {
              return {
                "id_paket_msg": item["id_paket_msg"],
                "nama_paket_msg": item["nama_paket_msg"],
                "harga_paket_msg": item["harga_paket_msg"],
                "durasi": item["durasi"],
              };
            }).toList();
      });
    } catch (e) {
      log("Error di fn Get Data Paket $e");
    }
  }

  Future<void> inputdatapromohappyhour() async {
    String kodePromo = controller_kode_promo.text;
    String namaPromo = controller_nama_promo.text;
    String discPromo = controller_diskon_promo.text;
    String jamMulai = controller_jam_mulai.text;
    String menitMulai = controller_menit_mulai.text;
    String jamSelesai = controller_jam_selesai.text;
    String menitSelesai = controller_menit_selesai.text;

    try {
      var response2 = await dio.get('${myIpAddr()}/promo/getidpromo');
      setState(() {
        kode_promo = response2.data;
      });
      bool packageExists = kode_promo.any(
        (item) => item['kode_promo'] == kodePromo,
      );
      if (kodePromo != "" &&
          namaPromo != "" &&
          discPromo != "" &&
          jamMulai != "" &&
          menitMulai != "" &&
          jamSelesai != "" &&
          menitSelesai != "") {
        if (!packageExists) {
          var response = await dio.post(
            '${myIpAddr()}/promo/daftarpromohappyhour',
            data: {
              "kode_promo": kodePromo,
              "nama_promo": namaPromo,
              "disc": int.parse(discPromo),
              "senin": valuesenin,
              "selasa": valueselasa,
              "rabu": valuerabu,
              "kamis": valuekamis,
              "jumat": valuejumat,
              "sabtu": valuesabtu,
              "minggu": valueminggu,
              "jam_mulai": "$jamMulai:$menitMulai",
              "jam_selesai": "$jamSelesai:$menitSelesai",
              "umum": valueumum,
              "member": valuemember,
              "vip": valuevip,
            },
          );
          log("data sukses tersimpan");
          CherryToast.success(
            title: Text('paket ${kodePromo} Saved successfully!'),
          ).show(context);
          controller_nama_promo.clear();
          controller_kode_promo.clear();
          controller_diskon_promo.clear();
          controller_menit_mulai.clear();
          controller_menit_selesai.clear();
          controller_jam_mulai.clear();
          controller_jam_selesai.clear();
          setState(() {
            isSelasaChecked = false;
            isSeninChecked = false;
            isRabuChecked = false;
            isKamisChecked = false;
            isJumatChecked = false;
            isSabtuChecked = false;
            isMingguChecked = false;
            isUmumChecked = false;
            isVIPChecked = false;
            isMemberChecked = false;  
          });
        } else {
          log("data gagal tersimpan");
          CherryToast.error(
            title: Text('paket ${kodePromo} Already existed!'),
          ).show(context);
        }
      } else {
        log("data kosong");
        CherryToast.warning(
          title: Text('Data inputan tidak boleh kosong'),
        ).show(context);
      }
    } catch (e) {
      log("error: ${e.toString()}");
    }
  }

  Future<void> inputdatapromokunjungan() async {
    String kodePromoKunjungan = controller_kode_promo_kunjungan.text;
    String limitKunjungan = controller_limit_kunjungan.text;
    String limitPromo = controller_limit_promo.text;
    String diskonPaket = controller_diskon_paket.text;
    int hargaPromoKunjungan = hargaPromo.value.toInt();
    try {
      var response2 = await dio.get('${myIpAddr()}/promo/getidpromo');
      setState(() {
        kode_promo = response2.data;
      });
      bool packageExists = kode_promo.any(
        (item) => item['kode_promo'] == kodePromoKunjungan,
      );
      bool namapackageExists = kode_promo.any(
        (item) => item['nama_promo'] == dropdownNamaPaket!,
      );

      if (kodePromoKunjungan != "" &&
          dropdownNamaPaket != "" &&
          limitKunjungan != "" &&
          limitPromo != "" &&
          diskonPaket != "") {
        if (!packageExists && !namapackageExists) {
          var response = await dio.post(
            '${myIpAddr()}/promo/daftarpromokunjungan',
            data: {
              "kode_promo": kodePromoKunjungan,
              "nama_promo": dropdownNamaPaket,
              "limit_kunjungan": int.parse(limitKunjungan),
              "limit_promo": int.parse(limitPromo),
              "durasi": selectedDurasi,
              "discount": int.parse(diskonPaket),
              "harga_promo": hargaPromoKunjungan,
              "harga_satuan": hargaSatuan.value,
            },
          );
          log("data sukses tersimpan");
          CherryToast.success(
            title: Text('paket ${kodePromoKunjungan} Saved successfully!'),
          ).show(context);
          setState(() {
            dropdownNamaPaket = null;
          });
          hargaPromo.value = 0.0;
          controller_kode_promo_kunjungan.clear();
          controller_nama_promo_kunjungan.clear();
          controller_limit_kunjungan.clear();
          controller_harga_promo_kunjungan.clear();
          controller_hargasatuan.clear();
          controller_limit_promo.clear();
          controller_diskon_paket.clear();
        } else {
          log("data gagal tersimpan");
          if (packageExists) {
            CherryToast.error(
              title: Text('paket ${kodePromoKunjungan} Already existed!'),
            ).show(context);
          } else {
            CherryToast.error(
              title: Text('paket ${dropdownNamaPaket} Already existed!'),
            ).show(context);
          }
        }
      } else {
        log("data kosong");
        CherryToast.warning(
          title: Text('Data inputan tidak boleh kosong'),
        ).show(context);
      }
    } catch (e) {
      log("error: ${e.toString()}");
    }
  }

  Future<void> inputdatapromotahunan() async {
    String kodePromoTahunan = controller_kode_promo_tahunan.text;
    String namaPromoTahunan = controller_nama_promo_tahunan.text;
    String jangkaTahunan = controller_jangka_tahunan.text;
    String hargaPromoTahunan = controller_harga_promo_tahunan.text;

    try {
      var response2 = await dio.get('${myIpAddr()}/promo/getidpromo');
      setState(() {
        kode_promo = response2.data;
      });
      bool packageExists = kode_promo.any(
        (item) => item['kode_promo'] == kodePromoTahunan,
      );
      if (kodePromoTahunan != "" &&
          namaPromoTahunan != "" &&
          jangkaTahunan != "" &&
          hargaPromoTahunan != "") {
        if (!packageExists) {
          var response = await dio.post(
            '${myIpAddr()}/promo/daftarpromotahunan',
            data: {
              "kode_promo": kodePromoTahunan,
              "nama_promo": namaPromoTahunan,
              "jangka_tahun": int.parse(jangkaTahunan),
              "harga_promo": int.parse(hargaPromoTahunan),
            },
          );
          log("data sukses tersimpan");
          CherryToast.success(
            title: Text('paket ${kodePromoTahunan} Saved successfully!'),
          ).show(context);
          controller_nama_promo_tahunan.clear();
          controller_kode_promo_tahunan.clear();
          controller_jangka_tahunan.clear();
          controller_harga_promo_tahunan.clear();
        } else {
          log("data gagal tersimpan");
          CherryToast.error(
            title: Text('paket ${kodePromoTahunan} Already existed!'),
          ).show(context);
        }
      } else {
        log("data kosong");
        CherryToast.warning(
          title: Text('Data inputan tidak boleh kosong'),
        ).show(context);
      }
    } catch (e) {
      log("error: ${e.toString()}");
    }
  }

  void calculateHargaPromo() {
    hargaPromo.value =
        hargaPromo.value =
            (hargaSatuan.value * limitKunjungan.value) *
            (1 - (diskonPaket.value / 100));
  }

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(''),
        toolbarHeight: 30,
        centerTitle: true,
        backgroundColor: Color(0XFFFFE0B2),
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
          width: Get.width,
          height: Get.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(shape: BoxShape.circle),
                child: ClipOval(
                  child: Image.asset('assets/spa.jpg', fit: BoxFit.cover),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text(
                  'Daftar Promo',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 20, left: 73),
                    child: ElevatedButton(
                      onPressed: () {
                        _moveFirstContainerToTop();
                        _toggleButtonColors(buttonIndex: 1);
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor:
                            _FirstbuttonColor == Colors.blue
                                ? Colors.white
                                : Colors.black,
                        backgroundColor: _FirstbuttonColor,
                        minimumSize: Size(150, 45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: Text(
                        'Promo Happy Hour',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 20, left: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        _moveSecondContainerToTop();
                        _toggleButtonColors(buttonIndex: 2);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _SecondbuttonColor,
                        foregroundColor:
                            _FirstbuttonColor == Colors.blue
                                ? Colors.white
                                : Colors.black,
                        minimumSize: Size(150, 45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: Text(
                        'Promo Paketan',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 20, left: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        _moveThirdContainerToTop();
                        _toggleButtonColors(buttonIndex: 3);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _ThirdbuttonColor,
                        foregroundColor:
                            _FirstbuttonColor == Colors.blue
                                ? Colors.white
                                : Colors.black,
                        minimumSize: Size(150, 45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: Text(
                        'Promo Tahunan',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
              Stack(
                children: [
                  if (_isFirstContainerOnTop)
                    Container(
                      height: 340,
                      width: 950,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.zero,
                                child: Container(
                                  height: 260,
                                  width: 200,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.only(right: 10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        SizedBox(height: 15),
                                        Text(
                                          'Kode Promo :',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          'Nama Promo :',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          'Discount Promo :',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          'Hari Berlaku :',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          'Jam Berlaku :',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          'Berlaku Untuk :',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                height: 260,
                                width: 750,
                                decoration: BoxDecoration(color: Colors.white),
                                child: Padding(
                                  padding: EdgeInsets.only(left: 10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 12),
                                      Container(
                                        alignment: Alignment.centerLeft,
                                        width: 730,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          color: Colors.grey[300],
                                        ),
                                        child: TextField(
                                          controller: controller_kode_promo,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  vertical: 13.5,
                                                  horizontal: 10,
                                                ),
                                          ),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Container(
                                        alignment: Alignment.centerLeft,
                                        width: 730,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          color: Colors.grey[300],
                                        ),
                                        child: TextField(
                                          controller: controller_nama_promo,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  vertical: 13.5,
                                                  horizontal: 10,
                                                ),
                                          ),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Container(
                                            alignment: Alignment.centerLeft,
                                            width: 270,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: Colors.grey[300],
                                            ),
                                            child: TextField(
                                              controller:
                                                  controller_diskon_promo,
                                              decoration: InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      vertical: 13.5,
                                                      horizontal: 10,
                                                    ),
                                              ),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(left: 10),
                                            child: Text(
                                              '% Dari Total Transaksi',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Center(
                                            child: Checkbox(
                                              value: isSeninChecked,
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  isSeninChecked =
                                                      value ?? false;
                                                });
                                                if (isSeninChecked == true) {
                                                  valuesenin = 1;
                                                } else {
                                                  valuesenin = 0;
                                                }
                                              },
                                            ),
                                          ),
                                          Text(
                                            'Senin',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 5,
                                            ),
                                            child: Center(
                                              child: Checkbox(
                                                value: isSelasaChecked,
                                                onChanged: (bool? value) {
                                                  setState(() {
                                                    isSelasaChecked =
                                                        value ?? false;
                                                  });
                                                  if (isSelasaChecked == true) {
                                                    valueselasa = 1;
                                                  } else {
                                                    valueselasa = 0;
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                          Text(
                                            'Selasa',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                          Center(
                                            child: Checkbox(
                                              value: isRabuChecked,
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  isRabuChecked =
                                                      value ?? false;
                                                });
                                                if (isRabuChecked == true) {
                                                  valuerabu = 1;
                                                } else {
                                                  valuerabu = 0;
                                                }
                                              },
                                            ),
                                          ),
                                          Text(
                                            'Rabu',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                          Center(
                                            child: Checkbox(
                                              value: isKamisChecked,
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  isKamisChecked =
                                                      value ?? false;
                                                });
                                                if (isKamisChecked == true) {
                                                  valuekamis = 1;
                                                } else {
                                                  valuekamis = 0;
                                                }
                                              },
                                            ),
                                          ),
                                          Text(
                                            'Kamis',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                          Center(
                                            child: Checkbox(
                                              value: isJumatChecked,
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  isJumatChecked =
                                                      value ?? false;
                                                });
                                                if (isJumatChecked == true) {
                                                  valuejumat = 1;
                                                } else {
                                                  valuejumat = 0;
                                                }
                                              },
                                            ),
                                          ),
                                          Text(
                                            'Jumat',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                          Center(
                                            child: Checkbox(
                                              value: isSabtuChecked,
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  isSabtuChecked =
                                                      value ?? false;
                                                });
                                                if (isSabtuChecked == true) {
                                                  valuesabtu = 1;
                                                } else {
                                                  valuesabtu = 0;
                                                }
                                              },
                                            ),
                                          ),
                                          Text(
                                            'Sabtu',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                          Center(
                                            child: Checkbox(
                                              value: isMingguChecked,
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  isMingguChecked =
                                                      value ?? false;
                                                });
                                                if (isMingguChecked == true) {
                                                  valueminggu = 1;
                                                } else {
                                                  valueminggu = 0;
                                                }
                                              },
                                            ),
                                          ),
                                          Text(
                                            'Minggu',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            alignment: Alignment.centerLeft,
                                            width: 50,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: Colors.grey[300],
                                            ),
                                            child: TextField(
                                              controller: controller_jam_mulai,
                                              keyboardType:
                                                  TextInputType.number,
                                              inputFormatters:
                                                  <TextInputFormatter>[
                                                    FilteringTextInputFormatter
                                                        .digitsOnly,
                                                  ],
                                              decoration: InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      vertical: 13.5,
                                                      horizontal: 10,
                                                    ),
                                              ),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(
                                              left: 5,
                                              right: 5,
                                            ),
                                            child: Text(
                                              ':',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ),
                                          Container(
                                            alignment: Alignment.centerLeft,
                                            width: 50,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: Colors.grey[300],
                                            ),
                                            child: TextField(
                                              controller:
                                                  controller_menit_mulai,
                                              keyboardType:
                                                  TextInputType.number,
                                              inputFormatters:
                                                  <TextInputFormatter>[
                                                    FilteringTextInputFormatter
                                                        .digitsOnly,
                                                  ],
                                              decoration: InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      vertical: 13.5,
                                                      horizontal: 10,
                                                    ),
                                              ),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(
                                              left: 10,
                                              right: 10,
                                            ),
                                            child: Text(
                                              'Sampai',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ),
                                          Container(
                                            alignment: Alignment.centerLeft,
                                            width: 50,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: Colors.grey[300],
                                            ),
                                            child: TextField(
                                              controller:
                                                  controller_jam_selesai,
                                              keyboardType:
                                                  TextInputType.number,
                                              inputFormatters:
                                                  <TextInputFormatter>[
                                                    FilteringTextInputFormatter
                                                        .digitsOnly,
                                                  ],
                                              decoration: InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      vertical: 13.5,
                                                      horizontal: 10,
                                                    ),
                                              ),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(
                                              left: 5,
                                              right: 5,
                                            ),
                                            child: Text(
                                              ':',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ),
                                          Container(
                                            alignment: Alignment.centerLeft,
                                            width: 50,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: Colors.grey[300],
                                            ),
                                            child: TextField(
                                              controller:
                                                  controller_menit_selesai,
                                              keyboardType:
                                                  TextInputType.number,
                                              inputFormatters:
                                                  <TextInputFormatter>[
                                                    FilteringTextInputFormatter
                                                        .digitsOnly,
                                                  ],
                                              decoration: InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      vertical: 13.5,
                                                      horizontal: 10,
                                                    ),
                                              ),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 3),

                                      Row(
                                        children: [
                                          Center(
                                            child: Checkbox(
                                              value: isUmumChecked,
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  isUmumChecked =
                                                      value ?? false;
                                                });
                                                if (isUmumChecked == true) {
                                                  valueumum = 1;
                                                } else {
                                                  valueumum = 0;
                                                }
                                              },
                                            ),
                                          ),
                                          Text(
                                            'Umum',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 30,
                                            ),
                                            child: Checkbox(
                                              value: isMemberChecked,
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  isMemberChecked =
                                                      value ?? false;
                                                });
                                                if (isMemberChecked == true) {
                                                  valuemember = 1;
                                                } else {
                                                  valuemember = 0;
                                                }
                                              },
                                            ),
                                          ),
                                          Text(
                                            'Member',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 30,
                                            ),
                                            child: Center(
                                              child: Checkbox(
                                                value: isVIPChecked,
                                                onChanged: (bool? value) {
                                                  setState(() {
                                                    isVIPChecked =
                                                        value ?? false;
                                                  });
                                                  if (isVIPChecked == true) {
                                                    valuevip = 1;
                                                  } else {
                                                    valuevip = 0;
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                          Text(
                                            'VIP',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontFamily: 'Poppins',
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
                          SizedBox(height: 10),
                          Center(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: Color(0XFFF6F7C4),
                              ),
                              height: 70,
                              width: 300,
                              child: TextButton(
                                onPressed: () {
                                  inputdatapromohappyhour();
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.black,
                                ),
                                child: Text(
                                  'Simpan',
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_isSecondContainerOnTop)
                    Container(
                      height: 370,
                      width: 950,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.zero,
                                child: Container(
                                  height: 260,
                                  width: 200,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.only(right: 10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        SizedBox(height: 15),
                                        Text(
                                          'Kode Promo :',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          'Nama Paket :',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          'Harga Satuan :',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          'Limit Promo :',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          'Limit Kunjungan :',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          'Harga Promo :',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                height: 260,
                                width: 750,
                                decoration: BoxDecoration(color: Colors.white),
                                child: Padding(
                                  padding: EdgeInsets.only(left: 10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 12),
                                      Container(
                                        alignment: Alignment.centerLeft,
                                        width: 730,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          color: Colors.grey[300],
                                        ),
                                        child: TextField(
                                          controller:
                                              controller_kode_promo_kunjungan,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  vertical: 13.5,
                                                  horizontal: 10,
                                                ),
                                          ),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Container(
                                        width: 730,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          color: Colors.grey[300],
                                        ),

                                        child: DropdownButton<String>(
                                          value: dropdownNamaPaket,
                                          isExpanded: true,
                                          icon: const Icon(
                                            Icons.arrow_drop_down,
                                          ),
                                          elevation: 16,
                                          style: const TextStyle(
                                            color: Colors.deepPurple,
                                          ),
                                          underline: SizedBox(),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),
                                          onChanged: (String? value) {
                                            setState(() {
                                              dropdownNamaPaket = value;
                                              controller_limit_kunjungan
                                                  .clear();
                                              controller_diskon_paket.clear();
                                              hargaPromo.value = 0;
                                              diskonPaket.value = 0.0;
                                              // Find the corresponding id_karyawan
                                              var selectedPaket = _listNamaPaket
                                                  .firstWhere(
                                                    (item) =>
                                                        item['nama_paket_msg'] ==
                                                        value,
                                                    orElse:
                                                        () => {
                                                          "nama_paket_msg": "",
                                                          "harga_paket_msg": 0,
                                                        },
                                                  );
                                              // controller_hargasatuan
                                              //     .text = currencyFormatter.format(
                                              //   selectedPaket['harga_paket_msg'],
                                              // );
                                              hargaSatuan.value =
                                                  (selectedPaket['harga_paket_msg']
                                                          as num)
                                                      .toDouble();
                                              controller_hargasatuan.text =
                                                  selectedPaket['harga_paket_msg']
                                                      .toString();
                                              selectedDurasi =
                                                  selectedPaket['durasi'];
                                              // controller_hargasatuan
                                              //     .text = currencyFormatter
                                              //     .format(hargaSatuan.value);
                                            });
                                          },
                                          items:
                                              _listNamaPaket.map<
                                                DropdownMenuItem<String>
                                              >((item) {
                                                return DropdownMenuItem<String>(
                                                  value:
                                                      item['nama_paket_msg'], // Use ID as value
                                                  child: Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Text(
                                                      item['nama_paket_msg']
                                                          .toString(), // Display category name
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontFamily: 'Poppins',
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Container(
                                        alignment: Alignment.centerLeft,
                                        width: 730,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          color: Colors.grey[300],
                                        ),
                                        child: TextField(
                                          controller: controller_hargasatuan,
                                          keyboardType:
                                              TextInputType
                                                  .number, // Show number keyboard
                                          inputFormatters: <TextInputFormatter>[
                                            FilteringTextInputFormatter
                                                .digitsOnly, // Allow only digits
                                          ],
                                          onChanged: (value) {
                                            if (value.isNotEmpty) {
                                              if (int.parse(value) > 0) {
                                                hargaSatuan.value =
                                                    double.parse(value);

                                                calculateHargaPromo();
                                              }
                                            }
                                          },
                                          readOnly: false,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  vertical: 13.5,
                                                  horizontal: 10,
                                                ),
                                          ),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Container(
                                            alignment: Alignment.centerLeft,
                                            width: 70,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: Colors.grey[300],
                                            ),
                                            child: TextField(
                                              controller:
                                                  controller_limit_promo,
                                              keyboardType:
                                                  TextInputType
                                                      .number, // Show number keyboard
                                              inputFormatters: <
                                                TextInputFormatter
                                              >[
                                                FilteringTextInputFormatter
                                                    .digitsOnly, // Allow only digits
                                              ],
                                              decoration: InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      vertical: 13.5,
                                                      horizontal: 10,
                                                    ),
                                              ),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(left: 10),
                                            child: Text(
                                              'Tahun',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Container(
                                            alignment: Alignment.centerLeft,
                                            width: 70,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: Colors.grey[300],
                                            ),
                                            child: TextField(
                                              controller:
                                                  controller_limit_kunjungan,
                                              keyboardType:
                                                  TextInputType
                                                      .number, // Show number keyboard
                                              inputFormatters: <
                                                TextInputFormatter
                                              >[
                                                FilteringTextInputFormatter
                                                    .digitsOnly, // Allow only digits
                                              ],
                                              decoration: InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      vertical: 13.5,
                                                      horizontal: 10,
                                                    ),
                                              ),
                                              onChanged: (value) {
                                                limitKunjungan.value =
                                                    int.tryParse(value) ?? 1;
                                                calculateHargaPromo();
                                              },
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(left: 10),
                                            child: Text(
                                              'Discount :',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 10,
                                            ),
                                            child: Container(
                                              alignment: Alignment.centerLeft,
                                              width: 70,
                                              height: 30,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                color: Colors.grey[300],
                                              ),
                                              child: TextField(
                                                controller:
                                                    controller_diskon_paket,
                                                keyboardType:
                                                    TextInputType
                                                        .number, // Show number keyboard
                                                inputFormatters: <
                                                  TextInputFormatter
                                                >[
                                                  FilteringTextInputFormatter
                                                      .digitsOnly, // Allow only digits
                                                ],
                                                decoration: InputDecoration(
                                                  border: InputBorder.none,
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                        vertical: 13.5,
                                                        horizontal: 10,
                                                      ),
                                                ),
                                                onChanged: (value) {
                                                  diskonPaket.value =
                                                      double.tryParse(value) ??
                                                      0.0;
                                                  calculateHargaPromo();
                                                },
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(left: 10),
                                            child: Text(
                                              '%',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 10),
                                      Container(
                                        alignment: Alignment.centerLeft,
                                        width: 250,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          color: Colors.grey[300],
                                        ),
                                        child: Obx(
                                          () => TextField(
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    vertical: 13.5,
                                                    horizontal: 10,
                                                  ),
                                            ),
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontFamily: 'Poppins',
                                            ),
                                            readOnly: true,
                                            controller: TextEditingController(
                                              text: currencyFormatter.format(
                                                hargaPromo.value,
                                              ), // Auto-update
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Center(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: Color(0XFFF6F7C4),
                              ),
                              height: 70,
                              width: 300,
                              child: TextButton(
                                onPressed: () {
                                  inputdatapromokunjungan();
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.black,
                                ),
                                child: Text(
                                  'Simpan',
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_isThirdContainerOnTop)
                    Container(
                      height: 270,
                      width: 950,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.zero,
                                child: Container(
                                  height: 180,
                                  width: 200,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.only(right: 10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        SizedBox(height: 15),
                                        Text(
                                          'Kode Promo :',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          'Nama Promo :',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          'Jangka Waktu :',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          'Harga Promo :',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                height: 180,
                                width: 750,
                                decoration: BoxDecoration(color: Colors.white),
                                child: Padding(
                                  padding: EdgeInsets.only(left: 10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 12),
                                      Container(
                                        alignment: Alignment.centerLeft,
                                        width: 730,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          color: Colors.grey[300],
                                        ),
                                        child: TextField(
                                          controller:
                                              controller_kode_promo_tahunan,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  vertical: 13.5,
                                                  horizontal: 10,
                                                ),
                                          ),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Container(
                                        alignment: Alignment.centerLeft,
                                        width: 730,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          color: Colors.grey[300],
                                        ),
                                        child: TextField(
                                          controller:
                                              controller_nama_promo_tahunan,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  vertical: 13.5,
                                                  horizontal: 10,
                                                ),
                                          ),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Container(
                                            alignment: Alignment.centerLeft,
                                            width: 50,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: Colors.grey[300],
                                            ),
                                            child: TextField(
                                              controller:
                                                  controller_jangka_tahunan,
                                              decoration: InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      vertical: 13.5,
                                                      horizontal: 10,
                                                    ),
                                              ),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(left: 10),
                                            child: Text(
                                              'Tahun',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 10),
                                      Container(
                                        alignment: Alignment.centerLeft,
                                        width: 270,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          color: Colors.grey[300],
                                        ),
                                        child: TextField(
                                          controller:
                                              controller_harga_promo_tahunan,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  vertical: 13.5,
                                                  horizontal: 10,
                                                ),
                                          ),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Center(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: Color(0XFFF6F7C4),
                              ),
                              height: 70,
                              width: 300,
                              child: TextButton(
                                onPressed: () {
                                  inputdatapromotahunan();
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.black,
                                ),
                                child: Text(
                                  'Simpan',
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontFamily: 'Poppins',
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
            ],
          ),
        ),
      ),
      drawer: AdminDrawer(),
    );
  }
}
