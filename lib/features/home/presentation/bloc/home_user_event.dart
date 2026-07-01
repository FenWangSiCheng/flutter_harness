import 'package:equatable/equatable.dart';

abstract class HomeUserEvent extends Equatable {
  const HomeUserEvent();

  @override
  List<Object> get props => [];
}

class LoadHomeUser extends HomeUserEvent {
  final String userId;

  const LoadHomeUser(this.userId);

  @override
  List<Object> get props => [userId];
}
