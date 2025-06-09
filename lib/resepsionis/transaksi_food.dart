import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Project_SPA/function/ip_address.dart';
import 'package:Project_SPA/function/token.dart';
import 'detail_food_n_beverages.dart';
import 'package:dio/dio.dart';

const List<String> list = <String>['Umum', 'Member', 'VIP'];
String? dropdownValue;

class TransaksiFood extends StatefulWidget {
  const TransaksiFood({super.key});

  @override
  State<TransaksiFood> createState() => _TransaksiFoodState();
}

class _TransaksiFoodState extends State<TransaksiFood> {
  var dio = Dio();
  var idTrans = "";
  TextEditingController _txtIdTrans = TextEditingController();

  Future<void> _createDraftLastTrans() async {
    try {
      var token = await getTokenSharedPref();
      print(token);

      // pake method post. jadi alurny post dlu id transaksi ke tabel, lalu update
      var response = await dio.post(
        '${myIpAddr()}/id_trans/createDraft',
        options: Options(headers: {"Authorization": "Bearer " + token!}),
      );

      var newId = response.data['id_transaksi'];
      log("New Transaction ID: $newId");

      setState(() {
        idTrans = newId;
        _txtIdTrans.text = idTrans;
      });
    } catch (e) {
      log("Error GetLastId $e");
    }
  }

  TextEditingController _noHp = TextEditingController();
  TextEditingController _namaTamu = TextEditingController();

  Future<void> _updateLastTrans() async {
    try {
      var token = await getTokenSharedPref();
      print(token);

      var response = await dio.put(
        '${myIpAddr()}/id_trans/updateDraft/${idTrans}',
        options: Options(headers: {"Authorization": "Bearer " + token!}),
        data: {
          "jenis_tamu": dropdownValue,
          "no_hp": _noHp.text,
          "nama_tamu": _namaTamu.text,
        },
      );

      log("Update Draft $response");
    } catch (e) {
      log("Error di Update Draft $e");
    }
  }

  Future<void> removeIdDraft() async {
    try {
      var token = await getTokenSharedPref();
      print(token);

      var response = await dio.delete(
        '${myIpAddr()}/id_trans/deleteDraftId/${idTrans}',
        options: Options(headers: {"Authorization": "Bearer " + token!}),
      );

      log("Delete Draft $response");
    } catch (e) {
      log("Error di Delete Draft $e");
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _txtIdTrans.dispose();
    _namaTamu.dispose();
    _noHp.dispose();
    idTrans = "";
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    _createDraftLastTrans();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await removeIdDraft();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Transaksi Food & Beverages',
            style: TextStyle(fontSize: 60, fontFamily: 'Poppins'),
          ),
          leading: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: IconButton(
              icon: Icon(Icons.arrow_back, size: 40), // Back Icon
              onPressed: () async {
                await removeIdDraft();
                Get.back(); // Navigate back
              },
            ),
          ),
          leadingWidth: 100,
          centerTitle: true,
          toolbarHeight: 130,
          backgroundColor: Color(0XFFFFE0B2),
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
            width: Get.width,
            height: Get.height - 155,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Get.width * 0.28,
                vertical: Get.height * 0.08,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'No Transaksi : ',
                        style: TextStyle(fontSize: 22, fontFamily: 'Poppins'),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: Container(
                          width: 300,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                          ),
                          child: TextField(
                            readOnly: true,
                            controller: _txtIdTrans,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 15,
                                horizontal: 10,
                              ),
                            ),
                            style: TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text(
                          'Jenis Tamu : ',
                          style: TextStyle(fontSize: 22, fontFamily: 'Poppins'),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 24, top: 10),
                        child: Container(
                          width: 300,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                          ),
                          child: DropdownButton<String>(
                            value: dropdownValue,
                            icon: const Icon(Icons.arrow_drop_down),
                            isExpanded: true,
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
                                list.map<DropdownMenuItem<String>>((
                                  String value,
                                ) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        value,
                                        style: TextStyle(fontSize: 22),
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
                      Text(
                        'No HP : ',
                        style: TextStyle(fontSize: 22, fontFamily: 'Poppins'),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 88, top: 10),
                        child: Container(
                          width: 300,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                          ),
                          child: TextField(
                            controller: _noHp,
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
                  Row(
                    children: [
                      Text(
                        'Nama : ',
                        style: TextStyle(fontSize: 22, fontFamily: 'Poppins'),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 84, top: 10),
                        child: Container(
                          width: 300,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                          ),
                          child: TextField(
                            controller: _namaTamu,
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
                    padding: EdgeInsets.only(top: 50),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Color(0XFFF6F7C4),
                      ),
                      height: 100,
                      width: 380,
                      child: TextButton(
                        onPressed: () {
                          _updateLastTrans().then((_) {
                            Get.to(
                              () => DetailFoodNBeverages(idTrans: idTrans),
                            );
                          });
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                        ),
                        child: Text(
                          'Pilih Paket',
                          style: TextStyle(fontSize: 40, fontFamily: 'Poppins'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
