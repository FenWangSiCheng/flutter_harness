import '../entities/todo.dart';

abstract class TodoRepository {
  List<Todo> getTodos();

  List<Todo> addTodo(String title);

  List<Todo> toggleTodo({required int id, required bool completed});

  List<Todo> deleteTodo(int id);
}
