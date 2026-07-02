import 'package:injectable/injectable.dart';

import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

@injectable
class DeleteTodoUseCase {
  DeleteTodoUseCase(this.repository);

  final TodoRepository repository;

  List<Todo> call(int id) {
    return repository.deleteTodo(id);
  }
}
