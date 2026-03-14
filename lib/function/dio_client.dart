import 'package:Project_SPA/function/token.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

export 'package:dio/dio.dart';

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
