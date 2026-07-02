import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_foundations/core/harness/harness_logger.dart';
import 'package:flutter_foundations/features/home/data/datasource/todo_local_data_source.dart';
import 'package:flutter_foundations/features/home/data/repositories/todo_repository_impl.dart';
import 'package:flutter_foundations/features/home/domain/entities/todo.dart';
import 'package:flutter_foundations/features/home/domain/usecase/add_todo_use_case.dart';
import 'package:flutter_foundations/features/home/domain/usecase/delete_todo_use_case.dart';
import 'package:flutter_foundations/features/home/domain/usecase/get_todos_use_case.dart';
import 'package:flutter_foundations/features/home/domain/usecase/toggle_todo_use_case.dart';
import 'package:flutter_foundations/features/home/presentation/bloc/home_todo_bloc.dart';
import 'package:flutter_foundations/features/home/presentation/bloc/home_todo_event.dart';
import 'package:flutter_foundations/features/home/presentation/bloc/home_todo_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  HomeTodoBloc buildBloc() {
    final repository = TodoRepositoryImpl(InMemoryTodoLocalDataSource());
    return HomeTodoBloc(
      getTodosUseCase: GetTodosUseCase(repository),
      addTodoUseCase: AddTodoUseCase(repository),
      toggleTodoUseCase: ToggleTodoUseCase(repository),
      deleteTodoUseCase: DeleteTodoUseCase(repository),
    );
  }

  setUp(() {
    HarnessLogger.configure(enabled: false);
  });

  tearDown(HarnessLogger.reset);

  group('HomeTodoBloc', () {
    test('initial state is empty', () {
      final bloc = buildBloc();

      expect(bloc.state, const HomeTodoState());

      bloc.close();
    });

    blocTest<HomeTodoBloc, HomeTodoState>(
      'loads existing todos on start',
      build: buildBloc,
      act: (bloc) => bloc.add(const HomeTodoStarted()),
      expect: () => [const HomeTodoState()],
    );

    blocTest<HomeTodoBloc, HomeTodoState>(
      'tracks draft changes',
      build: buildBloc,
      act: (bloc) => bloc.add(const HomeTodoDraftChanged('Buy milk')),
      expect: () => [const HomeTodoState(draft: 'Buy milk')],
    );

    blocTest<HomeTodoBloc, HomeTodoState>(
      'ignores empty submissions',
      build: buildBloc,
      act: (bloc) => bloc.add(const HomeTodoSubmitted()),
      expect: () => <HomeTodoState>[],
    );

    blocTest<HomeTodoBloc, HomeTodoState>(
      'adds a todo and clears the draft',
      build: buildBloc,
      act: (bloc) {
        bloc
          ..add(const HomeTodoDraftChanged('  Buy milk  '))
          ..add(const HomeTodoSubmitted());
      },
      expect: () => [
        const HomeTodoState(draft: '  Buy milk  '),
        const HomeTodoState(todos: [Todo(id: 1, title: 'Buy milk')]),
      ],
    );

    blocTest<HomeTodoBloc, HomeTodoState>(
      'toggles completion',
      build: buildBloc,
      act: (bloc) {
        bloc
          ..add(const HomeTodoDraftChanged('Buy milk'))
          ..add(const HomeTodoSubmitted())
          ..add(const HomeTodoCompletionToggled(id: 1, completed: true));
      },
      expect: () => [
        const HomeTodoState(draft: 'Buy milk'),
        const HomeTodoState(todos: [Todo(id: 1, title: 'Buy milk')]),
        const HomeTodoState(
          todos: [Todo(id: 1, title: 'Buy milk', completed: true)],
        ),
      ],
    );

    blocTest<HomeTodoBloc, HomeTodoState>(
      'deletes todos',
      build: buildBloc,
      act: (bloc) {
        bloc
          ..add(const HomeTodoDraftChanged('Buy milk'))
          ..add(const HomeTodoSubmitted())
          ..add(const HomeTodoDeleted(1));
      },
      expect: () => [
        const HomeTodoState(draft: 'Buy milk'),
        const HomeTodoState(todos: [Todo(id: 1, title: 'Buy milk')]),
        const HomeTodoState(),
      ],
    );
  });
}
