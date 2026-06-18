import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_foundations/features/user/presentation/bloc/user_event.dart';

// Concrete implementation for testing the abstract UserEvent class
class _TestUserEvent extends UserEvent {
  const _TestUserEvent();
}

void main() {
  group('UserEvent', () {
    test('base class should have empty props', () {
      const event = _TestUserEvent();
      expect(event.props, equals([]));
    });

    test('base class instances should be equal with same props', () {
      const event1 = _TestUserEvent();
      const event2 = _TestUserEvent();
      expect(event1, equals(event2));
    });

    group('LoadUserEvent', () {
      const tUserId = '1';

      test('should have correct props', () {
        const event = LoadUserEvent(tUserId);
        expect(event.props, equals([tUserId]));
      });

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

      test('should handle empty user ID', () {
        const event = LoadUserEvent('');
        expect(event.props, equals(['']));
        expect(event.userId, equals(''));
      });

      test('should handle special characters in user ID', () {
        const event = LoadUserEvent('user@123!#');
        expect(event.props, equals(['user@123!#']));
        expect(event.userId, equals('user@123!#'));
      });

      test('should create different instances with different user IDs', () {
        const event1 = LoadUserEvent('user1');
        const event2 = LoadUserEvent('user2');
        const event3 = LoadUserEvent('user3');

        expect(event1, isNot(equals(event2)));
        expect(event2, isNot(equals(event3)));
        expect(event1, isNot(equals(event3)));
      });
    });
  });
}
