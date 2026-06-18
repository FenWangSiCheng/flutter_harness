import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:flutter_foundations/features/user/domain/entities/user.dart';
import 'package:flutter_foundations/features/user/presentation/bloc/user_bloc.dart';
import 'package:flutter_foundations/features/user/presentation/bloc/user_event.dart';
import 'package:flutter_foundations/features/user/presentation/bloc/user_state.dart';
import 'package:flutter_foundations/features/user/presentation/pages/user_page.dart';
import 'package:flutter_foundations/core/injection/injection.dart';

import 'user_page_test.mocks.dart';

@GenerateMocks([UserBloc])
void main() {
  late MockUserBloc mockUserBloc;

  setUp(() async {
    await getIt.reset();
    mockUserBloc = MockUserBloc();
    // Mock the getIt call
    getIt.registerFactory<UserBloc>(() => mockUserBloc);
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget makeTestableWidget(Widget child) {
    return MaterialApp(home: child);
  }

  group('UserPage', () {
    testWidgets('should display loading indicator when state is UserLoading', (
      WidgetTester tester,
    ) async {
      // Arrange
      when(mockUserBloc.state).thenReturn(UserLoading());
      when(mockUserBloc.stream).thenAnswer((_) => Stream.value(UserLoading()));

      // Act
      await tester.pumpWidget(makeTestableWidget(const UserPage()));
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('User Info'), findsOneWidget);
    });

    testWidgets('should display user data when state is UserLoaded', (
      WidgetTester tester,
    ) async {
      // Arrange
      const testUser = User(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
      );
      const loadedState = UserLoaded(testUser);

      when(mockUserBloc.state).thenReturn(loadedState);
      when(mockUserBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      // Act
      await tester.pumpWidget(makeTestableWidget(const UserPage()));
      await tester.pump();

      // Assert
      expect(find.text('ID: 1'), findsOneWidget);
      expect(find.text('Name: John Doe'), findsOneWidget);
      expect(find.text('Email: john@example.com'), findsOneWidget);
      expect(find.text('Load Different Users:'), findsOneWidget);
      expect(find.text('User 1'), findsOneWidget);
      expect(find.text('User 2'), findsOneWidget);
      expect(find.text('User 3'), findsOneWidget);
    });

    testWidgets('should display error message when state is UserError', (
      WidgetTester tester,
    ) async {
      // Arrange
      const errorState = UserError('Failed to load user');

      when(mockUserBloc.state).thenReturn(errorState);
      when(mockUserBloc.stream).thenAnswer((_) => Stream.value(errorState));

      // Act
      await tester.pumpWidget(makeTestableWidget(const UserPage()));
      await tester.pump();

      // Assert
      expect(find.text('Error: Failed to load user'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('should display default message when state is UserInitial', (
      WidgetTester tester,
    ) async {
      // Arrange
      when(mockUserBloc.state).thenReturn(UserInitial());
      when(mockUserBloc.stream).thenAnswer((_) => Stream.value(UserInitial()));

      // Act
      await tester.pumpWidget(makeTestableWidget(const UserPage()));
      await tester.pump();

      // Assert
      expect(find.text('Press a button to load user'), findsOneWidget);
    });

    testWidgets('should trigger LoadUserEvent when User 1 button is pressed', (
      WidgetTester tester,
    ) async {
      // Arrange
      const testUser = User(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
      );
      const loadedState = UserLoaded(testUser);

      when(mockUserBloc.state).thenReturn(loadedState);
      when(mockUserBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      // Act
      await tester.pumpWidget(makeTestableWidget(const UserPage()));
      await tester.pump();

      // Reset the mock to clear the initial LoadUserEvent('1') call from BlocProvider
      reset(mockUserBloc);
      when(mockUserBloc.state).thenReturn(loadedState);
      when(mockUserBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      await tester.tap(find.text('User 1'));
      await tester.pump();

      // Assert
      verify(mockUserBloc.add(const LoadUserEvent('1'))).called(1);
    });

    testWidgets('should trigger LoadUserEvent when User 2 button is pressed', (
      WidgetTester tester,
    ) async {
      // Arrange
      const testUser = User(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
      );
      const loadedState = UserLoaded(testUser);

      when(mockUserBloc.state).thenReturn(loadedState);
      when(mockUserBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      // Act
      await tester.pumpWidget(makeTestableWidget(const UserPage()));
      await tester.pump();

      await tester.tap(find.text('User 2'));
      await tester.pump();

      // Assert
      verify(mockUserBloc.add(const LoadUserEvent('2'))).called(1);
    });

    testWidgets('should trigger LoadUserEvent when User 3 button is pressed', (
      WidgetTester tester,
    ) async {
      // Arrange
      const testUser = User(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
      );
      const loadedState = UserLoaded(testUser);

      when(mockUserBloc.state).thenReturn(loadedState);
      when(mockUserBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      // Act
      await tester.pumpWidget(makeTestableWidget(const UserPage()));
      await tester.pump();

      await tester.tap(find.text('User 3'));
      await tester.pump();

      // Assert
      verify(mockUserBloc.add(const LoadUserEvent('3'))).called(1);
    });

    testWidgets('should trigger LoadUserEvent when Retry button is pressed', (
      WidgetTester tester,
    ) async {
      // Arrange
      const errorState = UserError('Failed to load user');

      when(mockUserBloc.state).thenReturn(errorState);
      when(mockUserBloc.stream).thenAnswer((_) => Stream.value(errorState));

      // Act
      await tester.pumpWidget(makeTestableWidget(const UserPage()));
      await tester.pump();

      // Reset the mock to clear the initial LoadUserEvent('1') call from BlocProvider
      reset(mockUserBloc);
      when(mockUserBloc.state).thenReturn(errorState);
      when(mockUserBloc.stream).thenAnswer((_) => Stream.value(errorState));

      await tester.tap(find.text('Retry'));
      await tester.pump();

      // Assert
      verify(mockUserBloc.add(const LoadUserEvent('1'))).called(1);
    });

    testWidgets('should have AppBar with correct title and color', (
      WidgetTester tester,
    ) async {
      // Arrange
      when(mockUserBloc.state).thenReturn(UserInitial());
      when(mockUserBloc.stream).thenAnswer((_) => Stream.value(UserInitial()));

      // Act
      await tester.pumpWidget(makeTestableWidget(const UserPage()));
      await tester.pump();

      // Assert
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.title, isA<Text>());
      expect((appBar.title as Text).data, equals('User Info'));
      expect(appBar.backgroundColor, equals(Colors.blue));
    });

    testWidgets('should display image or fallback icon in loaded state', (
      WidgetTester tester,
    ) async {
      // Arrange
      const testUser = User(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
      );
      const loadedState = UserLoaded(testUser);

      when(mockUserBloc.state).thenReturn(loadedState);
      when(mockUserBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      // Act
      await tester.pumpWidget(makeTestableWidget(const UserPage()));
      await tester.pump();

      // Assert - Image.asset widget should be present
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('should render Card widget for user info in loaded state', (
      WidgetTester tester,
    ) async {
      // Arrange
      const testUser = User(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
      );
      const loadedState = UserLoaded(testUser);

      when(mockUserBloc.state).thenReturn(loadedState);
      when(mockUserBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      // Act
      await tester.pumpWidget(makeTestableWidget(const UserPage()));
      await tester.pump();

      // Assert
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('should display all three user buttons in loaded state', (
      WidgetTester tester,
    ) async {
      // Arrange
      const testUser = User(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
      );
      const loadedState = UserLoaded(testUser);

      when(mockUserBloc.state).thenReturn(loadedState);
      when(mockUserBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      // Act
      await tester.pumpWidget(makeTestableWidget(const UserPage()));
      await tester.pump();

      // Assert
      expect(find.byType(ElevatedButton), findsNWidgets(3));
    });

    testWidgets('should display error icon in error state', (
      WidgetTester tester,
    ) async {
      // Arrange
      const errorState = UserError('Network error');

      when(mockUserBloc.state).thenReturn(errorState);
      when(mockUserBloc.stream).thenAnswer((_) => Stream.value(errorState));

      // Act
      await tester.pumpWidget(makeTestableWidget(const UserPage()));
      await tester.pump();

      // Assert
      final iconFinder = find.byIcon(Icons.error_outline);
      expect(iconFinder, findsOneWidget);

      final icon = tester.widget<Icon>(iconFinder);
      expect(icon.color, equals(Colors.red));
      expect(icon.size, equals(60));
    });
  });
}
