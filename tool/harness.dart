import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final command = args.isEmpty ? 'help' : args.first;
  final runner = HarnessRunner(stdout: stdout, stderr: stderr);

  late final int exitCode;
  switch (command) {
    case 'bootstrap':
      exitCode = await runner.bootstrap();
    case 'check':
      exitCode = await runner.check();
    case 'doctor':
      exitCode = await runner.doctor();
    case 'format':
      exitCode = await runner.formatCheck();
    case 'structure':
      exitCode = await runner.structure();
    case 'test':
      exitCode = await runner.test();
    case 'help':
    case '--help':
    case '-h':
      exitCode = runner.help();
    default:
      exitCode = runner.unknown(command);
  }

  exit(exitCode);
}

class HarnessRunner {
  HarnessRunner({required this.stdout, required this.stderr});

  final Stdout stdout;
  final IOSink stderr;

  int help() {
    stdout.writeln('Flutter Foundations harness');
    stdout.writeln('');
    stdout.writeln('Usage: fvm dart run tool/harness.dart <command>');
    stdout.writeln('');
    stdout.writeln('Commands:');
    stdout.writeln('  bootstrap  Install dependencies and regenerate code');
    stdout.writeln('  doctor     Print tool and repository diagnostics');
    stdout.writeln('  format     Check formatting for lib, test, and tool');
    stdout.writeln('  structure  Run harness structural tests');
    stdout.writeln('  test       Run the Flutter test suite');
    stdout.writeln('  check      Run format, structure, analyze, and tests');
    return 0;
  }

  int unknown(String command) {
    stderr.writeln('Unknown harness command: $command');
    help();
    return 64;
  }

  Future<int> bootstrap() async {
    return _runAll([
      CommandSpec('fvm', ['flutter', 'pub', 'get']),
      CommandSpec('fvm', [
        'flutter',
        'packages',
        'pub',
        'run',
        'build_runner',
        'build',
        '--delete-conflicting-outputs',
      ]),
    ]);
  }

  Future<int> check() async {
    return _runAll([
      CommandSpec('fvm', [
        'dart',
        'format',
        '--set-exit-if-changed',
        'lib',
        'test',
        'tool',
      ]),
      CommandSpec('fvm', ['dart', 'run', 'tool/harness.dart', 'structure']),
      CommandSpec('fvm', ['flutter', 'analyze']),
      CommandSpec('fvm', ['flutter', 'test']),
    ]);
  }

  Future<int> doctor() async {
    final diagnostics = <String, Object?>{
      'flutter': await _capture('fvm', ['flutter', '--version']),
      'fvm_dart': await _capture('fvm', ['dart', '--version']),
      'fvm': await _readJsonFile('.fvm/fvm_config.json'),
      'generated_files': _generatedFiles(),
      'harness_docs': _requiredHarnessFiles()
          .map((path) => {'path': path, 'exists': File(path).existsSync()})
          .toList(),
    };

    stdout.writeln(const JsonEncoder.withIndent('  ').convert(diagnostics));
    return 0;
  }

  Future<int> formatCheck() {
    return _runAll([
      CommandSpec('fvm', [
        'dart',
        'format',
        '--set-exit-if-changed',
        'lib',
        'test',
        'tool',
      ]),
    ]);
  }

  Future<int> structure() {
    return _runAll([
      CommandSpec('fvm', ['flutter', 'test', 'test/harness']),
    ]);
  }

  Future<int> test() {
    return _runAll([
      CommandSpec('fvm', ['flutter', 'test']),
    ]);
  }

  Future<int> _runAll(List<CommandSpec> commands) async {
    for (final command in commands) {
      final result = await _run(command);
      if (result != 0) {
        return result;
      }
    }
    return 0;
  }

  Future<int> _run(CommandSpec command) async {
    stdout.writeln('> ${command.executable} ${command.arguments.join(' ')}');
    final process = await Process.start(
      command.executable,
      command.arguments,
      mode: ProcessStartMode.inheritStdio,
    );
    return process.exitCode;
  }

  Future<Map<String, Object?>> _capture(
    String executable,
    List<String> arguments,
  ) async {
    final result = await Process.run(executable, arguments);
    return {
      'command': '$executable ${arguments.join(' ')}',
      'exit_code': result.exitCode,
      'stdout': result.stdout.toString().trim(),
      'stderr': result.stderr.toString().trim(),
    };
  }

  Future<Object?> _readJsonFile(String path) async {
    final file = File(path);
    if (!file.existsSync()) {
      return {'missing': path};
    }
    return jsonDecode(await file.readAsString());
  }

  List<Map<String, Object?>> _generatedFiles() {
    const files = [
      'lib/core/injection/injection.config.dart',
      'lib/features/user/data/models/user_model.freezed.dart',
      'lib/features/user/data/models/user_model.g.dart',
    ];

    return files.map((path) {
      return {'path': path, 'exists': File(path).existsSync()};
    }).toList();
  }

  List<String> _requiredHarnessFiles() {
    return const [
      'AGENTS.md',
      'docs/harness/README.md',
      'docs/harness/ARCHITECTURE.md',
      'docs/harness/VALIDATION.md',
      'docs/harness/QUALITY.md',
      'docs/harness/OPERABILITY.md',
      'docs/harness/TASKS.md',
      'tool/harness.dart',
    ];
  }
}

class CommandSpec {
  const CommandSpec(this.executable, this.arguments);

  final String executable;
  final List<String> arguments;
}
