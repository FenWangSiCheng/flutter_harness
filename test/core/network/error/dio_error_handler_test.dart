import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_foundations/core/network/error/dio_error_handler.dart';
import 'package:flutter_foundations/core/network/error/exception.dart';

void main() {
  group('handleError', () {
    test('should handle connectionTimeout error', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );

      final result = handleError(dioError);

      expect(result, isA<ApiException>());
      expect((result as ApiException).message, equals('Connection timeout'));
    });

    test('should handle receiveTimeout error', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.receiveTimeout,
      );

      final result = handleError(dioError);

      expect(result, isA<ApiException>());
      expect((result as ApiException).message, equals('Receive timeout'));
    });

    test('should handle sendTimeout error', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.sendTimeout,
      );

      final result = handleError(dioError);

      expect(result, isA<ApiException>());
      expect((result as ApiException).message, equals('Send timeout'));
    });

    test('should handle badResponse error with status code', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 404,
        ),
      );

      final result = handleError(dioError);

      expect(result, isA<ApiException>());
      expect(
        (result as ApiException).message,
        equals('Received invalid status code: 404'),
      );
    });

    test('should handle badResponse error without status code', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: RequestOptions(path: '/test')),
      );

      final result = handleError(dioError);

      expect(result, isA<ApiException>());
      expect(
        (result as ApiException).message,
        equals('Received invalid status code: null'),
      );
    });

    test('should handle cancel error', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.cancel,
      );

      final result = handleError(dioError);

      expect(result, isA<ApiException>());
      expect(
        (result as ApiException).message,
        equals('Request to API server was cancelled'),
      );
    });

    test('should handle connectionError', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionError,
      );

      final result = handleError(dioError);

      expect(result, isA<ApiException>());
      expect((result as ApiException).message, equals('Connection error'));
    });

    test('should handle unknown error', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.unknown,
      );

      final result = handleError(dioError);

      expect(result, isA<ApiException>());
      expect(
        (result as ApiException).message,
        equals('Unexpected error occurred'),
      );
    });

    test('should return Exception type', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );

      final result = handleError(dioError);

      expect(result, isA<Exception>());
    });

    test('should handle badResponse error without response object', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
      );

      final result = handleError(dioError);

      expect(result, isA<ApiException>());
      expect(
        (result as ApiException).message,
        equals('Received invalid status code: null'),
      );
    });
  });
}
