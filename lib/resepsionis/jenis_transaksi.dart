import 'package:Project_SPA/function/our_drawer.dart';
import 'package:Project_SPA/resepsionis/transaksi_fasilitas.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:Project_SPA/resepsionis/transaksi_food.dart';
import 'package:Project_SPA/resepsionis/transaksi_massage.dart';

class JenisTransaksi extends StatefulWidget {
  const JenisTransaksi({super.key});

  @override
  State<JenisTransaksi> createState() => _JenisTransaksiState();
}

class _JenisTransaksiState extends State<JenisTransaksi> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: OurDrawer(),
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: IconButton(
            icon: Icon(Icons.arrow_back, size: 40), // Back Icon
            onPressed: () {
              Get.back(); // Navigate back
            },
          ),
        ),
        title: Text(
          'PLATINUM',
          style: TextStyle(fontSize: 60, fontFamily: 'Poppins'),
        ),
        centerTitle: true,
        leadingWidth: 100,
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
                "Pilih Jenis Transaksi",
                style: TextStyle(fontSize: 30, fontFamily: 'Poppins'),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 60, left: 220, right: 220),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Get.to(() => TransaksiMassage());
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
                            padding: EdgeInsets.only(top: 68),
                            child: Icon(
                              FontAwesomeIcons.handHoldingHeart,
                              size: 140,
                            ),
                          ),

                          Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: Text(
                              'Massage',
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
                      Get.to(() => TransaksiFasilitas());
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
                          Icon(Icons.spa, size: 200),
                          Text(
                            'Facilities',
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
