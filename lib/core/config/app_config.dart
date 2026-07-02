enum Flavor { dev, stg, prod }

class AppConfig {
  const AppConfig({required this.currentFlavor});

  final Flavor currentFlavor;

  factory AppConfig.fromEnvironment() {
    const flavorString = String.fromEnvironment('flavor', defaultValue: 'prod');
    return AppConfig(currentFlavor: _parseFlavor(flavorString));
  }

  String get appName => switch (currentFlavor) {
    Flavor.dev => 'Flutter Foundations Dev',
    Flavor.stg => 'Flutter Foundations Stg',
    Flavor.prod => 'Flutter Foundations',
  };

  String get baseUrl => switch (currentFlavor) {
    Flavor.dev => 'https://api-dev.example.com',
    Flavor.stg => 'https://api-staging.example.com',
    Flavor.prod => 'https://api.example.com',
  };

  bool get mockApiDataSource => currentFlavor == Flavor.dev;

  bool get isNeedProxy => !isProduction;

  String get flavorName => currentFlavor.name;

  String get flavorTitle => switch (currentFlavor) {
    Flavor.dev => 'flutter dev',
    Flavor.stg => 'flutter stg',
    Flavor.prod => 'flutter prod',
  };

  bool get isProduction => currentFlavor == Flavor.prod;

  Map<String, Object?> get harnessContext {
    return {
      'flavor': flavorName,
      'app_name': appName,
      'base_url': baseUrl,
      'mock_api_data_source': mockApiDataSource,
      'is_need_proxy': isNeedProxy,
      'is_production': isProduction,
    };
  }
}

Flavor _parseFlavor(String flavorString) {
  return switch (flavorString.toLowerCase()) {
    'dev' => Flavor.dev,
    'stg' => Flavor.stg,
    _ => Flavor.prod,
  };
}
