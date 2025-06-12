import 'dart:developer';
import 'dart:io';

// import 'package:Project_SPA/admin/laporan_ob.dart';
import 'package:Project_SPA/admin/listpaket.dart';
import 'package:Project_SPA/admin/listpekerja.dart';
import 'package:Project_SPA/admin/listpromo.dart';
import 'package:Project_SPA/admin/listroom.dart';
import 'package:Project_SPA/admin/listuser.dart';
import 'package:Project_SPA/admin/regis_locker.dart';
import 'package:Project_SPA/admin/regis_paket.dart';
import 'package:Project_SPA/admin/regis_promo.dart';
import 'package:Project_SPA/admin/regis_room.dart';
import 'package:Project_SPA/admin/regis_users.dart';
import 'package:Project_SPA/function/admin_drawer.dart';
import 'package:Project_SPA/function/ip_address.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:Project_SPA/resepsionis/billing_locker.dart';
import 'package:Project_SPA/resepsionis/jenis_transaksi.dart';
import 'package:Project_SPA/main.dart';

const List<String> list = <String>[
  'admin',
  'resepsionis',
  'supervisor',
  'terapis',
  'gro',
  'office boy',
  'kitchen',
];
String? dropdownValue;

const List<String> listJK = <String>['Laki-Laki', 'Perempuan'];
const List<String> listStatus = <String>['Aktif', "Non Aktif"];
String? dropdownJK;
String? dropdownStatus;

class RegisPekerja extends StatefulWidget {
  const RegisPekerja({super.key});

  @override
  State<RegisPekerja> createState() => _RegisPekerjaState();
}

class _RegisPekerjaState extends State<RegisPekerja> {
  List<PlatformFile> selectedFiles = [];
  final TextEditingController _textController = TextEditingController();
  var dio = Dio();
  var txtNik = TextEditingController();
  var txtNamaKaryawan = TextEditingController();
  var txtAlamat = TextEditingController();
  var txtNoHP = TextEditingController();
  var txtumur = TextEditingController();

  bool isSeninChecked = false;
  bool isSelasaChecked = false;
  bool isRabuChecked = false;
  bool isKamisChecked = false;
  bool isJumatChecked = false;
  bool isSabtuChecked = false;
  bool isMingguChecked = false;

