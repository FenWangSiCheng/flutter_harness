import 'dart:async';
import 'package:flutter/material.dart';
import 'core/widgets/app.dart';
import 'core/config/app_config.dart';
import 'core/harness/harness_logger.dart';
import 'core/injection/injection.dart';

FutureOr<void> main() async {
  final startupStopwatch = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();
  HarnessLogger.event('app.bootstrap.start');

  final appConfig = AppConfig.fromEnvironment();
  HarnessLogger.event('app.config.loaded', fields: appConfig.harnessContext);

  // Initialize dependency injection with AppConfig
  await configureDependencies(appConfig);
  HarnessLogger.event(
    'app.dependencies.ready',
    fields: appConfig.harnessContext,
  );
  HarnessLogger.event(
    'app.bootstrap.ready',
    fields: {
      ...appConfig.harnessContext,
      'elapsed_ms': startupStopwatch.elapsedMilliseconds,
    },
  );

  runApp(const App());
}
