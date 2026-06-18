import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_foundations/features/user/data/datasource/remote_datasource.dart';
import 'package:flutter_foundations/features/user/data/models/user_model.dart';
import 'package:flutter_foundations/core/network/error/exception.dart';

import 'remote_datasource_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  late RemoteDataSourceImpl dataSource;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    dataSource = RemoteDataSourceImpl(mockDio);
  });

  group('RemoteDataSource - getUser', () {
    const tUserId = '1';
    const tUserModel = UserModel(
      id: '1',
      name: 'John Doe',
      email: 'john@example.com',
    );

    test('should perform a GET request to /users/:userId', () async {
      when(mockDio.get(any)).thenAnswer(
        (_) async => Response(
          data: {'id': '1', 'name': 'John Doe', 'email': 'john@example.com'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/users/$tUserId'),
        ),
      );

      await dataSource.getUser(tUserId);

      verify(mockDio.get('/users/$tUserId')).called(1);
    });

    test('should return UserModel when response is successful (200)', () async {
      when(mockDio.get(any)).thenAnswer(
        (_) async => Response(
          data: {'id': '1', 'name': 'John Doe', 'email': 'john@example.com'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/users/$tUserId'),
        ),
      );

      final result = await dataSource.getUser(tUserId);

      expect(result, equals(tUserModel));
    });

    test('should throw ApiException when DioException occurs', () async {
      when(mockDio.get(any)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/users/$tUserId'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      expect(() => dataSource.getUser(tUserId), throwsA(isA<ApiException>()));
    });

    test(
      'should throw ApiException with proper message on network error',
      () async {
        when(mockDio.get(any)).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/users/$tUserId'),
            type: DioExceptionType.receiveTimeout,
          ),
        );

        try {
          await dataSource.getUser(tUserId);
          fail('Should have thrown ApiException');
        } catch (e) {
          expect(e, isA<ApiException>());
          expect((e as ApiException).message, equals('Receive timeout'));
        }
      },
    );
  });
}
