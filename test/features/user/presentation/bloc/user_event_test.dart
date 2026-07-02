import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_foundations/features/user/presentation/bloc/user_event.dart';

// Concrete implementation for testing the abstract UserEvent class
class _TestUserEvent extends UserEvent {
  const _TestUserEvent();
}

void main() {
  group('UserEvent', () {
    test('base class instances should be equal with same props', () {
      const event1 = _TestUserEvent();
      const event2 = _TestUserEvent();
      expect(event1, equals(event2));
    });

    group('LoadUserEvent', () {
      const tUserId = '1';

      test('should support equality comparison', () {
        const event1 = LoadUserEvent(tUserId);
        const event2 = LoadUserEvent(tUserId);
        expect(event1, equals(event2));
      });

      test('should differentiate between different user IDs', () {
        const event1 = LoadUserEvent('1');
        const event2 = LoadUserEvent('2');
        expect(event1, isNot(equals(event2)));
      });

      test('should be a UserEvent', () {
        const event = LoadUserEvent(tUserId);
        expect(event, isA<UserEvent>());
      });

      for (final id in <String>['', 'user@123!#']) {
        test('should preserve user ID "$id"', () {
          final event = LoadUserEvent(id);
          expect(event.userId, equals(id));
        });
      }
    });
  });
}
