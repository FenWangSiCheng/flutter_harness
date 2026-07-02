import 'package:flutter_foundations/features/home/data/datasource/todo_local_data_source.dart';
import 'package:flutter_foundations/features/home/data/models/todo_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InMemoryTodoLocalDataSource', () {
    late InMemoryTodoLocalDataSource dataSource;

    setUp(() {
      dataSource = InMemoryTodoLocalDataSource();
    });

    test('starts empty and returns an immutable snapshot', () {
      final todos = dataSource.getTodos();

      expect(todos, isEmpty);
      expect(
        () => todos.add(
          const TodoModel(id: 1, title: 'Buy milk', completed: false),
        ),
        throwsUnsupportedError,
      );
    });

    test('adds todos with incremental ids', () {
      dataSource.addTodo('Buy milk');
      final todos = dataSource.addTodo('Walk');

      expect(todos.map((todo) => todo.id), [1, 2]);
      expect(todos.map((todo) => todo.title), ['Buy milk', 'Walk']);
      expect(todos.every((todo) => !todo.completed), isTrue);
    });

    test('toggles completion for an existing todo', () {
      dataSource.addTodo('Buy milk');

      final todos = dataSource.toggleTodo(id: 1, completed: true);

      expect(todos.single.completed, isTrue);
    });

    test('ignores toggle for a missing todo', () {
      dataSource.addTodo('Buy milk');

      final todos = dataSource.toggleTodo(id: 99, completed: true);

      expect(todos.single.completed, isFalse);
    });

    test('deletes matching todo', () {
      dataSource.addTodo('Buy milk');
      dataSource.addTodo('Walk');

      final todos = dataSource.deleteTodo(1);

      expect(todos.map((todo) => todo.title), ['Walk']);
    });
  });
}
