import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/harness/harness_logger.dart';
import '../../../../core/injection/injection.dart';
import '../../../../core/resources/images.dart';
import '../../domain/entities/user.dart';
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
            listener: _handleStateChange,
            builder: (context, state) {
              switch (state) {
                case UserLoading():
                  return Center(
                    child: Semantics(
                      identifier: 'user.loading',
                      child: const CircularProgressIndicator(),
                    ),
                  );
                case UserLoaded(:final user):
                  return _UserLoadedView(
                    user: user,
                    onRequestUser: (userId) => _requestUser(context, userId),
                  );
                case UserError(:final message):
                  return _UserErrorView(
                    message: message,
                    onRetry: () => _requestUser(context, '1'),
                  );
                case UserInitial():
                default:
                  return const Center(
                    child: Text('Press a button to load user'),
                  );
              }
            },
          ),
        ),
      ),
    );
  }

  void _handleStateChange(BuildContext context, UserState state) {
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
        HarnessLogger.flowFailed('user_profile', fields: {'message': message});
      case UserInitial():
        HarnessLogger.event('flow.user_profile.initial');
    }
  }

  void _requestUser(BuildContext context, String userId) {
    HarnessLogger.event(
      'flow.user_profile.switch_user.requested',
      fields: {'user_id': userId},
    );
    context.read<UserBloc>().add(LoadUserEvent(userId));
  }
}

class _UserLoadedView extends StatelessWidget {
  const _UserLoadedView({required this.user, required this.onRequestUser});

  final User user;
  final ValueChanged<String> onRequestUser;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _UserCard(user: user),
          const SizedBox(height: 24),
          const Text(
            'Load Different Users:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final id in const ['1', '2', '3'])
                Semantics(
                  identifier: 'user.load_user_$id',
                  child: ElevatedButton(
                    onPressed: () => onRequestUser(id),
                    child: Text('User $id'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'user.card',
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                    errorBuilder: (_, _, _) => ColoredBox(
                      color: Colors.grey[300]!,
                      child: const SizedBox(
                        width: 100,
                        height: 100,
                        child: Icon(Icons.person, size: 50, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                identifier: 'user.id',
                child: Text(
                  'ID: ${user.id}',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                identifier: 'user.name',
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
                identifier: 'user.email',
                child: Text(
                  'Email: ${user.email}',
                  style: const TextStyle(fontSize: 16, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserErrorView extends StatelessWidget {
  const _UserErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 60),
          const SizedBox(height: 16),
          Text(
            'Error: $message',
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: Semantics(
              identifier: 'user.retry',
              child: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }
}
