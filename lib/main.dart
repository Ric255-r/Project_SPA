// ignore_for_file: prefer_const_constructors, camel_case_types, prefer_const_literals_to_create_immutables, sort_child_properties_last
import 'dart:developer';
import 'dart:ui';

import 'package:Project_SPA/admin/regis_paket.dart';
import 'package:Project_SPA/admin/regis_pekerja.dart';
import 'package:Project_SPA/admin/main_admin.dart';
import 'package:Project_SPA/admin/regis_promo.dart';
import 'package:Project_SPA/admin/regis_room.dart';
import 'package:Project_SPA/admin/regis_users.dart';
import 'package:Project_SPA/function/confirm_logout.dart';
import 'package:Project_SPA/function/ip_address.dart';
import 'package:Project_SPA/function/me.dart';
import 'package:Project_SPA/function/token.dart';
import 'package:Project_SPA/kamar_terapis/main_kamar_terapis.dart';
import 'package:Project_SPA/kitchen/main_kitchen.dart';
import 'package:Project_SPA/komisi/main_komisi_pekerja.dart';
import 'package:Project_SPA/office_boy/hp_ob.dart';
import 'package:Project_SPA/office_boy/laporan.dart';
import 'package:Project_SPA/office_boy/main_ob.dart';
import 'package:Project_SPA/owner/main_owner.dart';
import 'package:Project_SPA/resepsionis/billing_locker.dart';
import 'package:Project_SPA/resepsionis/rating.dart';
import 'package:Project_SPA/resepsionis/transaksi_massage.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get/get.dart';
import 'package:Project_SPA/resepsionis/main_resepsionis.dart';
import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import 'package:Project_SPA/ruang_tunggu/main_rt.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> onNotificationTap(ReceivedAction receivedAction) async {
  print("Notification tapped: ${receivedAction.id}");
  // Handle navigation or actions here
}

@pragma('vm:entry-point')
void onStartBackgroundTask(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  print("Background service started!");

  if (service is AndroidServiceInstance) {
    await service.setForegroundNotificationInfo(title: "SPA App Service", content: "Running in background");

    await service.setAsForegroundService();

    // Keep WebSocket or other logic running
    service.invoke('startForeground', {
      'id': 1,
      'title': 'WebSocket Running',
      'content': 'Keeping WebSocket Active',
    });
  }

  service.on("keepAlive").listen((event) {
    print("Received keep-alive event");
  });
}

void startbackgroundservice() async {
  final service = FlutterBackgroundService();
  final isRunning = await service.isRunning();

  if (isRunning) {
    return;
  }

  // autostart awal itu true, ak jadikan false biar nda 2x callstack di main
  final androidConfiguration = AndroidConfiguration(
    onStart: onStartBackgroundTask,
    isForegroundMode: true,
    autoStart: false,
  );

  final iosConfiguration = IosConfiguration(
    onForeground: onStartBackgroundTask,
    onBackground: (service) => false,
  );

  await service.configure(androidConfiguration: androidConfiguration, iosConfiguration: iosConfiguration);
  await service.startService();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  startbackgroundservice();

  // Add this error handler
  FlutterError.onError = (details) {
    log('[CRASH] ${details.exception}');
    log('[STACKTRACE] ${details.stack}');
  };

  await Future.wait([
    GetStorage.init(),
    SharedPreferences.getInstance(), // Force SharedPreferences initialization
  ]);

  AwesomeNotifications().initialize(
    null, // null for default icon
    [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Basic notifications',
        channelDescription: 'Notification channel for basic tests',
        defaultColor: Color(0xFF9D50DD),
        ledColor: Colors.white,
        importance: NotificationImportance.Max, // Ensure high importance untuk event Tap
      ),
    ],
    debug: true, //
  );

  // Buat Ngecek Udah login atau blm, klo udh lngsung tembak ke mainresepsionis();
  final String? token = await getTokenSharedPref();
  // Inisiasikan widget mana mw ditembak nnti
  Widget initialPage = LoginPage();

  if (token != null) {
    var response = await getMyData(token);
    log("Main.dart Response $response");
    if (response != null && response['is_logged_in'] == true) {
      switch (response['data']['hak_akses']) {
        case "resepsionis":
          initialPage = MainResepsionis();
          break;
        case "kitchen":
          initialPage = MainKitchen();
          break;
        case "ob":
          initialPage = Hp_Ob();
        case "ruangan":
          initialPage = MainKamarTerapis();
          break;
        case "gro":
          initialPage = MainRt();
          break;
        case "admin":
          initialPage = MainAdmin();
          break;
        case "terapis":
        case "pekerja":
          initialPage = PageKomisiPekerja();
          break;
        case "owner":
          initialPage = OwnerPage();
          break;
        case "spv":
          initialPage = MainRt();
          break;
      }
    }
  }

  if (Get.isRegistered<ControllerPekerja>()) {
    Get.delete<ControllerPekerja>();
  }
  Get.put(ControllerPekerja());

  runApp(Myapp(initialPage: initialPage));
}

