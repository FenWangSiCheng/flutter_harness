import '../config/app_config.dart';
import '../network/dio_client.dart';
import 'injection.config.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

final getIt = GetIt.instance;
AppConfig? _configuredAppConfig;

@InjectableInit()
Future<void> configureDependencies(AppConfig appConfig) async {
  _configuredAppConfig = appConfig;
  await getIt.init();
}

@module
abstract class RegisterModule {
  @singleton
  AppConfig get appConfig =>
      _configuredAppConfig ?? AppConfig.fromEnvironment();

  @preResolve
  @lazySingleton
  Future<DioClient> dioClient(AppConfig appConfig) async {
    final client = DioClient(appConfig);
    await client.initialize();
    return client;
  }

  @lazySingleton
  Dio dio(DioClient dioClient) => dioClient.dio;
}
