import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_foundations/features/user/data/models/user_model.dart';
import 'package:flutter_foundations/features/user/domain/entities/user.dart';

void main() {
  group('UserModel', () {
    const tUserModel = UserModel(
      id: '1',
      name: 'John Doe',
      email: 'john@example.com',
    );

    const tJson = {'id': '1', 'name': 'John Doe', 'email': 'john@example.com'};

    test('should be a subclass of User entity via toEntity', () {
      final entity = tUserModel.toEntity();
      expect(entity, isA<User>());
    });

    test('fromJson should return a valid model', () {
      final result = UserModel.fromJson(tJson);
      expect(result, equals(tUserModel));
    });

    test('toJson should return a JSON map containing proper data', () {
      final result = tUserModel.toJson();
      expect(result, equals(tJson));
    });

    test('toEntity should return a User entity with correct values', () {
      expect(
        tUserModel.toEntity(),
        equals(
          const User(id: '1', name: 'John Doe', email: 'john@example.com'),
        ),
      );
    });

    test('should support equality comparison', () {
      const model1 = UserModel(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
      );
      const model2 = UserModel(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
      );
      expect(model1, equals(model2));
    });

    test('should support copyWith', () {
      expect(
        tUserModel.copyWith(name: 'Jane Doe'),
        equals(tUserModel.copyWith(name: 'Jane Doe')),
      );
      expect(tUserModel.copyWith(name: 'Jane Doe').name, equals('Jane Doe'));
    });
  });
}
