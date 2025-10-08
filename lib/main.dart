// ignore_for_file: prefer_const_constructors, camel_case_types, prefer_const_literals_to_create_immutables, sort_child_properties_last
import 'dart:developer';
import 'dart:ui';

import 'package:Project_SPA/admin/main_admin.dart';
import 'package:Project_SPA/function/confirm_logout.dart';
import 'package:Project_SPA/function/ip_address.dart';
import 'package:Project_SPA/function/me.dart';
import 'package:Project_SPA/function/token.dart';
import 'package:Project_SPA/kamar_terapis/main_kamar_terapis.dart';
import 'package:Project_SPA/kitchen/main_kitchen.dart';
import 'package:Project_SPA/komisi/main_komisi_pekerja.dart';
import 'package:Project_SPA/login/login_page.dart';
import 'package:Project_SPA/office_boy/hp_ob.dart';
import 'package:Project_SPA/owner/main_owner.dart';
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
  await ApiEndpointResolver.init(); // <<— cukup sekali di sini

  // Add this error handler
  FlutterError.onError = (details) {
    log('[CRASH] ${details.exception}');
    log('[STACKTRACE] ${details.stack}');
  };

  await Future.wait([
    GetStorage.init(),
    SharedPreferences.getInstance(), // Force SharedPreferences initialization
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]),
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
    ),
  ]);

  startbackgroundservice();

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
    );
  }
}
