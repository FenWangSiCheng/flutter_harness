import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasource/remote_datasource.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  final RemoteDataSource remoteDataSource;

  UserRepositoryImpl(this.remoteDataSource);

  @override
  Future<User> getUser(String userId) async {
    final userModel = await remoteDataSource.getUser(userId);
    return userModel.toEntity();
  }
}
