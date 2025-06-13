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
        child: Column(children: []),
      ),
    );
  }
}
