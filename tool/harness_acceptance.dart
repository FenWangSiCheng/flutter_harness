import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart' as yaml;

import 'harness_device.dart';
import 'harness_process.dart';
import 'harness_support.dart';

const prettyJson = JsonEncoder.withIndent('  ');

class AcceptanceRunner {
  const AcceptanceRunner({
    required this.state,
    required this.policy,
    required this.process,
    required this.installer,
    required this.stdout,
    required this.stderr,
  });

  final HarnessStateStore state;
  final HarnessPolicy policy;
  final HarnessProcess process;
  final DevAppInstaller installer;
  final Stdout stdout;
  final IOSink stderr;

  Future<int> accept(
    String id, {
    required String platform,
    required bool runMaestro,
    String reportFileName = 'report.json',
  }) async {
    if (platform == 'all') {
      return acceptAll(id, runMaestro: runMaestro);
    }

    final file = state.acceptanceFile(id);
    if (file == null) {
      stderr.writeln('No acceptance.yaml found for spec "$id".');
      return 64;
    }
    final doc = yaml.loadYaml(file.readAsStringSync()) as yaml.YamlMap;
    final acceptance = doc['acceptance'] as yaml.YamlList;
    final criteria = _criteriaFrom(id, acceptance);

    final testResult = await _runTestCriteria(id, criteria);
    final maestroResult = runMaestro
        ? await _runMaestroCriteria(platform, criteria.maestroFlows)
        : const _MaestroResult.skipped();

    final results = [
      for (final item in acceptance)
        _criterionReport(
          id: id,
          platform: platform,
          item: item as yaml.YamlMap,
          tests: testResult,
          maestro: maestroResult,
          runMaestro: runMaestro,
        ),
    ];
    final overall = overallFromVerdicts(
      results.map((r) => r['verdict'].toString()),
    );

    final report = <String, Object?>{
      'spec': id,
      'feature': doc['feature']?.toString(),
      'platform': platform,
      'result': overall,
      'maestro_run': runMaestro && maestroResult.blockedReason.isEmpty,
      'maestro_blocked_reason': maestroResult.blockedReason.isEmpty
          ? null
          : maestroResult.blockedReason,
      'maestro_all_pass':
          runMaestro &&
          maestroResult.blockedReason.isEmpty &&
          maestroResult.flowResults.values.every((e) => e == 0),
      'harness_events': policy.acceptanceReportEvents,
      'acceptance': results,
    };

    final evidenceDir = Directory('${policy.buildEvidenceDir}/$id');
    await evidenceDir.create(recursive: true);
    await File(
      '${evidenceDir.path}/$reportFileName',
    ).writeAsString(prettyJson.convert(report));

    stdout.writeln('');
    stdout.writeln('Acceptance report for "$id" on $platform: $overall');
    for (final r in results) {
      stdout.writeln('  [${r['verdict']}] ${r['id']}  ${r['claim']}');
    }
    stdout.writeln('Evidence: ${evidenceDir.path}/$reportFileName');
    return overall == 'PASS' ? 0 : 1;
  }

  Future<int> acceptAll(String id, {required bool runMaestro}) async {
    final evidenceDir = Directory('${policy.buildEvidenceDir}/$id');
    final platformReports = <Map<String, Object?>>[];

    for (final platform in policy.maestroPlatforms) {
      final reportFileName = 'report-$platform.json';
      final reportFile = File('${evidenceDir.path}/$reportFileName');
      if (reportFile.existsSync()) {
        await reportFile.delete();
      }

      await accept(
        id,
        platform: platform,
        runMaestro: runMaestro,
        reportFileName: reportFileName,
      );

      platformReports.add(
        reportFile.existsSync()
            ? jsonDecode(reportFile.readAsStringSync()) as Map<String, Object?>
            : _missingPlatformReport(id, platform),
      );
    }

    final overall = overallFromVerdicts(
      platformReports.map((report) => report['result'].toString()),
    );
    final summary = <String, Object?>{
      'spec': id,
      'feature': firstStringField(platformReports, 'feature'),
      'platform': 'all',
      'result': overall,
      'maestro_run': platformReports.every((report) {
        return report['maestro_run'] == true;
      }),
      'maestro_all_pass': platformReports.every((report) {
        return report['maestro_all_pass'] == true;
      }),
      'harness_events': policy.acceptanceReportEvents,
      'platforms': platformReports,
    };

    await evidenceDir.create(recursive: true);
    await File(
      '${evidenceDir.path}/report.json',
    ).writeAsString(prettyJson.convert(summary));

    stdout.writeln('');
    stdout.writeln('Dual-platform acceptance report for "$id": $overall');
    for (final report in platformReports) {
      stdout.writeln('  [${report['result']}] ${report['platform']}');
    }
    stdout.writeln('Evidence: ${evidenceDir.path}/report.json');
    return overall == 'PASS' ? 0 : 1;
  }

  _AcceptanceCriteria _criteriaFrom(String id, yaml.YamlList acceptance) {
    final testFiles = <String>{};
    final maestroFlows = <String>{};
    for (final item in acceptance) {
      final criterion = item as yaml.YamlMap;
      final kind = criterion['kind'].toString();
      if (kind == 'test') {
        testFiles.add(criterion['file'].toString());
      } else if (kind == 'maestro') {
        maestroFlows.add((criterion['flow'] ?? flowName(id)).toString());
      }
    }
    return _AcceptanceCriteria(
      testFiles: testFiles,
      maestroFlows: maestroFlows,
    );
  }

