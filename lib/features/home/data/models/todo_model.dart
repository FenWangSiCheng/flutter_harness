import '../../domain/entities/todo.dart';

class TodoModel {
  const TodoModel({
    required this.id,
    required this.title,
    required this.completed,
  });

  final int id;
  final String title;
  final bool completed;

  factory TodoModel.fromEntity(Todo todo) {
    return TodoModel(id: todo.id, title: todo.title, completed: todo.completed);
  }

  Todo toEntity() {
    return Todo(id: id, title: title, completed: completed);
  }

  TodoModel copyWith({bool? completed}) {
    return TodoModel(
      id: id,
      title: title,
      completed: completed ?? this.completed,
    );
  }
}
