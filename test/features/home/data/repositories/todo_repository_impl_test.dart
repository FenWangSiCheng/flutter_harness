import 'package:flutter_foundations/features/home/data/datasource/todo_local_data_source.dart';
import 'package:flutter_foundations/features/home/data/repositories/todo_repository_impl.dart';
import 'package:flutter_foundations/features/home/domain/entities/todo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TodoRepositoryImpl', () {
    late TodoRepositoryImpl repository;

    setUp(() {
      repository = TodoRepositoryImpl(InMemoryTodoLocalDataSource());
    });

    test('returns an empty list initially', () {
      expect(repository.getTodos(), isEmpty);
    });

    test('adds and maps todos to domain entities', () {
      final todos = repository.addTodo('Buy milk');

      expect(todos, [const Todo(id: 1, title: 'Buy milk')]);
    });

    test('toggles todo completion', () {
      repository.addTodo('Buy milk');

      final todos = repository.toggleTodo(id: 1, completed: true);

      expect(todos, [const Todo(id: 1, title: 'Buy milk', completed: true)]);
    });

    test('deletes todos', () {
      repository.addTodo('Buy milk');

      final todos = repository.deleteTodo(1);

      expect(todos, isEmpty);
    });
  });
}
