import '../entities/user.dart';
import '../repositories/user_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetUserUseCase {
  final UserRepository repository;

  GetUserUseCase(this.repository);

  Future<User> call(String userId) {
    return repository.getUser(userId);
  }
}
