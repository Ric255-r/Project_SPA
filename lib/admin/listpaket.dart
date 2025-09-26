import 'dart:async';
import 'dart:developer';
import 'package:Project_SPA/admin/laporan_ob.dart';
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
import 'package:Project_SPA/function/our_drawer.dart';
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

class Listpaket extends StatefulWidget {
  const Listpaket({super.key});

  @override
  State<Listpaket> createState() => _ListpaketState();
}

class _ListpaketState extends State<Listpaket> {
  List<String> listproduk = <String>['Pewangi', 'Pembersih'];
  List<String> listFnB = <String>['Food', 'Beverage'];

  String? selectedKategoriIdFnb;

  TextEditingController textinputan = TextEditingController();
  TextEditingController textSearchMassage = TextEditingController();
  TextEditingController textSearchFnb = TextEditingController();
  TextEditingController textSearchProduk = TextEditingController();
  TextEditingController textSearchFasilitas = TextEditingController();

  TextEditingController controller_edit_nama_massage = TextEditingController();
  TextEditingController controller_edit_harga_massage = TextEditingController();
  TextEditingController controller_edit_detail_paket = TextEditingController();
  TextEditingController controller_nominal_komisi_terapis =
      TextEditingController();
  TextEditingController controller_nominal_komisi_gro = TextEditingController();
  TextEditingController controller_edit_durasi = TextEditingController();

  TextEditingController controller_edit_nama_fnb = TextEditingController();
  TextEditingController controller_edit_harga_fnb = TextEditingController();
  TextEditingController controller_edit_stok_fnb = TextEditingController();

  TextEditingController controller_edit_nama_produk = TextEditingController();
  TextEditingController controller_edit_durasi_produk = TextEditingController();
  TextEditingController controller_edit_harga_produk = TextEditingController();
  TextEditingController controller_edit_stok_produk = TextEditingController();
  TextEditingController controller_edit_nominal_komisi_produk =
      TextEditingController();
  TextEditingController controller_edit_nominal_komisi_produk_gro =
      TextEditingController();

  TextEditingController controller_edit_nama_fasilitas =
      TextEditingController();
  TextEditingController controller_edit_harga_fasilitas =
      TextEditingController();

  bool _isSecondContainerOnTop = false;

  bool _isThirdContainerOntop = false;

  bool _isFourthContainerOnTop = false;

  Color _FirstbuttonColor = Colors.blue;

  Color _SecondbuttonColor = Colors.white;

  Color _ThirdbuttonColor = Colors.white;

  Color _FourthbuttonColor = Colors.white;

  int? _selectedRadio;
  int? _selectedRadioGro;

  int? _selectedRadioKomisiProduk;
  int? _selectedRadioKomisiProdukGro;

  int? valueradio;

  int? valueRadioKomisiProduk;
  int? valueRadioKomisiProdukGro;

  String? isistatus;

  int? valuestatus;

  Timer? debounce;

  bool changekategori = false;

  List<RxString> dropdownpenerimakomisi = ['Terapis'.obs, 'Gro'.obs];
  RxString? selecteditem = ''.obs;
  RxString cekpenerima = ''.obs;

  NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp. ',
    decimalDigits: 0,
  );

  int isready = 0;

  var dio = Dio();

  RxList<Map<String, dynamic>> datapaketmassage = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> datafnb = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> dataproduk = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> datafasilitas = <Map<String, dynamic>>[].obs;
  List<Map<String, dynamic>> datakategorifnb = [];
  List<String> extractDataFnb = [];

  @override
  void dispose() {
    // TODO: implement dispose
    // textinputan.dispose();
    // textSearchMassage.dispose();
    // textSearchFnb.dispose();
    // textSearchProduk.dispose();
    // textSearchFasilitas.dispose();
    controller_edit_nama_massage.dispose();
    controller_edit_harga_massage.dispose();
    controller_nominal_komisi_terapis.dispose();
    controller_nominal_komisi_gro.dispose();
    controller_edit_durasi.dispose();
    controller_edit_nama_fnb.dispose();
    controller_edit_harga_fnb.dispose();
    controller_edit_nama_produk.dispose();
    controller_edit_durasi_produk.dispose();
    controller_edit_harga_produk.dispose();
    controller_edit_nominal_komisi_produk.dispose();
    controller_edit_nama_fasilitas.dispose();
    controller_edit_harga_fasilitas.dispose();
    debounce?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    refreshData();
    refreshDataProduk();
    refreshDatafnb();
    refreshDataFasilitas();
    getkategorifnb();
    getdataagency();
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
    _isSecondContainerOnTop = false;
    _isThirdContainerOntop = false;
    _isFourthContainerOnTop = true;
  }

  void _toggleButtonColors({
    required bool isFirstButtonPressed,
    isThirdButtonPressed,
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
      } else if (isFourthButtonPressed) {
        _FirstbuttonColor = Colors.white;
        _SecondbuttonColor = Colors.white;
        _ThirdbuttonColor = Colors.white;
        _FourthbuttonColor = Colors.blue;
      } else {
        _FirstbuttonColor = Colors.white;
        _SecondbuttonColor = Colors.blue;
        _ThirdbuttonColor = Colors.white;
        _FourthbuttonColor = Colors.white;
      }
    });
  }

  void selectInputPaket() {
    if (_isSecondContainerOnTop == false &&
        _isThirdContainerOntop == false &&
        _isFourthContainerOnTop == false) {
      textSearchProduk.clear();
      textSearchFnb.clear();
      textSearchFasilitas.clear();
      textinputan = textSearchMassage;
    } else if (_isSecondContainerOnTop == true &&
        _isThirdContainerOntop == false &&
        _isFourthContainerOnTop == false) {
      textSearchMassage.clear();
      textSearchProduk.clear();
      textSearchFasilitas.clear();
      textinputan = textSearchFnb;
    } else if (_isSecondContainerOnTop == false &&
        _isThirdContainerOntop == true &&
        _isFourthContainerOnTop == false) {
      textSearchMassage.clear();
      textSearchFnb.clear();
      textSearchFasilitas.clear();
      textinputan = textSearchProduk;
    } else if (_isSecondContainerOnTop == false &&
        _isThirdContainerOntop == false &&
        _isFourthContainerOnTop == true) {
      textSearchMassage.clear();
      textSearchFnb.clear();
      textSearchProduk.clear();
      textinputan = textSearchFasilitas;
    }
  }

  void selectsearchpaket() {
    if (_isSecondContainerOnTop == false &&
        _isThirdContainerOntop == false &&
        _isFourthContainerOnTop == false) {
      if (selectedagency == null || selectedagency == "No Agency") {
        searchdatamassage();
      } else {
        searchdatamassageagency(selectedagency);
      }
    } else if (_isSecondContainerOnTop == true &&
        _isThirdContainerOntop == false &&
        _isFourthContainerOnTop == false) {
      searchdatafnb();
    } else if (_isSecondContainerOnTop == false &&
        _isThirdContainerOntop == true &&
        _isFourthContainerOnTop == false) {
      if (selectedagency == null || selectedagency == "No Agency") {
        searchdataproduk();
      } else {
        searchdataprodukagency(selectedagency);
      }
    } else if (_isSecondContainerOnTop == false &&
        _isThirdContainerOntop == false &&
        _isFourthContainerOnTop == true) {
      searchdatafasilitas();
    }
  }

  void isibuttoneditproduk(id_produk) {
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Container(
                width: Get.width - 330,
                height: Get.height - 250,
                child: ListView(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.zero,
                          child: Container(
                            margin: EdgeInsets.only(top: 40),
                            height: 400,
                            width: 200,
                            child: Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
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
                          padding: const EdgeInsets.only(top: 40),
                          child: Container(
                            height: 400,
                            width: 500,
                            child: Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 12),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    width: 480,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey[300],
                                    ),
                                    child: TextField(
                                      controller: controller_edit_nama_produk,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
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
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey[300],
                                    ),
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      controller: controller_edit_harga_produk,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
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
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          color: Colors.grey[300],
                                        ),
                                        child: TextField(
                                          keyboardType: TextInputType.number,
                                          inputFormatters: <TextInputFormatter>[
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          controller:
                                              controller_edit_durasi_produk,
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
                                  selectedagency == 'No Agency'
                                      ? Obx(
                                        () => Container(
                                          width: 120,
                                          height: 30,
                                          padding: EdgeInsets.only(left: 10),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
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
                                      )
                                      : Text(
                                        'Terapis',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontFamily: 'Poppins',
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
                                                      _selectedRadioKomisiProduk,
                                                  onChanged: (int? value) {
                                                    setState(() {
                                                      _selectedRadioKomisiProduk =
                                                          value;
                                                      if (_selectedRadioKomisiProduk ==
                                                          1) {
                                                        valueRadioKomisiProduk =
                                                            1;
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
                                                    value: 0,
                                                    groupValue:
                                                        _selectedRadioKomisiProduk,
                                                    onChanged: (int? value) {
                                                      setState(() {
                                                        _selectedRadioKomisiProduk =
                                                            value;
                                                        if (_selectedRadioKomisiProduk ==
                                                            0) {
                                                          valueRadioKomisiProduk =
                                                              0;
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
                                                      _selectedRadioKomisiProdukGro,
                                                  onChanged: (int? value) {
                                                    setState(() {
                                                      _selectedRadioKomisiProdukGro =
                                                          value;
                                                      if (_selectedRadioKomisiProdukGro ==
                                                          1) {
                                                        valueRadioKomisiProdukGro =
                                                            1;
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
                                                    value: 0,
                                                    groupValue:
                                                        _selectedRadioKomisiProdukGro,
                                                    onChanged: (int? value) {
                                                      setState(() {
                                                        _selectedRadioKomisiProdukGro =
                                                            value;
                                                        if (_selectedRadioKomisiProdukGro ==
                                                            0) {
                                                          valueRadioKomisiProdukGro =
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
                                                      _selectedRadioKomisiProduk ==
                                                      1,
                                                  child: Container(
                                                    alignment:
                                                        Alignment.centerLeft,
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
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            inputFormatters: <
                                                              TextInputFormatter
                                                            >[
                                                              FilteringTextInputFormatter
                                                                  .digitsOnly,
                                                            ],
                                                            controller:
                                                                controller_edit_nominal_komisi_produk,
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
                                                              fontSize: 16,
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
                                                      _selectedRadioKomisiProduk ==
                                                      0,
                                                  child: Container(
                                                    alignment:
                                                        Alignment.centerLeft,
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
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            inputFormatters: <
                                                              TextInputFormatter
                                                            >[
                                                              FilteringTextInputFormatter
                                                                  .digitsOnly,
                                                            ],
                                                            controller:
                                                                controller_edit_nominal_komisi_produk,
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
                                                              fontSize: 16,
                                                              fontFamily:
                                                                  'Poppins',
                                                            ),
                                                          ),
                                                        ),
                                                        Text(
                                                          '%',
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
                                                      _selectedRadioKomisiProdukGro ==
                                                      1,
                                                  child: Container(
                                                    alignment:
                                                        Alignment.centerLeft,
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
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            inputFormatters: <
                                                              TextInputFormatter
                                                            >[
                                                              FilteringTextInputFormatter
                                                                  .digitsOnly,
                                                            ],
                                                            controller:
                                                                controller_edit_nominal_komisi_produk_gro,
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
                                                              fontSize: 16,
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
                                                      _selectedRadioKomisiProdukGro ==
                                                      0,
                                                  child: Container(
                                                    alignment:
                                                        Alignment.centerLeft,
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
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            inputFormatters: <
                                                              TextInputFormatter
                                                            >[
                                                              FilteringTextInputFormatter
                                                                  .digitsOnly,
                                                            ],
                                                            controller:
                                                                controller_edit_nominal_komisi_produk_gro,
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
                                                              fontSize: 16,
                                                              fontFamily:
                                                                  'Poppins',
                                                            ),
                                                          ),
                                                        ),
                                                        Text(
                                                          '%',
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
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey[300],
                                    ),
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      controller: controller_edit_stok_produk,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
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
                                  SizedBox(height: 20),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 120),
                                    child: SizedBox(
                                      height: 35,
                                      width: 100,
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.green,
                                        ),
                                        onPressed: () {
                                          if (selectedagency == null ||
                                              selectedagency == 'No Agency') {
                                            updatedataproduk(id_produk);
                                          } else {
                                            updatekomisiprodukagency(
                                              id_produk,
                                              selectedagency,
                                            );
                                          }
                                          dataproduk.isEmpty
                                              ? Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              )
                                              : refreshDataProduk();
                                          Get.back();
                                          CherryToast.success(
                                            title: Text(
                                              'Data Berhasil Diupdate',
                                            ),
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

  void isibuttoneditfnb(id_fnb, idkategori) {
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Container(
                width: Get.width - 350,
                height: Get.height - 350,
                child: ListView(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.zero,
                          child: Container(
                            margin: EdgeInsets.only(top: 50),
                            height: 230,
                            width: 200,

                            child: Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
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
                            margin: EdgeInsets.only(top: 50),
                            height: 230,
                            width: 500,
                            child: Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 12),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    width: 480,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey[300],
                                    ),
                                    child: TextField(
                                      controller: controller_edit_nama_fnb,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
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
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey[300],
                                    ),
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      controller: controller_edit_harga_fnb,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
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
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey[300],
                                    ),
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      controller: controller_edit_stok_fnb,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
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
                                        width: 250,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          color: Colors.grey[300],
                                        ),
                                        child: DropdownButton<String>(
                                          value:
                                              selectedKategoriIdFnb ??
                                              datakategorifnb
                                                  .first['id_kategori'],
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
                                              changekategori = true;
                                              selectedKategoriIdFnb = value;
                                            });
                                          },
                                          items:
                                              datakategorifnb.map<
                                                DropdownMenuItem<String>
                                              >((item) {
                                                return DropdownMenuItem<String>(
                                                  value: item['id_kategori'],
                                                  child: Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Text(
                                                      item['nama_kategori']
                                                          .toString(),
                                                      style: TextStyle(
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
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 120,
                                      top: 20,
                                    ),
                                    child: SizedBox(
                                      height: 35,
                                      width: 100,
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.green,
                                        ),
                                        onPressed: () {
                                          log(selectedKategoriIdFnb.toString());
                                          log('ini loh : $idkategori');
                                          if (changekategori == false) {
                                            selectedKategoriIdFnb = idkategori;
                                          }
                                          changekategori = false;
                                          updatedatafnb(id_fnb);
                                          refreshDatafnb();
                                          Get.back();
                                          CherryToast.success(
                                            title: Text(
                                              'Data Berhasil DiUpdate',
                                            ),
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

  void isibuttoneditpaket(id_paket_msg) {
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            scrollable: true,
            content: SingleChildScrollView(
              child: Container(
                width: Get.width - 300,
                height: Get.height - 250,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.zero,
                          child: Container(
                            margin: EdgeInsets.only(top: 40),
                            height: 290,
                            width: 200,
                            child: Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
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
                                  SizedBox(height: 15),
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
                          padding: const EdgeInsets.only(top: 40),
                          child: Container(
                            height: 370,
                            width: 500,
                            child: Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 12),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    width: 480,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey[300],
                                    ),
                                    child: TextField(
                                      controller: controller_edit_nama_massage,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
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
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey[300],
                                    ),
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      controller: controller_edit_harga_massage,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
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
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          color: Colors.grey[300],
                                        ),
                                        child: TextField(
                                          keyboardType: TextInputType.number,
                                          inputFormatters: <TextInputFormatter>[
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          controller: controller_edit_durasi,
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
                                  id_paket_msg[0] == 'M' &&
                                          (selectedagency == 'No Agency' ||
                                              selectedagency == null)
                                      ? Obx(
                                        () => Container(
                                          width: 120,
                                          height: 30,
                                          padding: EdgeInsets.only(left: 10),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
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
                                      )
                                      : Container(
                                        width: 100,

                                        child: Text(
                                          'Terapis',
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 18,
                                            fontFamily: 'Poppins',
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
                                                  groupValue: _selectedRadio,
                                                  onChanged: (int? value) {
                                                    setState(() {
                                                      _selectedRadio = value;
                                                      if (_selectedRadio == 1) {
                                                        valueradio = 1;
                                                      }
                                                    });
                                                  },
                                                ),
                                                Text('Nominal'),
                                                id_paket_msg[0] == 'M'
                                                    ? Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            left: 20,
                                                          ),
                                                      child: Radio<int>(
                                                        value: 0,
                                                        groupValue:
                                                            _selectedRadio,
                                                        onChanged: (
                                                          int? value,
                                                        ) {
                                                          setState(() {
                                                            _selectedRadio =
                                                                value;
                                                            if (_selectedRadio ==
                                                                0) {
                                                              valueradio = 0;
                                                            }
                                                          });
                                                        },
                                                      ),
                                                    )
                                                    : SizedBox.shrink(),
                                                id_paket_msg[0] == 'M'
                                                    ? Text('Persenan')
                                                    : SizedBox.shrink(),
                                              ],
                                            )
                                            : Row(
                                              children: [
                                                Radio<int>(
                                                  value: 1,
                                                  groupValue: _selectedRadioGro,
                                                  onChanged: (int? value) {
                                                    setState(() {
                                                      _selectedRadioGro = value;
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
                                                    value: 0,
                                                    groupValue:
                                                        _selectedRadioGro,
                                                    onChanged: (int? value) {
                                                      setState(() {
                                                        _selectedRadioGro =
                                                            value;
                                                        if (_selectedRadioGro ==
                                                            0) {
                                                          valueradiogro = 0;
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
                                                  visible: _selectedRadio == 1,
                                                  child: Container(
                                                    alignment:
                                                        Alignment.centerLeft,
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
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            inputFormatters: <
                                                              TextInputFormatter
                                                            >[
                                                              FilteringTextInputFormatter
                                                                  .digitsOnly,
                                                            ],
                                                            controller:
                                                                controller_nominal_komisi_terapis,
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
                                                              fontSize: 16,
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
                                                  visible: _selectedRadio == 0,
                                                  child: Container(
                                                    alignment:
                                                        Alignment.centerLeft,
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
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            inputFormatters: <
                                                              TextInputFormatter
                                                            >[
                                                              FilteringTextInputFormatter
                                                                  .digitsOnly,
                                                            ],
                                                            controller:
                                                                controller_nominal_komisi_terapis,
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
                                                              fontSize: 16,
                                                              fontFamily:
                                                                  'Poppins',
                                                            ),
                                                          ),
                                                        ),
                                                        Text(
                                                          '%',
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
                                                      _selectedRadioGro == 1,
                                                  child: Container(
                                                    alignment:
                                                        Alignment.centerLeft,
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
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            inputFormatters: <
                                                              TextInputFormatter
                                                            >[
                                                              FilteringTextInputFormatter
                                                                  .digitsOnly,
                                                            ],
                                                            controller:
                                                                controller_nominal_komisi_gro,
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
                                                              fontSize: 16,
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
                                                      _selectedRadioGro == 0,
                                                  child: Container(
                                                    alignment:
                                                        Alignment.centerLeft,
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
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            inputFormatters: <
                                                              TextInputFormatter
                                                            >[
                                                              FilteringTextInputFormatter
                                                                  .digitsOnly,
                                                            ],
                                                            controller:
                                                                controller_nominal_komisi_gro,
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
                                                              fontSize: 16,
                                                              fontFamily:
                                                                  'Poppins',
                                                            ),
                                                          ),
                                                        ),
                                                        Text(
                                                          '%',
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
                                  id_paket_msg[0] == 'M'
                                      ? Container(
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
                                          controller:
                                              controller_edit_detail_paket,
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
                                      )
                                      : Padding(
                                        padding: EdgeInsets.only(top: 5),
                                        child: Text(
                                          '-',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                  SizedBox(height: 20),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 130),
                                    child: SizedBox(
                                      height: 35,
                                      width: 100,
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.green,
                                        ),
                                        onPressed: () {
                                          if (selectedagency == null ||
                                              selectedagency == 'No Agency') {
                                            updatedatapaketmassage(
                                              id_paket_msg,
                                            );
                                          } else {
                                            updatedatapaketmassageagency(
                                              id_paket_msg,
                                              selectedagency,
                                            );
                                          }
                                          datapaketmassage.isEmpty
                                              ? Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              )
                                              : refreshData();
                                          Get.back();
                                          CherryToast.success(
                                            title: Text(
                                              'Data Berhasil DiUpdate',
                                            ),
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

  void isibuttoneditfasilitas(id_fasilitas) {
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Container(
                width: Get.width - 350,
                height: Get.height - 350,
                child: ListView(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.zero,
                          child: Container(
                            margin: EdgeInsets.only(top: 80),
                            height: 180,
                            width: 200,

                            child: Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
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
                            margin: EdgeInsets.only(top: 80),
                            height: 180,
                            width: 500,
                            child: Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 12),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    width: 480,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey[300],
                                    ),
                                    child: TextField(
                                      controller:
                                          controller_edit_nama_fasilitas,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
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
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey[300],
                                    ),
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      controller:
                                          controller_edit_harga_fasilitas,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
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
                                  SizedBox(height: 20),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 120),
                                    child: SizedBox(
                                      height: 35,
                                      width: 100,
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.green,
                                        ),
                                        onPressed: () {
                                          updatedatafasilitas(id_fasilitas);
                                          datafasilitas.isEmpty
                                              ? Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              )
                                              : refreshDataFasilitas();
                                          Get.back();
                                          CherryToast.success(
                                            title: Text(
                                              'Data Berhasil DiUpdate',
                                            ),
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

  Future<void> getdatapaketmassage() async {
    try {
      var response = await dio.get(
        '${myIpAddr()}/listmassage/getdatapaketmassage',
      );
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "id_paket_msg": item['id_paket_msg'],
              "nama_paket_msg": item['nama_paket_msg'],
              "harga_paket_msg": item['harga_paket_msg'],
              "durasi": item['durasi'],
              "tipe_komisi": item['tipe_komisi'],
              "nominal_komisi": item['nominal_komisi'],
              "detail_paket": item['detail_paket'],
              "tipe_komisi_gro": item['tipe_komisi_gro'],
              "nominal_komisi_gro": item['nominal_komisi_gro'],
            };
          }).toList();
      setState(() {
        datapaketmassage.clear();
        datapaketmassage.assignAll(fetcheddata);
        datapaketmassage.refresh();
      });
    } catch (e) {
      log("Error di fn Getdatapaketmassage : $e");
    }
  }

  Future<void> getdatapaketmassageagency(namaagency) async {
    try {
      var response = await dio.get(
        '${myIpAddr()}/listmassage/getdatapaketmassageagency',
        data: {'nama_agency': namaagency},
      );
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "id_paket_msg": item['id_paket_msg'],
              "nama_paket_msg": item['nama_paket_msg'],
              "harga_paket_msg": item['harga_paket_msg'],
              "durasi": item['durasi'],
              "tipe_komisi": item['tipe_komisi'],
              "nominal_komisi": item['nominal_komisi'],
              "detail_paket": item['detail_paket'],
              "tipe_komisi_gro": item['tipe_komisi_gro'],
              "nominal_komisi_gro": item['nominal_komisi_gro'],
            };
          }).toList();
      setState(() {
        datapaketmassage.assignAll(fetcheddata);
      });
    } catch (e) {
      log("Error di fn Getdatapaketmassageagency : $e");
    }
  }

  Future<void> updatedatapaketmassage(id_paket_msg) async {
    try {
      log(valueradio.toString());
      var response = await dio.put(
        '${myIpAddr()}/listmassage/updatepaketmassage',
        data: {
          "nama_paket_msg": controller_edit_nama_massage.text,
          "harga_paket_msg": int.parse(controller_edit_harga_massage.text),
          "durasi": int.parse(controller_edit_durasi.text),
          "tipe_komisi": valueradio,
          "nominal_komisi": int.parse(controller_nominal_komisi_terapis.text),
          "tipe_komisi_gro": valueradiogro,
          "nominal_komisi_gro": int.parse(controller_nominal_komisi_gro.text),
          "id_paket_msg": id_paket_msg,
          "detail_paket": controller_edit_detail_paket.text,
        },
      );
    } catch (e) {
      log("Error di fn updatepaketmassage : $e");
    }
  }

  Future<void> updatedatapaketmassageagency(id_paket_msg, namaagency) async {
    try {
      log(valueradio.toString());
      var response = await dio.put(
        '${myIpAddr()}/listmassage/updatekomisiagency',
        data: {
          "nama_paket_msg": controller_edit_nama_massage.text,
          "harga_paket_msg": int.parse(controller_edit_harga_massage.text),
          "durasi": int.parse(controller_edit_durasi.text),
          "tipe_komisi": valueradio,
          "nominal_komisi": int.parse(controller_nominal_komisi_terapis.text),
          "tipe_komisi_gro": valueradiogro,
          "nominal_komisi_gro": int.parse(controller_nominal_komisi_gro.text),
          "id_paket_msg": id_paket_msg,
          "detail_paket": controller_edit_detail_paket.text,
          "nama_agency": namaagency,
        },
      );
    } catch (e) {
      log("Error di fn updatepaketmassage : $e");
    }
  }

  Future<void> deletedatapaketmassage(id_paket_msg) async {
    try {
      var response = await dio.delete(
        '${myIpAddr()}/listmassage/deletepaketmassage',
        data: {"id_paket_msg": id_paket_msg},
      );
    } catch (e) {
      log("Error di fn Getdapaketmassage : $e");
    }
  }

  Future<void> refreshData() async {
    await Future.delayed(Duration(seconds: 1));

    if (selectedagency == 'No Agency' || selectedagency == null) {
      await getdatapaketmassage();
    } else {
      await getdatapaketmassageagency(selectedagency);
    }
  }

  Future<void> getdatafnb() async {
    try {
      var response = await dio.get('${myIpAddr()}/listfnb/getdatafnb');
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "id_fnb": item['id_fnb'],
              "id_kategori": item['id_kategori'],
              "nama_fnb": item['nama_fnb'],
              "harga_fnb": item['harga_fnb'],
              "stok_fnb": item['stok_fnb'],
              "status_fnb": item['status_fnb'],
              "nama_kategori": item['nama_kategori'],
            };
          }).toList();
      setState(() {
        datafnb.clear();
        datafnb.assignAll(fetcheddata);
        datafnb.refresh();
      });
    } catch (e) {
      log("Error di fn getdatafnb : $e");
    }
  }

  Future<void> updatedatafnb(id_fnb) async {
    try {
      var response = await dio.put(
        '${myIpAddr()}/listfnb/updatefnb',
        data: {
          "id_fnb": id_fnb,
          "id_kategori": selectedKategoriIdFnb!,
          "nama_fnb": controller_edit_nama_fnb.text,
          "harga_fnb": int.parse(controller_edit_harga_fnb.text),
          "stok_fnb": int.parse(controller_edit_stok_fnb.text),
        },
      );
      log("api response after update : ${response.data}");
    } catch (e) {
      log("Error di fn updatedatafnb : $e");
    }
  }

  Future<void> updatestatusfnb(id_fnb, String status_fnb) async {
    try {
      var response = await dio.put(
        '${myIpAddr()}/listfnb/updatestatus',
        data: {"id_fnb": id_fnb, "status_fnb": status_fnb},
      );
      log("Status sudah di update");
    } catch (e) {
      log("Error di fn updatedatafnb : $e");
    }
  }

  Future<void> deletedatafnb(id_fnb) async {
    try {
      var response = await dio.delete(
        '${myIpAddr()}/listfnb/deletefnb',
        data: {"id_fnb": id_fnb},
      );
    } catch (e) {
      log("Error di fn Getdapaketmassage : $e");
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
      setState(() {
        dataproduk.clear();
        dataproduk.assignAll(fetcheddata);
        dataproduk.refresh();
      });
    } catch (e) {
      log("Error di fn getdatafnb : $e");
    }
  }

  Future<void> getdataprodukagency(namaagency) async {
    try {
      var response = await dio.get(
        '${myIpAddr()}/listproduk/getdataprodukagency',
        data: {'nama_agency': namaagency},
      );
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
      setState(() {
        dataproduk.assignAll(fetcheddata);
      });
    } catch (e) {
      log("Error di fn getdataprodukagency : $e");
    }
  }

  Future<void> updatedataproduk(id_produk) async {
    try {
      var response = await dio.put(
        '${myIpAddr()}/listproduk/updateproduk',
        data: {
          "nama_produk": controller_edit_nama_produk.text,
          "durasi": int.parse(controller_edit_durasi_produk.text),
          "harga_produk": int.parse(controller_edit_harga_produk.text),
          "stok_produk": int.parse(controller_edit_stok_produk.text),
          "tipe_komisi": valueRadioKomisiProduk,
          "nominal_komisi": int.parse(
            controller_edit_nominal_komisi_produk.text,
          ),
          "tipe_komisi_gro": valueRadioKomisiProdukGro,
          "nominal_komisi_gro": controller_edit_nominal_komisi_produk_gro.text,
          "id_produk": id_produk,
        },
      );
    } catch (e) {
      log("Error di fn Getdapaketmassage : $e");
    }
  }

  Future<void> updatekomisiprodukagency(id_produk, namaagency) async {
    try {
      var response = await dio.put(
        '${myIpAddr()}/listproduk/updatekomisiprodukagency',
        data: {
          "nama_produk": controller_edit_nama_produk.text,
          "durasi": int.parse(controller_edit_durasi_produk.text),
          "harga_produk": int.parse(controller_edit_harga_produk.text),
          "stok_produk": int.parse(controller_edit_stok_produk.text),
          "tipe_komisi": valueRadioKomisiProduk,
          "nominal_komisi": int.parse(
            controller_edit_nominal_komisi_produk.text,
          ),
          "tipe_komisi_gro": valueRadioKomisiProdukGro,
          "nominal_komisi_gro": controller_edit_nominal_komisi_produk_gro.text,
          "id_produk": id_produk,
          "nama_agency": namaagency,
        },
      );
    } catch (e) {
      log("Error di fn updatekomisiprodukagency : $e");
    }
  }

  Future<void> deletedataproduk(id_produk) async {
    try {
      var response = await dio.delete(
        '${myIpAddr()}/listproduk/deleteproduk',
        data: {"id_produk": id_produk},
      );
    } catch (e) {
      log("Error di fn Getdapaketmassage : $e");
    }
  }

  Future<void> getdatafasilitas() async {
    try {
      var response = await dio.get(
        '${myIpAddr()}/listfasilitas/getdatafasilitas',
      );
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "id_fasilitas": item['id_fasilitas'],
              "nama_fasilitas": item['nama_fasilitas'],
              "harga_fasilitas": item['harga_fasilitas'],
            };
          }).toList();
      setState(() {
        datafasilitas.clear();
        datafasilitas.assignAll(fetcheddata);
        datafasilitas.refresh();
      });
    } catch (e) {
      log("Error di fn getdatafnb : $e");
    }
  }

  Future<void> updatedatafasilitas(id_fasilitas) async {
    try {
      log(controller_edit_nama_fasilitas.text);
      var response = await dio.put(
        '${myIpAddr()}/listfasilitas/updatefasilitas',
        data: {
          "nama_fasilitas": controller_edit_nama_fasilitas.text,
          "harga_fasilitas": int.parse(controller_edit_harga_fasilitas.text),
          "id_fasilitas": id_fasilitas,
        },
      );
      log(controller_edit_nama_fasilitas.text);
    } catch (e) {
      log("Error di fn Getdapaketmassage : $e");
    }
  }

  Future<void> deletedatafasilitas(id_fasilitas) async {
    try {
      var response = await dio.delete(
        '${myIpAddr()}/listfasilitas/deletefasilitas',
        data: {"id_fasilitas": id_fasilitas},
      );
    } catch (e) {
      log("Error di fn Getdapaketmassage : $e");
    }
  }

  Future<void> refreshDatafnb() async {
    await Future.delayed(Duration(seconds: 1));
    await getdatafnb();
  }

  Future<void> refreshDatakategori() async {
    await Future.delayed(Duration(seconds: 1));
    await getkategorifnb();
  }

  Future<void> refreshDataProduk() async {
    await Future.delayed(Duration(seconds: 1));
    if (selectedagency == 'No Agency' || selectedagency == null) {
      await getdataproduk();
    } else {
      await getdataprodukagency(selectedagency);
    }
  }

  Future<void> refreshDataFasilitas() async {
    await Future.delayed(Duration(seconds: 1));
    await getdatafasilitas();
  }

  Future<void> getkategorifnb() async {
    try {
      var response = await dio.get('${myIpAddr()}/listfnb/getkategori');
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

  Future<void> searchdatamassage() async {
    try {
      var response = await dio.get(
        '${myIpAddr()}/search/searchdatamassage',
        data: {"nama_paket_msg": textinputan.text},
      );
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "id_paket_msg": item['id_paket_msg'],
              "nama_paket_msg": item['nama_paket_msg'],
              "harga_paket_msg": item['harga_paket_msg'],
              "durasi": item['durasi'],
              "tipe_komisi": item['tipe_komisi'],
              "nominal_komisi": item['nominal_komisi'],
              "detail_paket": item['detail_paket'],
              "tipe_komisi_gro": item['tipe_komisi_gro'],
              "nominal_komisi_gro": item['nominal_komisi_gro'],
            };
          }).toList();
      setState(() {
        datapaketmassage.assignAll(fetcheddata);
      });
    } catch (e) {
      log("Error di fn Getdapaketmassage : $e");
    }
  }

  Future<void> searchdatamassageagency(namaagency) async {
    try {
      var response = await dio.get(
        '${myIpAddr()}/search/searchdatamassageagency',
        data: {"nama_paket_msg": textinputan.text, "nama_agency": namaagency},
      );
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "id_paket_msg": item['id_paket_msg'],
              "nama_paket_msg": item['nama_paket_msg'],
              "harga_paket_msg": item['harga_paket_msg'],
              "durasi": item['durasi'],
              "tipe_komisi": item['tipe_komisi'],
              "nominal_komisi": item['nominal_komisi'],
              "detail_paket": item['detail_paket'],
              "tipe_komisi_gro": item['tipe_komisi_gro'],
              "nominal_komisi_gro": item['nominal_komisi_gro'],
            };
          }).toList();
      setState(() {
        datapaketmassage.assignAll(fetcheddata);
      });
    } catch (e) {
      log("Error di fn Getdapaketmassageagency : $e");
    }
  }

  Future<void> searchdatafnb() async {
    try {
      var response = await dio.get(
        '${myIpAddr()}/search/searchdatafnb',
        data: {"nama_fnb": textinputan.text},
      );
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "id_fnb": item['id_fnb'],
              "id_kategori": item['id_kategori'],
              "nama_fnb": item['nama_fnb'],
              "harga_fnb": item['harga_fnb'],
              "status_fnb": item['status_fnb'],
              "nama_kategori": item['nama_kategori'],
            };
          }).toList();
      setState(() {
        datafnb.clear();
        datafnb.assignAll(fetcheddata);
        datafnb.refresh();
      });
    } catch (e) {
      log("Error di fn getdatafnb : $e");
    }
  }

  Future<void> searchdataproduk() async {
    try {
      var response = await dio.get(
        '${myIpAddr()}/search/searchdataproduk',
        data: {"nama_produk": textinputan.text},
      );
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "id_produk": item['id_produk'],
              "nama_produk": item['nama_produk'],
              "harga_produk": item['harga_produk'],
              "durasi": item['durasi'],
              "stok_produk": item['stok_produk'],
              "tipe_komisi": item['tipe_komisi'],
              "nominal_komisi": item['nominal_komisi'],
              "tipe_komisi_gro": item['tipe_komisi_gro'],
              "nominal_komisi_gro": item['nominal_komisi_gro'],
            };
          }).toList();
      setState(() {
        dataproduk.clear();
        dataproduk.assignAll(fetcheddata);
        dataproduk.refresh();
      });
    } catch (e) {
      log("Error di fn getdatafnb : $e");
    }
  }

  Future<void> searchdataprodukagency(namaagency) async {
    try {
      var response = await dio.get(
        '${myIpAddr()}/search/searchdataprodukagency',
        data: {"nama_produk": textinputan.text, "nama_agency": namaagency},
      );
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
      setState(() {
        dataproduk.assignAll(fetcheddata);
      });
    } catch (e) {
      log("Error di fn searchdataprodukagency : $e");
    }
  }

  Future<void> searchdatafasilitas() async {
    try {
      var response = await dio.get(
        '${myIpAddr()}/search/searchdatafasilitas',
        data: {"nama_fasilitas": textinputan.text},
      );
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "id_fasilitas": item['id_fasilitas'],
              "nama_fasilitas": item['nama_fasilitas'],
              "harga_fasilitas": item['harga_fasilitas'],
            };
          }).toList();
      setState(() {
        datafasilitas.clear();
        datafasilitas.assignAll(fetcheddata);
        datafasilitas.refresh();
      });
    } catch (e) {
      log("Error di fn getdatafnb : $e");
    }
  }

  String? selectedagency;
  RxList<Map<String, dynamic>> data_agency = <Map<String, String>>[].obs;

  Future<void> getdataagency() async {
    try {
      var response2 = await dio.get('${myIpAddr()}/listagency/getdataagency');
      data_agency.value =
          (response2.data as List)
              .map((item) => Map<String, String>.from(item))
              .toList();

      log(data_agency.toString());
    } catch (e) {
      log("error di getdataagency: ${e.toString()}");
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
        isMobile
            ? tabletDesignWidth * mobileAdjustmentFactor
            : tabletDesignWidth;
    final double effectiveDesignHeight =
        isMobile
            ? tabletDesignHeight * mobileAdjustmentFactor
            : tabletDesignHeight;
    return isMobile
        ? WidgetListPaketMobile()
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
                      'List Paket',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
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
                              debounce = Timer(
                                Duration(milliseconds: 1000),
                                () {
                                  selectsearchpaket();
                                },
                              );
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Input Nama',
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
                            if (textSearchMassage.text == "") {
                              refreshData();
                            }
                            selectInputPaket();
                            _moveFirstContainerToTop();
                            _toggleButtonColors(
                              isFirstButtonPressed: true,
                              isThirdButtonPressed: false,
                              isFourthButtonPressed: false,
                            );
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
                        padding: EdgeInsets.only(top: 20, left: 10),
                        child: ElevatedButton(
                          onPressed: () {
                            if (textSearchFnb.text == "") {
                              refreshDatafnb();
                            }
                            selectInputPaket();
                            _moveSecondContainerToTop();
                            _toggleButtonColors(
                              isFirstButtonPressed: false,
                              isThirdButtonPressed: false,
                              isFourthButtonPressed: false,
                            );
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
                        padding: EdgeInsets.only(top: 20, left: 10),
                        child: ElevatedButton(
                          onPressed: () {
                            if (textSearchProduk.text == "") {
                              refreshDataProduk();
                            }
                            selectInputPaket();
                            _moveThirdContainerToTop();
                            _toggleButtonColors(
                              isFirstButtonPressed: false,
                              isThirdButtonPressed: true,
                              isFourthButtonPressed: false,
                            );
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
                            'Paket Produk',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 20, left: 10),
                        child: ElevatedButton(
                          onPressed: () {
                            if (textSearchFasilitas.text == "") {
                              refreshDataFasilitas();
                            }
                            selectInputPaket();
                            _moveFourthContainerToTop();
                            _toggleButtonColors(
                              isFirstButtonPressed: false,
                              isThirdButtonPressed: false,
                              isFourthButtonPressed: true,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _FourthbuttonColor,
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
                            'Paket Fasilitas',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                      if (_isSecondContainerOnTop == false &&
                          _isFourthContainerOnTop == false)
                        Container(
                          width: 240,
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            border: Border.all(width: 1),
                          ),
                          margin: EdgeInsets.only(left: 10, top: 17.5),
                          child: DropdownButton<String>(
                            value: selectedagency,
                            hint: Text('Select Agency'),
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down),
                            elevation: 14,
                            style: const TextStyle(color: Colors.deepPurple),
                            underline: SizedBox(),
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            onChanged: (String? value) {
                              setState(() {
                                selectedagency = value;

                                if (textinputan.text != '') {
                                  if (selectedagency == null ||
                                      selectedagency == "No Agency") {
                                    searchdatamassage();
                                    searchdataproduk();
                                  } else {
                                    searchdatamassageagency(selectedagency);
                                    searchdataprodukagency(selectedagency);
                                  }
                                } else {
                                  refreshData();
                                  refreshDataProduk();
                                }
                              });
                            },
                            items:
                                data_agency.map<DropdownMenuItem<String>>((
                                  agency,
                                ) {
                                  final namaagency =
                                      agency['nama_agency']?.toString() ?? '';
                                  final kodeagency =
                                      agency['kode_agency']?.toString() ?? '';
                                  return DropdownMenuItem<String>(
                                    value: namaagency,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        namaagency,
                                        style: TextStyle(
                                          fontSize: 20,
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
                              datapaketmassage.isEmpty
                                  ? Center(
                                    child: Text("Data Paket Massage Tidak Ada"),
                                  )
                                  : Obx(
                                    () => ListView.builder(
                                      padding: EdgeInsets.zero,
                                      itemCount: datapaketmassage.length,
                                      itemBuilder: (context, index) {
                                        var item = datapaketmassage[index];
                                        return Container(
                                          margin: EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            border: Border.all(width: 1),
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(10),
                                            ),
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
                                                        item['id_paket_msg']
                                                            .toString(),
                                                        style: TextStyle(
                                                          fontSize: 25,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Container(
                                                      child: Text(
                                                        item['nama_paket_msg']
                                                            .toString(),
                                                        style: TextStyle(
                                                          fontSize: 25,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Container(
                                                      child: const Text(
                                                        'Durasi :',
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Container(
                                                      child: Text(
                                                        '${item['durasi'].toString()} Menit',
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Container(
                                                      child: Text(
                                                        'Komisi GRO:',
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Visibility(
                                                      visible:
                                                          item['tipe_komisi_gro'] ==
                                                          0,
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            child: Text(
                                                              item['nominal_komisi_gro']
                                                                  .toString(),
                                                              style: TextStyle(
                                                                fontSize: 15,
                                                                fontFamily:
                                                                    'Poppins',
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(width: 4),
                                                          Container(
                                                            child: Text(
                                                              '%',
                                                              style: TextStyle(
                                                                fontSize: 15,
                                                                fontFamily:
                                                                    'Poppins',
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Visibility(
                                                      visible:
                                                          item['tipe_komisi_gro'] ==
                                                          1,
                                                      child: Container(
                                                        child: Text(
                                                          item['nominal_komisi_gro'] ==
                                                                  null
                                                              ? '0'
                                                              : currencyFormat
                                                                  .format(
                                                                    item['nominal_komisi_gro'],
                                                                  )
                                                                  .toString(),
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            fontFamily:
                                                                'Poppins',
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Container(
                                                      child: Text(
                                                        'Komisi Terapis:',
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Visibility(
                                                      visible:
                                                          item['tipe_komisi'] ==
                                                          0,
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            child: Text(
                                                              item['nominal_komisi']
                                                                  .toString(),
                                                              style: TextStyle(
                                                                fontSize: 15,
                                                                fontFamily:
                                                                    'Poppins',
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(width: 4),
                                                          Container(
                                                            child: Text(
                                                              '%',
                                                              style: TextStyle(
                                                                fontSize: 15,
                                                                fontFamily:
                                                                    'Poppins',
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Visibility(
                                                      visible:
                                                          item['tipe_komisi'] ==
                                                          1,
                                                      child: Container(
                                                        child: Text(
                                                          currencyFormat
                                                              .format(
                                                                item['nominal_komisi'],
                                                              )
                                                              .toString(),
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            fontFamily:
                                                                'Poppins',
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Container(
                                                      child: const Text(
                                                        'Detail :',
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Container(
                                                      child: Text(
                                                        item['detail_paket']
                                                            .toString(),
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ),

                                                    SizedBox(width: 10),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Container(
                                                      child: Text(
                                                        currencyFormat.format(
                                                          item['harga_paket_msg'] ??
                                                              0,
                                                        )..toString(),
                                                        style: TextStyle(
                                                          fontSize: 25,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ),
                                                    Spacer(),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        controller_edit_nama_massage
                                                                .text =
                                                            item['nama_paket_msg'];
                                                        controller_edit_harga_massage
                                                                .text =
                                                            item['harga_paket_msg']
                                                                .toString();
                                                        controller_edit_durasi
                                                                .text =
                                                            item['durasi']
                                                                .toString();
                                                        controller_nominal_komisi_terapis
                                                                .text =
                                                            item['nominal_komisi']
                                                                .toString();
                                                        controller_edit_detail_paket
                                                                .text =
                                                            item['detail_paket'];
                                                        controller_nominal_komisi_gro
                                                                .text =
                                                            item['nominal_komisi_gro']
                                                                .toString();
                                                        _selectedRadio =
                                                            item['tipe_komisi'];
                                                        _selectedRadioGro =
                                                            item['tipe_komisi_gro'];

                                                        if (_selectedRadio ==
                                                            1) {
                                                          valueradio = 1;
                                                        } else {
                                                          valueradio = 0;
                                                        }

                                                        if (_selectedRadioGro ==
                                                            1) {
                                                          valueradiogro = 1;
                                                        } else {
                                                          valueradiogro = 0;
                                                        }

                                                        selecteditem!.value =
                                                            'Terapis';
                                                        isibuttoneditpaket(
                                                          item['id_paket_msg'],
                                                        );
                                                      },
                                                      child: Text(
                                                        'Edit',
                                                        style: TextStyle(
                                                          fontSize: 25,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        Get.dialog(
                                                          StatefulBuilder(
                                                            builder: (
                                                              context,
                                                              setState,
                                                            ) {
                                                              return AlertDialog(
                                                                actions: [
                                                                  Center(
                                                                    child: Container(
                                                                      margin:
                                                                          EdgeInsets.only(
                                                                            top:
                                                                                20,
                                                                          ),
                                                                      height:
                                                                          100,
                                                                      width:
                                                                          250,
                                                                      child: Center(
                                                                        child: Column(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.center,
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.center,
                                                                          children: [
                                                                            Text(
                                                                              '${item['nama_paket_msg']}',
                                                                              style: TextStyle(
                                                                                fontSize:
                                                                                    16,
                                                                                fontFamily:
                                                                                    'Poppins',
                                                                              ),
                                                                            ),
                                                                            Text(
                                                                              'Yakin ingin delete ?',
                                                                              style: TextStyle(
                                                                                fontSize:
                                                                                    16,
                                                                                fontFamily:
                                                                                    'Poppins',
                                                                              ),
                                                                            ),

                                                                            SizedBox(
                                                                              height:
                                                                                  4,
                                                                            ),
                                                                            Row(
                                                                              crossAxisAlignment:
                                                                                  CrossAxisAlignment.center,
                                                                              mainAxisAlignment:
                                                                                  MainAxisAlignment.center,
                                                                              children: [
                                                                                ElevatedButton(
                                                                                  onPressed: () {
                                                                                    deletedatapaketmassage(
                                                                                      item['id_paket_msg'],
                                                                                    );
                                                                                    refreshData();
                                                                                    Get.back();
                                                                                    CherryToast.success(
                                                                                      title: Text(
                                                                                        'Data Berhasil DiHapus',
                                                                                      ),
                                                                                    ).show(
                                                                                      context,
                                                                                    );
                                                                                  },
                                                                                  child: Text(
                                                                                    'Yes',
                                                                                  ),
                                                                                ),
                                                                                SizedBox(
                                                                                  width:
                                                                                      20,
                                                                                ),
                                                                                ElevatedButton(
                                                                                  onPressed: () {
                                                                                    Get.back();
                                                                                  },
                                                                                  child: Text(
                                                                                    'No',
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
                                                              );
                                                            },
                                                          ),
                                                        );
                                                      },
                                                      child: Text(
                                                        'Delete',
                                                        style: TextStyle(
                                                          fontSize: 25,
                                                          fontFamily: 'Poppins',
                                                        ),
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
                              datafnb.isEmpty
                                  ? Center(child: Text("Data F&B Tidak Ada"))
                                  : Obx(
                                    () => ListView.builder(
                                      padding: EdgeInsets.zero,
                                      itemCount: datafnb.length,
                                      itemBuilder: (context, index) {
                                        var item = datafnb[index];
                                        var valkategori = item['id_kategori'];
                                        return Container(
                                          margin: EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            border: Border.all(width: 1),
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(10),
                                            ),
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
                                                        item['id_fnb'],
                                                        style: TextStyle(
                                                          fontSize: 25,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Container(
                                                      child: Text(
                                                        item['nama_fnb'],
                                                        style: TextStyle(
                                                          fontSize: 25,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Container(
                                                      child: Text(
                                                        'Kategori :',
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Container(
                                                      child: Text(
                                                        item['nama_kategori']
                                                            .toString(),
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Container(
                                                      child: Text(
                                                        'Stok :',
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Container(
                                                      child: Text(
                                                        item['stok_fnb']
                                                            .toString(),
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Container(
                                                      child: Text(
                                                        'Status :',
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Switch(
                                                      value:
                                                          item['status_fnb'] ==
                                                          "available",
                                                      onChanged: (Value) {
                                                        setState(() {
                                                          item['status_fnb'] =
                                                              Value
                                                                  ? "available"
                                                                  : "unavailable";
                                                          updatestatusfnb(
                                                            item['id_fnb'],
                                                            item['status_fnb'],
                                                          );
                                                        });
                                                      },
                                                    ),
                                                    SizedBox(width: 10),
                                                    Text(
                                                      item['status_fnb'] ==
                                                              "available"
                                                          ? 'Available'
                                                          : 'Not Available',
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        fontFamily: 'Poppins',
                                                      ),
                                                    ),
                                                    Spacer(),
                                                    Container(
                                                      child: Text(
                                                        currencyFormat
                                                            .format(
                                                              item['harga_fnb'],
                                                            )
                                                            .toString(),
                                                        style: TextStyle(
                                                          fontSize: 25,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          controller_edit_nama_fnb
                                                                  .text =
                                                              item['nama_fnb'];
                                                          controller_edit_harga_fnb
                                                                  .text =
                                                              item['harga_fnb']
                                                                  .toString();
                                                          controller_edit_stok_fnb
                                                                  .text =
                                                              item['stok_fnb']
                                                                  .toString();
                                                          selectedKategoriIdFnb =
                                                              item['id_kategori'];
                                                        });
                                                        isibuttoneditfnb(
                                                          item['id_fnb'],
                                                          valkategori,
                                                        );
                                                        getkategorifnb();
                                                      },
                                                      child: Text(
                                                        'Edit',
                                                        style: TextStyle(
                                                          fontSize: 25,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        Get.dialog(
                                                          StatefulBuilder(
                                                            builder: (
                                                              context,
                                                              setState,
                                                            ) {
                                                              return AlertDialog(
                                                                actions: [
                                                                  Center(
                                                                    child: Container(
                                                                      margin:
                                                                          EdgeInsets.only(
                                                                            top:
                                                                                20,
                                                                          ),
                                                                      height:
                                                                          100,
                                                                      width:
                                                                          250,
                                                                      child: Center(
                                                                        child: Column(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.center,
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.center,
                                                                          children: [
                                                                            Text(
                                                                              '${item['nama_fnb']}',
                                                                              style: TextStyle(
                                                                                fontSize:
                                                                                    16,
                                                                                fontFamily:
                                                                                    'Poppins',
                                                                              ),
                                                                            ),
                                                                            Text(
                                                                              'Yakin ingin delete ?',
                                                                              style: TextStyle(
                                                                                fontSize:
                                                                                    16,
                                                                                fontFamily:
                                                                                    'Poppins',
                                                                              ),
                                                                            ),

                                                                            SizedBox(
                                                                              height:
                                                                                  4,
                                                                            ),
                                                                            Row(
                                                                              crossAxisAlignment:
                                                                                  CrossAxisAlignment.center,
                                                                              mainAxisAlignment:
                                                                                  MainAxisAlignment.center,
                                                                              children: [
                                                                                ElevatedButton(
                                                                                  onPressed: () {
                                                                                    deletedatafnb(
                                                                                      item['id_fnb'],
                                                                                    );
                                                                                    refreshDatafnb();
                                                                                    Get.back();
                                                                                    CherryToast.success(
                                                                                      title: Text(
                                                                                        'Data Berhasil DiHapus',
                                                                                      ),
                                                                                    ).show(
                                                                                      context,
                                                                                    );
                                                                                  },
                                                                                  child: Text(
                                                                                    'Yes',
                                                                                  ),
                                                                                ),
                                                                                SizedBox(
                                                                                  width:
                                                                                      20,
                                                                                ),
                                                                                ElevatedButton(
                                                                                  onPressed: () {
                                                                                    Get.back();
                                                                                  },
                                                                                  child: Text(
                                                                                    'No',
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
                                                              );
                                                            },
                                                          ),
                                                        );
                                                      },
                                                      child: Text(
                                                        'Delete',
                                                        style: TextStyle(
                                                          fontSize: 25,
                                                          fontFamily: 'Poppins',
                                                        ),
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
                              dataproduk.isEmpty
                                  ? Center(child: Text("Data Produk Tidak Ada"))
                                  : Obx(
                                    () => ListView.builder(
                                      padding: EdgeInsets.zero,
                                      itemCount: dataproduk.length,
                                      itemBuilder: (context, index) {
                                        var item = dataproduk[index];
                                        return Container(
                                          margin: EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            border: Border.all(width: 1),
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(10),
                                            ),
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
                                                        item['id_produk'],
                                                        style: TextStyle(
                                                          fontSize: 25,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Container(
                                                      child: Text(
                                                        item['nama_produk'],
                                                        style: TextStyle(
                                                          fontSize: 25,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                Row(
                                                  children: [
                                                    Container(
                                                      child: const Text(
                                                        'Durasi :',
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Container(
                                                      child: Text(
                                                        '${item['durasi'].toString()} Menit',
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Container(
                                                      child: const Text(
                                                        'Stok :',
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Container(
                                                      child: Text(
                                                        item['stok_produk']
                                                            .toString(),
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Container(
                                                      child: const Text(
                                                        'Komisi Gro :',
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Visibility(
                                                      visible:
                                                          item['tipe_komisi_gro'] ==
                                                          0,
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            child: Text(
                                                              item['nominal_komisi_gro']
                                                                  .toString(),
                                                              style: TextStyle(
                                                                fontSize: 15,
                                                                fontFamily:
                                                                    'Poppins',
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(width: 4),
                                                          Container(
                                                            child: Text(
                                                              '%',
                                                              style: TextStyle(
                                                                fontSize: 15,
                                                                fontFamily:
                                                                    'Poppins',
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Visibility(
                                                      visible:
                                                          item['tipe_komisi_gro'] ==
                                                          1,
                                                      child: Container(
                                                        child: Text(
                                                          currencyFormat
                                                              .format(
                                                                item['nominal_komisi_gro'] ??
                                                                    0,
                                                              )
                                                              .toString(),
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            fontFamily:
                                                                'Poppins',
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Container(
                                                      child: const Text(
                                                        'Komisi Terapis :',
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Visibility(
                                                      visible:
                                                          item['tipe_komisi'] ==
                                                          0,
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            child: Text(
                                                              item['nominal_komisi']
                                                                  .toString(),
                                                              style: TextStyle(
                                                                fontSize: 15,
                                                                fontFamily:
                                                                    'Poppins',
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(width: 4),
                                                          Container(
                                                            child: Text(
                                                              '%',
                                                              style: TextStyle(
                                                                fontSize: 15,
                                                                fontFamily:
                                                                    'Poppins',
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Visibility(
                                                      visible:
                                                          item['tipe_komisi'] ==
                                                          1,
                                                      child: Container(
                                                        child: Text(
                                                          currencyFormat
                                                              .format(
                                                                item['nominal_komisi'],
                                                              )
                                                              .toString(),
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            fontFamily:
                                                                'Poppins',
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Spacer(),
                                                    Container(
                                                      child: Text(
                                                        currencyFormat
                                                            .format(
                                                              item['harga_produk'],
                                                            )
                                                            .toString(),
                                                        style: TextStyle(
                                                          fontSize: 25,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        controller_edit_nama_produk
                                                                .text =
                                                            item['nama_produk'];
                                                        controller_edit_durasi_produk
                                                                .text =
                                                            item['durasi']
                                                                .toString();
                                                        controller_edit_harga_produk
                                                                .text =
                                                            item['harga_produk']
                                                                .toString();
                                                        controller_edit_stok_produk
                                                                .text =
                                                            item['stok_produk']
                                                                .toString();
                                                        controller_edit_nominal_komisi_produk
                                                                .text =
                                                            item['nominal_komisi']
                                                                .toString();
                                                        _selectedRadioKomisiProduk =
                                                            item['tipe_komisi'];
                                                        _selectedRadioKomisiProdukGro =
                                                            item['tipe_komisi_gro'];
                                                        selecteditem!.value =
                                                            'Terapis';

                                                        if (_selectedRadioKomisiProduk ==
                                                            1) {
                                                          valueRadioKomisiProduk =
                                                              1;
                                                        } else {
                                                          valueRadioKomisiProduk =
                                                              0;
                                                        }

                                                        if (_selectedRadioKomisiProdukGro ==
                                                            1) {
                                                          valueRadioKomisiProdukGro =
                                                              1;
                                                        } else {
                                                          valueRadioKomisiProdukGro =
                                                              0;
                                                        }

                                                        controller_edit_nominal_komisi_produk_gro
                                                                .text =
                                                            item['nominal_komisi_gro']
                                                                .toString();

                                                        isibuttoneditproduk(
                                                          item['id_produk'],
                                                        );
                                                      },
                                                      child: Text(
                                                        'Edit',
                                                        style: TextStyle(
                                                          fontSize: 25,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        Get.dialog(
                                                          StatefulBuilder(
                                                            builder: (
                                                              context,
                                                              setState,
                                                            ) {
                                                              return AlertDialog(
                                                                actions: [
                                                                  Center(
                                                                    child: Container(
                                                                      margin:
                                                                          EdgeInsets.only(
                                                                            top:
                                                                                20,
                                                                          ),
                                                                      height:
                                                                          100,
                                                                      width:
                                                                          250,
                                                                      child: Center(
                                                                        child: Column(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.center,
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.center,
                                                                          children: [
                                                                            Text(
                                                                              '${item['nama_produk']}',
                                                                              style: TextStyle(
                                                                                fontSize:
                                                                                    16,
                                                                                fontFamily:
                                                                                    'Poppins',
                                                                              ),
                                                                            ),
                                                                            Text(
                                                                              'Yakin ingin delete ?',
                                                                              style: TextStyle(
                                                                                fontSize:
                                                                                    16,
                                                                                fontFamily:
                                                                                    'Poppins',
                                                                              ),
                                                                            ),

                                                                            SizedBox(
                                                                              height:
                                                                                  4,
                                                                            ),
                                                                            Row(
                                                                              crossAxisAlignment:
                                                                                  CrossAxisAlignment.center,
                                                                              mainAxisAlignment:
                                                                                  MainAxisAlignment.center,
                                                                              children: [
                                                                                ElevatedButton(
                                                                                  onPressed: () {
                                                                                    deletedataproduk(
                                                                                      item['id_produk'],
                                                                                    );
                                                                                    refreshDataProduk();
                                                                                    Get.back();
                                                                                    CherryToast.success(
                                                                                      title: Text(
                                                                                        'Data Berhasil DiHapus',
                                                                                      ),
                                                                                    ).show(
                                                                                      context,
                                                                                    );
                                                                                  },
                                                                                  child: Text(
                                                                                    'Yes',
                                                                                  ),
                                                                                ),
                                                                                SizedBox(
                                                                                  width:
                                                                                      20,
                                                                                ),
                                                                                ElevatedButton(
                                                                                  onPressed: () {
                                                                                    Get.back();
                                                                                  },
                                                                                  child: Text(
                                                                                    'No',
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
                                                              );
                                                            },
                                                          ),
                                                        );
                                                      },
                                                      child: Text(
                                                        'Delete',
                                                        style: TextStyle(
                                                          fontSize: 25,
                                                          fontFamily: 'Poppins',
                                                        ),
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
                              datafasilitas.isEmpty
                                  ? Center(
                                    child: Text("Data Fasilitas Tidak Ada"),
                                  )
                                  : Obx(
                                    () => ListView.builder(
                                      padding: EdgeInsets.zero,
                                      itemCount: datafasilitas.length,
                                      itemBuilder: (context, index) {
                                        var item = datafasilitas[index];
                                        return Container(
                                          margin: EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            border: Border.all(width: 1),
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(10),
                                            ),
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
                                                        item['id_fasilitas'],
                                                        style: TextStyle(
                                                          fontSize: 25,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Container(
                                                      child: Text(
                                                        item['nama_fasilitas'],
                                                        style: TextStyle(
                                                          fontSize: 25,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ),
                                                    Spacer(),
                                                    Container(
                                                      child: Text(
                                                        currencyFormat
                                                            .format(
                                                              item['harga_fasilitas'],
                                                            )
                                                            .toString(),
                                                        style: TextStyle(
                                                          fontSize: 25,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          controller_edit_nama_fasilitas
                                                                  .text =
                                                              item['nama_fasilitas'];
                                                          controller_edit_harga_fasilitas
                                                                  .text =
                                                              item['harga_fasilitas']
                                                                  .toString();
                                                        });
                                                        isibuttoneditfasilitas(
                                                          item['id_fasilitas'],
                                                        );
                                                      },
                                                      child: Text(
                                                        'Edit',
                                                        style: TextStyle(
                                                          fontSize: 25,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        Get.dialog(
                                                          StatefulBuilder(
                                                            builder: (
                                                              context,
                                                              setState,
                                                            ) {
                                                              return AlertDialog(
                                                                actions: [
                                                                  Center(
                                                                    child: Container(
                                                                      margin:
                                                                          EdgeInsets.only(
                                                                            top:
                                                                                20,
                                                                          ),
                                                                      height:
                                                                          100,
                                                                      width:
                                                                          250,
                                                                      child: Center(
                                                                        child: Column(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.center,
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.center,
                                                                          children: [
                                                                            Text(
                                                                              '${item['nama_fasilitas']}',
                                                                              style: TextStyle(
                                                                                fontSize:
                                                                                    16,
                                                                                fontFamily:
                                                                                    'Poppins',
                                                                              ),
                                                                            ),
                                                                            Text(
                                                                              'Yakin ingin delete ?',
                                                                              style: TextStyle(
                                                                                fontSize:
                                                                                    16,
                                                                                fontFamily:
                                                                                    'Poppins',
                                                                              ),
                                                                            ),

                                                                            SizedBox(
                                                                              height:
                                                                                  4,
                                                                            ),
                                                                            Row(
                                                                              crossAxisAlignment:
                                                                                  CrossAxisAlignment.center,
                                                                              mainAxisAlignment:
                                                                                  MainAxisAlignment.center,
                                                                              children: [
                                                                                ElevatedButton(
                                                                                  onPressed: () {
                                                                                    deletedatafasilitas(
                                                                                      item['id_fasilitas'],
                                                                                    );
                                                                                    refreshDataFasilitas();
                                                                                    Get.back();
                                                                                    CherryToast.success(
                                                                                      title: Text(
                                                                                        'Data Berhasil DiHapus',
                                                                                      ),
                                                                                    ).show(
                                                                                      context,
                                                                                    );
                                                                                  },
                                                                                  child: Text(
                                                                                    'Yes',
                                                                                  ),
                                                                                ),
                                                                                SizedBox(
                                                                                  width:
                                                                                      20,
                                                                                ),
                                                                                ElevatedButton(
                                                                                  onPressed: () {
                                                                                    Get.back();
                                                                                  },
                                                                                  child: Text(
                                                                                    'No',
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
                                                              );
                                                            },
                                                          ),
                                                        );
                                                      },
                                                      child: Text(
                                                        'Delete',
                                                        style: TextStyle(
                                                          fontSize: 25,
                                                          fontFamily: 'Poppins',
                                                        ),
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

class WidgetListPaketMobile extends StatefulWidget {
  const WidgetListPaketMobile({super.key});

  @override
  State<WidgetListPaketMobile> createState() => _WidgetListPaketMobileState();
}

class _WidgetListPaketMobileState extends State<WidgetListPaketMobile> {
  List<String> listproduk = <String>['Pewangi', 'Pembersih'];
  List<String> listFnB = <String>['Food', 'Beverage'];

  String? selectedKategoriIdFnb;

  TextEditingController textinputan = TextEditingController();
  TextEditingController textSearchMassage = TextEditingController();
  TextEditingController textSearchFnb = TextEditingController();
  TextEditingController textSearchProduk = TextEditingController();
  TextEditingController textSearchFasilitas = TextEditingController();

  TextEditingController controller_edit_nama_massage = TextEditingController();
  TextEditingController controller_edit_harga_massage = TextEditingController();
  TextEditingController controller_edit_detail_paket = TextEditingController();
  TextEditingController controller_nominal_komisi_terapis =
      TextEditingController();
  TextEditingController controller_nominal_komisi_gro = TextEditingController();
  TextEditingController controller_edit_durasi = TextEditingController();

  TextEditingController controller_edit_nama_fnb = TextEditingController();
  TextEditingController controller_edit_harga_fnb = TextEditingController();
  TextEditingController controller_edit_stok_fnb = TextEditingController();

  TextEditingController controller_edit_nama_produk = TextEditingController();
  TextEditingController controller_edit_durasi_produk = TextEditingController();
  TextEditingController controller_edit_harga_produk = TextEditingController();
  TextEditingController controller_edit_stok_produk = TextEditingController();
  TextEditingController controller_edit_nominal_komisi_produk =
      TextEditingController();
  TextEditingController controller_edit_nominal_komisi_produk_gro =
      TextEditingController();

  TextEditingController controller_edit_nama_fasilitas =
      TextEditingController();
  TextEditingController controller_edit_harga_fasilitas =
      TextEditingController();

  bool _isSecondContainerOnTop = false;

  bool _isThirdContainerOntop = false;

  bool _isFourthContainerOnTop = false;

  Color _FirstbuttonColor = Colors.blue;

  Color _SecondbuttonColor = Colors.white;

  Color _ThirdbuttonColor = Colors.white;

  Color _FourthbuttonColor = Colors.white;

  int? _selectedRadio;
  int? _selectedRadioGro;

  int? _selectedRadioKomisiProduk;
  int? _selectedRadioKomisiProdukGro;

  int? valueradio;

  int? valueRadioKomisiProduk;
  int? valueRadioKomisiProdukGro;

  String? isistatus;

  int? valuestatus;

  Timer? debounce;

  bool changekategori = false;

  List<RxString> dropdownpenerimakomisi = ['Terapis'.obs, 'Gro'.obs];
  RxString? selecteditem = ''.obs;
  RxString cekpenerima = ''.obs;

  NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp. ',
    decimalDigits: 0,
  );

  int isready = 0;

  var dio = Dio();

  RxList<Map<String, dynamic>> datapaketmassage = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> datafnb = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> dataproduk = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> datafasilitas = <Map<String, dynamic>>[].obs;
  List<Map<String, dynamic>> datakategorifnb = [];
  List<String> extractDataFnb = [];

  @override
  void dispose() {
    // TODO: implement dispose
    textinputan.dispose();
    textSearchMassage.dispose();
    textSearchFnb.dispose();
    textSearchProduk.dispose();
    textSearchFasilitas.dispose();
    controller_edit_nama_massage.dispose();
    controller_edit_harga_massage.dispose();
    controller_nominal_komisi_terapis.dispose();
    controller_nominal_komisi_gro.dispose();
    controller_edit_durasi.dispose();
    controller_edit_nama_fnb.dispose();
    controller_edit_harga_fnb.dispose();
    controller_edit_nama_produk.dispose();
    controller_edit_durasi_produk.dispose();
    controller_edit_harga_produk.dispose();
    controller_edit_nominal_komisi_produk.dispose();
    controller_edit_nama_fasilitas.dispose();
    controller_edit_harga_fasilitas.dispose();
    debounce?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    refreshData();
    refreshData();
    refreshDataProduk();
    refreshDatafnb();
    refreshDataFasilitas();
    getkategorifnb();
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
    _isSecondContainerOnTop = false;
    _isThirdContainerOntop = false;
    _isFourthContainerOnTop = true;
  }

  void _toggleButtonColors({
    required bool isFirstButtonPressed,
    isThirdButtonPressed,
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
      } else if (isFourthButtonPressed) {
        _FirstbuttonColor = Colors.white;
        _SecondbuttonColor = Colors.white;
        _ThirdbuttonColor = Colors.white;
        _FourthbuttonColor = Colors.blue;
      } else {
        _FirstbuttonColor = Colors.white;
        _SecondbuttonColor = Colors.blue;
        _ThirdbuttonColor = Colors.white;
        _FourthbuttonColor = Colors.white;
      }
    });
  }

  void selectInputPaket() {
    if (_isSecondContainerOnTop == false &&
        _isThirdContainerOntop == false &&
        _isFourthContainerOnTop == false) {
      textSearchProduk.clear();
      textSearchFnb.clear();
      textSearchFasilitas.clear();
      textinputan = textSearchMassage;
    } else if (_isSecondContainerOnTop == true &&
        _isThirdContainerOntop == false &&
        _isFourthContainerOnTop == false) {
      textSearchMassage.clear();
      textSearchProduk.clear();
      textSearchFasilitas.clear();
      textinputan = textSearchFnb;
    } else if (_isSecondContainerOnTop == false &&
        _isThirdContainerOntop == true &&
        _isFourthContainerOnTop == false) {
      textSearchMassage.clear();
      textSearchFnb.clear();
      textSearchFasilitas.clear();
      textinputan = textSearchProduk;
    } else if (_isSecondContainerOnTop == false &&
        _isThirdContainerOntop == false &&
        _isFourthContainerOnTop == true) {
      textSearchMassage.clear();
      textSearchFnb.clear();
      textSearchProduk.clear();
      textinputan = textSearchFasilitas;
    }
  }

  void selectsearchpaket() {
    if (_isSecondContainerOnTop == false &&
        _isThirdContainerOntop == false &&
        _isFourthContainerOnTop == false) {
      searchdatamassage();
    } else if (_isSecondContainerOnTop == true &&
        _isThirdContainerOntop == false &&
        _isFourthContainerOnTop == false) {
      searchdatafnb();
    } else if (_isSecondContainerOnTop == false &&
        _isThirdContainerOntop == true &&
        _isFourthContainerOnTop == false) {
      searchdataproduk();
    } else if (_isSecondContainerOnTop == false &&
        _isThirdContainerOntop == false &&
        _isFourthContainerOnTop == true) {
      searchdatafasilitas();
    }
  }

  void isibuttoneditproduk(id_produk) {
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Container(
                width: Get.width * 0.9,
                height: Get.height - 80,
                child: ListView(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.zero,
                          child: Container(
                            margin: EdgeInsets.only(top: 20),
                            height: 400,
                            width: 200,
                            child: Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
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
                          padding: const EdgeInsets.only(top: 20),
                          child: Container(
                            height: 400,
                            width: Get.width * 0.55,
                            child: Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 12),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    width: Get.width * 0.55,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey[300],
                                    ),
                                    child: TextField(
                                      controller: controller_edit_nama_produk,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
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
                                    width: Get.width * 0.55,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey[300],
                                    ),
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      controller: controller_edit_harga_produk,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
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
                                        width: Get.width * 0.1,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          color: Colors.grey[300],
                                        ),
                                        child: TextField(
                                          keyboardType: TextInputType.number,
                                          inputFormatters: <TextInputFormatter>[
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          controller:
                                              controller_edit_durasi_produk,
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
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.grey[300],
                                      ),
                                      child: DropdownButton<RxString>(
                                        value:
                                            selecteditem?.value == null ||
                                                    selecteditem!.value.isEmpty
                                                ? null
                                                : dropdownpenerimakomisi
                                                    .firstWhereOrNull(
                                                      (itemRx) =>
                                                          itemRx.value ==
                                                          selecteditem!.value,
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
                                              return DropdownMenuItem<RxString>(
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
                                                      _selectedRadioKomisiProduk,
                                                  onChanged: (int? value) {
                                                    setState(() {
                                                      _selectedRadioKomisiProduk =
                                                          value;
                                                      if (_selectedRadioKomisiProduk ==
                                                          1) {
                                                        valueRadioKomisiProduk =
                                                            1;
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
                                                    value: 0,
                                                    groupValue:
                                                        _selectedRadioKomisiProduk,
                                                    onChanged: (int? value) {
                                                      setState(() {
                                                        _selectedRadioKomisiProduk =
                                                            value;
                                                        if (_selectedRadioKomisiProduk ==
                                                            0) {
                                                          valueRadioKomisiProduk =
                                                              0;
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
                                                      _selectedRadioKomisiProdukGro,
                                                  onChanged: (int? value) {
                                                    setState(() {
                                                      _selectedRadioKomisiProdukGro =
                                                          value;
                                                      if (_selectedRadioKomisiProdukGro ==
                                                          1) {
                                                        valueRadioKomisiProdukGro =
                                                            1;
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
                                                    value: 0,
                                                    groupValue:
                                                        _selectedRadioKomisiProdukGro,
                                                    onChanged: (int? value) {
                                                      setState(() {
                                                        _selectedRadioKomisiProdukGro =
                                                            value;
                                                        if (_selectedRadioKomisiProdukGro ==
                                                            0) {
                                                          valueRadioKomisiProdukGro =
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
                                                      _selectedRadioKomisiProduk ==
                                                      1,
                                                  child: Container(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    width: Get.width * 0.55,
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
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            inputFormatters: <
                                                              TextInputFormatter
                                                            >[
                                                              FilteringTextInputFormatter
                                                                  .digitsOnly,
                                                            ],
                                                            controller:
                                                                controller_edit_nominal_komisi_produk,
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
                                                              fontSize: 16,
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
                                                      _selectedRadioKomisiProduk ==
                                                      0,
                                                  child: Container(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    width: Get.width * 0.55,
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
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            inputFormatters: <
                                                              TextInputFormatter
                                                            >[
                                                              FilteringTextInputFormatter
                                                                  .digitsOnly,
                                                            ],
                                                            controller:
                                                                controller_edit_nominal_komisi_produk,
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
                                                              fontSize: 16,
                                                              fontFamily:
                                                                  'Poppins',
                                                            ),
                                                          ),
                                                        ),
                                                        Text(
                                                          '%',
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
                                                      _selectedRadioKomisiProdukGro ==
                                                      1,
                                                  child: Container(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    width: Get.width * 0.55,
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
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            inputFormatters: <
                                                              TextInputFormatter
                                                            >[
                                                              FilteringTextInputFormatter
                                                                  .digitsOnly,
                                                            ],
                                                            controller:
                                                                controller_edit_nominal_komisi_produk_gro,
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
                                                              fontSize: 16,
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
                                                      _selectedRadioKomisiProdukGro ==
                                                      0,
                                                  child: Container(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    width: Get.width * 0.55,
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
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            inputFormatters: <
                                                              TextInputFormatter
                                                            >[
                                                              FilteringTextInputFormatter
                                                                  .digitsOnly,
                                                            ],
                                                            controller:
                                                                controller_edit_nominal_komisi_produk_gro,
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
                                                              fontSize: 16,
                                                              fontFamily:
                                                                  'Poppins',
                                                            ),
                                                          ),
                                                        ),
                                                        Text(
                                                          '%',
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
                                    width: Get.width * 0.55,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey[300],
                                    ),
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      controller: controller_edit_stok_produk,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
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
                                  SizedBox(height: 20),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 120),
                                    child: SizedBox(
                                      height: 35,
                                      width: 100,
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.green,
                                        ),
                                        onPressed: () {
                                          updatedataproduk(id_produk);
                                          dataproduk.isEmpty
                                              ? Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              )
                                              : refreshDataProduk();
                                          Get.back();
                                          CherryToast.success(
                                            title: Text(
                                              'Data Berhasil Diupdate',
                                            ),
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

  void isibuttoneditfnb(id_fnb, idkategori) {
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Container(
                width: Get.width * 0.9,
                height: Get.height * 0.8,
                child: ListView(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.zero,
                          child: Container(
                            margin: EdgeInsets.only(top: 20),
                            height: 230,
                            width: 200,

                            child: Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
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
                            margin: EdgeInsets.only(top: 20),
                            height: 230,
                            width: Get.width * 0.55,
                            child: Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 12),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    width: Get.width * 0.55,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey[300],
                                    ),
                                    child: TextField(
                                      controller: controller_edit_nama_fnb,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
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
                                    width: Get.width * 0.55,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey[300],
                                    ),
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      controller: controller_edit_harga_fnb,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
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
                                    width: Get.width * 0.55,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey[300],
                                    ),
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      controller: controller_edit_stok_fnb,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
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
                                        width: 250,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          color: Colors.grey[300],
                                        ),
                                        child: DropdownButton<String>(
                                          value:
                                              selectedKategoriIdFnb ??
                                              datakategorifnb
                                                  .first['id_kategori'],
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
                                              changekategori = true;
                                              selectedKategoriIdFnb = value;
                                            });
                                          },
                                          items:
                                              datakategorifnb.map<
                                                DropdownMenuItem<String>
                                              >((item) {
                                                return DropdownMenuItem<String>(
                                                  value: item['id_kategori'],
                                                  child: Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Text(
                                                      item['nama_kategori']
                                                          .toString(),
                                                      style: TextStyle(
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
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 120,
                                      top: 20,
                                    ),
                                    child: SizedBox(
                                      height: 35,
                                      width: 100,
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.green,
                                        ),
                                        onPressed: () {
                                          log(selectedKategoriIdFnb.toString());
                                          log('ini loh : $idkategori');
                                          if (changekategori == false) {
                                            selectedKategoriIdFnb = idkategori;
                                          }
                                          changekategori = false;
                                          updatedatafnb(id_fnb);
                                          refreshDatafnb();
                                          Get.back();
                                          CherryToast.success(
                                            title: Text(
                                              'Data Berhasil DiUpdate',
                                            ),
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

  void isibuttoneditpaket(id_paket_msg) {
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            scrollable: true,
            content: SingleChildScrollView(
              child: Container(
                width: Get.width * 0.9,
                height: Get.height * 0.7,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.zero,
                          child: Container(
                            margin: EdgeInsets.only(top: 20),
                            height: 290,
                            width: 200,
                            child: Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
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
                                  SizedBox(height: 15),
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
                          padding: const EdgeInsets.only(top: 20),
                          child: Container(
                            height: 370,
                            width: Get.width * 0.55,
                            child: Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 12),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    width: Get.width * 0.55,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey[300],
                                    ),
                                    child: TextField(
                                      controller: controller_edit_nama_massage,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
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
                                    width: Get.width * 0.55,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey[300],
                                    ),
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      controller: controller_edit_harga_massage,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
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
                                        width: Get.width * 0.15,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          color: Colors.grey[300],
                                        ),
                                        child: TextField(
                                          keyboardType: TextInputType.number,
                                          inputFormatters: <TextInputFormatter>[
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          controller: controller_edit_durasi,
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
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.grey[300],
                                      ),
                                      child: DropdownButton<RxString>(
                                        value:
                                            selecteditem?.value == null ||
                                                    selecteditem!.value.isEmpty
                                                ? null
                                                : dropdownpenerimakomisi
                                                    .firstWhereOrNull(
                                                      (itemRx) =>
                                                          itemRx.value ==
                                                          selecteditem!.value,
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
                                              return DropdownMenuItem<RxString>(
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
                                                  groupValue: _selectedRadio,
                                                  onChanged: (int? value) {
                                                    setState(() {
                                                      _selectedRadio = value;
                                                      if (_selectedRadio == 1) {
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
                                                    value: 0,
                                                    groupValue: _selectedRadio,
                                                    onChanged: (int? value) {
                                                      setState(() {
                                                        _selectedRadio = value;
                                                        if (_selectedRadio ==
                                                            0) {
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
                                                  groupValue: _selectedRadioGro,
                                                  onChanged: (int? value) {
                                                    setState(() {
                                                      _selectedRadioGro = value;
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
                                                    value: 0,
                                                    groupValue:
                                                        _selectedRadioGro,
                                                    onChanged: (int? value) {
                                                      setState(() {
                                                        _selectedRadioGro =
                                                            value;
                                                        if (_selectedRadioGro ==
                                                            0) {
                                                          valueradiogro = 0;
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
                                                  visible: _selectedRadio == 1,
                                                  child: Container(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    width: Get.width * 0.55,
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
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            inputFormatters: <
                                                              TextInputFormatter
                                                            >[
                                                              FilteringTextInputFormatter
                                                                  .digitsOnly,
                                                            ],
                                                            controller:
                                                                controller_nominal_komisi_terapis,
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
                                                              fontSize: 16,
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
                                                  visible: _selectedRadio == 0,
                                                  child: Container(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    width: Get.width * 0.55,
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
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            inputFormatters: <
                                                              TextInputFormatter
                                                            >[
                                                              FilteringTextInputFormatter
                                                                  .digitsOnly,
                                                            ],
                                                            controller:
                                                                controller_nominal_komisi_terapis,
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
                                                              fontSize: 16,
                                                              fontFamily:
                                                                  'Poppins',
                                                            ),
                                                          ),
                                                        ),
                                                        Text(
                                                          '%',
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
                                                      _selectedRadioGro == 1,
                                                  child: Container(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    width: Get.width * 0.55,
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
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            inputFormatters: <
                                                              TextInputFormatter
                                                            >[
                                                              FilteringTextInputFormatter
                                                                  .digitsOnly,
                                                            ],
                                                            controller:
                                                                controller_nominal_komisi_gro,
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
                                                              fontSize: 16,
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
                                                      _selectedRadioGro == 0,
                                                  child: Container(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    width: Get.width * 0.55,
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
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            inputFormatters: <
                                                              TextInputFormatter
                                                            >[
                                                              FilteringTextInputFormatter
                                                                  .digitsOnly,
                                                            ],
                                                            controller:
                                                                controller_nominal_komisi_gro,
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
                                                              fontSize: 16,
                                                              fontFamily:
                                                                  'Poppins',
                                                            ),
                                                          ),
                                                        ),
                                                        Text(
                                                          '%',
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
                                    width: Get.width * 0.55,
                                    height: 45,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey[300],
                                    ),
                                    child: TextField(
                                      controller: controller_edit_detail_paket,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
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
                                  SizedBox(height: 20),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 130),
                                    child: SizedBox(
                                      height: 35,
                                      width: 100,
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.green,
                                        ),
                                        onPressed: () {
                                          updatedatapaketmassage(id_paket_msg);
                                          datapaketmassage.isEmpty
                                              ? Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              )
                                              : refreshData();

                                          Get.back();
                                          CherryToast.success(
                                            title: Text(
                                              'Data Berhasil DiUpdate',
                                            ),
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

  void isibuttoneditfasilitas(id_fasilitas) {
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Container(
                width: Get.width * 0.9,
                height: Get.height * 0.5,
                child: ListView(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.zero,
                          child: Container(
                            margin: EdgeInsets.only(top: 20),
                            height: 180,
                            width: 200,

                            child: Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
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
                            margin: EdgeInsets.only(top: 20),
                            height: 180,
                            width: Get.width * 0.55,
                            child: Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 12),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    width: Get.width * 0.55,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey[300],
                                    ),
                                    child: TextField(
                                      controller:
                                          controller_edit_nama_fasilitas,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
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
                                    width: Get.width * 0.55,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey[300],
                                    ),
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      controller:
                                          controller_edit_harga_fasilitas,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
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
                                  SizedBox(height: 20),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 120),
                                    child: SizedBox(
                                      height: 35,
                                      width: 100,
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.green,
                                        ),
                                        onPressed: () {
                                          updatedatafasilitas(id_fasilitas);
                                          datafasilitas.isEmpty
                                              ? Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              )
                                              : refreshDataFasilitas();
                                          Get.back();
                                          CherryToast.success(
                                            title: Text(
                                              'Data Berhasil DiUpdate',
                                            ),
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

  Future<void> getdatapaketmassage() async {
    try {
      var response = await dio.get(
        '${myIpAddr()}/listmassage/getdatapaketmassage',
      );
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "id_paket_msg": item['id_paket_msg'],
              "nama_paket_msg": item['nama_paket_msg'],
              "harga_paket_msg": item['harga_paket_msg'],
              "durasi": item['durasi'],
              "tipe_komisi": item['tipe_komisi'],
              "nominal_komisi": item['nominal_komisi'],
              "detail_paket": item['detail_paket'],
              "tipe_komisi_gro": item['tipe_komisi_gro'],
              "nominal_komisi_gro": item['nominal_komisi_gro'],
            };
          }).toList();
      setState(() {
        datapaketmassage.clear();
        datapaketmassage.assignAll(fetcheddata);
        datapaketmassage.refresh();
      });
    } catch (e) {
      log("Error di fn Getdatapaketmassage : $e");
    }
  }

  Future<void> getdatapaketmassageagency() async {
    try {
      var response = await dio.get(
        '${myIpAddr()}/listmassage/getdatapaketmassageagency',
      );
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "id_paket_msg": item['id_paket_msg'],
              "nama_paket_msg": item['nama_paket_msg'],
              "harga_paket_msg": item['harga_paket_msg'],
              "durasi": item['durasi'],
              "tipe_komisi": item['tipe_komisi'],
              "nominal_komisi": item['nominal_komisi'],
              "detail_paket": item['detail_paket'],
              "tipe_komisi_gro": item['tipe_komisi_gro'],
              "nominal_komisi_gro": item['nominal_komisi_gro'],
            };
          }).toList();
      setState(() {
        datapaketmassage.assignAll(fetcheddata);
      });
    } catch (e) {
      log("Error di fn Getdatapaketmassage : $e");
    }
  }

  Future<void> updatedatapaketmassage(id_paket_msg) async {
    try {
      log(valueradio.toString());
      var response = await dio.put(
        '${myIpAddr()}/listmassage/updatepaketmassage',
        data: {
          "nama_paket_msg": controller_edit_nama_massage.text,
          "harga_paket_msg": int.parse(controller_edit_harga_massage.text),
          "durasi": int.parse(controller_edit_durasi.text),
          "tipe_komisi": valueradio,
          "nominal_komisi": int.parse(controller_nominal_komisi_terapis.text),
          "tipe_komisi_gro": valueradiogro,
          "nominal_komisi_gro": int.parse(controller_nominal_komisi_gro.text),
          "id_paket_msg": id_paket_msg,
          "detail_paket": controller_edit_detail_paket.text,
        },
      );
    } catch (e) {
      log("Error di fn updatepaketmassage : $e");
    }
  }

  Future<void> deletedatapaketmassage(id_paket_msg) async {
    try {
      var response = await dio.delete(
        '${myIpAddr()}/listmassage/deletepaketmassage',
        data: {"id_paket_msg": id_paket_msg},
      );
    } catch (e) {
      log("Error di fn Getdapaketmassage : $e");
    }
  }

  Future<void> refreshData() async {
    await Future.delayed(Duration(seconds: 1));
    await getdatapaketmassage();
  }

  Future<void> getdatafnb() async {
    try {
      var response = await dio.get('${myIpAddr()}/listfnb/getdatafnb');
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "id_fnb": item['id_fnb'],
              "id_kategori": item['id_kategori'],
              "nama_fnb": item['nama_fnb'],
              "harga_fnb": item['harga_fnb'],
              "stok_fnb": item['stok_fnb'],
              "status_fnb": item['status_fnb'],
              "nama_kategori": item['nama_kategori'],
            };
          }).toList();
      setState(() {
        datafnb.clear();
        datafnb.assignAll(fetcheddata);
        datafnb.refresh();
      });
    } catch (e) {
      log("Error di fn getdatafnb : $e");
    }
  }

  Future<void> updatedatafnb(id_fnb) async {
    try {
      var response = await dio.put(
        '${myIpAddr()}/listfnb/updatefnb',
        data: {
          "id_fnb": id_fnb,
          "id_kategori": selectedKategoriIdFnb!,
          "nama_fnb": controller_edit_nama_fnb.text,
          "harga_fnb": int.parse(controller_edit_harga_fnb.text),
          "stok_fnb": int.parse(controller_edit_stok_fnb.text),
        },
      );
      log("api response after update : ${response.data}");
    } catch (e) {
      log("Error di fn updatedatafnb : $e");
    }
  }

  Future<void> updatestatusfnb(id_fnb, String status_fnb) async {
    try {
      var response = await dio.put(
        '${myIpAddr()}/listfnb/updatestatus',
        data: {"id_fnb": id_fnb, "status_fnb": status_fnb},
      );
      log("Status sudah di update");
    } catch (e) {
      log("Error di fn updatedatafnb : $e");
    }
  }

  Future<void> deletedatafnb(id_fnb) async {
    try {
      var response = await dio.delete(
        '${myIpAddr()}/listfnb/deletefnb',
        data: {"id_fnb": id_fnb},
      );
    } catch (e) {
      log("Error di fn Getdapaketmassage : $e");
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
      setState(() {
        dataproduk.clear();
        dataproduk.assignAll(fetcheddata);
        dataproduk.refresh();
      });
    } catch (e) {
      log("Error di fn getdatafnb : $e");
    }
  }

  Future<void> updatedataproduk(id_produk) async {
    try {
      var response = await dio.put(
        '${myIpAddr()}/listproduk/updateproduk',
        data: {
          "nama_produk": controller_edit_nama_produk.text,
          "durasi": int.parse(controller_edit_durasi_produk.text),
          "harga_produk": int.parse(controller_edit_harga_produk.text),
          "stok_produk": int.parse(controller_edit_stok_produk.text),
          "tipe_komisi": valueRadioKomisiProduk,
          "nominal_komisi": int.parse(
            controller_edit_nominal_komisi_produk.text,
          ),
          "tipe_komisi_gro": valueRadioKomisiProdukGro,
          "nominal_komisi_gro": controller_edit_nominal_komisi_produk_gro.text,
          "id_produk": id_produk,
        },
      );
    } catch (e) {
      log("Error di fn Getdapaketmassage : $e");
    }
  }

  Future<void> deletedataproduk(id_produk) async {
    try {
      var response = await dio.delete(
        '${myIpAddr()}/listproduk/deleteproduk',
        data: {"id_produk": id_produk},
      );
    } catch (e) {
      log("Error di fn Getdapaketmassage : $e");
    }
  }

  Future<void> getdatafasilitas() async {
    try {
      var response = await dio.get(
        '${myIpAddr()}/listfasilitas/getdatafasilitas',
      );
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "id_fasilitas": item['id_fasilitas'],
              "nama_fasilitas": item['nama_fasilitas'],
              "harga_fasilitas": item['harga_fasilitas'],
            };
          }).toList();
      setState(() {
        datafasilitas.clear();
        datafasilitas.assignAll(fetcheddata);
        datafasilitas.refresh();
      });
    } catch (e) {
      log("Error di fn getdatafnb : $e");
    }
  }

  Future<void> updatedatafasilitas(id_fasilitas) async {
    try {
      log(controller_edit_nama_fasilitas.text);
      var response = await dio.put(
        '${myIpAddr()}/listfasilitas/updatefasilitas',
        data: {
          "nama_fasilitas": controller_edit_nama_fasilitas.text,
          "harga_fasilitas": int.parse(controller_edit_harga_fasilitas.text),
          "id_fasilitas": id_fasilitas,
        },
      );
      log(controller_edit_nama_fasilitas.text);
    } catch (e) {
      log("Error di fn Getdapaketmassage : $e");
    }
  }

  Future<void> deletedatafasilitas(id_fasilitas) async {
    try {
      var response = await dio.delete(
        '${myIpAddr()}/listfasilitas/deletefasilitas',
        data: {"id_fasilitas": id_fasilitas},
      );
    } catch (e) {
      log("Error di fn Getdapaketmassage : $e");
    }
  }

  Future<void> refreshDatafnb() async {
    await Future.delayed(Duration(seconds: 1));
    await getdatafnb();
  }

  Future<void> refreshDatakategori() async {
    await Future.delayed(Duration(seconds: 1));
    await getkategorifnb();
  }

  Future<void> refreshDataProduk() async {
    await Future.delayed(Duration(seconds: 1));
    await getdataproduk();
  }

  Future<void> refreshDataFasilitas() async {
    await Future.delayed(Duration(seconds: 1));
    await getdatafasilitas();
  }

  Future<void> getkategorifnb() async {
    try {
      var response = await dio.get('${myIpAddr()}/listfnb/getkategori');
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

  Future<void> searchdatamassage() async {
    try {
      var response = await dio.get(
        '${myIpAddr()}/search/searchdatamassage',
        data: {"nama_paket_msg": textinputan.text},
      );
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "id_paket_msg": item['id_paket_msg'],
              "nama_paket_msg": item['nama_paket_msg'],
              "harga_paket_msg": item['harga_paket_msg'],
              "durasi": item['durasi'],
              "tipe_komisi": item['tipe_komisi'],
              "nominal_komisi": item['nominal_komisi'],
              "tipe_komisi_gro": item['tipe_komisi_gro'],
              "nominal_komisi_gro": item['nominal_komisi_gro'],
              "detail_paket": item['detail_paket'],
            };
          }).toList();
      setState(() {
        datapaketmassage.clear();
        datapaketmassage.assignAll(fetcheddata);
        datapaketmassage.refresh();
      });
    } catch (e) {
      log("Error di fn Getdapaketmassage : $e");
    }
  }

  Future<void> searchdatafnb() async {
    try {
      var response = await dio.get(
        '${myIpAddr()}/search/searchdatafnb',
        data: {"nama_fnb": textinputan.text},
      );
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "id_fnb": item['id_fnb'],
              "id_kategori": item['id_kategori'],
              "nama_fnb": item['nama_fnb'],
              "harga_fnb": item['harga_fnb'],
              "status_fnb": item['status_fnb'],
              "nama_kategori": item['nama_kategori'],
            };
          }).toList();
      setState(() {
        datafnb.clear();
        datafnb.assignAll(fetcheddata);
        datafnb.refresh();
      });
    } catch (e) {
      log("Error di fn getdatafnb : $e");
    }
  }

  Future<void> searchdataproduk() async {
    try {
      var response = await dio.get(
        '${myIpAddr()}/search/searchdataproduk',
        data: {"nama_produk": textinputan.text},
      );
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "id_produk": item['id_produk'],
              "nama_produk": item['nama_produk'],
              "harga_produk": item['harga_produk'],
              "durasi": item['durasi'],
              "tipe_komisi": item['tipe_komisi'],
              "nominal_komisi": item['nominal_komisi'],
            };
          }).toList();
      setState(() {
        dataproduk.clear();
        dataproduk.assignAll(fetcheddata);
        dataproduk.refresh();
      });
    } catch (e) {
      log("Error di fn getdatafnb : $e");
    }
  }

  Future<void> searchdatafasilitas() async {
    try {
      var response = await dio.get(
        '${myIpAddr()}/search/searchdatafasilitas',
        data: {"nama_fasilitas": textinputan.text},
      );
      List<Map<String, dynamic>> fetcheddata =
          (response.data as List).map((item) {
            return {
              "id_fasilitas": item['id_fasilitas'],
              "nama_fasilitas": item['nama_fasilitas'],
              "harga_fasilitas": item['harga_fasilitas'],
            };
          }).toList();
      setState(() {
        datafasilitas.clear();
        datafasilitas.assignAll(fetcheddata);
        datafasilitas.refresh();
      });
    } catch (e) {
      log("Error di fn getdatafnb : $e");
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
                  'List Paket',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
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
                            selectsearchpaket();
                          });
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Input Nama',
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
                        if (textSearchMassage.text == "") {
                          refreshData();
                        }
                        selectInputPaket();
                        _moveFirstContainerToTop();
                        _toggleButtonColors(
                          isFirstButtonPressed: true,
                          isThirdButtonPressed: false,
                          isFourthButtonPressed: false,
                        );
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
                    padding: EdgeInsets.only(top: 20, left: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        if (textSearchFnb.text == "") {
                          refreshDatafnb();
                        }
                        selectInputPaket();
                        _moveSecondContainerToTop();
                        _toggleButtonColors(
                          isFirstButtonPressed: false,
                          isThirdButtonPressed: false,
                          isFourthButtonPressed: false,
                        );
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
                    padding: EdgeInsets.only(top: 20, left: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        if (textSearchProduk.text == "") {
                          refreshDataProduk();
                        }
                        selectInputPaket();
                        _moveThirdContainerToTop();
                        _toggleButtonColors(
                          isFirstButtonPressed: false,
                          isThirdButtonPressed: true,
                          isFourthButtonPressed: false,
                        );
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
                        'Paket Produk',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 20, left: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        if (textSearchFasilitas.text == "") {
                          refreshDataFasilitas();
                        }
                        selectInputPaket();
                        _moveFourthContainerToTop();
                        _toggleButtonColors(
                          isFirstButtonPressed: false,
                          isThirdButtonPressed: false,
                          isFourthButtonPressed: true,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _FourthbuttonColor,
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
                        'Paket Fasilitas',
                        style: TextStyle(color: Colors.black),
                      ),
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
                          datapaketmassage.isEmpty
                              ? Center(
                                child: Text("Data Paket Massage Tidak Ada"),
                              )
                              : Obx(
                                () => ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: datapaketmassage.length,
                                  itemBuilder: (context, index) {
                                    var item = datapaketmassage[index];
                                    return Container(
                                      margin: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        border: Border.all(width: 1),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(10),
                                        ),
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
                                                    item['id_paket_msg'],
                                                    style: TextStyle(
                                                      fontSize: 25,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                Container(
                                                  child: Text(
                                                    item['nama_paket_msg'],
                                                    style: TextStyle(
                                                      fontSize: 25,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Container(
                                                  child: const Text(
                                                    'Durasi :',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                Container(
                                                  child: Text(
                                                    '${item['durasi'].toString()} Menit',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Container(
                                                  child: Text(
                                                    'Komisi GRO:',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                Visibility(
                                                  visible:
                                                      item['tipe_komisi_gro'] ==
                                                      0,
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        child: Text(
                                                          item['nominal_komisi_gro']
                                                              .toString(),
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            fontFamily:
                                                                'Poppins',
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(width: 4),
                                                      Container(
                                                        child: Text(
                                                          '%',
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            fontFamily:
                                                                'Poppins',
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Visibility(
                                                  visible:
                                                      item['tipe_komisi_gro'] ==
                                                      1,
                                                  child: Container(
                                                    child: Text(
                                                      item['nominal_komisi_gro'] ==
                                                              null
                                                          ? '0'
                                                          : currencyFormat
                                                              .format(
                                                                item['nominal_komisi_gro'],
                                                              )
                                                              .toString(),
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        fontFamily: 'Poppins',
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Container(
                                                  child: Text(
                                                    'Komisi Terapis:',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                Visibility(
                                                  visible:
                                                      item['tipe_komisi'] == 0,
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        child: Text(
                                                          item['nominal_komisi']
                                                              .toString(),
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            fontFamily:
                                                                'Poppins',
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(width: 4),
                                                      Container(
                                                        child: Text(
                                                          '%',
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            fontFamily:
                                                                'Poppins',
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Visibility(
                                                  visible:
                                                      item['tipe_komisi'] == 1,
                                                  child: Container(
                                                    child: Text(
                                                      currencyFormat
                                                          .format(
                                                            item['nominal_komisi'],
                                                          )
                                                          .toString(),
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        fontFamily: 'Poppins',
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Container(
                                                  child: const Text(
                                                    'Detail :',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                Container(
                                                  child: Text(
                                                    item['detail_paket'],
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),

                                                SizedBox(width: 10),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Container(
                                                  child: Text(
                                                    currencyFormat.format(
                                                      item['harga_paket_msg'],
                                                    )..toString(),
                                                    style: TextStyle(
                                                      fontSize: 25,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                                Spacer(),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    controller_edit_nama_massage
                                                            .text =
                                                        item['nama_paket_msg'];
                                                    controller_edit_harga_massage
                                                            .text =
                                                        item['harga_paket_msg']
                                                            .toString();
                                                    controller_edit_durasi
                                                        .text = item['durasi']
                                                            .toString();
                                                    controller_nominal_komisi_terapis
                                                            .text =
                                                        item['nominal_komisi']
                                                            .toString();
                                                    controller_edit_detail_paket
                                                            .text =
                                                        item['detail_paket'];
                                                    controller_nominal_komisi_gro
                                                            .text =
                                                        item['nominal_komisi_gro']
                                                            .toString();
                                                    _selectedRadio =
                                                        item['tipe_komisi'];
                                                    _selectedRadioGro =
                                                        item['tipe_komisi_gro'];

                                                    if (_selectedRadio == 1) {
                                                      valueradio = 1;
                                                    } else {
                                                      valueradio = 0;
                                                    }

                                                    if (_selectedRadioGro ==
                                                        1) {
                                                      valueradiogro = 1;
                                                    } else {
                                                      valueradiogro = 0;
                                                    }

                                                    selecteditem!.value =
                                                        'Terapis';
                                                    isibuttoneditpaket(
                                                      item['id_paket_msg'],
                                                    );
                                                  },
                                                  child: Text(
                                                    'Edit',
                                                    style: TextStyle(
                                                      fontSize: 25,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    Get.dialog(
                                                      StatefulBuilder(
                                                        builder: (
                                                          context,
                                                          setState,
                                                        ) {
                                                          return AlertDialog(
                                                            actions: [
                                                              Center(
                                                                child: Container(
                                                                  margin:
                                                                      EdgeInsets.only(
                                                                        top: 20,
                                                                      ),
                                                                  height: 100,
                                                                  width: 250,
                                                                  child: Center(
                                                                    child: Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .center,
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        Text(
                                                                          '${item['nama_paket_msg']}',
                                                                          style: TextStyle(
                                                                            fontSize:
                                                                                16,
                                                                            fontFamily:
                                                                                'Poppins',
                                                                          ),
                                                                        ),
                                                                        Text(
                                                                          'Yakin ingin delete ?',
                                                                          style: TextStyle(
                                                                            fontSize:
                                                                                16,
                                                                            fontFamily:
                                                                                'Poppins',
                                                                          ),
                                                                        ),

                                                                        SizedBox(
                                                                          height:
                                                                              4,
                                                                        ),
                                                                        Row(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.center,
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.center,
                                                                          children: [
                                                                            ElevatedButton(
                                                                              onPressed: () {
                                                                                deletedatapaketmassage(
                                                                                  item['id_paket_msg'],
                                                                                );
                                                                                refreshData();
                                                                                refreshData();
                                                                                Get.back();
                                                                                CherryToast.success(
                                                                                  title: Text(
                                                                                    'Data Berhasil DiHapus',
                                                                                  ),
                                                                                ).show(
                                                                                  context,
                                                                                );
                                                                              },
                                                                              child: Text(
                                                                                'Yes',
                                                                              ),
                                                                            ),
                                                                            SizedBox(
                                                                              width:
                                                                                  20,
                                                                            ),
                                                                            ElevatedButton(
                                                                              onPressed: () {
                                                                                Get.back();
                                                                              },
                                                                              child: Text(
                                                                                'No',
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
                                                          );
                                                        },
                                                      ),
                                                    );
                                                  },
                                                  child: Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                      fontSize: 25,
                                                      fontFamily: 'Poppins',
                                                    ),
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
                          datafnb.isEmpty
                              ? Center(child: Text("Data F&B Tidak Ada"))
                              : Obx(
                                () => ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: datafnb.length,
                                  itemBuilder: (context, index) {
                                    var item = datafnb[index];
                                    var valkategori = item['id_kategori'];
                                    return Container(
                                      margin: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        border: Border.all(width: 1),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(10),
                                        ),
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
                                                    item['id_fnb'],
                                                    style: TextStyle(
                                                      fontSize: 25,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                Container(
                                                  child: Text(
                                                    item['nama_fnb'],
                                                    style: TextStyle(
                                                      fontSize: 25,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Container(
                                                  child: Text(
                                                    'Kategori :',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                Container(
                                                  child: Text(
                                                    item['nama_kategori']
                                                        .toString(),
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Container(
                                                  child: Text(
                                                    'Stok :',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                Container(
                                                  child: Text(
                                                    item['stok_fnb'].toString(),
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Container(
                                                  child: Text(
                                                    'Status :',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                Switch(
                                                  value:
                                                      item['status_fnb'] ==
                                                      "available",
                                                  onChanged: (Value) {
                                                    setState(() {
                                                      item['status_fnb'] =
                                                          Value
                                                              ? "available"
                                                              : "unavailable";
                                                      updatestatusfnb(
                                                        item['id_fnb'],
                                                        item['status_fnb'],
                                                      );
                                                    });
                                                  },
                                                ),
                                                SizedBox(width: 10),
                                                Text(
                                                  item['status_fnb'] ==
                                                          "available"
                                                      ? 'Available'
                                                      : 'Not Available',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontFamily: 'Poppins',
                                                  ),
                                                ),
                                                Spacer(),
                                                Container(
                                                  child: Text(
                                                    currencyFormat
                                                        .format(
                                                          item['harga_fnb'],
                                                        )
                                                        .toString(),
                                                    style: TextStyle(
                                                      fontSize: 25,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      controller_edit_nama_fnb
                                                              .text =
                                                          item['nama_fnb'];
                                                      controller_edit_harga_fnb
                                                              .text =
                                                          item['harga_fnb']
                                                              .toString();
                                                      controller_edit_stok_fnb
                                                              .text =
                                                          item['stok_fnb']
                                                              .toString();
                                                      selectedKategoriIdFnb =
                                                          item['id_kategori'];
                                                    });
                                                    isibuttoneditfnb(
                                                      item['id_fnb'],
                                                      valkategori,
                                                    );
                                                    getkategorifnb();
                                                  },
                                                  child: Text(
                                                    'Edit',
                                                    style: TextStyle(
                                                      fontSize: 25,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    Get.dialog(
                                                      StatefulBuilder(
                                                        builder: (
                                                          context,
                                                          setState,
                                                        ) {
                                                          return AlertDialog(
                                                            actions: [
                                                              Center(
                                                                child: Container(
                                                                  margin:
                                                                      EdgeInsets.only(
                                                                        top: 20,
                                                                      ),
                                                                  height: 100,
                                                                  width: 250,
                                                                  child: Center(
                                                                    child: Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .center,
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        Text(
                                                                          '${item['nama_fnb']}',
                                                                          style: TextStyle(
                                                                            fontSize:
                                                                                16,
                                                                            fontFamily:
                                                                                'Poppins',
                                                                          ),
                                                                        ),
                                                                        Text(
                                                                          'Yakin ingin delete ?',
                                                                          style: TextStyle(
                                                                            fontSize:
                                                                                16,
                                                                            fontFamily:
                                                                                'Poppins',
                                                                          ),
                                                                        ),

                                                                        SizedBox(
                                                                          height:
                                                                              4,
                                                                        ),
                                                                        Row(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.center,
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.center,
                                                                          children: [
                                                                            ElevatedButton(
                                                                              onPressed: () {
                                                                                deletedatafnb(
                                                                                  item['id_fnb'],
                                                                                );
                                                                                refreshDatafnb();
                                                                                Get.back();
                                                                                CherryToast.success(
                                                                                  title: Text(
                                                                                    'Data Berhasil DiHapus',
                                                                                  ),
                                                                                ).show(
                                                                                  context,
                                                                                );
                                                                              },
                                                                              child: Text(
                                                                                'Yes',
                                                                              ),
                                                                            ),
                                                                            SizedBox(
                                                                              width:
                                                                                  20,
                                                                            ),
                                                                            ElevatedButton(
                                                                              onPressed: () {
                                                                                Get.back();
                                                                              },
                                                                              child: Text(
                                                                                'No',
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
                                                          );
                                                        },
                                                      ),
                                                    );
                                                  },
                                                  child: Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                      fontSize: 25,
                                                      fontFamily: 'Poppins',
                                                    ),
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
                          dataproduk.isEmpty
                              ? Center(child: Text("Data Produk Tidak Ada"))
                              : Obx(
                                () => ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: dataproduk.length,
                                  itemBuilder: (context, index) {
                                    var item = dataproduk[index];
                                    return Container(
                                      margin: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        border: Border.all(width: 1),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(10),
                                        ),
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
                                                    item['id_produk'],
                                                    style: TextStyle(
                                                      fontSize: 25,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                Container(
                                                  child: Text(
                                                    item['nama_produk'],
                                                    style: TextStyle(
                                                      fontSize: 25,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),

                                            Row(
                                              children: [
                                                Container(
                                                  child: const Text(
                                                    'Durasi :',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                Container(
                                                  child: Text(
                                                    '${item['durasi'].toString()} Menit',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Container(
                                                  child: const Text(
                                                    'Stok :',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                Container(
                                                  child: Text(
                                                    item['stok_produk']
                                                        .toString(),
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Container(
                                                  child: const Text(
                                                    'Komisi Gro :',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                Visibility(
                                                  visible:
                                                      item['tipe_komisi_gro'] ==
                                                      0,
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        child: Text(
                                                          item['nominal_komisi_gro']
                                                              .toString(),
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            fontFamily:
                                                                'Poppins',
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(width: 4),
                                                      Container(
                                                        child: Text(
                                                          '%',
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            fontFamily:
                                                                'Poppins',
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Visibility(
                                                  visible:
                                                      item['tipe_komisi_gro'] ==
                                                      1,
                                                  child: Container(
                                                    child: Text(
                                                      currencyFormat
                                                          .format(
                                                            item['nominal_komisi_gro'],
                                                          )
                                                          .toString(),
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        fontFamily: 'Poppins',
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Container(
                                                  child: const Text(
                                                    'Komisi Terapis :',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                Visibility(
                                                  visible:
                                                      item['tipe_komisi'] == 0,
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        child: Text(
                                                          item['nominal_komisi']
                                                              .toString(),
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            fontFamily:
                                                                'Poppins',
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(width: 4),
                                                      Container(
                                                        child: Text(
                                                          '%',
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            fontFamily:
                                                                'Poppins',
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Visibility(
                                                  visible:
                                                      item['tipe_komisi'] == 1,
                                                  child: Container(
                                                    child: Text(
                                                      currencyFormat
                                                          .format(
                                                            item['nominal_komisi'],
                                                          )
                                                          .toString(),
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        fontFamily: 'Poppins',
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Spacer(),
                                                Container(
                                                  child: Text(
                                                    currencyFormat
                                                        .format(
                                                          item['harga_produk'],
                                                        )
                                                        .toString(),
                                                    style: TextStyle(
                                                      fontSize: 25,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    controller_edit_nama_produk
                                                            .text =
                                                        item['nama_produk'];
                                                    controller_edit_durasi_produk
                                                        .text = item['durasi']
                                                            .toString();
                                                    controller_edit_harga_produk
                                                            .text =
                                                        item['harga_produk']
                                                            .toString();
                                                    controller_edit_stok_produk
                                                            .text =
                                                        item['stok_produk']
                                                            .toString();
                                                    controller_edit_nominal_komisi_produk
                                                            .text =
                                                        item['nominal_komisi']
                                                            .toString();
                                                    _selectedRadioKomisiProduk =
                                                        item['tipe_komisi'];
                                                    _selectedRadioKomisiProdukGro =
                                                        item['tipe_komisi_gro'];
                                                    selecteditem!.value =
                                                        'Terapis';

                                                    if (_selectedRadioKomisiProduk ==
                                                        1) {
                                                      valueRadioKomisiProduk =
                                                          1;
                                                    } else {
                                                      valueRadioKomisiProduk =
                                                          0;
                                                    }

                                                    if (_selectedRadioKomisiProdukGro ==
                                                        1) {
                                                      valueRadioKomisiProdukGro =
                                                          1;
                                                    } else {
                                                      valueRadioKomisiProdukGro =
                                                          0;
                                                    }

                                                    controller_edit_nominal_komisi_produk_gro
                                                            .text =
                                                        item['nominal_komisi_gro']
                                                            .toString();

                                                    isibuttoneditproduk(
                                                      item['id_produk'],
                                                    );
                                                  },
                                                  child: Text(
                                                    'Edit',
                                                    style: TextStyle(
                                                      fontSize: 25,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    Get.dialog(
                                                      StatefulBuilder(
                                                        builder: (
                                                          context,
                                                          setState,
                                                        ) {
                                                          return AlertDialog(
                                                            actions: [
                                                              Center(
                                                                child: Container(
                                                                  margin:
                                                                      EdgeInsets.only(
                                                                        top: 20,
                                                                      ),
                                                                  height: 100,
                                                                  width: 250,
                                                                  child: Center(
                                                                    child: Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .center,
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        Text(
                                                                          '${item['nama_produk']}',
                                                                          style: TextStyle(
                                                                            fontSize:
                                                                                16,
                                                                            fontFamily:
                                                                                'Poppins',
                                                                          ),
                                                                        ),
                                                                        Text(
                                                                          'Yakin ingin delete ?',
                                                                          style: TextStyle(
                                                                            fontSize:
                                                                                16,
                                                                            fontFamily:
                                                                                'Poppins',
                                                                          ),
                                                                        ),

                                                                        SizedBox(
                                                                          height:
                                                                              4,
                                                                        ),
                                                                        Row(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.center,
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.center,
                                                                          children: [
                                                                            ElevatedButton(
                                                                              onPressed: () {
                                                                                deletedataproduk(
                                                                                  item['id_produk'],
                                                                                );
                                                                                refreshDataProduk();
                                                                                Get.back();
                                                                                CherryToast.success(
                                                                                  title: Text(
                                                                                    'Data Berhasil DiHapus',
                                                                                  ),
                                                                                ).show(
                                                                                  context,
                                                                                );
                                                                              },
                                                                              child: Text(
                                                                                'Yes',
                                                                              ),
                                                                            ),
                                                                            SizedBox(
                                                                              width:
                                                                                  20,
                                                                            ),
                                                                            ElevatedButton(
                                                                              onPressed: () {
                                                                                Get.back();
                                                                              },
                                                                              child: Text(
                                                                                'No',
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
                                                          );
                                                        },
                                                      ),
                                                    );
                                                  },
                                                  child: Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                      fontSize: 25,
                                                      fontFamily: 'Poppins',
                                                    ),
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
                      width: 700,
                      height: 400,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        color: Colors.white,
                      ),
                      child:
                          datafasilitas.isEmpty
                              ? Center(child: Text("Data Fasilitas Tidak Ada"))
                              : Obx(
                                () => ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: datafasilitas.length,
                                  itemBuilder: (context, index) {
                                    var item = datafasilitas[index];
                                    return Container(
                                      margin: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        border: Border.all(width: 1),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(10),
                                        ),
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
                                                    item['id_fasilitas'],
                                                    style: TextStyle(
                                                      fontSize: 25,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                Container(
                                                  child: Text(
                                                    item['nama_fasilitas'],
                                                    style: TextStyle(
                                                      fontSize: 25,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),

                                                SizedBox(width: 10),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Container(
                                                  child: Text(
                                                    currencyFormat
                                                        .format(
                                                          item['harga_fasilitas'],
                                                        )
                                                        .toString(),
                                                    style: TextStyle(
                                                      fontSize: 25,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                                Spacer(),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      controller_edit_nama_fasilitas
                                                              .text =
                                                          item['nama_fasilitas'];
                                                      controller_edit_harga_fasilitas
                                                              .text =
                                                          item['harga_fasilitas']
                                                              .toString();
                                                    });
                                                    isibuttoneditfasilitas(
                                                      item['id_fasilitas'],
                                                    );
                                                  },
                                                  child: Text(
                                                    'Edit',
                                                    style: TextStyle(
                                                      fontSize: 25,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    Get.dialog(
                                                      StatefulBuilder(
                                                        builder: (
                                                          context,
                                                          setState,
                                                        ) {
                                                          return AlertDialog(
                                                            actions: [
                                                              Center(
                                                                child: Container(
                                                                  margin:
                                                                      EdgeInsets.only(
                                                                        top: 20,
                                                                      ),
                                                                  height: 100,
                                                                  width: 250,
                                                                  child: Center(
                                                                    child: Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .center,
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        Text(
                                                                          '${item['nama_fasilitas']}',
                                                                          style: TextStyle(
                                                                            fontSize:
                                                                                16,
                                                                            fontFamily:
                                                                                'Poppins',
                                                                          ),
                                                                        ),
                                                                        Text(
                                                                          'Yakin ingin delete ?',
                                                                          style: TextStyle(
                                                                            fontSize:
                                                                                16,
                                                                            fontFamily:
                                                                                'Poppins',
                                                                          ),
                                                                        ),

                                                                        SizedBox(
                                                                          height:
                                                                              4,
                                                                        ),
                                                                        Row(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.center,
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.center,
                                                                          children: [
                                                                            ElevatedButton(
                                                                              onPressed: () {
                                                                                deletedatafasilitas(
                                                                                  item['id_fasilitas'],
                                                                                );
                                                                                refreshDataFasilitas();
                                                                                Get.back();
                                                                                CherryToast.success(
                                                                                  title: Text(
                                                                                    'Data Berhasil DiHapus',
                                                                                  ),
                                                                                ).show(
                                                                                  context,
                                                                                );
                                                                              },
                                                                              child: Text(
                                                                                'Yes',
                                                                              ),
                                                                            ),
                                                                            SizedBox(
                                                                              width:
                                                                                  20,
                                                                            ),
                                                                            ElevatedButton(
                                                                              onPressed: () {
                                                                                Get.back();
                                                                              },
                                                                              child: Text(
                                                                                'No',
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
                                                          );
                                                        },
                                                      ),
                                                    );
                                                  },
                                                  child: Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                      fontSize: 25,
                                                      fontFamily: 'Poppins',
                                                    ),
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
