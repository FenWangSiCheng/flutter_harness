import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_foundations/core/config/app_config.dart';
import 'package:flutter_foundations/core/injection/injection.dart';
import 'package:flutter_foundations/core/network/dio_client.dart';

void main() {
  group('Dependency Injection', () {
    setUp(() async {
      // Reset GetIt before each test
      await getIt.reset();
    });

    tearDown(() async {
      await getIt.reset();
    });

    test('configureDependencies should register AppConfig', () async {
      const testConfig = AppConfig(currentFlavor: Flavor.dev);

      await configureDependencies(testConfig);

      expect(getIt.isRegistered<AppConfig>(), true);
      expect(getIt.get<AppConfig>(), testConfig);
    });

    test('configureDependencies should register DioClient', () async {
      const testConfig = AppConfig(currentFlavor: Flavor.prod);

      await configureDependencies(testConfig);

      expect(getIt.isRegistered<DioClient>(), true);
      expect(getIt<DioClient>(), isA<DioClient>());
    });

    test('configureDependencies should register Dio instance', () async {
      const testConfig = AppConfig(currentFlavor: Flavor.prod);

      await configureDependencies(testConfig);

      expect(getIt.isRegistered<Dio>(), true);
      expect(getIt<Dio>(), isA<Dio>());
    });

    test('Dio instance should be obtained from DioClient', () async {
      const testConfig = AppConfig(currentFlavor: Flavor.prod);

      await configureDependencies(testConfig);

      final dioClient = getIt<DioClient>();
      final dio = getIt<Dio>();

      expect(dio, same(dioClient.dio));
    });

    test('DioClient should be initialized with correct AppConfig', () async {
      const testConfig = AppConfig(currentFlavor: Flavor.dev);

      await configureDependencies(testConfig);

      final dioClient = getIt<DioClient>();

      // Verify DioClient was initialized with correct config
      expect(dioClient.dio.options.baseUrl, testConfig.baseUrl);
    });

    test('should handle reconfiguration after reset', () async {
      const config1 = AppConfig(currentFlavor: Flavor.dev);

      await configureDependencies(config1);

      expect(getIt.isRegistered<AppConfig>(), true);
      expect(getIt.get<AppConfig>().currentFlavor, Flavor.dev);

      // Reset and configure again with different config
      await getIt.reset();

      const config2 = AppConfig(currentFlavor: Flavor.prod);
      await configureDependencies(config2);

      expect(getIt.isRegistered<AppConfig>(), true);
      expect(getIt.get<AppConfig>().currentFlavor, Flavor.prod);
    });

    test('DioClient should be singleton', () async {
      const testConfig = AppConfig(currentFlavor: Flavor.prod);

      await configureDependencies(testConfig);

      final dioClient1 = getIt<DioClient>();
      final dioClient2 = getIt<DioClient>();

      expect(dioClient1, same(dioClient2));
    });

    test('Dio should be singleton', () async {
      const testConfig = AppConfig(currentFlavor: Flavor.prod);

      await configureDependencies(testConfig);

      final dio1 = getIt<Dio>();
      final dio2 = getIt<Dio>();

      expect(dio1, same(dio2));
    });
  });
}
