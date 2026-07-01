import 'package:equatable/equatable.dart';

abstract class HomeCounterEvent extends Equatable {
  const HomeCounterEvent();

  @override
  List<Object> get props => [];
}

class IncrementHomeCounter extends HomeCounterEvent {
  const IncrementHomeCounter();
}

class ResetHomeCounter extends HomeCounterEvent {
  const ResetHomeCounter();
}

class DecrementHomeCounter extends HomeCounterEvent {
  const DecrementHomeCounter();
}
