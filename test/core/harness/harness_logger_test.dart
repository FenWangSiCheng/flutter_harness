import 'package:flutter_foundations/core/harness/harness_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(HarnessLogger.reset);

  test('writes structured events to configured sink', () {
    final sink = RecordingHarnessLogSink();
    final timestamp = DateTime.utc(2026, 6, 18, 12, 30);

    HarnessLogger.configure(sink: sink, clock: () => timestamp, enabled: true);

    HarnessLogger.event('app.bootstrap.ready', fields: {'elapsed_ms': 42});

    expect(sink.events, hasLength(1));
    expect(sink.events.single.name, 'app.bootstrap.ready');
    expect(sink.events.single.timestamp, timestamp);
    expect(sink.events.single.fields, {'elapsed_ms': 42});
  });

  test('does not write events when disabled', () {
    final sink = RecordingHarnessLogSink();

    HarnessLogger.configure(sink: sink, enabled: false);
    HarnessLogger.event('ignored');

    expect(sink.events, isEmpty);
  });

  test('writes flow success and failure events', () {
    final sink = RecordingHarnessLogSink();

    HarnessLogger.configure(sink: sink, enabled: true);
    HarnessLogger.flowSucceeded('user_profile', fields: {'user_id': '1'});
    HarnessLogger.flowFailed('user_profile', fields: {'message': 'boom'});

    expect(sink.events.map((event) => event.name), [
      'flow.user_profile.succeeded',
      'flow.user_profile.failed',
    ]);
    expect(sink.events.first.fields, {'result': 'success', 'user_id': '1'});
    expect(sink.events.last.fields, {'result': 'failure', 'message': 'boom'});
  });
}

class RecordingHarnessLogSink extends HarnessLogSink {
  final List<HarnessLogEvent> events = [];

  @override
  void write(HarnessLogEvent event) {
    events.add(event);
  }
}
