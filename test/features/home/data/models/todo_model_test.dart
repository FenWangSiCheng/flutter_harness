import 'package:flutter_foundations/features/home/data/models/todo_model.dart';
import 'package:flutter_foundations/features/home/domain/entities/todo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TodoModel', () {
    test('maps from and to domain entity', () {
      final model = TodoModel.fromEntity(
        const Todo(id: 1, title: 'Buy milk', completed: true),
      );

      expect(model.id, 1);
      expect(model.title, 'Buy milk');
      expect(model.completed, isTrue);
      expect(
        model.toEntity(),
        const Todo(id: 1, title: 'Buy milk', completed: true),
      );
    });

    test('copyWith updates completion', () {
      final model = const TodoModel(
        id: 1,
        title: 'Buy milk',
        completed: false,
      ).copyWith(completed: true);

      expect(model.completed, isTrue);
      expect(model.id, 1);
      expect(model.title, 'Buy milk');
    });
  });
}
