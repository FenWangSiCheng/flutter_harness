import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/injection/injection.dart';
import '../../../../core/resources/images.dart';
import '../../../user/domain/usecase/get_user_use_case.dart';
import '../bloc/home_counter_bloc.dart';
import '../bloc/home_counter_event.dart';
import '../bloc/home_counter_state.dart';
import '../bloc/home_user_bloc.dart';
import '../bloc/home_user_event.dart';
import '../bloc/home_user_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => HomeCounterBloc()),
        BlocProvider(
          create: (_) =>
              HomeUserBloc(getIt<GetUserUseCase>())
                ..add(const LoadHomeUser('1')),
        ),
      ],
      child: const _HomePageView(),
    );
  }
}

class _HomePageView extends StatelessWidget {
  const _HomePageView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 32),
        children: [
          const _HomeUserSection(),
          const SizedBox(height: 32),
          const _HomeCounterSection(),
        ],
      ),
    );
  }
}

class _HomeUserSection extends StatelessWidget {
  const _HomeUserSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeUserBloc, HomeUserState>(
      builder: (context, state) {
        if (state is HomeUserLoading) {
          return Center(
            child: Semantics(
              identifier: 'home.user.loading',
              child: const CircularProgressIndicator(),
            ),
          );
        }

        if (state is HomeUserLoaded) {
          final user = state.user;
          return Semantics(
            identifier: 'home.user.card',
            child: Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Semantics(
                          identifier: 'home.user.avatar',
                          child: Image.asset(
                            Images.userAvatar,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Semantics(
                      identifier: 'home.user.name',
                      child: Text(
                        'Name: ${user.name}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      identifier: 'home.user.email',
                      child: Text(
                        'Email: ${user.email}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (state is HomeUserError) {
          return Center(
            child: Column(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text(
                  state.message,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // HomeUserInitial
        return const SizedBox.shrink();
      },
    );
  }
}

class _HomeCounterSection extends StatelessWidget {
  const _HomeCounterSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCounterBloc, HomeCounterState>(
      builder: (context, state) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Semantics(
                identifier: 'home.counter.value',
                child: Text(
                  'Steps: ${state.steps}',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Semantics(
                    identifier: 'home.counter.decrement',
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<HomeCounterBloc>().add(
                          const DecrementHomeCounter(),
                        );
                      },
                      child: const Text('-1'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Semantics(
                    identifier: 'home.counter.increment',
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<HomeCounterBloc>().add(
                          const IncrementHomeCounter(),
                        );
                      },
                      child: const Text('+1'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Semantics(
                    identifier: 'home.counter.reset',
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<HomeCounterBloc>().add(
                          const ResetHomeCounter(),
                        );
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
