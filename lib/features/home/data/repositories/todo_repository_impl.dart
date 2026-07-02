import 'package:injectable/injectable.dart';

import '../../domain/entities/todo.dart';
import '../../domain/repositories/todo_repository.dart';
import '../datasource/todo_local_data_source.dart';

@LazySingleton(as: TodoRepository)
class TodoRepositoryImpl implements TodoRepository {
  TodoRepositoryImpl(this.localDataSource);

  final TodoLocalDataSource localDataSource;

  @override
  List<Todo> getTodos() {
    return localDataSource.getTodos().map((todo) => todo.toEntity()).toList();
  }

  @override
  List<Todo> addTodo(String title) {
    return localDataSource
        .addTodo(title)
        .map((todo) => todo.toEntity())
        .toList();
  }

  @override
  List<Todo> toggleTodo({required int id, required bool completed}) {
    return localDataSource
        .toggleTodo(id: id, completed: completed)
        .map((todo) => todo.toEntity())
        .toList();
  }

  @override
  List<Todo> deleteTodo(int id) {
    return localDataSource
        .deleteTodo(id)
        .map((todo) => todo.toEntity())
        .toList();
  }
}
