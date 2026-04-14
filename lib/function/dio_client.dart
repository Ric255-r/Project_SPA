import 'package:Project_SPA/function/token.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// Re-export package Dio supaya file yang mengimpor `dio_client.dart`
/// tetap bisa memakai tipe-tipe Dio seperti `BaseOptions`, `Options`,
/// `Response`, dan `DioException` tanpa perlu import tambahan.
export 'package:dio/dio.dart';

/// Nama key pada `Options.extra` untuk menandai request yang tidak perlu
/// menyisipkan header `Authorization`.
///
/// Contoh penggunaan:
/// ```dart
/// dio.post(
///   '/login',
///   options: Options(extra: {skipAuthExtraKey: true}),
/// );
/// ```
const String skipAuthExtraKey = 'skipAuth';

/// HTTP client berbasis Dio yang otomatis menambahkan bearer token
/// dari `SharedPreferences` ke setiap request.
///
/// Secara default semua request akan melewati interceptor auth.
/// Jika ada request tertentu yang tidak memerlukan token, seperti login,
/// kirim `Options(extra: {skipAuthExtraKey: true})` agar pembacaan token
/// dilewati.
class DioClient extends DioForNative {
  DioClient({BaseOptions? options})
    : super(
        options ??
            BaseOptions(
              connectTimeout: const Duration(seconds: 6),
              receiveTimeout: const Duration(seconds: 10),
              sendTimeout: const Duration(seconds: 10),
            ),
      ) {
    interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final shouldSkipAuth = options.extra[skipAuthExtraKey] == true;
          if (shouldSkipAuth) {
            handler.next(options);
            return;
          }

          final token = await getTokenSharedPref();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }
}
