import 'package:equatable/equatable.dart';

class Todo extends Equatable {
  const Todo({required this.id, required this.title, this.completed = false});

  final int id;
  final String title;
  final bool completed;

  Todo copyWith({bool? completed}) {
    return Todo(id: id, title: title, completed: completed ?? this.completed);
  }

  @override
  List<Object> get props => [id, title, completed];
}
