// login_controller.dart
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cherry_toast/cherry_toast.dart';

import 'package:Project_SPA/function/ip_address.dart';
import 'package:Project_SPA/function/token.dart';
import 'package:Project_SPA/resepsionis/main_resepsionis.dart';
import 'package:Project_SPA/kitchen/main_kitchen.dart';
import 'package:Project_SPA/office_boy/hp_ob.dart';
import 'package:Project_SPA/kamar_terapis/main_kamar_terapis.dart';
import 'package:Project_SPA/komisi/main_komisi_pekerja.dart';
import 'package:Project_SPA/admin/main_admin.dart';
import 'package:Project_SPA/owner/main_owner.dart';
import 'package:Project_SPA/ruang_tunggu/main_rt.dart';

class LoginController extends GetxController {
  final userC = TextEditingController();
  final passC = TextEditingController();
  final firstFocus = FocusNode();
  final secondFocus = FocusNode();

  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
    ),
  );

  Future<void> login(BuildContext context) async {
    log("Login WOi");
    try {
      final hasConnection = await ApiEndpointResolver.refresh();
      if (!hasConnection) {
        CherryToast.warning(
          title: const Text('Koneksi belum tersedia'),
          description: const Text('Silakan cek jaringan lalu coba lagi'),
        ).show(Get.context!);
        return;
      }

      final resp = await dio.post(
        '${myIpAddr()}/login',
        data: {'id_karyawan': userC.text, 'passwd': passC.text},
      );

      final Map<String, dynamic> responseData = resp.data;

      if (resp.data == null || resp.data['access_token'] == null) {
        Get.back();
        CherryToast.error(
          title: const Text('Error'),
          description: const Text('Invalid server response'),
        ).show(Get.context!);
        return;
      }

      try {
        await saveTokenSharedPref(resp.data['access_token']);
      } catch (_) {
        Get.back();
        CherryToast.error(
          title: const Text('Error'),
          description: const Text('Failed to save login session'),
        ).show(Get.context!);
        return;
      }

      log("Fn Login : $responseData");

      switch (responseData['data_user']['hak_akses']) {
        case "resepsionis":
          Get.to(() => MainResepsionis());
          break;
        case "kitchen":
          Get.to(() => MainKitchen());
          break;
        case "ob":
          Get.to(() => Hp_Ob());
          break;
        case "ruangan":
          Get.to(() => MainKamarTerapis());
          break;
        case "gro":
          Get.to(() => PageKomisiPekerja());
          break;
        case "admin":
          Get.to(() => MainAdmin());
          break;
        case "terapis":
        case "pekerja":
          Get.to(() => PageKomisiPekerja());
          break;
        case "owner":
          Get.to(() => OwnerPage());
          break;
        case "spv":
          Get.to(() => MainRt());
          break;
      }
    } catch (e) {
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout) {
          CherryToast.warning(title: const Text('Koneksi timeout')).show(Get.context!);
          return;
        }

        final code = e.response?.statusCode;
        if (code == 401) {
          CherryToast.warning(title: const Text('Username Atau Password Tidak sesuai')).show(Get.context!);
        } else if (code == 404) {
          CherryToast.warning(title: const Text('User Tidak Ditemukan')).show(Get.context!);
        } else {
          CherryToast.warning(title: Text('HTTP Error $code')).show(Get.context!);
        }
      } else {
        CherryToast.warning(title: Text('Error $e')).show(Get.context!);
        log("Error : $e");
      }
    }
  }

  @override
  void onClose() {
    try {
      userC.dispose();
    } catch (_) {}
    try {
      passC.dispose();
    } catch (_) {}
    try {
      firstFocus.dispose();
    } catch (_) {}
    try {
      secondFocus.dispose();
    } catch (_) {}
    super.onClose();
  }
}
