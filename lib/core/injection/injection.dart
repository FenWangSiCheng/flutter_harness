import '../config/app_config.dart';
import '../network/dio_client.dart';
import 'injection.config.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies(AppConfig appConfig) async {
  // Register AppConfig first
  getIt.registerSingleton<AppConfig>(appConfig);

  await getIt.init();
}

@module
abstract class RegisterModule {
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
