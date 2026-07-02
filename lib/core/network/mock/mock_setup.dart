import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'mock_responses.dart';

class MockSetup {
  static Future<void> configureMockAdapter(DioAdapter dioAdapter) async {
    // Pre-load mock data to avoid race conditions
    await MockResponses.loadUserList();

    const mockDelay = Duration(milliseconds: 300);

    // Mock for user list
    dioAdapter.onGet('/users', (server) async {
      final users = await MockResponses.loadUserList();
      return server.reply(200, users, delay: mockDelay);
    });

    // Mock for specific users
    for (final userId in ['1', '2', '3']) {
      dioAdapter.onGet('/users/$userId', (server) async {
        final userData = await MockResponses.getUserById(userId);
        return server.reply(200, userData, delay: mockDelay);
      });
    }

    // Mock for non-existent user
    dioAdapter.onGet(
      '/users/404',
      (server) => server.reply(404, {
        'error': 'User not found',
        'message': 'The requested user does not exist',
      }, delay: const Duration(milliseconds: 200)),
    );
  }
}
