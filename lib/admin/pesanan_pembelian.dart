import 'package:flutter/material.dart';

class PesananPembelian extends StatefulWidget {
  const PesananPembelian({super.key});

  @override
  State<PesananPembelian> createState() => _PesananPembelianState();
}

class _PesananPembelianState extends State<PesananPembelian> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pesanan Pembelian',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
      ),
    );
  }
}
