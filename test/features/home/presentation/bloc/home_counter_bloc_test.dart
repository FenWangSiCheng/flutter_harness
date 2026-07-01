import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_foundations/features/home/presentation/bloc/home_counter_bloc.dart';
import 'package:flutter_foundations/features/home/presentation/bloc/home_counter_event.dart';
import 'package:flutter_foundations/features/home/presentation/bloc/home_counter_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeCounterBloc', () {
    test('initial state has zero steps', () async {
      final bloc = HomeCounterBloc();

      expect(bloc.state, equals(const HomeCounterState.initial()));

      await bloc.close();
    });

    blocTest<HomeCounterBloc, HomeCounterState>(
      'emits one step when incremented',
      build: HomeCounterBloc.new,
      act: (bloc) => bloc.add(const IncrementHomeCounter()),
      expect: () => [const HomeCounterState(steps: 1)],
    );

    blocTest<HomeCounterBloc, HomeCounterState>(
      'increments from the current step count',
      build: HomeCounterBloc.new,
      act: (bloc) {
        bloc.add(const IncrementHomeCounter());
        bloc.add(const IncrementHomeCounter());
      },
      expect: () => [
        const HomeCounterState(steps: 1),
        const HomeCounterState(steps: 2),
      ],
    );

    blocTest<HomeCounterBloc, HomeCounterState>(
      'resets steps to zero',
      build: HomeCounterBloc.new,
      seed: () => const HomeCounterState(steps: 2),
      act: (bloc) => bloc.add(const ResetHomeCounter()),
      expect: () => [const HomeCounterState.initial()],
    );

    blocTest<HomeCounterBloc, HomeCounterState>(
      'emits decremented step when above zero',
      build: HomeCounterBloc.new,
      seed: () => const HomeCounterState(steps: 2),
      act: (bloc) => bloc.add(const DecrementHomeCounter()),
      expect: () => [const HomeCounterState(steps: 1)],
    );

    blocTest<HomeCounterBloc, HomeCounterState>(
      'does not emit when decrementing at zero',
      build: HomeCounterBloc.new,
      act: (bloc) => bloc.add(const DecrementHomeCounter()),
      expect: () => [],
    );

    blocTest<HomeCounterBloc, HomeCounterState>(
      'decrements from 1 to 0',
      build: HomeCounterBloc.new,
      seed: () => const HomeCounterState(steps: 1),
      act: (bloc) => bloc.add(const DecrementHomeCounter()),
      expect: () => [const HomeCounterState(steps: 0)],
    );
  });
}
