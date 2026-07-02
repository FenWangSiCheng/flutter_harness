import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'package:flutter_foundations/core/network/mock/mock_setup.dart';

import '../../../helpers/mock_asset_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const mockUsersJson =
      '[{"id":"1","name":"Alice"},{"id":"2","name":"Bob"},{"id":"3","name":"Eve"}]';

  late Dio dio;
  late DioAdapter adapter;

  setUp(() {
    clearMockAssetBundle();
    setMockAssetBundle({'assets/mock/users.json': mockUsersJson});

    dio = Dio(BaseOptions(baseUrl: 'https://mock.api'));
    adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;
  });

  tearDown(() {
    clearMockAssetBundle();
  });

  test('configureMockAdapter registers handlers for user endpoints', () async {
    await MockSetup.configureMockAdapter(adapter);

    final listResponse = await dio.get('/users');
    expect(listResponse.statusCode, equals(200));
    expect(listResponse.data, isA<List<dynamic>>());
    expect(listResponse.data.length, equals(3));

    final userResponse = await dio.get('/users/2');
    expect(userResponse.statusCode, equals(200));
    expect(userResponse.data['id'], equals('2'));

    final missingResponse = await dio.get(
      '/users/404',
      options: Options(validateStatus: (_) => true),
    );

    expect(missingResponse.statusCode, equals(404));
    expect(missingResponse.data['error'], equals('User not found'));
  });
}
