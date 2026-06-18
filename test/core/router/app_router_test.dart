import 'package:flutter/material.dart';
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

    test('router should have home route', () {
      final routes = appRouter.router.configuration.routes;
      final homeRoute = routes.firstWhere(
        (route) => (route as GoRoute).path == RouterPaths.home,
      );
      expect(homeRoute, isNotNull);
    });

    test('router should have user route', () {
      final routes = appRouter.router.configuration.routes;
      final userRoute = routes.firstWhere(
        (route) => (route as GoRoute).path == RouterPaths.user,
      );
      expect(userRoute, isNotNull);
    });

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

    group('Navigation', () {
      testWidgets('should navigate to home page', (tester) async {
        await tester.pumpWidget(
          MaterialApp.router(routerConfig: appRouter.router),
        );

        expect(find.byType(MaterialApp), findsOneWidget);
        await tester.pumpAndSettle();
        // There are two "Home" texts in the tree: one in the page body
        // and one as the BottomNavigationBar label. Assert specifically
        // on the centered body content to avoid ambiguity.
        expect(find.widgetWithText(Center, 'Home'), findsOneWidget);
      });

      testWidgets('should navigate to user page', (tester) async {
        await tester.pumpWidget(
          MaterialApp.router(routerConfig: appRouter.router),
        );

        appRouter.router.go(RouterPaths.user);
        await tester.pumpAndSettle();

        expect(
          appRouter.router.routeInformationProvider.value.uri.path,
          RouterPaths.user,
        );
        expect(find.text('User Info'), findsOneWidget);
      });

      testWidgets('should show error page for invalid route', (tester) async {
        await tester.pumpWidget(
          MaterialApp.router(routerConfig: appRouter.router),
        );

        appRouter.router.go('/invalid-route');
        await tester.pumpAndSettle();

        expect(find.text('Error'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.textContaining('Page not found'), findsOneWidget);
        expect(find.text('Go Home'), findsOneWidget);
      });

      testWidgets('should navigate back to home from error page', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp.router(routerConfig: appRouter.router),
        );

        appRouter.router.go('/invalid-route');
        await tester.pumpAndSettle();

        expect(find.text('Error'), findsOneWidget);

        await tester.tap(find.text('Go Home'));
        await tester.pumpAndSettle();

        expect(
          appRouter.router.routeInformationProvider.value.uri.path,
          RouterPaths.home,
        );
      });
    });
  });
}
