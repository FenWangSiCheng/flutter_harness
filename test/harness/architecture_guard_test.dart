import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart' as yaml;

void main() {
  group('Harness structure', () {
    test('required harness files exist', () {
      const paths = [
        'AGENTS.md',
        'feature_list.json',
        'progress.md',
        'init.sh',
        'session-handoff.md',
        '.github/workflows/harness.yml',
        '.github/workflows/maestro.yml',
        'docs/harness/README.md',
        'docs/harness/ARCHITECTURE.md',
        'docs/harness/VALIDATION.md',
        'docs/harness/SKILLS.md',
        'docs/harness/QUALITY.md',
        'docs/harness/OPERABILITY.md',
        'docs/harness/TASKS.md',
        'docs/harness/specs/ui-map.yaml',
        'docs/harness/evidence/README.md',
        'tool/harness.dart',
      ];

      for (final path in paths) {
        expect(File(path).existsSync(), isTrue, reason: '$path should exist');
      }
    });

    test('project agent skills are installed and documented', () {
      final skillsDirectory = Directory('.agents/skills');
      expect(skillsDirectory.existsSync(), isTrue);

      const expectedSkills = [
        'dart-add-unit-test',
        'dart-build-cli-app',
        'dart-collect-coverage',
        'dart-fix-runtime-errors',
        'dart-generate-test-mocks',
        'dart-migrate-to-checks-package',
        'dart-resolve-package-conflicts',
        'dart-run-static-analysis',
        'dart-setup-ffi-assets',
        'dart-use-ffigen',
        'dart-use-pattern-matching',
        'flutter-add-integration-test',
        'flutter-add-widget-preview',
        'flutter-add-widget-test',
        'flutter-build-responsive-layout',
        'flutter-fix-layout-issues',
        'flutter-implement-json-serialization',
        'flutter-setup-declarative-routing',
        'flutter-setup-localization',
        'flutter-use-http-package',
      ];

      for (final skill in expectedSkills) {
        final skillFile = File('.agents/skills/$skill/SKILL.md');
        expect(skillFile.existsSync(), isTrue, reason: '$skill should exist');
      }

      final skillsDoc = File('docs/harness/SKILLS.md').readAsStringSync();
      expect(skillsDoc, contains('flutter/skills'));
      expect(skillsDoc, contains('dart-lang/skills'));
      expect(skillsDoc, contains('.agents/skills'));
    });

    test(
      'agent instructions route state, verification, scope, and lifecycle',
      () {
        final agents = File('AGENTS.md').readAsStringSync();

        expect(agents, contains('Startup Workflow'));
        expect(agents, contains('Definition of Done'));
        expect(agents, contains('Verification Commands'));
        expect(agents, contains('End of Session'));
        expect(agents, contains('One feature at a time'));
        expect(agents, contains('feature_list.json'));
        expect(agents, contains('progress.md'));
        expect(agents, contains('session-handoff.md'));
        expect(agents, contains('.agents/skills'));
      },
    );

    test('feature list is valid walkinglabs state', () {
      final decoded =
          jsonDecode(File('feature_list.json').readAsStringSync())
              as Map<String, Object?>;
      final features = decoded['features'] as List<Object?>;

      expect(features, isNotEmpty);
      for (final feature in features.cast<Map<String, Object?>>()) {
        expect(feature['id'], isA<String>());
        expect(feature['name'], isA<String>());
        expect(feature['description'], isA<String>());
        expect(feature['dependencies'], isA<List<Object?>>());
        expect(feature['status'], isA<String>());
        expect(feature.containsKey('evidence'), isTrue);
      }
    });

    test('session lifecycle artifacts support restart and evidence', () {
      final progress = File('progress.md').readAsStringSync();
      final handoff = File('session-handoff.md').readAsStringSync();
      final init = File('init.sh').readAsStringSync();

      expect(progress, contains('Current State'));
      expect(progress, contains("What's Next"));
      expect(progress, contains('Evidence of Completion'));
      expect(progress, contains('Files Modified This Session'));

      expect(handoff, contains('Current Objective'));
      expect(handoff, contains('Verification Evidence'));
      expect(handoff, contains('Recommended Next Step'));

      expect(init, contains('set -e'));
      expect(init, contains('fvm flutter pub get'));
      expect(init, contains('fvm dart run tool/harness.dart bootstrap'));
      expect(init, contains('fvm dart run tool/harness.dart check'));
    });

    test('ci runs the standard harness lifecycle', () {
      final workflow = File('.github/workflows/harness.yml').readAsStringSync();

      expect(workflow, contains('fvm install'));
      expect(workflow, contains('./init.sh'));
    });

    test('maestro ci runs simulator acceptance without release artifacts', () {
      final workflow = File('.github/workflows/maestro.yml').readAsStringSync();

      expect(workflow, contains('iOS simulator Maestro'));
      expect(workflow, contains('Android emulator Maestro'));
      expect(workflow, contains('fvm flutter pub get'));
      expect(workflow, contains('xcrun simctl boot'));
      expect(workflow, contains('reactivecircus/android-emulator-runner@v2'));
      expect(workflow, contains('tool/harness.dart spec accept'));
      expect(workflow, contains('--maestro --platform ios'));
      expect(workflow, contains('bash tool/ci_android_maestro.sh'));
      expect(workflow, isNot(contains('flutter build ipa')));
      expect(workflow, isNot(contains('flutter build appbundle')));
      expect(workflow, isNot(contains('upload-artifact')));

      final androidScript = File(
        'tool/ci_android_maestro.sh',
      ).readAsStringSync();
      expect(androidScript, contains('set -euo pipefail'));
      expect(androidScript, contains('feature_list.json'));
      expect(androidScript, contains('--maestro --platform android'));
    });

    test('coverage gate protects non-ui logic coverage', () {
      final runner = File('tool/harness.dart').readAsStringSync();
      final validation = File('docs/harness/VALIDATION.md').readAsStringSync();
      final quality = File('docs/harness/QUALITY.md').readAsStringSync();

      expect(runner, contains("case 'coverage'"));
      expect(runner, contains("'flutter', 'test', '--coverage'"));
      expect(runner, contains("_isIncludedCoverageFile"));
      expect(runner, contains("normalized.contains('/presentation/pages/')"));
      expect(runner, contains("normalized.startsWith('lib/core/router/')"));
      expect(runner, contains("return 90"));
      expect(runner, contains("tool/harness.dart', 'coverage'"));
      expect(validation, contains('Coverage Gate'));
      expect(quality, contains('coverage at 90%'));
    });

    test('bootstrap uses the current build_runner command', () {
      final runner = File('tool/harness.dart').readAsStringSync();
      final validation = File('docs/harness/VALIDATION.md').readAsStringSync();

      expect(runner, contains("'dart',"));
      expect(runner, contains("'build_runner',"));
      expect(runner, contains("'build',"));
      expect(runner, isNot(contains('--delete-conflicting-outputs')));
      expect(validation, contains('fvm dart run build_runner build'));
    });

    test('spec evaluation workflow is discoverable via harness commands', () {
      final runner = File('tool/harness.dart').readAsStringSync();
      expect(runner, contains("case 'eval'"));
      expect(runner, contains("case 'eval-all'"));
      expect(runner, contains("case 'eval-ios'"));
      expect(runner, contains('_platformsFor'));
      expect(
        runner,
        contains("maestro', ['test', '--platform', plat, target]"),
      );
    });

    test(
      'spec evaluation workflow is wired and has an acceptance checklist',
      () {
        expect(
          File('docs/harness/specs/home-counter/acceptance.yaml').existsSync(),
          isTrue,
        );

        final runner = File('tool/harness.dart').readAsStringSync();
        expect(runner, contains("case 'spec'"));
        expect(runner, contains('_specReview'));
        expect(runner, contains('_specAccept'));
        expect(runner, contains('--maestro'));
        expect(runner, contains('spec-approved'));
        expect(runner, contains('build/harness/evidence'));
        // Gate B can run Maestro explicitly and reports when no device is ready.
        expect(runner, contains('_buildAndInstall'));
        expect(runner, contains('--platform'));
        expect(runner, contains('ios|android|all'));
        expect(runner, contains('_specAcceptAll'));
        expect(runner, contains(r'report-$plat.json'));
        expect(
          File('docs/harness/evidence/README.md').readAsStringSync(),
          contains('report-android.json'),
        );
        expect(runner, contains('Maestro acceptance blocked'));
        expect(runner, contains('_overallFromVerdicts'));
        expect(runner, contains("case 'ui-map'"));
        expect(runner, contains('_generateCanonicalUiMap'));

        final acceptance = File(
          'docs/harness/specs/home-counter/acceptance.yaml',
        ).readAsStringSync();
        expect(acceptance, contains('spec: home-counter'));
        expect(acceptance, contains('kind: maestro'));
        final doc = yaml.loadYaml(acceptance) as yaml.YamlMap;
        final criteria = doc['acceptance'] as yaml.YamlList;
        final hasTestCriterion = criteria.any(
          (item) => (item as yaml.YamlMap)['kind'].toString() == 'test',
        );
        expect(hasTestCriterion, isFalse);
      },
    );

    test('ui behavior is not covered by Flutter widget tests', () {
      final violations = _dartFilesUnder('test')
          .where((file) => !file.path.contains('/harness/'))
          .expand(_widgetTestViolations)
          .toList();

      expect(
        violations,
        isEmpty,
        reason:
            'UI behavior belongs in Maestro flows. Keep Flutter tests for '
            'logic, data, BLoC, repository, configuration, and harness rules.',
      );
    });

    test('every spec has at least one maestro acceptance criterion', () {
      final acceptanceFiles = _acceptanceFiles();
      expect(acceptanceFiles, isNotEmpty);
      for (final file in acceptanceFiles) {
        final doc = yaml.loadYaml(file.readAsStringSync()) as yaml.YamlMap;
        final acceptance = doc['acceptance'] as yaml.YamlList;
        final hasMaestro = acceptance.any(
          (item) => (item as yaml.YamlMap)['kind'].toString() == 'maestro',
        );
        expect(
          hasMaestro,
          isTrue,
          reason: '${file.path} must have at least one kind: maestro criterion',
        );
      }
    });

    test(
      'every maestro flow referenced by a spec exists on both platforms',
      () {
        for (final file in _acceptanceFiles()) {
          final doc = yaml.loadYaml(file.readAsStringSync()) as yaml.YamlMap;
          final acceptance = doc['acceptance'] as yaml.YamlList;
          for (final item in acceptance) {
            final m = item as yaml.YamlMap;
            if (m['kind'].toString() != 'maestro') continue;
            final flow = m['flow'].toString();
            for (final platform in const ['ios', 'android']) {
              final path = '.maestro/$platform/$flow.yaml';
              expect(
                File(path).existsSync(),
                isTrue,
                reason: 'Flow $path referenced by ${file.path} is missing',
              );
            }
          }
        }
      },
    );

    test('canonical UI map is generated from approved spec deltas', () async {
      final canonicalFile = File('docs/harness/specs/ui-map.yaml');
      expect(canonicalFile.existsSync(), isTrue);

      final result = await Process.run('fvm', [
        'dart',
        'run',
        'tool/harness.dart',
        'spec',
        'ui-map',
        '--check',
      ]);

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      expect(
        canonicalFile.readAsStringSync(),
        contains('Generated by `fvm dart run tool/harness.dart spec ui-map`'),
      );
    });

    test('done feature evidence matches current acceptance checklists', () {
      final decoded =
          jsonDecode(File('feature_list.json').readAsStringSync())
              as Map<String, Object?>;
      final features = (decoded['features'] as List<Object?>)
          .cast<Map<String, Object?>>();

      for (final feature in features.where((f) => f['status'] == 'done')) {
        final spec = feature['spec'] as String?;
        expect(
          spec,
          isNotNull,
          reason: '${feature['id']} is done without spec',
        );

        final reportFile = File('docs/harness/evidence/$spec/report.json');
        expect(
          reportFile.existsSync(),
          isTrue,
          reason: '${feature['id']} is done without committed evidence',
        );

        final report =
            jsonDecode(reportFile.readAsStringSync()) as Map<String, Object?>;
        expect(report['result'], 'PASS');
        expect(report['feature'], feature['id']);
        expect(report['spec'], spec);

        final acceptanceFile = File('docs/harness/specs/$spec/acceptance.yaml');
        final acceptanceDoc =
            yaml.loadYaml(acceptanceFile.readAsStringSync()) as yaml.YamlMap;
        final acceptance = (acceptanceDoc['acceptance'] as yaml.YamlList)
            .cast<yaml.YamlMap>();

        _expectPassingAcceptanceReport(
          report: report,
          feature: feature,
          spec: spec!,
          acceptance: acceptance,
        );
      }
    });

    test('home_counter flow exists with correct dev app ids', () {
      final iosFlow = File(
        '.maestro/ios/home_counter_flow.yaml',
      ).readAsStringSync();
      final androidFlow = File(
        '.maestro/android/home_counter_flow.yaml',
      ).readAsStringSync();

      expect(iosFlow, contains('cn.com.fenrir-inc.iosAppTest.dev'));
      expect(iosFlow, contains('home.counter.increment'));
      expect(androidFlow, contains('com.example.basic_demo.dev'));
      expect(androidFlow, contains('home.counter.reset'));
    });

    test('feature statuses stay within the documented legend', () {
      final decoded =
          jsonDecode(File('feature_list.json').readAsStringSync())
              as Map<String, Object?>;
      final legend = (decoded['status_legend'] as List<Object?>)
          .cast<String>()
          .toSet();
      expect(
        legend,
        containsAll(<String>[
          'proposed',
          'spec-drafting',
          'spec-approved',
          'implementing',
          'accepted',
        ]),
      );

      final features = (decoded['features'] as List<Object?>)
          .cast<Map<String, Object?>>();
      for (final feature in features) {
        final status = feature['status'] as String;
        expect(
          legend.contains(status),
          isTrue,
          reason: '${feature['id']} has status "$status" not in status_legend',
        );
      }
    });

    test('every feature with a business layer links an approved spec', () {
      final decoded =
          jsonDecode(File('feature_list.json').readAsStringSync())
              as Map<String, Object?>;
      final features = (decoded['features'] as List<Object?>)
          .cast<Map<String, Object?>>();

      const approvedStatuses = <String>{
        'spec-approved',
        'implementing',
        'accepted',
        'done',
      };

      for (final entry in features) {
        final featureDir = entry['feature_dir'];
        // Only check features that declare a feature_dir and have a business layer.
        if (featureDir == null) continue;
        final hasBusinessLayer =
            Directory('$featureDir/domain').existsSync() ||
            Directory('$featureDir/data').existsSync();
        if (!hasBusinessLayer) continue;

        final spec = entry['spec'];
        if (spec == null) continue;
        expect(
          spec,
          isA<String>(),
          reason:
              '${entry['id']} ($featureDir) has a business layer but no spec '
              'linked in feature_list.json.',
        );
        expect(
          approvedStatuses.contains(entry['status']),
          isTrue,
          reason:
              '${entry['id']} (spec $spec) is not past gate A: status is '
              '"${entry['status']}" but implementation already exists under '
              '$featureDir.',
        );
      }
    });

    test('domain layer does not import data or presentation', () {
      final violations = _dartFilesUnder('lib/features')
          .where((file) => file.path.contains('/domain/'))
          .expand(_layerImportViolations)
          .toList();

      expect(violations, isEmpty);
    });

    test('data layer does not import presentation', () {
      final violations = _dartFilesUnder('lib/features')
          .where((file) => file.path.contains('/data/'))
          .expand(_presentationImportViolations)
          .toList();

      expect(violations, isEmpty);
    });

    test('features with domain or data expose all business layers', () {
      final featuresDirectory = Directory('lib/features');
      final featureDirectories = featuresDirectory
          .listSync()
          .whereType<Directory>()
          .where((directory) => !directory.path.endsWith('.DS_Store'));

      for (final feature in featureDirectories) {
        final hasBusinessLayer =
            Directory('${feature.path}/domain').existsSync() ||
            Directory('${feature.path}/data').existsSync();

        if (!hasBusinessLayer) {
          continue;
        }

        for (final layer in ['domain', 'data', 'presentation']) {
          final layerDirectory = Directory('${feature.path}/$layer');
          expect(
            layerDirectory.existsSync(),
            isTrue,
            reason: '${feature.path} should contain $layer',
          );
        }
      }
    });
  });
}

