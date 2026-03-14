import 'package:Project_SPA/login/login_page.dart';
import 'package:Project_SPA/function/dio_client.dart';
import 'package:Project_SPA/function/ip_address.dart';
import 'package:Project_SPA/function/token.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/services.dart';

Future<Map<String, dynamic>> getMyData(jwt) async {
  Map<String, dynamic> responseData;
  var dio = DioClient();

  try {
    var response = await dio.get('${myIpAddr()}/user');

    responseData = response.data;

    return {
      "data": responseData,
      "is_logged_in": responseData != null, // false klo responseny g ad
    };
  } catch (e) {
    return {"Error Bagian User": e};
  }
}

Future<void> fnLogout() async {
  // Hapus Token di SharedPref
  await saveTokenSharedPref('');

  // Hapus token di get storage
  final storage = GetStorage();
  storage.remove('token');

  // Restore default orientation when leaving
  Future.delayed(Duration(milliseconds: 500), () {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  });

  Get.offAll(() => LoginPage());
}
