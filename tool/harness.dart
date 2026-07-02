import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart' as yaml;

import 'harness_acceptance.dart';
import 'harness_device.dart';
import 'harness_evidence.dart';
import 'harness_process.dart';
import 'harness_support.dart';

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
    case 'done-specs':
      exitCode = runner.doneSpecs();
    case 'evidence':
      exitCode = await runner.evidence(args.sublist(1));
    case 'eval':
      exitCode = await runner.eval(args.sublist(1));
    case 'format':
      exitCode = await runner.formatCheck();
    case 'review':
      exitCode = await runner.review(args.sublist(1));
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
  final HarnessStateStore _state = HarnessStateStore();
  late final HarnessProcess _process = HarnessProcess(
    stdout: stdout,
    stderr: stderr,
  );
  late final DevAppInstaller _installer = DevAppInstaller(
    process: _process,
    stdout: stdout,
    stderr: stderr,
  );
  late final HarnessUiMapGenerator _uiMapGenerator = HarnessUiMapGenerator(
    state: _state,
  );
  late final HarnessPolicy _policy = HarnessPolicy.load(
    File('docs/harness/policy.yaml'),
  );
  late final AcceptanceRunner _acceptance = AcceptanceRunner(
    state: _state,
    policy: _policy,
    process: _process,
    installer: _installer,
    stdout: stdout,
    stderr: stderr,
  );
  late final EvidenceManager _evidence = EvidenceManager(
    state: _state,
    policy: _policy,
    process: _process,
    stdout: stdout,
    stderr: stderr,
  );

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
    stdout.writeln(
      '  done-specs List specs linked to done features (one per line)',
    );
    stdout.writeln(
      '  evidence   Evidence workflow: promote <id|--all> [--check]',
    );
    stdout.writeln(
      '  eval       Run Maestro E2E flows [--platform ios|android|all]',
    );
    stdout.writeln('  format     Check formatting for lib, test, and tool');
    stdout.writeln(
      '  review     Run the read-only harness evaluator for a spec',
    );
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

  /// Print every spec linked to a `done` feature, one per line.
  int doneSpecs() {
    for (final spec in _state.doneSpecs()) {
      stdout.writeln(spec);
    }
    return 0;
  }

  Future<int> bootstrap() async {
    return _process.runAll([
      _process.flutterCommand(['pub', 'get']),
      _process.dartCommand(['run', 'build_runner', 'build']),
    ]);
  }

  Future<int> check() async {
    return _process.runAll([
      _process.formatCommand(),
      _process.harnessCommand(['structure']),
      _process.flutterCommand(['analyze']),
      _process.harnessCommand(['coverage']),
    ]);
  }

  Future<int> coverage(List<String> args) async {
    final minimum = _coverageMinimum(args);
    final checkOnly = args.contains('--check-only');

    if (!checkOnly) {
      final testExit = await _process.run(
        _process.flutterCommand(['test', '--coverage']),
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
      'Coverage excludes policy-owned UI/generated files; '
      'UI behavior is accepted by Maestro.',
    );

    final lowFiles =
        summary.files
            .where(
              (file) =>
                  file.foundLines > 0 &&
                  file.percent < _policy.lowFileCoverageThreshold,
            )
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
      'flutter': await _process.capture('fvm', ['flutter', '--version']),
      'fvm_dart': await _process.capture('fvm', ['dart', '--version']),
      'fvm': await _readJsonFile('.fvm/fvm_config.json'),
      'maestro': await _process.capture('maestro', ['--version']),
      'harness_policy': _policy.toJson(),
      'generated_files': _generatedFiles(),
      'harness_files': _requiredHarnessFiles()
          .map((path) => {'path': path, 'exists': File(path).existsSync()})
          .toList(),
      'harness_directories': _requiredHarnessDirectories()
          .map((path) => {'path': path, 'exists': Directory(path).existsSync()})
          .toList(),
      'agent_skills': _agentSkills(),
    };

    stdout.writeln(prettyJson.convert(diagnostics));
    return 0;
  }

  Future<int> evidence(List<String> args) async {
    final sub = args.isEmpty ? 'help' : args.first;
    switch (sub) {
      case 'promote':
        if (args.length < 2 && !args.contains('--all')) {
          stderr.writeln(
            'Usage: fvm dart run tool/harness.dart evidence promote <id|--all> [--check]',
          );
          return 64;
        }
        final checkOnly = args.contains('--check');
        final specs = args.contains('--all')
            ? _state.doneSpecs()
            : <String>[args[1]];
        if (specs.isEmpty) {
          stderr.writeln('No done specs found in feature_list.json.');
          return 1;
        }

        var exitCode = 0;
        for (final spec in specs) {
          final result = await _evidence.promote(spec, checkOnly: checkOnly);
          if (result != 0) exitCode = result;
        }
        return exitCode;
      case 'help':
      case '--help':
      case '-h':
        stdout.writeln('Evidence workflow commands:');
        stdout.writeln(
          '  evidence promote <id|--all> [--check]  Promote or verify enriched acceptance reports',
        );
        return 0;
      default:
        stderr.writeln('Unknown evidence subcommand: $sub');
        return 64;
    }
  }

  Future<int> formatCheck() {
    return _process.runAll([_process.formatCommand()]);
  }

  Future<int> review(List<String> args) async {
    if (args.isEmpty || args.first == '--help' || args.first == '-h') {
      stdout.writeln('Usage: fvm dart run tool/harness.dart review <spec-id>');
      stdout.writeln(
        'Runs the read-only harness evaluator against committed spec evidence.',
      );
      return args.isEmpty ? 64 : 0;
    }

    return _evidence.review(args.first);
  }

  Future<int> eval(List<String> args) async {
    final maestro = await _process.capture('maestro', ['--version']);
    if (maestro['exit_code'] != 0) {
      stderr.writeln('Maestro CLI is not installed or not on PATH.');
      stderr.writeln('Install it with: brew tap mobile-dev-inc/tap');
      stderr.writeln('Then run: brew install mobile-dev-inc/tap/maestro');
      stderr.writeln('After launching a dev app on a simulator/device, run:');
      stderr.writeln('  fvm dart run tool/harness.dart eval');
      return 69;
    }

    final platform = _platformArg(args);
    for (final plat in _platformsFor(platform)) {
      final installExit = await _installer.buildAndInstall(plat);
      if (installExit != 0) {
        stderr.writeln(
          'Failed to build and install dev app for platform "$plat".',
        );
        return 69;
      }

      final exitCode = await _process.runAll([
        CommandSpec('maestro', [
          'test',
          '--platform',
          plat,
          maestroTargetDirectory(plat),
        ]),
      ]);
      if (exitCode != 0) return exitCode;
    }
    return 0;
  }

  Future<int> structure() {
    return _process.runAll([
      _process.flutterCommand(['test', 'test/harness']),
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
    return _policy.minimumCoverage;
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
    return !_policy.coverageExcludes.any((rule) => rule.matches(normalized));
  }

  List<String> _platformsFor(String platform) {
    if (platform == 'all') return _policy.maestroPlatforms;
    return [platform];
  }

  Future<int> _specNew(String id) async {
    final dir = Directory('docs/harness/specs/$id');
    if (dir.existsSync()) {
      stderr.writeln('Spec already exists: ${dir.path}');
      return 64;
    }
    final flow = flowName(id);
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
    ).writeAsString(_maestroFlowTemplate(_policy.iosAppId));
    await File(
      '.maestro/android/$flow.yaml',
    ).writeAsString(_maestroFlowTemplate(_policy.androidAppId));
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

  String _maestroFlowTemplate(String appId) =>
      '''
appId: $appId
---
- launchApp
# Translate spec steps here. Prefer semantics_identifier ids from ui-map.yaml.
''';

  Future<int> _specReview(String id, {required bool approve}) async {
    final file = _state.acceptanceFile(id);
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
    final status = _state.specStatus(id);

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
      final updated = _state.setSpecStatus(id, 'spec-approved');
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
      generated = _uiMapGenerator.generate();
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
    return _acceptance.accept(
      id,
      platform: platform,
      runMaestro: runMaestro,
      reportFileName: reportFileName,
    );
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
    return _process.runAll([
      _process.flutterCommand(['test']),
    ]);
  }

  Future<Object?> _readJsonFile(String path) async {
    final file = File(path);
    if (!file.existsSync()) {
      return {'missing': path};
    }
    return jsonDecode(await file.readAsString());
  }

  List<Map<String, Object?>> _generatedFiles() {
    return _policy.generatedFiles.map((path) {
      return {'path': path, 'exists': File(path).existsSync()};
    }).toList();
  }

  List<String> _requiredHarnessFiles() {
    return _policy.requiredHarnessFiles;
  }

  List<String> _requiredHarnessDirectories() {
    return _policy.requiredHarnessDirectories;
  }

  List<Map<String, Object?>> _agentSkills() {
    final directory = Directory('.agents/skills');
    if (!directory.existsSync()) {
      return const [];
    }

    return _policy.agentSkills.map((name) {
        return {
          'name': name,
          'skill_file': '${directory.path}/$name/SKILL.md',
          'exists': File('${directory.path}/$name/SKILL.md').existsSync(),
        };
      }).toList()
      ..sort((a, b) => (a['name']! as String).compareTo(b['name']! as String));
  }
}
