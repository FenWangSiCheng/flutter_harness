import 'package:injectable/injectable.dart';

import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

@injectable
class AddTodoUseCase {
  AddTodoUseCase(this.repository);

  final TodoRepository repository;

  List<Todo> call(String title) {
    return repository.addTodo(title);
  }
}
