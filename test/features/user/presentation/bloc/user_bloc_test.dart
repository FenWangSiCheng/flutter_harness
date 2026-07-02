import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_foundations/features/user/domain/entities/user.dart';
import 'package:flutter_foundations/features/user/domain/usecase/get_user_use_case.dart';
import 'package:flutter_foundations/features/user/presentation/bloc/user_bloc.dart';
import 'package:flutter_foundations/features/user/presentation/bloc/user_event.dart';
import 'package:flutter_foundations/features/user/presentation/bloc/user_state.dart';
import 'package:flutter_foundations/core/network/error/exception.dart';

import 'user_bloc_test.mocks.dart';

@GenerateMocks([GetUserUseCase])
void main() {
  late MockGetUserUseCase mockGetUserUseCase;

  setUp(() {
    mockGetUserUseCase = MockGetUserUseCase();
  });

  group('UserBloc', () {
    const tUserId = '1';
    const tUser = User(id: '1', name: 'John Doe', email: 'john@example.com');

    test('initial state should be UserInitial', () async {
      final bloc = UserBloc(mockGetUserUseCase);

      expect(bloc.state, equals(UserInitial()));

      await bloc.close();
    });

    blocTest<UserBloc, UserState>(
      'should emit [UserLoading, UserLoaded] when LoadUserEvent is successful',
      build: () {
        when(mockGetUserUseCase.call(any)).thenAnswer((_) async => tUser);
        return UserBloc(mockGetUserUseCase);
      },
      act: (bloc) => bloc.add(const LoadUserEvent(tUserId)),
      expect: () => [UserLoading(), const UserLoaded(tUser)],
      verify: (_) {
        verify(mockGetUserUseCase.call(tUserId)).called(1);
      },
    );

    blocTest<UserBloc, UserState>(
      'should emit [UserLoading, UserError] when LoadUserEvent fails',
      build: () {
        when(
          mockGetUserUseCase.call(any),
        ).thenThrow(Exception('Failed to load user'));
        return UserBloc(mockGetUserUseCase);
      },
      act: (bloc) => bloc.add(const LoadUserEvent(tUserId)),
      expect: () => [
        UserLoading(),
        const UserError('Failed to load user. Please try again.'),
      ],
      verify: (_) {
        verify(mockGetUserUseCase.call(tUserId)).called(1);
      },
    );

    blocTest<UserBloc, UserState>(
      'should call getUserUseCase with correct userId',
      build: () {
        when(mockGetUserUseCase.call(any)).thenAnswer((_) async => tUser);
        return UserBloc(mockGetUserUseCase);
      },
      act: (bloc) => bloc.add(const LoadUserEvent(tUserId)),
      verify: (_) {
        verify(mockGetUserUseCase.call(tUserId)).called(1);
        verifyNoMoreInteractions(mockGetUserUseCase);
      },
    );

    blocTest<UserBloc, UserState>(
      'should handle multiple LoadUserEvent independently',
      build: () {
        const userId1 = '1';
        const userId2 = '2';
        const user1 = User(id: '1', name: 'John', email: 'john@example.com');
        const user2 = User(id: '2', name: 'Jane', email: 'jane@example.com');

        when(mockGetUserUseCase.call(userId1)).thenAnswer((_) async => user1);
        when(mockGetUserUseCase.call(userId2)).thenAnswer((_) async => user2);
        return UserBloc(mockGetUserUseCase);
      },
      act: (bloc) {
        bloc.add(const LoadUserEvent('1'));
        bloc.add(const LoadUserEvent('2'));
      },
      expect: () => [
        UserLoading(),
        const UserLoaded(
          User(id: '1', name: 'John', email: 'john@example.com'),
        ),
        UserLoading(),
        const UserLoaded(
          User(id: '2', name: 'Jane', email: 'jane@example.com'),
        ),
      ],
    );

    blocTest<UserBloc, UserState>(
      'should emit UserError with ApiException message',
      build: () {
        when(
          mockGetUserUseCase.call(any),
        ).thenThrow(ApiException('Connection timeout'));
        return UserBloc(mockGetUserUseCase);
      },
      act: (bloc) => bloc.add(const LoadUserEvent(tUserId)),
      expect: () => [UserLoading(), const UserError('Connection timeout')],
    );
  });
}
