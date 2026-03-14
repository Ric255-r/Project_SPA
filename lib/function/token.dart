import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveTokenSharedPref(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('token', token);

  // var storage = GetStorage();
  // // Simpan Ke Storage. biar nnti tarik data pake token
  // storage.write('token', token);
}

Future<String?> getTokenSharedPref() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('token');
}
