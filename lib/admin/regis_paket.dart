import 'dart:developer';

import 'package:Project_SPA/admin/laporan_ob.dart';
import 'package:Project_SPA/admin/listpaket.dart';
import 'package:Project_SPA/admin/listpekerja.dart';
import 'package:Project_SPA/admin/listpromo.dart';
import 'package:Project_SPA/admin/listroom.dart';
import 'package:Project_SPA/admin/listuser.dart';
import 'package:Project_SPA/admin/regis_locker.dart';
import 'package:Project_SPA/admin/regis_pekerja.dart';
import 'package:Project_SPA/admin/regis_promo.dart';
import 'package:Project_SPA/admin/regis_room.dart';
import 'package:Project_SPA/admin/regis_users.dart';
import 'package:Project_SPA/function/admin_drawer.dart';
import 'package:Project_SPA/function/ip_address.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:Project_SPA/resepsionis/billing_locker.dart';
import 'package:Project_SPA/resepsionis/jenis_transaksi.dart';
import 'package:Project_SPA/main.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'package:cherry_toast/cherry_toast.dart';

String? dropdownValueProduk;
String? dropdownValueFnB;
String? selectedKategoriIdProduk;
String? selectedKategoriIdFnb;
int? valueradio;
int? valueradiogro;

class RegisPaket extends StatefulWidget {
  const RegisPaket({super.key});

  @override
  State<RegisPaket> createState() => _RegisPaketState();
}

