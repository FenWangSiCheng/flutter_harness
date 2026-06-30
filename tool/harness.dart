import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart' as yaml;

Future<void> main(List<String> args) async {
  final command = args.isEmpty ? 'help' : args.first;
  final runner = HarnessRunner(stdout: stdout, stderr: stderr);

  late final int exitCode;
  switch (command) {
    case 'bootstrap':
      exitCode = await runner.bootstrap();
    case 'check':
      exitCode = await runner.check();
    case 'coverage':
      exitCode = await runner.coverage(args.sublist(1));
    case 'doctor':
      exitCode = await runner.doctor();
    case 'eval':
      exitCode = await runner.eval();
    case 'eval-all':
      exitCode = await runner.eval(platform: 'all');
    case 'eval-android':
      exitCode = await runner.eval(platform: 'android');
    case 'eval-ios':
      exitCode = await runner.eval(platform: 'ios');
    case 'format':
      exitCode = await runner.formatCheck();
    case 'structure':
      exitCode = await runner.structure();
    case 'spec':
      exitCode = await runner.spec(args.sublist(1));
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
    stdout.writeln(
      '  coverage   Run tests with the non-UI logic coverage gate',
    );
    stdout.writeln('  doctor     Print tool and repository diagnostics');
    stdout.writeln('  eval       Run optional Maestro E2E evaluation flows');
    stdout.writeln(
      '  eval-all   Run iOS and Android Maestro E2E evaluation flows',
    );
    stdout.writeln('  eval-android Run Android Maestro E2E evaluation flows');
    stdout.writeln('  eval-ios   Run iOS Maestro E2E evaluation flows');
    stdout.writeln('  format     Check formatting for lib, test, and tool');
    stdout.writeln('  structure  Run harness structural tests');
    stdout.writeln(
      '  spec       Spec workflow: new <id> | review <id> [--approve] | '
      'accept <id> [--maestro] [--platform ios|android|all] | ui-map [--check]',
    );
    stdout.writeln('  test       Run the Flutter test suite');
    stdout.writeln(
      '  check      Run format, structure, analyze, and coverage-gated tests',
    );
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
      CommandSpec('fvm', ['dart', 'run', 'build_runner', 'build']),
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
      CommandSpec('fvm', ['dart', 'run', 'tool/harness.dart', 'coverage']),
    ]);
  }

  Future<int> coverage(List<String> args) async {
    final minimum = _coverageMinimum(args);
    final checkOnly = args.contains('--check-only');

    if (!checkOnly) {
      final testExit = await _run(
        CommandSpec('fvm', ['flutter', 'test', '--coverage']),
      );
      if (testExit != 0) return testExit;
    }

    final coverageFile = File('coverage/lcov.info');
    if (!coverageFile.existsSync()) {
      stderr.writeln('Missing coverage report: ${coverageFile.path}');
      stderr.writeln('Run: fvm dart run tool/harness.dart coverage');
      return 1;
    }

    final summary = _parseCoverage(coverageFile);
    stdout.writeln(
      'Coverage gate: ${summary.hitLines}/${summary.foundLines} lines '
      '= ${summary.percent.toStringAsFixed(2)}% '
      '(minimum ${minimum.toStringAsFixed(2)}%).',
    );
    stdout.writeln(
      'Coverage excludes UI pages/router/widgets/resources and generated files; '
      'UI behavior is accepted by Maestro.',
    );

    final lowFiles =
        summary.files
            .where((file) => file.foundLines > 0 && file.percent < 90)
            .toList()
          ..sort((a, b) => a.percent.compareTo(b.percent));
    if (lowFiles.isNotEmpty) {
      stdout.writeln('Lowest covered included files:');
      for (final file in lowFiles.take(5)) {
        stdout.writeln(
          '  ${file.percent.toStringAsFixed(2)}% '
          '${file.hitLines}/${file.foundLines} ${file.path}',
        );
      }
    }

    if (summary.percent + 0.0001 < minimum) {
      stderr.writeln(
        'Coverage ${summary.percent.toStringAsFixed(2)}% is below '
        '${minimum.toStringAsFixed(2)}%.',
      );
      return 1;
    }

    return 0;
  }

  Future<int> doctor() async {
    final diagnostics = <String, Object?>{
      'flutter': await _capture('fvm', ['flutter', '--version']),
      'fvm_dart': await _capture('fvm', ['dart', '--version']),
      'fvm': await _readJsonFile('.fvm/fvm_config.json'),
      'maestro': await _capture('maestro', ['--version']),
      'generated_files': _generatedFiles(),
      'harness_files': _requiredHarnessFiles()
          .map((path) => {'path': path, 'exists': File(path).existsSync()})
          .toList(),
      'harness_directories': _requiredHarnessDirectories()
          .map((path) => {'path': path, 'exists': Directory(path).existsSync()})
          .toList(),
      'agent_skills': _agentSkills(),
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

  Future<int> eval({String? platform}) async {
    final maestro = await _capture('maestro', ['--version']);
    if (maestro['exit_code'] != 0) {
      stderr.writeln('Maestro CLI is not installed or not on PATH.');
      stderr.writeln('Install it with: brew tap mobile-dev-inc/tap');
      stderr.writeln('Then run: brew install mobile-dev-inc/tap/maestro');
      stderr.writeln('After launching a dev app on a simulator/device, run:');
      stderr.writeln('  fvm dart run tool/harness.dart eval');
      return 69;
    }

    for (final plat in _platformsFor(platform ?? 'ios')) {
      final installExit = await _buildAndInstall(plat);
      if (installExit != 0) {
        stderr.writeln(
          'Failed to build and install dev app for platform "$plat".',
        );
        return 69;
      }

      final target = switch (plat) {
        'android' => '.maestro/android',
        'ios' => '.maestro/ios',
        _ => '.maestro',
      };

      final exitCode = await _runAll([
        CommandSpec('maestro', ['test', '--platform', plat, target]),
      ]);
      if (exitCode != 0) return exitCode;
    }
    return 0;
  }

  Future<int> structure() {
    return _runAll([
      CommandSpec('fvm', ['flutter', 'test', 'test/harness']),
    ]);
  }

  /// Spec evaluation workflow.
  ///
  /// Four stages with two gates:
  ///   `spec new <id>`          AI scaffolds a reviewable acceptance script.
  ///   `spec review <id>`       Human reviews the acceptance checklist (gate A).
  ///       `--approve`          Mark the linked feature spec-approved.
  ///   `spec accept <id>`       AI runs acceptance and reports pass/fail (gate B).
  ///       `--maestro`          Also run device-backed Maestro criteria.
  ///       `--platform <p>`     Run Maestro on `ios` (default), `android`, or `all`.
  /// Gate B writes a report. If Maestro is requested, the dev app is built and
  /// installed on the booted device before running flows.
  Future<int> spec(List<String> args) async {
    final sub = args.isEmpty ? 'help' : args.first;
    switch (sub) {
      case 'new':
        if (args.length < 2) {
          stderr.writeln('Usage: fvm dart run tool/harness.dart spec new <id>');
          return 64;
        }
        return _specNew(args[1]);
      case 'review':
        if (args.length < 2) {
          stderr.writeln(
            'Usage: fvm dart run tool/harness.dart spec review <id> [--approve]',
          );
          return 64;
        }
        return _specReview(args[1], approve: args.contains('--approve'));
      case 'accept':
        if (args.length < 2) {
          stderr.writeln(
            'Usage: fvm dart run tool/harness.dart spec accept <id> '
            '[--maestro] [--platform ios|android|all]',
          );
          return 64;
        }
        final platform = _platformArg(args);
        return _specAccept(
          args[1],
          platform: platform,
          runMaestro: args.contains('--maestro'),
        );
      case 'ui-map':
        return _specUiMap(checkOnly: args.contains('--check'));
      case 'help':
      case '--help':
      case '-h':
        stdout.writeln('Spec workflow commands:');
        stdout.writeln(
          '  spec new <id>             Scaffold a reviewable spec',
        );
        stdout.writeln(
          '  spec review <id> [--approve]  Print the acceptance checklist (gate A)',
        );
        stdout.writeln(
          '  spec accept <id> [--maestro] [--platform ios|android|all]  Run acceptance and report (gate B)',
        );
        stdout.writeln(
          '  spec ui-map [--check]      Generate or verify the canonical UI target map',
        );
        return 0;
      default:
        stderr.writeln('Unknown spec subcommand: $sub');
        return 64;
    }
  }

  String _platformArg(List<String> args) {
    final i = args.indexOf('--platform');
    if (i >= 0 && i + 1 < args.length) {
      final v = args[i + 1];
      if (v == 'ios' || v == 'android' || v == 'all') return v;
    }
    return 'ios';
  }

  double _coverageMinimum(List<String> args) {
    final i = args.indexOf('--min');
    if (i >= 0 && i + 1 < args.length) {
      final parsed = double.tryParse(args[i + 1]);
      if (parsed != null) return parsed;
    }
    return 90;
  }

  CoverageSummary _parseCoverage(File file) {
    final files = <CoverageFile>[];
    String? currentPath;
    var foundLines = 0;
    var hitLines = 0;

    void flush() {
      final path = currentPath;
      if (path == null) return;
      if (_isIncludedCoverageFile(path) && foundLines > 0) {
        files.add(
          CoverageFile(path: path, foundLines: foundLines, hitLines: hitLines),
        );
      }
    }

    for (final line in file.readAsLinesSync()) {
      if (line.startsWith('SF:')) {
        flush();
        currentPath = line.substring(3);
        foundLines = 0;
        hitLines = 0;
      } else if (line.startsWith('LF:')) {
        foundLines = int.tryParse(line.substring(3)) ?? foundLines;
      } else if (line.startsWith('LH:')) {
        hitLines = int.tryParse(line.substring(3)) ?? hitLines;
      } else if (line == 'end_of_record') {
        flush();
        currentPath = null;
        foundLines = 0;
        hitLines = 0;
      }
    }
    flush();

    return CoverageSummary(files);
  }

  bool _isIncludedCoverageFile(String path) {
    final normalized = path.replaceAll('\\', '/');
    if (!normalized.startsWith('lib/')) return false;
    if (normalized.contains('/presentation/pages/')) return false;
    if (normalized.startsWith('lib/core/router/')) return false;
    if (normalized.startsWith('lib/core/widgets/')) return false;
    if (normalized.startsWith('lib/core/resources/')) return false;
    if (normalized == 'lib/main.dart') return false;
    if (normalized.endsWith('.g.dart')) return false;
    if (normalized.endsWith('.freezed.dart')) return false;
    if (normalized == 'lib/core/injection/injection.config.dart') return false;
    return true;
  }

  List<String> _platformsFor(String platform) {
    if (platform == 'all') return const ['ios', 'android'];
    return [platform];
  }

  Future<int> _specNew(String id) async {
    final dir = Directory('docs/harness/specs/$id');
    if (dir.existsSync()) {
      stderr.writeln('Spec already exists: ${dir.path}');
      return 64;
    }
    final flow = _flowName(id);
    await dir.create(recursive: true);
    await File('${dir.path}/spec.md').writeAsString(_specMarkdownTemplate(id));
    await File(
      '${dir.path}/ui-map.delta.yaml',
    ).writeAsString(_uiMapDeltaTemplate(id));
    await File(
      '${dir.path}/acceptance.yaml',
    ).writeAsString(_acceptanceTemplate(id, flow));
    await File(
      '.maestro/ios/$flow.yaml',
    ).writeAsString(_maestroFlowTemplate('cn.com.fenrir-inc.iosAppTest.dev'));
    await File(
      '.maestro/android/$flow.yaml',
    ).writeAsString(_maestroFlowTemplate('com.example.basic_demo.dev'));
    stdout.writeln('Scaffolded spec "$id" at ${dir.path}');
    stdout.writeln(
      'Scaffolded Maestro flows: .maestro/ios/$flow.yaml, '
      '.maestro/android/$flow.yaml',
    );
    stdout.writeln('');
    stdout.writeln('Next steps:');
    stdout.writeln('  1. Fill spec.md with goal, preconditions, and steps.');
    stdout.writeln('  2. Add only new UI targets to ui-map.delta.yaml.');
    stdout.writeln(
      '  3. Map UI criteria to Maestro flows; use test files only for non-UI logic.',
    );
    stdout.writeln(
      '  4. Translate the spec steps into the Maestro flow files.',
    );
    stdout.writeln('  5. fvm dart run tool/harness.dart spec review $id');
    return 0;
  }

  String _flowName(String id) => '${id.replaceAll('-', '_')}_flow';

  String _maestroFlowTemplate(String appId) =>
      '''
appId: $appId
---
- launchApp
# Translate spec steps here. Prefer semantics_identifier ids from ui-map.yaml.
''';

  Future<int> _specReview(String id, {required bool approve}) async {
    final file = _acceptanceFile(id);
    if (file == null) {
      stderr.writeln('No acceptance.yaml found for spec "$id".');
      stderr.writeln(
        'Expected docs/harness/specs/$id/acceptance.yaml '
        'or docs/harness/specs/acceptance.yaml with spec: $id.',
      );
      return 64;
    }
    final doc = yaml.loadYaml(file.readAsStringSync()) as yaml.YamlMap;
    final acceptance = doc['acceptance'] as yaml.YamlList;
    final status = _specStatus(id);

    stdout.writeln('Spec: $id');
    if (doc['feature'] != null) {
      stdout.writeln('Feature: ${doc['feature']}  (status: $status)');
    }
    if (doc['goal'] != null) {
      stdout.writeln('Goal: ${doc['goal']}');
    }
    stdout.writeln('');
    stdout.writeln('Acceptance checklist (gate A):');
    for (final item in acceptance) {
      final m = item as yaml.YamlMap;
      stdout.writeln('  [${m['kind']}] ${m['id']}  ${m['claim']}');
    }
    stdout.writeln('');
    if (approve) {
      final updated = _setSpecStatus(id, 'spec-approved');
      if (updated) {
        stdout.writeln(
          'Marked spec "$id" as spec-approved in feature_list.json.',
        );
        stdout.writeln('Implementation may now proceed.');
      } else {
        stderr.writeln(
          'Could not find a feature linked to spec "$id" in feature_list.json.',
        );
        return 64;
      }
    } else {
      stdout.writeln('Review the checklist. To approve, run:');
      stdout.writeln(
        '  fvm dart run tool/harness.dart spec review $id --approve',
      );
    }
    return 0;
  }

  Future<int> _specUiMap({required bool checkOnly}) async {
    late final GeneratedUiMap generated;
    try {
      generated = _generateCanonicalUiMap();
    } on FormatException catch (error) {
      stderr.writeln('Could not generate UI map: ${error.message}');
      return 65;
    }
    final file = File('docs/harness/specs/ui-map.yaml');

    if (checkOnly) {
      if (!file.existsSync()) {
        stderr.writeln('Missing generated UI map: ${file.path}');
        stderr.writeln('Run: fvm dart run tool/harness.dart spec ui-map');
        return 1;
      }

      final current = file.readAsStringSync();
      if (current != generated.content) {
        stderr.writeln('Generated UI map is out of date: ${file.path}');
        stderr.writeln('Run: fvm dart run tool/harness.dart spec ui-map');
        return 1;
      }

      stdout.writeln(
        'Generated UI map is up to date: ${file.path} '
        '(${generated.targetCount} target(s) from '
        '${generated.specCount} approved spec delta(s)).',
      );
      return 0;
    }

    await file.parent.create(recursive: true);
    await file.writeAsString(generated.content);
    stdout.writeln(
      'Generated ${file.path} with ${generated.targetCount} target(s) '
      'from ${generated.specCount} approved spec delta(s).',
    );
    return 0;
  }

  Future<int> _specAccept(
    String id, {
    required String platform,
    required bool runMaestro,
    String reportFileName = 'report.json',
  }) async {
    if (platform == 'all') {
      return _specAcceptAll(id, runMaestro: runMaestro);
    }

    final file = _acceptanceFile(id);
    if (file == null) {
      stderr.writeln('No acceptance.yaml found for spec "$id".');
      return 64;
    }
    final doc = yaml.loadYaml(file.readAsStringSync()) as yaml.YamlMap;
    final acceptance = doc['acceptance'] as yaml.YamlList;

    final testFiles = <String>{};
    final maestroFlows = <String>{};
    for (final item in acceptance) {
      final m = item as yaml.YamlMap;
      final kind = m['kind'].toString();
      if (kind == 'test') {
        testFiles.add(m['file'].toString());
      } else if (kind == 'maestro') {
        maestroFlows.add((m['flow'] ?? _flowName(id)).toString());
      }
    }

    // Run non-UI unit or logic tests first.
    final testRan = testFiles.isNotEmpty;
    var testExit = 0;
    if (testRan) {
      stdout.writeln(
        '> running ${testFiles.length} test file(s) for spec "$id"',
      );
      testExit = await _run(
        CommandSpec('fvm', ['flutter', 'test', ...testFiles]),
      );
    }

    var maestroBlockedReason = '';
    final flowResults = <String, int>{};
    if (runMaestro) {
      if (maestroFlows.isEmpty) {
        maestroBlockedReason =
            'Spec "$id" has no kind: maestro acceptance criteria.';
      } else {
        final maestroOk = await _capture('maestro', ['--version']);
        if (maestroOk['exit_code'] != 0) {
          maestroBlockedReason =
              'Maestro CLI is not installed or not on PATH. Install it with: '
              'brew tap mobile-dev-inc/tap && brew install mobile-dev-inc/tap/maestro';
        }
      }

      if (maestroBlockedReason.isEmpty) {
        final missing = maestroFlows
            .map((flow) => '.maestro/$platform/$flow.yaml')
            .where((path) => !File(path).existsSync())
            .toList();
        if (missing.isNotEmpty) {
          maestroBlockedReason =
              'Missing Maestro flow file(s) for platform "$platform": '
              '${missing.join(', ')}';
        }
      }

      if (maestroBlockedReason.isEmpty) {
        final installExit = await _buildAndInstall(platform);
        if (installExit != 0) {
          maestroBlockedReason =
              'Failed to build and install dev app for platform "$platform".';
        }
      }

      if (maestroBlockedReason.isEmpty) {
        for (final flow in maestroFlows) {
          final path = '.maestro/$platform/$flow.yaml';
          stdout.writeln('> running maestro flow $path');
          flowResults[flow] = await _run(
            CommandSpec('maestro', ['test', '--platform', platform, path]),
          );
        }
      } else {
        stderr.writeln('Maestro acceptance blocked for platform "$platform":');
        stderr.writeln(maestroBlockedReason);
      }
    }
    final maestroAllPass =
        runMaestro &&
        maestroBlockedReason.isEmpty &&
        flowResults.values.every((e) => e == 0);

    final results = <Map<String, Object?>>[];
    for (final item in acceptance) {
      final m = item as yaml.YamlMap;
      final kind = m['kind'].toString();
      String verdict;
      String evidence;
      if (kind == 'test') {
        verdict = testRan && testExit == 0 ? 'pass' : 'fail';
        evidence = m['file'].toString();
      } else if (kind == 'maestro') {
        final flow = (m['flow'] ?? _flowName(id)).toString();
        if (!runMaestro) {
          verdict = 'skipped';
        } else if (maestroBlockedReason.isNotEmpty) {
          verdict = 'blocked';
        } else {
          verdict = flowResults[flow] == 0 ? 'pass' : 'fail';
        }
        evidence = '.maestro/$platform/$flow.yaml';
      } else {
        verdict = 'blocked';
        evidence = 'unknown kind $kind';
      }
      results.add({
        'id': m['id'].toString(),
        'claim': m['claim'].toString(),
        'kind': kind,
        'verdict': verdict,
        'evidence': evidence,
      });
    }

    final overall = _overallFromVerdicts(
      results.map((r) => r['verdict'].toString()),
    );

    final report = <String, Object?>{
      'spec': id,
      'feature': doc['feature']?.toString(),
      'platform': platform,
      'result': overall,
      'maestro_run': runMaestro && maestroBlockedReason.isEmpty,
      'maestro_blocked_reason': maestroBlockedReason.isEmpty
          ? null
          : maestroBlockedReason,
      'maestro_all_pass': maestroAllPass,
      'acceptance': results,
    };
    final evidenceDir = Directory('build/harness/evidence/$id');
    await evidenceDir.create(recursive: true);
    await File(
      '${evidenceDir.path}/$reportFileName',
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(report));

    stdout.writeln('');
    stdout.writeln('Acceptance report for "$id" on $platform: $overall');
    for (final r in results) {
      stdout.writeln('  [${r['verdict']}] ${r['id']}  ${r['claim']}');
    }
    stdout.writeln('Evidence: ${evidenceDir.path}/$reportFileName');
    return overall == 'PASS' ? 0 : 1;
  }

  Future<int> _specAcceptAll(String id, {required bool runMaestro}) async {
    final evidenceDir = Directory('build/harness/evidence/$id');
    final platformReports = <Map<String, Object?>>[];

    for (final plat in const ['ios', 'android']) {
      await _specAccept(
        id,
        platform: plat,
        runMaestro: runMaestro,
        reportFileName: 'report-$plat.json',
      );

      final reportFile = File('${evidenceDir.path}/report-$plat.json');
      if (reportFile.existsSync()) {
        platformReports.add(
          jsonDecode(reportFile.readAsStringSync()) as Map<String, Object?>,
        );
      } else {
        platformReports.add({
          'spec': id,
          'platform': plat,
          'result': 'BLOCKED',
          'maestro_run': false,
          'maestro_blocked_reason': 'No report was written for $plat.',
          'acceptance': const [],
        });
      }
    }

    final overall = _overallFromVerdicts(
      platformReports.map((report) => report['result'].toString()),
    );
    final summary = <String, Object?>{
      'spec': id,
      'feature': _firstStringField(platformReports, 'feature'),
      'platform': 'all',
      'result': overall,
      'maestro_run': platformReports.every((report) {
        return report['maestro_run'] == true;
      }),
      'maestro_all_pass': platformReports.every((report) {
        return report['maestro_all_pass'] == true;
      }),
      'platforms': platformReports,
    };

    await evidenceDir.create(recursive: true);
    await File(
      '${evidenceDir.path}/report.json',
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(summary));

    stdout.writeln('');
    stdout.writeln('Dual-platform acceptance report for "$id": $overall');
    for (final report in platformReports) {
      stdout.writeln('  [${report['result']}] ${report['platform']}');
    }
    stdout.writeln('Evidence: ${evidenceDir.path}/report.json');
    return overall == 'PASS' ? 0 : 1;
  }

  String? _firstStringField(
    Iterable<Map<String, Object?>> reports,
    String field,
  ) {
    for (final report in reports) {
      final value = report[field];
      if (value is String) return value;
    }
    return null;
  }

  String _overallFromVerdicts(Iterable<String> verdicts) {
    final values = verdicts.toList();
    if (values.contains('FAIL')) return 'FAIL';
    if (values.contains('fail')) return 'FAIL';
    if (values.contains('BLOCKED')) return 'BLOCKED';
    if (values.contains('blocked')) return 'BLOCKED';
    if (values.contains('SKIPPED')) return 'SKIPPED';
    if (values.contains('skipped')) return 'SKIPPED';
    if (values.contains('PASS')) return 'PASS';
    if (values.contains('pass')) return 'PASS';
    return 'SKIPPED';
  }

  /// Build and install the dev app on a booted device for [platform].
  /// Returns 0 on success, non-zero on failure.
  Future<int> _buildAndInstall(String platform) async {
    if (platform == 'ios') {
      final booted = await _capture('xcrun', [
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
      final buildResult = await _run(
        CommandSpec('fvm', [
          'flutter',
          'build',
          'ios',
          '--flavor',
          'dev',
          '--dart-define-from-file',
          'dart_defines/dev.json',
          '--debug',
          '--simulator',
        ]),
      );
      if (buildResult != 0) {
        stderr.writeln('iOS build failed.');
        return buildResult;
      }

      stdout.writeln('Installing on booted iOS simulator...');
      return _run(
        CommandSpec('xcrun', [
          'simctl',
          'install',
          'booted',
          'build/ios/iphonesimulator/Runner.app',
        ]),
      );
    }

    // android
    final devices = await _capture('adb', ['devices']);
    final deviceOk =
        devices['exit_code'] == 0 &&
        (devices['stdout'] as String).contains(RegExp(r'device\s*$'));
    if (!deviceOk) {
      stderr.writeln('No Android device/emulator connected via adb.');
      return 1;
    }

    stdout.writeln('Building Android dev APK...');
    final buildResult = await _run(
      CommandSpec('fvm', [
        'flutter',
        'build',
        'apk',
        '--flavor',
        'dev',
        '--dart-define-from-file',
        'dart_defines/dev.json',
        '--debug',
      ]),
    );
    if (buildResult != 0) {
      stderr.writeln('Android build failed.');
      return buildResult;
    }

    stdout.writeln('Installing on Android device...');
    return _run(
      CommandSpec('adb', [
        'install',
        '-r',
        'build/app/outputs/flutter-apk/app-dev-debug.apk',
      ]),
    );
  }

  File? _acceptanceFile(String id) {
    final nested = File('docs/harness/specs/$id/acceptance.yaml');
    if (nested.existsSync()) return nested;
    final flat = File('docs/harness/specs/acceptance.yaml');
    if (flat.existsSync()) {
      final doc = yaml.loadYaml(flat.readAsStringSync());
      if (doc is yaml.YamlMap && doc['spec'] == id) return flat;
    }
    return null;
  }

  String _specStatus(String id) {
    final features = _loadFeatures();
    for (final feature in features) {
      if (feature['spec'] == id) {
        return feature['status']?.toString() ?? 'unknown';
      }
    }
    return 'unlinked';
  }

  bool _setSpecStatus(String id, String status) {
    final raw = File('feature_list.json').readAsStringSync();
    final decoded = jsonDecode(raw) as Map<String, Object?>;
    final features = (decoded['features'] as List<Object?>)
        .cast<Map<String, Object?>>();
    var found = false;
    for (final feature in features) {
      if (feature['spec'] == id) {
        feature['status'] = status;
        found = true;
      }
    }
    if (!found) return false;
    File(
      'feature_list.json',
    ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(decoded));
    return true;
  }

  List<Map<String, Object?>> _loadFeatures() {
    final raw = File('feature_list.json').readAsStringSync();
    final decoded = jsonDecode(raw) as Map<String, Object?>;
    return (decoded['features'] as List<Object?>).cast<Map<String, Object?>>();
  }

  GeneratedUiMap _generateCanonicalUiMap() {
    const approvedStatuses = {
      'spec-approved',
      'implementing',
      'accepted',
      'done',
    };
    final targets = <String, Map<String, Object?>>{};
    var specCount = 0;

    for (final feature in _loadFeatures()) {
      if (!approvedStatuses.contains(feature['status'])) continue;

      final spec = feature['spec'];
      if (spec is! String || spec.isEmpty) continue;

      final deltaFile = File('docs/harness/specs/$spec/ui-map.delta.yaml');
      if (!deltaFile.existsSync()) continue;

      specCount += 1;
      final delta = yaml.loadYaml(deltaFile.readAsStringSync());
      if (delta is! yaml.YamlMap || delta['targets'] == null) continue;

      final deltaTargets = delta['targets'] as yaml.YamlMap;
      for (final key in deltaTargets.keys) {
        final targetId = key.toString();
        final rawTarget = deltaTargets[key];
        if (rawTarget is! yaml.YamlMap) {
          throw FormatException(
            'Target "$targetId" in ${deltaFile.path} must be a map.',
          );
        }

        final target = <String, Object?>{};
        for (final field in rawTarget.keys) {
          target[field.toString()] = rawTarget[field];
        }

        final existing = targets[targetId];
        if (existing != null && !_sameMap(existing, target)) {
          throw FormatException(
            'Target "$targetId" is defined differently in ${deltaFile.path}.',
          );
        }
        targets[targetId] = target;
      }
    }

    return GeneratedUiMap(
      content: _formatCanonicalUiMap(targets),
      specCount: specCount,
      targetCount: targets.length,
    );
  }

  bool _sameMap(Map<String, Object?> a, Map<String, Object?> b) {
    return jsonEncode(a) == jsonEncode(b);
  }

  String _formatCanonicalUiMap(Map<String, Map<String, Object?>> targets) {
    final buffer = StringBuffer()
      ..writeln('# Canonical UI target map for harness specs.')
      ..writeln(
        '# Generated by `fvm dart run tool/harness.dart spec ui-map`; do not edit by hand.',
      )
      ..writeln(
        '# Source: approved docs/harness/specs/*/ui-map.delta.yaml files.',
      );

    if (targets.isEmpty) {
      buffer.writeln('targets: {}');
      return buffer.toString();
    }

    buffer.writeln('targets:');
    for (final entry in targets.entries) {
      buffer.writeln('  ${entry.key}:');
      for (final field in entry.value.entries) {
        buffer.writeln('    ${field.key}: ${_formatYamlScalar(field.value)}');
      }
    }
    return buffer.toString();
  }

  String _formatYamlScalar(Object? value) {
    if (value == null) return 'null';
    if (value is num || value is bool) return value.toString();

    final text = value.toString();
    if (_canUsePlainYamlScalar(text)) return text;

    return "'${text.replaceAll("'", "''")}'";
  }

  bool _canUsePlainYamlScalar(String text) {
    if (text.isEmpty || text.trim() != text) return false;
    if (text.contains(':') || text.contains('#')) return false;
    if (RegExp(r'^[+\-?&*!|>{}\[\],%@`]').hasMatch(text)) return false;
    if (RegExp(r'^(true|false|null|Null|NULL|~)$').hasMatch(text)) {
      return false;
    }
    if (num.tryParse(text) != null) return false;
    return RegExp(r'^[A-Za-z0-9_./() -]+$').hasMatch(text);
  }

  String _specMarkdownTemplate(String id) =>
      '''
# Spec: $id

## Goal

Describe what this spec verifies.

## Preconditions

- Run the `dev` flavor.

## Steps

1. Launch the app.
2. ...

## Acceptance Criteria

Mirrored as machine-checkable items in `acceptance.yaml`.

## Translation Rules

- Prefer `semantics_identifier` from `docs/harness/specs/ui-map.yaml`.
- Do not invent labels or targets.
- If a step cannot be mapped to a known target, report `BLOCKED`.
''';

  String _uiMapDeltaTemplate(String id) =>
      '''
# New UI targets introduced by the "$id" spec.
# Approved deltas are generated into docs/harness/specs/ui-map.yaml by:
#   fvm dart run tool/harness.dart spec ui-map
targets: {}
''';

  String _acceptanceTemplate(String id, String flow) =>
      '''
spec: $id
feature: feat-XXX
goal: 'Describe what this spec verifies.'
preconditions:
  - Run the dev flavor.
acceptance:
  - id: a1
    claim: 'Describe the E2E outcome verified by the Maestro flow.'
    kind: maestro
    flow: $flow
# Add kind: test criteria only for non-UI logic, data, BLoC, repository, or
# harness unit tests. UI behavior belongs in the Maestro flow above.
''';

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
    final command = '$executable ${arguments.join(' ')}';

    // Try to find adb in common Android SDK locations if not on PATH
    final env = <String, String>{};
    if (executable == 'adb') {
      final candidatePaths = <String>[
        if (Platform.environment.containsKey('ANDROID_HOME'))
          '${Platform.environment['ANDROID_HOME']}/platform-tools',
        if (Platform.environment.containsKey('ANDROID_SDK_ROOT'))
          '${Platform.environment['ANDROID_SDK_ROOT']}/platform-tools',
        '${Platform.environment['HOME']}/Library/Android/sdk/platform-tools',
        '${Platform.environment['HOME']}/Android/Sdk/platform-tools',
        '/usr/local/share/android-sdk/platform-tools',
        '/opt/android-sdk/platform-tools',
      ];

      for (final path in candidatePaths) {
        final adbPath = '$path/adb';
        if (File(adbPath).existsSync()) {
          env['PATH'] = '${Platform.environment['PATH']}:$path';
          break;
        }
      }
    }

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
      'feature_list.json',
      'progress.md',
      'init.sh',
      'session-handoff.md',
      '.github/workflows/harness.yml',
      'docs/harness/README.md',
      'docs/harness/ARCHITECTURE.md',
      'docs/harness/VALIDATION.md',
      'docs/harness/SKILLS.md',
      'docs/harness/QUALITY.md',
      'docs/harness/OPERABILITY.md',
      'docs/harness/TASKS.md',
      'tool/harness.dart',
    ];
  }

  List<String> _requiredHarnessDirectories() {
    return const ['.agents/skills'];
  }

  List<Map<String, Object?>> _agentSkills() {
    final directory = Directory('.agents/skills');
    if (!directory.existsSync()) {
      return const [];
    }

    return directory.listSync().whereType<Directory>().map((skill) {
        final name = skill.uri.pathSegments
            .where((segment) => segment.isNotEmpty)
            .last;
        return {
          'name': name,
          'skill_file': '${skill.path}/SKILL.md',
          'exists': File('${skill.path}/SKILL.md').existsSync(),
        };
      }).toList()
      ..sort((a, b) => (a['name']! as String).compareTo(b['name']! as String));
  }
}

class CommandSpec {
  const CommandSpec(this.executable, this.arguments);

  final String executable;
  final List<String> arguments;
}

class GeneratedUiMap {
  const GeneratedUiMap({
    required this.content,
    required this.specCount,
    required this.targetCount,
  });

  final String content;
  final int specCount;
  final int targetCount;
}

class CoverageSummary {
  const CoverageSummary(this.files);

  final List<CoverageFile> files;

  int get foundLines => files.fold(0, (sum, file) => sum + file.foundLines);

  int get hitLines => files.fold(0, (sum, file) => sum + file.hitLines);

  double get percent {
    if (foundLines == 0) return 0;
    return hitLines * 100 / foundLines;
  }
}

class CoverageFile {
  const CoverageFile({
    required this.path,
    required this.foundLines,
    required this.hitLines,
  });

  final String path;
  final int foundLines;
  final int hitLines;

  double get percent {
    if (foundLines == 0) return 0;
    return hitLines * 100 / foundLines;
  }
}
