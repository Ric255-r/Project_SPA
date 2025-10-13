import 'dart:developer';

import 'package:Project_SPA/function/ip_address.dart';
import 'package:Project_SPA/function/token.dart';
import 'package:Project_SPA/resepsionis/daftar_member.dart';
import 'package:Project_SPA/resepsionis/detail_paket_msg.dart';
import 'package:Project_SPA/resepsionis/scannerQR.dart';
import 'package:Project_SPA/resepsionis/store_locker.dart';
import 'package:Project_SPA/ruang_tunggu/main_rt.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'billing_locker.dart';
import 'package:dio/dio.dart';

const List<String> list = <String>['Umum', 'Member', 'VIP'];
String? dropdownValue;

class ControllerPekerja extends GetxController {
  var getnotrans = "".obs;
  var getroom = "".obs;
  var getidterapis = "".obs;
  var getnamaterapis = "".obs;
  var getidterapis2 = "".obs;
  var getnamaterapis2 = "".obs;
  var getidterapis3 = "".obs;
  var getnamaterapis3 = "".obs;
  var statusshowing = "".obs;
}

class TransaksiMassage extends StatefulWidget {
  const TransaksiMassage({super.key});

  @override
  State<TransaksiMassage> createState() => _TransaksiMassageState();
}

class _TransaksiMassageState extends State<TransaksiMassage> {
  final ControllerPekerja controllerPekerja = Get.find<ControllerPekerja>();

  TextEditingController txtRoom = TextEditingController();
  TextEditingController txtTerapis = TextEditingController();
  TextEditingController txtTerapis2 = TextEditingController();
  TextEditingController txtTerapis3 = TextEditingController();
  TextEditingController txtGRO = TextEditingController();
  TextEditingController _noHp = TextEditingController();
  TextEditingController _namaTamu = TextEditingController();

  // Utk Ambil Data Locker
  LockerManager _lockerManager = LockerManager();
  TextEditingController _txtNoLocker = TextEditingController();

  var dio = Dio();
  var idTrans = "";
  TextEditingController _txtIdTrans = TextEditingController();

  final isbuttonvisible = true.obs;

  final ischecked = false.obs;

  List<String> listJenisPilihan = <String>['Showing', 'Pilih Bawah', 'Request', 'Rolling'];
  String? _dropdownJenisPilihan;

  Future<void> _createDraftLastTrans() async {
    try {
      var token = await getTokenSharedPref();
      print(token);

      // pake method post. jadi alurny post dlu id transaksi ke tabel, lalu update
      var response = await dio.post(
        '${myIpAddr()}/id_trans/createDraft',
        data: {"no_loker": _lockerManager.getLocker().toString()},
        options: Options(headers: {"Authorization": "Bearer ${token!}"}),
      );

      var newId = response.data['id_transaksi'];
      log("New Transaction ID: $newId");

      setState(() {
        idTrans = newId;
        _txtIdTrans.text = idTrans;
        _txtNoLocker.text = _lockerManager.getLocker().toString();
      });
    } catch (e) {
      if (e is DioException) {
        log("Error GetLastId Dio ${e.response!.data}");
      }
      log("Error GetLastId $e");
    }
  }

  List<Map<String, dynamic>> _listRoom = [];
  int? _idRuangan;