  Future<_TestResult> _runTestCriteria(
    String id,
    _AcceptanceCriteria criteria,
  ) async {
    if (criteria.testFiles.isEmpty) return const _TestResult.notRun();

    stdout.writeln(
      '> running ${criteria.testFiles.length} test file(s) for spec "$id"',
    );
    final exitCode = await process.run(
      CommandSpec('fvm', ['flutter', 'test', ...criteria.testFiles]),
    );
    return _TestResult(ran: true, exitCode: exitCode);
  }

  Future<_MaestroResult> _runMaestroCriteria(
    String platform,
    Set<String> flows,
  ) async {
    final blockedReason = await _maestroBlockedReason(platform, flows);
    if (blockedReason != null) {
      stderr.writeln('Maestro acceptance blocked for platform "$platform":');
      stderr.writeln(blockedReason);
      return _MaestroResult.blocked(blockedReason);
    }

    final flowResults = <String, int>{};
    for (final flow in flows) {
      final path = maestroFlowPath(platform, flow);
      stdout.writeln('> running maestro flow $path');
      flowResults[flow] = await process.run(
        CommandSpec('maestro', ['test', '--platform', platform, path]),
      );
    }
    return _MaestroResult(flowResults: flowResults, blockedReason: '');
  }

  Future<String?> _maestroBlockedReason(
    String platform,
    Set<String> flows,
  ) async {
    if (flows.isEmpty) {
      return 'Spec has no kind: maestro acceptance criteria.';
    }

    final maestroOk = await process.capture('maestro', ['--version']);
    if (maestroOk['exit_code'] != 0) {
      return 'Maestro CLI is not installed or not on PATH. Install it with: '
          'brew tap mobile-dev-inc/tap && brew install mobile-dev-inc/tap/maestro';
    }

    final missing = flows
        .map((flow) => maestroFlowPath(platform, flow))
        .where((path) => !File(path).existsSync())
        .toList();
    if (missing.isNotEmpty) {
      return 'Missing Maestro flow file(s) for platform "$platform": '
          '${missing.join(', ')}';
    }

    final installExit = await installer.buildAndInstall(platform);
    if (installExit != 0) {
      return 'Failed to build and install dev app for platform "$platform".';
    }
    return null;
  }

  Map<String, Object?> _criterionReport({
    required String id,
    required String platform,
    required yaml.YamlMap item,
    required _TestResult tests,
    required _MaestroResult maestro,
    required bool runMaestro,
  }) {
    final kind = item['kind'].toString();
    late final String verdict;
    late final String evidence;

    if (kind == 'test') {
      verdict = tests.ran && tests.exitCode == 0 ? 'pass' : 'fail';
      evidence = item['file'].toString();
    } else if (kind == 'maestro') {
      final flow = (item['flow'] ?? flowName(id)).toString();
      if (!runMaestro) {
        verdict = 'skipped';
      } else if (maestro.blockedReason.isNotEmpty) {
        verdict = 'blocked';
      } else {
        verdict = maestro.flowResults[flow] == 0 ? 'pass' : 'fail';
      }
      evidence = maestroFlowPath(platform, flow);
    } else {
      verdict = 'blocked';
      evidence = 'unknown kind $kind';
    }

    return {
      'id': item['id'].toString(),
      'claim': item['claim'].toString(),
      'kind': kind,
      'verdict': verdict,
      'evidence': evidence,
    };
  }

  Map<String, Object?> _missingPlatformReport(String id, String platform) {
    return {
      'spec': id,
      'platform': platform,
      'result': 'BLOCKED',
      'maestro_run': false,
      'maestro_blocked_reason': 'No report was written for $platform.',
      'acceptance': const [],
    };
  }
}

String flowName(String id) => '${id.replaceAll('-', '_')}_flow';

String maestroFlowPath(String platform, String flow) {
  return '${maestroTargetDirectory(platform)}/$flow.yaml';
}

String maestroTargetDirectory(String platform) {
  return switch (platform) {
    'android' => '.maestro/android',
    'ios' => '.maestro/ios',
    _ => '.maestro',
  };
}

String overallFromVerdicts(Iterable<String> verdicts) {
  final values = verdicts.map((value) => value.toUpperCase()).toSet();
  for (final verdict in const ['FAIL', 'BLOCKED', 'SKIPPED', 'PASS']) {
    if (values.contains(verdict)) return verdict;
  }
  return 'SKIPPED';
}

String? firstStringField(Iterable<Map<String, Object?>> reports, String field) {
  for (final report in reports) {
    final value = report[field];
    if (value is String) return value;
  }
  return null;
}

class _AcceptanceCriteria {
  const _AcceptanceCriteria({
    required this.testFiles,
    required this.maestroFlows,
  });

  final Set<String> testFiles;
  final Set<String> maestroFlows;
}

class _TestResult {
  const _TestResult({required this.ran, required this.exitCode});

  const _TestResult.notRun() : ran = false, exitCode = 0;

  final bool ran;
  final int exitCode;
}

class _MaestroResult {
  const _MaestroResult({
    required this.flowResults,
    required this.blockedReason,
  });

  const _MaestroResult.skipped() : flowResults = const {}, blockedReason = '';

  const _MaestroResult.blocked(String reason)
    : flowResults = const {},
      blockedReason = reason;

  final Map<String, int> flowResults;
  final String blockedReason;
}
