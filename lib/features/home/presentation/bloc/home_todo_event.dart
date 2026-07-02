import 'package:equatable/equatable.dart';

abstract class HomeTodoEvent extends Equatable {
  const HomeTodoEvent();

  @override
  List<Object?> get props => [];
}

class HomeTodoStarted extends HomeTodoEvent {
  const HomeTodoStarted();
}

class HomeTodoDraftChanged extends HomeTodoEvent {
  const HomeTodoDraftChanged(this.draft);

  final String draft;

  @override
  List<Object?> get props => [draft];
}

class HomeTodoSubmitted extends HomeTodoEvent {
  const HomeTodoSubmitted();
}

class HomeTodoCompletionToggled extends HomeTodoEvent {
  const HomeTodoCompletionToggled({required this.id, required this.completed});

  final int id;
  final bool completed;

  @override
  List<Object?> get props => [id, completed];
}

class HomeTodoDeleted extends HomeTodoEvent {
  const HomeTodoDeleted(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}
