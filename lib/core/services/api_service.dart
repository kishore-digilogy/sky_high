import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:sky_high/core/services/storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  static const String baseUrl =
      'https://skyhighdevapi.digilogy.dev/api';

  late final Dio dio;

  ApiService._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final token =
                GetIt.I<StorageService>().getToken();

            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] =
                  'Bearer $token';
            }

            options.headers['Accept'] =
                'application/json';

            /// ==============================
            /// PRINT REQUEST DETAILS
            /// ==============================

            print('''
╔══════════════════════════════════════════╗
║              API REQUEST                ║
╚══════════════════════════════════════════╝

➡️ METHOD: ${options.method}

➡️ URL: ${options.path}

➡️ HEADERS:
${options.headers}

➡️ QUERY PARAMS:
${options.queryParameters}

➡️ PAYLOAD:
${options.data}

════════════════════════════════════════════
''');
          } catch (e) {
            print(
              "ApiService: Error getting token: $e",
            );
          }

          return handler.next(options);
        },

        /// ==============================
        /// RESPONSE
        /// ==============================
        onResponse: (response, handler) {
          print('''
╔══════════════════════════════════════════╗
║             API RESPONSE                 ║
╚══════════════════════════════════════════╝

✅ STATUS CODE: ${response.statusCode}

✅ URL: ${response.requestOptions.path}

✅ RESPONSE:
${response.data} 
 ✅ QUERY PARAMS:
params:${response.requestOptions.queryParameters}

════════════════════════════════════════════
''');

          return handler.next(response);
        },

        /// ==============================
        /// ERROR
        /// ==============================
        onError: (DioException e, handler) {
          print('''
╔══════════════════════════════════════════╗
║               API ERROR                 ║
╚══════════════════════════════════════════╝

❌ STATUS CODE:
${e.response?.statusCode}

❌ URL:
${e.requestOptions.path}

❌ METHOD:
${e.requestOptions.method}

❌ HEADERS:
${e.requestOptions.headers}

❌ QUERY PARAMS:
${e.requestOptions.queryParameters}

❌ PAYLOAD:
${e.requestOptions.data}

❌ RESPONSE:
${e.response?.data}

❌ ERROR MESSAGE:
${e.message}

════════════════════════════════════════════
''');

          return handler.next(e);
        },
      ),
    );
  }
}
