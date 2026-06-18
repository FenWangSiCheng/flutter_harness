import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_foundations/features/user/domain/entities/user.dart';

void main() {
  group('User', () {
    const tUser = User(id: '1', name: 'John Doe', email: 'john@example.com');

    test('should create a User instance with required properties', () {
      expect(tUser.id, equals('1'));
      expect(tUser.name, equals('John Doe'));
      expect(tUser.email, equals('john@example.com'));
    });

    test('should support equality comparison with Equatable', () {
      const user1 = User(id: '1', name: 'John Doe', email: 'john@example.com');
      const user2 = User(id: '1', name: 'John Doe', email: 'john@example.com');

      expect(user1, equals(user2));
      expect(user1.hashCode, equals(user2.hashCode));
    });

    test('should differentiate between different users', () {
      const user1 = User(id: '1', name: 'John Doe', email: 'john@example.com');
      const user2 = User(
        id: '2',
        name: 'Jane Smith',
        email: 'jane@example.com',
      );

      expect(user1, isNot(equals(user2)));
      expect(user1.hashCode, isNot(equals(user2.hashCode)));
    });

    test('should be a const constructor', () {
      const user = User(id: '1', name: 'John Doe', email: 'john@example.com');

      expect(user, isA<User>());
    });
  });
}
