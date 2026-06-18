import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_foundations/features/user/data/datasource/remote_datasource.dart';
import 'package:flutter_foundations/features/user/data/models/user_model.dart';
import 'package:flutter_foundations/features/user/data/repositories/user_repository_impl.dart';
import 'package:flutter_foundations/features/user/domain/entities/user.dart';

import 'user_repository_impl_test.mocks.dart';

@GenerateMocks([RemoteDataSource])
void main() {
  late UserRepositoryImpl repository;
  late MockRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = MockRemoteDataSource();
    repository = UserRepositoryImpl(mockRemoteDataSource);
  });

  group('UserRepositoryImpl - getUser', () {
    const tUserId = '1';
    const tUserModel = UserModel(
      id: '1',
      name: 'John Doe',
      email: 'john@example.com',
    );
    final tUser = tUserModel.toEntity();

    test(
      'should return User entity when remote data source call is successful',
      () async {
        when(
          mockRemoteDataSource.getUser(any),
        ).thenAnswer((_) async => tUserModel);

        final result = await repository.getUser(tUserId);

        expect(result, isA<User>());
        expect(result.id, equals(tUser.id));
        expect(result.name, equals(tUser.name));
        expect(result.email, equals(tUser.email));
        verify(mockRemoteDataSource.getUser(tUserId)).called(1);
      },
    );

    test('should throw Exception when remote data source throws', () async {
      when(
        mockRemoteDataSource.getUser(any),
      ).thenThrow(Exception('Network error'));

      expect(() => repository.getUser(tUserId), throwsA(isA<Exception>()));
      verify(mockRemoteDataSource.getUser(tUserId)).called(1);
    });

    test('should pass the correct userId to remote data source', () async {
      when(
        mockRemoteDataSource.getUser(any),
      ).thenAnswer((_) async => tUserModel);

      await repository.getUser(tUserId);

      verify(mockRemoteDataSource.getUser(tUserId)).called(1);
      verifyNoMoreInteractions(mockRemoteDataSource);
    });
  });
}
