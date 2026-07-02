import 'package:injectable/injectable.dart';

import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

@injectable
class GetTodosUseCase {
  GetTodosUseCase(this.repository);

  final TodoRepository repository;

  List<Todo> call() {
    return repository.getTodos();
  }
}
