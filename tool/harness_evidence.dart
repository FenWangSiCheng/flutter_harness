import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart' as yaml;

import 'harness_acceptance.dart';
import 'harness_process.dart';
import 'harness_support.dart';

class EvidenceManager {
  const EvidenceManager({
    required this.state,
    required this.policy,
    required this.process,
    required this.stdout,
    required this.stderr,
  });

  final HarnessStateStore state;
  final HarnessPolicy policy;
  final HarnessProcess process;
  final Stdout stdout;
  final IOSink stderr;

  Future<int> promote(String spec, {required bool checkOnly}) async {
    final buildDir = Directory('${policy.buildEvidenceDir}/$spec');
    final committedDir = Directory('${policy.committedEvidenceDir}/$spec');
    var exitCode = 0;

    if (!checkOnly) {
      await committedDir.create(recursive: true);
    }

    final env = await _captureEvidenceEnv();
    final acceptanceFile = state.acceptanceFile(spec);
    final acceptanceSummary = acceptanceFile == null
        ? null
        : acceptanceSummaryFrom(spec, acceptanceFile);

    for (final reportName in policy.requiredEvidenceReports) {
      final buildReport = File('${buildDir.path}/$reportName');
      final committedReport = File('${committedDir.path}/$reportName');
      final source = buildReport.existsSync() ? buildReport : committedReport;
      if (!source.existsSync()) {
        stderr.writeln(
          'Missing source evidence for "$spec": ${buildReport.path} '
          'or ${committedReport.path}',
        );
        exitCode = 1;
        continue;
      }

      final sourceReport =
          jsonDecode(source.readAsStringSync()) as Map<String, Object?>;
      if (checkOnly) {
        exitCode =
            _checkCommittedReport(
              spec: spec,
              reportName: reportName,
              sourcePath: source.path,
              sourceReport: sourceReport,
              committedReport: committedReport,
              acceptanceSummary: acceptanceSummary,
              env: env,
            )
            ? exitCode
            : 1;
      } else {
        final enriched = _enrichedEvidenceReport(
          sourceReport,
          spec: spec,
          reportName: reportName,
          sourcePath: source.path,
          existingMetadata: null,
          acceptanceSummary: acceptanceSummary,
          env: env,
        );
        await committedReport.writeAsString(
          '${prettyJson.convert(enriched)}\n',
        );
        stdout.writeln('Promoted evidence: ${committedReport.path}');
      }
    }

    if (exitCode == 0 && checkOnly) {
      stdout.writeln('Committed evidence is current for "$spec".');
    }
    return exitCode;
  }

  Future<int> review(String spec) async {
    final rubric = File('docs/harness/evaluators/default.md');
    if (!rubric.existsSync()) {
      stderr.writeln('Missing review rubric: ${rubric.path}');
      return 1;
    }

    final findings = <String>[];
    final feature = state.featureForSpec(spec);
    if (feature == null) {
      findings.add('No feature in feature_list.json links spec "$spec".');
    }

    final acceptanceFile = state.acceptanceFile(spec);
    if (acceptanceFile == null) {
      findings.add('No acceptance.yaml found for spec "$spec".');
    }

    final reportFile = File('${policy.committedEvidenceDir}/$spec/report.json');
    final report = _readReport(reportFile, findings);
    if (report != null) {
      _reviewReportShape(
        report: report,
        spec: spec,
        feature: feature,
        findings: findings,
      );
    }

    if (acceptanceFile != null && report != null) {
      final acceptance = acceptanceSummaryFrom(spec, acceptanceFile);
      final metadata = report['harness_metadata'];
      final currentSummary = metadata is Map<String, Object?>
          ? metadata['acceptance_summary']
          : null;
      if (canonicalJson(currentSummary) != canonicalJson(acceptance)) {
        findings.add('Committed report acceptance summary is stale.');
      }
    }

    final verdict = findings.isEmpty ? 'PASS' : 'NEEDS_WORK';
    final reviewReport = <String, Object?>{
      'spec': spec,
      'verdict': verdict,
      'rubric': rubric.path,
      'findings': findings,
    };

    final reviewDir = Directory('build/harness/reviews/$spec');
    await reviewDir.create(recursive: true);
    await File(
      '${reviewDir.path}/review.json',
    ).writeAsString(prettyJson.convert(reviewReport));

    stdout.writeln('Harness review for "$spec": $verdict');
    if (findings.isEmpty) {
      stdout.writeln('  Committed evidence matches the current spec.');
    } else {
      for (final finding in findings) {
        stdout.writeln('  - $finding');
      }
    }
    stdout.writeln('Review report: ${reviewDir.path}/review.json');
    return verdict == 'PASS' ? 0 : 1;
  }

