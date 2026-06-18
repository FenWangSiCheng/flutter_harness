enum Flavor { dev, stg, prod }

class AppConfig {
  final Flavor currentFlavor;

  const AppConfig({required this.currentFlavor});

  factory AppConfig.fromEnvironment() {
    const flavorString = String.fromEnvironment('flavor', defaultValue: 'prod');
    final flavor = _parseFlavorFromString(flavorString);

    return AppConfig(currentFlavor: flavor);
  }

  String get appName {
    switch (currentFlavor) {
      case Flavor.dev:
        return 'Flutter Foundations Dev';
      case Flavor.stg:
        return 'Flutter Foundations Stg';
      case Flavor.prod:
        return 'Flutter Foundations';
    }
  }

  String get baseUrl {
    switch (currentFlavor) {
      case Flavor.dev:
        return 'https://api-dev.example.com';
      case Flavor.stg:
        return 'https://api-staging.example.com';
      case Flavor.prod:
        return 'https://api.example.com';
    }
  }

  bool get mockApiDataSource {
    switch (currentFlavor) {
      case Flavor.dev:
        return true;
      case Flavor.stg:
        return false;
      case Flavor.prod:
        return false;
    }
  }

  bool get isNeedProxy {
    switch (currentFlavor) {
      case Flavor.dev:
        return true;
      case Flavor.stg:
        return true;
      case Flavor.prod:
        return false;
    }
  }

  String get flavorName => currentFlavor.name;

  String get flavorTitle {
    switch (currentFlavor) {
      case Flavor.dev:
        return 'flutter dev';
      case Flavor.stg:
        return 'flutter stg';
      case Flavor.prod:
        return 'flutter prod';
    }
  }

  bool get isProduction {
    switch (currentFlavor) {
      case Flavor.dev:
        return false;
      case Flavor.stg:
        return false;
      case Flavor.prod:
        return true;
    }
  }

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

Flavor _parseFlavorFromString(String flavorString) {
  switch (flavorString.toLowerCase()) {
    case 'dev':
      return Flavor.dev;
    case 'stg':
      return Flavor.stg;
    case 'prod':
      return Flavor.prod;
    default:
      return Flavor.prod;
  }
}
