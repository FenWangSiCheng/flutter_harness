import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_foundations/core/network/error/exception.dart';

void main() {
  group('ApiException', () {
    test('should create exception with message only', () {
      const message = 'Test error message';
      final exception = ApiException(message);

      expect(exception.message, equals(message));
      expect(exception.errorCode, isNull);
      expect(exception.details, isNull);
    });

    test('should create exception with message and error code', () {
      const message = 'Test error message';
      const errorCode = 404;
      final exception = ApiException(message, errorCode: errorCode);

      expect(exception.message, equals(message));
      expect(exception.errorCode, equals(errorCode));
      expect(exception.details, isNull);
    });

    test('should create exception with message, error code and details', () {
      const message = 'Test error message';
      const errorCode = 500;
      final details = {'field': 'value', 'count': 42};
      final exception = ApiException(
        message,
        errorCode: errorCode,
        details: details,
      );

      expect(exception.message, equals(message));
      expect(exception.errorCode, equals(errorCode));
      expect(exception.details, equals(details));
    });

    test('withCode factory should create exception with message and code', () {
      const message = 'Factory test error';
      const errorCode = 401;
      final exception = ApiException.withCode(message, errorCode);

      expect(exception.message, equals(message));
      expect(exception.errorCode, equals(errorCode));
      expect(exception.details, isNull);
    });

    test('withDetails factory should create exception with all parameters', () {
      const message = 'Detailed error';
      const errorCode = 400;
      final details = {'error': 'Bad Request'};
      final exception = ApiException.withDetails(
        message,
        errorCode: errorCode,
        details: details,
      );

      expect(exception.message, equals(message));
      expect(exception.errorCode, equals(errorCode));
      expect(exception.details, equals(details));
    });

    test('withDetails factory should work without optional parameters', () {
      const message = 'Minimal error';
      final exception = ApiException.withDetails(message);

      expect(exception.message, equals(message));
      expect(exception.errorCode, isNull);
      expect(exception.details, isNull);
    });

    test('toString should format message without error code', () {
      const message = 'Simple error';
      final exception = ApiException(message);

      expect(exception.toString(), equals('ApiException: Simple error'));
    });

    test('toString should format message with error code', () {
      const message = 'Error with code';
      const errorCode = 403;
      final exception = ApiException(message, errorCode: errorCode);

      expect(
        exception.toString(),
        equals('ApiException: Error with code (Code: 403)'),
      );
    });

    test('should implement Exception interface', () {
      final exception = ApiException('Test');
      expect(exception, isA<Exception>());
    });
  });
}
