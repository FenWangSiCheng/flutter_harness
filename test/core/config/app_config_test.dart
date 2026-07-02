import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_foundations/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    const cases = <_FlavorCase>[
      _FlavorCase(
        flavor: Flavor.dev,
        appName: 'Flutter Foundations Dev',
        baseUrl: 'https://api-dev.example.com',
        mockApiDataSource: true,
        isNeedProxy: true,
        flavorName: 'dev',
        flavorTitle: 'flutter dev',
        isProduction: false,
      ),
      _FlavorCase(
        flavor: Flavor.stg,
        appName: 'Flutter Foundations Stg',
        baseUrl: 'https://api-staging.example.com',
        mockApiDataSource: false,
        isNeedProxy: true,
        flavorName: 'stg',
        flavorTitle: 'flutter stg',
        isProduction: false,
      ),
      _FlavorCase(
        flavor: Flavor.prod,
        appName: 'Flutter Foundations',
        baseUrl: 'https://api.example.com',
        mockApiDataSource: false,
        isNeedProxy: false,
        flavorName: 'prod',
        flavorTitle: 'flutter prod',
        isProduction: true,
      ),
    ];

    for (final c in cases) {
      group('${c.flavor.name} flavor', () {
        final config = AppConfig(currentFlavor: c.flavor);

        test('exposes currentFlavor', () {
          expect(config.currentFlavor, c.flavor);
        });

        test('appName', () => expect(config.appName, c.appName));
        test('baseUrl', () => expect(config.baseUrl, c.baseUrl));
        test(
          'mockApiDataSource',
          () => expect(config.mockApiDataSource, c.mockApiDataSource),
        );
        test('isNeedProxy', () => expect(config.isNeedProxy, c.isNeedProxy));
        test('flavorName', () => expect(config.flavorName, c.flavorName));
        test('flavorTitle', () => expect(config.flavorTitle, c.flavorTitle));
        test('isProduction', () => expect(config.isProduction, c.isProduction));
      });
    }
  });
}

class _FlavorCase {
  const _FlavorCase({
    required this.flavor,
    required this.appName,
    required this.baseUrl,
    required this.mockApiDataSource,
    required this.isNeedProxy,
    required this.flavorName,
    required this.flavorTitle,
    required this.isProduction,
  });

  final Flavor flavor;
  final String appName;
  final String baseUrl;
  final bool mockApiDataSource;
  final bool isNeedProxy;
  final String flavorName;
  final String flavorTitle;
  final bool isProduction;
}
