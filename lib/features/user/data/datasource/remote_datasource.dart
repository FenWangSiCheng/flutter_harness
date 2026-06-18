import 'package:dio/dio.dart';
import '../models/user_model.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/network/error/dio_error_handler.dart';

abstract class RemoteDataSource {
  Future<UserModel> getUser(String userId);
}

@Injectable(as: RemoteDataSource)
class RemoteDataSourceImpl implements RemoteDataSource {
  final Dio dio;

  RemoteDataSourceImpl(this.dio);

  @override
  Future<UserModel> getUser(String userId) async {
    try {
      final response = await dio.get('/users/$userId');
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw handleError(e);
    }
  }
}