class _RegisPaketState extends State<RegisPaket> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController controller_nama_fnb = TextEditingController();
  final TextEditingController controller_harga_fnb = TextEditingController();
  final TextEditingController controller_nama_kategori =
      TextEditingController();
  final TextEditingController controller_stok_fnb = TextEditingController();

  final TextEditingController controller_nama_paket = TextEditingController();
  final TextEditingController controller_harga_paket = TextEditingController();
  final TextEditingController controller_durasi_paket = TextEditingController();
  final TextEditingController controller_nominal_komisi_paket_terapis =
      TextEditingController();
  final TextEditingController controller_nominal_komisi_paket_gro =
      TextEditingController();
  final TextEditingController controller_stok_paket = TextEditingController();
  final TextEditingController controller_detail_paket = TextEditingController();

  final TextEditingController controller_nama_produk = TextEditingController();
  final TextEditingController controller_harga_produk = TextEditingController();
  final TextEditingController controller_stok_produk = TextEditingController();
  final TextEditingController controller_durasi_produk =
      TextEditingController();
  final TextEditingController controller_nominal_komisi_produk =
      TextEditingController();
  final TextEditingController controller_nominal_komisi_produk_gro =
      TextEditingController();

  final TextEditingController controller_nama_fasilitas =
      TextEditingController();
  final TextEditingController controller_harga_fasilitias =
      TextEditingController();

  final TextEditingController controller_nama_paket_extend =
      TextEditingController();
  final TextEditingController controller_harga_paket_extend =
      TextEditingController();
  final TextEditingController controller_durasi_paket_extend =
      TextEditingController();
  final TextEditingController controller_komisi_paket_extend =
      TextEditingController();

  List<Map<String, dynamic>> datakategorifnb = [];
  List<String> extractDataFnb = [];
  List<dynamic> namapaketmsg = [];
  List<dynamic> namapaketextend = [];
  List<dynamic> namafnb = [];
  List<dynamic> namaproduk = [];
  List<dynamic> namafasilitas = [];
  List<dynamic> namakategori = [];
  List<RxString> dropdownpenerimakomisi = ['Terapis'.obs, 'Gro'.obs];
  RxString? selecteditem = ''.obs;
  RxString cekpenerima = ''.obs;

  bool _isSecondContainerOnTop = false;
  bool _isThirdContainerOnTop = false;
  bool _isFirstContainerOnTop = true;
  bool _isFourthContainerOnTop = false;
  bool _isFifthContainerOnTop = false;

  Color _FirstbuttonColor = Colors.blue;
  Color _SecondbuttonColor = Colors.white;
  Color _ThirdbuttonColor = Colors.white;
  Color _Fourthbuttoncolor = Colors.white;
  Color _Fifthbuttoncolor = Colors.white;

  var dio = Dio();

  int? _selectedRadio;
  int? _selectedRadioGro;

  @override
  void initState() {
    getkategorifnb();
    super.initState();
    _selectedRadio = 1;
    _selectedRadioGro = 1;
    valueradio = 1;
    valueradiogro = 1;
    if (dropdownpenerimakomisi.isNotEmpty) {
      selecteditem!.value = dropdownpenerimakomisi.first.value;
    }
    cekpenerima.value = 'Terapis';
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _textController.dispose();
    controller_nama_fnb.dispose();
    controller_harga_fnb.dispose();
    controller_nama_kategori.dispose();
    controller_nama_paket.dispose();
    controller_harga_paket.dispose();
    controller_durasi_paket.dispose();
    controller_nominal_komisi_paket_terapis.dispose();
    controller_nominal_komisi_paket_gro.dispose();
    controller_detail_paket.dispose();
    controller_nama_produk.dispose();
    controller_harga_produk.dispose();
    controller_durasi_produk.dispose();
    controller_nominal_komisi_produk.dispose();
    controller_nominal_komisi_produk_gro.dispose();
    controller_nama_paket_extend.dispose();
    controller_durasi_paket_extend.dispose();
    controller_harga_paket_extend.dispose();
    controller_komisi_paket_extend.dispose();
  }

  void _moveSecondContainerToTop() {
    setState(() {
      _isSecondContainerOnTop = true;
      _isFirstContainerOnTop = false;
      _isThirdContainerOnTop = false;
      _isFourthContainerOnTop = false;
      _isFifthContainerOnTop = false;
    });
  }

  void _moveFirstContainerToTop() {
    setState(() {
      _isSecondContainerOnTop = false;
      _isFirstContainerOnTop = true;
      _isThirdContainerOnTop = false;
      _isFourthContainerOnTop = false;
      _isFifthContainerOnTop = false;
    });
  }

  void _moveThirdContainerToTop() {
    setState(() {
      _isSecondContainerOnTop = false;
      _isThirdContainerOnTop = true;
      _isFirstContainerOnTop = false;
      _isFourthContainerOnTop = false;
      _isFifthContainerOnTop = false;
    });
  }

  void _moveFourthContainerToTop() {
    setState(() {
      _isFirstContainerOnTop = false;
      _isSecondContainerOnTop = false;
      _isThirdContainerOnTop = false;
      _isFourthContainerOnTop = true;
      _isFifthContainerOnTop = false;
    });
  }

  void _moveFifthContainerToTop() {
    setState(() {
      _isFirstContainerOnTop = false;
      _isSecondContainerOnTop = false;
      _isThirdContainerOnTop = false;
      _isFourthContainerOnTop = false;
      _isFifthContainerOnTop = true;
    });
  }

  void _toggleButtonColors({required int buttonIndex}) {
    setState(() {
      if (buttonIndex == 1) {
        _FirstbuttonColor = Colors.blue;
        _SecondbuttonColor = Colors.white;
        _ThirdbuttonColor = Colors.white;
        _Fourthbuttoncolor = Colors.white;
        _Fifthbuttoncolor = Colors.white;
      } else if (buttonIndex == 2) {
        _FirstbuttonColor = Colors.white;
        _SecondbuttonColor = Colors.blue;
        _ThirdbuttonColor = Colors.white;
        _Fourthbuttoncolor = Colors.white;
        _Fifthbuttoncolor = Colors.white;
      } else if (buttonIndex == 3) {
        _FirstbuttonColor = Colors.white;
        _SecondbuttonColor = Colors.white;
        _ThirdbuttonColor = Colors.blue;
        _Fourthbuttoncolor = Colors.white;
        _Fifthbuttoncolor = Colors.white;
      } else if (buttonIndex == 4) {
        _FirstbuttonColor = Colors.white;
        _SecondbuttonColor = Colors.white;
        _ThirdbuttonColor = Colors.white;
        _Fourthbuttoncolor = Colors.blue;
        _Fifthbuttoncolor = Colors.white;
      } else if (buttonIndex == 5) {
        _FirstbuttonColor = Colors.white;
        _SecondbuttonColor = Colors.white;
        _ThirdbuttonColor = Colors.white;
        _Fourthbuttoncolor = Colors.white;
        _Fifthbuttoncolor = Colors.blue;
      }
    });
  }

  Future<void> getkategorifnb() async {
    try {
      var response = await dio.get(
        '${myIpAddr()}/fnb/getkategori?timestamp=${DateTime.now().millisecondsSinceEpoch}',
      );
      // log("Raw API response: ${response.data}".toString());
      setState(() {
        datakategorifnb =
            (response.data as List).map((item) {
              return {
                "id_kategori": item["id_kategori"],
                "nama_kategori": item["nama_kategori"],
              };
            }).toList();
        extractDataFnb =
            datakategorifnb
                .map((item) => item['id_kategori'] as String)
                .toList();
        if (extractDataFnb.isNotEmpty) {
          selectedKategoriIdFnb = extractDataFnb.first;
        } else {
          selectedKategoriIdFnb = null;
        }
      });
    } catch (e) {
      log("Error di fn Get Kategori $e");
    }
  }

  Future<void> inputdatafnb() async {
    try {
      String namaFnb = controller_nama_fnb.text;
      String hargaFnb = controller_harga_fnb.text;
      String idKategori = selectedKategoriIdFnb!;
      String stokFnb = controller_stok_fnb.text;

      var response2 = await dio.get('${myIpAddr()}/fnb/getnamafnb');
      setState(() {
        namafnb = response2.data;
        controller_nama_paket.text = namaFnb;
      });
      bool packageExists = namafnb.any((item) => item['nama_fnb'] == namaFnb);
      if (namaFnb != "" && hargaFnb != "") {
        if (!packageExists) {
          var response = await dio.post(
            '${myIpAddr()}/fnb/daftarpaket',
            data: {
              "nama_fnb": namaFnb,
              "harga_fnb": int.parse(hargaFnb),
              "stok_fnb": int.parse(stokFnb),
              "id_kategori": idKategori,
              "status_fnb": "Available",
            },
          );
          log("Data sukses tersimpan");
          CherryToast.success(
            title: Text(
              'Item ${controller_nama_paket.text} Saved successfully!',
            ),
          ).show(context);
          controller_nama_fnb.clear();
          controller_harga_fnb.clear();
          controller_stok_fnb.clear();
        } else {
          log("data gagal tersimpan");
          CherryToast.error(
            title: Text('Item ${controller_nama_paket.text} Already existed!'),
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

  Future<void> inputdatakategorifnb() async {
    try {
      var response = await dio.post(
        '${myIpAddr()}/fnb/daftarkategori',
        data: {"nama_kategori": controller_nama_kategori.text},
      );
      controller_nama_kategori.clear();
      log("sukses");
    } catch (e) {
      log("error: ${e.toString()}");
    }
  }

  Future<void> inputdatapaketmassage() async {
    String inputNamaPaket = controller_nama_paket.text;
    String hargaPaket = controller_harga_paket.text;
    String durasiPaket = controller_durasi_paket.text;
    String nominalKomisiPaket = controller_nominal_komisi_paket_terapis.text;
    int? tipeKomisi = valueradio;
    String detailPaket = controller_detail_paket.text;
    int? tipekomisigro = valueradiogro;
    String nominalkomisigro = controller_nominal_komisi_paket_gro.text;

    try {
      var response2 = await dio.get(
        '${myIpAddr()}/massage/getnamapaketmassage',
      );
      setState(() {
        namapaketmsg = response2.data;
      });
      bool packageExists = namapaketmsg.any(
        (item) => item['nama_paket_msg'] == inputNamaPaket,
      );
      if (inputNamaPaket != "" &&
          hargaPaket != "" &&
          durasiPaket != "" &&
          nominalKomisiPaket != "" &&
          nominalkomisigro != "") {
        if (!packageExists) {
          log(nominalkomisigro);
          log(valueradiogro.toString());
          var response = await dio.post(
            '${myIpAddr()}/massage/daftarpaketmassage',
            data: {
              "nama_paket_msg": inputNamaPaket,
              "harga_paket_msg": int.parse(hargaPaket),
              "durasi": int.parse(durasiPaket),
              "nominal_komisi": int.parse(nominalKomisiPaket),
              "tipe_komisi": tipeKomisi,
              "detail_paket": detailPaket,
              "tipe_komisi_gro": tipekomisigro,
              "nominal_komisi_gro": int.parse(nominalkomisigro),
            },
          );
          log("data sukses tersimpan");
          CherryToast.success(
            title: Text('paket ${inputNamaPaket} Saved successfully!'),
          ).show(context);
          controller_nama_paket.clear();
          controller_harga_paket.clear();
          controller_durasi_paket.clear();
          controller_nominal_komisi_paket_terapis.clear();
          _selectedRadio = 0;
          _selectedRadioGro = 0;
          controller_detail_paket.clear();
          controller_nominal_komisi_paket_gro.clear();
        } else {
          log("data gagal tersimpan");
          CherryToast.error(
            title: Text('paket ${inputNamaPaket} Already existed!'),
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

  Future<void> inputdataproduk() async {
    String inputNamaProduk = controller_nama_produk.text.trim();
    String hargaProduk = controller_harga_produk.text.trim();
    String durasiProduk = controller_durasi_produk.text.trim();
    String nominalKomisiProduk = controller_nominal_komisi_produk.text.trim();
    String nominalkomisiprodukgro =
        controller_nominal_komisi_produk_gro.text.trim();
    String stokProduk = controller_stok_produk.text.trim();
    int? tipeKomisiProduk = valueradio;
    int? tipekomisiprodukgro = valueradiogro;

    try {
      var response2 = await dio.get('${myIpAddr()}/produk/getnamaproduk');
      setState(() {
        namaproduk = response2.data;
      });

      bool packageExists = namaproduk.any(
        (item) => item['nama_produk'] == inputNamaProduk,
      );

      if (inputNamaProduk.isNotEmpty && stokProduk.isNotEmpty) {
        if (!packageExists) {
          var response = await dio.post(
            '${myIpAddr()}/produk/daftarproduk',
            data: {
              "nama_produk": inputNamaProduk,
              "harga_produk": int.tryParse(hargaProduk) ?? 0,
              "stok_produk": int.tryParse(stokProduk) ?? 0,
              "durasi": int.tryParse(durasiProduk) ?? 0,
              "nominal_komisi": int.tryParse(nominalKomisiProduk) ?? 0,
              "tipe_komisi": tipeKomisiProduk,
              "tipe_komisi_gro": tipekomisiprodukgro,
              "nominal_komisi_gro": int.tryParse(nominalkomisiprodukgro) ?? 0,
            },
          );
          log("data sukses tersimpan");
          CherryToast.success(
            title: Text('Produk $inputNamaProduk saved successfully!'),
          ).show(context);

          controller_nama_produk.clear();
          controller_harga_produk.clear();
          controller_durasi_produk.clear();
          controller_nominal_komisi_produk.clear();
          controller_nominal_komisi_produk_gro.clear();
          controller_stok_produk.clear();
          _selectedRadio = 1;
          _selectedRadioGro = 1;
          selecteditem!.value = 'Terapis';
        } else {
          log("data gagal tersimpan");
          CherryToast.error(
            title: Text('Produk $inputNamaProduk already exists!'),
          ).show(context);
        }
      } else {
        log("data kosong");
        CherryToast.warning(
          title: Text('Nama dan Stok Produk tidak boleh kosong!'),
        ).show(context);
      }
    } catch (e) {
      log("error: ${e.toString()}");
    }
  }

  Future<void> inputdatafasilitas() async {
    String inputNamaFasilitas = controller_nama_fasilitas.text;
    String hargaFasilitas = controller_harga_fasilitias.text;
    try {
      var response2 = await dio.get('${myIpAddr()}/fasilitas/getnamafasilitas');
      setState(() {
        namafasilitas = response2.data;
      });
      bool packageExists = namafasilitas.any(
        (item) => item['nama_fasilitas'] == inputNamaFasilitas,
      );
      if (inputNamaFasilitas != "" && hargaFasilitas != "") {
        if (!packageExists) {
          var response = await dio.post(
            '${myIpAddr()}/fasilitas/daftarfasilitas',
            data: {
              "nama_fasilitas": inputNamaFasilitas,
              "harga_fasilitas": int.parse(hargaFasilitas),
            },
          );
          log("data sukses tersimpan");
          CherryToast.success(
            title: Text('Fasilitas ${inputNamaFasilitas} Saved successfully!'),
          ).show(context);
          controller_nama_fasilitas.clear();
          controller_harga_fasilitias.clear();
        } else {
          log("data gagal tersimpan");
          CherryToast.error(
            title: Text('Fasilitas ${inputNamaFasilitas} Already existed!'),
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

  Future<void> inputdatapaketextend() async {
    String inputNamaExtend = controller_nama_paket_extend.text;
    String hargaPaketExtend = controller_harga_paket_extend.text;
    String durasiPaketExtend = controller_durasi_paket_extend.text;
    String nominalKomisiExtend = controller_komisi_paket_extend.text;

    try {
      var response2 = await dio.get('${myIpAddr()}/extend/getnamapaketextend');
      setState(() {
        namapaketextend = response2.data;
      });
      bool packageExists = namapaketextend.any(
        (item) => item['nama_paket_extend'] == inputNamaExtend,
      );
      if (inputNamaExtend != "" &&
          hargaPaketExtend != "" &&
          durasiPaketExtend != "" &&
          nominalKomisiExtend != "") {
        if (!packageExists) {
          var response = await dio.post(
            '${myIpAddr()}/extend/daftarpaketextend',
            data: {
              "nama_paket_extend": inputNamaExtend,
              "harga_extend": int.parse(hargaPaketExtend),
              "durasi_extend": int.parse(durasiPaketExtend),
              "komisi_terapis": int.parse(nominalKomisiExtend),
            },
          );
          log("data sukses tersimpan");
          CherryToast.success(
            title: Text('paket ${inputNamaExtend} Saved successfully!'),
          ).show(context);
          controller_nama_paket_extend.clear();
          controller_durasi_paket_extend.clear();
          controller_harga_paket_extend.clear();
          controller_komisi_paket_extend.clear();
        } else {
          log("data gagal tersimpan");
          CherryToast.error(
            title: Text('paket ${inputNamaExtend} Already existed!'),
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

  Future<void> deletedatakategori() async {
    String isikategori = controller_nama_kategori.text;
    try {
      var response2 = await dio.get('${myIpAddr()}/fnb/getnamakategori');
      setState(() {
        namakategori = response2.data;
      });
      bool packageExists = namakategori.any(
        (item) => item['nama_kategori'] == isikategori,
      );
      if (packageExists) {
        var response = await dio.delete(
          '${myIpAddr()}/fnb/deletekategori',
          data: {"nama_kategori": isikategori},
        );
        log("data sukses terhapus");
        CherryToast.success(
          title: Text('Kategori $isikategori Deleted!'),
        ).show(context);
      } else {
        log("data gagal terhapus");
        CherryToast.warning(
          title: Text('Kategori $isikategori Not Found'),
        ).show(context);
      }
    } catch (e) {
      log("error: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(''),
        toolbarHeight: 30,
        centerTitle: true,
        backgroundColor: Color(0XFFFFE0B2),
      ),
      body: Container(
        decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
        width: Get.width,
        height: Get.height,
        child: SingleChildScrollView(
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
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'Daftar Paket',
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
                    padding: EdgeInsets.only(top: 10, left: 135),
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
                        'Paket Massage',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10, left: 10),
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
                        'Paket F&B',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10, left: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        _moveThirdContainerToTop();
                        _toggleButtonColors(buttonIndex: 3);
                        selecteditem!.value = 'Terapis';
                        _selectedRadio = 1;
                        _selectedRadioGro = 1;
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
                        'Produk',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10, left: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        _moveFourthContainerToTop();
                        _toggleButtonColors(buttonIndex: 4);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _Fourthbuttoncolor,
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
                        'Fasilitas',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10, left: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        _moveFifthContainerToTop();
                        _toggleButtonColors(buttonIndex: 5);
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor:
                            _Fifthbuttoncolor == Colors.blue
                                ? Colors.white
                                : Colors.black,
                        backgroundColor: _Fifthbuttoncolor,
                        minimumSize: Size(150, 45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: Text(
                        'Paket Extend',
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
                      height: 420,
                      width: 810,
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
                                  height: 320,
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
                                          'Nama Paket :',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          'Harga :',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          'Durasi :',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          'Penerima Komisi :',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          '',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          'Komisi :',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 20),
                                        Text(
                                          'Detail Paket :',
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
                              Padding(
                                padding: const EdgeInsets.only(top: 0),
                                child: Container(
                                  height: 320,
                                  width: 590,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 12),
                                        Container(
                                          alignment: Alignment.centerLeft,
                                          width: 480,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            color: Colors.grey[300],
                                          ),
                                          child: TextField(
                                            controller: controller_nama_paket,
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
                                          width: 480,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            color: Colors.grey[300],
                                          ),
                                          child: TextField(
                                            controller: controller_harga_paket,
                                            keyboardType: TextInputType.number,
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
                                        SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Container(
                                              alignment: Alignment.centerLeft,
                                              width: 120,
                                              height: 30,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                color: Colors.grey[300],
                                              ),
                                              child: TextField(
                                                controller:
                                                    controller_durasi_paket,
                                                keyboardType:
                                                    TextInputType.number,
                                                inputFormatters: <
                                                  TextInputFormatter
                                                >[
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
                                              ),
                                              child: Text(
                                                'Menit',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 10),
                                        Obx(
                                          () => Container(
                                            width: 120,
                                            height: 30,
                                            padding: EdgeInsets.only(left: 10),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: Colors.grey[300],
                                            ),
                                            child: DropdownButton<RxString>(
                                              value:
                                                  selecteditem?.value == null ||
                                                          selecteditem!
                                                              .value
                                                              .isEmpty
                                                      ? null
                                                      : dropdownpenerimakomisi
                                                          .firstWhereOrNull(
                                                            (itemRx) =>
                                                                itemRx.value ==
                                                                selecteditem!
                                                                    .value,
                                                          ),
                                              isExpanded: true,
                                              underline: SizedBox(),
                                              elevation: 20,
                                              style: const TextStyle(
                                                color: Colors.deepPurple,
                                                fontSize: 18,
                                              ),
                                              onChanged: (RxString? newvalue) {
                                                if (newvalue != null) {
                                                  selecteditem!.value =
                                                      newvalue.value;
                                                } else {
                                                  selecteditem!.value = '';
                                                }
                                              },
                                              items:
                                                  dropdownpenerimakomisi.map<
                                                    DropdownMenuItem<RxString>
                                                  >((RxString itemRx) {
                                                    return DropdownMenuItem<
                                                      RxString
                                                    >(
                                                      value: itemRx,
                                                      child: Text(itemRx.value),
                                                    );
                                                  }).toList(),
                                            ),
                                          ),
                                        ),
                                        Obx(
                                          () =>
                                              selecteditem!.value == 'Terapis'
                                                  ? Row(
                                                    children: [
                                                      Radio<int>(
                                                        value: 1,
                                                        groupValue:
                                                            _selectedRadio,
                                                        onChanged: (
                                                          int? value,
                                                        ) {
                                                          setState(() {
                                                            _selectedRadio =
                                                                value;
                                                            if (_selectedRadio ==
                                                                1) {
                                                              valueradio = 1;
                                                            }
                                                          });
                                                        },
                                                      ),
                                                      Text('Nominal'),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              left: 20,
                                                            ),
                                                        child: Radio<int>(
                                                          value: 2,
                                                          groupValue:
                                                              _selectedRadio,
                                                          onChanged: (
                                                            int? value,
                                                          ) {
                                                            setState(() {
                                                              _selectedRadio =
                                                                  value;
                                                              if (_selectedRadio ==
                                                                  2) {
                                                                valueradio = 0;
                                                              }
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                      Text('Persenan'),
                                                    ],
                                                  )
                                                  : Row(
                                                    children: [
                                                      Radio<int>(
                                                        value: 1,
                                                        groupValue:
                                                            _selectedRadioGro,
                                                        onChanged: (
                                                          int? value,
                                                        ) {
                                                          setState(() {
                                                            _selectedRadioGro =
                                                                value;
                                                            if (_selectedRadioGro ==
                                                                1) {
                                                              valueradiogro = 1;
                                                            }
                                                          });
                                                        },
                                                      ),
                                                      Text('Nominal'),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              left: 20,
                                                            ),
                                                        child: Radio<int>(
                                                          value: 2,
                                                          groupValue:
                                                              _selectedRadioGro,
                                                          onChanged: (
                                                            int? value,
                                                          ) {
                                                            setState(() {
                                                              _selectedRadioGro =
                                                                  value;
                                                              if (_selectedRadioGro ==
                                                                  2) {
                                                                valueradiogro =
                                                                    0;
                                                              }
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                      Text('Persenan'),
                                                    ],
                                                  ),
                                        ),

                                        SizedBox(height: 4),
                                        //INI STACK DIBAWAH RADIOBUTTON
                                        Obx(
                                          () =>
                                              selecteditem!.value == 'Terapis'
                                                  ? Stack(
                                                    children: [
                                                      Visibility(
                                                        visible:
                                                            _selectedRadio == 1,
                                                        child: Container(
                                                          alignment:
                                                              Alignment
                                                                  .centerLeft,
                                                          width: 480,
                                                          height: 30,
                                                          child: Row(
                                                            children: [
                                                              Text(
                                                                'Rp ',
                                                                style: TextStyle(
                                                                  fontSize: 16,
                                                                  fontFamily:
                                                                      'Poppins',
                                                                ),
                                                              ),
                                                              Container(
                                                                alignment:
                                                                    Alignment
                                                                        .centerLeft,
                                                                width: 230,
                                                                height: 30,
                                                                decoration: BoxDecoration(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        10,
                                                                      ),
                                                                  color:
                                                                      Colors
                                                                          .grey[300],
                                                                ),
                                                                child: TextField(
                                                                  controller:
                                                                      controller_nominal_komisi_paket_terapis,
                                                                  keyboardType:
                                                                      TextInputType
                                                                          .number,
                                                                  inputFormatters: <
                                                                    TextInputFormatter
                                                                  >[
                                                                    FilteringTextInputFormatter
                                                                        .digitsOnly,
                                                                  ],
                                                                  decoration: InputDecoration(
                                                                    border:
                                                                        InputBorder
                                                                            .none,
                                                                    contentPadding:
                                                                        EdgeInsets.symmetric(
                                                                          vertical:
                                                                              12,
                                                                          horizontal:
                                                                              5,
                                                                        ),
                                                                  ),
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    fontFamily:
                                                                        'Poppins',
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      Visibility(
                                                        visible:
                                                            _selectedRadio == 2,
                                                        child: Container(
                                                          alignment:
                                                              Alignment
                                                                  .centerLeft,
                                                          width: 480,
                                                          height: 30,
                                                          child: Row(
                                                            children: [
                                                              Container(
                                                                alignment:
                                                                    Alignment
                                                                        .centerLeft,
                                                                width: 230,
                                                                height: 30,
                                                                decoration: BoxDecoration(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        10,
                                                                      ),
                                                                  color:
                                                                      Colors
                                                                          .grey[300],
                                                                ),
                                                                child: TextField(
                                                                  controller:
                                                                      controller_nominal_komisi_paket_terapis,
                                                                  keyboardType:
                                                                      TextInputType
                                                                          .number,
                                                                  inputFormatters: <
                                                                    TextInputFormatter
                                                                  >[
                                                                    FilteringTextInputFormatter
                                                                        .digitsOnly,
                                                                  ],
                                                                  decoration: InputDecoration(
                                                                    border:
                                                                        InputBorder
                                                                            .none,
                                                                    contentPadding:
                                                                        EdgeInsets.symmetric(
                                                                          vertical:
                                                                              12,
                                                                          horizontal:
                                                                              5,
                                                                        ),
                                                                  ),
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    fontFamily:
                                                                        'Poppins',
                                                                  ),
                                                                ),
                                                              ),
                                                              Text(
                                                                ' % ',
                                                                style: TextStyle(
                                                                  fontSize: 16,
                                                                  fontFamily:
                                                                      'Poppins',
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                  : Stack(
                                                    children: [
                                                      Visibility(
                                                        visible:
                                                            _selectedRadioGro ==
                                                            1,
                                                        child: Container(
                                                          alignment:
                                                              Alignment
                                                                  .centerLeft,
                                                          width: 480,
                                                          height: 30,
                                                          child: Row(
                                                            children: [
                                                              Text(
                                                                'Rp ',
                                                                style: TextStyle(
                                                                  fontSize: 16,
                                                                  fontFamily:
                                                                      'Poppins',
                                                                ),
                                                              ),
                                                              Container(
                                                                alignment:
                                                                    Alignment
                                                                        .centerLeft,
                                                                width: 230,
                                                                height: 30,
                                                                decoration: BoxDecoration(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        10,
                                                                      ),
                                                                  color:
                                                                      Colors
                                                                          .grey[300],
                                                                ),
                                                                child: TextField(
                                                                  controller:
                                                                      controller_nominal_komisi_paket_gro,
                                                                  keyboardType:
                                                                      TextInputType
                                                                          .number,
                                                                  inputFormatters: <
                                                                    TextInputFormatter
                                                                  >[
                                                                    FilteringTextInputFormatter
                                                                        .digitsOnly,
                                                                  ],
                                                                  decoration: InputDecoration(
                                                                    border:
                                                                        InputBorder
                                                                            .none,
                                                                    contentPadding:
                                                                        EdgeInsets.symmetric(
                                                                          vertical:
                                                                              12,
                                                                          horizontal:
                                                                              5,
                                                                        ),
                                                                  ),
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    fontFamily:
                                                                        'Poppins',
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      Visibility(
                                                        visible:
                                                            _selectedRadioGro ==
                                                            2,
                                                        child: Container(
                                                          alignment:
                                                              Alignment
                                                                  .centerLeft,
                                                          width: 480,
                                                          height: 30,
                                                          child: Row(
                                                            children: [
                                                              Container(
                                                                alignment:
                                                                    Alignment
                                                                        .centerLeft,
                                                                width: 230,
                                                                height: 30,
                                                                decoration: BoxDecoration(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        10,
                                                                      ),
                                                                  color:
                                                                      Colors
                                                                          .grey[300],
                                                                ),
                                                                child: TextField(
                                                                  controller:
                                                                      controller_nominal_komisi_paket_gro,
                                                                  keyboardType:
                                                                      TextInputType
                                                                          .number,
                                                                  inputFormatters: <
                                                                    TextInputFormatter
                                                                  >[
                                                                    FilteringTextInputFormatter
                                                                        .digitsOnly,
                                                                  ],
                                                                  decoration: InputDecoration(
                                                                    border:
                                                                        InputBorder
                                                                            .none,
                                                                    contentPadding:
                                                                        EdgeInsets.symmetric(
                                                                          vertical:
                                                                              12,
                                                                          horizontal:
                                                                              5,
                                                                        ),
                                                                  ),
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    fontFamily:
                                                                        'Poppins',
                                                                  ),
                                                                ),
                                                              ),
                                                              Text(
                                                                ' % ',
                                                                style: TextStyle(
                                                                  fontSize: 16,
                                                                  fontFamily:
                                                                      'Poppins',
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                        ),

                                        SizedBox(height: 12),
                                        Container(
                                          alignment: Alignment.centerLeft,
                                          width: 480,
                                          height: 45,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            color: Colors.grey[300],
                                          ),
                                          child: TextField(
                                            controller: controller_detail_paket,
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
                              ),
                            ],
                          ),
                          SizedBox(height: 5),
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
                                  inputdatapaketmassage();
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
                      height: 300,
                      width: 810,
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
                                          'Nama F&B :',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          'Harga :',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          'Stok :',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          'Kategori :',
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
                              Padding(
                                padding: const EdgeInsets.only(top: 0),
                                child: Container(
                                  height: 180,
                                  width: 590,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 12),
                                        Container(
                                          alignment: Alignment.centerLeft,
                                          width: 480,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            color: Colors.grey[300],
                                          ),
                                          child: TextField(
                                            controller: controller_nama_fnb,
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
                                          width: 480,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            color: Colors.grey[300],
                                          ),
                                          child: TextField(
                                            controller: controller_harga_fnb,
                                            keyboardType: TextInputType.number,
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
                                        SizedBox(height: 12),
                                        Container(
                                          alignment: Alignment.centerLeft,
                                          width: 480,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            color: Colors.grey[300],
                                          ),
                                          child: TextField(
                                            controller: controller_stok_fnb,
                                            keyboardType: TextInputType.number,
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
                                        SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Container(
                                              width: 250,
                                              height: 30,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                color: Colors.grey[300],
                                              ),
                                              child: DropdownButton<String>(
                                                value: selectedKategoriIdFnb,
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
                                                    selectedKategoriIdFnb =
                                                        value;
                                                  });
                                                },
                                                items:
                                                    datakategorifnb.map<
                                                      DropdownMenuItem<String>
                                                    >((item) {
                                                      return DropdownMenuItem<
                                                        String
                                                      >(
                                                        value:
                                                            item['id_kategori'], // Use ID as value
                                                        child: Align(
                                                          alignment:
                                                              Alignment
                                                                  .centerLeft,
                                                          child: Text(
                                                            item['nama_kategori']
                                                                .toString(), // Display category name
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 18,
                                                                  fontFamily:
                                                                      'Poppins',
                                                                ),
                                                          ),
                                                        ),
                                                      );
                                                    }).toList(),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 20,
                                                top: 2,
                                              ),
                                              child: SizedBox(
                                                height: 35,
                                                width: 100,
                                                child: TextButton(
                                                  style: TextButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.green,
                                                  ),
                                                  onPressed: () {
                                                    Get.dialog(
                                                      StatefulBuilder(
                                                        builder: (
                                                          context,
                                                          setState,
                                                        ) {
                                                          return AlertDialog(
                                                            title: const Center(
                                                              child: Text(
                                                                "Add New Kategori",
                                                                style: TextStyle(
                                                                  fontFamily:
                                                                      'Poppins',
                                                                ),
                                                              ),
                                                            ),
                                                            content: SizedBox(
                                                              height:
                                                                  Get.height -
                                                                  500,
                                                              width:
                                                                  Get.width -
                                                                  800,
                                                              child: Column(
                                                                children: [
                                                                  Container(
                                                                    alignment:
                                                                        Alignment
                                                                            .centerLeft,
                                                                    width: 300,
                                                                    height: 40,
                                                                    decoration: BoxDecoration(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            10,
                                                                          ),
                                                                      color:
                                                                          Colors
                                                                              .grey[300],
                                                                    ),
                                                                    child: TextField(
                                                                      controller:
                                                                          controller_nama_kategori,
                                                                      decoration: InputDecoration(
                                                                        border:
                                                                            InputBorder.none,
                                                                        contentPadding: EdgeInsets.symmetric(
                                                                          vertical:
                                                                              15,
                                                                          horizontal:
                                                                              10,
                                                                        ),
                                                                      ),
                                                                      style: TextStyle(
                                                                        fontSize:
                                                                            16,
                                                                        fontFamily:
                                                                            'Poppins',
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                    height: 30,
                                                                  ),
                                                                  Container(
                                                                    decoration: BoxDecoration(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            15,
                                                                          ),
                                                                      color: Color(
                                                                        0XFFF6F7C4,
                                                                      ),
                                                                    ),
                                                                    height: 50,
                                                                    width: 150,
                                                                    child: TextButton(
                                                                      onPressed: () async {
                                                                        if (controller_nama_kategori
                                                                            .text
                                                                            .isNotEmpty) {
                                                                          await inputdatakategorifnb().then((
                                                                            _,
                                                                          ) {
                                                                            Get.back();
                                                                          });
                                                                          getkategorifnb();
                                                                          getkategorifnb();
                                                                        }
                                                                      },
                                                                      style: TextButton.styleFrom(
                                                                        foregroundColor:
                                                                            Colors.black,
                                                                      ),
                                                                      child: Text(
                                                                        'Simpan',
                                                                        style: TextStyle(
                                                                          fontSize:
                                                                              20,
                                                                          fontFamily:
                                                                              'Poppins',
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    );
                                                  },
                                                  child: Text(
                                                    'Add',
                                                    style: TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontSize: 14,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 10,
                                                top: 2,
                                              ),
                                              child: SizedBox(
                                                height: 35,
                                                width: 100,
                                                child: TextButton(
                                                  style: TextButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                  ),
                                                  onPressed: () {
                                                    Get.dialog(
                                                      StatefulBuilder(
                                                        builder: (
                                                          context,
                                                          setState,
                                                        ) {
                                                          return AlertDialog(
                                                            title: const Center(
                                                              child: Text(
                                                                "Delete Kategori",
                                                                style: TextStyle(
                                                                  fontFamily:
                                                                      'Poppins',
                                                                ),
                                                              ),
                                                            ),
                                                            content: SizedBox(
                                                              height:
                                                                  Get.height -
                                                                  500,
                                                              width:
                                                                  Get.width -
                                                                  800,
                                                              child: Column(
                                                                children: [
                                                                  Container(
                                                                    alignment:
                                                                        Alignment
                                                                            .centerLeft,
                                                                    width: 300,
                                                                    height: 40,
                                                                    decoration: BoxDecoration(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            10,
                                                                          ),
                                                                      color:
                                                                          Colors
                                                                              .grey[300],
                                                                    ),
                                                                    child: TextField(
                                                                      controller:
                                                                          controller_nama_kategori,
                                                                      decoration: InputDecoration(
                                                                        border:
                                                                            InputBorder.none,
                                                                        contentPadding: EdgeInsets.symmetric(
                                                                          vertical:
                                                                              15,
                                                                          horizontal:
                                                                              10,
                                                                        ),
                                                                      ),
                                                                      style: TextStyle(
                                                                        fontSize:
                                                                            16,
                                                                        fontFamily:
                                                                            'Poppins',
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                    height: 30,
                                                                  ),
                                                                  Container(
                                                                    decoration: BoxDecoration(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            15,
                                                                          ),
                                                                      color: Color(
                                                                        0XFFF6F7C4,
                                                                      ),
                                                                    ),
                                                                    height: 50,
                                                                    width: 150,
                                                                    child: TextButton(
                                                                      onPressed: () async {
                                                                        if (controller_nama_kategori
                                                                            .text
                                                                            .isNotEmpty) {
                                                                          await deletedatakategori().then((
                                                                            _,
                                                                          ) {
                                                                            Get.back();
                                                                            controller_nama_kategori.clear();
                                                                          });
                                                                          getkategorifnb();
                                                                          getkategorifnb();
                                                                        }
                                                                      },
                                                                      style: TextButton.styleFrom(
                                                                        foregroundColor:
                                                                            Colors.black,
                                                                      ),
                                                                      child: Text(
                                                                        'Hapus',
                                                                        style: TextStyle(
                                                                          fontSize:
                                                                              20,
                                                                          fontFamily:
                                                                              'Poppins',
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    );
                                                  },
                                                  child: Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontSize: 14,
                                                      color: Colors.white,
                                                    ),
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
                                  inputdatafnb();
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
                      height: 400,
                      width: 810,
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
                                  height: 300,
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
                                          'Nama Produk :',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          'Harga :',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          'Durasi :',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          'Penerima Komisi :',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          '',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          'Komisi :',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          'Stok :',
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
                              Padding(
                                padding: const EdgeInsets.only(top: 0),
                                child: Container(
                                  height: 300,
                                  width: 590,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 12),
                                        Container(
                                          alignment: Alignment.centerLeft,
                                          width: 480,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            color: Colors.grey[300],
                                          ),
                                          child: TextField(
                                            controller: controller_nama_produk,
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
                                          width: 480,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            color: Colors.grey[300],
                                          ),
                                          child: TextField(
                                            controller: controller_harga_produk,
                                            keyboardType: TextInputType.number,
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
                                        SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Container(
                                              alignment: Alignment.centerLeft,
                                              width: 120,
                                              height: 30,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                color: Colors.grey[300],
                                              ),
                                              child: TextField(
                                                controller:
                                                    controller_durasi_produk,
                                                keyboardType:
                                                    TextInputType.number,
                                                inputFormatters: <
                                                  TextInputFormatter
                                                >[
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
                                              ),
                                              child: Text(
                                                'Menit',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 10),
                                        Obx(
                                          () => Container(
                                            width: 120,
                                            height: 30,
                                            padding: EdgeInsets.only(left: 10),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: Colors.grey[300],
                                            ),
                                            child: DropdownButton<RxString>(
                                              value:
                                                  selecteditem?.value == null ||
                                                          selecteditem!
                                                              .value
                                                              .isEmpty
                                                      ? null
                                                      : dropdownpenerimakomisi
                                                          .firstWhereOrNull(
                                                            (itemRx) =>
                                                                itemRx.value ==
                                                                selecteditem!
                                                                    .value,
                                                          ),
                                              isExpanded: true,
                                              underline: SizedBox(),
                                              elevation: 20,
                                              style: const TextStyle(
                                                color: Colors.deepPurple,
                                                fontSize: 18,
                                              ),
                                              onChanged: (RxString? newvalue) {
                                                if (newvalue != null) {
                                                  selecteditem!.value =
                                                      newvalue.value;
                                                } else {
                                                  selecteditem!.value = '';
                                                }
                                              },
                                              items:
                                                  dropdownpenerimakomisi.map<
                                                    DropdownMenuItem<RxString>
                                                  >((RxString itemRx) {
                                                    return DropdownMenuItem<
                                                      RxString
                                                    >(
                                                      value: itemRx,
                                                      child: Text(itemRx.value),
                                                    );
                                                  }).toList(),
                                            ),
                                          ),
                                        ),
                                        Obx(
                                          () =>
                                              selecteditem!.value == 'Terapis'
                                                  ? Row(
                                                    children: [
                                                      Radio<int>(
                                                        value: 1,
                                                        groupValue:
                                                            _selectedRadio,
                                                        onChanged: (
                                                          int? value,
                                                        ) {
                                                          setState(() {
                                                            _selectedRadio =
                                                                value;
                                                            if (_selectedRadio ==
                                                                1) {
                                                              valueradio = 1;
                                                            }
                                                            print(valueradio);
                                                          });
                                                        },
                                                      ),
                                                      Text('Nominal'),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              left: 20,
                                                            ),
                                                        child: Radio<int>(
                                                          value: 2,
                                                          groupValue:
                                                              _selectedRadio,
                                                          onChanged: (
                                                            int? value,
                                                          ) {
                                                            setState(() {
                                                              _selectedRadio =
                                                                  value;
                                                              if (_selectedRadio ==
                                                                  2) {
                                                                valueradio = 0;
                                                              }
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                      Text('Persenan'),
                                                    ],
                                                  )
                                                  : Row(
                                                    children: [
                                                      Radio<int>(
                                                        value: 1,
                                                        groupValue:
                                                            _selectedRadioGro,
                                                        onChanged: (
                                                          int? value,
                                                        ) {
                                                          setState(() {
                                                            _selectedRadioGro =
                                                                value;
                                                            if (_selectedRadioGro ==
                                                                1) {
                                                              valueradiogro = 1;
                                                            }
                                                          });
                                                        },
                                                      ),
                                                      Text('Nominal'),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              left: 20,
                                                            ),
                                                        child: Radio<int>(
                                                          value: 2,
                                                          groupValue:
                                                              _selectedRadioGro,
                                                          onChanged: (
                                                            int? value,
                                                          ) {
                                                            setState(() {
                                                              _selectedRadioGro =
                                                                  value;
                                                              if (_selectedRadioGro ==
                                                                  2) {
                                                                valueradiogro =
                                                                    0;
                                                              }
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                      Text('Persenan'),
                                                    ],
                                                  ),
                                        ),

                                        SizedBox(height: 4),
                                        //INI STACK DIBAWAH RADIOBUTTON
                                        Obx(
                                          () =>
                                              selecteditem!.value == 'Terapis'
                                                  ? Stack(
                                                    children: [
                                                      Visibility(
                                                        visible:
                                                            _selectedRadio == 1,
                                                        child: Container(
                                                          alignment:
                                                              Alignment
                                                                  .centerLeft,
                                                          width: 480,
                                                          height: 30,
                                                          child: Row(
                                                            children: [
                                                              Text(
                                                                'Rp ',
                                                                style: TextStyle(
                                                                  fontSize: 16,
                                                                  fontFamily:
                                                                      'Poppins',
                                                                ),
                                                              ),
                                                              Container(
                                                                alignment:
                                                                    Alignment
                                                                        .centerLeft,
                                                                width: 230,
                                                                height: 30,
                                                                decoration: BoxDecoration(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        10,
                                                                      ),
                                                                  color:
                                                                      Colors
                                                                          .grey[300],
                                                                ),
                                                                child: TextField(
                                                                  controller:
                                                                      controller_nominal_komisi_produk,
                                                                  keyboardType:
                                                                      TextInputType
                                                                          .number,
                                                                  inputFormatters: <
                                                                    TextInputFormatter
                                                                  >[
                                                                    FilteringTextInputFormatter
                                                                        .digitsOnly,
                                                                  ],
                                                                  decoration: InputDecoration(
                                                                    border:
                                                                        InputBorder
                                                                            .none,
                                                                    contentPadding:
                                                                        EdgeInsets.symmetric(
                                                                          vertical:
                                                                              12,
                                                                          horizontal:
                                                                              5,
                                                                        ),
                                                                  ),
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    fontFamily:
                                                                        'Poppins',
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      Visibility(
                                                        visible:
                                                            _selectedRadio == 2,
                                                        child: Container(
                                                          alignment:
                                                              Alignment
                                                                  .centerLeft,
                                                          width: 480,
                                                          height: 30,
                                                          child: Row(
                                                            children: [
                                                              Container(
                                                                alignment:
                                                                    Alignment
                                                                        .centerLeft,
                                                                width: 230,
                                                                height: 30,
                                                                decoration: BoxDecoration(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        10,
                                                                      ),
                                                                  color:
                                                                      Colors
                                                                          .grey[300],
                                                                ),
                                                                child: TextField(
                                                                  controller:
                                                                      controller_nominal_komisi_produk,
                                                                  keyboardType:
                                                                      TextInputType
                                                                          .number,
                                                                  inputFormatters: <
                                                                    TextInputFormatter
                                                                  >[
                                                                    FilteringTextInputFormatter
                                                                        .digitsOnly,
                                                                  ],
                                                                  decoration: InputDecoration(
                                                                    border:
                                                                        InputBorder
                                                                            .none,
                                                                    contentPadding:
                                                                        EdgeInsets.symmetric(
                                                                          vertical:
                                                                              12,
                                                                          horizontal:
                                                                              5,
                                                                        ),
                                                                  ),
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    fontFamily:
                                                                        'Poppins',
                                                                  ),
                                                                ),
                                                              ),
                                                              Text(
                                                                ' % ',
                                                                style: TextStyle(
                                                                  fontSize: 16,
                                                                  fontFamily:
                                                                      'Poppins',
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                  : Stack(
                                                    children: [
                                                      Visibility(
                                                        visible:
                                                            _selectedRadioGro ==
                                                            1,
                                                        child: Container(
                                                          alignment:
                                                              Alignment
                                                                  .centerLeft,
                                                          width: 480,
                                                          height: 30,
                                                          child: Row(
                                                            children: [
                                                              Text(
                                                                'Rp ',
                                                                style: TextStyle(
                                                                  fontSize: 16,
                                                                  fontFamily:
                                                                      'Poppins',
                                                                ),
                                                              ),
                                                              Container(
                                                                alignment:
                                                                    Alignment
                                                                        .centerLeft,
                                                                width: 230,
                                                                height: 30,
                                                                decoration: BoxDecoration(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        10,
                                                                      ),
                                                                  color:
                                                                      Colors
                                                                          .grey[300],
                                                                ),
                                                                child: TextField(
                                                                  controller:
                                                                      controller_nominal_komisi_produk_gro,
                                                                  keyboardType:
                                                                      TextInputType
                                                                          .number,
                                                                  inputFormatters: <
                                                                    TextInputFormatter
                                                                  >[
                                                                    FilteringTextInputFormatter
                                                                        .digitsOnly,
                                                                  ],
                                                                  decoration: InputDecoration(
                                                                    border:
                                                                        InputBorder
                                                                            .none,
                                                                    contentPadding:
                                                                        EdgeInsets.symmetric(
                                                                          vertical:
                                                                              12,
                                                                          horizontal:
                                                                              5,
                                                                        ),
                                                                  ),
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    fontFamily:
                                                                        'Poppins',
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      Visibility(
                                                        visible:
                                                            _selectedRadioGro ==
                                                            2,
                                                        child: Container(
                                                          alignment:
                                                              Alignment
                                                                  .centerLeft,
                                                          width: 480,
                                                          height: 30,
                                                          child: Row(
                                                            children: [
                                                              Container(
                                                                alignment:
                                                                    Alignment
                                                                        .centerLeft,
                                                                width: 230,
                                                                height: 30,
                                                                decoration: BoxDecoration(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        10,
                                                                      ),
                                                                  color:
                                                                      Colors
                                                                          .grey[300],
                                                                ),
                                                                child: TextField(
                                                                  controller:
                                                                      controller_nominal_komisi_produk_gro,
                                                                  keyboardType:
                                                                      TextInputType
                                                                          .number,
                                                                  inputFormatters: <
                                                                    TextInputFormatter
                                                                  >[
                                                                    FilteringTextInputFormatter
                                                                        .digitsOnly,
                                                                  ],
                                                                  decoration: InputDecoration(
                                                                    border:
                                                                        InputBorder
                                                                            .none,
                                                                    contentPadding:
                                                                        EdgeInsets.symmetric(
                                                                          vertical:
                                                                              12,
                                                                          horizontal:
                                                                              5,
                                                                        ),
                                                                  ),
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    fontFamily:
                                                                        'Poppins',
                                                                  ),
                                                                ),
                                                              ),
                                                              Text(
                                                                ' % ',
                                                                style: TextStyle(
                                                                  fontSize: 16,
                                                                  fontFamily:
                                                                      'Poppins',
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                        ),
                                        SizedBox(height: 12),
                                        Container(
                                          alignment: Alignment.centerLeft,
                                          width: 480,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            color: Colors.grey[300],
                                          ),
                                          child: TextField(
                                            controller: controller_stok_produk,
                                            keyboardType: TextInputType.number,
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
                                  inputdataproduk();
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
                  if (_isFourthContainerOnTop)
                    Container(
                      height: 200,
                      width: 810,
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
                                  height: 100,
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
                                          'Nama Fasilitas :',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          'Harga :',
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
                              Padding(
                                padding: const EdgeInsets.only(top: 0),
                                child: Container(
                                  height: 100,
                                  width: 590,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 12),
                                        Container(
                                          alignment: Alignment.centerLeft,
                                          width: 480,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            color: Colors.grey[300],
                                          ),
                                          child: TextField(
                                            controller:
                                                controller_nama_fasilitas,
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
                                          width: 480,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            color: Colors.grey[300],
                                          ),
                                          child: TextField(
                                            controller:
                                                controller_harga_fasilitias,
                                            keyboardType: TextInputType.number,
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
                                  inputdatafasilitas();
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
                  if (_isFifthContainerOnTop)
                    Container(
                      height: 300,
                      width: 810,
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
                                          'Nama Paket :',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          'Durasi :',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          'Harga :',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          'Komisi Terapis :',
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
                              Padding(
                                padding: const EdgeInsets.only(top: 0),
                                child: Container(
                                  height: 180,
                                  width: 590,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 12),
                                        Container(
                                          alignment: Alignment.centerLeft,
                                          width: 480,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            color: Colors.grey[300],
                                          ),
                                          child: TextField(
                                            controller:
                                                controller_nama_paket_extend,
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
                                              width: 120,
                                              height: 30,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                color: Colors.grey[300],
                                              ),
                                              child: TextField(
                                                controller:
                                                    controller_durasi_paket_extend,
                                                keyboardType:
                                                    TextInputType.number,
                                                inputFormatters: <
                                                  TextInputFormatter
                                                >[
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
                                              ),
                                              child: Text(
                                                'Menit',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 12),
                                        Container(
                                          alignment: Alignment.centerLeft,
                                          width: 480,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            color: Colors.grey[300],
                                          ),
                                          child: TextField(
                                            controller:
                                                controller_harga_paket_extend,
                                            keyboardType: TextInputType.number,
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
                                        SizedBox(height: 12),
                                        Container(
                                          alignment: Alignment.centerLeft,
                                          width: 480,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            color: Colors.grey[300],
                                          ),
                                          child: TextField(
                                            controller:
                                                controller_komisi_paket_extend,
                                            keyboardType: TextInputType.number,
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
                                  inputdatapaketextend();
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
