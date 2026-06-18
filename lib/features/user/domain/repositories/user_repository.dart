import '../entities/user.dart';

/// Repository interface for user data operations
abstract class UserRepository {
  /// Fetches a user by their ID
  ///
  /// Throws [ApiException] if the request fails
  /// Returns a [User] entity on success
  Future<User> getUser(String userId);
}
