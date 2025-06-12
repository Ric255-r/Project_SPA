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
import 'package:Project_SPA/admin/regis_users.dart';
import 'package:Project_SPA/function/admin_drawer.dart';
import 'package:Project_SPA/function/ip_address.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:Project_SPA/resepsionis/billing_locker.dart';
import 'package:Project_SPA/resepsionis/jenis_transaksi.dart';
import 'package:Project_SPA/main.dart';
import 'package:dio/dio.dart';

const List<String> list = <String>['Fasilitas', 'VIP', 'Reguler'];
String? _dropdownValue;
const List<String> _listStatus = <String>[
  'aktif',
  'maintenance',
  // "non aktif",
  // "dalam perbaikan",
];
String? _dropdownStatus;

class RegisRoom extends StatefulWidget {
  const RegisRoom({super.key});

  @override
  State<RegisRoom> createState() => _RegisRoomState();
}

class _RegisRoomState extends State<RegisRoom> {
  var dio = Dio();
  var txtNamaRuangan = TextEditingController();
  var txtLantaiRuangan = TextEditingController();
  var txtJenisRuangan = TextEditingController();
  var txtKodeRuangan = TextEditingController();
  var txtPassRuangan = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getIdRoom();
    _dropdownValue = null;
    _dropdownStatus = null;
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    txtNamaRuangan.dispose();
    txtLantaiRuangan.dispose();
    txtKodeRuangan.dispose();
    txtPassRuangan.dispose();
  }

  Future<void> _getIdRoom() async {
    try {
      var response = await dio.get('${myIpAddr()}/room/idroom');

      if (response.statusCode == 200 && response.data != null) {
        setState(() {
          txtKodeRuangan.text =
              response.data
                  .toString()
                  .trim(); // Update TextField with id_karyawan
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching ID: ${response.statusCode}")),
        );
      }
    } catch (e) {
      print("Error fetching ID: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error fetching ID")));
    }
  }

  Future<bool> _isRoomNameAvailable(String nama_ruangan) async {
    try {
      // Trim the room name to remove spaces
      String trimmedName = nama_ruangan.trim();

      if (trimmedName.isEmpty) {
        log("Room name cannot be empty!");
        CherryToast.warning(
          title: Text("Nama ruang tidak boleh kosong!"),
        ).show(context);
        return false; // Reject empty names
      }

      // Send the full room name to the backend
      var response = await dio.get(
        '${myIpAddr()}/room/check_room/$trimmedName',
        // Full room name
      );

      // Check the backend response
      if (response.data["exists"] == true) {
        return false; // Room name already exists
      } else {
        return true; // Room name is available
      }
    } catch (e) {
      log("Error checking room name availability: $e");
      return false; // Assume unavailable in case of error
    }
  }

  Future<void> _storeRoom() async {
    try {
      var response = await dio.post(
        '${myIpAddr()}/room/post_room',
        data: {
          "nama_ruangan": txtNamaRuangan.text,
          "kode_ruangan": txtKodeRuangan.text,
          "lantai": int.parse(txtLantaiRuangan.text),
          "jenis_ruangan": _dropdownValue!,
          "status": _dropdownStatus!,
          "passwd": txtPassRuangan.text,
          "hak_akses": "7",
        },
      );

      CherryToast.success(
        title: Text("Ruang '${txtNamaRuangan.text}' berhasil disimpan!"),
      ).show(context);
      txtNamaRuangan.clear();
      txtLantaiRuangan.clear();
      txtKodeRuangan.clear();
      txtPassRuangan.clear();
      _dropdownValue = null; // Reset dropdown if needed
      _dropdownStatus = null;
      _getIdRoom();

      log('Successfully stored room');
    } catch (e) {
      log("Error storing room: $e");
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
                padding: EdgeInsets.only(top: 20),
                child: Text(
                  'Daftar Room',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(top: 50),
                child: Container(
                  height: 270,
                  width: 710,
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
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(15),
                                  bottomLeft: Radius.circular(15),
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.only(right: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    SizedBox(height: 15),
                                    Text(
                                      'Nama Kamar :',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 18,
                                      ),
                                    ),
                                    SizedBox(height: 15),
                                    Text(
                                      'Kode Kamar :',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 18,
                                      ),
                                    ),
                                    SizedBox(height: 15),
                                    Text(
                                      'Lantai :',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 18,
                                      ),
                                    ),
                                    SizedBox(height: 15),
                                    Text(
                                      'Jenis Kamar :',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 18,
                                      ),
                                    ),
                                    SizedBox(height: 15),
                                    Text(
                                      'Status :',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 18,
                                      ),
                                    ),
                                    SizedBox(height: 15),
                                    Text(
                                      'Password Kamar :',
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
                            width: 500,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(15),
                                bottomRight: Radius.circular(15),
                              ),
                            ),
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
                                      controller: txtNamaRuangan,
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
                                  SizedBox(height: 11),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    width: 480,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey[300],
                                    ),
                                    child: TextField(
                                      controller: txtKodeRuangan,
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
                                  SizedBox(height: 11),
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
                                      controller: txtLantaiRuangan,
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
                                  SizedBox(height: 11),
                                  Container(
                                    width: 480,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey[300],
                                    ),
                                    child: DropdownButton<String>(
                                      value: _dropdownValue,
                                      isExpanded: true,
                                      icon: const Icon(Icons.arrow_drop_down),
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
                                          _dropdownValue = value;
                                        });
                                      },
                                      items:
                                          list.map<DropdownMenuItem<String>>((
                                            String value,
                                          ) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  value,
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
                                  SizedBox(height: 11),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    width: 480,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey[300],
                                    ),
                                    child: DropdownButton<String>(
                                      value: _dropdownStatus,
                                      isExpanded: true,
                                      icon: const Icon(Icons.arrow_drop_down),
                                      elevation: 14,
                                      style: const TextStyle(
                                        color: Colors.deepPurple,
                                      ),
                                      underline: SizedBox(),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      onChanged: (String? value) {
                                        setState(() {
                                          _dropdownStatus = value;
                                        });
                                      },
                                      items:
                                          _listStatus.map<
                                            DropdownMenuItem<String>
                                          >((String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  value,
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
                                  SizedBox(height: 11),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    width: 480,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey[300],
                                    ),
                                    child: TextField(
                                      controller: txtPassRuangan,
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
              SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Color(0XFFF6F7C4),
                ),
                height: 70,
                width: 300,
                child: TextButton(
                  onPressed: () async {
                    String roomName = txtNamaRuangan.text.trim();
                    String lantaiRoom = txtLantaiRuangan.text.trim();
                    bool isAvailable = await _isRoomNameAvailable(roomName);
                    if (roomName.isEmpty && context.mounted) {
                      CherryToast.warning(
                        title: Text("Nama ruang tidak boleh kosong!"),
                      ).show(context);
                    } else if (lantaiRoom.isEmpty && context.mounted) {
                      CherryToast.warning(
                        title: Text('Lantai ruang tidak boleh kosong!'),
                      ).show(context);
                    } else if (!isAvailable && context.mounted) {
                      log("Mati");
                      CherryToast.error(
                        title: Text(
                          "Nama ruang '${txtNamaRuangan.text}' sudah ada!",
                        ),
                      ).show(context);
                      return;
                    } else {
                      await _storeRoom();

                      setState(() {
                        _getIdRoom();
                      });
                    }

                    // Proceed to save the room
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.black),
                  child: Text(
                    'Simpan',
                    style: TextStyle(fontSize: 40, fontFamily: 'Poppins'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      drawer: AdminDrawer(),
    );
  }
}
