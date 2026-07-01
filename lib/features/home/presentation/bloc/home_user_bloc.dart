import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../user/domain/usecase/get_user_use_case.dart';
import '../../../../core/network/error/exception.dart';
import 'home_user_event.dart';
import 'home_user_state.dart';

class HomeUserBloc extends Bloc<HomeUserEvent, HomeUserState> {
  final GetUserUseCase _getUserUseCase;

  HomeUserBloc(this._getUserUseCase) : super(HomeUserInitial()) {
    on<LoadHomeUser>(_onLoadUser);
  }

  Future<void> _onLoadUser(
    LoadHomeUser event,
    Emitter<HomeUserState> emit,
  ) async {
    emit(HomeUserLoading());
    try {
      final user = await _getUserUseCase(event.userId);
      emit(HomeUserLoaded(user));
    } on ApiException catch (e) {
      emit(HomeUserError(e.message));
    } catch (e) {
      emit(HomeUserError('Failed to load user. Please try again.'));
    }
  }
}
