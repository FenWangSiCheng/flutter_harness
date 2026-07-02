import 'package:injectable/injectable.dart';

import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

@injectable
class ToggleTodoUseCase {
  ToggleTodoUseCase(this.repository);

  final TodoRepository repository;

  List<Todo> call({required int id, required bool completed}) {
    return repository.toggleTodo(id: id, completed: completed);
  }
}
