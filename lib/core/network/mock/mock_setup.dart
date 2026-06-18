import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'mock_responses.dart';

class MockSetup {
  static Future<void> configureMockAdapter(DioAdapter dioAdapter) async {
    // Pre-load mock data to avoid race conditions
    await MockResponses.loadUserList();

    // Mock for user list
    dioAdapter.onGet('/users', (server) async {
      final users = await MockResponses.loadUserList();
      return server.reply(200, users, delay: const Duration(milliseconds: 300));
    });

    // Mock for specific users
    dioAdapter.onGet('/users/1', (server) async {
      final userData = await MockResponses.getUserById('1');
      return server.reply(
        200,
        userData,
        delay: const Duration(milliseconds: 300),
      );
    });

    dioAdapter.onGet('/users/2', (server) async {
      final userData = await MockResponses.getUserById('2');
      return server.reply(
        200,
        userData,
        delay: const Duration(milliseconds: 300),
      );
    });

    dioAdapter.onGet('/users/3', (server) async {
      final userData = await MockResponses.getUserById('3');
      return server.reply(
        200,
        userData,
        delay: const Duration(milliseconds: 300),
      );
    });

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
