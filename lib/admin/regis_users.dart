import 'dart:developer';

// import 'package:Project_SPA/admin/laporan_ob.dart';
import 'package:Project_SPA/admin/listpaket.dart';
import 'package:Project_SPA/admin/listpekerja.dart';
import 'package:Project_SPA/admin/listpromo.dart';
import 'package:Project_SPA/admin/listroom.dart';
import 'package:Project_SPA/admin/regis_paket.dart';
import 'package:Project_SPA/admin/regis_pekerja.dart';
import 'package:Project_SPA/admin/regis_promo.dart';
import 'package:Project_SPA/admin/regis_room.dart';
import 'package:Project_SPA/function/admin_drawer.dart';
import 'package:Project_SPA/function/ip_address.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:Project_SPA/resepsionis/billing_locker.dart';
import 'package:Project_SPA/resepsionis/jenis_transaksi.dart';
import 'package:Project_SPA/main.dart';

String? selectedKode;
String? selectedHakAksesUtama;

class RegisUser extends StatefulWidget {
  const RegisUser({super.key});

  @override
  State<RegisUser> createState() => _RegisUserState();
}

class _RegisUserState extends State<RegisUser> {
  var dio = Dio();
  var txtNama = TextEditingController();
  var txtPass = TextEditingController();
  String namaKaryawan = '';
  List<Map<String, dynamic>> dataKodeKaryawan = [];
  List<String> extractKodeKaryawan = [];

  @override
  void dispose() {
    // TODO: implement dispose
    txtNama.dispose();
    txtPass.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    selectedKode = null;
    txtNama.text = "";
    selectedHakAksesUtama = null;
    _getKodeKaryawan();
    _getHakAkses();
  }

  Future<void> _getKodeKaryawan() async {
    try {
      var response = await dio.get('${myIpAddr()}/form_user/kode');

      setState(() {
        // Map response data to `dataKategoriProduk`
        txtNama.text =
            response.data.isNotEmpty ? response.data[0]['nama_karyawan'] : "";
        dataKodeKaryawan =
            (response.data as List).map((item) {
              return {
                'nama_karyawan': item['nama_karyawan'],
                'id_karyawan': item['id_karyawan'],
              };
            }).toList();

        // Extract IDs into `extractDataProduk`
        extractKodeKaryawan =
            dataKodeKaryawan
                .map((item) => item['id_karyawan'] as String)
                .toList();

        log("Extracted IDs: $extractKodeKaryawan");
        if (selectedKode == null) {
          selectedKode = null;
          txtNama.text = "";
        }
      });

      log("Data Kategori: $dataKodeKaryawan");
      log("Selected ID: $selectedKode");
    } catch (e) {
      log("Error in GetKodeKaryawan: $e");
    }
  }

  List<Map<String, dynamic>> _hakAkses = [];
  Future<void> _getHakAkses() async {
    try {
      var response = await dio.get('${myIpAddr()}/form_user/hak_akses');

      _hakAkses =
          (response.data as List).map((item) {
            return {"id": item['id'], "nama_hakakses": item['nama_hakakses']};
          }).toList();

      log("Isi Hak Akses Utama : $_hakAkses");
    } catch (e) {
      log("Error Get Hak Akses $e");
    }
  }

  List<dynamic> _hakAksesTambahan = [];
  List<dynamic> _selectedHakAksesTambah = [];
  Future<void> _getHakAksesExtra(int id) async {
    try {
      var response = await dio.get('${myIpAddr()}/form_user/hak_akses?id=$id');

      List<dynamic> responseData = response.data;

      setState(() {
        // Add this to trigger UI rebuild
        _hakAksesTambahan.clear();
        for (var i = 0; i < responseData.length; i++) {
          _hakAksesTambahan.add({
            "id": responseData[i]['id'],
            "nama_hakakses": responseData[i]['nama_hakakses'],
          });
        }

        log("Isi Hak Akses Tambahan $_hakAksesTambahan ");
        _selectedHakAksesTambah.clear(); // Clear previous selections
      });
    } catch (e) {
      log("Error Get Hak Akses Tambahan $e");
    }
  }

  void _clearForm() {
    txtNama.clear();
    txtPass.clear();
    selectedKode = null;
    selectedHakAksesUtama = null;
    _hakAksesTambahan.clear();
    _selectedHakAksesTambah.clear();

    setState(() {});
  }

  Future<void> _storeUsers() async {
    try {
      var response = await dio.post(
        '${myIpAddr()}/form_user/post_users',
        data: {
          "id_karyawan": selectedKode!,
          "passwd": txtPass.text,
          "hak_akses": selectedHakAksesUtama,
          // selected hakakses ini passing array berisi id saja
          "hak_akses_tambahan":
              _selectedHakAksesTambah.map((id) => id.toString()).toList(),
        },
      );
      if (response.statusCode == 200) {
        log('Data saved successfully!');
        CherryToast.success(
          title: Text('Data berhasil disimpan'),
        ).show(context);
        _clearForm(); // Clear the form after successful submission
      } else {
        log("Failed to save data: ${response.statusCode}");
      }
    } catch (e) {
      log("Error saving data: $e");
      CherryToast.error(
        title: Text('Terjadi kesalahan saat menyimpan data'),
      ).show(context);
    }
  }