class Myapp extends StatelessWidget {
  final Widget initialPage;

  const Myapp({super.key, required this.initialPage});

  // Screenwidth UI Kita
  final double referenceScreenWidth = 650.0;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: ThemeData(primaryColor: Colors.white),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
          child: child!,
        );
      },
      home: initialPage,
      getPages: [
        GetPage(
          name: '/mainresepsionis',
          page: () => MainResepsionis(),
          binding: BindingsBuilder(() {
            // Get.create<MainResepsionisController>(
            //   () => MainResepsionisController(),
            // );
            // Change from Get.create to Get.lazyPut to ensure singleton behavior:
            Get.lazyPut<MainResepsionisController>(() => MainResepsionisController());
          }),
        ),
        GetPage(name: '/rating', page: () => Rating()),
      ],
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _firstFieldFocus = FocusNode();
  final FocusNode _secondFieldFocus = FocusNode();

  var dio = Dio();
  var storage = GetStorage();

  @override
  void dispose() {
    // TODO: implement dispose
    _userController.dispose();
    _passwordController.dispose();
    _firstFieldFocus.dispose();
    _secondFieldFocus.dispose();

    super.dispose();
  }

  Future<void> fnLogin() async {
    log("Login WOi");
    try {
      var response = await dio.post(
        '${myIpAddr()}/login',
        data: {'id_karyawan': _userController.text, 'passwd': _passwordController.text},
      );

      // Convert Response data
      final Map<String, dynamic> responseData = response.data;

      // Ensure response is valid
      if (response.data == null || response.data['access_token'] == null) {
        Get.back(); // Close loading
        Get.snackbar('Error', 'Invalid server response');
        return;
      }

      // Save token with error handling
      try {
        await saveTokenSharedPref(response.data['access_token']);
      } catch (e) {
        Get.back(); // Close loading
        Get.snackbar('Error', 'Failed to save login session');
        return;
      }

      // // Simpan Ke Storage. biar nnti tarik data pake token
      // storage.write('token', responseData['access_token']);

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
        if (e.response!.statusCode == 401) {
          CherryToast.warning(title: Text('Username Atau Password Tidak sesuai')).show(context);
        } else if (e.response!.statusCode == 404) {
          CherryToast.warning(title: Text('User Tidak Ditemukan')).show(context);
        }
      }
      log("Error : ${e}");
    }
  }

  // Future<void> testStorage() async {
  //   print('[DEBUG] Testing storage...');
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     await prefs.setString('test_key', 'test_value');
  //     final value = prefs.getString('test_key');
  //     print('[DEBUG] Storage test value: $value');
  //   } catch (e) {
  //     print('[DEBUG] Storage error: $e');
  //   }
  // }

  @override
  void initState() {
    // TODO: implement initState
    // testStorage();
    super.initState();
    // Kunci Login Screen Saja
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WillPopScope(
        onWillPop: () async => await showPopupExit(),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black, Colors.yellow],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned.fill(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        margin: EdgeInsets.only(top: 150),
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(width: 0, color: Colors.black),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/spa.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.image_not_supported, size: 100);
                            },
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        padding: EdgeInsets.only(left: 10),
                        margin: EdgeInsets.only(top: 40),
                        width: 300,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          focusNode: _firstFieldFocus,
                          textInputAction: TextInputAction.next,
                          onEditingComplete: () {
                            FocusScope.of(context).requestFocus(_secondFieldFocus);
                          },
                          controller: _userController,
                          decoration: InputDecoration(hintText: 'Isi User ID', border: InputBorder.none),
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        padding: EdgeInsets.only(left: 10),
                        margin: EdgeInsets.only(top: 20),
                        width: 300,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          focusNode: _secondFieldFocus,
                          textInputAction: TextInputAction.done,
                          controller: _passwordController,
                          decoration: InputDecoration(hintText: 'Isi Password', border: InputBorder.none),
                          obscureText: true,
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: SizedBox(
                          width: 200,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_userController.text != "" && _passwordController.text != "") {
                                await fnLogin();
                              } else {
                                CherryToast.warning(
                                  title: Text('Inputan Username / Password Kosong'),
                                ).show(context);
                              }
                            },
                            child: Text(
                              'LOGIN',
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.black.withOpacity(0.5)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
