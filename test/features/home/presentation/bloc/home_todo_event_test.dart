import 'package:flutter_foundations/features/home/presentation/bloc/home_todo_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeTodoEvent', () {
    test('supports value equality for start events', () {
      expect(const HomeTodoStarted(), equals(const HomeTodoStarted()));
      expect(const HomeTodoStarted(), isA<HomeTodoEvent>());
    });

    test('supports value equality for draft changes', () {
      expect(
        const HomeTodoDraftChanged('Buy milk'),
        equals(const HomeTodoDraftChanged('Buy milk')),
      );
      expect(const HomeTodoDraftChanged('Buy milk'), isA<HomeTodoEvent>());
    });

    test('supports value equality for submissions', () {
      expect(const HomeTodoSubmitted(), equals(const HomeTodoSubmitted()));
      expect(const HomeTodoSubmitted(), isA<HomeTodoEvent>());
    });

    test('supports value equality for completion toggles', () {
      expect(
        const HomeTodoCompletionToggled(id: 1, completed: true),
        equals(const HomeTodoCompletionToggled(id: 1, completed: true)),
      );
      expect(
        const HomeTodoCompletionToggled(id: 1, completed: true),
        isA<HomeTodoEvent>(),
      );
    });

    test('supports value equality for deletes', () {
      expect(const HomeTodoDeleted(1), equals(const HomeTodoDeleted(1)));
      expect(const HomeTodoDeleted(1), isA<HomeTodoEvent>());
    });
  });
}
