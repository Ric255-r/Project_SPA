import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DownloadSplash extends StatelessWidget {
  const DownloadSplash({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.5),
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text('Downloading...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                const SizedBox(height: 10),
                Text('Please wait while we prepare your file', style: TextStyle(fontSize: 14, fontFamily: 'Poppins')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
