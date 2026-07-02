import 'package:dio/dio.dart';
import 'exception.dart';

/// Handle Dio exceptions and convert to custom exceptions.
Exception handleError(DioException error) {
  return switch (error.type) {
    DioExceptionType.connectionTimeout => ApiException('Connection timeout'),
    DioExceptionType.receiveTimeout => ApiException('Receive timeout'),
    DioExceptionType.sendTimeout => ApiException('Send timeout'),
    DioExceptionType.transformTimeout => ApiException('Transform timeout'),
    DioExceptionType.badResponse => ApiException(
      'Received invalid status code: ${error.response?.statusCode}',
    ),
    DioExceptionType.badCertificate => ApiException('Bad certificate'),
    DioExceptionType.cancel => ApiException(
      'Request to API server was cancelled',
    ),
    DioExceptionType.connectionError => ApiException('Connection error'),
    DioExceptionType.unknown => ApiException('Unexpected error occurred'),
  };
}
