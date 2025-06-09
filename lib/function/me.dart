import 'package:dio/dio.dart';
import 'package:Project_SPA/function/ip_address.dart';
import 'package:Project_SPA/function/token.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:Project_SPA/main.dart';

Future<Map<String, dynamic>> getMyData(jwt) async {
  Map<String, dynamic> responseData;
  var dio = Dio();

  try {
    var response = await dio.get(
      '${myIpAddr()}/user',
      options: Options(
        headers: {
          "Authorization": "Bearer $jwt",
        },
      ),
    );

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

  Get.offAll(() => LoginPage());
}
