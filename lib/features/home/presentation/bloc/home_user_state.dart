import 'package:equatable/equatable.dart';
import '../../../user/domain/entities/user.dart';

abstract class HomeUserState extends Equatable {
  const HomeUserState();

  @override
  List<Object> get props => [];
}

class HomeUserInitial extends HomeUserState {}

class HomeUserLoading extends HomeUserState {}

class HomeUserLoaded extends HomeUserState {
  final User user;

  const HomeUserLoaded(this.user);

  @override
  List<Object> get props => [user];
}

class HomeUserError extends HomeUserState {
  final String message;

  const HomeUserError(this.message);

  @override
  List<Object> get props => [message];
}
