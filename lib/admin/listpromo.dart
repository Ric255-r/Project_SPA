import 'dart:async';
import 'dart:developer';
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
import 'package:Project_SPA/function/ip_address.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'main_admin.dart';
import 'package:Project_SPA/kamar_terapis/main_kamar_terapis.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Project_SPA/main.dart';
import 'package:dio/dio.dart';

class Listpromo extends StatefulWidget {
  const Listpromo({super.key});

  @override
  State<Listpromo> createState() => _ListpromoState();
}

class _ListpromoState extends State<Listpromo> {
  var hargaSatuan = 0.0.obs;
  var limitKunjungan = 1.obs;
  RxDouble hargaPromo = 0.0.obs;
  var diskonPaket = 0.0.obs;
  TextEditingController textinputan = TextEditingController();
  TextEditingController textSearchHappyHour = TextEditingController();
  TextEditingController textsearchkunjungan = TextEditingController();
  TextEditingController textsearchtahunan = TextEditingController();
  TextEditingController textsearchbonusitem = TextEditingController();

  TextEditingController controller_edit_nama_promo_happyhour = TextEditingController();
  TextEditingController controller_edit_jam_mulai_happyhour = TextEditingController();
  TextEditingController controller_edit_jam_selesai_happyhour = TextEditingController();
  TextEditingController controller_edit_menit_mulai_happyhour = TextEditingController();
  TextEditingController controller_edit_menit_selesai_happyhour = TextEditingController();
  TextEditingController controller_edit_disc_happyhour = TextEditingController();

  TextEditingController controller_edit_nama_promo_kunjungan = TextEditingController();
  TextEditingController controller_edit_kode_promo_kunjungan = TextEditingController();
  TextEditingController controller_edit_limit_promo_kunjungan = TextEditingController();
  TextEditingController controller_edit_harga_promo_kunjungan = TextEditingController();
  TextEditingController controller_edit_diskon_paket = TextEditingController();
  TextEditingController controller_edit_hargasatuan = TextEditingController();
  TextEditingController controller_edit_limit_promo = TextEditingController();

  TextEditingController controller_edit_nama_promo_tahunan = TextEditingController();
  TextEditingController controller_edit_jangka_waktu_promo_tahunan = TextEditingController();
  TextEditingController controller_edit_harga_promo_tahunan = TextEditingController();
  TextEditingController controller_edit_nama_promo_bonus_item = TextEditingController();
  TextEditingController controller_edit_qty_bonus_item = TextEditingController();

  List<Map<String, dynamic>> _listNamaPaket = [];
  List<Map<String, dynamic>> _listfnb = [];
  String? dropdownNamaPaket;

  bool _isSecondContainerOnTop = false;

  bool _isThirdContainerOntop = false;

  bool _isFourthContainerOnTop = false;

  Color _FirstbuttonColor = Colors.blue;

  Color _SecondbuttonColor = Colors.white;

  Color _ThirdbuttonColor = Colors.white;

  Color _FourthbuttonColor = Colors.white;

  Timer? debounce;
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

  NumberFormat currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp. ', decimalDigits: 0);

  var dio = Dio();

