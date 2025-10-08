// ip_address.dart
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class ApiEndpointResolver {
  // Mainkan IP Kalian Disini
  static const String _localIp = "192.168.1.11";
  static const String _tailscaleIp = "100.90.36.28";

  static const String _firstLocalBase = "http://$_mainLocalIp:5500/api";
  static const String _secondLocalBase = "http://$_secondLocalIp:5500/api";
  static const String _thirdLocalBase = "http://$_thirdLocalIp:5500/api";
  static const String _tailscaleBase = "http://$_tailscaleIp:5500/api";

  // Selalu punya nilai default → tidak akan null.
  static String _cachedBase = _tailscaleBase;
  static bool _isInitialized = false;

  /// Panggil sekali saat app start (di main()).
  static Future<void> init() async {
    // Resolve awal secara sinkron ke default, lalu coba “perbaiki” via probe async
    _cachedBase = _tailscaleBase;
    await _refresh(); // pastikan di-try resolve di awal
    _isInitialized = true;

    // Dengarkan perubahan konektivitas, refresh diam-diam
    Connectivity().onConnectivityChanged.listen((_) {
      _refresh(); // tidak perlu await; biarkan jalan di background
    });
  }

  /// Alias agar nama fungsi lama tetap sama dan sinkron.
  /// ini untuk defaultnya.
  static String myIpAddr() => _cachedBase;

  // --------------------------------------------------------------------------

  static Future<void> _refresh() async {
    // 1) Coba reach Tailscale dulu
    final bool tailscaleOk = await _canReach(_tailscaleIp, 5500);
    if (tailscaleOk) {
      // jika tailscale ok, myIpAddr di method class itu bkl set IP tailscale
      _cachedBase = _tailscaleBase;
      return;
    }

    // 2) Kalau tidak, dan ada Wi-Fi + server lokal reachable → pakai lokal
    final connectivity = await Connectivity().checkConnectivity();
    final onWifi = connectivity == ConnectivityResult.wifi;
    List<bool> localOk = await Future.wait([
      _canReach(_mainLocalIp, 5500),
      _canReach(_secondLocalIp, 5500),
      _canReach(_thirdLocalIp, 5500),
    ]);
    if (onWifi && localOk[0]) {
      _cachedBase = _firstLocalBase;
      return;
    }
    if (onWifi && localOk[1]) {
      _cachedBase = _secondLocalBase;
      return;
    }
    if (onWifi && localOk[2]) {
      _cachedBase = _thirdLocalBase;
      return;
    }
    // 3) Kalau semua gagal, tetap Tailscale (biar “pulih sendiri” saat internet balik)
    _cachedBase = _tailscaleBase;
  }

  static Future<bool> _canReach(String host, int port) async {
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 2),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }
}

// === API lama tetap hidup ===
// Semua file lama tetap bisa memanggil ini secara sinkron.
String myIpAddr() => ApiEndpointResolver.myIpAddr();
