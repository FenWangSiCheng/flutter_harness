import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_foundations/core/network/error/dio_error_handler.dart';
import 'package:flutter_foundations/core/network/error/exception.dart';

void main() {
  group('handleError', () {
    final cases = <_ErrorCase>[
      _ErrorCase(DioExceptionType.connectionTimeout, 'Connection timeout'),
      _ErrorCase(DioExceptionType.receiveTimeout, 'Receive timeout'),
      _ErrorCase(DioExceptionType.sendTimeout, 'Send timeout'),
      _ErrorCase(DioExceptionType.transformTimeout, 'Transform timeout'),
      _ErrorCase(DioExceptionType.badCertificate, 'Bad certificate'),
      _ErrorCase(
        DioExceptionType.cancel,
        'Request to API server was cancelled',
      ),
      _ErrorCase(DioExceptionType.connectionError, 'Connection error'),
      _ErrorCase(DioExceptionType.unknown, 'Unexpected error occurred'),
    ];

    for (final c in cases) {
      test('should handle ${c.type.name} error', () {
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: c.type,
        );

        final result = handleError(dioError);

        expect(result, isA<Exception>());
        expect(result, isA<ApiException>());
        expect((result as ApiException).message, equals(c.expectedMessage));
      });
    }

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

class _ErrorCase {
  const _ErrorCase(this.type, this.expectedMessage);

  final DioExceptionType type;
  final String expectedMessage;
}
