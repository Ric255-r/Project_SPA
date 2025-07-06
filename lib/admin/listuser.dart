import 'dart:developer';

import 'package:Project_SPA/function/admin_drawer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Project_SPA/function/ip_address.dart';
import 'package:dio/dio.dart';
import 'package:cherry_toast/cherry_toast.dart';

class ListUser extends StatefulWidget {
  const ListUser({super.key});

  @override
  State<ListUser> createState() => _ListUserState();
}

class _ListUserState extends State<ListUser> {
  ScrollController _scrollController = ScrollController();
  RxList<dynamic> _listUser = [].obs;
  RxList<dynamic> _ListUserFiltered = [].obs;
  TextEditingController _searchController = TextEditingController();

  var dio = Dio();
  Future<void> _getUser() async {
    try {
      var response = await dio.get('${myIpAddr()}/listuser/');

      List<dynamic> responseData = response.data;

      _listUser.assignAll(responseData);
      _ListUserFiltered.assignAll(responseData);

      log("Isi List user $_listUser");
    } catch (e) {
      log("Gagal di getUser listuser $e");
    }
  }

  void _runSearch() {
    String keyword = _searchController.text.toLowerCase().trim();

    setState(() {
      if (keyword.isEmpty) {
        _ListUserFiltered.assignAll(_listUser);
      }

      final filtered =
          _listUser.where((user) {
            final nama =
                (user['nama_karyawan'] ?? '').toString().toLowerCase().trim();
            final id =
                (user['id_karyawan'] ?? '').toString().toLowerCase().trim();

            return nama.contains(keyword) || id.contains(keyword);
          }).toList();
      _ListUserFiltered.assignAll(filtered);
    });
  }

  // Bagian idKaryawan
  RxString _idKaryawan = "".obs;
  // Bagian Old Pass
  RxBool _obscureOldPasswd = true.obs;
  TextEditingController _passwdOldController = TextEditingController();
  // Bagian New Pass
  RxBool _obscureNewPasswd = true.obs;
  TextEditingController _passwdNewController = TextEditingController();
  // Bagian Confirm Pass
  RxBool _obscureConfirmPasswd = true.obs;
  TextEditingController _passwdConfirmController = TextEditingController();
  // Hak Akses
  RxString _hakAkses = "".obs;
  RxString _namaHakAkses = "".obs;
  // RxList<dynamic> _roleOptions = [].obs;
  RxList<dynamic> _hakAksesTambahan = [].obs;
  RxList<dynamic> _selectedHakAksesTambah = [].obs;

  Future<void> _getHakAksesExtra(int id, String idKaryawan) async {
    try {
      var response1 = await dio.get('${myIpAddr()}/form_user/hak_akses?id=$id');
      var response2 = await dio.get(
        '${myIpAddr()}/form_user/hakakses_tambahan?id_karyawan=$idKaryawan',
      );

      List<dynamic> response1Data = response1.data;
      List<dynamic> response2Data = response2.data;

      // Use .assignAll() to update the RxList
      _hakAksesTambahan.assignAll(
        response1Data.map((item) {
          return {"id": item['id'], "nama_hakakses": item['nama_hakakses']};
        }).toList(),
      );

      _selectedHakAksesTambah.assignAll(
        response2Data.map((item) {
          return item['id_hak_akses'];
        }).toList(),
      );

      log("Isi Hak Akses Tambahan $_hakAksesTambahan ");
      log("Isi Selected Hak Akses Tambahan $_selectedHakAksesTambah ");
      // log("Isi roleOptions  $_roleOptions ");
    } catch (e) {
      log("Error Get Hak Akses Tambahan $e");
    }
  }

  // End Hak Akses