  bool _checkCommittedReport({
    required String spec,
    required String reportName,
    required String sourcePath,
    required Map<String, Object?> sourceReport,
    required File committedReport,
    required Map<String, Object?>? acceptanceSummary,
    required _EvidenceEnv env,
  }) {
    if (!committedReport.existsSync()) {
      stderr.writeln('Missing committed evidence: ${committedReport.path}');
      return false;
    }

    final current =
        jsonDecode(committedReport.readAsStringSync()) as Map<String, Object?>;
    final enriched = _enrichedEvidenceReport(
      sourceReport,
      spec: spec,
      reportName: reportName,
      sourcePath: sourcePath,
      existingMetadata: _metadataFrom(current),
      acceptanceSummary: acceptanceSummary,
      env: env,
    );
    if (canonicalJson(current) == canonicalJson(enriched)) return true;

    stderr.writeln(
      'Committed evidence is out of date: ${committedReport.path}',
    );
    stderr.writeln(
      'Run: fvm dart run tool/harness.dart evidence promote $spec',
    );
    return false;
  }

  Future<_EvidenceEnv> _captureEvidenceEnv() async {
    final results = await Future.wait([
      process.capture('git', ['rev-parse', '--short', 'HEAD']),
      process.capture('fvm', ['flutter', '--version']),
      process.capture('maestro', ['--version']),
    ]);
    final gitSha = results[0];
    final flutter = results[1];
    final maestro = results[2];
    return _EvidenceEnv(
      gitSha: gitSha['exit_code'] == 0 ? gitSha['stdout'] as String : null,
      flutterVersion: firstLine(flutter['stdout']),
      maestroVersion: firstLine(maestro['stdout']),
    );
  }

  Map<String, Object?> _enrichedEvidenceReport(
    Map<String, Object?> report, {
    required String spec,
    required String reportName,
    required String sourcePath,
    required Map<String, Object?>? existingMetadata,
    required Map<String, Object?>? acceptanceSummary,
    required _EvidenceEnv env,
  }) {
    return {
      ...report,
      'harness_events': policy.acceptanceReportEvents,
      'harness_metadata': {
        'promoted_at':
            existingMetadata?['promoted_at'] ??
            DateTime.now().toUtc().toIso8601String(),
        'git_sha': existingMetadata?['git_sha'] ?? env.gitSha,
        'command': 'fvm dart run tool/harness.dart evidence promote $spec',
        'report_name': reportName,
        'source_report': existingMetadata?['source_report'] ?? sourcePath,
        'policy_file': policy.path,
        'policy_version': policy.version,
        'flutter_version':
            existingMetadata?['flutter_version'] ?? env.flutterVersion,
        'maestro_version':
            existingMetadata?['maestro_version'] ?? env.maestroVersion,
        'acceptance_summary': acceptanceSummary,
      },
    };
  }

  Map<String, Object?>? _readReport(File reportFile, List<String> findings) {
    if (!reportFile.existsSync()) {
      findings.add('Missing committed evidence report: ${reportFile.path}.');
      return null;
    }
    return jsonDecode(reportFile.readAsStringSync()) as Map<String, Object?>;
  }

  void _reviewReportShape({
    required Map<String, Object?> report,
    required String spec,
    required Map<String, Object?>? feature,
    required List<String> findings,
  }) {
    if (report['result'] != 'PASS') {
      findings.add('Committed report result is ${report['result']}, not PASS.');
    }
    if (feature != null && report['feature'] != feature['id']) {
      findings.add(
        'Committed report feature does not match feature_list.json.',
      );
    }
    if (report['spec'] != spec) {
      findings.add('Committed report spec does not match "$spec".');
    }
    if (report['harness_metadata'] is! Map<String, Object?>) {
      findings.add('Committed report is missing harness_metadata.');
    }
  }

  Map<String, Object?>? _metadataFrom(Map<String, Object?> report) {
    final metadata = report['harness_metadata'];
    if (metadata is! Map<String, Object?>) return null;
    return metadata;
  }
}

Map<String, Object?> acceptanceSummaryFrom(String spec, File acceptanceFile) {
  final doc = yaml.loadYaml(acceptanceFile.readAsStringSync()) as yaml.YamlMap;
  final acceptance = (doc['acceptance'] as yaml.YamlList).cast<yaml.YamlMap>();
  return {
    'file': acceptanceFile.path,
    'spec': spec,
    'feature': doc['feature']?.toString(),
    'criterion_count': acceptance.length,
    'criteria': [
      for (final item in acceptance)
        {
          'id': item['id'].toString(),
          'claim': item['claim'].toString(),
          'kind': item['kind'].toString(),
        },
    ],
  };
}

String canonicalJson(Object? value) {
  return jsonEncode(_canonicalValue(value));
}

Object? _canonicalValue(Object? value) {
  if (value is Map) {
    final sorted = <String, Object?>{};
    for (final key
        in value.keys.map((key) => key.toString()).toList()..sort()) {
      sorted[key] = _canonicalValue(value[key]);
    }
    return sorted;
  }
  if (value is List) return value.map(_canonicalValue).toList();
  return value;
}

String? firstLine(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return value.split('\n').first.trim();
}

class _EvidenceEnv {
  const _EvidenceEnv({
    required this.gitSha,
    required this.flutterVersion,
    required this.maestroVersion,
  });

  final String? gitSha;
  final String? flutterVersion;
  final String? maestroVersion;
}
