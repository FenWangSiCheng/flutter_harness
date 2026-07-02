import 'package:injectable/injectable.dart';

import '../models/todo_model.dart';

abstract class TodoLocalDataSource {
  List<TodoModel> getTodos();

  List<TodoModel> addTodo(String title);

  List<TodoModel> toggleTodo({required int id, required bool completed});

  List<TodoModel> deleteTodo(int id);
}

@LazySingleton(as: TodoLocalDataSource)
class InMemoryTodoLocalDataSource implements TodoLocalDataSource {
  final List<TodoModel> _todos = [];
  int _nextId = 1;

  @override
  List<TodoModel> getTodos() {
    return List.unmodifiable(_todos);
  }

  @override
  List<TodoModel> addTodo(String title) {
    _todos.add(TodoModel(id: _nextId, title: title, completed: false));
    _nextId += 1;
    return getTodos();
  }

  @override
  List<TodoModel> toggleTodo({required int id, required bool completed}) {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index == -1) {
      return getTodos();
    }

    _todos[index] = _todos[index].copyWith(completed: completed);
    return getTodos();
  }

  @override
  List<TodoModel> deleteTodo(int id) {
    _todos.removeWhere((todo) => todo.id == id);
    return getTodos();
  }
}
