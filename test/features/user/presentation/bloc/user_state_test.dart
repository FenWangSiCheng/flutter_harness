import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_foundations/features/user/domain/entities/user.dart';
import 'package:flutter_foundations/features/user/presentation/bloc/user_state.dart';

void main() {
  group('UserState', () {
    group('UserInitial', () {
      test('should be a UserState', () {
        final state = UserInitial();
        expect(state, isA<UserState>());
      });

      test('should have empty props', () {
        final state = UserInitial();
        expect(state.props, equals([]));
      });

      test('should support equality comparison', () {
        final state1 = UserInitial();
        final state2 = UserInitial();
        expect(state1, equals(state2));
      });
    });

    group('UserLoading', () {
      test('should be a UserState', () {
        final state = UserLoading();
        expect(state, isA<UserState>());
      });

      test('should have empty props', () {
        final state = UserLoading();
        expect(state.props, equals([]));
      });

      test('should support equality comparison', () {
        final state1 = UserLoading();
        final state2 = UserLoading();
        expect(state1, equals(state2));
      });
    });

    group('UserLoaded', () {
      const tUser = User(id: '1', name: 'John Doe', email: 'john@example.com');

      test('should be a UserState', () {
        const state = UserLoaded(tUser);
        expect(state, isA<UserState>());
      });

      test('should have user in props', () {
        const state = UserLoaded(tUser);
        expect(state.props, equals([tUser]));
      });

      test('should support equality comparison with same user', () {
        const state1 = UserLoaded(tUser);
        const state2 = UserLoaded(tUser);
        expect(state1, equals(state2));
      });

      test('should differentiate between different users', () {
        const user1 = User(id: '1', name: 'John', email: 'john@example.com');
        const user2 = User(id: '2', name: 'Jane', email: 'jane@example.com');
        const state1 = UserLoaded(user1);
        const state2 = UserLoaded(user2);
        expect(state1, isNot(equals(state2)));
      });
    });

    group('UserError', () {
      const tMessage = 'Error message';

      test('should be a UserState', () {
        const state = UserError(tMessage);
        expect(state, isA<UserState>());
      });

      test('should have message in props', () {
        const state = UserError(tMessage);
        expect(state.props, equals([tMessage]));
      });

      test('should support equality comparison with same message', () {
        const state1 = UserError(tMessage);
        const state2 = UserError(tMessage);
        expect(state1, equals(state2));
      });

      test('should differentiate between different messages', () {
        const state1 = UserError('Error 1');
        const state2 = UserError('Error 2');
        expect(state1, isNot(equals(state2)));
      });
    });
  });
}
