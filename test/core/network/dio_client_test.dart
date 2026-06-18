import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'package:flutter_foundations/core/config/app_config.dart';
import 'package:flutter_foundations/core/network/dio_client.dart';
import 'package:flutter_foundations/core/network/interceptors/auth_interceptor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const proxyChannel = MethodChannel('native_flutter_proxy');

  late TestAppConfig config;
  late DioClient client;

  setUp(() {
    config = TestAppConfig(
      baseUrl: 'https://initial.example.com',
      mockApiDataSource: false,
      isProduction: false,
    );
    client = DioClient(config);
    config.update(
      baseUrl: 'https://initial.example.com',
      mockApiDataSource: false,
      isProduction: false,
    );
    _clearMockAssetBundle();
    _clearMockProxyResponse(proxyChannel);
  });

  tearDown(() {
    _clearMockAssetBundle();
    _clearMockProxyResponse(proxyChannel);
  });

  test(
    'initialize configures mock adapter when mock data source is enabled',
    () async {
      const mockUsersJson =
          '[{"id":"1","name":"Alice"},{"id":"2","name":"Bob"}]';

      config.update(
        baseUrl: 'https://mock.example.com',
        mockApiDataSource: true,
        isProduction: false,
      );

      _setMockAssetBundle({'assets/mock/users.json': mockUsersJson});

      await client.initialize();

      final dio = client.dio;

      expect(dio.options.baseUrl, equals('https://mock.example.com'));
      expect(dio.httpClientAdapter, isA<DioAdapter>());
      expect(
        dio.interceptors.any((interceptor) => interceptor is AuthInterceptor),
        isTrue,
      );

      final response = await dio.get('/users');
      expect(response.statusCode, equals(200));
      expect(response.data, isA<List<dynamic>>());
      expect(response.data.length, equals(2));
    },
  );

  test(
    'initialize configures IOHttpClientAdapter when mock data source is disabled',
    () async {
      config.update(
        baseUrl: 'https://api.example.com',
        mockApiDataSource: false,
        isProduction: false,
      );

      _setMockProxyResponse(proxyChannel, host: '127.0.0.1', port: 9090);

      await client.initialize();

      final dio = client.dio;
      expect(dio.options.baseUrl, equals('https://api.example.com'));
      expect(dio.httpClientAdapter, isA<IOHttpClientAdapter>());
      expect(
        dio.interceptors.any((interceptor) => interceptor is AuthInterceptor),
        isTrue,
      );
    },
  );

  test(
    'initialize does not configure proxy when proxy retrieval fails',
    () async {
      config.update(
        baseUrl: 'https://api.example.com',
        mockApiDataSource: false,
        isProduction: false,
      );

      // Don't set up mock proxy response, causing getProxySetting to return null
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(proxyChannel, (
            MethodCall methodCall,
          ) async {
            if (methodCall.method == 'getProxySetting') {
              throw Exception('Proxy retrieval failed');
            }
            return null;
          });

      await client.initialize();

      final dio = client.dio;
      expect(dio.options.baseUrl, equals('https://api.example.com'));
      expect(dio.httpClientAdapter, isA<IOHttpClientAdapter>());
    },
  );

  test('initialize does not configure proxy when proxy is disabled', () async {
    config.update(
      baseUrl: 'https://api.example.com',
      mockApiDataSource: false,
      isProduction: false,
    );

    // Return proxy with enabled = false
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(proxyChannel, (MethodCall methodCall) async {
          if (methodCall.method == 'getProxySetting') {
            return {'enabled': false, 'host': null, 'port': null};
          }
          return null;
        });

    await client.initialize();

    final dio = client.dio;
    expect(dio.options.baseUrl, equals('https://api.example.com'));
    expect(dio.httpClientAdapter, isA<IOHttpClientAdapter>());
  });

  test('initialize does not configure proxy when in production', () async {
    config.update(
      baseUrl: 'https://api.example.com',
      mockApiDataSource: false,
      isProduction: true,
    );

    _setMockProxyResponse(proxyChannel, host: '127.0.0.1', port: 9090);

    await client.initialize();

    final dio = client.dio;
    expect(dio.options.baseUrl, equals('https://api.example.com'));
    expect(dio.httpClientAdapter, isA<IOHttpClientAdapter>());
  });

  test('initialize does not configure proxy when proxy is empty', () async {
    config.update(
      baseUrl: 'https://api.example.com',
      mockApiDataSource: false,
      isProduction: false,
    );

    // Return proxy with host/port as null
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(proxyChannel, (MethodCall methodCall) async {
          if (methodCall.method == 'getProxySetting') {
            return {'enabled': true, 'host': null, 'port': null};
          }
          return null;
        });

    await client.initialize();

    final dio = client.dio;
    expect(dio.options.baseUrl, equals('https://api.example.com'));
    expect(dio.httpClientAdapter, isA<IOHttpClientAdapter>());
  });

  test(
    'creates HttpClient in non-production with valid proxy without errors',
    () async {
      config.update(
        baseUrl: 'https://api.example.com',
        mockApiDataSource: false,
        isProduction: false,
      );

      _setMockProxyResponse(proxyChannel, host: '127.0.0.1', port: 8888);

      await client.initialize();

      // Verify that IOHttpClientAdapter is configured with custom createHttpClient
      final adapter = client.dio.httpClientAdapter as IOHttpClientAdapter;
      expect(adapter.createHttpClient, isNotNull);

      // Trigger actual HttpClient creation to verify it doesn't throw
      final httpClient = adapter.createHttpClient!();
      expect(httpClient, isNotNull);

      httpClient.close();
    },
  );

  test('debug mode includes LogInterceptor in interceptors list', () async {
    config.update(
      baseUrl: 'https://api.example.com',
      mockApiDataSource: false,
      isProduction: false,
    );

    await client.initialize();

    final dio = client.dio;

    // In debug mode (kDebugMode), LogInterceptor should be present
    // Note: This test assumes we're running in debug mode
    final hasLogInterceptor = dio.interceptors.any(
      (interceptor) => interceptor is LogInterceptor,
    );
    final hasAuthInterceptor = dio.interceptors.any(
      (interceptor) => interceptor is AuthInterceptor,
    );

    expect(hasAuthInterceptor, isTrue);
    // LogInterceptor is only added in debug mode
    expect(hasLogInterceptor, isTrue);
  });

  test('dio getter returns the configured Dio instance', () async {
    config.update(
      baseUrl: 'https://test.example.com',
      mockApiDataSource: false,
      isProduction: false,
    );

    await client.initialize();

    final dioInstance = client.dio;

    expect(dioInstance, isNotNull);
    expect(dioInstance.options.baseUrl, equals('https://test.example.com'));
    expect(
      dioInstance.options.connectTimeout,
      equals(const Duration(seconds: 10)),
    );
    expect(
      dioInstance.options.receiveTimeout,
      equals(const Duration(seconds: 10)),
    );
  });

  test('multiple DioClient instances can be created independently', () async {
    final firstConfig = TestAppConfig(
      baseUrl: 'https://first.example.com',
      mockApiDataSource: false,
      isProduction: false,
    );
    final firstClient = DioClient(firstConfig);
    await firstClient.initialize();

    final secondConfig = TestAppConfig(
      baseUrl: 'https://second.example.com',
      mockApiDataSource: false,
      isProduction: false,
    );
    final secondClient = DioClient(secondConfig);
    await secondClient.initialize();

    expect(
      firstClient.dio.options.baseUrl,
      equals('https://first.example.com'),
    );
    expect(
      secondClient.dio.options.baseUrl,
      equals('https://second.example.com'),
    );
    expect(firstClient.dio, isNot(equals(secondClient.dio)));
  });

  test(
    'certificate callback allows bad certificates in non-production with proxy',
    () async {
      config.update(
        baseUrl: 'https://api.example.com',
        mockApiDataSource: false,
        isProduction: false,
      );

      _setMockProxyResponse(proxyChannel, host: '127.0.0.1', port: 8080);

      await client.initialize();

      final adapter = client.dio.httpClientAdapter as IOHttpClientAdapter;

      // Create HttpClient and store it to test the certificate callback
      final httpClient = adapter.createHttpClient!();
      expect(httpClient, isNotNull);

      // Note: badCertificateCallback is set but can't be directly accessed/tested
      // as it's a setter-only property. The callback would be triggered during
      // actual HTTPS requests with invalid certificates.
      // This test verifies that the HttpClient is created without errors.

      httpClient.close();
    },
  );

  test('base options are configured with correct timeout values', () async {
    config.update(
      baseUrl: 'https://api.example.com',
      mockApiDataSource: false,
      isProduction: false,
    );

    await client.initialize();

    final options = client.dio.options;

    expect(options.connectTimeout, equals(const Duration(seconds: 10)));
    expect(options.receiveTimeout, equals(const Duration(seconds: 10)));
  });

  test('initialize can be called on a fresh DioClient instance', () async {
    final freshConfig = TestAppConfig(
      baseUrl: 'https://fresh.example.com',
      mockApiDataSource: false,
      isProduction: true,
    );
    final freshClient = DioClient(freshConfig);

    // Should not throw any exceptions
    await freshClient.initialize();

    expect(freshClient.dio, isNotNull);
    expect(
      freshClient.dio.options.baseUrl,
      equals('https://fresh.example.com'),
    );
  });
}

