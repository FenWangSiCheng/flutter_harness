import 'dart:io';

import 'harness_process.dart';
import 'harness_support.dart';

class DevAppInstaller {
  const DevAppInstaller({
    required this.process,
    required this.stdout,
    required this.stderr,
  });

  final HarnessProcess process;
  final Stdout stdout;
  final IOSink stderr;

  Future<int> buildAndInstall(String platform) async {
    return switch (platform) {
      'ios' => _buildAndInstallIos(),
      'android' => _buildAndInstallAndroid(),
      _ => _unsupportedPlatform(platform),
    };
  }

  Future<int> _buildAndInstallIos() async {
    final booted = await process.capture('xcrun', [
      'simctl',
      'list',
      'devices',
      'booted',
    ]);
    final bootedOk =
        booted['exit_code'] == 0 &&
        (booted['stdout'] as String).contains('Booted');
    if (!bootedOk) {
      stderr.writeln('No booted iOS simulator. Boot one with:');
      stderr.writeln('  xcrun simctl boot "iPhone 16 Pro"');
      return 1;
    }

    stdout.writeln('Building iOS dev app for simulator...');
    final buildResult = await process.run(
      process.flutterCommand([
        'build',
        'ios',
        '--flavor',
        devFlavor,
        '--dart-define-from-file',
        devDartDefines,
        '--debug',
        '--simulator',
      ]),
    );
    if (buildResult != 0) {
      stderr.writeln('iOS build failed.');
      return buildResult;
    }

    stdout.writeln('Installing on booted iOS simulator...');
    return process.run(
      const CommandSpec('xcrun', [
        'simctl',
        'install',
        'booted',
        'build/ios/iphonesimulator/Runner.app',
      ]),
    );
  }

  Future<int> _buildAndInstallAndroid() async {
    final devices = await process.capture('adb', ['devices']);
    final deviceOk =
        devices['exit_code'] == 0 &&
        (devices['stdout'] as String).contains(RegExp(r'device\s*$'));
    if (!deviceOk) {
      stderr.writeln('No Android device/emulator connected via adb.');
      return 1;
    }

    stdout.writeln('Building Android dev APK...');
    final buildResult = await process.run(
      process.flutterCommand([
        'build',
        'apk',
        '--flavor',
        devFlavor,
        '--dart-define-from-file',
        devDartDefines,
        '--debug',
      ]),
    );
    if (buildResult != 0) {
      stderr.writeln('Android build failed.');
      return buildResult;
    }

    stdout.writeln('Installing on Android device...');
    return process.run(
      const CommandSpec('adb', [
        'install',
        '-r',
        'build/app/outputs/flutter-apk/app-dev-debug.apk',
      ]),
    );
  }

  int _unsupportedPlatform(String platform) {
    stderr.writeln('Unsupported platform "$platform".');
    return 64;
  }
}