Iterable<File> _dartFilesUnder(String path) {
  return Directory(path)
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));
}

Iterable<File> _acceptanceFiles() {
  final specsDirectory = Directory('docs/harness/specs');
  if (!specsDirectory.existsSync()) {
    return const [];
  }

  return specsDirectory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('acceptance.yaml'));
}

Iterable<String> _layerImportViolations(File file) {
  final content = file.readAsStringSync();
  final forbiddenPatterns = [
    RegExp("import\\s+['\\\"].*/data/"),
    RegExp("import\\s+['\\\"].*/presentation/"),
    RegExp("import\\s+['\\\"]package:flutter_foundations/features/.*/data/"),
    RegExp(
      "import\\s+['\\\"]package:flutter_foundations/features/.*/presentation/",
    ),
  ];

  return forbiddenPatterns
      .where((pattern) => pattern.hasMatch(content))
      .map((pattern) => '${file.path} matches ${pattern.pattern}');
}

Iterable<String> _presentationImportViolations(File file) {
  final content = file.readAsStringSync();
  final forbiddenPatterns = [
    RegExp("import\\s+['\\\"].*/presentation/"),
    RegExp(
      "import\\s+['\\\"]package:flutter_foundations/features/.*/presentation/",
    ),
  ];

  return forbiddenPatterns
      .where((pattern) => pattern.hasMatch(content))
      .map((pattern) => '${file.path} matches ${pattern.pattern}');
}

