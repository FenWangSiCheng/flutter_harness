import 'package:flutter_foundations/features/home/domain/entities/todo.dart';
import 'package:flutter_foundations/features/home/presentation/bloc/home_todo_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeTodoState', () {
    test('derives counts and submit availability', () {
      const state = HomeTodoState(
        draft: 'Buy milk',
        todos: [
          Todo(id: 1, title: 'Buy milk', completed: true),
          Todo(id: 2, title: 'Walk'),
        ],
      );

      expect(state.completedCount, 1);
      expect(state.activeCount, 1);
      expect(state.canSubmit, isTrue);
    });

    test('copyWith preserves omitted values', () {
      const state = HomeTodoState(draft: 'Buy milk');

      expect(state.copyWith().draft, 'Buy milk');
      expect(state.copyWith(draft: '').canSubmit, isFalse);
    });
  });
}