  ScrollController _scrollController = ScrollController();

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
                padding: EdgeInsets.only(top: 20),
                child: Text(
                  'Daftar Users',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 20),
                height: 300,
                width: Get.width - 300,
                color: Colors.white,
                child: Scrollbar(
                  thumbVisibility: true,
                  controller: _scrollController,
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column (Labels)
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Container(
                              height: 300,
                              width: 200,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(15),
                                  bottomLeft: Radius.circular(15),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: ListView(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: const [
                                    SizedBox(height: 15),
                                    Text(
                                      'Kode :',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 15),
                                    Text(
                                      'Nama :',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 15),
                                    Text(
                                      'Password :',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 15),
                                    Text(
                                      'Hak Akses Utama :',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 15),
                                    Text(
                                      'Hak Akses Tambahan:',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Right Column (Inputs)
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Container(
                              height: 300,
                              width: 500,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(15),
                                  bottomRight: Radius.circular(15),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: ListView(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: [
                                    const SizedBox(height: 12),
                                    Container(
                                      width: 250,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.grey[300],
                                      ),
                                      child: DropdownButton<String>(
                                        value: selectedKode,
                                        isExpanded: true,
                                        icon: const Icon(Icons.arrow_drop_down),
                                        elevation: 16,
                                        style: const TextStyle(
                                          color: Colors.deepPurple,
                                        ),
                                        underline: const SizedBox(),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        onChanged: (String? value) {
                                          setState(() {
                                            selectedKode = value;
                                            namaKaryawan =
                                                dataKodeKaryawan.firstWhere(
                                                  (item) =>
                                                      item['id_karyawan'] ==
                                                      value,
                                                  orElse:
                                                      () => {
                                                        'nama_karyawan': '',
                                                      },
                                                )['nama_karyawan']!;
                                            txtNama.text = namaKaryawan;
                                          });
                                        },
                                        items:
                                            dataKodeKaryawan.map<
                                              DropdownMenuItem<String>
                                            >((Map<String, dynamic> item) {
                                              return DropdownMenuItem<String>(
                                                value: item['id_karyawan'],
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    item['id_karyawan']!,
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
                                    const SizedBox(height: 8),
                                    Container(
                                      alignment: Alignment.centerLeft,
                                      width: 480,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.grey[300],
                                      ),
                                      child: TextField(
                                        keyboardType: TextInputType.text,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                            RegExp(r'^[a-zA-Z]+$'),
                                          ),
                                        ],
                                        controller: txtNama,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 13.5,
                                            horizontal: 10,
                                          ),
                                        ),
                                        readOnly: true,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      alignment: Alignment.centerLeft,
                                      width: 480,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.grey[300],
                                      ),
                                      child: TextField(
                                        keyboardType: TextInputType.text,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                            RegExp(r'^[a-zA-Z0-9\s]+$'),
                                          ),
                                        ],
                                        controller: txtPass,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 13.5,
                                            horizontal: 10,
                                          ),
                                        ),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      alignment: Alignment.centerLeft,
                                      width: 480,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.grey[300],
                                      ),
                                      child: DropdownButton<String>(
                                        value: selectedHakAksesUtama,
                                        isExpanded: true,
                                        icon: const Icon(Icons.arrow_drop_down),
                                        elevation: 16,
                                        style: const TextStyle(
                                          color: Colors.deepPurple,
                                        ),
                                        underline: const SizedBox(),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        onChanged: (String? value) {
                                          setState(() {
                                            selectedHakAksesUtama = value;
                                          });

                                          _getHakAksesExtra(
                                            int.parse(selectedHakAksesUtama!),
                                          );
                                        },
                                        items:
                                            _hakAkses.map<
                                              DropdownMenuItem<String>
                                            >((item) {
                                              return DropdownMenuItem<String>(
                                                value: item['id'].toString(),
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    item['nama_hakakses'],
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
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children:
                                          _hakAksesTambahan.isEmpty
                                              ? [
                                                SizedBox(height: 13),
                                                Text(
                                                  "Pilih Hak Akses Utama Dahulu",
                                                ),
                                              ]
                                              : _hakAksesTambahanRows(),
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
              SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Color(0XFFF6F7C4),
                ),
                height: 80,
                width: 300,
                child: Column(
                  children: [
                    TextButton(
                      onPressed: () {
                        if (txtPass.text == "") {
                          CherryToast.warning(
                            title: Text('Password tidak boleh kosong!'),
                          ).show(context);
                        } else {
                          _storeUsers();
                          _clearForm();
                          setState(() {
                            selectedKode = null;
                          });
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                      ),
                      child: Text(
                        'Simpan',
                        style: TextStyle(fontSize: 40, fontFamily: 'Poppins'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      drawer: AdminDrawer(),
    );
  }

  // Buat Column Kelipatan 3, Kalo dibawah 3 maka kasih sizedbox kosong
  List<Widget> _hakAksesTambahanRows() {
    List<Widget> rows = [];
    int itemCount = _hakAksesTambahan.length;
    // kalkulasi berapa banyak row yg dibutuhkan
    int rowCount = (itemCount / 3).ceil();

    for (var i = 0; i < rowCount; i++) {
      int startIndex = i * 3;
      int endIndex = startIndex + 3;
      if (endIndex > itemCount) endIndex = itemCount;

      rows.add(
        Row(
          children: List.generate(3, (colIndex) {
            int dataIndex = startIndex + colIndex;

            if (dataIndex < endIndex) {
              int idHakAkses = _hakAksesTambahan[dataIndex]['id'];

              return Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _selectedHakAksesTambah.contains(idHakAkses),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedHakAksesTambah.add(idHakAkses);
                          } else {
                            _selectedHakAksesTambah.remove(idHakAkses);
                          }

                          print(_selectedHakAksesTambah);
                        });
                      },
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _hakAksesTambahan[dataIndex]['nama_hakakses'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return const Expanded(child: SizedBox.shrink());
            }
          }),
        ),
      );
    }

    return rows;
  }
}
