import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_foundations/core/network/mock/mock_responses.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MockResponses', () {
    test('loadUserList returns bundled users when asset exists', () async {
      final users = await MockResponses.loadUserList();
      expect(users, isA<List<Map<String, dynamic>>>());
      expect(users, isNotEmpty);
      expect(users.first.keys, containsAll(['id', 'name', 'email']));
    });

    test('getUserById returns null for unknown user', () async {
      final user = await MockResponses.getUserById('nonexistent-id');
      expect(user, isNull);
    });
  });
}
