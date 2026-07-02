import 'package:equatable/equatable.dart';

import '../../domain/entities/todo.dart';

class HomeTodoState extends Equatable {
  const HomeTodoState({this.todos = const [], this.draft = ''});

  final List<Todo> todos;
  final String draft;

  int get completedCount => todos.where((todo) => todo.completed).length;

  int get activeCount => todos.length - completedCount;

  bool get canSubmit => draft.trim().isNotEmpty;

  HomeTodoState copyWith({List<Todo>? todos, String? draft}) {
    return HomeTodoState(
      todos: todos ?? this.todos,
      draft: draft ?? this.draft,
    );
  }

  @override
  List<Object> get props => [todos, draft];
}