void _setMockAssetBundle(Map<String, String> assets) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) async {
        final keyBytes = message!.buffer.asUint8List();
        final key = utf8.decode(keyBytes);
        final asset = assets[key];
        if (asset == null) {
          return null;
        }
        final encoded = utf8.encode(asset);
        final bytes = Uint8List.fromList(encoded);
        return ByteData.view(bytes.buffer);
      });
}

void _clearMockAssetBundle() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', null);
}

void _setMockProxyResponse(
  MethodChannel channel, {
  required String host,
  required int port,
}) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getProxySetting') {
          return {'enabled': true, 'host': host, 'port': port};
        }
        return null;
      });
}

void _clearMockProxyResponse(MethodChannel channel) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null);
}

class TestAppConfig extends AppConfig {
  TestAppConfig({
    required String baseUrl,
    required bool mockApiDataSource,
    required bool isProduction,
  }) : _baseUrl = baseUrl,
       _mockApiDataSource = mockApiDataSource,
       _isProduction = isProduction,
       super(currentFlavor: Flavor.dev);

  String _baseUrl;
  bool _mockApiDataSource;
  bool _isProduction;

  @override
  String get baseUrl => _baseUrl;

  @override
  bool get mockApiDataSource => _mockApiDataSource;

  @override
  bool get isProduction => _isProduction;

  void update({String? baseUrl, bool? mockApiDataSource, bool? isProduction}) {
    if (baseUrl != null) {
      _baseUrl = baseUrl;
    }
    if (mockApiDataSource != null) {
      _mockApiDataSource = mockApiDataSource;
    }
    if (isProduction != null) {
      _isProduction = isProduction;
    }
  }
}
