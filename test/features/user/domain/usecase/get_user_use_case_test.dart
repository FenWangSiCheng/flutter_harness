import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_foundations/features/user/domain/entities/user.dart';
import 'package:flutter_foundations/features/user/domain/repositories/user_repository.dart';
import 'package:flutter_foundations/features/user/domain/usecase/get_user_use_case.dart';

import 'get_user_use_case_test.mocks.dart';

@GenerateMocks([UserRepository])
void main() {
  late GetUserUseCase useCase;
  late MockUserRepository mockRepository;

  setUp(() {
    mockRepository = MockUserRepository();
    useCase = GetUserUseCase(mockRepository);
  });

  group('GetUserUseCase', () {
    const tUserId = '1';
    const tUser = User(id: '1', name: 'John Doe', email: 'john@example.com');

    test('should get user from the repository', () async {
      when(mockRepository.getUser(any)).thenAnswer((_) async => tUser);

      final result = await useCase.call(tUserId);

      expect(result, equals(tUser));
      verify(mockRepository.getUser(tUserId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should pass the correct userId to repository', () async {
      when(mockRepository.getUser(any)).thenAnswer((_) async => tUser);

      await useCase.call(tUserId);

      verify(mockRepository.getUser(tUserId)).called(1);
    });

    test('should throw exception when repository throws', () async {
      when(
        mockRepository.getUser(any),
      ).thenThrow(Exception('Repository error'));

      expect(() => useCase.call(tUserId), throwsA(isA<Exception>()));
      verify(mockRepository.getUser(tUserId)).called(1);
    });

    test('should be callable with function call syntax', () async {
      when(mockRepository.getUser(any)).thenAnswer((_) async => tUser);

      final result = await useCase(tUserId);

      expect(result, equals(tUser));
      verify(mockRepository.getUser(tUserId)).called(1);
    });

    test('should handle multiple calls independently', () async {
      const userId1 = '1';
      const userId2 = '2';
      const user1 = User(id: '1', name: 'John Doe', email: 'john@example.com');
      const user2 = User(
        id: '2',
        name: 'Jane Smith',
        email: 'jane@example.com',
      );

      when(mockRepository.getUser(userId1)).thenAnswer((_) async => user1);
      when(mockRepository.getUser(userId2)).thenAnswer((_) async => user2);

      final result1 = await useCase(userId1);
      final result2 = await useCase(userId2);

      expect(result1, equals(user1));
      expect(result2, equals(user2));
      verify(mockRepository.getUser(userId1)).called(1);
      verify(mockRepository.getUser(userId2)).called(1);
    });
  });
}
