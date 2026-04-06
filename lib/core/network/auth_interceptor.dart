import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // 토큰 강제 갱신 후 재시도
          final token = await user.getIdToken(true);
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $token';
          final dio = Dio();
          final response = await dio.fetch(opts);
          return handler.resolve(response);
        }
      } catch (_) {}
    }
    handler.next(err);
  }
}