  Future<void> _getRuangan() async {
    try {
      var response = await dio.get('${myIpAddr()}/listroom/dataroom');

      setState(() {
        _listRoom =
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
            }).toList();
      });
    } catch (e) {
      log("Error Get Data Ruangan $e");
    }
  }

  List<Map<String, dynamic>> _listTerapis = [];
  List<Map<String, dynamic>> _listTerapisRolling = [];
  String? _idTerapis;
  String? _idTerapis2;
  String? _idTerapis3;

  Future<void> _getTerapis() async {
    try {
      var response = await dio.get('${myIpAddr()}/listpekerja/dataterapis');

      setState(() {
        _listTerapis =
            (response.data as List).map((el) {
              return {
                "id_karyawan": el['id_karyawan'],
                "nama_karyawan": el['nama_karyawan'],
                "umur": el['umur'],
                "jabatan": el['jabatan'],
                "is_occupied": el['is_occupied'],
              };
            }).toList();
      });
    } catch (e) {
      log("Error Get Data Terapis $e");
    }
  }

  Future<void> _getTerapisRolling() async {
    try {
      var response = await dio.get('${myIpAddr()}/listpekerja/dataterapisrolling');

      setState(() {
        _listTerapisRolling =
            (response.data as List).map((el) {
              return {
                "id_karyawan": el['id_karyawan'],
                "nama_karyawan": el['nama_karyawan'],
                "umur": el['umur'],
                "jabatan": el['jabatan'],
                "is_occupied": el['is_occupied'],
              };
            }).toList();
      });
    } catch (e) {
      log("Error Get Data Terapis $e");
    }
  }

  List<Map<String, dynamic>> _listGRO = [];
  String? _idGRO;

  Future<void> _getGRO() async {
    try {
      var response = await dio.get('${myIpAddr()}/listpekerja/datagro');

      setState(() {
        _listGRO =
            (response.data as List).map((el) {
              return {
                "id_karyawan": el['id_karyawan'],
                "nama_karyawan": el['nama_karyawan'],
                "umur": el['umur'],
                "jabatan": el['jabatan'],
              };
            }).toList();
      });
    } catch (e) {
      log("Error Get Data GRO $e");
    }
  }

  Future<void> _updateLastTrans() async {
    try {
      var token = await getTokenSharedPref();
      print(token);

      var response = await dio.put(
        '${myIpAddr()}/id_trans/updateDraft/${idTrans}',
        options: Options(headers: {"Authorization": "Bearer " + token!}),
        data: {
          "no_loker": _txtNoLocker.text,
          "jenis_tamu": dropdownValue,
          "jenis_pilihan": _dropdownJenisPilihan,
          "no_hp": _noHp.text,
          "nama_tamu": _namaTamu.text,
          "id_ruangan": _idRuangan,
          "id_terapis": _idTerapis,
          "id_gro": _idGRO,
          "mode": "for_massage",
        },
      );

      log("Update Draft $response");
    } catch (e) {
      log("Error di Update Draft $e");
      if (e is DioException) {
        log("error : ${e.response!.data}");
      }
    }
  }

  Future<bool> removeIdDraft() async {
    try {
      var token = await getTokenSharedPref();
      print(token);

      var response = await dio.delete(
        '${myIpAddr()}/id_trans/deleteDraftId/$idTrans',
        options: Options(headers: {"Authorization": "Bearer " + token!}),
      );

      if (response.statusCode == 200) {
        log("Delete Draft $response");
        return true;
      }

      return false;
    } catch (e) {
      log("Error di Delete Draft $e");
      return false;
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _createDraftLastTrans().then((_) async {
      // Berjalan scr paralel. g ush saling nunggu krn g ad kaitan
      try {
        await Future.wait([_getRuangan(), _getTerapis(), _getGRO(), _getTerapisRolling()]);
      } catch (e) {
        log("Error Get Data ruangan, gro & terapis $e");
      }
      controllerPekerja.statusshowing.value = "notpressed";
      dropdownValue = null;
    });
  }

  Future<void> daftarpanggilankerja(namaruangan, namaterapis) async {
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

  @override
  void dispose() {
    // TODO: implement dispose
    _txtIdTrans.dispose();
    _namaTamu.dispose();
    _noHp.dispose();
    idTrans = "";
    txtRoom.clear();
    txtTerapis.clear();
    txtGRO.clear();
    _txtNoLocker.dispose();
    super.dispose();
  }

  List<dynamic> historyMember = [];

  Future<void> _fetchHistoryMember(String id_member) async {
    try {
      final response = await dio.get(
        '${myIpAddr()}/history/historymemberkunjungan/$id_member',
      ); // API request
      if (response.statusCode == 200) {
        setState(() {
          historyMember = response.data;
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error fetching ID: ${response.statusCode}")));
      }
    } catch (e) {
      print("Error fetching ID: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching ID")));
    }
  }

  String? idMember;
  List<Map<String, dynamic>> _activePromos = [];
  bool _isLoadingPromos = false;

  void _updateFields(String nama, String noHp, String status, String id_member) {
    setState(() {
      _namaTamu.text = nama;
      _noHp.text = noHp;
      dropdownValue = status;
      idMember = id_member;
    });
    _fetchHistoryMember(id_member);

    // Check for active promos when member is scanned
    if (id_member.isNotEmpty) {
      _checkMemberPromos(id_member);
    }
  }

  Future<void> _checkMemberPromos(String id_member) async {
    setState(() {
      _isLoadingPromos = true;
    });

    try {
      var response = await dio.get('${myIpAddr()}/history/historymember/$id_member');
      final now = DateTime.now();
      setState(() {
        _activePromos =
            (response.data as List)
                .where((promo) {
                  final expKunjungan = promo['exp_kunjungan'];
                  if (expKunjungan != null && expKunjungan.isNotEmpty) {
                    final expDate = DateTime.tryParse(expKunjungan);
                    if (expDate != null) {
                      return expDate.isAfter(now); // Only include if not expired
                    }
                  }
                  return false; // Skip invalid or expired promo
                })
                .map((promo) {
                  return {
                    'kode_promo': promo['kode_promo'],
                    'nama_promo': promo['nama_promo'],
                    'nama_paket_msg': promo['nama_paket_msg'],
                    'sisa_kunjungan': promo['sisa_kunjungan'],
                    'exp_kunjungan': promo['exp_kunjungan'],
                    'exp_tahunan': promo['exp_tahunan'],
                  };
                })
                .toList();
        _isLoadingPromos = false;
      });
    } catch (e) {
      log("Error checking member promos: $e");
      setState(() {
        _isLoadingPromos = false;
      });
      CherryToast.error(
        title: Text(
          "Failed to load member promos.",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
        ),
        animationDuration: const Duration(milliseconds: 1500),
        autoDismiss: true,
      ).show(context);
    }
  }

  void _showDialogRoom() {
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Center(child: Text("List Room Tersedia", style: TextStyle(fontFamily: 'Poppins'))),
            content: SizedBox(
              height: Get.height - 200,
              width: Get.width,
              child: ListView(
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 30,
                      mainAxisSpacing: 25,
                      childAspectRatio: 2 / 1.5,
                    ),
                    itemCount: _listRoom.length,
                    itemBuilder: (context, index) {
                      var data = _listRoom[index];
                      // int noRoom = index + 1;
                      // Kondisi Ecek2 buat room penuh
                      bool isFull = data['status'] == "maintenance" || data['status'] == "occupied";
                      Color roomColor = Colors.grey;
                      if (data['status'] == "maintenance") {
                        roomColor = const Color.fromARGB(255, 238, 5, 40); // Red for maintenance
                      } else if (data['status'] == "occupied") {
                        roomColor = const Color.fromARGB(255, 238, 5, 40);
                      } else if ((data['status'] as String).toLowerCase() == "aktif") {
                        roomColor = const Color.fromARGB(255, 64, 97, 55);
                      }

                      return InkWell(
                        onTap: () {
                          if (data['status'] == "maintenance" || data['status'] == "occupied") {
                            CherryToast.error(
                              title: Text(
                                "Ruangan Sedang ${data['status']}!",
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
                            setState(() {
                              try {
                                // Attempt to access txtRoom directly (if in the same widget)
                                txtRoom.text = "Room ${data['nama_ruangan']}";
                                _idRuangan = data['id_ruangan'];
                              } catch (e) {
                                print(
                                  "Error: txtRoom is not directly accessible here. Ensure it's properly managed by GetX.",
                                );
                              }
                            });
                            Get.back();
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: roomColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.door_back_door, size: 50, color: Colors.white),
                              Text(
                                "Room ${data['nama_ruangan']}",
                                style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Poppins'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDialogTherapist() {
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Center(child: Text("Choose Therapist", style: TextStyle(fontFamily: 'Poppins'))),
            content: Container(
              width: Get.width,
              height: Get.height - 200,
              child: SingleChildScrollView(
                child: GridView.builder(
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
                    return InkWell(
                      highlightColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      onTap: () {
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
                        }
                        if (txtTerapis.text == "${data['id_karyawan']} - ${data['nama_karyawan']}" ||
                            txtTerapis3.text == "${data['id_karyawan']} - ${data['nama_karyawan']}") {
                          CherryToast.error(
                            title: Text(
                              'Terapis sudah dipilih',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            animationDuration: const Duration(milliseconds: 1500),
                          ).show(Get.context!);
                        }
                        if (txtTerapis.text == "${data['id_karyawan']} - ${data['nama_karyawan']}" ||
                            txtTerapis3.text == "${data['id_karyawan']} - ${data['nama_karyawan']}") {
                          CherryToast.error(
                            title: Text(
                              'Terapis sudah dipilih',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            animationDuration: const Duration(milliseconds: 1500),
                          ).show(Get.context!);
                        } else {
                          if (txtTerapis2.text == "${data['id_karyawan']} - ${data['nama_karyawan']}" ||
                              txtTerapis3.text == "${data['id_karyawan']} - ${data['nama_karyawan']}") {
                            CherryToast.error(
                              title: Text(
                                'Terapis sudah dipilih',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              animationDuration: const Duration(milliseconds: 1500),
                            ).show(Get.context!);
                          } else {
                            setState(() {
                              try {
                                // Attempt to access txtTerapis directly (if in the same widget)
                                txtTerapis.text = "${data['id_karyawan']} - ${data['nama_karyawan']}";
                                _idTerapis = data['id_karyawan'];
                                controllerPekerja.getidterapis.value = data['id_karyawan'];
                                controllerPekerja.getnamaterapis.value = data['nama_karyawan'];
                              } catch (e) {
                                print(
                                  "Error: txtTerapis is not directly accessible here. Ensure it's properly managed by GetX.",
                                );
                              }
                            });
                            Get.back();
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
                                margin: const EdgeInsets.only(top: 20, left: 12, right: 12),
                                child: Text(data['id_karyawan'], style: TextStyle(fontSize: 30)),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 10),
                                    Text(
                                      data['nama_karyawan'],
                                      style: TextStyle(fontSize: 30, fontFamily: 'Poppins'),
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
          );
        },
      ),
    );
  }

  void _showDialogTherapist2() {
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Center(child: Text("Choose Therapist", style: TextStyle(fontFamily: 'Poppins'))),
            content: Container(
              width: Get.width,
              height: Get.height - 200,
              child: SingleChildScrollView(
                child: GridView.builder(
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
                    return InkWell(
                      highlightColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      onTap: () {
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
                          if (txtTerapis.text == "${data['id_karyawan']} - ${data['nama_karyawan']}" ||
                              txtTerapis3.text == "${data['id_karyawan']} - ${data['nama_karyawan']}") {
                            CherryToast.error(
                              title: Text(
                                'Terapis sudah dipilih',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              animationDuration: const Duration(milliseconds: 1500),
                            ).show(Get.context!);
                          } else {
                            setState(() {
                              try {
                                // Attempt to access txtTerapis directly (if in the same widget)
                                txtTerapis2.text = "${data['id_karyawan']} - ${data['nama_karyawan']}";
                                _idTerapis2 = data['id_karyawan'];
                                controllerPekerja.getidterapis2.value = data['id_karyawan'];
                                controllerPekerja.getnamaterapis2.value = data['nama_karyawan'];
                              } catch (e) {
                                print(
                                  "Error: txtTerapis is not directly accessible here. Ensure it's properly managed by GetX.",
                                );
                              }
                            });
                          }
                          Get.back();
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
                                margin: const EdgeInsets.only(top: 20, left: 12, right: 12),
                                child: Text(data['id_karyawan'], style: TextStyle(fontSize: 30)),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 10),
                                    Text(
                                      data['nama_karyawan'],
                                      style: TextStyle(fontSize: 30, fontFamily: 'Poppins'),
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
          );
        },
      ),
    );
  }

  void _showDialogTherapist3() {
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Center(child: Text("Choose Therapist", style: TextStyle(fontFamily: 'Poppins'))),
            content: Container(
              width: Get.width,
              height: Get.height - 200,
              child: SingleChildScrollView(
                child: GridView.builder(
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
                    return InkWell(
                      highlightColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      onTap: () {
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
                          if (txtTerapis.text == "${data['id_karyawan']} - ${data['nama_karyawan']}" ||
                              txtTerapis2.text == "${data['id_karyawan']} - ${data['nama_karyawan']}") {
                            CherryToast.error(
                              title: Text(
                                'Terapis sudah dipilih',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              animationDuration: const Duration(milliseconds: 1500),
                            ).show(Get.context!);
                          } else {
                            setState(() {
                              try {
                                // Attempt to access txtTerapis directly (if in the same widget)
                                txtTerapis3.text = "${data['id_karyawan']} - ${data['nama_karyawan']}";
                                _idTerapis3 = data['id_karyawan'];
                                controllerPekerja.getidterapis3.value = data['id_karyawan'];
                                controllerPekerja.getnamaterapis3.value = data['nama_karyawan'];
                              } catch (e) {
                                print(
                                  "Error: txtTerapis is not directly accessible here. Ensure it's properly managed by GetX.",
                                );
                              }
                            });
                          }

                          Get.back();
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
                                margin: const EdgeInsets.only(top: 20, left: 12, right: 12),
                                child: Text(data['id_karyawan'], style: TextStyle(fontSize: 30)),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 10),
                                    Text(
                                      data['nama_karyawan'],
                                      style: TextStyle(fontSize: 30, fontFamily: 'Poppins'),
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
          );
        },
      ),
    );
  }

  void _showDialogTherapistRolling() {
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Center(child: Text("Choose Therapist", style: TextStyle(fontFamily: 'Poppins'))),
            content: Container(
              width: Get.width,
              height: Get.height - 200,
              child: SingleChildScrollView(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 30,
                    mainAxisSpacing: 25,
                    childAspectRatio: 2 / 1.5,
                  ),
                  itemCount: _listTerapisRolling.length,
                  itemBuilder: (context, index) {
                    var data = _listTerapisRolling[index];

                    bool isOccupied = data['is_occupied'] == 1;
                    return InkWell(
                      highlightColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      onTap: () {
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
                          if (txtTerapis2.text == "${data['id_karyawan']} - ${data['nama_karyawan']}" ||
                              txtTerapis3.text == "${data['id_karyawan']} - ${data['nama_karyawan']}") {
                            CherryToast.error(
                              title: Text(
                                'Terapis sudah dipilih',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              animationDuration: const Duration(milliseconds: 1500),
                            ).show(Get.context!);
                          } else {
                            setState(() {
                              try {
                                // Attempt to access txtTerapis directly (if in the same widget)
                                txtTerapis.text = "${data['id_karyawan']} - ${data['nama_karyawan']}";
                                _idTerapis = data['id_karyawan'];
                                controllerPekerja.getidterapis.value = data['id_karyawan'];
                                controllerPekerja.getnamaterapis.value = data['nama_karyawan'];
                              } catch (e) {
                                print(
                                  "Error: txtTerapis is not directly accessible here. Ensure it's properly managed by GetX.",
                                );
                              }
                            });
                          }

                          Get.back();
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
                                margin: const EdgeInsets.only(top: 20, left: 12, right: 12),
                                child: Text(data['id_karyawan'], style: TextStyle(fontSize: 30)),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 10),
                                    Text(
                                      data['nama_karyawan'],
                                      style: TextStyle(fontSize: 30, fontFamily: 'Poppins'),
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
          );
        },
      ),
    );
  }

  void _showDialogTherapistRolling2() {
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Center(child: Text("Choose Therapist", style: TextStyle(fontFamily: 'Poppins'))),
            content: Container(
              width: Get.width,
              height: Get.height - 200,
              child: SingleChildScrollView(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 30,
                    mainAxisSpacing: 25,
                    childAspectRatio: 2 / 1.5,
                  ),
                  itemCount: _listTerapisRolling.length,
                  itemBuilder: (context, index) {
                    var data = _listTerapisRolling[index];

                    bool isOccupied = data['is_occupied'] == 1;
                    return InkWell(
                      highlightColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      onTap: () {
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
                          if (txtTerapis.text == "${data['id_karyawan']} - ${data['nama_karyawan']}" ||
                              txtTerapis3.text == "${data['id_karyawan']} - ${data['nama_karyawan']}") {
                            CherryToast.error(
                              title: Text(
                                'Terapis sudah dipilih',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              animationDuration: const Duration(milliseconds: 1500),
                            ).show(Get.context!);
                          } else {
                            setState(() {
                              try {
                                // Attempt to access txtTerapis directly (if in the same widget)
                                txtTerapis2.text = "${data['id_karyawan']} - ${data['nama_karyawan']}";
                                _idTerapis2 = data['id_karyawan'];
                                controllerPekerja.getidterapis2.value = data['id_karyawan'];
                                controllerPekerja.getnamaterapis2.value = data['nama_karyawan'];
                              } catch (e) {
                                print(
                                  "Error: txtTerapis is not directly accessible here. Ensure it's properly managed by GetX.",
                                );
                              }
                            });
                          }

                          Get.back();
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
                                margin: const EdgeInsets.only(top: 20, left: 12, right: 12),
                                child: Text(data['id_karyawan'], style: TextStyle(fontSize: 30)),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 10),
                                    Text(
                                      data['nama_karyawan'],
                                      style: TextStyle(fontSize: 30, fontFamily: 'Poppins'),
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
          );
        },
      ),
    );
  }

  void _showDialogTherapistRolling3() {
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Center(child: Text("Choose Therapist", style: TextStyle(fontFamily: 'Poppins'))),
            content: Container(
              width: Get.width,
              height: Get.height - 200,
              child: SingleChildScrollView(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 30,
                    mainAxisSpacing: 25,
                    childAspectRatio: 2 / 1.5,
                  ),
                  itemCount: _listTerapisRolling.length,
                  itemBuilder: (context, index) {
                    var data = _listTerapisRolling[index];

                    bool isOccupied = data['is_occupied'] == 1;
                    return InkWell(
                      highlightColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      onTap: () {
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
                          if (txtTerapis.text == "${data['id_karyawan']} - ${data['nama_karyawan']}" ||
                              txtTerapis2.text == "${data['id_karyawan']} - ${data['nama_karyawan']}") {
                            CherryToast.error(
                              title: Text(
                                'Terapis sudah dipilih',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              animationDuration: const Duration(milliseconds: 1500),
                            ).show(Get.context!);
                          } else {
                            setState(() {
                              try {
                                // Attempt to access txtTerapis directly (if in the same widget)
                                txtTerapis3.text = "${data['id_karyawan']} - ${data['nama_karyawan']}";
                                _idTerapis3 = data['id_karyawan'];
                                controllerPekerja.getidterapis3.value = data['id_karyawan'];
                                controllerPekerja.getnamaterapis3.value = data['nama_karyawan'];
                              } catch (e) {
                                print(
                                  "Error: txtTerapis is not directly accessible here. Ensure it's properly managed by GetX.",
                                );
                              }
                            });
                          }
                          Get.back();
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
                                margin: const EdgeInsets.only(top: 20, left: 12, right: 12),
                                child: Text(data['id_karyawan'], style: TextStyle(fontSize: 30)),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 10),
                                    Text(
                                      data['nama_karyawan'],
                                      style: TextStyle(fontSize: 30, fontFamily: 'Poppins'),
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
          );
        },
      ),
    );
  }

  void _showDialogGRO() {
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Center(child: Text("Choose GRO", style: TextStyle(fontFamily: 'Poppins'))),
            content: Container(
              width: Get.width,
              height: Get.height - 200,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 30,
                  mainAxisSpacing: 25,
                  childAspectRatio: 2 / 1.5,
                ),
                itemCount: _listGRO.length,
                itemBuilder: (context, index) {
                  var data = _listGRO[index];

                  return InkWell(
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    onTap: () {
                      setState(() {
                        txtGRO.text = "${data['id_karyawan']} - ${data['nama_karyawan']}";
                        _idGRO = data['id_karyawan'];
                      });
                      Get.back();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(top: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: const Color.fromARGB(255, 35, 195, 144),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 20, left: 12, right: 12),
                              child: Text(data['id_karyawan'], style: TextStyle(fontSize: 30)),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 10),
                                  Text(
                                    data['nama_karyawan'],
                                    style: TextStyle(fontSize: 30, fontFamily: 'Poppins'),
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
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        try {
          bool isDeleted = await removeIdDraft();
          return isDeleted;
        } catch (e) {
          Get.snackbar("Error", "Gagal Remove Id Draft $e");
          return false;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: IconButton(
              icon: Icon(Icons.arrow_back, size: 40), // Back Icon
              onPressed: () async {
                bool isDeleted = await removeIdDraft();
                if (isDeleted) Get.back();
              },
            ),
          ),
          title: Text('Transaksi Massage', style: TextStyle(fontSize: 60, fontFamily: 'Poppins')),
          centerTitle: true,
          toolbarHeight: 130,
          leadingWidth: 100,
          backgroundColor: Color(0XFFFFE0B2),
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          child: Obx(
            () => Container(
              decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
              width: Get.width,
              height: ischecked.value == false ? Get.height + 20 : Get.height + 120,
              child: Padding(
                padding: EdgeInsets.only(left: 20),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Kolom Pertama
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'No Transaksi :',
                                    style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(left: 10),
                                    child: Container(
                                      width: 300,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.white,
                                      ),
                                      child: TextField(
                                        controller: _txtIdTrans,
                                        readOnly: true,
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                                        ),
                                        style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(top: 15),
                                    child: Text(
                                      'No Locker :',
                                      style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(left: 38, top: 15),
                                    child: Container(
                                      width: 200,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.white,
                                      ),
                                      child: TextField(
                                        controller: _txtNoLocker,
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                                        ),
                                        style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(top: 15),
                                    child: Text(
                                      'Jenis Tamu :',
                                      style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(left: 22, top: 15),
                                    child: Container(
                                      width: 200,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.white,
                                      ),
                                      child: DropdownButton<String>(
                                        value: dropdownValue,
                                        isExpanded: true,
                                        icon: const Icon(Icons.arrow_drop_down),
                                        elevation: 16,
                                        style: const TextStyle(color: Colors.deepPurple),
                                        underline: SizedBox(),
                                        padding: EdgeInsets.symmetric(horizontal: 10),
                                        onChanged: (String? value) {
                                          setState(() {
                                            dropdownValue = value;
                                          });
                                        },
                                        items:
                                            list.map<DropdownMenuItem<String>>((String value) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Align(
                                                  alignment: Alignment.centerLeft,
                                                  child: Text(
                                                    value,
                                                    style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(top: 15),
                                    child: Text(
                                      'No HP :',
                                      style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(left: 74, top: 15),
                                    child: Container(
                                      width: 300,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.white,
                                      ),
                                      child: TextField(
                                        maxLines: 1,
                                        controller: _noHp,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: <TextInputFormatter>[
                                          FilteringTextInputFormatter.digitsOnly,
                                        ],
                                        textInputAction: TextInputAction.done,
                                        textAlign: TextAlign.start,
                                        scrollPhysics: BouncingScrollPhysics(),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.only(left: 10, bottom: 7),
                                        ),
                                        style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(top: 15),
                                    child: Text(
                                      'Nama :',
                                      style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(left: 70, top: 15),
                                    child: Container(
                                      width: 300,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.white,
                                      ),
                                      child: TextField(
                                        maxLines: 1,
                                        controller: _namaTamu,
                                        keyboardType: TextInputType.text,
                                        textInputAction: TextInputAction.done,
                                        textAlign: TextAlign.start,
                                        scrollPhysics: BouncingScrollPhysics(),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.only(left: 10, bottom: 7),
                                        ),
                                        style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(top: 15),
                                    child: Text(
                                      'Jenis Pilihan :',
                                      style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(left: 14, top: 15),
                                        child: Container(
                                          width: 300,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                            color: Colors.white,
                                          ),
                                          child: DropdownButton<String>(
                                            value: _dropdownJenisPilihan,
                                            isExpanded: true,
                                            icon: const Icon(Icons.arrow_drop_down),
                                            elevation: 16,
                                            style: const TextStyle(color: Colors.deepPurple),
                                            underline: SizedBox(),
                                            padding: EdgeInsets.symmetric(horizontal: 10),
                                            onChanged: (String? value) {
                                              setState(() {
                                                _dropdownJenisPilihan = value;
                                                isbuttonvisible.value = true;
                                              });
                                            },
                                            items:
                                                listJenisPilihan.map<DropdownMenuItem<String>>((
                                                  String value,
                                                ) {
                                                  return DropdownMenuItem<String>(
                                                    value: value,
                                                    child: Align(
                                                      alignment: Alignment.centerLeft,
                                                      child: Text(
                                                        value,
                                                        style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                          ),
                                        ),
                                      ),
                                      if (_dropdownJenisPilihan == 'Showing')
                                        Obx(() {
                                          return isbuttonvisible.value
                                              ? Padding(
                                                padding: EdgeInsets.only(top: 15, left: 20),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Color(0XFFF6F7C4),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  height: 40,
                                                  width: 130,
                                                  child: TextButton(
                                                    onPressed: () {
                                                      daftarpanggilankerja('Showing Room', 'Semua Terapis');
                                                      // var c = Get.put(ControllerPanggilanKerja());
                                                      // c.refreshDataPanggilanKerja();
                                                      CherryToast.success(
                                                        title: Text('Notif berhasil dikirim'),
                                                      ).show(context);
                                                      isbuttonvisible.value = false;
                                                      controllerPekerja.statusshowing.value = 'pressed';
                                                    },
                                                    style: TextButton.styleFrom(
                                                      foregroundColor: Colors.black,
                                                    ),
                                                    child: Text(
                                                      'SEND NOTIF',
                                                      style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                    ),
                                                  ),
                                                ),
                                              )
                                              : SizedBox.shrink();
                                        }),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(top: 15),
                                    child: Text(
                                      'Terapis :',
                                      style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      Row(
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.only(left: 60, top: 15),
                                            child: Container(
                                              width: 300,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(10),
                                                color: Colors.white,
                                              ),
                                              child: TextField(
                                                readOnly: true,
                                                controller: txtTerapis,
                                                decoration: InputDecoration(
                                                  border: InputBorder.none,
                                                  contentPadding: EdgeInsets.symmetric(
                                                    vertical: 15,
                                                    horizontal: 10,
                                                  ),
                                                ),
                                                style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(top: 15, left: 20),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Color(0XFFF6F7C4),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              height: 40,
                                              width: 130,
                                              child: TextButton(
                                                onPressed: () {
                                                  if (_dropdownJenisPilihan == "Rolling") {
                                                    _showDialogTherapistRolling();
                                                  } else {
                                                    _showDialogTherapist();
                                                  }
                                                },
                                                style: TextButton.styleFrom(foregroundColor: Colors.black),
                                                child: Text(
                                                  'THERAPIST',
                                                  style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Obx(
                                        () =>
                                            ischecked.value == true
                                                ? Column(
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Padding(
                                                          padding: EdgeInsets.only(left: 60, top: 15),
                                                          child: Container(
                                                            width: 300,
                                                            height: 40,
                                                            decoration: BoxDecoration(
                                                              borderRadius: BorderRadius.circular(10),
                                                              color: Colors.white,
                                                            ),
                                                            child: TextField(
                                                              readOnly: true,
                                                              controller: txtTerapis2,
                                                              decoration: InputDecoration(
                                                                border: InputBorder.none,
                                                                contentPadding: EdgeInsets.symmetric(
                                                                  vertical: 15,
                                                                  horizontal: 10,
                                                                ),
                                                              ),
                                                              style: TextStyle(
                                                                fontSize: 18,
                                                                fontFamily: 'Poppins',
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding: EdgeInsets.only(top: 15, left: 20),
                                                          child: Container(
                                                            decoration: BoxDecoration(
                                                              color: Color(0XFFF6F7C4),
                                                              borderRadius: BorderRadius.circular(10),
                                                            ),
                                                            height: 40,
                                                            width: 130,
                                                            child: TextButton(
                                                              onPressed: () {
                                                                if (_dropdownJenisPilihan == "Rolling") {
                                                                  _showDialogTherapistRolling2();
                                                                } else {
                                                                  _showDialogTherapist2();
                                                                }
                                                              },
                                                              style: TextButton.styleFrom(
                                                                foregroundColor: Colors.black,
                                                              ),
                                                              child: Text(
                                                                'THERAPIST 2',
                                                                style: TextStyle(
                                                                  fontSize: 18,
                                                                  fontFamily: 'Poppins',
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Row(
                                                      children: [
                                                        Padding(
                                                          padding: EdgeInsets.only(left: 60, top: 15),
                                                          child: Container(
                                                            width: 300,
                                                            height: 40,
                                                            decoration: BoxDecoration(
                                                              borderRadius: BorderRadius.circular(10),
                                                              color: Colors.white,
                                                            ),
                                                            child: TextField(
                                                              readOnly: true,
                                                              controller: txtTerapis3,
                                                              decoration: InputDecoration(
                                                                border: InputBorder.none,
                                                                contentPadding: EdgeInsets.symmetric(
                                                                  vertical: 15,
                                                                  horizontal: 10,
                                                                ),
                                                              ),
                                                              style: TextStyle(
                                                                fontSize: 18,
                                                                fontFamily: 'Poppins',
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding: EdgeInsets.only(top: 15, left: 20),
                                                          child: Container(
                                                            decoration: BoxDecoration(
                                                              color: Color(0XFFF6F7C4),
                                                              borderRadius: BorderRadius.circular(10),
                                                            ),
                                                            height: 40,
                                                            width: 132,
                                                            child: TextButton(
                                                              onPressed: () {
                                                                if (_dropdownJenisPilihan == "Rolling") {
                                                                  _showDialogTherapistRolling3();
                                                                } else {
                                                                  _showDialogTherapist3();
                                                                }
                                                              },
                                                              style: TextButton.styleFrom(
                                                                foregroundColor: Colors.black,
                                                              ),
                                                              child: Text(
                                                                'THERAPIST 3',
                                                                style: TextStyle(
                                                                  fontSize: 18,
                                                                  fontFamily: 'Poppins',
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                )
                                                : SizedBox.shrink(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(top: 15),
                                    child: Text(
                                      'Room :',
                                      style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(left: 75, top: 15),
                                        child: Container(
                                          width: 300,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                            color: Colors.white,
                                          ),
                                          child: TextField(
                                            controller: txtRoom,
                                            readOnly: true,
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.symmetric(
                                                vertical: 15,
                                                horizontal: 10,
                                              ),
                                            ),
                                            style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(top: 15, left: 20),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Color(0XFFF6F7C4),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          height: 40,
                                          width: 130,
                                          child: TextButton(
                                            onPressed: () {
                                              _showDialogRoom();
                                            },
                                            style: TextButton.styleFrom(foregroundColor: Colors.black),
                                            child: Text(
                                              'ROOM',
                                              style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(top: 15),
                                    child: Text(
                                      'GRO :',
                                      style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(left: 88, top: 15),
                                        child: Container(
                                          width: 300,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                            color: Colors.white,
                                          ),
                                          child: TextField(
                                            readOnly: true,
                                            controller: txtGRO,
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.symmetric(
                                                vertical: 15,
                                                horizontal: 10,
                                              ),
                                            ),
                                            style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(top: 15, left: 20),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Color(0XFFF6F7C4),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          height: 40,
                                          width: 130,
                                          child: TextButton(
                                            onPressed: () {
                                              _showDialogGRO();
                                            },
                                            style: TextButton.styleFrom(foregroundColor: Colors.black),
                                            child: Text(
                                              'GRO',
                                              style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              //  BAGIAN UNTUK MENGAKTIFKAN SELURUH FUNGSI KTV 3 TERAPIS
                              Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(top: 15),
                                    child: Text(
                                      'TRANSAKSI KTV',
                                      style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(top: 13, left: 20),
                                    width: 20,
                                    height: 20,
                                    child: Obx(
                                      () => Checkbox(
                                        value: ischecked.value,
                                        onChanged: (bool? newvalue) {
                                          if (ischecked.value == true) {
                                            txtTerapis2.clear();
                                            txtTerapis3.clear();
                                            controllerPekerja.getidterapis2.value = '';
                                            controllerPekerja.getidterapis3.value = '';
                                          }
                                          ischecked.value = newvalue!;
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Kolom Kedua
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                'Detail Member :',
                                style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: Colors.white,
                                ),
                                width: 460,
                                height: 280,
                                child:
                                    historyMember.isEmpty
                                        ? Center(
                                          child: Text(
                                            "Silahkan Scan QR Terlebih Dahulu",
                                            style: TextStyle(fontFamily: 'Poppins'),
                                          ),
                                        )
                                        : ListView.builder(
                                          itemCount: historyMember.length,
                                          itemBuilder: (context, index) {
                                            final item = historyMember[index];
                                            return Column(
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(
                                                    vertical: 4.0,
                                                    horizontal: 8.0,
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Container(
                                                            width: 100,
                                                            height: 25,
                                                            child: Text(
                                                              'Nama Promo',
                                                              style: TextStyle(
                                                                fontFamily: 'Poppins',
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(width: 70),
                                                          Container(
                                                            width: 120,
                                                            height: 25,
                                                            child: Text(
                                                              'Sisa Kunjungan',
                                                              style: TextStyle(
                                                                fontFamily: 'Poppins',
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(width: 24),
                                                          Container(
                                                            width: 130,
                                                            height: 25,
                                                            child: Text(
                                                              'Berlaku Sampai',
                                                              style: TextStyle(
                                                                fontFamily: 'Poppins',
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Divider(thickness: 1, color: Colors.black, height: 1),
                                                      Row(
                                                        children: [
                                                          Container(
                                                            width: 160,
                                                            child: Text(
                                                              item['nama_promo'] ?? '',
                                                              style: TextStyle(fontFamily: 'Poppins'),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: 25,
                                                            child: Text(
                                                              "|",
                                                              textAlign: TextAlign.left,
                                                              style: TextStyle(fontSize: 21),
                                                            ),
                                                          ),
                                                          Container(
                                                            width: 90,
                                                            child: Text(
                                                              item['sisa_kunjungan'] != null &&
                                                                      item['sisa_kunjungan'] != ''
                                                                  ? '${item['sisa_kunjungan']} Kali'
                                                                  : '',
                                                              style: TextStyle(fontFamily: 'Poppins'),
                                                              textAlign: TextAlign.center,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: 55,
                                                            child: Text(
                                                              "|",
                                                              textAlign: TextAlign.center,
                                                              style: TextStyle(fontSize: 21),
                                                            ),
                                                          ),
                                                          Container(
                                                            width: 90,
                                                            child: Text(
                                                              item['exp_kunjungan'] != null &&
                                                                      item['exp_kunjungan'] != ''
                                                                  ? '${item['exp_kunjungan']}'
                                                                  : '',
                                                              style: TextStyle(fontFamily: 'Poppins'),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Divider(thickness: 1, color: Colors.grey.shade300, height: 1),
                                              ],
                                            );
                                          },
                                        ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: Color(0XCCCDFADB),
                                ),
                                height: 100,
                                width: 460,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => QRScannerScreen(onScannedData: _updateFields),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(foregroundColor: Colors.black),
                                  child: Text(
                                    'SCAN QR',
                                    style: TextStyle(fontSize: 30, fontFamily: 'Poppins'),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    Padding(
                      padding: EdgeInsets.only(left: 100, top: 30, right: 100),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Color(0XFFF6F7C4),
                            ),
                            height: 120,
                            width: 400,
                            child: TextButton(
                              onPressed: () {
                                _updateLastTrans().then((_) {
                                  controllerPekerja.getnotrans.value = _txtIdTrans.text;
                                  controllerPekerja.getroom.value = txtRoom.text;
                                  Get.to(
                                    () => DetailPaketMassage(
                                      idTrans: idTrans,
                                      activePromos: _activePromos,
                                      idMember: idMember,
                                      namaRoom: txtRoom.text,
                                      statusTamu: dropdownValue,
                                    ),
                                  );
                                });
                              },
                              style: TextButton.styleFrom(foregroundColor: Colors.black),
                              child: Text(
                                'Pilih Paket',
                                style: TextStyle(fontSize: 40, fontFamily: 'Poppins'),
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Color(0XCCCDFADB),
                            ),
                            height: 120,
                            width: 400,
                            child: TextButton(
                              onPressed: () {
                                Get.to(() => DaftarMember());
                              },
                              style: TextButton.styleFrom(foregroundColor: Colors.black),
                              child: Text(
                                'Daftar Member',
                                style: TextStyle(fontSize: 40, fontFamily: 'Poppins'),
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
          ),
        ),
      ),
    );
  }
}
