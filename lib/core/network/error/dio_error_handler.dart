import 'package:dio/dio.dart';
import 'exception.dart';

/// Handle Dio exceptions and convert to custom exceptions
Exception handleError(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
      return ApiException("Connection timeout");
    case DioExceptionType.receiveTimeout:
      return ApiException("Receive timeout");
    case DioExceptionType.sendTimeout:
      return ApiException("Send timeout");
    case DioExceptionType.transformTimeout:
      return ApiException("Transform timeout");
    case DioExceptionType.badResponse:
      return ApiException(
        "Received invalid status code: ${error.response?.statusCode}",
      );
    case DioExceptionType.badCertificate:
      return ApiException("Bad certificate");
    case DioExceptionType.cancel:
      return ApiException("Request to API server was cancelled");
    case DioExceptionType.connectionError:
      return ApiException("Connection error");
    case DioExceptionType.unknown:
      return ApiException("Unexpected error occurred");
  }
}
