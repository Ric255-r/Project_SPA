// ip_address.dart
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class ApiEndpointResolver {
  // Note. Ip Mereka 192.168.1.55 Platinum System 2. taruh di MainlocalIp
  // Start. Mainkan IP Kalian di MainLocalIp
  static const String _mainLocalIp = "192.168.1.55";
  // End. Cukup Mainkan Disini
  static const String _secondLocalIp = "192.168.1.25";
  static const String _thirdLocalIp = "192.168.100.130";
  static const String _tailscaleIp = "100.90.36.28";

  static const String _firstLocalBase = "http://$_mainLocalIp:5500/api";
  static const String _secondLocalBase = "http://$_secondLocalIp:5500/api";
  static const String _thirdLocalBase = "http://$_thirdLocalIp:5500/api";
  static const String _tailscaleBase = "http://$_tailscaleIp:5500/api";
  // Selalu punya nilai default → tidak akan null.
  static String _cachedBase = _tailscaleBase;
  static bool _isInitialized = false;

  /// Panggil sekali saat app start (di main()).
  /// Return true jika ada endpoint yang bisa dijangkau.
  static Future<bool> init() async {
    // Resolve awal secara sinkron ke default, lalu coba “perbaiki” via probe async
    _cachedBase = _tailscaleBase;
    final ok = await _refresh(); // pastikan di-try resolve di awal
    _isInitialized = true;

    // Dengarkan perubahan konektivitas, refresh diam-diam
    Connectivity().onConnectivityChanged.listen((_) {
      _refresh(); // tidak perlu await; biarkan jalan di background
    });
    return ok;
  }

  /// Alias agar nama fungsi lama tetap sama dan sinkron.
  /// ini untuk defaultnya.
  static String myIpAddr() => _cachedBase;

  /// Public wrapper untuk refresh koneksi saat dibutuhkan (mis. sebelum login).
  /// Return true jika ada endpoint yang bisa dijangkau.
  static Future<bool> refresh() => _refresh();

  static Future<bool> _refresh() async {
    final connectivity = await Connectivity().checkConnectivity();

    // Tentukan apakah kita punya akses ke jaringan lokal
    final bool onLocalNetwork =
        connectivity == ConnectivityResult.wifi || connectivity == ConnectivityResult.ethernet;

    // 1. PRIORITAS PERTAMA: Cek IP Lokal
    // Jika kita terhubung ke Wi-Fi, cek apakah server lokal bisa dijangkau.
    // Ini lebih cepat dan efisien jika Anda sedang berada di lokasi (kantor/toko).
    if (onLocalNetwork) {
      List<bool> localResults = await Future.wait([
        _canReach(_mainLocalIp, 5500),
        _canReach(_secondLocalIp, 5500),
        _canReach(_thirdLocalIp, 5500),
      ]);

      if (localResults[0]) {
        _cachedBase = _firstLocalBase;
        return true;
      } else if (localResults[1]) {
        _cachedBase = _secondLocalBase;
        return true;
      } else if (localResults[2]) {
        _cachedBase = _thirdLocalBase;
        return true;
      }
    }

    // 2. PRIORITAS KEDUA: Cek Tailscale
    // Jika tidak di LAN atau server lokal tidak ketemu, baru coba Tailscale.
    final bool tailscaleOk = await _canReach(_tailscaleIp, 5500);
    if (tailscaleOk) {
      _cachedBase = _tailscaleBase;
      return true;
    }

    // 3. FALLBACK: Jika semua gagal, tetap gunakan Tailscale sebagai default
    // agar saat internet kembali stabil, aplikasi bisa terhubung otomatis.
    _cachedBase = _tailscaleBase;
    return false;
  }

  static Future<bool> _canReach(String host, int port) async {
    try {
      final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 2));
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
