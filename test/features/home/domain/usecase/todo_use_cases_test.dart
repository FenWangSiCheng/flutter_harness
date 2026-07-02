import 'package:flutter_foundations/features/home/data/datasource/todo_local_data_source.dart';
import 'package:flutter_foundations/features/home/data/repositories/todo_repository_impl.dart';
import 'package:flutter_foundations/features/home/domain/entities/todo.dart';
import 'package:flutter_foundations/features/home/domain/usecase/add_todo_use_case.dart';
import 'package:flutter_foundations/features/home/domain/usecase/delete_todo_use_case.dart';
import 'package:flutter_foundations/features/home/domain/usecase/get_todos_use_case.dart';
import 'package:flutter_foundations/features/home/domain/usecase/toggle_todo_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Todo use cases', () {
    late TodoRepositoryImpl repository;
    late GetTodosUseCase getTodos;
    late AddTodoUseCase addTodo;
    late ToggleTodoUseCase toggleTodo;
    late DeleteTodoUseCase deleteTodo;

    setUp(() {
      repository = TodoRepositoryImpl(InMemoryTodoLocalDataSource());
      getTodos = GetTodosUseCase(repository);
      addTodo = AddTodoUseCase(repository);
      toggleTodo = ToggleTodoUseCase(repository);
      deleteTodo = DeleteTodoUseCase(repository);
    });

    test('getTodos delegates to repository', () {
      expect(getTodos(), isEmpty);
    });

    test('addTodo delegates to repository', () {
      expect(addTodo('Buy milk'), [const Todo(id: 1, title: 'Buy milk')]);
    });

    test('toggleTodo delegates to repository', () {
      addTodo('Buy milk');

      expect(toggleTodo(id: 1, completed: true), [
        const Todo(id: 1, title: 'Buy milk', completed: true),
      ]);
    });

    test('deleteTodo delegates to repository', () {
      addTodo('Buy milk');

      expect(deleteTodo(1), isEmpty);
    });
  });
}