  bool pilihHariKerja = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _clearForm();
    selectedFiles.clear();
    dropdownValue = null;
    dropdownJK = null;
    dropdownStatus = null;
    selectedJK = null;
    selectedStatus = null;
    selectedJabatan = null;
    selectedFiles.clear();
  }

  String? selectedJK;
  String? selectedStatus;
  String? selectedJabatan;

  Future<void> _storePekerja() async {
    try {
      var formData = FormData();

      formData.fields.addAll([
        MapEntry('id_karyawan', _textController.text),
        MapEntry('nik', txtNik.text),
        MapEntry('nama_karyawan', txtNamaKaryawan.text),
        MapEntry('alamat', txtAlamat.text),
        MapEntry('jk', selectedJK ?? ''),
        MapEntry('no_hp', txtNoHP.text),
        MapEntry('jabatan', selectedJabatan ?? ''),
        MapEntry('status', selectedStatus ?? ''),
      ]);

      if (selectedFiles.isNotEmpty) {
        for (var file in selectedFiles) {
          if (file.bytes != null) {
            formData.files.add(
              MapEntry(
                'kontrak_img',
                await MultipartFile.fromBytes(file.bytes!, filename: file.name),
              ),
            );
          } else {
            log('⚠️ Skipping file: ${file.name} has null bytes');
          }
        }
      }

      var response = await dio.post(
        '${myIpAddr()}/pekerja/post_pekerja',
        data: formData,
      );

      if (response.statusCode == 200) {
        log('Data saved successfully!');
        CherryToast.success(
          title: Text('Data berhasil disimpan'),
        ).show(context);
        selectedFiles.clear();
        setState(() {});
        _clearForm();
        setState(() {
          dropdownJK = null;
          dropdownValue = null;
          dropdownStatus = null;
        }); // Clear the form after successful submission
      } else {
        log("Failed to save data: \${response.statusCode}");
      }
    } catch (e, stackTrace) {
      log("LOG TEST");
      log("Error saving data: $e");
      log("Stacktrace: $stackTrace");
      CherryToast.error(
        title: Text('Terjadi kesalahan saat menyimpan data'),
        description: Text(e.toString()), // Show actual error in the toast
      ).show(context);
    }
  }

  File? kontrakFile;
  String? kontrakFileName;

  Future<void> pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (result != null) {
      setState(() {
        selectedFiles = result.files;
      });
    }
  }

  Future<void> _storeOB() async {
    try {
      var formData = FormData();

      // Add regular text fields
      formData.fields.addAll([
        MapEntry('id_karyawan', _textController.text),
        MapEntry('nik', txtNik.text),
        MapEntry('nama_karyawan', txtNamaKaryawan.text),
        MapEntry('alamat', txtAlamat.text),
        MapEntry('jk', dropdownJK ?? ''),
        MapEntry('no_hp', txtNoHP.text),
        MapEntry('jabatan', dropdownValue ?? ''),
        MapEntry('status', dropdownStatus ?? ''),
        MapEntry('senin', isSeninChecked ? '1' : '0'),
        MapEntry('selasa', isSelasaChecked ? '1' : '0'),
        MapEntry('rabu', isRabuChecked ? '1' : '0'),
        MapEntry('kamis', isKamisChecked ? '1' : '0'),
        MapEntry('jumat', isJumatChecked ? '1' : '0'),
        MapEntry('sabtu', isSabtuChecked ? '1' : '0'),
        MapEntry('minggu', isMingguChecked ? '1' : '0'),
      ]);

      // Add kontrak_img file only if selectedFiles has valid content
      if (selectedFiles.isNotEmpty) {
        for (var file in selectedFiles) {
          if (file.bytes != null) {
            formData.files.add(
              MapEntry(
                'kontrak_img',
                await MultipartFile.fromBytes(file.bytes!, filename: file.name),
              ),
            );
          } else {
            log('⚠️ Skipping file: ${file.name} has null bytes');
          }
        }
      }

      // Send request
      var response = await dio.post(
        '${myIpAddr()}/pekerja/post_ob',
        data: formData,
      );

      if (response.statusCode == 200) {
        log('Data saved successfully!');
        CherryToast.success(
          title: Text('Data berhasil disimpan'),
        ).show(context);
        _clearForm();
        setState(() {
          dropdownJK = null;
          dropdownValue = null;
          dropdownStatus = null;
        }); // Clear the form after successful submission
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

  Future<void> _storeTerapis() async {
    try {
      var formData = FormData();

      // Add text fields
      formData.fields.addAll([
        MapEntry('id_karyawan', _textController.text),
        MapEntry('nik', txtNik.text),
        MapEntry('nama_karyawan', txtNamaKaryawan.text),
        MapEntry('alamat', txtAlamat.text),
        MapEntry('jk', dropdownJK ?? ''),
        MapEntry('no_hp', txtNoHP.text),
        MapEntry('jabatan', dropdownValue ?? ''),
        MapEntry('status', dropdownStatus ?? ''),
        MapEntry('senin', isSeninChecked ? '1' : '0'),
        MapEntry('selasa', isSelasaChecked ? '1' : '0'),
        MapEntry('rabu', isRabuChecked ? '1' : '0'),
        MapEntry('kamis', isKamisChecked ? '1' : '0'),
        MapEntry('jumat', isJumatChecked ? '1' : '0'),
        MapEntry('sabtu', isSabtuChecked ? '1' : '0'),
        MapEntry('minggu', isMingguChecked ? '1' : '0'),
      ]);

      // Add kontrak_img if a file is selected
      if (selectedFiles.isNotEmpty) {
        for (var file in selectedFiles) {
          if (file.bytes != null) {
            formData.files.add(
              MapEntry(
                'kontrak_img',
                await MultipartFile.fromBytes(file.bytes!, filename: file.name),
              ),
            );
          } else {
            log('⚠️ Skipping file: ${file.name} has null bytes');
          }
        }
      }

      // Send the POST request
      var response = await dio.post(
        '${myIpAddr()}/pekerja/post_terapis',
        data: formData,
      );

      if (response.statusCode == 200) {
        log('Data saved successfully!');
        CherryToast.success(
          title: Text('Data berhasil disimpan'),
        ).show(context);
        _clearForm();
        setState(() {
          dropdownJK = null;
          dropdownValue = null;
          dropdownStatus = null;
        });
      } else {
        log("Failed to save data: ${response.statusCode}");
      }
    } catch (e, stackTrace) {
      log("LOG TEST");
      log("Error saving data: $e");
      log("Stacktrace: $stackTrace");
      CherryToast.error(
        title: Text('Terjadi kesalahan saat menyimpan data'),
        description: Text(e.toString()),
      ).show(context);
    }
  }

  void _submit() {
    if (txtNik.text.isEmpty) {
      // Show an alert if the TextField is empty
      CherryToast.warning(title: Text('NIK tidak boleh kosong!')).show(context);
    } else {
      _storePekerja();
    }
  }

  void _clearForm() {
    _textController.clear();
    txtNik.clear();
    txtNamaKaryawan.clear();
    txtAlamat.clear();
    txtNoHP.clear();
    isSeninChecked = false;
    isSelasaChecked = false;
    isRabuChecked = false;
    isKamisChecked = false;
    isJumatChecked = false;
    isSabtuChecked = false;
    isMingguChecked = false;
    selectedFiles.clear();
  }

  Future<void> _fetchIdKaryawan(String jabatan) async {
    try {
      final response = await dio.get(
        '${myIpAddr()}/pekerja/getIdKaryawan/$jabatan',
      ); // API request
      if (response.statusCode == 200) {
        setState(() {
          _textController.text =
              response.data; // Update TextField with id_karyawan
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

  @override
  void dispose() {
    // TODO: implement dispose
    _textController.clear();
    txtumur.dispose();
    txtNik.dispose();
    txtNamaKaryawan.dispose();
    txtAlamat.dispose();
    txtNoHP.dispose();

    super.dispose();
  }

  void munculHariKerja() {
    pilihHariKerja = true;
    isSeninChecked = false;
    isSelasaChecked = false;
    isRabuChecked = false;
    isKamisChecked = false;
    isJumatChecked = false;
    isSabtuChecked = false;
    isMingguChecked = false;
  }

  void hilangHariKeja() {
    pilihHariKerja = false;
    isSeninChecked = false;
    isSelasaChecked = false;
    isRabuChecked = false;
    isKamisChecked = false;
    isJumatChecked = false;
    isSabtuChecked = false;
    isMingguChecked = false;
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
                  'Daftar Pekerja',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Container(
                      height: 357,
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
                              'NIK :',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                              ),
                            ),

                            SizedBox(height: 15),
                            Text(
                              'No HP :',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 15),
                            Text(
                              'Jenis Kelamin :',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 15),
                            Text(
                              'Alamat :',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 15),
                            Text(
                              'Jabatan :',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 15),
                            Text(
                              'Status :',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Kontrak :',
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
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Container(
                      height: 357,
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
                                readOnly: true,
                                controller: _textController,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Pilih Jabatan Terlebih Dahulu',
                                  hintStyle: TextStyle(color: Colors.grey),
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 9,
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
                                controller: txtNamaKaryawan,
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
                            SizedBox(height: 8),
                            Container(
                              alignment: Alignment.centerLeft,
                              width: 480,
                              height: 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.grey[300],
                              ),
                              child: TextFormField(
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                controller: txtNik,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 13.5,
                                    horizontal: 10,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "NIK harus diisi";
                                  }
                                  return null;
                                },
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
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
                                controller: txtNoHP,
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
                            SizedBox(height: 8),
                            Container(
                              alignment: Alignment.centerLeft,
                              width: 480,
                              height: 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.grey[300],
                              ),
                              child: DropdownButton<String>(
                                value: dropdownJK,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down),
                                elevation: 14,
                                style: const TextStyle(
                                  color: Colors.deepPurple,
                                ),
                                underline: SizedBox(),
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                onChanged: (String? value) {
                                  setState(() {
                                    dropdownJK = value;
                                    selectedJK = value;
                                  });
                                },
                                items:
                                    listJK.map<DropdownMenuItem<String>>((
                                      String value,
                                    ) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            value,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              alignment: Alignment.centerLeft,
                              width: 480,
                              height: 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.grey[300],
                              ),
                              child: TextField(
                                controller: txtAlamat,
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
                            SizedBox(height: 8),
                            Container(
                              alignment: Alignment.centerLeft,
                              width: 480,
                              height: 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.grey[300],
                              ),
                              child: DropdownButton<String>(
                                value: dropdownValue,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down),
                                elevation: 14,
                                style: const TextStyle(
                                  color: Colors.deepPurple,
                                ),
                                underline: SizedBox(),
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                onChanged: (String? value) {
                                  setState(() {
                                    dropdownValue = value;
                                    selectedJabatan = value;
                                    if (value != null) {
                                      _fetchIdKaryawan(value);
                                    }
                                    switch (value) {
                                      case "admin":
                                        hilangHariKeja();
                                        break;
                                      case "resepsionis":
                                        hilangHariKeja();
                                        break;
                                      case "terapis":
                                        munculHariKerja();
                                        break;
                                      case "supervisor":
                                        hilangHariKeja();
                                        break;
                                      case "gro":
                                        hilangHariKeja();
                                        break;
                                      case "office boy":
                                        munculHariKerja();
                                        break;
                                      case "kitchen":
                                        hilangHariKeja();
                                        break;
                                    }
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
                                              fontSize: 14,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              alignment: Alignment.centerLeft,
                              width: 480,
                              height: 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.grey[300],
                              ),
                              child: DropdownButton<String>(
                                value: dropdownStatus,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down),
                                elevation: 14,
                                style: const TextStyle(
                                  color: Colors.deepPurple,
                                ),
                                underline: SizedBox(),
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                onChanged: (String? value) {
                                  setState(() {
                                    dropdownStatus = value;
                                    selectedStatus = value;
                                  });
                                },
                                items:
                                    listStatus.map<DropdownMenuItem<String>>((
                                      String value,
                                    ) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            value,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              children:
                                  selectedFiles
                                      .map((f) => Chip(label: Text(f.name)))
                                      .toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (pilihHariKerja)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Container(
                        height: 355,
                        width: 170,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(15),
                            bottomRight: Radius.circular(15),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SizedBox(height: 5),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Hari Kerja :',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 18,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Center(
                                        child: SizedBox(
                                          height: 40,
                                          width: 30,
                                          child: Checkbox(
                                            value: isSeninChecked,
                                            onChanged: (bool? value) {
                                              setState(() {
                                                isSeninChecked = value ?? false;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        'Senin',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Center(
                                        child: SizedBox(
                                          height: 40,
                                          width: 30,
                                          child: Checkbox(
                                            value: isSelasaChecked,
                                            onChanged: (bool? value) {
                                              setState(() {
                                                isSelasaChecked =
                                                    value ?? false;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        'Selasa',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Center(
                                        child: SizedBox(
                                          height: 40,
                                          width: 30,
                                          child: Checkbox(
                                            value: isRabuChecked,
                                            onChanged: (bool? value) {
                                              setState(() {
                                                isRabuChecked = value ?? false;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        'Rabu',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Center(
                                        child: SizedBox(
                                          height: 40,
                                          width: 30,
                                          child: Checkbox(
                                            value: isKamisChecked,
                                            onChanged: (bool? value) {
                                              setState(() {
                                                isKamisChecked = value ?? false;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        'Kamis',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Center(
                                        child: SizedBox(
                                          height: 40,
                                          width: 30,
                                          child: Checkbox(
                                            value: isJumatChecked,
                                            onChanged: (bool? value) {
                                              setState(() {
                                                isJumatChecked = value ?? false;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        'Jumat',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Center(
                                        child: SizedBox(
                                          height: 40,
                                          width: 30,
                                          child: Checkbox(
                                            value: isSabtuChecked,
                                            onChanged: (bool? value) {
                                              setState(() {
                                                isSabtuChecked = value ?? false;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        'Sabtu',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Center(
                                        child: SizedBox(
                                          height: 40,
                                          width: 30,
                                          child: Checkbox(
                                            value: isMingguChecked,
                                            onChanged: (bool? value) {
                                              setState(() {
                                                isMingguChecked =
                                                    value ?? false;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        'Minggu',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ],
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
              SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.lightBlueAccent,
                    ),
                    height: 80,
                    width: 280,
                    child: TextButton(
                      onPressed: pickFiles,
                      child: Text(
                        'Upload File',
                        style: TextStyle(
                          fontSize: 40,
                          fontFamily: 'Poppins',
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 30),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Color(0XFFF6F7C4),
                    ),
                    height: 80,
                    width: 280,
                    child: Column(
                      children: [
                        if (dropdownValue == "terapis")
                          Expanded(
                            child: SizedBox(
                              width: double.infinity,
                              height: double.infinity,

                              child: TextButton(
                                onPressed: () {
                                  if (txtNik.text.trim().isEmpty) {
                                    CherryToast.warning(
                                      title: Text('NIK tidak boleh kosong!'),
                                    ).show(context);
                                    return; // Stop if validation fails
                                  }

                                  _storeTerapis();
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
                          )
                        else if (dropdownValue == "office boy")
                          Expanded(
                            child: SizedBox(
                              width: double.infinity,
                              height: double.infinity,

                              child: TextButton(
                                onPressed: () {
                                  if (txtNik.text.trim().isEmpty) {
                                    CherryToast.warning(
                                      title: Text('NIK tidak boleh kosong!'),
                                    ).show(context);
                                    return; // Stop if validation fails
                                  }

                                  _storeOB();
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
                          )
                        else
                          Expanded(
                            child: SizedBox(
                              width: double.infinity,
                              height: double.infinity,

                              child: TextButton(
                                onPressed: () {
                                  _submit();
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