Iterable<String> _widgetTestViolations(File file) {
  final content = file.readAsStringSync();
  const forbidden = ['testWidgets(', 'WidgetTester', '.pumpWidget('];
  return forbidden
      .where(content.contains)
      .map((token) => '${file.path} contains $token');
}

void _expectPassingAcceptanceReport({
  required Map<String, Object?> report,
  required Map<String, Object?> feature,
  required String spec,
  required List<yaml.YamlMap> acceptance,
}) {
  expect(report['result'], 'PASS');
  expect(report['feature'], feature['id']);
  expect(report['spec'], spec);

  if (report['platform'] == 'all') {
    final platforms = (report['platforms'] as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(
      platforms.map((platform) => platform['platform']),
      containsAll(const ['ios', 'android']),
    );
    for (final platformReport in platforms) {
      _expectPassingSinglePlatformReport(
        report: platformReport,
        feature: feature,
        spec: spec,
        acceptance: acceptance,
      );
    }
    return;
  }

  _expectPassingSinglePlatformReport(
    report: report,
    feature: feature,
    spec: spec,
    acceptance: acceptance,
  );
}

void _expectPassingSinglePlatformReport({
  required Map<String, Object?> report,
  required Map<String, Object?> feature,
  required String spec,
  required List<yaml.YamlMap> acceptance,
}) {
  expect(report['result'], 'PASS');
  expect(report['feature'], feature['id']);
  expect(report['spec'], spec);
  expect(report['platform'], isIn(const ['ios', 'android']));

  final reported = (report['acceptance'] as List<Object?>)
      .cast<Map<String, Object?>>();

  expect(reported, hasLength(acceptance.length));
  for (var i = 0; i < acceptance.length; i += 1) {
    expect(reported[i]['id'], acceptance[i]['id']);
    expect(reported[i]['claim'], acceptance[i]['claim']);
    expect(reported[i]['kind'], acceptance[i]['kind']);
    expect(reported[i]['verdict'], 'pass');
  }
}
