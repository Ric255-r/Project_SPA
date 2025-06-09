import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:Project_SPA/function/ip_address.dart';
import 'package:Project_SPA/function/our_drawer.dart';
import 'package:Project_SPA/resepsionis/scannerQR.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';

class DaftarMember extends StatefulWidget {
  const DaftarMember({super.key});

  @override
  State<DaftarMember> createState() => _DaftarMemberState();
}

class _DaftarMemberState extends State<DaftarMember> {
  TextEditingController namaController = TextEditingController();
  TextEditingController noHpController = TextEditingController();
  List<String> list = <String>['Member', 'VIP'];
  String? _dropdownStatus;
  String qrData = "";
  bool showQR = false;
  Uint8List? updatedQrBytes;

  void _generateQRCode() {
    setState(() {
      qrData = "${namaController.text}|${noHpController.text}|$_dropdownStatus";
      showQR = true;
    });
  }

  Future<void> _sendDataToServer() async {
    try {
      var dioInstance = dio.Dio();

      // Step 1: Send form data to get id_member (no QR code yet)
      var formData = dio.FormData.fromMap({
        "nama": namaController.text,
        "no_hp": noHpController.text,
        "status": _dropdownStatus,
      });

      var response = await dioInstance.post(
        '${myIpAddr()}/member/post_member',
        data: formData,
      );

      if (response.statusCode == 200) {
        String idMember = response.data["id_member"];

        // Step 2: Generate QR code with id_member
        String updatedQrData =
            "${namaController.text}|${noHpController.text}|$_dropdownStatus|$idMember";

        final updatedQrImage = await QrPainter(
          data: updatedQrData,
          version: QrVersions.auto,
          gapless: true,
        ).toImage(300);

        ByteData? updatedByteData = await updatedQrImage.toByteData(
          format: ImageByteFormat.png,
        );
        Uint8List updatedBytes = updatedByteData!.buffer.asUint8List();

        // Step 3: Send updated QR code to be saved
        var qrFormData = dio.FormData.fromMap({
          "id_member": idMember,
          "qr_code": dio.MultipartFile.fromBytes(
            updatedBytes,
            filename: "${idMember}_qrcode.png",
          ),
        });

        await dioInstance.post(
          '${myIpAddr()}/member/upload_qr',
          data: qrFormData,
        );

        setState(() {
          updatedQrBytes = updatedBytes;
          showQR = true;
        });

        CherryToast.success(
          title: Text('Data berhasil disimpan'),
        ).show(context);

        noHpController.clear();
        namaController.clear();
      } else {
        CherryToast.error(title: Text('Gagal menyimpan data')).show(context);
      }
    } catch (e) {
      print("Error sending data: $e");
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _dropdownStatus = null;
    qrData = "";
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    namaController.dispose();
    noHpController.dispose();
  }

  void _submit() {
    if (noHpController.text.isEmpty) {
      // Show an alert if the TextField is empty
      CherryToast.warning(
        title: Text('No HP tidak boleh kosong!'),
      ).show(context);
    } else if (namaController.text.isEmpty) {
      CherryToast.warning(
        title: Text('Nama tidak boleh kosong!'),
      ).show(context);
    } else if (_dropdownStatus == null) {
      CherryToast.warning(
        title: Text('Status tidak boleh kosong!'),
      ).show(context);
    } else {
      _sendDataToServer();
    }
  }

  // Future<void> _saveQRCode() async {
  //   try {
  //     // Generate QR Code as an image
  //     final qrImage = await QrPainter(
  //       data: qrData,
  //       version: QrVersions.auto,
  //       gapless: true,
  //     ).toImage(300);

  //     // Convert image to bytes
  //     ByteData? byteData = await qrImage.toByteData(
  //       format: ImageByteFormat.png,
  //     );
  //     Uint8List bytes = byteData!.buffer.asUint8List();

  //     // Save to gallery using `image_gallery_saver`
  //     final result = await ImageGallerySaver.saveImage(bytes);

  //     if (result['isSuccess']) {
  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(SnackBar(content: Text("QR Code saved to gallery!")));
  //     } else {
  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(SnackBar(content: Text("Failed to save QR Code")));
  //     }
  //   } catch (e) {
  //     print("Error saving QR Code: $e");
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    String qrData =
        "${namaController.text}|${noHpController.text}|$_dropdownStatus";

    return Scaffold(
      drawer: OurDrawer(),
      appBar: AppBar(
        title: Text(
          'Daftar Member',
          style: TextStyle(fontSize: 60, fontFamily: 'Poppins'),
        ),
        leading: Builder(
          builder:
              (context) => Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: IconButton(
                      icon: Icon(Icons.menu), // Drawer icon
                      onPressed: () {
                        Scaffold.of(
                          context,
                        ).openDrawer(); // Open drawer manually
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back),
                      iconSize: 40, // Back icon
                      onPressed: () {
                        Get.back();
                      },
                    ),
                  ),
                ],
              ),
        ),
        centerTitle: true,
        toolbarHeight: 130,
        leadingWidth: 130,
        backgroundColor: Color(0XFFFFE0B2),
      ),
      body: Container(
        decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
        width: Get.width,
        height: Get.height,
        child: Padding(
          padding: EdgeInsets.only(left: 10),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: EdgeInsets.only(top: 70, left: 150),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  'No HP : ',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(left: 19),
                                  child: Container(
                                    width: 300,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.white,
                                    ),
                                    child: TextField(
                                      controller: noHpController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 15,
                                          horizontal: 10,
                                        ),
                                      ),
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 15),
                              child: Row(
                                children: [
                                  Text(
                                    'Nama : ',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(left: 15, top: 10),
                                    child: Container(
                                      width: 300,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.white,
                                      ),
                                      child: TextField(
                                        controller: namaController,
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 15,
                                            horizontal: 10,
                                          ),
                                        ),
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 15),
                              child: Row(
                                children: [
                                  Text(
                                    'Status : ',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(left: 12, top: 10),
                                    child: Container(
                                      width: 300,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.white,
                                      ),
                                      child: DropdownButton<String>(
                                        value: _dropdownStatus,
                                        icon: const Icon(Icons.arrow_drop_down),
                                        isExpanded: true,
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
                                            _dropdownStatus = value;
                                          });
                                        },
                                        items:
                                            list.map<DropdownMenuItem<String>>((
                                              String value,
                                            ) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    value,
                                                    style: TextStyle(
                                                      fontSize: 22,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 40, right: 170),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: Color(0XCCCDFADB),
                                ),
                                height: 120,
                                width: 400,
                                child: TextButton(
                                  onPressed: () {
                                    _submit();
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.black,
                                  ),
                                  child: Text(
                                    'SUBMIT',
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
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Align(
                                alignment: Alignment.topLeft,
                                child: Padding(
                                  padding: EdgeInsets.only(left: 0),
                                  child: Text(
                                    'QR CODE :',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (showQR)
                            Padding(
                              padding: EdgeInsets.only(top: 10, right: 110),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: Colors.white,
                                ),
                                width: 250,
                                height: 250,
                                child: Center(
                                  child:
                                      updatedQrBytes != null
                                          ? Image.memory(updatedQrBytes!)
                                          : QrImageView(
                                            data:
                                                qrData.isNotEmpty
                                                    ? qrData
                                                    : "Enter Data",
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
      ),
    );
  }
}
