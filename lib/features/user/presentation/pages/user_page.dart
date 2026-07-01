import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/harness/harness_logger.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/resources/images.dart';
import '../bloc/user_bloc.dart';
import '../bloc/user_event.dart';
import '../bloc/user_state.dart';

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<UserBloc>()..add(const LoadUserEvent('1')),
      child: Semantics(
        identifier: 'user.page',
        child: Scaffold(
          appBar: AppBar(
            title: const Text('User Info'),
            backgroundColor: Colors.blue,
          ),
          body: BlocConsumer<UserBloc, UserState>(
            listener: (context, state) {
              switch (state) {
                case UserLoading():
                  HarnessLogger.event('flow.user_profile.loading');
                case UserLoaded(:final user):
                  HarnessLogger.event(
                    'flow.user_profile.user_loaded',
                    fields: {'user_id': user.id, 'email': user.email},
                  );
                  HarnessLogger.flowSucceeded(
                    'user_profile',
                    fields: {'user_id': user.id, 'email': user.email},
                  );
                case UserError(:final message):
                  HarnessLogger.event(
                    'flow.user_profile.error',
                    fields: {'message': message},
                  );
                  HarnessLogger.flowFailed(
                    'user_profile',
                    fields: {'message': message},
                  );
                case UserInitial():
                  HarnessLogger.event('flow.user_profile.initial');
              }
            },
            builder: (context, state) {
              if (state is UserLoading) {
                return Center(
                  child: Semantics(
                    identifier: 'user.loading',
                    child: const CircularProgressIndicator(),
                  ),
                );
              } else if (state is UserLoaded) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        identifier: 'user.card',
                        child: Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(50),
                                    child: Image.asset(
                                      Images.userAvatar,
                                      semanticLabel: 'user.avatar',
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              width: 100,
                                              height: 100,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[300],
                                                borderRadius:
                                                    BorderRadius.circular(50),
                                              ),
                                              child: const Icon(
                                                Icons.person,
                                                size: 50,
                                                color: Colors.grey,
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Semantics(
                                  identifier: 'user.id',
                                  child: Text(
                                    'ID: ${state.user.id}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Semantics(
                                  identifier: 'user.name',
                                  child: Text(
                                    'Name: ${state.user.name}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Semantics(
                                  identifier: 'user.email',
                                  child: Text(
                                    'Email: ${state.user.email}',
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
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Load Different Users:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Semantics(
                            identifier: 'user.load_user_1',
                            child: ElevatedButton(
                              onPressed: () {
                                _requestUser(context, '1');
                              },
                              child: const Text('User 1'),
                            ),
                          ),
                          Semantics(
                            identifier: 'user.load_user_2',
                            child: ElevatedButton(
                              onPressed: () {
                                _requestUser(context, '2');
                              },
                              child: const Text('User 2'),
                            ),
                          ),
                          Semantics(
                            identifier: 'user.load_user_3',
                            child: ElevatedButton(
                              onPressed: () {
                                _requestUser(context, '3');
                              },
                              child: const Text('User 3'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              } else if (state is UserError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 60,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${state.message}',
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          _requestUser(context, '1');
                        },
                        child: Semantics(
                          identifier: 'user.retry',
                          child: const Text('Retry'),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const Center(child: Text('Press a button to load user'));
            },
          ),
        ),
      ),
    );
  }

  void _requestUser(BuildContext context, String userId) {
    HarnessLogger.event(
      'flow.user_profile.switch_user.requested',
      fields: {'user_id': userId},
    );
    context.read<UserBloc>().add(LoadUserEvent(userId));
  }
}
