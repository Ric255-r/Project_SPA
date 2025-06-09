import 'package:Project_SPA/function/ip_address.dart';
import 'package:Project_SPA/function/our_drawer.dart';
import 'package:Project_SPA/resepsionis/daftar_member.dart';
import 'package:Project_SPA/resepsionis/scannerQR.dart';
import 'package:Project_SPA/resepsionis/transaksi_fasilitas.dart';
import 'package:Project_SPA/resepsionis/transaksi_member.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:Project_SPA/resepsionis/transaksi_food.dart';
import 'package:Project_SPA/resepsionis/transaksi_massage.dart';

class HistoryMember extends StatefulWidget {
  const HistoryMember({super.key});

  @override
  State<HistoryMember> createState() => _HistoryMemberState();
}

class _HistoryMemberState extends State<HistoryMember> {
  String idMember = "";
  TextEditingController _txtIdMember = TextEditingController();
  TextEditingController _txtJenisTamu = TextEditingController();
  TextEditingController _txtNamaTamu = TextEditingController();
  TextEditingController _txtNoHP = TextEditingController();
  void _updateFields(
    String nama,
    String noHp,
    String status,
    String id_member,
  ) {
    setState(() {
      _txtNamaTamu.text = nama;
      _txtNoHP.text = noHp;
      _txtJenisTamu.text = status;
      _txtIdMember.text = id_member;
      idMember = id_member;
    });
    _fetchHistoryMember(id_member);
  }

  var dio = Dio();

  List<dynamic> historyMember = [];

  Future<void> _fetchHistoryMember(String id_member) async {
    try {
      final response = await dio.get(
        '${myIpAddr()}/history/historymember/$id_member',
      ); // API request
      if (response.statusCode == 200) {
        setState(() {
          historyMember = response.data;
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
    super.dispose();
    _txtIdMember.dispose();
    _txtJenisTamu.dispose();
    _txtNamaTamu.dispose();
    _txtNoHP.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: OurDrawer(),
      appBar: AppBar(
        title: Text(
          'History Member',
          style: TextStyle(fontSize: 60, fontFamily: 'Poppins'),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 30),
          child: IconButton(
            icon: Icon(Icons.arrow_back, size: 40), // Back Icon
            onPressed: () {
              Navigator.pop(context); // Navigate back
            },
          ),
        ),
        leadingWidth: 100,
        centerTitle: true,
        toolbarHeight: 130,
        backgroundColor: Color(0XFFFFE0B2),
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
        width: Get.width,
        height: Get.height,
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(width: 80),
                Row(
                  children: [
                    Text(
                      'ID Member : ',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 18),
                    ),
                    Container(
                      width: 85,
                      height: 38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      child: TextField(
                        controller: _txtIdMember,
                        readOnly: true,
                        maxLines: 1,
                        textAlign: TextAlign.start,
                        scrollPhysics: BouncingScrollPhysics(),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(left: 5, bottom: 15),
                        ),
                        style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 40),
                Row(
                  children: [
                    Text(
                      'Status : ',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 18),
                    ),
                    Container(
                      width: 100,
                      height: 38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      child: TextField(
                        controller: _txtJenisTamu,
                        readOnly: true,
                        maxLines: 1,
                        textAlign: TextAlign.start,
                        scrollPhysics: BouncingScrollPhysics(),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(
                            left: 5,
                            bottom: 17.5,
                          ),
                        ),
                        style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 40),
                Row(
                  children: [
                    Text(
                      'Nama : ',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 18),
                    ),
                    Container(
                      width: 200,
                      height: 38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      child: TextField(
                        controller: _txtNamaTamu,
                        readOnly: true,
                        maxLines: 1,
                        textAlign: TextAlign.start,
                        scrollPhysics: BouncingScrollPhysics(),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(
                            left: 5,
                            bottom: 17.5,
                          ),
                        ),
                        style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 40),
                Row(
                  children: [
                    Text(
                      'No HP : ',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 18),
                    ),
                    Container(
                      width: 85,
                      height: 38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      child: TextField(
                        controller: _txtNoHP,
                        readOnly: true,
                        maxLines: 1,
                        textAlign: TextAlign.start,
                        scrollPhysics: BouncingScrollPhysics(),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(
                            left: 5,
                            bottom: 17.5,
                          ),
                        ),
                        style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                SizedBox(width: 80),
                Container(
                  height: 30,
                  width: 170,
                  child: Text(
                    "Kode Promo",
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 18),
                  ),
                ),
                SizedBox(width: 10),
                Container(
                  height: 30,
                  width: 140,
                  child: Text(
                    "Nama Promo",
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 18),
                  ),
                ),
                SizedBox(width: 80),
                Container(
                  height: 30,
                  width: 170,
                  child: Text(
                    "Sisa Kunjungan",
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 18),
                  ),
                ),
                SizedBox(width: 18),
                Container(
                  height: 50,
                  width: 150,
                  child: Text(
                    "Kunjungan\nBerlaku Sampai",
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(width: 30),
                Container(
                  height: 50,
                  width: 160,
                  child: Text(
                    "Tahunan\nBerlaku Sampai",
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Container(
              height: 270,
              width: Get.width - 150,
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
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                  horizontal: 8.0,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 120,
                                      child: Text(
                                        item['kode_promo'] ?? '',
                                        style: TextStyle(fontFamily: 'Poppins'),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 10,
                                      child: Text(
                                        "|",
                                        style: TextStyle(fontSize: 21),
                                      ),
                                    ),
                                    Container(
                                      width: 240,
                                      child: Text(
                                        item['nama_promo'] ?? '',
                                        style: TextStyle(fontFamily: 'Poppins'),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 75,
                                      child: Text(
                                        "|",
                                        textAlign: TextAlign.left,
                                        style: TextStyle(fontSize: 21),
                                      ),
                                    ),
                                    Container(
                                      width: 110,
                                      child: Text(
                                        item['sisa_kunjungan'] != null &&
                                                item['sisa_kunjungan'] != ''
                                            ? '${item['sisa_kunjungan']} Kali'
                                            : '',
                                        style: TextStyle(fontFamily: 'Poppins'),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 60,
                                      child: Text(
                                        "|",
                                        textAlign: TextAlign.left,
                                        style: TextStyle(fontSize: 21),
                                      ),
                                    ),
                                    Container(
                                      width: 135,
                                      child: Text(
                                        item['exp_kunjungan'] != null &&
                                                item['exp_kunjungan'] != ''
                                            ? '${item['exp_kunjungan']}'
                                            : '',
                                        style: TextStyle(fontFamily: 'Poppins'),
                                      ),
                                    ),

                                    SizedBox(
                                      width: 50,
                                      child: Text(
                                        "|",
                                        textAlign: TextAlign.left,
                                        style: TextStyle(fontSize: 21),
                                      ),
                                    ),
                                    Container(
                                      width: 100,
                                      child: Text(
                                        item['exp_tahunan'] != null &&
                                                item['exp_tahunan'] != ''
                                            ? '${item['exp_tahunan']}'
                                            : '',
                                        style: TextStyle(fontFamily: 'Poppins'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(
                                thickness: 1,
                                color: Colors.grey.shade300,
                                height: 1,
                              ),
                            ],
                          );
                        },
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
                width: 300,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                QRScannerScreen(onScannedData: _updateFields),
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
      ),
    );
  }
}
