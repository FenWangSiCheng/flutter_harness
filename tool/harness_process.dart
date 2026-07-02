import 'dart:io';

import 'harness_support.dart';

const devFlavor = 'dev';
const devDartDefines = 'dart_defines/dev.json';

class HarnessProcess {
  const HarnessProcess({required this.stdout, required this.stderr});

  final Stdout stdout;
  final IOSink stderr;

  CommandSpec dartCommand(List<String> arguments) {
    return CommandSpec('fvm', ['dart', ...arguments]);
  }

  CommandSpec flutterCommand(List<String> arguments) {
    return CommandSpec('fvm', ['flutter', ...arguments]);
  }

  CommandSpec harnessCommand(List<String> arguments) {
    return dartCommand(['run', 'tool/harness.dart', ...arguments]);
  }

  CommandSpec formatCommand() {
    return dartCommand([
      'format',
      '--set-exit-if-changed',
      'lib',
      'test',
      'tool',
    ]);
  }

  Future<int> runAll(List<CommandSpec> commands) async {
    for (final command in commands) {
      final result = await run(command);
      if (result != 0) return result;
    }
    return 0;
  }

  Future<int> run(CommandSpec command) async {
    stdout.writeln('> ${command.executable} ${command.arguments.join(' ')}');
    final process = await Process.start(
      command.executable,
      command.arguments,
      mode: ProcessStartMode.inheritStdio,
    );
    return process.exitCode;
  }

  Future<Map<String, Object?>> capture(
    String executable,
    List<String> arguments,
  ) async {
    final command = '$executable ${arguments.join(' ')}';
    final env = _environmentFor(executable);

    try {
      final result = await Process.run(
        executable,
        arguments,
        environment: env.isEmpty ? null : env,
      );
      return {
        'command': command,
        'exit_code': result.exitCode,
        'stdout': result.stdout.toString().trim(),
        'stderr': result.stderr.toString().trim(),
      };
    } on ProcessException catch (error) {
      return {
        'command': command,
        'exit_code': 127,
        'stdout': '',
        'stderr': error.message,
      };
    }
  }

  Map<String, String> _environmentFor(String executable) {
    if (executable != 'adb') return const {};

    for (final path in _androidPlatformToolPaths()) {
      final adbPath = '$path/adb';
      if (File(adbPath).existsSync()) {
        return {'PATH': '${Platform.environment['PATH']}:$path'};
      }
    }
    return const {};
  }

  Iterable<String> _androidPlatformToolPaths() sync* {
    final home = Platform.environment['HOME'];
    final androidHome = Platform.environment['ANDROID_HOME'];
    final androidSdkRoot = Platform.environment['ANDROID_SDK_ROOT'];

    if (androidHome != null) yield '$androidHome/platform-tools';
    if (androidSdkRoot != null) yield '$androidSdkRoot/platform-tools';
    if (home != null) {
      yield '$home/Library/Android/sdk/platform-tools';
      yield '$home/Android/Sdk/platform-tools';
    }
    yield '/usr/local/share/android-sdk/platform-tools';
    yield '/opt/android-sdk/platform-tools';
  }
}
