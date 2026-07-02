import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_foundations/core/router/app_router.dart';
import 'package:flutter_foundations/core/router/router_constants.dart';
import 'package:flutter_foundations/features/user/presentation/bloc/user_bloc.dart';
import 'package:flutter_foundations/features/user/presentation/bloc/user_state.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'app_router_test.mocks.dart';

@GenerateMocks([UserBloc])
void main() {
  group('AppRouter', () {
    late AppRouter appRouter;
    late MockUserBloc mockUserBloc;

    setUp(() {
      // Initialize GetIt for tests
      if (GetIt.instance.isRegistered<UserBloc>()) {
        GetIt.instance.unregister<UserBloc>();
      }

      mockUserBloc = MockUserBloc();
      GetIt.instance.registerFactory<UserBloc>(() => mockUserBloc);

      // Setup mock behavior
      when(mockUserBloc.stream).thenAnswer((_) => const Stream.empty());
      when(mockUserBloc.state).thenReturn(UserInitial());

      appRouter = AppRouter();
    });

    tearDown(() {
      if (GetIt.instance.isRegistered<UserBloc>()) {
        GetIt.instance.unregister<UserBloc>();
      }
    });

    test('router should not be null', () {
      expect(appRouter.router, isNotNull);
      expect(appRouter.router, isA<GoRouter>());
    });

    test('router should have routes configured', () {
      expect(appRouter.router.configuration.routes, isNotEmpty);
    });

    for (final path in const [RouterPaths.home, RouterPaths.user]) {
      test('router should have $path route', () {
        final routes = appRouter.router.configuration.routes;
        final match = routes.whereType<GoRoute>().firstWhere(
          (route) => route.path == path,
          orElse: () => throw TestFailure('Missing route for $path'),
        );
        expect(match, isNotNull);
      });
    }

    test('router should have correct initial location', () {
      expect(
        appRouter.router.routeInformationProvider.value.uri.path,
        RouterPaths.home,
      );
    });

    group('Multiple instances', () {
      test('should create independent router instances', () {
        final router1 = AppRouter();
        final router2 = AppRouter();

        expect(router1.router, isNot(same(router2.router)));
      });
    });
  });
}
