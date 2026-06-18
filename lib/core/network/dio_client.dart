import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:native_flutter_proxy/native_flutter_proxy.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import '../config/app_config.dart';
import '../harness/harness_logger.dart';
import 'interceptors/auth_interceptor.dart';
import 'mock/mock_setup.dart';

class DioClient {
  final AppConfig _appConfig;
  late final Dio _dio;

  DioClient(this._appConfig);

  /// Get the configured Dio instance
  Dio get dio => _dio;

  /// Initialize the Dio client with all necessary configurations
  Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    HarnessLogger.event(
      'dio.initialize.start',
      fields: _appConfig.harnessContext,
    );

    // Create and configure Dio instance
    _dio = Dio(_getBaseOptions());

    // Configure adapter based on mock setting
    if (_appConfig.mockApiDataSource) {
      await _setupMockAdapter();
      HarnessLogger.event(
        'dio.mock_adapter.ready',
        fields: _appConfig.harnessContext,
      );
    } else {
      _dio.initHttpClient([await _configureStagingProxy()]);
      HarnessLogger.event(
        'dio.http_adapter.ready',
        fields: _appConfig.harnessContext,
      );
    }

    // Add interceptors
    _dio.interceptors.addAll(_getInterceptors());
    HarnessLogger.event(
      'dio.initialize.ready',
      fields: {
        ..._appConfig.harnessContext,
        'interceptor_count': _dio.interceptors.length,
      },
    );
  }

  /// Get base options for Dio
  BaseOptions _getBaseOptions() {
    return BaseOptions(
      baseUrl: _appConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    );
  }

  /// Configure staging proxy settings
  Future<_InitAction> _configureStagingProxy() async {
    final proxy = await _getSystemProxy();
    return _stagingProxy(proxy);
  }

  /// Get list of interceptors
  List<Interceptor> _getInterceptors() {
    return [
      AuthInterceptor(),
      if (kDebugMode) LogInterceptor(requestBody: true, responseBody: true),
    ];
  }

  /// Get system proxy settings
  Future<String> _getSystemProxy() async {
    try {
      final ProxySetting settings = await NativeProxyReader.proxySetting;
      if (settings.enabled && settings.host != null && settings.port != null) {
        return "PROXY ${settings.host}:${settings.port}";
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get system proxy: $e');
      }
    }
    return "";
  }

  /// Setup mock adapter for development environment
  Future<void> _setupMockAdapter() async {
    final dioAdapter = DioAdapter(dio: _dio);
    _dio.httpClientAdapter = dioAdapter;
    await MockSetup.configureMockAdapter(dioAdapter);
  }

  /// Create staging proxy configuration action
  _InitAction _stagingProxy(String proxy) {
    return (HttpClient client) {
      if (!_appConfig.isProduction && proxy.isNotEmpty) {
        client.findProxy = (uri) => proxy;
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
      }
    };
  }
}

/// Extension to add HTTP client initialization capability to Dio
extension _DioInitExt on Dio {
  void initHttpClient(List<_InitAction> actions) {
    (httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      for (var action in actions) {
        action.call(client);
      }
      return client;
    };
  }
}

/// Type definition for HTTP client initialization actions
typedef _InitAction = void Function(HttpClient client);
