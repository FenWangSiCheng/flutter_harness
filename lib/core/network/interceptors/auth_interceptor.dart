import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!options.headers.containsKey("x-rcms-api-access-token")) {
      options.headers.addAll({"token": ""});
    }
    handler.next(options);
  }
}