  RxList<Map<String, dynamic>> datapromohappyhour = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> datapromokunjungan = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> datapromotahunan = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> datapromobonusitem = <Map<String, dynamic>>[].obs;
  String? dropdownnamapaketbonusitem;
  String? selecteditem;

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    controller_edit_disc_happyhour.dispose();
    controller_edit_harga_promo_kunjungan.dispose();
    controller_edit_harga_promo_tahunan.dispose();
    controller_edit_jam_mulai_happyhour.dispose();
    controller_edit_jam_selesai_happyhour.dispose();
    controller_edit_jangka_waktu_promo_tahunan.dispose();
    controller_edit_limit_promo_kunjungan.dispose();
    controller_edit_menit_mulai_happyhour.dispose();
    controller_edit_menit_selesai_happyhour.dispose();
    controller_edit_nama_promo_happyhour.dispose();
    controller_edit_nama_promo_kunjungan.dispose();
    controller_edit_nama_promo_tahunan.dispose();
    debounce?.cancel();
  }

  @override
  void initState() {
    super.initState();
    refreshDataHappyHour();
    refreshDataPromoKunjungan();
    refreshDataPromoTahunan();
    refreshDataPromoBonusItem();
    refreshdatapaketmassageandfnb();
  }

  void _moveSecondContainerToTop() {
    setState(() {
      _isSecondContainerOnTop = true;
      _isThirdContainerOntop = false;
      _isFourthContainerOnTop = false;
    });
  }

  void _moveFirstContainerToTop() {
    setState(() {
      _isSecondContainerOnTop = false;
      _isThirdContainerOntop = false;
      _isFourthContainerOnTop = false;
    });
  }

  void _moveThirdContainerToTop() {
    setState(() {
      _isSecondContainerOnTop = false;
      _isThirdContainerOntop = true;
      _isFourthContainerOnTop = false;
    });
  }

  void _moveFourthContainerToTop() {
    setState(() {
      _isSecondContainerOnTop = false;
      _isThirdContainerOntop = false;
      _isFourthContainerOnTop = true;
    });
  }

  void _toggleButtonColors({
    required bool isFirstButtonPressed,
    isThirdButtonPressed,
    isSecondButtonPressed,
    isFourthButtonPressed,
  }) {
    setState(() {
      if (isFirstButtonPressed) {
        _FirstbuttonColor = Colors.blue;
        _SecondbuttonColor = Colors.white;
        _ThirdbuttonColor = Colors.white;
        _FourthbuttonColor = Colors.white;
      } else if (isThirdButtonPressed) {
        _FirstbuttonColor = Colors.white;
        _SecondbuttonColor = Colors.white;
        _ThirdbuttonColor = Colors.blue;
        _FourthbuttonColor = Colors.white;
      } else if (isSecondButtonPressed) {
        _FirstbuttonColor = Colors.white;
        _SecondbuttonColor = Colors.blue;
        _ThirdbuttonColor = Colors.white;
        _FourthbuttonColor = Colors.white;
      } else if (isFourthButtonPressed) {
        _FirstbuttonColor = Colors.white;
        _SecondbuttonColor = Colors.white;
        _ThirdbuttonColor = Colors.white;
        _FourthbuttonColor = Colors.blue;
      }
    });
  }

  void selectInputPromo() {
    if (_isSecondContainerOnTop == false && _isThirdContainerOntop == false && _isFourthContainerOnTop) {
      textsearchtahunan.clear();
      textsearchkunjungan.clear();
      textsearchbonusitem.clear();
      textinputan = textSearchHappyHour;
    } else if (_isSecondContainerOnTop == true &&
        _isThirdContainerOntop == false &&
        _isFourthContainerOnTop == false) {
      textSearchHappyHour.clear();
      textsearchtahunan.clear();
      textsearchbonusitem.clear();
      textinputan = textsearchkunjungan;
    } else if (_isSecondContainerOnTop == false &&
        _isThirdContainerOntop == true &&
        _isFourthContainerOnTop == false) {
      textSearchHappyHour.clear();
      textsearchkunjungan.clear();
      textsearchbonusitem.clear();
      textinputan = textsearchtahunan;
    } else if (_isSecondContainerOnTop == false &&
        _isThirdContainerOntop == false &&
        _isFourthContainerOnTop == true) {
      textSearchHappyHour.clear();
      textsearchtahunan.clear();
      textsearchkunjungan.clear();
      textinputan = textsearchbonusitem;
    }
  }

  void selectSearchPromo() {
    if (_isSecondContainerOnTop == false &&
        _isThirdContainerOntop == false &&
        _isFourthContainerOnTop == false) {
      searchpromohappyhour();
    } else if (_isSecondContainerOnTop == true &&
        _isThirdContainerOntop == false &&
        _isFourthContainerOnTop == false) {
      searchpromokunjungan();
    } else if (_isSecondContainerOnTop == false &&
        _isThirdContainerOntop == true &&
        _isFourthContainerOnTop == false) {
      searchpromotahunan();
    } else if (_isSecondContainerOnTop == false &&
        _isThirdContainerOntop == false &&
        _isFourthContainerOnTop == true) {
      searchpromobonusitem();
    }
  }

  void calculateHargaPromo() {
    hargaPromo.value =
        hargaPromo.value = (hargaSatuan.value * limitKunjungan.value) * (1 - (diskonPaket.value / 100));
    controller_edit_harga_promo_kunjungan.text = hargaPromo.value.toString();
  }

  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  void isibuttoneditpromotahunan(kode_promo, detail_kode_promo) {
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Container(
                height: 270,
                width: Get.width,
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
                            margin: EdgeInsets.only(top: 50),
                            height: 200,
                            width: 200,
                            decoration: BoxDecoration(color: Colors.white),
                            child: Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  SizedBox(height: 15),
                                  Text('Nama Promo :', style: TextStyle(fontFamily: 'Poppins', fontSize: 18)),
                                  SizedBox(height: 15),
                                  Text(
                                    'Jangka Waktu :',
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 18),
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    'Harga Promo :',
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 18),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(top: 50),
                          height: 200,
                          width: 745,
                          decoration: BoxDecoration(color: Colors.white),
                          child: Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 12),
                                Container(
                                  alignment: Alignment.centerLeft,
                                  width: 700,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.grey[300],
                                  ),
                                  child: TextField(
                                    controller: controller_edit_nama_promo_tahunan,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(vertical: 13.5, horizontal: 10),
                                    ),
                                    style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
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
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.grey[300],
                                      ),
                                      child: TextField(
                                        controller: controller_edit_jangka_waktu_promo_tahunan,
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 13.5,
                                            horizontal: 10,
                                          ),
                                        ),
                                        style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(left: 10),
                                      child: Text(
                                        'Tahun',
                                        style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
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
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.grey[300],
                                  ),
                                  child: TextField(
                                    controller: controller_edit_harga_promo_tahunan,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(vertical: 13.5, horizontal: 10),
                                    ),
                                    style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                  ),
                                ),
                                SizedBox(height: 20),
                                Center(
                                  child: Container(
                                    margin: EdgeInsets.only(right: 120),
                                    height: 35,
                                    width: 100,
                                    child: TextButton(
                                      style: TextButton.styleFrom(backgroundColor: Colors.green),
                                      onPressed: () {
                                        updatedatapromotahunan(kode_promo, detail_kode_promo);
                                        datapromohappyhour.isEmpty
                                            ? Center(child: CircularProgressIndicator())
                                            : refreshDataPromoTahunan();
                                        Get.back();
                                        CherryToast.success(
                                          title: Text('Data Berhasil DiUpdate'),
                                        ).show(context);
                                      },
                                      child: Text(
                                        'Save',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void isibuttoneditpromobonusitem(kode_promo, detail_kode_promo) {
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Container(
                height: 300,
                width: Get.width,
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
                            margin: EdgeInsets.only(top: 50),
                            height: 235,
                            width: 200,
                            decoration: BoxDecoration(color: Colors.white),
                            child: Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  SizedBox(height: 15),
                                  Text('Nama Promo :', style: TextStyle(fontFamily: 'Poppins', fontSize: 18)),
                                  SizedBox(height: 15),
                                  Text('Nama Paket :', style: TextStyle(fontFamily: 'Poppins', fontSize: 18)),
                                  SizedBox(height: 15),
                                  Text('Bonus Item :', style: TextStyle(fontFamily: 'Poppins', fontSize: 18)),
                                  SizedBox(height: 15),
                                  Text('Qty :', style: TextStyle(fontFamily: 'Poppins', fontSize: 18)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(top: 50),
                          height: 235,
                          width: 745,
                          decoration: BoxDecoration(color: Colors.white),
                          child: Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 12),
                                Container(
                                  alignment: Alignment.centerLeft,
                                  width: 700,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.grey[300],
                                  ),
                                  child: TextField(
                                    controller: controller_edit_nama_promo_bonus_item,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(vertical: 13.5, horizontal: 10),
                                    ),
                                    style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                  ),
                                ),
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    Container(
                                      alignment: Alignment.centerLeft,
                                      width: 700,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.grey[300],
                                      ),
                                      child: DropdownButton<String>(
                                        value: dropdownnamapaketbonusitem,
                                        isExpanded: true,
                                        icon: const Icon(Icons.arrow_drop_down),
                                        elevation: 16,
                                        style: const TextStyle(color: Colors.deepPurple),
                                        underline: SizedBox(),
                                        padding: EdgeInsets.symmetric(horizontal: 10),
                                        onChanged: (String? value) {
                                          setState(() {
                                            dropdownnamapaketbonusitem = value;
                                          });
                                        },
                                        items:
                                            _listNamaPaket.map<DropdownMenuItem<String>>((item) {
                                              return DropdownMenuItem<String>(
                                                value: item['id_paket_msg'], // Use ID as value
                                                child: Align(
                                                  alignment: Alignment.centerLeft,
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
                                  ],
                                ),
                                SizedBox(height: 12),
                                Container(
                                  alignment: Alignment.centerLeft,
                                  width: 700,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.grey[300],
                                  ),
                                  child: DropdownButton<String>(
                                    value: selecteditem,
                                    isExpanded: true,
                                    icon: const Icon(Icons.arrow_drop_down),
                                    elevation: 16,
                                    style: const TextStyle(color: Colors.deepPurple),
                                    underline: SizedBox(),
                                    padding: EdgeInsets.symmetric(horizontal: 10),
                                    onChanged: (String? value) {
                                      setState(() {
                                        selecteditem = value;
                                      });
                                    },
                                    items:
                                        _listfnb.map<DropdownMenuItem<String>>((item) {
                                          return DropdownMenuItem<String>(
                                            value: item['id_fnb'], // Use ID as value
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                item['nama_fnb'].toString(), // Display category name
                                                style: const TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ),
                                SizedBox(height: 12),
                                Container(
                                  alignment: Alignment.centerLeft,
                                  width: 700,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.grey[300],
                                  ),
                                  child: TextField(
                                    controller: controller_edit_qty_bonus_item,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(vertical: 13.5, horizontal: 10),
                                    ),
                                    style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                  ),
                                ),
                                SizedBox(height: 20),
                                Center(
                                  child: Container(
                                    margin: EdgeInsets.only(right: 120),
                                    height: 35,
                                    width: 100,
                                    child: TextButton(
                                      style: TextButton.styleFrom(backgroundColor: Colors.green),
                                      onPressed: () {
                                        updatedatapromobonusitem(kode_promo, detail_kode_promo);
                                        datapromobonusitem.isEmpty
                                            ? Center(child: CircularProgressIndicator())
                                            : refreshDataPromoBonusItem();
                                        Get.back();
                                        CherryToast.success(
                                          title: Text('Data Berhasil DiUpdate'),
                                        ).show(context);
                                      },
                                      child: Text(
                                        'Save',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void isibuttoneditpromokunjungan(kode_promo, detail_kode_promo) {
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Container(
                height: 300,
                width: Get.width,
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
                            margin: EdgeInsets.only(top: 50),
                            height: 180,
                            width: 200,
                            decoration: BoxDecoration(color: Colors.white),
                            child: Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  SizedBox(height: 15),
                                  Text('Nama Paket :', style: TextStyle(fontFamily: 'Poppins', fontSize: 18)),
                                  SizedBox(height: 15),
                                  Text(
                                    'Limit Promo :',
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 18),
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    'Limit Kunjungan :',
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 18),
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    'Harga Promo :',
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 18),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(top: 50),
                          height: 180,
                          width: 745,
                          decoration: BoxDecoration(color: Colors.white),
                          child: Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 12),
                                Container(
                                  alignment: Alignment.centerLeft,
                                  width: 730,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.grey[300],
                                  ),
                                  child: TextField(
                                    controller: controller_edit_nama_promo_kunjungan,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(vertical: 13.5, horizontal: 10),
                                    ),
                                    style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
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
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.grey[300],
                                      ),
                                      child: TextField(
                                        controller: controller_edit_limit_promo,
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 13.5,
                                            horizontal: 10,
                                          ),
                                        ),
                                        style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(left: 10),
                                      child: Text(
                                        'Tahun',
                                        style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
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
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.grey[300],
                                      ),
                                      child: TextField(
                                        controller: controller_edit_limit_promo_kunjungan,
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 13.5,
                                            horizontal: 10,
                                          ),
                                        ),
                                        onChanged: (value) {
                                          limitKunjungan.value = int.tryParse(value) ?? 1;
                                          calculateHargaPromo();
                                        },
                                        style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(left: 10),
                                      child: Text(
                                        'Discount :',
                                        style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 10),
                                      child: Container(
                                        alignment: Alignment.centerLeft,
                                        width: 70,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          color: Colors.grey[300],
                                        ),
                                        child: TextField(
                                          controller: controller_edit_diskon_paket,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(
                                              vertical: 13.5,
                                              horizontal: 10,
                                            ),
                                          ),
                                          onChanged: (value) {
                                            diskonPaket.value = double.tryParse(value) ?? 0.0;
                                            calculateHargaPromo();
                                          },
                                          style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(left: 10),
                                      child: Text('%', style: TextStyle(fontSize: 18, fontFamily: 'Poppins')),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Container(
                                  alignment: Alignment.centerLeft,
                                  width: 250,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.grey[300],
                                  ),
                                  child: Obx(
                                    () => TextField(
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(vertical: 13.5, horizontal: 10),
                                      ),
                                      style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                      readOnly: true,
                                      controller: TextEditingController(
                                        text: currencyFormatter.format(hargaPromo.value), // Auto-update
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
                    SizedBox(height: 20),
                    Center(
                      child: Container(
                        height: 35,
                        width: 100,
                        child: TextButton(
                          style: TextButton.styleFrom(backgroundColor: Colors.green),
                          onPressed: () {
                            updatedatapromokunjungan(kode_promo, detail_kode_promo);
                            datapromohappyhour.isEmpty
                                ? Center(child: CircularProgressIndicator())
                                : refreshDataPromoKunjungan();
                            Get.back();
                            CherryToast.success(title: Text('Data Berhasil DiUpdate')).show(context);
                          },
                          child: Text(
                            'Save',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void isibuttonedithappyhour(kode_promo, detail_kode_promo) {
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Center(
                child: Container(
                  height: 380,
                  width: Get.width,
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
                            child: Center(
                              child: Container(
                                margin: EdgeInsets.only(top: 60),
                                height: 260,
                                width: 200,
                                decoration: BoxDecoration(color: Colors.white),
                                child: Padding(
                                  padding: EdgeInsets.only(right: 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      SizedBox(height: 15),
                                      Text(
                                        'Nama Promo :',
                                        style: TextStyle(fontFamily: 'Poppins', fontSize: 18),
                                      ),
                                      SizedBox(height: 15),
                                      Text(
                                        'Discount Promo :',
                                        style: TextStyle(fontFamily: 'Poppins', fontSize: 18),
                                      ),
                                      SizedBox(height: 15),
                                      Text(
                                        'Hari Berlaku :',
                                        style: TextStyle(fontFamily: 'Poppins', fontSize: 18),
                                      ),
                                      SizedBox(height: 15),
                                      Text(
                                        'Jam Berlaku :',
                                        style: TextStyle(fontFamily: 'Poppins', fontSize: 18),
                                      ),
                                      SizedBox(height: 15),
                                      Text(
                                        'Berlaku Untuk :',
                                        style: TextStyle(fontFamily: 'Poppins', fontSize: 18),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(top: 60),
                            height: 260,
                            width: 749,
                            decoration: BoxDecoration(color: Colors.white),
                            child: Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 12),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    width: 730,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey[300],
                                    ),
                                    child: TextField(
                                      controller: controller_edit_nama_promo_happyhour,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(vertical: 13.5, horizontal: 10),
                                      ),
                                      style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
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
                                          borderRadius: BorderRadius.circular(10),
                                          color: Colors.grey[300],
                                        ),
                                        child: TextField(
                                          controller: controller_edit_disc_happyhour,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(
                                              vertical: 13.5,
                                              horizontal: 10,
                                            ),
                                          ),
                                          style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(left: 10),
                                        child: Text(
                                          '% Dari Total Transaksi',
                                          style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
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
                                              isSeninChecked = value ?? false;
                                            });
                                            if (isSeninChecked == true) {
                                              valuesenin = 1;
                                            } else {
                                              valuesenin = 0;
                                            }
                                          },
                                        ),
                                      ),
                                      Text('Senin', style: TextStyle(fontSize: 17, fontFamily: 'Poppins')),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 5),
                                        child: Center(
                                          child: Checkbox(
                                            value: isSelasaChecked,
                                            onChanged: (bool? value) {
                                              setState(() {
                                                isSelasaChecked = value ?? false;
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
                                      Text('Selasa', style: TextStyle(fontSize: 17, fontFamily: 'Poppins')),
                                      Center(
                                        child: Checkbox(
                                          value: isRabuChecked,
                                          onChanged: (bool? value) {
                                            setState(() {
                                              isRabuChecked = value ?? false;
                                            });
                                            if (isRabuChecked == true) {
                                              valuerabu = 1;
                                            } else {
                                              valuerabu = 0;
                                            }
                                          },
                                        ),
                                      ),
                                      Text('Rabu', style: TextStyle(fontSize: 17, fontFamily: 'Poppins')),
                                      Center(
                                        child: Checkbox(
                                          value: isKamisChecked,
                                          onChanged: (bool? value) {
                                            setState(() {
                                              isKamisChecked = value ?? false;
                                            });
                                            if (isKamisChecked == true) {
                                              valuekamis = 1;
                                            } else {
                                              valuekamis = 0;
                                            }
                                          },
                                        ),
                                      ),
                                      Text('Kamis', style: TextStyle(fontSize: 17, fontFamily: 'Poppins')),
                                      Center(
                                        child: Checkbox(
                                          value: isJumatChecked,
                                          onChanged: (bool? value) {
                                            setState(() {
                                              isJumatChecked = value ?? false;
                                            });
                                            if (isJumatChecked == true) {
                                              valuejumat = 1;
                                            } else {
                                              valuejumat = 0;
                                            }
                                          },
                                        ),
                                      ),
                                      Text('Jumat', style: TextStyle(fontSize: 17, fontFamily: 'Poppins')),
                                      Center(
                                        child: Checkbox(
                                          value: isSabtuChecked,
                                          onChanged: (bool? value) {
                                            setState(() {
                                              isSabtuChecked = value ?? false;
                                            });
                                            if (isSabtuChecked == true) {
                                              valuesabtu = 1;
                                            } else {
                                              valuesabtu = 0;
                                            }
                                          },
                                        ),
                                      ),
                                      Text('Sabtu', style: TextStyle(fontSize: 17, fontFamily: 'Poppins')),
                                      Center(
                                        child: Checkbox(
                                          value: isMingguChecked,
                                          onChanged: (bool? value) {
                                            setState(() {
                                              isMingguChecked = value ?? false;
                                            });
                                            if (isMingguChecked == true) {
                                              valueminggu = 1;
                                            } else {
                                              valueminggu = 0;
                                            }
                                          },
                                        ),
                                      ),
                                      Text('Minggu', style: TextStyle(fontSize: 17, fontFamily: 'Poppins')),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        alignment: Alignment.centerLeft,
                                        width: 50,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          color: Colors.grey[300],
                                        ),
                                        child: TextField(
                                          controller: controller_edit_jam_mulai_happyhour,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(
                                              vertical: 13.5,
                                              horizontal: 10,
                                            ),
                                          ),
                                          style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(left: 5, right: 5),
                                        child: Text(
                                          ':',
                                          style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                        ),
                                      ),
                                      Container(
                                        alignment: Alignment.centerLeft,
                                        width: 50,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          color: Colors.grey[300],
                                        ),
                                        child: TextField(
                                          controller: controller_edit_menit_mulai_happyhour,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(
                                              vertical: 13.5,
                                              horizontal: 10,
                                            ),
                                          ),
                                          style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(left: 10, right: 10),
                                        child: Text(
                                          'Sampai',
                                          style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                        ),
                                      ),
                                      Container(
                                        alignment: Alignment.centerLeft,
                                        width: 50,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          color: Colors.grey[300],
                                        ),
                                        child: TextField(
                                          controller: controller_edit_jam_selesai_happyhour,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(
                                              vertical: 13.5,
                                              horizontal: 10,
                                            ),
                                          ),
                                          style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(left: 5, right: 5),
                                        child: Text(
                                          ':',
                                          style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                        ),
                                      ),
                                      Container(
                                        alignment: Alignment.centerLeft,
                                        width: 50,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          color: Colors.grey[300],
                                        ),
                                        child: TextField(
                                          controller: controller_edit_menit_selesai_happyhour,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(
                                              vertical: 13.5,
                                              horizontal: 10,
                                            ),
                                          ),
                                          style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
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
                                              isUmumChecked = value ?? false;
                                            });
                                            if (isUmumChecked == true) {
                                              valueumum = 1;
                                            } else {
                                              valueumum = 0;
                                            }
                                          },
                                        ),
                                      ),
                                      Text('Umum', style: TextStyle(fontSize: 18, fontFamily: 'Poppins')),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 30),
                                        child: Checkbox(
                                          value: isMemberChecked,
                                          onChanged: (bool? value) {
                                            setState(() {
                                              isMemberChecked = value ?? false;
                                            });
                                            if (isMemberChecked == true) {
                                              valuemember = 1;
                                            } else {
                                              valuemember = 0;
                                            }
                                          },
                                        ),
                                      ),
                                      Text('Member', style: TextStyle(fontSize: 17, fontFamily: 'Poppins')),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 30),
                                        child: Center(
                                          child: Checkbox(
                                            value: isVIPChecked,
                                            onChanged: (bool? value) {
                                              setState(() {
                                                isVIPChecked = value ?? false;
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
                                      Text('VIP', style: TextStyle(fontSize: 18, fontFamily: 'Poppins')),
                                    ],
                                  ),
                                  Center(
                                    child: Container(
                                      margin: EdgeInsets.only(right: 120),
                                      height: 35,
                                      width: 100,
                                      child: TextButton(
                                        style: TextButton.styleFrom(backgroundColor: Colors.green),
                                        onPressed: () {
                                          updatepromohappyhour(kode_promo, detail_kode_promo);
                                          datapromohappyhour.isEmpty
                                              ? Center(child: CircularProgressIndicator())
                                              : refreshDataHappyHour();
                                          Get.back();
                                          CherryToast.success(
                                            title: Text('Data Berhasil DiUpdate'),
                                          ).show(context);
                                        },
                                        child: Text(
                                          'Save',
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
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> getdatahappyhour() async {
    try {
      var response = await dio.get('${myIpAddr()}/listpromo/getdatapromohappyhour');
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "kode_promo": item['kode_promo'],
              "nama_promo": item['nama_promo'],
              "disc": item['disc'],
              "valuesenin": item['senin'],
              "valueselasa": item['selasa'],
              "valuerabu": item['rabu'],
              "valuekamis": item['kamis'],
              "valuejumat": item['jumat'],
              "valuesabtu": item['sabtu'],
              "valueminggu": item['minggu'],
              "valueumum": item['umum'],
              "valuevip": item['vip'],
              "valuemember": item['member'],
              "jam_mulai": item['jam_mulai'],
              "jam_selesai": item['jam_selesai'],
              "detail_kode_promo": item['detail_kode_promo'],
            };
          }).toList();
      setState(() {
        datapromohappyhour.clear();
        datapromohappyhour.assignAll(fetcheddata);
        datapromohappyhour.refresh();
      });
    } catch (e) {
      log("Error di fn Getdapaketmassage : $e");
    }
  }

  Future<void> updatepromohappyhour(kode_promo, detail_kode_promo) async {
    try {
      var response = await dio.put(
        '${myIpAddr()}/listpromo/updatepromohappyhour',
        data: {
          "nama_promo": controller_edit_nama_promo_happyhour.text,
          "senin": valuesenin,
          "selasa": valueselasa,
          "rabu": valuerabu,
          "kamis": valuekamis,
          "jumat": valuejumat,
          "sabtu": valuesabtu,
          "minggu": valueminggu,
          "umum": valueumum,
          "vip": valuevip,
          "member": valuemember,
          "jam_mulai":
              '${controller_edit_jam_mulai_happyhour.text}:${controller_edit_menit_mulai_happyhour.text}',
          "jam_selesai":
              '${controller_edit_jam_selesai_happyhour.text}:${controller_edit_menit_selesai_happyhour.text}',
          "disc": controller_edit_disc_happyhour.text,
          "kode_promo": kode_promo,
          "detail_kode_promo": detail_kode_promo,
        },
      );
    } catch (e) {
      log("Error di fn Getdapaketmassage : $e");
    }
  }

  Future<void> deletepromohappyhour(kode_promo) async {
    try {
      var response = await dio.delete(
        '${myIpAddr()}/listpromo/deletepromohappyhour',
        data: {"kode_promo": kode_promo},
      );
    } catch (e) {
      log("Error di fn Getdapaketmassage : $e");
    }
  }

  Future<void> getdatapromokunjungan() async {
    try {
      var response = await dio.get('${myIpAddr()}/listpromo/getdatapromokunjungan');
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "kode_promo": item['kode_promo'],
              "nama_promo": item['nama_promo'],
              "limit_kunjungan": item['limit_kunjungan'],
              "harga_promo": item['harga_promo'],
              "harga_satuan": item['harga_satuan'],
              "detail_kode_promo": item['detail_kode_promo'],
              "limit_promo": item['limit_promo'],
              "durasi": item['durasi'],
              "discount": item['discount'],
            };
          }).toList();
      setState(() {
        datapromokunjungan.clear();
        datapromokunjungan.assignAll(fetcheddata);
        datapromokunjungan.refresh();
      });
    } catch (e) {
      log("Error di fn Getdapaketmassage : $e");
    }
  }

  Future<void> updatedatapromokunjungan(kode_promo, detail_kode_promo) async {
    try {
      var response = await dio.put(
        '${myIpAddr()}/listpromo/updatepromokunjungan',
        data: {
          "kode_promo": kode_promo,
          "nama_promo": controller_edit_nama_promo_kunjungan.text,
          "limit_kunjungan": controller_edit_limit_promo_kunjungan.text,
          "limit_promo": controller_edit_limit_promo.text,
          "harga_promo": controller_edit_harga_promo_kunjungan.text,
          "detail_kode_promo": detail_kode_promo,
          "discount": controller_edit_diskon_paket.text,
        },
      );
    } catch (e) {
      log("Error di fn Getdapaketmassage : $e");
    }
  }

  Future<void> deletepromokunjungan(kode_promo) async {
    try {
      var response = await dio.delete(
        '${myIpAddr()}/listpromo/deletepromokunjungan',
        data: {"kode_promo": kode_promo},
      );
    } catch (e) {
      if (e is DioException) {
        log("Error di fn Getdapaketmassage : ${e.response!.data}");
      }
    }
  }

  Future<void> getdatapromotahunan() async {
    try {
      var response = await dio.get('${myIpAddr()}/listpromo/getdatapromotahunan');
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "kode_promo": item['kode_promo'],
              "nama_promo": item['nama_promo'],
              "jangka_tahun": item['jangka_tahun'],
              "harga_promo": item['harga_promo'],
              "detail_kode_promo": item['detail_kode_promo'],
            };
          }).toList();
      setState(() {
        datapromotahunan.clear();
        datapromotahunan.assignAll(fetcheddata);
        datapromotahunan.refresh();
      });
    } catch (e) {
      log("Error di fn Getdapaketmassage : $e");
    }
  }

  Future<void> updatedatapromotahunan(kode_promo, detail_kode_promo) async {
    try {
      var response = await dio.put(
        '${myIpAddr()}/listpromo/updatepromotahunan',
        data: {
          "nama_promo": controller_edit_nama_promo_tahunan.text,
          "jangka_tahun": controller_edit_jangka_waktu_promo_tahunan.text,
          "harga_promo": controller_edit_harga_promo_tahunan.text,
          "kode_promo": kode_promo,
          "detail_kode_promo": detail_kode_promo,
        },
      );
    } catch (e) {
      log("Error di fn Getdapaketmassage : $e");
    }
  }

  Future<void> deletepromotahunan(kode_promo) async {
    try {
      var response = await dio.delete(
        '${myIpAddr()}/listpromo/deletepromotahunan',
        data: {"kode_promo": kode_promo},
      );
    } catch (e) {
      log("Error di fn deletepromotahunan : $e");
    }
  }

  Future<void> getdatapromobonusitem() async {
    try {
      var response = await dio.get('${myIpAddr()}/listpromo/getdatapromobonusitem');
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "kode_promo": item['kode_promo'],
              "nama_promo": item['nama_promo'],
              "detail_kode_promo": item['detail_kode_promo'],
              "nama_paket_msg": item['nama_paket_msg'],
              "nama_fnb": item['nama_fnb'],
              "id_paket_msg": item['id_paket'],
              "id_fnb": item['id_fnb'],
              "qty": item['qty'],
            };
          }).toList();
      setState(() {
        datapromobonusitem.clear();
        datapromobonusitem.assignAll(fetcheddata);
        datapromobonusitem.refresh();
      });
    } catch (e) {
      log("Error di fn Getdapaketmassage : $e");
    }
  }

  Future<void> updatedatapromobonusitem(kode_promo, detail_kode_promo) async {
    try {
      var response = await dio.put(
        '${myIpAddr()}/listpromo/updatepromobonusitem',
        data: {
          "nama_promo": controller_edit_nama_promo_bonus_item.text,
          "id_paket": dropdownnamapaketbonusitem,
          "id_fnb": selecteditem,
          "qty": controller_edit_qty_bonus_item.text,
          "kode_promo": kode_promo,
          "detail_kode_promo": detail_kode_promo,
        },
      );
    } catch (e) {
      log("Error di fn updatedatapromobonusitem : $e");
    }
  }

  Future<void> deletepromobonusitem(kode_promo) async {
    try {
      var response = await dio.delete(
        '${myIpAddr()}/listpromo/deletepromobonusitem',
        data: {"kode_promo": kode_promo},
      );
    } catch (e) {
      log("Error di fn deletepromobonusitem : $e");
    }
  }

  Future<void> getDataPaket() async {
    try {
      var response = await dio.get('${myIpAddr()}/listmassage/getdatapaketmassage');
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

  Future<void> getDataFnb() async {
    try {
      var response = await dio.get('${myIpAddr()}/listfnb/getdatafnb');
      setState(() {
        _listfnb =
            (response.data as List).map((item) {
              return {"id_fnb": item["id_fnb"], "nama_fnb": item["nama_fnb"]};
            }).toList();
      });
    } catch (e) {
      log("Error di fn Get Data Fnb $e");
    }
  }

  Future<void> refreshDataHappyHour() async {
    await Future.delayed(Duration(seconds: 1));
    await getdatahappyhour();
  }

  Future<void> refreshdatapaketmassageandfnb() async {
    await Future.delayed(Duration(seconds: 1));
    await getDataPaket();
    await getDataFnb();
  }

  Future<void> refreshDataPromoKunjungan() async {
    await Future.delayed(Duration(seconds: 1));
    await getdatapromokunjungan();
  }

  Future<void> refreshDataPromoTahunan() async {
    await Future.delayed(Duration(seconds: 1));
    await getdatapromotahunan();
  }

  Future<void> refreshDataPromoBonusItem() async {
    await Future.delayed(Duration(seconds: 1));
    await getdatapromobonusitem();
  }

  Future<void> searchpromohappyhour() async {
    try {
      var response = await dio.get(
        '${myIpAddr()}/searchpromo/searchpromohappyhour',
        data: {"nama_promo": textinputan.text},
      );
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "kode_promo": item['kode_promo'],
              "nama_promo": item['nama_promo'],
              "disc": item['disc'],
              "valuesenin": item['senin'],
              "valueselasa": item['selasa'],
              "valuerabu": item['rabu'],
              "valuekamis": item['kamis'],
              "valuejumat": item['jumat'],
              "valuesabtu": item['sabtu'],
              "valueminggu": item['minggu'],
              "valuevip": item['vip'],
              "valuemember": item['member'],
              "jam_mulai": item['jam_mulai'],
              "jam_selesai": item['jam_selesai'],
              "detail_kode_promo": item['detail_kode_promo'],
            };
          }).toList();
      setState(() {
        datapromohappyhour.clear();
        datapromohappyhour.assignAll(fetcheddata);
        datapromohappyhour.refresh();
      });
    } catch (e) {
      log("Error di fn searchpromohappyhour : $e");
    }
  }

  Future<void> searchpromokunjungan() async {
    try {
      var response = await dio.get(
        '${myIpAddr()}/searchpromo/searchpromokunjungan',
        queryParameters: {"nama_promo": textinputan.text},
      );
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "kode_promo": item['kode_promo'],
              "nama_promo": item['nama_promo'],
              "limit_kunjungan": item['limit_kunjungan'],
              "harga_promo": item['harga_promo'],
              "harga_satuan": item['harga_paket_msg'],
              "detail_kode_promo": item['detail_kode_promo'],
              "limit_promo": item['limit_promo'],
              "durasi": item['durasi'],
              "discount": item['discount'],
            };
          }).toList();
      setState(() {
        datapromokunjungan.clear();
        datapromokunjungan.assignAll(fetcheddata);
        datapromokunjungan.refresh();
      });
    } catch (e) {
      log("Error di fn searchpromokunjungan : $e");
    }
  }

  Future<void> searchpromotahunan() async {
    try {
      var response = await dio.get(
        '${myIpAddr()}/searchpromo/searchpromotahunan',
        data: {"nama_promo": textinputan.text},
      );
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "kode_promo": item['kode_promo'],
              "nama_promo": item['nama_promo'],
              "jangka_tahun": item['jangka_tahun'],
              "harga_promo": item['harga_promo'],
              "detail_kode_promo": item['detail_kode_promo'],
            };
          }).toList();
      setState(() {
        datapromotahunan.clear();
        datapromotahunan.assignAll(fetcheddata);
        datapromotahunan.refresh();
      });
    } catch (e) {
      log("Error di fn searchpromotahunan : $e");
    }
  }

  Future<void> searchpromobonusitem() async {
    try {
      var response = await dio.get(
        '${myIpAddr()}/searchpromo/searchpromobonusitem',
        data: {"nama_promo": textinputan.text},
      );
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "kode_promo": item['kode_promo'],
              "nama_promo": item['nama_promo'],
              "detail_kode_promo": item['detail_kode_promo'],
              "nama_paket_msg": item['nama_paket_msg'],
              "nama_fnb": item['nama_fnb'],
              "id_paket_msg": item['id_paket'],
              "id_fnb": item['id_fnb'],
              "qty": item['qty'],
            };
          }).toList();
      setState(() {
        datapromobonusitem.clear();
        datapromobonusitem.assignAll(fetcheddata);
        datapromobonusitem.refresh();
      });
    } catch (e) {
      log("Error di fn searchpromobonusitem : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
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
        ? WidgetListPromoMobile()
        : Scaffold(
          appBar: AppBar(
            // title: Container(
            //   width: 30,
            //   height: 30,
            //   child: ClipOval(child: Image.asset('assets/spa.jpeg')),
            // ),
            elevation: 0,
            scrolledUnderElevation: 0,
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
                  Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Text(
                      'List Promo',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 730),
                    child: Row(
                      children: [
                        Container(
                          width: 250,
                          height: 40,
                          child: TextField(
                            controller: textinputan,
                            onChanged: (String query) {
                              if (debounce?.isActive ?? false) {
                                debounce!.cancel();
                              }
                              debounce = Timer(Duration(milliseconds: 1000), () {
                                selectSearchPromo();
                              });
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Input Promo',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 20, left: 100),
                        child: ElevatedButton(
                          onPressed: () {
                            if (textSearchHappyHour.text == "") {
                              refreshDataHappyHour();
                            }
                            selectInputPromo();
                            _moveFirstContainerToTop();
                            _toggleButtonColors(
                              isFirstButtonPressed: true,
                              isSecondButtonPressed: false,
                              isThirdButtonPressed: false,
                              isFourthButtonPressed: false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: _FirstbuttonColor == Colors.blue ? Colors.white : Colors.black,
                            backgroundColor: _FirstbuttonColor,
                            minimumSize: Size(150, 45),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          ),
                          child: Text('Promo Happy Hour', style: TextStyle(color: Colors.black)),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 20, left: 10),
                        child: ElevatedButton(
                          onPressed: () {
                            if (textsearchkunjungan.text == "") {
                              refreshDataPromoKunjungan();
                            }
                            selectInputPromo();
                            _moveSecondContainerToTop();
                            _toggleButtonColors(
                              isFirstButtonPressed: false,
                              isThirdButtonPressed: false,
                              isSecondButtonPressed: true,
                              isFourthButtonPressed: false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _SecondbuttonColor,
                            foregroundColor: _FirstbuttonColor == Colors.blue ? Colors.white : Colors.black,
                            minimumSize: Size(150, 45),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          ),
                          child: Text('Promo Paketan', style: TextStyle(color: Colors.black)),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 20, left: 10),
                        child: ElevatedButton(
                          onPressed: () {
                            if (textsearchtahunan.text == "") {
                              refreshDataPromoTahunan();
                            }
                            selectInputPromo();
                            _moveThirdContainerToTop();
                            _toggleButtonColors(
                              isFirstButtonPressed: false,
                              isThirdButtonPressed: true,
                              isSecondButtonPressed: false,
                              isFourthButtonPressed: false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _ThirdbuttonColor,
                            foregroundColor: _FirstbuttonColor == Colors.blue ? Colors.white : Colors.black,
                            minimumSize: Size(150, 45),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          ),
                          child: Text('Promo Tahunan', style: TextStyle(color: Colors.black)),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 20, left: 10),
                        child: ElevatedButton(
                          onPressed: () {
                            if (textsearchbonusitem.text == "") {
                              refreshDataPromoBonusItem();
                            }
                            selectInputPromo();
                            _moveFourthContainerToTop();
                            _toggleButtonColors(
                              isFirstButtonPressed: false,
                              isSecondButtonPressed: false,
                              isThirdButtonPressed: false,
                              isFourthButtonPressed: true,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _FourthbuttonColor,
                            foregroundColor: _FirstbuttonColor == Colors.blue ? Colors.white : Colors.black,
                            minimumSize: Size(150, 45),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          ),
                          child: Text('Promo Bonus Item', style: TextStyle(color: Colors.black)),
                        ),
                      ),
                    ],
                  ),

                  Stack(
                    children: [
                      if (!_isSecondContainerOnTop)
                        Container(
                          width: 900,
                          height: 400,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                            color: Colors.white,
                          ),
                          child:
                              datapromohappyhour.isEmpty
                                  ? Center(child: Text('Data Promo Happy Hour Tidak Ada'))
                                  : Obx(
                                    () => ListView.builder(
                                      padding: EdgeInsets.zero,
                                      itemCount: datapromohappyhour.length,
                                      itemBuilder: (context, index) {
                                        var item = datapromohappyhour[index];
                                        return Container(
                                          margin: EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            border: Border.all(width: 1),
                                            borderRadius: BorderRadius.all(Radius.circular(10)),
                                          ),
                                          child: Container(
                                            width: 400,
                                            height: 175,
                                            padding: EdgeInsets.only(left: 10),
                                            child: Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      child: Text(
                                                        item['kode_promo'],
                                                        style: TextStyle(fontSize: 25, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Container(
                                                      child: Text(
                                                        item['nama_promo'],
                                                        style: TextStyle(fontSize: 25, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Container(
                                                      child: Text(
                                                        'Diskon :',
                                                        style: TextStyle(fontSize: 15, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Container(
                                                      child: Text(
                                                        item['disc'].toString(),
                                                        style: TextStyle(fontSize: 15, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                    SizedBox(width: 4),
                                                    Container(
                                                      child: Text(
                                                        '%',
                                                        style: TextStyle(fontSize: 15, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Container(
                                                      child: Text(
                                                        'Hari Berlaku :',
                                                        style: TextStyle(fontSize: 15, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                    Center(
                                                      child: Checkbox(
                                                        value: item['valuesenin'] == 1,
                                                        onChanged: (bool? value) {},
                                                      ),
                                                    ),
                                                    Text(
                                                      'Senin',
                                                      style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.only(left: 5),
                                                      child: Center(
                                                        child: Checkbox(
                                                          value: item['valueselasa'] == 1,
                                                          onChanged: (bool? value) {
                                                            setState(() {});
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      'Selasa',
                                                      style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                    ),
                                                    Center(
                                                      child: Checkbox(
                                                        value: item['valuerabu'] == 1,
                                                        onChanged: (bool? value) {},
                                                      ),
                                                    ),
                                                    Text(
                                                      'Rabu',
                                                      style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                    ),
                                                    Center(
                                                      child: Checkbox(
                                                        value: item['valuekamis'] == 1,
                                                        onChanged: (bool? value) {},
                                                      ),
                                                    ),
                                                    Text(
                                                      'Kamis',
                                                      style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                    ),
                                                    Center(
                                                      child: Checkbox(
                                                        value: item['valuejumat'] == 1,
                                                        onChanged: (bool? value) {},
                                                      ),
                                                    ),
                                                    Text(
                                                      'Jumat',
                                                      style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                    ),
                                                    Center(
                                                      child: Checkbox(
                                                        value: item['valuesabtu'] == 1,
                                                        onChanged: (bool? value) {},
                                                      ),
                                                    ),
                                                    Text(
                                                      'Sabtu',
                                                      style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                    ),
                                                    Center(
                                                      child: Checkbox(
                                                        value: item['valueminggu'] == 1,
                                                        onChanged: (bool? value) {},
                                                      ),
                                                    ),
                                                    Text(
                                                      'Minggu',
                                                      style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                    ),
                                                  ],
                                                ),

                                                Row(
                                                  children: [
                                                    Container(
                                                      child: Text(
                                                        'Jam Berlaku : ',
                                                        style: TextStyle(fontSize: 15, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                    Container(
                                                      child: Text(
                                                        item['jam_mulai'].toString(),
                                                        style: TextStyle(fontSize: 15, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                    Container(
                                                      child: Text(
                                                        ' - ',
                                                        style: TextStyle(fontSize: 15, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                    Container(
                                                      child: Text(
                                                        item['jam_selesai'].toString(),
                                                        style: TextStyle(fontSize: 15, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Container(
                                                      child: Text(
                                                        'Berlaku Untuk : ',
                                                        style: TextStyle(fontSize: 15, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                    Center(
                                                      child: Checkbox(
                                                        value: item['valueumum'] == 1,
                                                        onChanged: (bool? value) {},
                                                      ),
                                                    ),
                                                    Text(
                                                      'Umum',
                                                      style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.only(left: 30),
                                                      child: Checkbox(
                                                        value: item['valuemember'] == 1,
                                                        onChanged: (bool? value) {},
                                                      ),
                                                    ),
                                                    Text(
                                                      'Member',
                                                      style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.only(left: 30),
                                                      child: Center(
                                                        child: Checkbox(
                                                          value: item['valuevip'] == 1,
                                                          onChanged: (bool? value) {},
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      'VIP',
                                                      style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                    ),
                                                    Spacer(),

                                                    SizedBox(width: 10),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        isSeninChecked = item['valuesenin'] == 1;
                                                        isSelasaChecked = item['valueselasa'] == 1;
                                                        isRabuChecked = item['valuerabu'] == 1;
                                                        isKamisChecked = item['valuekamis'] == 1;
                                                        isJumatChecked = item['valuejumat'] == 1;
                                                        isSabtuChecked = item['valuesabtu'] == 1;
                                                        isMingguChecked = item['valueminggu'] == 1;
                                                        isUmumChecked = item['valueumum'] == 1;
                                                        isVIPChecked = item['valuevip'] == 1;
                                                        isMemberChecked = item['valuemember'] == 1;
                                                        valuesenin = isSeninChecked ? 1 : 0;
                                                        valueselasa = isSelasaChecked ? 1 : 0;
                                                        valuerabu = isRabuChecked ? 1 : 0;
                                                        valuekamis = isKamisChecked ? 1 : 0;
                                                        valuejumat = isJumatChecked ? 1 : 0;
                                                        valuesabtu = isSabtuChecked ? 1 : 0;
                                                        valueminggu = isMingguChecked ? 1 : 0;
                                                        valueumum = isUmumChecked ? 1 : 0;
                                                        valuevip = isVIPChecked ? 1 : 0;
                                                        valuemember = isMemberChecked ? 1 : 0;

                                                        controller_edit_nama_promo_happyhour.text =
                                                            item['nama_promo'];
                                                        controller_edit_disc_happyhour.text =
                                                            item['disc'].toString();
                                                        controller_edit_jam_mulai_happyhour.text =
                                                            item['jam_mulai'].toString().split(':')[0];
                                                        controller_edit_menit_mulai_happyhour.text =
                                                            item['jam_mulai'].toString().split(':')[1];
                                                        controller_edit_jam_selesai_happyhour.text =
                                                            item['jam_selesai'].toString().split(':')[0];
                                                        controller_edit_menit_selesai_happyhour.text =
                                                            item['jam_selesai'].toString().split(':')[1];
                                                        isibuttonedithappyhour(
                                                          item['kode_promo'],
                                                          item['detail_kode_promo'],
                                                        );
                                                      },
                                                      child: Text(
                                                        'Edit',
                                                        style: TextStyle(fontSize: 25, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        Get.dialog(
                                                          StatefulBuilder(
                                                            builder: (context, setState) {
                                                              return AlertDialog(
                                                                actions: [
                                                                  Center(
                                                                    child: Container(
                                                                      margin: EdgeInsets.only(top: 20),
                                                                      height: 100,
                                                                      width: 250,
                                                                      child: Center(
                                                                        child: Column(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.center,
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.center,
                                                                          children: [
                                                                            Text(
                                                                              '${item['nama_promo']}',
                                                                              style: TextStyle(
                                                                                fontSize: 16,
                                                                                fontFamily: 'Poppins',
                                                                              ),
                                                                            ),
                                                                            Text(
                                                                              'Yakin ingin delete ?',
                                                                              style: TextStyle(
                                                                                fontSize: 16,
                                                                                fontFamily: 'Poppins',
                                                                              ),
                                                                            ),

                                                                            SizedBox(height: 4),
                                                                            Row(
                                                                              crossAxisAlignment:
                                                                                  CrossAxisAlignment.center,
                                                                              mainAxisAlignment:
                                                                                  MainAxisAlignment.center,
                                                                              children: [
                                                                                ElevatedButton(
                                                                                  onPressed: () {
                                                                                    deletepromohappyhour(
                                                                                      item['kode_promo'],
                                                                                    );
                                                                                    refreshDataHappyHour();
                                                                                    Get.back();
                                                                                    CherryToast.success(
                                                                                      title: Text(
                                                                                        'Data Berhasil DiHapus',
                                                                                      ),
                                                                                    ).show(context);
                                                                                  },
                                                                                  child: Text('Yes'),
                                                                                ),
                                                                                SizedBox(width: 20),
                                                                                ElevatedButton(
                                                                                  onPressed: () {
                                                                                    Get.back();
                                                                                  },
                                                                                  child: Text('No'),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          ),
                                                        );
                                                      },
                                                      child: Text(
                                                        'Delete',
                                                        style: TextStyle(fontSize: 25, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                        ),
                      if (_isSecondContainerOnTop)
                        Container(
                          width: 900,
                          height: 400,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                            color: Colors.white,
                          ),
                          child:
                              datapromokunjungan.isEmpty
                                  ? Center(child: Text('Data Promo Paketan Tidak Ada'))
                                  : Obx(
                                    () => ListView.builder(
                                      padding: EdgeInsets.zero,
                                      itemCount: datapromokunjungan.length,
                                      itemBuilder: (context, index) {
                                        var item = datapromokunjungan[index];
                                        return Container(
                                          margin: EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            border: Border.all(width: 1),
                                            borderRadius: BorderRadius.all(Radius.circular(10)),
                                          ),
                                          child: Container(
                                            width: 400,
                                            padding: EdgeInsets.only(left: 10),
                                            child: Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      child: Text(
                                                        item['kode_promo'],
                                                        style: TextStyle(fontSize: 25, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Container(
                                                      child: Text(
                                                        item['nama_promo'],
                                                        style: TextStyle(fontSize: 25, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Container(
                                                      child: Text(
                                                        'Limit Kunjungan : ',
                                                        style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                    Container(
                                                      child: Text(
                                                        item['limit_kunjungan'].toString(),
                                                        style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 10),
                                                Row(
                                                  children: [
                                                    Container(
                                                      child: Text(
                                                        'Limit Promo : ',
                                                        style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                    Container(
                                                      child: Text(
                                                        item['limit_promo'].toString(),
                                                        style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                    Container(
                                                      child: Text(
                                                        ' Tahun',
                                                        style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 10),
                                                Row(
                                                  children: [
                                                    Container(
                                                      child: Text(
                                                        'Durasi Paket : ',
                                                        style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                    Container(
                                                      child: Text(
                                                        item['durasi'].toString(),
                                                        style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                    Container(
                                                      child: Text(
                                                        ' Menit',
                                                        style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Container(
                                                      child: Text(
                                                        'Diskon : ',
                                                        style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                    Container(
                                                      child: Text(
                                                        item['discount'].toString(),
                                                        style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                    Container(
                                                      child: Text(
                                                        '%',
                                                        style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                    Spacer(),
                                                    Container(
                                                      child: Text(
                                                        currencyFormat.format(item['harga_promo']).toString(),
                                                        style: TextStyle(fontSize: 22, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        controller_edit_kode_promo_kunjungan.text =
                                                            item['kode_promo'];
                                                        controller_edit_nama_promo_kunjungan.text =
                                                            item['nama_promo'];
                                                        controller_edit_limit_promo_kunjungan.text =
                                                            item['limit_kunjungan'].toString();
                                                        controller_edit_limit_promo.text =
                                                            item['limit_promo'].toString();
                                                        hargaPromo.value =
                                                            (item['harga_promo'] as num).toDouble();
                                                        hargaSatuan.value =
                                                            (item['harga_satuan'] as num).toDouble();

                                                        controller_edit_diskon_paket.text =
                                                            item['discount'].toString();

                                                        isibuttoneditpromokunjungan(
                                                          item['kode_promo'],
                                                          item['detail_kode_promo'],
                                                        );
                                                      },
                                                      child: Text(
                                                        'Edit',
                                                        style: TextStyle(fontSize: 25, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        Get.dialog(
                                                          StatefulBuilder(
                                                            builder: (context, setState) {
                                                              return AlertDialog(
                                                                actions: [
                                                                  Center(
                                                                    child: Container(
                                                                      margin: EdgeInsets.only(top: 20),
                                                                      height: 100,
                                                                      width: 250,
                                                                      child: Center(
                                                                        child: Column(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.center,
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.center,
                                                                          children: [
                                                                            Text(
                                                                              '${item['nama_promo']}',
                                                                              style: TextStyle(
                                                                                fontSize: 16,
                                                                                fontFamily: 'Poppins',
                                                                              ),
                                                                            ),
                                                                            Text(
                                                                              'Yakin ingin delete ?',
                                                                              style: TextStyle(
                                                                                fontSize: 16,
                                                                                fontFamily: 'Poppins',
                                                                              ),
                                                                            ),

                                                                            SizedBox(height: 4),
                                                                            Row(
                                                                              crossAxisAlignment:
                                                                                  CrossAxisAlignment.center,
                                                                              mainAxisAlignment:
                                                                                  MainAxisAlignment.center,
                                                                              children: [
                                                                                ElevatedButton(
                                                                                  onPressed: () {
                                                                                    deletepromokunjungan(
                                                                                      item['kode_promo'],
                                                                                    );
                                                                                    refreshDataPromoKunjungan();
                                                                                    Get.back();
                                                                                    CherryToast.success(
                                                                                      title: Text(
                                                                                        'Data Berhasil DiHapus',
                                                                                      ),
                                                                                    ).show(context);
                                                                                  },
                                                                                  child: Text('Yes'),
                                                                                ),
                                                                                SizedBox(width: 20),
                                                                                ElevatedButton(
                                                                                  onPressed: () {
                                                                                    Get.back();
                                                                                  },
                                                                                  child: Text('No'),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          ),
                                                        );
                                                      },
                                                      child: Text(
                                                        'Delete',
                                                        style: TextStyle(fontSize: 25, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                        ),
                      if (_isThirdContainerOntop)
                        Container(
                          width: 900,
                          height: 400,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                            color: Colors.white,
                          ),
                          child:
                              datapromotahunan.isEmpty
                                  ? Center(child: Text('Data Promo Tahunan Tidak Ada'))
                                  : Obx(
                                    () => ListView.builder(
                                      padding: EdgeInsets.zero,
                                      itemCount: datapromotahunan.length,
                                      itemBuilder: (context, index) {
                                        var item = datapromotahunan[index];
                                        return Container(
                                          margin: EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            border: Border.all(width: 1),
                                            borderRadius: BorderRadius.all(Radius.circular(10)),
                                          ),
                                          child: Container(
                                            width: 400,
                                            padding: EdgeInsets.only(left: 10),
                                            child: Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      child: Text(
                                                        item['kode_promo'],
                                                        style: TextStyle(fontSize: 25, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Container(
                                                      child: Text(
                                                        item['nama_promo'],
                                                        style: TextStyle(fontSize: 25, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Container(
                                                      child: Text(
                                                        'Jangka Waktu : ',
                                                        style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                    Container(
                                                      child: Text(
                                                        item['jangka_tahun'].toString(),
                                                        style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                    Container(
                                                      child: Text(
                                                        ' Tahun',
                                                        style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Spacer(),
                                                    Container(
                                                      child: Text(
                                                        currencyFormat
                                                            .format(item['harga_promo'] ?? 0)
                                                            .toString(),
                                                        style: TextStyle(fontSize: 25, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        controller_edit_nama_promo_tahunan.text =
                                                            item['nama_promo'];
                                                        controller_edit_jangka_waktu_promo_tahunan.text =
                                                            item['jangka_tahun'].toString();
                                                        controller_edit_harga_promo_tahunan.text =
                                                            item['harga_promo'].toString();
                                                        isibuttoneditpromotahunan(
                                                          item['kode_promo'],
                                                          item['detail_kode_promo'],
                                                        );
                                                      },
                                                      child: Text(
                                                        'Edit',
                                                        style: TextStyle(fontSize: 25, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        Get.dialog(
                                                          StatefulBuilder(
                                                            builder: (context, setState) {
                                                              return AlertDialog(
                                                                actions: [
                                                                  Center(
                                                                    child: Container(
                                                                      margin: EdgeInsets.only(top: 20),
                                                                      height: 100,
                                                                      width: 250,
                                                                      child: Center(
                                                                        child: Column(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.center,
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.center,
                                                                          children: [
                                                                            Text(
                                                                              '${item['nama_promo']}',
                                                                              style: TextStyle(
                                                                                fontSize: 16,
                                                                                fontFamily: 'Poppins',
                                                                              ),
                                                                            ),
                                                                            Text(
                                                                              'Yakin ingin delete ?',
                                                                              style: TextStyle(
                                                                                fontSize: 16,
                                                                                fontFamily: 'Poppins',
                                                                              ),
                                                                            ),

                                                                            SizedBox(height: 4),
                                                                            Row(
                                                                              crossAxisAlignment:
                                                                                  CrossAxisAlignment.center,
                                                                              mainAxisAlignment:
                                                                                  MainAxisAlignment.center,
                                                                              children: [
                                                                                ElevatedButton(
                                                                                  onPressed: () {
                                                                                    deletepromotahunan(
                                                                                      item['kode_promo'],
                                                                                    );
                                                                                    refreshDataPromoTahunan();
                                                                                    Get.back();
                                                                                    CherryToast.success(
                                                                                      title: Text(
                                                                                        'Data Berhasil DiHapus',
                                                                                      ),
                                                                                    ).show(context);
                                                                                  },
                                                                                  child: Text('Yes'),
                                                                                ),
                                                                                SizedBox(width: 20),
                                                                                ElevatedButton(
                                                                                  onPressed: () {
                                                                                    Get.back();
                                                                                  },
                                                                                  child: Text('No'),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          ),
                                                        );
                                                      },
                                                      child: Text(
                                                        'Delete',
                                                        style: TextStyle(fontSize: 25, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                        ),
                      if (_isFourthContainerOnTop)
                        Container(
                          width: 900,
                          height: 400,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                            color: Colors.white,
                          ),
                          child:
                              datapromobonusitem.isEmpty
                                  ? Center(child: Text('Data Promo Bonus Item Tidak Ada'))
                                  : Obx(
                                    () => ListView.builder(
                                      padding: EdgeInsets.zero,
                                      itemCount: datapromobonusitem.length,
                                      itemBuilder: (context, index) {
                                        var item = datapromobonusitem[index];
                                        return Container(
                                          margin: EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            border: Border.all(width: 1),
                                            borderRadius: BorderRadius.all(Radius.circular(10)),
                                          ),
                                          child: Container(
                                            width: 400,
                                            padding: EdgeInsets.only(left: 10),
                                            child: Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      child: Text(
                                                        item['kode_promo'],
                                                        style: TextStyle(fontSize: 25, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Container(
                                                      child: Text(
                                                        item['nama_promo'],
                                                        style: TextStyle(fontSize: 25, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Container(
                                                      width: 120,
                                                      child: Text(
                                                        'Nama Paket',
                                                        style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                    SizedBox(width: 1),
                                                    Container(
                                                      child: Text(
                                                        ':',
                                                        style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                    SizedBox(width: 5),
                                                    Container(
                                                      child: Text(
                                                        item['nama_paket_msg'].toString(),
                                                        style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Container(
                                                      width: 120,
                                                      child: Text(
                                                        'Bonus Item',
                                                        style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                    SizedBox(width: 1),
                                                    Container(
                                                      child: Text(
                                                        ':',
                                                        style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                    SizedBox(width: 5),
                                                    Container(
                                                      child: Text(
                                                        item['nama_fnb'].toString(),
                                                        style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Container(
                                                      child: Text(
                                                        item['qty'].toString(),
                                                        style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Container(
                                                      child: Text(
                                                        'Pcs',
                                                        style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: [
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        controller_edit_nama_promo_bonus_item.text =
                                                            item['nama_promo'].toString();
                                                        dropdownnamapaketbonusitem =
                                                            item['id_paket_msg'].toString();
                                                        selecteditem = item['id_fnb'].toString();
                                                        controller_edit_qty_bonus_item.text =
                                                            item['qty'].toString();
                                                        isibuttoneditpromobonusitem(
                                                          item['kode_promo'].toString(),
                                                          item['detail_kode_promo'].toString(),
                                                        );
                                                      },
                                                      child: Text(
                                                        'Edit',
                                                        style: TextStyle(fontSize: 25, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        Get.dialog(
                                                          StatefulBuilder(
                                                            builder: (context, setState) {
                                                              return AlertDialog(
                                                                actions: [
                                                                  Center(
                                                                    child: Container(
                                                                      margin: EdgeInsets.only(top: 20),
                                                                      height: 100,
                                                                      width: 250,
                                                                      child: Center(
                                                                        child: Column(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.center,
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.center,
                                                                          children: [
                                                                            Text(
                                                                              '${item['nama_promo']}',
                                                                              style: TextStyle(
                                                                                fontSize: 16,
                                                                                fontFamily: 'Poppins',
                                                                              ),
                                                                            ),
                                                                            Text(
                                                                              'Yakin ingin delete ?',
                                                                              style: TextStyle(
                                                                                fontSize: 16,
                                                                                fontFamily: 'Poppins',
                                                                              ),
                                                                            ),

                                                                            SizedBox(height: 4),
                                                                            Row(
                                                                              crossAxisAlignment:
                                                                                  CrossAxisAlignment.center,
                                                                              mainAxisAlignment:
                                                                                  MainAxisAlignment.center,
                                                                              children: [
                                                                                ElevatedButton(
                                                                                  onPressed: () {
                                                                                    deletepromobonusitem(
                                                                                      item['kode_promo'],
                                                                                    );
                                                                                    refreshDataPromoBonusItem();
                                                                                    Get.back();
                                                                                    CherryToast.success(
                                                                                      title: Text(
                                                                                        'Data Berhasil DiHapus',
                                                                                      ),
                                                                                    ).show(context);
                                                                                  },
                                                                                  child: Text('Yes'),
                                                                                ),
                                                                                SizedBox(width: 20),
                                                                                ElevatedButton(
                                                                                  onPressed: () {
                                                                                    Get.back();
                                                                                  },
                                                                                  child: Text('No'),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          ),
                                                        );
                                                      },
                                                      child: Text(
                                                        'Delete',
                                                        style: TextStyle(fontSize: 25, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
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

class WidgetListPromoMobile extends StatefulWidget {
  const WidgetListPromoMobile({super.key});

  @override
  State<WidgetListPromoMobile> createState() => _WidgetListPromoMobileState();
}

class _WidgetListPromoMobileState extends State<WidgetListPromoMobile> {
  var hargaSatuan = 0.0.obs;
  var limitKunjungan = 1.obs;
  RxDouble hargaPromo = 0.0.obs;
  var diskonPaket = 0.0.obs;
  TextEditingController textinputan = TextEditingController();
  TextEditingController textSearchHappyHour = TextEditingController();
  TextEditingController textsearchkunjungan = TextEditingController();
  TextEditingController textsearchtahunan = TextEditingController();
  TextEditingController textsearchbonusitem = TextEditingController();

  TextEditingController controller_edit_nama_promo_happyhour = TextEditingController();
  TextEditingController controller_edit_jam_mulai_happyhour = TextEditingController();
  TextEditingController controller_edit_jam_selesai_happyhour = TextEditingController();
  TextEditingController controller_edit_menit_mulai_happyhour = TextEditingController();
  TextEditingController controller_edit_menit_selesai_happyhour = TextEditingController();
  TextEditingController controller_edit_disc_happyhour = TextEditingController();

  TextEditingController controller_edit_nama_promo_kunjungan = TextEditingController();
  TextEditingController controller_edit_kode_promo_kunjungan = TextEditingController();
  TextEditingController controller_edit_limit_promo_kunjungan = TextEditingController();
  TextEditingController controller_edit_harga_promo_kunjungan = TextEditingController();
  TextEditingController controller_edit_diskon_paket = TextEditingController();
  TextEditingController controller_edit_hargasatuan = TextEditingController();
  TextEditingController controller_edit_limit_promo = TextEditingController();

  TextEditingController controller_edit_nama_promo_tahunan = TextEditingController();
  TextEditingController controller_edit_jangka_waktu_promo_tahunan = TextEditingController();
  TextEditingController controller_edit_harga_promo_tahunan = TextEditingController();

  List<Map<String, dynamic>> _listNamaPaket = [];
  String? dropdownNamaPaket;

  bool _isSecondContainerOnTop = false;

  bool _isThirdContainerOntop = false;

  bool _isFourthContainerOnTop = false;

  Color _FirstbuttonColor = Colors.blue;

  Color _SecondbuttonColor = Colors.white;

  Color _ThirdbuttonColor = Colors.white;

  Color _FourthbuttonColor = Colors.white;

  Timer? debounce;
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

  NumberFormat currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp. ', decimalDigits: 0);

  var dio = Dio();

  RxList<Map<String, dynamic>> datapromohappyhour = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> datapromokunjungan = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> datapromotahunan = <Map<String, dynamic>>[].obs;

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    controller_edit_disc_happyhour.dispose();
    controller_edit_harga_promo_kunjungan.dispose();
    controller_edit_harga_promo_tahunan.dispose();
    controller_edit_jam_mulai_happyhour.dispose();
    controller_edit_jam_selesai_happyhour.dispose();
    controller_edit_jangka_waktu_promo_tahunan.dispose();
    controller_edit_limit_promo_kunjungan.dispose();
    controller_edit_menit_mulai_happyhour.dispose();
    controller_edit_menit_selesai_happyhour.dispose();
    controller_edit_nama_promo_happyhour.dispose();
    controller_edit_nama_promo_kunjungan.dispose();
    controller_edit_nama_promo_tahunan.dispose();
    debounce?.cancel();
  }

  @override
  void initState() {
    super.initState();
    refreshDataHappyHour();
    refreshDataPromoKunjungan();
    refreshDataPromoTahunan();
  }

  void _moveSecondContainerToTop() {
    setState(() {
      _isSecondContainerOnTop = true;
      _isThirdContainerOntop = false;
      _isFourthContainerOnTop = false;
    });
  }

  void _moveFirstContainerToTop() {
    setState(() {
      _isSecondContainerOnTop = false;
      _isThirdContainerOntop = false;
      _isFourthContainerOnTop = false;
    });
  }

  void _moveThirdContainerToTop() {
    setState(() {
      _isSecondContainerOnTop = false;
      _isThirdContainerOntop = true;
      _isFourthContainerOnTop = false;
    });
  }

  void _toggleButtonColors({required bool isFirstButtonPressed, isThirdButtonPressed}) {
    setState(() {
      if (isFirstButtonPressed) {
        _FirstbuttonColor = Colors.blue;
        _SecondbuttonColor = Colors.white;
        _ThirdbuttonColor = Colors.white;
      } else if (isThirdButtonPressed) {
        _FirstbuttonColor = Colors.white;
        _SecondbuttonColor = Colors.white;
        _ThirdbuttonColor = Colors.blue;
      } else {
        _FirstbuttonColor = Colors.white;
        _SecondbuttonColor = Colors.blue;
        _ThirdbuttonColor = Colors.white;
      }
    });
  }

  void selectInputPromo() {
    if (_isSecondContainerOnTop == false && _isThirdContainerOntop == false) {
      textsearchtahunan.clear();
      textsearchkunjungan.clear();
      textinputan = textSearchHappyHour;
    } else if (_isSecondContainerOnTop == true && _isThirdContainerOntop == false) {
      textSearchHappyHour.clear();
      textsearchtahunan.clear();
      textinputan = textsearchkunjungan;
    } else if (_isSecondContainerOnTop == false && _isThirdContainerOntop == true) {
      textSearchHappyHour.clear();
      textsearchkunjungan.clear();
      textinputan = textsearchtahunan;
    }
  }

  void selectSearchPromo() {
    if (_isSecondContainerOnTop == false &&
        _isThirdContainerOntop == false &&
        _isFourthContainerOnTop == false) {
      searchpromohappyhour();
    } else if (_isSecondContainerOnTop == true &&
        _isThirdContainerOntop == false &&
        _isFourthContainerOnTop == false) {
      searchpromokunjungan();
    } else if (_isSecondContainerOnTop == false && _isThirdContainerOntop == true) {
      searchpromotahunan();
    } else {}
  }

  void calculateHargaPromo() {
    hargaPromo.value =
        hargaPromo.value = (hargaSatuan.value * limitKunjungan.value) * (1 - (diskonPaket.value / 100));
    controller_edit_harga_promo_kunjungan.text = hargaPromo.value.toString();
  }

  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  void isibuttoneditpromotahunan(kode_promo, detail_kode_promo) {
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Container(
                height: 270,
                width: Get.width,
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
                            margin: EdgeInsets.only(top: 50),
                            height: 200,
                            width: 200,
                            decoration: BoxDecoration(color: Colors.white),
                            child: Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  SizedBox(height: 15),
                                  Text('Nama Promo :', style: TextStyle(fontFamily: 'Poppins', fontSize: 18)),
                                  SizedBox(height: 15),
                                  Text(
                                    'Jangka Waktu :',
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 18),
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    'Harga Promo :',
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 18),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(top: 50),
                          height: 200,
                          width: 480,
                          decoration: BoxDecoration(color: Colors.white),
                          child: Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 12),
                                Container(
                                  alignment: Alignment.centerLeft,
                                  width: 450,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.grey[300],
                                  ),
                                  child: TextField(
                                    controller: controller_edit_nama_promo_tahunan,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(vertical: 13.5, horizontal: 10),
                                    ),
                                    style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
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
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.grey[300],
                                      ),
                                      child: TextField(
                                        controller: controller_edit_jangka_waktu_promo_tahunan,
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 13.5,
                                            horizontal: 10,
                                          ),
                                        ),
                                        style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(left: 10),
                                      child: Text(
                                        'Tahun',
                                        style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
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
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.grey[300],
                                  ),
                                  child: TextField(
                                    controller: controller_edit_harga_promo_tahunan,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(vertical: 13.5, horizontal: 10),
                                    ),
                                    style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                  ),
                                ),
                                SizedBox(height: 20),
                                Center(
                                  child: Container(
                                    margin: EdgeInsets.only(right: 120),
                                    height: 35,
                                    width: 100,
                                    child: TextButton(
                                      style: TextButton.styleFrom(backgroundColor: Colors.green),
                                      onPressed: () {
                                        updatedatapromotahunan(kode_promo, detail_kode_promo);
                                        datapromohappyhour.isEmpty
                                            ? Center(child: CircularProgressIndicator())
                                            : refreshDataPromoTahunan();
                                        Get.back();
                                        CherryToast.success(
                                          title: Text('Data Berhasil DiUpdate'),
                                        ).show(context);
                                      },
                                      child: Text(
                                        'Save',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void isibuttoneditpromokunjungan(kode_promo, detail_kode_promo) {
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Container(
                height: 300,
                width: Get.width,
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
                            margin: EdgeInsets.only(top: 50),
                            height: 180,
                            width: 200,
                            decoration: BoxDecoration(color: Colors.white),
                            child: Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  SizedBox(height: 15),
                                  Text('Nama Paket :', style: TextStyle(fontFamily: 'Poppins', fontSize: 18)),
                                  SizedBox(height: 15),
                                  Text(
                                    'Limit Promo :',
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 18),
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    'Limit Kunjungan :',
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 18),
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    'Harga Promo :',
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 18),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(top: 50),
                          height: 180,
                          width: 480,
                          decoration: BoxDecoration(color: Colors.white),
                          child: Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 12),
                                Container(
                                  alignment: Alignment.centerLeft,
                                  width: 450,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.grey[300],
                                  ),
                                  child: TextField(
                                    controller: controller_edit_nama_promo_kunjungan,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(vertical: 13.5, horizontal: 10),
                                    ),
                                    style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
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
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.grey[300],
                                      ),
                                      child: TextField(
                                        controller: controller_edit_limit_promo,
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 13.5,
                                            horizontal: 10,
                                          ),
                                        ),
                                        style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(left: 10),
                                      child: Text(
                                        'Tahun',
                                        style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
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
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.grey[300],
                                      ),
                                      child: TextField(
                                        controller: controller_edit_limit_promo_kunjungan,
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 13.5,
                                            horizontal: 10,
                                          ),
                                        ),
                                        onChanged: (value) {
                                          limitKunjungan.value = int.tryParse(value) ?? 1;
                                          calculateHargaPromo();
                                        },
                                        style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(left: 10),
                                      child: Text(
                                        'Discount :',
                                        style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 10),
                                      child: Container(
                                        alignment: Alignment.centerLeft,
                                        width: 70,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          color: Colors.grey[300],
                                        ),
                                        child: TextField(
                                          controller: controller_edit_diskon_paket,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(
                                              vertical: 13.5,
                                              horizontal: 10,
                                            ),
                                          ),
                                          onChanged: (value) {
                                            diskonPaket.value = double.tryParse(value) ?? 0.0;
                                            calculateHargaPromo();
                                          },
                                          style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(left: 10),
                                      child: Text('%', style: TextStyle(fontSize: 18, fontFamily: 'Poppins')),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Container(
                                  alignment: Alignment.centerLeft,
                                  width: 250,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.grey[300],
                                  ),
                                  child: Obx(
                                    () => TextField(
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(vertical: 13.5, horizontal: 10),
                                      ),
                                      style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                      readOnly: true,
                                      controller: TextEditingController(
                                        text: currencyFormatter.format(hargaPromo.value), // Auto-update
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
                    SizedBox(height: 20),
                    Center(
                      child: Container(
                        height: 35,
                        width: 100,
                        child: TextButton(
                          style: TextButton.styleFrom(backgroundColor: Colors.green),
                          onPressed: () {
                            updatedatapromokunjungan(kode_promo, detail_kode_promo);
                            datapromohappyhour.isEmpty
                                ? Center(child: CircularProgressIndicator())
                                : refreshDataPromoKunjungan();
                            Get.back();
                            CherryToast.success(title: Text('Data Berhasil DiUpdate')).show(context);
                          },
                          child: Text(
                            'Save',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void isibuttonedithappyhour(kode_promo, detail_kode_promo) {
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Center(
                child: Container(
                  height: 380,
                  width: Get.width,
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
                            child: Center(
                              child: Container(
                                margin: EdgeInsets.only(top: 60),
                                height: 300,
                                width: 140,
                                decoration: BoxDecoration(color: Colors.white),
                                child: Padding(
                                  padding: EdgeInsets.only(right: 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      SizedBox(height: 15),
                                      Text(
                                        'Nama Promo :',
                                        style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
                                      ),
                                      SizedBox(height: 25),
                                      Text(
                                        'Discount Promo :',
                                        style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
                                      ),
                                      SizedBox(height: 40),
                                      Text(
                                        'Hari Berlaku :',
                                        style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
                                      ),
                                      SizedBox(height: 45),
                                      Text(
                                        'Jam Berlaku :',
                                        style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
                                      ),
                                      SizedBox(height: 25),
                                      Text(
                                        'Berlaku Untuk :',
                                        style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(top: 60),
                            height: 300,
                            width: 540,
                            decoration: BoxDecoration(color: Colors.white),
                            child: Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 12),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    width: 500,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey[300],
                                    ),
                                    child: TextField(
                                      controller: controller_edit_nama_promo_happyhour,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(vertical: 13.5, horizontal: 10),
                                      ),
                                      style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
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
                                          borderRadius: BorderRadius.circular(10),
                                          color: Colors.grey[300],
                                        ),
                                        child: TextField(
                                          controller: controller_edit_disc_happyhour,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(
                                              vertical: 13.5,
                                              horizontal: 10,
                                            ),
                                          ),
                                          style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(left: 10),
                                        child: Text(
                                          '% Dari Total Transaksi',
                                          style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
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
                                              isSeninChecked = value ?? false;
                                            });
                                            if (isSeninChecked == true) {
                                              valuesenin = 1;
                                            } else {
                                              valuesenin = 0;
                                            }
                                          },
                                        ),
                                      ),
                                      Text('Senin', style: TextStyle(fontSize: 14, fontFamily: 'Poppins')),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 5),
                                        child: Center(
                                          child: Checkbox(
                                            value: isSelasaChecked,
                                            onChanged: (bool? value) {
                                              setState(() {
                                                isSelasaChecked = value ?? false;
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
                                      Text('Selasa', style: TextStyle(fontSize: 14, fontFamily: 'Poppins')),
                                      Center(
                                        child: Checkbox(
                                          value: isRabuChecked,
                                          onChanged: (bool? value) {
                                            setState(() {
                                              isRabuChecked = value ?? false;
                                            });
                                            if (isRabuChecked == true) {
                                              valuerabu = 1;
                                            } else {
                                              valuerabu = 0;
                                            }
                                          },
                                        ),
                                      ),
                                      Text('Rabu', style: TextStyle(fontSize: 14, fontFamily: 'Poppins')),
                                      Center(
                                        child: Checkbox(
                                          value: isKamisChecked,
                                          onChanged: (bool? value) {
                                            setState(() {
                                              isKamisChecked = value ?? false;
                                            });
                                            if (isKamisChecked == true) {
                                              valuekamis = 1;
                                            } else {
                                              valuekamis = 0;
                                            }
                                          },
                                        ),
                                      ),
                                      Text('Kamis', style: TextStyle(fontSize: 14, fontFamily: 'Poppins')),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Center(
                                        child: Checkbox(
                                          value: isJumatChecked,
                                          onChanged: (bool? value) {
                                            setState(() {
                                              isJumatChecked = value ?? false;
                                            });
                                            if (isJumatChecked == true) {
                                              valuejumat = 1;
                                            } else {
                                              valuejumat = 0;
                                            }
                                          },
                                        ),
                                      ),
                                      Text('Jumat', style: TextStyle(fontSize: 14, fontFamily: 'Poppins')),
                                      Center(
                                        child: Checkbox(
                                          value: isSabtuChecked,
                                          onChanged: (bool? value) {
                                            setState(() {
                                              isSabtuChecked = value ?? false;
                                            });
                                            if (isSabtuChecked == true) {
                                              valuesabtu = 1;
                                            } else {
                                              valuesabtu = 0;
                                            }
                                          },
                                        ),
                                      ),
                                      Text('Sabtu', style: TextStyle(fontSize: 14, fontFamily: 'Poppins')),
                                      Center(
                                        child: Checkbox(
                                          value: isMingguChecked,
                                          onChanged: (bool? value) {
                                            setState(() {
                                              isMingguChecked = value ?? false;
                                            });
                                            if (isMingguChecked == true) {
                                              valueminggu = 1;
                                            } else {
                                              valueminggu = 0;
                                            }
                                          },
                                        ),
                                      ),
                                      Text('Minggu', style: TextStyle(fontSize: 14, fontFamily: 'Poppins')),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        alignment: Alignment.centerLeft,
                                        width: 50,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          color: Colors.grey[300],
                                        ),
                                        child: TextField(
                                          controller: controller_edit_jam_mulai_happyhour,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(
                                              vertical: 13.5,
                                              horizontal: 10,
                                            ),
                                          ),
                                          style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(left: 5, right: 5),
                                        child: Text(
                                          ':',
                                          style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                        ),
                                      ),
                                      Container(
                                        alignment: Alignment.centerLeft,
                                        width: 50,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          color: Colors.grey[300],
                                        ),
                                        child: TextField(
                                          controller: controller_edit_menit_mulai_happyhour,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(
                                              vertical: 13.5,
                                              horizontal: 10,
                                            ),
                                          ),
                                          style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(left: 10, right: 10),
                                        child: Text(
                                          'Sampai',
                                          style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                        ),
                                      ),
                                      Container(
                                        alignment: Alignment.centerLeft,
                                        width: 50,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          color: Colors.grey[300],
                                        ),
                                        child: TextField(
                                          controller: controller_edit_jam_selesai_happyhour,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(
                                              vertical: 13.5,
                                              horizontal: 10,
                                            ),
                                          ),
                                          style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(left: 5, right: 5),
                                        child: Text(
                                          ':',
                                          style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                        ),
                                      ),
                                      Container(
                                        alignment: Alignment.centerLeft,
                                        width: 50,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          color: Colors.grey[300],
                                        ),
                                        child: TextField(
                                          controller: controller_edit_menit_selesai_happyhour,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(
                                              vertical: 13.5,
                                              horizontal: 10,
                                            ),
                                          ),
                                          style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
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
                                              isUmumChecked = value ?? false;
                                            });
                                            if (isUmumChecked == true) {
                                              valueumum = 1;
                                            } else {
                                              valueumum = 0;
                                            }
                                          },
                                        ),
                                      ),
                                      Text('Umum', style: TextStyle(fontSize: 14, fontFamily: 'Poppins')),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 30),
                                        child: Checkbox(
                                          value: isMemberChecked,
                                          onChanged: (bool? value) {
                                            setState(() {
                                              isMemberChecked = value ?? false;
                                            });
                                            if (isMemberChecked == true) {
                                              valuemember = 1;
                                            } else {
                                              valuemember = 0;
                                            }
                                          },
                                        ),
                                      ),
                                      Text('Member', style: TextStyle(fontSize: 14, fontFamily: 'Poppins')),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 30),
                                        child: Center(
                                          child: Checkbox(
                                            value: isVIPChecked,
                                            onChanged: (bool? value) {
                                              setState(() {
                                                isVIPChecked = value ?? false;
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
                                      Text('VIP', style: TextStyle(fontSize: 14, fontFamily: 'Poppins')),
                                    ],
                                  ),
                                  Center(
                                    child: Container(
                                      margin: EdgeInsets.only(right: 120),
                                      height: 35,
                                      width: 100,
                                      child: TextButton(
                                        style: TextButton.styleFrom(backgroundColor: Colors.green),
                                        onPressed: () {
                                          updatepromohappyhour(kode_promo, detail_kode_promo);
                                          datapromohappyhour.isEmpty
                                              ? Center(child: CircularProgressIndicator())
                                              : refreshDataHappyHour();
                                          Get.back();
                                          CherryToast.success(
                                            title: Text('Data Berhasil DiUpdate'),
                                          ).show(context);
                                        },
                                        child: Text(
                                          'Save',
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
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> getdatahappyhour() async {
    try {
      var response = await dio.get('${myIpAddr()}/listpromo/getdatapromohappyhour');
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "kode_promo": item['kode_promo'],
              "nama_promo": item['nama_promo'],
              "disc": item['disc'],
              "valuesenin": item['senin'],
              "valueselasa": item['selasa'],
              "valuerabu": item['rabu'],
              "valuekamis": item['kamis'],
              "valuejumat": item['jumat'],
              "valuesabtu": item['sabtu'],
              "valueminggu": item['minggu'],
              "valueumum": item['umum'],
              "valuevip": item['vip'],
              "valuemember": item['member'],
              "jam_mulai": item['jam_mulai'],
              "jam_selesai": item['jam_selesai'],
              "detail_kode_promo": item['detail_kode_promo'],
            };
          }).toList();
      setState(() {
        datapromohappyhour.clear();
        datapromohappyhour.assignAll(fetcheddata);
        datapromohappyhour.refresh();
      });
    } catch (e) {
      log("Error di fn Getdapaketmassage : $e");
    }
  }

  Future<void> updatepromohappyhour(kode_promo, detail_kode_promo) async {
    try {
      var response = await dio.put(
        '${myIpAddr()}/listpromo/updatepromohappyhour',
        data: {
          "nama_promo": controller_edit_nama_promo_happyhour.text,
          "senin": valuesenin,
          "selasa": valueselasa,
          "rabu": valuerabu,
          "kamis": valuekamis,
          "jumat": valuejumat,
          "sabtu": valuesabtu,
          "minggu": valueminggu,
          "umum": valueumum,
          "vip": valuevip,
          "member": valuemember,
          "jam_mulai":
              '${controller_edit_jam_mulai_happyhour.text}:${controller_edit_menit_mulai_happyhour.text}',
          "jam_selesai":
              '${controller_edit_jam_selesai_happyhour.text}:${controller_edit_menit_selesai_happyhour.text}',
          "disc": controller_edit_disc_happyhour.text,
          "kode_promo": kode_promo,
          "detail_kode_promo": detail_kode_promo,
        },
      );
    } catch (e) {
      log("Error di fn Getdapaketmassage : $e");
    }
  }

  Future<void> deletepromohappyhour(kode_promo) async {
    try {
      var response = await dio.delete(
        '${myIpAddr()}/listpromo/deletepromohappyhour',
        data: {"kode_promo": kode_promo},
      );
    } catch (e) {
      log("Error di fn Getdapaketmassage : $e");
    }
  }

  Future<void> getdatapromokunjungan() async {
    try {
      var response = await dio.get('${myIpAddr()}/listpromo/getdatapromokunjungan');
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "kode_promo": item['kode_promo'],
              "nama_promo": item['nama_promo'],
              "limit_kunjungan": item['limit_kunjungan'],
              "harga_promo": item['harga_promo'],
              "harga_satuan": item['harga_satuan'],
              "detail_kode_promo": item['detail_kode_promo'],
              "limit_promo": item['limit_promo'],
              "durasi": item['durasi'],
              "discount": item['discount'],
            };
          }).toList();
      setState(() {
        datapromokunjungan.clear();
        datapromokunjungan.assignAll(fetcheddata);
        datapromokunjungan.refresh();
      });
    } catch (e) {
      log("Error di fn Getdapaketmassage : $e");
    }
  }

  Future<void> updatedatapromokunjungan(kode_promo, detail_kode_promo) async {
    try {
      var response = await dio.put(
        '${myIpAddr()}/listpromo/updatepromokunjungan',
        data: {
          "kode_promo": kode_promo,
          "nama_promo": controller_edit_nama_promo_kunjungan.text,
          "limit_kunjungan": controller_edit_limit_promo_kunjungan.text,
          "limit_promo": controller_edit_limit_promo.text,
          "harga_promo": controller_edit_harga_promo_kunjungan.text,
          "detail_kode_promo": detail_kode_promo,
          "discount": controller_edit_diskon_paket.text,
        },
      );
    } catch (e) {
      log("Error di fn Getdapaketmassage : $e");
    }
  }

  Future<void> deletepromokunjungan(kode_promo) async {
    try {
      var response = await dio.delete(
        '${myIpAddr()}/listpromo/deletepromokunjungan',
        data: {"kode_promo": kode_promo},
      );
    } catch (e) {
      if (e is DioException) {
        log("Error di fn Getdapaketmassage : ${e.response!.data}");
      }
    }
  }

  Future<void> getdatapromotahunan() async {
    try {
      var response = await dio.get('${myIpAddr()}/listpromo/getdatapromotahunan');
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "kode_promo": item['kode_promo'],
              "nama_promo": item['nama_promo'],
              "jangka_tahun": item['jangka_tahun'],
              "harga_promo": item['harga_promo'],
              "detail_kode_promo": item['detail_kode_promo'],
            };
          }).toList();
      setState(() {
        datapromotahunan.clear();
        datapromotahunan.assignAll(fetcheddata);
        datapromotahunan.refresh();
      });
    } catch (e) {
      log("Error di fn Getdapaketmassage : $e");
    }
  }

  Future<void> updatedatapromotahunan(kode_promo, detail_kode_promo) async {
    try {
      var response = await dio.put(
        '${myIpAddr()}/listpromo/updatepromotahunan',
        data: {
          "nama_promo": controller_edit_nama_promo_tahunan.text,
          "jangka_tahun": controller_edit_jangka_waktu_promo_tahunan.text,
          "harga_promo": controller_edit_harga_promo_tahunan.text,
          "kode_promo": kode_promo,
          "detail_kode_promo": detail_kode_promo,
        },
      );
    } catch (e) {
      log("Error di fn Getdapaketmassage : $e");
    }
  }

  Future<void> deletepromotahunan(kode_promo) async {
    try {
      var response = await dio.delete(
        '${myIpAddr()}/listpromo/deletepromotahunan',
        data: {"kode_promo": kode_promo},
      );
    } catch (e) {
      log("Error di fn deletepromotahunan : $e");
    }
  }

  Future<void> refreshDataHappyHour() async {
    await Future.delayed(Duration(seconds: 1));
    await getdatahappyhour();
  }

  Future<void> refreshDataPromoKunjungan() async {
    await Future.delayed(Duration(seconds: 1));
    await getdatapromokunjungan();
  }

  Future<void> refreshDataPromoTahunan() async {
    await Future.delayed(Duration(seconds: 1));
    await getdatapromotahunan();
  }

  Future<void> searchpromohappyhour() async {
    try {
      var response = await dio.get(
        '${myIpAddr()}/searchpromo/searchpromohappyhour',
        data: {"nama_promo": textinputan.text},
      );
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "kode_promo": item['kode_promo'],
              "nama_promo": item['nama_promo'],
              "disc": item['disc'],
              "valuesenin": item['senin'],
              "valueselasa": item['selasa'],
              "valuerabu": item['rabu'],
              "valuekamis": item['kamis'],
              "valuejumat": item['jumat'],
              "valuesabtu": item['sabtu'],
              "valueminggu": item['minggu'],
              "valuevip": item['vip'],
              "valuemember": item['member'],
              "jam_mulai": item['jam_mulai'],
              "jam_selesai": item['jam_selesai'],
              "detail_kode_promo": item['detail_kode_promo'],
            };
          }).toList();
      setState(() {
        datapromohappyhour.clear();
        datapromohappyhour.assignAll(fetcheddata);
        datapromohappyhour.refresh();
      });
    } catch (e) {
      log("Error di fn searchpromohappyhour : $e");
    }
  }

  Future<void> searchpromokunjungan() async {
    try {
      var response = await dio.get(
        '${myIpAddr()}/searchpromo/searchpromokunjungan',
        queryParameters: {"nama_promo": textinputan.text},
      );
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "kode_promo": item['kode_promo'],
              "nama_promo": item['nama_promo'],
              "limit_kunjungan": item['limit_kunjungan'],
              "harga_promo": item['harga_promo'],
              "harga_satuan": item['harga_paket_msg'],
              "detail_kode_promo": item['detail_kode_promo'],
              "limit_promo": item['limit_promo'],
              "durasi": item['durasi'],
              "discount": item['discount'],
            };
          }).toList();
      setState(() {
        datapromokunjungan.clear();
        datapromokunjungan.assignAll(fetcheddata);
        datapromokunjungan.refresh();
      });
    } catch (e) {
      log("Error di fn searchpromokunjungan : $e");
    }
  }

  Future<void> searchpromotahunan() async {
    try {
      var response = await dio.get(
        '${myIpAddr()}/searchpromo/searchpromotahunan',
        data: {"nama_promo": textinputan.text},
      );
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "kode_promo": item['kode_promo'],
              "nama_promo": item['nama_promo'],
              "jangka_tahun": item['jangka_tahun'],
              "harga_promo": item['harga_promo'],
              "detail_kode_promo": item['detail_kode_promo'],
            };
          }).toList();
      setState(() {
        datapromotahunan.clear();
        datapromotahunan.assignAll(fetcheddata);
        datapromotahunan.refresh();
      });
    } catch (e) {
      log("Error di fn searchpromotahunan : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: Container(
        //   width: 30,
        //   height: 30,
        //   child: ClipOval(child: Image.asset('assets/spa.jpeg')),
        // ),
        elevation: 0,
        scrolledUnderElevation: 0,
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
              Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text(
                  'List Promo',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 30, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                margin: EdgeInsets.only(right: 70),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 250,
                      height: 40,
                      child: TextField(
                        controller: textinputan,
                        onChanged: (String query) {
                          if (debounce?.isActive ?? false) {
                            debounce!.cancel();
                          }
                          debounce = Timer(Duration(milliseconds: 1000), () {
                            selectSearchPromo();
                          });
                        },
                        decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'Input Promo'),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: ElevatedButton(
                      onPressed: () {
                        if (textSearchHappyHour.text == "") {
                          refreshDataHappyHour();
                        }
                        selectInputPromo();
                        _moveFirstContainerToTop();
                        _toggleButtonColors(isFirstButtonPressed: true, isThirdButtonPressed: false);
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: _FirstbuttonColor == Colors.blue ? Colors.white : Colors.black,
                        backgroundColor: _FirstbuttonColor,
                        minimumSize: Size(150, 45),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      child: Text('Promo Happy Hour', style: TextStyle(color: Colors.black)),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 20, left: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        if (textsearchkunjungan.text == "") {
                          refreshDataPromoKunjungan();
                        }
                        selectInputPromo();
                        _moveSecondContainerToTop();
                        _toggleButtonColors(isFirstButtonPressed: false, isThirdButtonPressed: false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _SecondbuttonColor,
                        foregroundColor: _FirstbuttonColor == Colors.blue ? Colors.white : Colors.black,
                        minimumSize: Size(150, 45),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      child: Text('Promo Paketan', style: TextStyle(color: Colors.black)),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 20, left: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        if (textsearchtahunan.text == "") {
                          refreshDataPromoTahunan();
                        }
                        selectInputPromo();
                        _moveThirdContainerToTop();
                        _toggleButtonColors(isFirstButtonPressed: false, isThirdButtonPressed: true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _ThirdbuttonColor,
                        foregroundColor: _FirstbuttonColor == Colors.blue ? Colors.white : Colors.black,
                        minimumSize: Size(150, 45),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      child: Text('Promo Tahunan', style: TextStyle(color: Colors.black)),
                    ),
                  ),
                ],
              ),
              Stack(
                children: [
                  if (!_isSecondContainerOnTop)
                    Container(
                      width: 700,
                      height: 400,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        color: Colors.white,
                      ),
                      child:
                          datapromohappyhour.isEmpty
                              ? Center(child: Text('Data Promo Happy Hour Tidak Ada'))
                              : Obx(
                                () => ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: datapromohappyhour.length,
                                  itemBuilder: (context, index) {
                                    var item = datapromohappyhour[index];
                                    return Container(
                                      margin: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        border: Border.all(width: 1),
                                        borderRadius: BorderRadius.all(Radius.circular(10)),
                                      ),
                                      child: Container(
                                        width: 400,
                                        height: 185,
                                        padding: EdgeInsets.only(left: 10),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  child: Text(
                                                    item['kode_promo'],
                                                    style: TextStyle(fontSize: 20, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                Container(
                                                  child: Text(
                                                    item['nama_promo'],
                                                    style: TextStyle(fontSize: 20, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Container(
                                                  child: Text(
                                                    'Diskon :',
                                                    style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                Container(
                                                  child: Text(
                                                    item['disc'].toString(),
                                                    style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                                SizedBox(width: 4),
                                                Container(
                                                  child: Text(
                                                    '%',
                                                    style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Container(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                'Hari Berlaku :',
                                                style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Center(
                                                  child: Checkbox(
                                                    value: item['valuesenin'] == 1,
                                                    onChanged: (bool? value) {},
                                                  ),
                                                ),
                                                Text(
                                                  'Senin',
                                                  style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 5),
                                                  child: Center(
                                                    child: Checkbox(
                                                      value: item['valueselasa'] == 1,
                                                      onChanged: (bool? value) {
                                                        setState(() {});
                                                      },
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  'Selasa',
                                                  style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                                ),
                                                Center(
                                                  child: Checkbox(
                                                    value: item['valuerabu'] == 1,
                                                    onChanged: (bool? value) {},
                                                  ),
                                                ),
                                                Text(
                                                  'Rabu',
                                                  style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                                ),
                                                Center(
                                                  child: Checkbox(
                                                    value: item['valuekamis'] == 1,
                                                    onChanged: (bool? value) {},
                                                  ),
                                                ),
                                                Text(
                                                  'Kamis',
                                                  style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                                ),
                                                Center(
                                                  child: Checkbox(
                                                    value: item['valuejumat'] == 1,
                                                    onChanged: (bool? value) {},
                                                  ),
                                                ),
                                                Text(
                                                  'Jumat',
                                                  style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                                ),
                                                Center(
                                                  child: Checkbox(
                                                    value: item['valuesabtu'] == 1,
                                                    onChanged: (bool? value) {},
                                                  ),
                                                ),
                                                Text(
                                                  'Sabtu',
                                                  style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                                ),
                                                Center(
                                                  child: Checkbox(
                                                    value: item['valueminggu'] == 1,
                                                    onChanged: (bool? value) {},
                                                  ),
                                                ),
                                                Text(
                                                  'Minggu',
                                                  style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                                ),
                                              ],
                                            ),

                                            Row(
                                              children: [
                                                Container(
                                                  child: Text(
                                                    'Jam Berlaku : ',
                                                    style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                                Container(
                                                  child: Text(
                                                    item['jam_mulai'].toString(),
                                                    style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                                Container(
                                                  child: Text(
                                                    ' - ',
                                                    style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                                Container(
                                                  child: Text(
                                                    item['jam_selesai'].toString(),
                                                    style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Container(
                                                  child: Text(
                                                    'Berlaku Untuk : ',
                                                    style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                                Center(
                                                  child: Checkbox(
                                                    value: item['valueumum'] == 1,
                                                    onChanged: (bool? value) {},
                                                  ),
                                                ),
                                                Text(
                                                  'Umum',
                                                  style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 10),
                                                  child: Checkbox(
                                                    value: item['valuemember'] == 1,
                                                    onChanged: (bool? value) {},
                                                  ),
                                                ),
                                                Text(
                                                  'Member',
                                                  style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 10),
                                                  child: Center(
                                                    child: Checkbox(
                                                      value: item['valuevip'] == 1,
                                                      onChanged: (bool? value) {},
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  'VIP',
                                                  style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                                ),
                                                Spacer(),

                                                SizedBox(width: 10),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    isSeninChecked = item['valuesenin'] == 1;
                                                    isSelasaChecked = item['valueselasa'] == 1;
                                                    isRabuChecked = item['valuerabu'] == 1;
                                                    isKamisChecked = item['valuekamis'] == 1;
                                                    isJumatChecked = item['valuejumat'] == 1;
                                                    isSabtuChecked = item['valuesabtu'] == 1;
                                                    isMingguChecked = item['valueminggu'] == 1;
                                                    isUmumChecked = item['valueumum'] == 1;
                                                    isVIPChecked = item['valuevip'] == 1;
                                                    isMemberChecked = item['valuemember'] == 1;
                                                    valuesenin = isSeninChecked ? 1 : 0;
                                                    valueselasa = isSelasaChecked ? 1 : 0;
                                                    valuerabu = isRabuChecked ? 1 : 0;
                                                    valuekamis = isKamisChecked ? 1 : 0;
                                                    valuejumat = isJumatChecked ? 1 : 0;
                                                    valuesabtu = isSabtuChecked ? 1 : 0;
                                                    valueminggu = isMingguChecked ? 1 : 0;
                                                    valueumum = isUmumChecked ? 1 : 0;
                                                    valuevip = isVIPChecked ? 1 : 0;
                                                    valuemember = isMemberChecked ? 1 : 0;

                                                    controller_edit_nama_promo_happyhour.text =
                                                        item['nama_promo'];
                                                    controller_edit_disc_happyhour.text =
                                                        item['disc'].toString();
                                                    controller_edit_jam_mulai_happyhour.text =
                                                        item['jam_mulai'].toString().split(':')[0];
                                                    controller_edit_menit_mulai_happyhour.text =
                                                        item['jam_mulai'].toString().split(':')[1];
                                                    controller_edit_jam_selesai_happyhour.text =
                                                        item['jam_selesai'].toString().split(':')[0];
                                                    controller_edit_menit_selesai_happyhour.text =
                                                        item['jam_selesai'].toString().split(':')[1];
                                                    isibuttonedithappyhour(
                                                      item['kode_promo'],
                                                      item['detail_kode_promo'],
                                                    );
                                                  },
                                                  child: Text(
                                                    'Edit',
                                                    style: TextStyle(fontSize: 20, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    Get.dialog(
                                                      StatefulBuilder(
                                                        builder: (context, setState) {
                                                          return AlertDialog(
                                                            actions: [
                                                              Center(
                                                                child: Container(
                                                                  margin: EdgeInsets.only(top: 20),
                                                                  height: 100,
                                                                  width: 250,
                                                                  child: Center(
                                                                    child: Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment.center,
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment.center,
                                                                      children: [
                                                                        Text(
                                                                          '${item['nama_promo']}',
                                                                          style: TextStyle(
                                                                            fontSize: 16,
                                                                            fontFamily: 'Poppins',
                                                                          ),
                                                                        ),
                                                                        Text(
                                                                          'Yakin ingin delete ?',
                                                                          style: TextStyle(
                                                                            fontSize: 16,
                                                                            fontFamily: 'Poppins',
                                                                          ),
                                                                        ),

                                                                        SizedBox(height: 4),
                                                                        Row(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.center,
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.center,
                                                                          children: [
                                                                            ElevatedButton(
                                                                              onPressed: () {
                                                                                deletepromohappyhour(
                                                                                  item['kode_promo'],
                                                                                );
                                                                                refreshDataHappyHour();
                                                                                Get.back();
                                                                                CherryToast.success(
                                                                                  title: Text(
                                                                                    'Data Berhasil DiHapus',
                                                                                  ),
                                                                                ).show(context);
                                                                              },
                                                                              child: Text('Yes'),
                                                                            ),
                                                                            SizedBox(width: 20),
                                                                            ElevatedButton(
                                                                              onPressed: () {
                                                                                Get.back();
                                                                              },
                                                                              child: Text('No'),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      ),
                                                    );
                                                  },
                                                  child: Text(
                                                    'Delete',
                                                    style: TextStyle(fontSize: 20, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                    ),
                  if (_isSecondContainerOnTop)
                    Container(
                      width: 700,
                      height: 400,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        color: Colors.white,
                      ),
                      child:
                          datapromokunjungan.isEmpty
                              ? Center(child: Text('Data Promo Paketan Tidak Ada'))
                              : Obx(
                                () => ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: datapromokunjungan.length,
                                  itemBuilder: (context, index) {
                                    var item = datapromokunjungan[index];
                                    return Container(
                                      margin: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        border: Border.all(width: 1),
                                        borderRadius: BorderRadius.all(Radius.circular(10)),
                                      ),
                                      child: Container(
                                        width: 400,
                                        padding: EdgeInsets.only(left: 10),
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  child: Text(
                                                    item['kode_promo'],
                                                    style: TextStyle(fontSize: 25, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                Container(
                                                  child: Text(
                                                    item['nama_promo'],
                                                    style: TextStyle(fontSize: 25, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Container(
                                                  child: Text(
                                                    'Limit Kunjungan : ',
                                                    style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                                Container(
                                                  child: Text(
                                                    item['limit_kunjungan'].toString(),
                                                    style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 10),
                                            Row(
                                              children: [
                                                Container(
                                                  child: Text(
                                                    'Limit Promo : ',
                                                    style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                                Container(
                                                  child: Text(
                                                    item['limit_promo'].toString(),
                                                    style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                                Container(
                                                  child: Text(
                                                    ' Tahun',
                                                    style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 10),
                                            Row(
                                              children: [
                                                Container(
                                                  child: Text(
                                                    'Durasi Paket : ',
                                                    style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                                Container(
                                                  child: Text(
                                                    item['durasi'].toString(),
                                                    style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                                Container(
                                                  child: Text(
                                                    ' Menit',
                                                    style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Container(
                                                  child: Text(
                                                    'Diskon : ',
                                                    style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                                Container(
                                                  child: Text(
                                                    item['discount'].toString(),
                                                    style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                                Container(
                                                  child: Text(
                                                    '%',
                                                    style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                                Spacer(),
                                                Container(
                                                  child: Text(
                                                    currencyFormat.format(item['harga_promo']).toString(),
                                                    style: TextStyle(fontSize: 22, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    controller_edit_kode_promo_kunjungan.text =
                                                        item['kode_promo'];
                                                    controller_edit_nama_promo_kunjungan.text =
                                                        item['nama_promo'];
                                                    controller_edit_limit_promo_kunjungan.text =
                                                        item['limit_kunjungan'].toString();
                                                    controller_edit_limit_promo.text =
                                                        item['limit_promo'].toString();
                                                    hargaPromo.value =
                                                        (item['harga_promo'] as num).toDouble();
                                                    hargaSatuan.value =
                                                        (item['harga_satuan'] as num).toDouble();

                                                    controller_edit_diskon_paket.text =
                                                        item['discount'].toString();

                                                    isibuttoneditpromokunjungan(
                                                      item['kode_promo'],
                                                      item['detail_kode_promo'],
                                                    );
                                                  },
                                                  child: Text(
                                                    'Edit',
                                                    style: TextStyle(fontSize: 25, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    Get.dialog(
                                                      StatefulBuilder(
                                                        builder: (context, setState) {
                                                          return AlertDialog(
                                                            actions: [
                                                              Center(
                                                                child: Container(
                                                                  margin: EdgeInsets.only(top: 20),
                                                                  height: 100,
                                                                  width: 250,
                                                                  child: Center(
                                                                    child: Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment.center,
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment.center,
                                                                      children: [
                                                                        Text(
                                                                          '${item['nama_promo']}',
                                                                          style: TextStyle(
                                                                            fontSize: 16,
                                                                            fontFamily: 'Poppins',
                                                                          ),
                                                                        ),
                                                                        Text(
                                                                          'Yakin ingin delete ?',
                                                                          style: TextStyle(
                                                                            fontSize: 16,
                                                                            fontFamily: 'Poppins',
                                                                          ),
                                                                        ),

                                                                        SizedBox(height: 4),
                                                                        Row(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.center,
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.center,
                                                                          children: [
                                                                            ElevatedButton(
                                                                              onPressed: () {
                                                                                deletepromokunjungan(
                                                                                  item['kode_promo'],
                                                                                );
                                                                                refreshDataPromoKunjungan();
                                                                                Get.back();
                                                                                CherryToast.success(
                                                                                  title: Text(
                                                                                    'Data Berhasil DiHapus',
                                                                                  ),
                                                                                ).show(context);
                                                                              },
                                                                              child: Text('Yes'),
                                                                            ),
                                                                            SizedBox(width: 20),
                                                                            ElevatedButton(
                                                                              onPressed: () {
                                                                                Get.back();
                                                                              },
                                                                              child: Text('No'),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      ),
                                                    );
                                                  },
                                                  child: Text(
                                                    'Delete',
                                                    style: TextStyle(fontSize: 25, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                    ),
                  if (_isThirdContainerOntop)
                    Container(
                      width: 700,
                      height: 400,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        color: Colors.white,
                      ),
                      child:
                          datapromotahunan.isEmpty
                              ? Center(child: Text('Data Promo Tahunan Tidak Ada'))
                              : Obx(
                                () => ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: datapromotahunan.length,
                                  itemBuilder: (context, index) {
                                    var item = datapromotahunan[index];
                                    return Container(
                                      margin: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        border: Border.all(width: 1),
                                        borderRadius: BorderRadius.all(Radius.circular(10)),
                                      ),
                                      child: Container(
                                        width: 400,
                                        padding: EdgeInsets.only(left: 10),
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  child: Text(
                                                    item['kode_promo'],
                                                    style: TextStyle(fontSize: 25, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                Container(
                                                  child: Text(
                                                    item['nama_promo'],
                                                    style: TextStyle(fontSize: 25, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Container(
                                                  child: Text(
                                                    'Jangka Waktu : ',
                                                    style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                                Container(
                                                  child: Text(
                                                    item['jangka_tahun'].toString(),
                                                    style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                                Container(
                                                  child: Text(
                                                    ' Tahun',
                                                    style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                Spacer(),
                                                Container(
                                                  child: Text(
                                                    currencyFormat.format(item['harga_promo']).toString(),
                                                    style: TextStyle(fontSize: 25, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    controller_edit_nama_promo_tahunan.text =
                                                        item['nama_promo'];
                                                    controller_edit_jangka_waktu_promo_tahunan.text =
                                                        item['jangka_tahun'].toString();
                                                    controller_edit_harga_promo_tahunan.text =
                                                        item['harga_promo'].toString();
                                                    isibuttoneditpromotahunan(
                                                      item['kode_promo'],
                                                      item['detail_kode_promo'],
                                                    );
                                                  },
                                                  child: Text(
                                                    'Edit',
                                                    style: TextStyle(fontSize: 25, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    Get.dialog(
                                                      StatefulBuilder(
                                                        builder: (context, setState) {
                                                          return AlertDialog(
                                                            actions: [
                                                              Center(
                                                                child: Container(
                                                                  margin: EdgeInsets.only(top: 20),
                                                                  height: 100,
                                                                  width: 250,
                                                                  child: Center(
                                                                    child: Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment.center,
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment.center,
                                                                      children: [
                                                                        Text(
                                                                          '${item['nama_promo']}',
                                                                          style: TextStyle(
                                                                            fontSize: 16,
                                                                            fontFamily: 'Poppins',
                                                                          ),
                                                                        ),
                                                                        Text(
                                                                          'Yakin ingin delete ?',
                                                                          style: TextStyle(
                                                                            fontSize: 16,
                                                                            fontFamily: 'Poppins',
                                                                          ),
                                                                        ),

                                                                        SizedBox(height: 4),
                                                                        Row(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.center,
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.center,
                                                                          children: [
                                                                            ElevatedButton(
                                                                              onPressed: () {
                                                                                deletepromotahunan(
                                                                                  item['kode_promo'],
                                                                                );
                                                                                refreshDataPromoTahunan();
                                                                                Get.back();
                                                                                CherryToast.success(
                                                                                  title: Text(
                                                                                    'Data Berhasil DiHapus',
                                                                                  ),
                                                                                ).show(context);
                                                                              },
                                                                              child: Text('Yes'),
                                                                            ),
                                                                            SizedBox(width: 20),
                                                                            ElevatedButton(
                                                                              onPressed: () {
                                                                                Get.back();
                                                                              },
                                                                              child: Text('No'),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      ),
                                                    );
                                                  },
                                                  child: Text(
                                                    'Delete',
                                                    style: TextStyle(fontSize: 25, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
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
