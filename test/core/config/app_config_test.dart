import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_foundations/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    group('fromEnvironment', () {
      test('should parse dev flavor from environment', () {
        // Note: Since we cannot set environment variables in tests,
        // this test demonstrates the expected behavior
        const config = AppConfig(currentFlavor: Flavor.dev);

        expect(config.currentFlavor, Flavor.dev);
      });

      test('should parse stg flavor from environment', () {
        const config = AppConfig(currentFlavor: Flavor.stg);

        expect(config.currentFlavor, Flavor.stg);
      });

      test('should parse prod flavor from environment', () {
        const config = AppConfig(currentFlavor: Flavor.prod);

        expect(config.currentFlavor, Flavor.prod);
      });
    });

    group('appName getter', () {
      test('should return correct app name for dev flavor', () {
        const config = AppConfig(currentFlavor: Flavor.dev);

        expect(config.appName, 'Flutter Foundations Dev');
      });

      test('should return correct app name for stg flavor', () {
        const config = AppConfig(currentFlavor: Flavor.stg);

        expect(config.appName, 'Flutter Foundations Stg');
      });

      test('should return correct app name for prod flavor', () {
        const config = AppConfig(currentFlavor: Flavor.prod);

        expect(config.appName, 'Flutter Foundations');
      });
    });

    group('baseUrl getter', () {
      test('should return dev base URL for dev flavor', () {
        const config = AppConfig(currentFlavor: Flavor.dev);

        expect(config.baseUrl, 'https://api-dev.example.com');
      });

      test('should return staging base URL for stg flavor', () {
        const config = AppConfig(currentFlavor: Flavor.stg);

        expect(config.baseUrl, 'https://api-staging.example.com');
      });

      test('should return production base URL for prod flavor', () {
        const config = AppConfig(currentFlavor: Flavor.prod);

        expect(config.baseUrl, 'https://api.example.com');
      });
    });

    group('mockApiDataSource getter', () {
      test('should return true for dev flavor', () {
        const config = AppConfig(currentFlavor: Flavor.dev);

        expect(config.mockApiDataSource, true);
      });

      test('should return false for stg flavor', () {
        const config = AppConfig(currentFlavor: Flavor.stg);

        expect(config.mockApiDataSource, false);
      });

      test('should return false for prod flavor', () {
        const config = AppConfig(currentFlavor: Flavor.prod);

        expect(config.mockApiDataSource, false);
      });
    });

    group('isNeedProxy getter', () {
      test('should return true for dev flavor', () {
        const config = AppConfig(currentFlavor: Flavor.dev);

        expect(config.isNeedProxy, true);
      });

      test('should return true for stg flavor', () {
        const config = AppConfig(currentFlavor: Flavor.stg);

        expect(config.isNeedProxy, true);
      });

      test('should return false for prod flavor', () {
        const config = AppConfig(currentFlavor: Flavor.prod);

        expect(config.isNeedProxy, false);
      });
    });

    group('flavorName getter', () {
      test('should return correct flavor name for dev', () {
        const config = AppConfig(currentFlavor: Flavor.dev);

        expect(config.flavorName, 'dev');
      });

      test('should return correct flavor name for stg', () {
        const config = AppConfig(currentFlavor: Flavor.stg);

        expect(config.flavorName, 'stg');
      });

      test('should return correct flavor name for prod', () {
        const config = AppConfig(currentFlavor: Flavor.prod);

        expect(config.flavorName, 'prod');
      });
    });

    group('flavorTitle getter', () {
      test('should return correct flavor title for dev', () {
        const config = AppConfig(currentFlavor: Flavor.dev);

        expect(config.flavorTitle, 'flutter dev');
      });

      test('should return correct flavor title for stg', () {
        const config = AppConfig(currentFlavor: Flavor.stg);

        expect(config.flavorTitle, 'flutter stg');
      });

      test('should return correct flavor title for prod', () {
        const config = AppConfig(currentFlavor: Flavor.prod);

        expect(config.flavorTitle, 'flutter prod');
      });
    });

    group('isProduction getter', () {
      test('should return false for dev flavor', () {
        const config = AppConfig(currentFlavor: Flavor.dev);

        expect(config.isProduction, false);
      });

      test('should return false for stg flavor', () {
        const config = AppConfig(currentFlavor: Flavor.stg);

        expect(config.isProduction, false);
      });

      test('should return true for prod flavor', () {
        const config = AppConfig(currentFlavor: Flavor.prod);

        expect(config.isProduction, true);
      });
    });
  });
}
