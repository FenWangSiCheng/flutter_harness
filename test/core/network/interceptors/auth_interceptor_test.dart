import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_foundations/core/network/interceptors/auth_interceptor.dart';

void main() {
  group('AuthInterceptor', () {
    test('adds default token header when required header is missing', () {
      final options = RequestOptions(path: '/test');
      final interceptor = AuthInterceptor();
      final handler = _CapturingRequestInterceptorHandler();

      interceptor.onRequest(options, handler);

      final captured = handler.capturedOptions;
      expect(captured, isNotNull);
      expect(captured!.headers['token'], equals(''));
      expect(captured.headers.containsKey('x-rcms-api-access-token'), isFalse);
    });

    test('keeps existing headers when access token header already exists', () {
      final options = RequestOptions(
        path: '/test',
        headers: {'x-rcms-api-access-token': 'abc123'},
      );
      final interceptor = AuthInterceptor();
      final handler = _CapturingRequestInterceptorHandler();

      interceptor.onRequest(options, handler);

      final captured = handler.capturedOptions;
      expect(captured, isNotNull);
      expect(captured!.headers['x-rcms-api-access-token'], equals('abc123'));
      expect(captured.headers.containsKey('token'), isFalse);
    });
  });
}

class _CapturingRequestInterceptorHandler extends RequestInterceptorHandler {
  RequestOptions? capturedOptions;

  @override
  void next(RequestOptions requestOptions) {
    capturedOptions = requestOptions;
  }
}
