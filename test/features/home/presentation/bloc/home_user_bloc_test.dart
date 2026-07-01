import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_foundations/features/user/domain/entities/user.dart';
import 'package:flutter_foundations/features/user/domain/usecase/get_user_use_case.dart';
import 'package:flutter_foundations/features/home/presentation/bloc/home_user_bloc.dart';
import 'package:flutter_foundations/features/home/presentation/bloc/home_user_event.dart';
import 'package:flutter_foundations/features/home/presentation/bloc/home_user_state.dart';
import 'package:flutter_foundations/core/network/error/exception.dart';

import 'home_user_bloc_test.mocks.dart';

@GenerateMocks([GetUserUseCase])
void main() {
  late MockGetUserUseCase mockGetUserUseCase;

  setUp(() {
    mockGetUserUseCase = MockGetUserUseCase();
  });

  group('HomeUserBloc', () {
    const tUserId = '1';
    const tUser = User(
      id: '1',
      name: 'John Doe',
      email: 'john.doe@example.com',
    );

    test('initial state is HomeUserInitial', () async {
      final bloc = HomeUserBloc(mockGetUserUseCase);

      expect(bloc.state, equals(HomeUserInitial()));

      await bloc.close();
    });

    blocTest<HomeUserBloc, HomeUserState>(
      'emits [HomeUserLoading, HomeUserLoaded] when LoadHomeUser succeeds',
      build: () {
        when(mockGetUserUseCase.call(any)).thenAnswer((_) async => tUser);
        return HomeUserBloc(mockGetUserUseCase);
      },
      act: (bloc) => bloc.add(const LoadHomeUser(tUserId)),
      expect: () => [HomeUserLoading(), const HomeUserLoaded(tUser)],
      verify: (_) {
        verify(mockGetUserUseCase.call(tUserId)).called(1);
      },
    );

    blocTest<HomeUserBloc, HomeUserState>(
      'emits [HomeUserLoading, HomeUserError] on generic exception',
      build: () {
        when(
          mockGetUserUseCase.call(any),
        ).thenThrow(Exception('Failed to load user'));
        return HomeUserBloc(mockGetUserUseCase);
      },
      act: (bloc) => bloc.add(const LoadHomeUser(tUserId)),
      expect: () => [
        HomeUserLoading(),
        const HomeUserError('Failed to load user. Please try again.'),
      ],
    );

    blocTest<HomeUserBloc, HomeUserState>(
      'emits [HomeUserLoading, HomeUserError] with ApiException message',
      build: () {
        when(
          mockGetUserUseCase.call(any),
        ).thenThrow(ApiException('Connection timeout'));
        return HomeUserBloc(mockGetUserUseCase);
      },
      act: (bloc) => bloc.add(const LoadHomeUser(tUserId)),
      expect: () => [
        HomeUserLoading(),
        const HomeUserError('Connection timeout'),
      ],
    );

    blocTest<HomeUserBloc, HomeUserState>(
      'calls GetUserUseCase with correct userId',
      build: () {
        when(mockGetUserUseCase.call(any)).thenAnswer((_) async => tUser);
        return HomeUserBloc(mockGetUserUseCase);
      },
      act: (bloc) => bloc.add(const LoadHomeUser('1')),
      verify: (_) {
        verify(mockGetUserUseCase.call('1')).called(1);
        verifyNoMoreInteractions(mockGetUserUseCase);
      },
    );

    blocTest<HomeUserBloc, HomeUserState>(
      'handles multiple LoadHomeUser events independently',
      build: () {
        const user1 = User(id: '1', name: 'John', email: 'john@example.com');
        const user2 = User(id: '2', name: 'Jane', email: 'jane@example.com');

        when(mockGetUserUseCase.call('1')).thenAnswer((_) async => user1);
        when(mockGetUserUseCase.call('2')).thenAnswer((_) async => user2);
        return HomeUserBloc(mockGetUserUseCase);
      },
      act: (bloc) async {
        bloc.add(const LoadHomeUser('1'));
        await Future.delayed(const Duration(milliseconds: 100));
        bloc.add(const LoadHomeUser('2'));
      },
      expect: () => [
        HomeUserLoading(),
        const HomeUserLoaded(
          User(id: '1', name: 'John', email: 'john@example.com'),
        ),
        HomeUserLoading(),
        const HomeUserLoaded(
          User(id: '2', name: 'Jane', email: 'jane@example.com'),
        ),
      ],
    );
  });
}