  void _dialogEdit(int index) async {
    _hakAkses.value = _listUser[index]['hak_akses'];
    _namaHakAkses.value = _listUser[index]['nama_hakakses'];
    // Debug print
    print('Current hak_akses value: ${_hakAkses.value}');
    // End Debug
    _passwdOldController.text = _listUser[index]['passwd'] ?? "-";
    _idKaryawan.value = _listUser[index]['id_karyawan'];

    await _getHakAksesExtra(int.parse(_hakAkses.value), _idKaryawan.value);

    Get.dialog(
      AlertDialog(
        title: Center(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Spacer(),
                  Text(
                    "Edit Data User",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () {
                      Get.back();
                    },
                    icon: Icon(Icons.cancel),
                  ),
                ],
              ),
              Divider(),
            ],
          ),
        ),
        content: SingleChildScrollView(
          child: Container(
            height: Get.height - 100,
            width: Get.width - 100,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        "Password",
                        style: TextStyle(
                          fontSize: 14,
                          height: 1,
                        ), // Optional: Reduce font size if needed
                      ),
                    ),
                    Expanded(
                      flex: 5, // Increased flex to give more space to TextField
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Obx(
                          () => TextField(
                            controller: _passwdOldController,
                            obscureText: _obscureOldPasswd.value,
                            decoration: InputDecoration(
                              hintText: 'Enter your password',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureOldPasswd.value
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  _obscureOldPasswd.value =
                                      !_obscureOldPasswd.value;
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2), // Space between rows
                Row(
                  children: [
                    Expanded(
                      flex: 2, // Consistent with first row
                      child: Text(
                        "Input Password Baru",
                        style: TextStyle(
                          fontSize: 14,
                          height: 1,
                        ), // Optional: Reduce font size if needed
                      ),
                    ),
                    Expanded(
                      flex: 5, // Consistent with first row
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Obx(
                          () => TextField(
                            controller: _passwdNewController,
                            obscureText: _obscureNewPasswd.value,
                            decoration: InputDecoration(
                              hintText: "Masukkan Password Baru",
                              suffixIcon: IconButton(
                                onPressed: () {
                                  _obscureNewPasswd.value =
                                      !_obscureNewPasswd.value;
                                },
                                icon: Icon(
                                  _obscureNewPasswd.value
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2), // Space between rows
                Row(
                  children: [
                    Expanded(
                      flex: 2, // Consistent with first row
                      child: Text(
                        "Konfirmasi Password Baru",
                        style: TextStyle(
                          fontSize: 14,
                          height: 1,
                        ), // Optional: Reduce font size if needed
                      ),
                    ),
                    Expanded(
                      flex: 5, // Consistent with first row
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Obx(
                          () => TextField(
                            controller: _passwdConfirmController,
                            obscureText: _obscureConfirmPasswd.value,
                            decoration: InputDecoration(
                              hintText: "Konfirmasi Password Baru",
                              suffixIcon: IconButton(
                                onPressed: () {
                                  _obscureConfirmPasswd.value =
                                      !_obscureConfirmPasswd.value;
                                },
                                icon: Icon(
                                  _obscureConfirmPasswd.value
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(child: Text("Hak Akses Utama"), flex: 2),
                    Expanded(
                      child: TextField(
                        readOnly: true,
                        controller: TextEditingController(
                          text: _namaHakAkses.value,
                        ),
                      ),
                      flex: 5,
                    ),
                  ],
                ),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        "Hak Akses Tambahan",
                        style: TextStyle(fontSize: 14, height: 1),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Obx(
                        () => Column(
                          children:
                              _hakAksesTambahan.isNotEmpty
                                  ? _hakAksesTambahanRows()
                                  : [],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),

                ElevatedButton(
                  onPressed: () async {
                    await _updateData();
                    Get.back();
                  },
                  child: Text("Update"),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      _passwdOldController.clear();
      _passwdNewController.clear();
      _passwdConfirmController.clear();
    });
  }

  Future<void> _updateData() async {
    try {
      var data = {
        "hak_akses": _hakAkses.value,
        "secondary_hakakses": _selectedHakAksesTambah,
      };

      // Cek Jika Ga kosong
      if (_passwdNewController.text != "" &&
          _passwdConfirmController.text != "") {
        if (_passwdNewController.text == _passwdConfirmController.text) {
          data['new_pass'] = _passwdNewController.text;
        } else {
          CherryToast.warning(
            title: Text('Password Baru dan Konfirmasi Tidak Cocok'),
          ).show(context);
          return;
        }
      }

      var response = await dio.put(
        '${myIpAddr()}/listuser/update_user/${_idKaryawan.value}',
        data: data,
      );

      if (response.statusCode == 200) {
        CherryToast.success(title: Text('Berhasil Update Data')).show(context);
        _getUser();
      }
    } catch (e) {
      if (e is DioException) {
        log("Error Update Data ${e.response?.data}");
      }
    }
  }

  Future<void> _deleteUser(int index) async {
    try {
      var idKaryawan = _listUser[index]['id_karyawan'];

      var response = await dio.delete(
        '${myIpAddr()}/listuser/delete_user/${idKaryawan}',
      );

      if (response.statusCode == 200) {
        CherryToast.success(title: Text('Berhasil Delete Data')).show(context);

        _getUser();
      }
    } catch (e) {
      if (e is DioException) {
        log("Error Delete User ${e.response?.data}");
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getUser().then((_) => _runSearch());
    _searchController.clear();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _scrollController.dispose();
    _passwdOldController.dispose();
    _passwdNewController.dispose();
    _passwdConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.shortestSide < 600;
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
        ? WidgetListUserMobile()
        : Scaffold(
          drawer: AdminDrawer(),
          appBar: AppBar(
            leading: Builder(
              builder:
                  (context) => IconButton(
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                    icon: Icon(Icons.menu),
                  ),
            ),
            backgroundColor: const Color(0XFFFFE0B2),
            toolbarHeight: 100,
            title: Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 50),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.asset('assets/spa.jpg', height: 80, width: 80),
                ),
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Container(
              height: Get.height,
              width: Get.width,
              decoration: const BoxDecoration(color: Color(0XFFFFE0B2)),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Text(
                    "List Users",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      fontSize: 30,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(right: 70),
                      width: 200,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          _runSearch();
                        },
                        decoration: InputDecoration(
                          hintText: "Cari ID atau Nama",
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    height: 400,
                    width: Get.width - 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.white,
                    ),
                    child: Column(
                      children: [
                        // Header Row
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text(
                                "No",
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "Id Karyawan",
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                "Nama Karyawan",
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "Hak Akses",
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                "Aksi",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),
                        Divider(),
                        // Data Row
                        SizedBox(
                          height: 300,
                          child: Obx(() {
                            if (_listUser.isEmpty) {
                              return Center(child: Text("No Data"));
                            }
                            return Scrollbar(
                              thumbVisibility: true,
                              radius: Radius.circular(10),
                              controller: _scrollController,
                              child: ListView.builder(
                                controller: _scrollController,
                                itemCount: _ListUserFiltered.length,
                                itemBuilder: (context, index) {
                                  final user = _ListUserFiltered[index];
                                  return Row(
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          "${index + 1}",
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          "${user['id_karyawan']}",
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          "${user['nama_karyawan'] ?? '-'}",
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          "${user['nama_hakakses']}",
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            ElevatedButton(
                                              onPressed: () {
                                                _dialogEdit(index);
                                              },
                                              child: Text("Edit"),
                                            ),
                                            SizedBox(width: 10),
                                            ElevatedButton(
                                              onPressed: () {
                                                Get.dialog(
                                                  AlertDialog(
                                                    title: Text('Confirm'),
                                                    content: Text(
                                                      'Yakin menghapus data?',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () {
                                                          Get.back();
                                                        },
                                                        child: Text('Cancel'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () async {
                                                          await _deleteUser(
                                                            index,
                                                          );

                                                          CherryToast.success(
                                                            title: Text(
                                                              'Data berhasil dihapus',
                                                            ),
                                                          ).show(context);
                                                          Get.back();
                                                        },
                                                        child: Text('Confirm'),
                                                      ),
                                                    ],
                                                  ),
                                                  barrierDismissible: false,
                                                );
                                              },
                                              child: Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            );
                          }),
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

class WidgetListUserMobile extends StatefulWidget {
  const WidgetListUserMobile({super.key});

  @override
  State<WidgetListUserMobile> createState() => _WidgetListUserMobileState();
}

class _WidgetListUserMobileState extends State<WidgetListUserMobile> {
  ScrollController _scrollController = ScrollController();
  RxList<dynamic> _listUser = [].obs;
  RxList<dynamic> _ListUserFiltered = [].obs;
  TextEditingController _searchController = TextEditingController();

  var dio = Dio();
  Future<void> _getUser() async {
    try {
      var response = await dio.get('${myIpAddr()}/listuser/');

      List<dynamic> responseData = response.data;

      _listUser.assignAll(responseData);
      _ListUserFiltered.assignAll(responseData);

      log("Isi List user $_listUser");
    } catch (e) {
      log("Gagal di getUser listuser $e");
    }
  }

  void _runSearch() {
    String keyword = _searchController.text.toLowerCase().trim();

    setState(() {
      if (keyword.isEmpty) {
        _ListUserFiltered.assignAll(_listUser);
      }

      final filtered =
          _listUser.where((user) {
            final nama =
                (user['nama_karyawan'] ?? '').toString().toLowerCase().trim();
            final id =
                (user['id_karyawan'] ?? '').toString().toLowerCase().trim();

            return nama.contains(keyword) || id.contains(keyword);
          }).toList();
      _ListUserFiltered.assignAll(filtered);
    });
  }

  // Bagian idKaryawan
  RxString _idKaryawan = "".obs;
  // Bagian Old Pass
  RxBool _obscureOldPasswd = true.obs;
  TextEditingController _passwdOldController = TextEditingController();
  // Bagian New Pass
  RxBool _obscureNewPasswd = true.obs;
  TextEditingController _passwdNewController = TextEditingController();
  // Bagian Confirm Pass
  RxBool _obscureConfirmPasswd = true.obs;
  TextEditingController _passwdConfirmController = TextEditingController();
  // Hak Akses
  RxString _hakAkses = "".obs;
  RxString _namaHakAkses = "".obs;
  // RxList<dynamic> _roleOptions = [].obs;
  RxList<dynamic> _hakAksesTambahan = [].obs;
  RxList<dynamic> _selectedHakAksesTambah = [].obs;

  Future<void> _getHakAksesExtra(int id, String idKaryawan) async {
    try {
      var response1 = await dio.get('${myIpAddr()}/form_user/hak_akses?id=$id');
      var response2 = await dio.get(
        '${myIpAddr()}/form_user/hakakses_tambahan?id_karyawan=$idKaryawan',
      );

      List<dynamic> response1Data = response1.data;
      List<dynamic> response2Data = response2.data;

      // Use .assignAll() to update the RxList
      _hakAksesTambahan.assignAll(
        response1Data.map((item) {
          return {"id": item['id'], "nama_hakakses": item['nama_hakakses']};
        }).toList(),
      );

      _selectedHakAksesTambah.assignAll(
        response2Data.map((item) {
          return item['id_hak_akses'];
        }).toList(),
      );

      log("Isi Hak Akses Tambahan $_hakAksesTambahan ");
      log("Isi Selected Hak Akses Tambahan $_selectedHakAksesTambah ");
      // log("Isi roleOptions  $_roleOptions ");
    } catch (e) {
      log("Error Get Hak Akses Tambahan $e");
    }
  }

  // End Hak Akses

  void _dialogEdit(int index) async {
    _hakAkses.value = _listUser[index]['hak_akses'];
    _namaHakAkses.value = _listUser[index]['nama_hakakses'];
    // Debug print
    print('Current hak_akses value: ${_hakAkses.value}');
    // End Debug
    _passwdOldController.text = _listUser[index]['passwd'] ?? "-";
    _idKaryawan.value = _listUser[index]['id_karyawan'];

    await _getHakAksesExtra(int.parse(_hakAkses.value), _idKaryawan.value);

    Get.dialog(
      AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            children: [
              Center(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Spacer(),
                        Text(
                          "Edit Data User",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          onPressed: () {
                            Get.back();
                          },
                          icon: Icon(Icons.cancel),
                        ),
                      ],
                    ),
                    Divider(),
                  ],
                ),
              ),
              Container(
                height: Get.height + 50,
                width: Get.width - 100,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            "Password",
                            style: TextStyle(
                              fontSize: 14,
                              height: 1,
                            ), // Optional: Reduce font size if needed
                          ),
                        ),
                        Expanded(
                          flex:
                              5, // Increased flex to give more space to TextField
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Obx(
                              () => TextField(
                                controller: _passwdOldController,
                                obscureText: _obscureOldPasswd.value,
                                decoration: InputDecoration(
                                  hintText: 'Enter your password',
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureOldPasswd.value
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      _obscureOldPasswd.value =
                                          !_obscureOldPasswd.value;
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2), // Space between rows
                    Row(
                      children: [
                        Expanded(
                          flex: 2, // Consistent with first row
                          child: Text(
                            "Input Password Baru",
                            style: TextStyle(
                              fontSize: 14,
                              height: 1,
                            ), // Optional: Reduce font size if needed
                          ),
                        ),
                        Expanded(
                          flex: 5, // Consistent with first row
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Obx(
                              () => TextField(
                                controller: _passwdNewController,
                                obscureText: _obscureNewPasswd.value,
                                decoration: InputDecoration(
                                  hintText: "Masukkan Password Baru",
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      _obscureNewPasswd.value =
                                          !_obscureNewPasswd.value;
                                    },
                                    icon: Icon(
                                      _obscureNewPasswd.value
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2), // Space between rows
                    Row(
                      children: [
                        Expanded(
                          flex: 2, // Consistent with first row
                          child: Text(
                            "Konfirmasi Password Baru",
                            style: TextStyle(
                              fontSize: 14,
                              height: 1,
                            ), // Optional: Reduce font size if needed
                          ),
                        ),
                        Expanded(
                          flex: 5, // Consistent with first row
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Obx(
                              () => TextField(
                                controller: _passwdConfirmController,
                                obscureText: _obscureConfirmPasswd.value,
                                decoration: InputDecoration(
                                  hintText: "Konfirmasi Password Baru",
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      _obscureConfirmPasswd.value =
                                          !_obscureConfirmPasswd.value;
                                    },
                                    icon: Icon(
                                      _obscureConfirmPasswd.value
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(child: Text("Hak Akses Utama"), flex: 2),
                        Expanded(
                          child: TextField(
                            readOnly: true,
                            controller: TextEditingController(
                              text: _namaHakAkses.value,
                            ),
                          ),
                          flex: 5,
                        ),
                      ],
                    ),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            "Hak Akses Tambahan",
                            style: TextStyle(fontSize: 14, height: 1),
                          ),
                        ),
                        Expanded(
                          flex: 5,
                          child: Obx(
                            () => Column(
                              children:
                                  _hakAksesTambahan.isNotEmpty
                                      ? _hakAksesTambahanRows()
                                      : [],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),

                    ElevatedButton(
                      onPressed: () async {
                        await _updateData();
                        Get.back();
                      },
                      child: Text("Update"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      _passwdOldController.clear();
      _passwdNewController.clear();
      _passwdConfirmController.clear();
    });
  }

  Future<void> _updateData() async {
    try {
      var data = {
        "hak_akses": _hakAkses.value,
        "secondary_hakakses": _selectedHakAksesTambah,
      };

      // Cek Jika Ga kosong
      if (_passwdNewController.text != "" &&
          _passwdConfirmController.text != "") {
        if (_passwdNewController.text == _passwdConfirmController.text) {
          data['new_pass'] = _passwdNewController.text;
        } else {
          CherryToast.warning(
            title: Text('Password Baru dan Konfirmasi Tidak Cocok'),
          ).show(context);
          return;
        }
      }

      var response = await dio.put(
        '${myIpAddr()}/listuser/update_user/${_idKaryawan.value}',
        data: data,
      );

      if (response.statusCode == 200) {
        CherryToast.success(title: Text('Berhasil Update Data')).show(context);
        _getUser();
      }
    } catch (e) {
      if (e is DioException) {
        log("Error Update Data ${e.response?.data}");
      }
    }
  }

  Future<void> _deleteUser(int index) async {
    try {
      var idKaryawan = _listUser[index]['id_karyawan'];

      var response = await dio.delete(
        '${myIpAddr()}/listuser/delete_user/${idKaryawan}',
      );

      if (response.statusCode == 200) {
        CherryToast.success(title: Text('Berhasil Delete Data')).show(context);

        _getUser();
      }
    } catch (e) {
      if (e is DioException) {
        log("Error Delete User ${e.response?.data}");
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getUser().then((_) => _runSearch());
    _searchController.clear();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _scrollController.dispose();
    _passwdOldController.dispose();
    _passwdNewController.dispose();
    _passwdConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AdminDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder:
              (context) => IconButton(
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                icon: Icon(Icons.menu),
              ),
        ),
        backgroundColor: const Color(0XFFFFE0B2),
        toolbarHeight: 100,
        title: Center(
          child: Padding(
            padding: const EdgeInsets.only(right: 50),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.asset('assets/spa.jpg', height: 80, width: 80),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          height: Get.height,
          width: Get.width,
          decoration: const BoxDecoration(color: Color(0XFFFFE0B2)),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                "List Users",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  fontSize: 30,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.only(right: 70),
                  width: 200,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      _runSearch();
                    },
                    decoration: InputDecoration(hintText: "Cari ID atau Nama"),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                height: 260,
                width: Get.width - 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    // Header Row
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text(
                            "No",
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            "Id Karyawan",
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            "Nama Karyawan",
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            "Hak Akses",
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            "Aksi",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                    Divider(),
                    // Data Row
                    SizedBox(
                      height: 180,
                      child: Obx(() {
                        if (_listUser.isEmpty) {
                          return Center(child: Text("No Data"));
                        }
                        return Scrollbar(
                          thumbVisibility: true,
                          radius: Radius.circular(10),
                          controller: _scrollController,
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: _ListUserFiltered.length,
                            itemBuilder: (context, index) {
                              final user = _ListUserFiltered[index];
                              return Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      "${index + 1}",
                                      textAlign: TextAlign.left,
                                      style: TextStyle(fontFamily: 'Poppins'),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      "${user['id_karyawan']}",
                                      textAlign: TextAlign.left,
                                      style: TextStyle(fontFamily: 'Poppins'),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      "${user['nama_karyawan'] ?? '-'}",
                                      textAlign: TextAlign.left,
                                      style: TextStyle(fontFamily: 'Poppins'),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      "${user['nama_hakakses']}",
                                      textAlign: TextAlign.left,
                                      style: TextStyle(fontFamily: 'Poppins'),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () {
                                            _dialogEdit(index);
                                          },
                                          child: Text("Edit"),
                                        ),
                                        SizedBox(width: 10),
                                        ElevatedButton(
                                          onPressed: () {
                                            Get.dialog(
                                              AlertDialog(
                                                title: Text('Confirm'),
                                                content: Text(
                                                  'Yakin menghapus data?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Get.back();
                                                    },
                                                    child: Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () async {
                                                      await _deleteUser(index);

                                                      CherryToast.success(
                                                        title: Text(
                                                          'Data berhasil dihapus',
                                                        ),
                                                      ).show(context);
                                                      Get.back();
                                                    },
                                                    child: Text('Confirm'),
                                                  ),
                                                ],
                                              ),
                                              barrierDismissible: false,
                                            );
                                          },
                                          child: Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        );
                      }),
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
