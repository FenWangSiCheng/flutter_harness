import 'dart:convert';

import 'package:flutter/foundation.dart';

typedef HarnessClock = DateTime Function();

class HarnessLogEvent {
  const HarnessLogEvent({
    required this.timestamp,
    required this.name,
    required this.fields,
  });

  final DateTime timestamp;
  final String name;
  final Map<String, Object?> fields;

  Map<String, Object?> toJson() {
    return {
      'timestamp': timestamp.toUtc().toIso8601String(),
      'name': name,
      'fields': fields,
    };
  }
}

abstract class HarnessLogSink {
  const HarnessLogSink();

  void write(HarnessLogEvent event);
}

class DebugPrintHarnessLogSink extends HarnessLogSink {
  const DebugPrintHarnessLogSink();

  @override
  void write(HarnessLogEvent event) {
    debugPrint('[harness] ${jsonEncode(event.toJson())}');
  }
}

class HarnessLogger {
  HarnessLogger._();

  static HarnessLogSink _sink = const DebugPrintHarnessLogSink();
  static HarnessClock _clock = DateTime.now;
  static bool _enabled = !kReleaseMode;

  static bool get isEnabled => _enabled;

  static void configure({
    HarnessLogSink? sink,
    HarnessClock? clock,
    bool? enabled,
  }) {
    if (sink != null) {
      _sink = sink;
    }
    if (clock != null) {
      _clock = clock;
    }
    if (enabled != null) {
      _enabled = enabled;
    }
  }

  static void reset() {
    _sink = const DebugPrintHarnessLogSink();
    _clock = DateTime.now;
    _enabled = !kReleaseMode;
  }

  static void event(String name, {Map<String, Object?> fields = const {}}) {
    if (!_enabled) {
      return;
    }

    _sink.write(
      HarnessLogEvent(
        timestamp: _clock(),
        name: name,
        fields: Map.unmodifiable(fields),
      ),
    );
  }

  static void flowSucceeded(
    String flow, {
    Map<String, Object?> fields = const {},
  }) {
    event('flow.$flow.succeeded', fields: {'result': 'success', ...fields});
  }

  static void flowFailed(
    String flow, {
    Map<String, Object?> fields = const {},
  }) {
    event('flow.$flow.failed', fields: {'result': 'failure', ...fields});
  }
}
