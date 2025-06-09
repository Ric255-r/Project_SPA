import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

Future<bool> showPopupExit() async {
  print("Hai Popup Exit");

  bool? result = await Get.dialog(
    AlertDialog(
      title: const Text("Keluar Aplikasi?"),
      content: const Text("Apakah Yakin Ingin Keluar?"),
      actions: [
        ElevatedButton(
          onPressed: () {
            Get.back(result: false);
          },
          child: Text("No"),
        ),
        ElevatedButton(
          onPressed: () async {
            Get.back(result: true);
            SystemNavigator.pop(); // Close App
          },
          child: Text("Yes"),
        ),
      ],
    ),
  );

  return result ?? false;
}
