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
    txtTerapis2.clear();
    txtTerapis3.clear();
    controllerPekerja.getidterapis2.value = '';
    controllerPekerja.getidterapis3.value = '';
    super.dispose();
  }

  List<dynamic> historyMember = [];

  Future<void> _fetchHistoryMember(String id_member) async {
    try {
      final response = await dio.get('${myIpAddr()}/history/historymemberkunjungan/$id_member');

      if (response.statusCode == 200) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        setState(() {
          historyMember =
              (response.data as List).map((raw) {
                final Map<String, dynamic> item = Map<String, dynamic>.from(raw);

                String expLabel = '';
                final expStr = item['exp_kunjungan']?.toString() ?? '';

                if (expStr.isNotEmpty) {
                  final expDate = DateTime.tryParse(expStr);
                  if (expDate != null) {
                    final expOnlyDate = DateTime(expDate.year, expDate.month, expDate.day);

                    // kalau lewat hari ini -> Expired
                    expLabel = expOnlyDate.isBefore(today) ? 'Expired' : '';
                  }
                }

                // gabungkan tanggal + label
                // contoh: "2026-07-03 (Expired)" atau cuma "2026-07-03"
                final labelExpired = expLabel.isNotEmpty ? '$expStr ($expLabel)' : expStr;

                item['exp_kunjungan_label'] = labelExpired;
                return item;
              }).toList();
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
      final today = DateTime(now.year, now.month, now.day);

      setState(() {
        _activePromos =
            (response.data as List)
                .where((promo) {
                  // ---- cek sisa kunjungan ----
                  final sisa = int.tryParse(promo['sisa_kunjungan']?.toString() ?? '0') ?? 0;
                  if (sisa <= 0) return false; // kalau sisa 0, tidak bisa apply

                  // ---- cek exp_kunjungan ----
                  final expKunjungan = promo['exp_kunjungan'];
                  if (expKunjungan != null && expKunjungan.toString().isNotEmpty) {
                    final expDate = DateTime.tryParse(expKunjungan.toString());
                    if (expDate != null) {
                      final expOnlyDate = DateTime(expDate.year, expDate.month, expDate.day);

                      // sama dengan kondisi: exp_kunjungan >= CURDATE()
                      final isExpired = expOnlyDate.isBefore(today);

                      // hanya include kalau belum expired
                      return !isExpired;
                    }
                  }
                  return false; // kalau tanggal tidak valid / null -> anggap tidak bisa dipakai
                })
                .map<Map<String, dynamic>>((promo) {
                  // bikin label buat ditampilkan di UI (Expired / tanggal)
                  String expLabel = '';
                  final expStr = promo['exp_kunjungan']?.toString() ?? '';
                  if (expStr.isNotEmpty) {
                    final expDate = DateTime.tryParse(expStr);
                    if (expDate != null) {
                      final expOnlyDate = DateTime(expDate.year, expDate.month, expDate.day);
                      expLabel = expOnlyDate.isBefore(today) ? 'Expired' : expStr;
                    } else {
                      expLabel = expStr;
                    }
                  }

                  return {
                    'kode_promo': promo['kode_promo'],
                    'nama_promo': promo['nama_promo'],
                    'nama_paket_msg': promo['nama_paket_msg'],
                    'sisa_kunjungan': promo['sisa_kunjungan'],
                    'exp_kunjungan': promo['exp_kunjungan'],
                    'exp_kunjungan_label': expLabel, // <-- bisa dipakai di Text()
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
    // Variable untuk merapikan lebar label input (agar titik dua sejajar)
    const double labelWidth = 140.0;

    return WillPopScope(
      onWillPop: () async {
        try {
          bool isDeleted = await removeIdDraft();
          return isDeleted;
        } catch (e) {
          CherryToast.error(
            title: const Text("Error"),
            description: Text("Gagal Remove Id Draft $e"),
          ).show(Get.context!);
          return false;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: IconButton(
              icon: Icon(Icons.arrow_back, size: 40),
              onPressed: () async {
                bool isDeleted = await removeIdDraft();
                if (isDeleted) Get.back();
              },
            ),
          ),
          title: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('Transaksi Massage', style: TextStyle(fontSize: 60, fontFamily: 'Poppins')),
          ),
          centerTitle: true,
          toolbarHeight: 130,
          leadingWidth: 100,
          backgroundColor: Color(0XFFFFE0B2),
          automaticallyImplyLeading: false,
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
          child: SingleChildScrollView(
            // Padding keseluruhan layar
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              children: [
                // ============================================================
                // BAGIAN 1: SPLIT SCREEN (KIRI: FORM, KANAN: MEMBER INFO)
                // ============================================================
                Obx(
                  () => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- KOLOM KIRI (FORM INPUT) ---
                      Expanded(
                        flex: 6, // Lebar 60%
                        child: Column(
                          children: [
                            _buildInputRow(
                              label: 'No Transaksi :',
                              controller: _txtIdTrans,
                              labelWidth: labelWidth,
                              readOnly: true,
                            ),
                            SizedBox(height: 15),
                            _buildInputRow(
                              label: 'No Locker :',
                              controller: _txtNoLocker,
                              labelWidth: labelWidth,
                            ),
                            SizedBox(height: 15),

                            // Dropdown Jenis Tamu
                            _buildCustomRow(
                              label: 'Jenis Tamu :',
                              labelWidth: labelWidth,
                              child: DropdownButton<String>(
                                value: dropdownValue,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down),
                                underline: SizedBox(),
                                onChanged: (String? value) {
                                  setState(() {
                                    dropdownValue = value;
                                  });
                                },
                                items:
                                    list.map<DropdownMenuItem<String>>((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(
                                          value,
                                          style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ),
                            SizedBox(height: 15),

                            _buildInputRow(
                              label: 'No HP :',
                              controller: _noHp,
                              labelWidth: labelWidth,
                              isNumber: true,
                            ),
                            SizedBox(height: 15),
                            _buildInputRow(label: 'Nama :', controller: _namaTamu, labelWidth: labelWidth),
                            SizedBox(height: 15),

                            // Dropdown Jenis Pilihan & Tombol Show
                            Row(
                              children: [
                                SizedBox(
                                  width: labelWidth,
                                  child: Text(
                                    'Jenis Pilihan :',
                                    style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Container(
                                          height: 40,
                                          padding: EdgeInsets.symmetric(horizontal: 10),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                            color: Colors.white,
                                          ),
                                          child: DropdownButton<String>(
                                            value: _dropdownJenisPilihan,
                                            isExpanded: true,
                                            underline: SizedBox(),
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
                                                    child: Text(
                                                      value,
                                                      style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                                    ),
                                                  );
                                                }).toList(),
                                          ),
                                        ),
                                      ),
                                      if (_dropdownJenisPilihan == 'Showing') ...[
                                        SizedBox(width: 10),
                                        Obx(
                                          () =>
                                              isbuttonvisible.value
                                                  ? Container(
                                                    height: 40,
                                                    child: ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Color(0XFFF6F7C4),
                                                        foregroundColor: Colors.black,
                                                      ),
                                                      onPressed: () {
                                                        daftarpanggilankerja('Showing Room', 'Semua Terapis');
                                                        CherryToast.success(
                                                          title: Text('Notif berhasil dikirim'),
                                                        ).show(context);
                                                        isbuttonvisible.value = false;
                                                        controllerPekerja.statusshowing.value = 'pressed';
                                                      },
                                                      child: Text(
                                                        'SEND NOTIF',
                                                        style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                                                      ),
                                                    ),
                                                  )
                                                  : SizedBox.shrink(),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 15),

                            // Terapis 1
                            _buildButtonInputRow(
                              label: 'Terapis :',
                              labelWidth: labelWidth,
                              controller: txtTerapis,
                              buttonText: 'THERAPIST',
                              onPressed:
                                  () =>
                                      _dropdownJenisPilihan == "Rolling"
                                          ? _showDialogTherapistRolling()
                                          : _showDialogTherapist(),
                            ),

                            // Terapis 2 & 3 (Conditional)
                            if (ischecked.value) ...[
                              SizedBox(height: 15),
                              _buildButtonInputRow(
                                label: '', // Kosongkan label agar sejajar
                                labelWidth: labelWidth,
                                controller: txtTerapis2,
                                buttonText: 'THERAPIST 2',
                                onPressed:
                                    () =>
                                        _dropdownJenisPilihan == "Rolling"
                                            ? _showDialogTherapistRolling2()
                                            : _showDialogTherapist2(),
                              ),
                              SizedBox(height: 15),
                              _buildButtonInputRow(
                                label: '',
                                labelWidth: labelWidth,
                                controller: txtTerapis3,
                                buttonText: 'THERAPIST 3',
                                onPressed:
                                    () =>
                                        _dropdownJenisPilihan == "Rolling"
                                            ? _showDialogTherapistRolling3()
                                            : _showDialogTherapist3(),
                              ),
                            ],

                            SizedBox(height: 15),
                            // Room
                            _buildButtonInputRow(
                              label: 'Room :',
                              labelWidth: labelWidth,
                              controller: txtRoom,
                              buttonText: 'ROOM',
                              onPressed: () => _showDialogRoom(),
                            ),

                            SizedBox(height: 15),
                            // GRO
                            _buildButtonInputRow(
                              label: 'GRO :',
                              labelWidth: labelWidth,
                              controller: txtGRO,
                              buttonText: 'GRO',
                              onPressed: () => _showDialogGRO(),
                            ),

                            SizedBox(height: 15),
                            // Transaksi KTV Checkbox
                            Row(
                              children: [
                                SizedBox(
                                  width: labelWidth,
                                  child: Text(
                                    'TRANSAKSI KTV',
                                    style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                  ),
                                ),
                                Obx(
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
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: 20), // Jarak antara Form dan Info Member
                      // --- KOLOM KANAN (INFO MEMBER & SCAN QR) ---
                      Expanded(
                        flex: 4, // Lebar 40%
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Detail Member :', style: TextStyle(fontSize: 18, fontFamily: 'Poppins')),
                            SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              height: 280,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: Colors.white,
                              ),
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
                                              ListTile(
                                                title: Text(
                                                  item['nama_promo'] ?? '',
                                                  style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
                                                ),
                                                trailing: Wrap(
                                                  spacing: 12,
                                                  children: [
                                                    Text(
                                                      item['sisa_kunjungan'] != null
                                                          ? '${item['sisa_kunjungan']} Kali'
                                                          : '',
                                                      style: TextStyle(fontSize: 12),
                                                    ),
                                                    Text("|"),
                                                    Text(
                                                      item['exp_kunjungan_label'] ?? '',
                                                      style: TextStyle(fontSize: 12),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Divider(height: 1),
                                            ],
                                          );
                                        },
                                      ),
                            ),
                            SizedBox(height: 10),
                            // Tombol Scan QR (Tetap di kanan)
                            Container(
                              width: double.infinity,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: Color(0XCCCDFADB),
                              ),
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => QRScannerScreen(onScannedData: _updateFields),
                                    ),
                                  );
                                },
                                child: Text(
                                  'SCAN QR',
                                  style: TextStyle(fontSize: 24, fontFamily: 'Poppins', color: Colors.black),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 40), // Jarak Pemisah Bagian Atas dan Bawah
                // ============================================================
                // BAGIAN 2: TOMBOL BAWAH (PILIH PAKET & DAFTAR MEMBER)
                // ============================================================
                // Padding digunakan agar tombol tidak terlalu mepet pinggir layar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Tombol 1: Pilih Paket
                      Expanded(
                        child: Container(
                          height: 120, // Tinggi tetap
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Color(0XFFF6F7C4),
                          ),
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
                            // FittedBox agar font 40 otomatis mengecil di layar sempit
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Pilih Paket',
                                style: TextStyle(fontSize: 40, fontFamily: 'Poppins'),
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: 30), // Jarak antar tombol
                      // Tombol 2: Daftar Member
                      Expanded(
                        child: Container(
                          height: 120, // Tinggi tetap
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Color(0XCCCDFADB),
                          ),
                          child: TextButton(
                            onPressed: () {
                              Get.to(() => DaftarMember());
                            },
                            style: TextButton.styleFrom(foregroundColor: Colors.black),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Daftar Member',
                                style: TextStyle(fontSize: 40, fontFamily: 'Poppins'),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20), // Jarak aman bawah
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPER (PASTE DI BAGIAN BAWAH CLASS ANDA) ---

  Widget _buildInputRow({
    required String label,
    required TextEditingController controller,
    required double labelWidth,
    bool readOnly = false,
    bool isNumber = false,
  }) {
    return Row(
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(label, style: TextStyle(fontSize: 18, fontFamily: 'Poppins')),
        ),
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white),
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              keyboardType: isNumber ? TextInputType.number : TextInputType.text,
              inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              ),
              style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomRow({required String label, required double labelWidth, required Widget child}) {
    return Row(
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(label, style: TextStyle(fontSize: 18, fontFamily: 'Poppins')),
        ),
        Expanded(
          child: Container(
            height: 40,
            padding: EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white),
            child: child,
          ),
        ),
      ],
    );
  }

  Widget _buildButtonInputRow({
    required String label,
    required double labelWidth,
    required TextEditingController controller,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Row(
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(label, style: TextStyle(fontSize: 18, fontFamily: 'Poppins')),
        ),
        Expanded(
          flex: 2,
          child: Container(
            height: 40,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white),
            child: TextField(
              controller: controller,
              readOnly: true,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              ),
              style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
            ),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          flex: 1,
          child: Container(
            height: 40,
            decoration: BoxDecoration(color: Color(0XFFF6F7C4), borderRadius: BorderRadius.circular(10)),
            child: TextButton(
              onPressed: onPressed,
              style: TextButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: Colors.black),
              child: FittedBox(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(buttonText, style: TextStyle(fontSize: 16, fontFamily: 'Poppins')),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
