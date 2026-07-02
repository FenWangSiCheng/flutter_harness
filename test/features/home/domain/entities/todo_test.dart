import 'package:flutter_foundations/features/home/domain/entities/todo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Todo', () {
    test('supports value equality', () {
      expect(
        const Todo(id: 1, title: 'Buy milk'),
        equals(const Todo(id: 1, title: 'Buy milk')),
      );
      expect(
        const Todo(id: 1, title: 'Buy milk'),
        isNot(equals(const Todo(id: 2, title: 'Buy milk'))),
      );
    });

    test('copyWith updates completion while preserving identity and title', () {
      final todo = const Todo(
        id: 1,
        title: 'Buy milk',
      ).copyWith(completed: true);

      expect(todo, const Todo(id: 1, title: 'Buy milk', completed: true));
    });
  });
}
