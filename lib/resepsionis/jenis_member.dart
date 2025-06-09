import 'package:Project_SPA/function/our_drawer.dart';
import 'package:Project_SPA/resepsionis/daftar_member.dart';
import 'package:Project_SPA/resepsionis/history_member.dart';
import 'package:Project_SPA/resepsionis/transaksi_fasilitas.dart';
import 'package:Project_SPA/resepsionis/transaksi_member.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:Project_SPA/resepsionis/transaksi_food.dart';
import 'package:Project_SPA/resepsionis/transaksi_massage.dart';

class JenisMember extends StatefulWidget {
  const JenisMember({super.key});

  @override
  State<JenisMember> createState() => _JenisMemberState();
}

class _JenisMemberState extends State<JenisMember> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: OurDrawer(),
      appBar: AppBar(
        title: Text(
          'PLATINUM',
          style: TextStyle(fontSize: 60, fontFamily: 'Poppins'),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 30),
          child: IconButton(
            icon: Icon(Icons.arrow_back, size: 40), // Back Icon
            onPressed: () {
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
      body: Container(
        decoration: BoxDecoration(color: Color(0XFFFFE0B2)),
        width: Get.width,
        height: Get.height,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 40),
              child: Text(
                "Pilih Jenis Aktivitas",
                style: TextStyle(fontSize: 30, fontFamily: 'Poppins'),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 60, left: 100, right: 100),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Get.to(() => TransaksiMember());
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      height: 300,
                      width: 250,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Icon(Icons.payment_rounded, size: 160),
                          ),

                          Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: Text(
                              'Transaksi',
                              style: TextStyle(
                                fontSize: 30,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Get.to(() => HistoryMember());
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      height: 300,
                      width: 250,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Icon(Icons.history_rounded, size: 160),
                          ),

                          Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: Text(
                              'History',
                              style: TextStyle(
                                fontSize: 30,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Get.to(() => DaftarMember());
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      height: 300,
                      width: 250,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.person, size: 200),
                          Text(
                            'Daftar',
                            style: TextStyle(
                              fontSize: 26,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          Text(
                            'Member',
                            style: TextStyle(
                              fontSize: 26,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
