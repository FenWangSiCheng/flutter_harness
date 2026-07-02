import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/harness/harness_logger.dart';
import '../../domain/usecase/add_todo_use_case.dart';
import '../../domain/usecase/delete_todo_use_case.dart';
import '../../domain/usecase/get_todos_use_case.dart';
import '../../domain/usecase/toggle_todo_use_case.dart';
import 'home_todo_event.dart';
import 'home_todo_state.dart';

@injectable
class HomeTodoBloc extends Bloc<HomeTodoEvent, HomeTodoState> {
  HomeTodoBloc({
    required this.getTodosUseCase,
    required this.addTodoUseCase,
    required this.toggleTodoUseCase,
    required this.deleteTodoUseCase,
  }) : super(const HomeTodoState()) {
    on<HomeTodoStarted>(_onStarted);
    on<HomeTodoDraftChanged>(_onDraftChanged);
    on<HomeTodoSubmitted>(_onSubmitted);
    on<HomeTodoCompletionToggled>(_onCompletionToggled);
    on<HomeTodoDeleted>(_onDeleted);
  }

  final GetTodosUseCase getTodosUseCase;
  final AddTodoUseCase addTodoUseCase;
  final ToggleTodoUseCase toggleTodoUseCase;
  final DeleteTodoUseCase deleteTodoUseCase;

  void _onStarted(HomeTodoStarted event, Emitter<HomeTodoState> emit) {
    emit(state.copyWith(todos: getTodosUseCase()));
    HarnessLogger.event('flow.home_todolist.initial');
  }

  void _onDraftChanged(
    HomeTodoDraftChanged event,
    Emitter<HomeTodoState> emit,
  ) {
    emit(state.copyWith(draft: event.draft));
  }

  void _onSubmitted(HomeTodoSubmitted event, Emitter<HomeTodoState> emit) {
    final title = state.draft.trim();
    if (title.isEmpty) {
      HarnessLogger.event('flow.home_todolist.add_empty_ignored');
      return;
    }

    final todos = addTodoUseCase(title);
    emit(state.copyWith(todos: todos, draft: ''));

    HarnessLogger.event(
      'flow.home_todolist.task_added',
      fields: {'task_count': todos.length},
    );
    HarnessLogger.flowSucceeded(
      'home_todolist',
      fields: {'action': 'task_added', 'task_count': todos.length},
    );
  }

  void _onCompletionToggled(
    HomeTodoCompletionToggled event,
    Emitter<HomeTodoState> emit,
  ) {
    final todos = toggleTodoUseCase(id: event.id, completed: event.completed);
    emit(state.copyWith(todos: todos));

    HarnessLogger.event(
      event.completed
          ? 'flow.home_todolist.task_completed'
          : 'flow.home_todolist.task_reopened',
      fields: {
        'task_id': event.id,
        'completed_count': todos.where((todo) => todo.completed).length,
        'task_count': todos.length,
      },
    );
  }

  void _onDeleted(HomeTodoDeleted event, Emitter<HomeTodoState> emit) {
    final todos = deleteTodoUseCase(event.id);
    emit(state.copyWith(todos: todos));

    HarnessLogger.event(
      'flow.home_todolist.task_deleted',
      fields: {'task_id': event.id, 'task_count': todos.length},
    );
  }
}
