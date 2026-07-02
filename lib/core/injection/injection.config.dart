// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:flutter_foundations/core/config/app_config.dart' as _i531;
import 'package:flutter_foundations/core/injection/injection.dart' as _i379;
import 'package:flutter_foundations/core/network/dio_client.dart' as _i542;
import 'package:flutter_foundations/core/router/app_router.dart' as _i177;
import 'package:flutter_foundations/features/home/data/datasource/todo_local_data_source.dart'
    as _i158;
import 'package:flutter_foundations/features/home/data/repositories/todo_repository_impl.dart'
    as _i190;
import 'package:flutter_foundations/features/home/domain/repositories/todo_repository.dart'
    as _i664;
import 'package:flutter_foundations/features/home/domain/usecase/add_todo_use_case.dart'
    as _i834;
import 'package:flutter_foundations/features/home/domain/usecase/delete_todo_use_case.dart'
    as _i200;
import 'package:flutter_foundations/features/home/domain/usecase/get_todos_use_case.dart'
    as _i716;
import 'package:flutter_foundations/features/home/domain/usecase/toggle_todo_use_case.dart'
    as _i98;
import 'package:flutter_foundations/features/home/presentation/bloc/home_todo_bloc.dart'
    as _i192;
import 'package:flutter_foundations/features/user/data/datasource/remote_datasource.dart'
    as _i653;
import 'package:flutter_foundations/features/user/data/repositories/user_repository_impl.dart'
    as _i44;
import 'package:flutter_foundations/features/user/domain/repositories/user_repository.dart'
    as _i776;
import 'package:flutter_foundations/features/user/domain/usecase/get_user_use_case.dart'
    as _i92;
import 'package:flutter_foundations/features/user/presentation/bloc/user_bloc.dart'
    as _i680;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    gh.singleton<_i531.AppConfig>(() => registerModule.appConfig);
    gh.lazySingleton<_i177.AppRouter>(() => _i177.AppRouter());
    await gh.lazySingletonAsync<_i542.DioClient>(
      () => registerModule.dioClient(gh<_i531.AppConfig>()),
      preResolve: true,
    );
    gh.lazySingleton<_i158.TodoLocalDataSource>(
      () => _i158.InMemoryTodoLocalDataSource(),
    );
    gh.lazySingleton<_i664.TodoRepository>(
      () => _i190.TodoRepositoryImpl(gh<_i158.TodoLocalDataSource>()),
    );
    gh.factory<_i834.AddTodoUseCase>(
      () => _i834.AddTodoUseCase(gh<_i664.TodoRepository>()),
    );
    gh.factory<_i200.DeleteTodoUseCase>(
      () => _i200.DeleteTodoUseCase(gh<_i664.TodoRepository>()),
    );
    gh.factory<_i716.GetTodosUseCase>(
      () => _i716.GetTodosUseCase(gh<_i664.TodoRepository>()),
    );
    gh.factory<_i98.ToggleTodoUseCase>(
      () => _i98.ToggleTodoUseCase(gh<_i664.TodoRepository>()),
    );
    gh.lazySingleton<_i361.Dio>(
      () => registerModule.dio(gh<_i542.DioClient>()),
    );
    gh.factory<_i192.HomeTodoBloc>(
      () => _i192.HomeTodoBloc(
        getTodosUseCase: gh<_i716.GetTodosUseCase>(),
        addTodoUseCase: gh<_i834.AddTodoUseCase>(),
        toggleTodoUseCase: gh<_i98.ToggleTodoUseCase>(),
        deleteTodoUseCase: gh<_i200.DeleteTodoUseCase>(),
      ),
    );
    gh.factory<_i653.RemoteDataSource>(
      () => _i653.RemoteDataSourceImpl(gh<_i361.Dio>()),
    );
    gh.factory<_i776.UserRepository>(
      () => _i44.UserRepositoryImpl(gh<_i653.RemoteDataSource>()),
    );
    gh.factory<_i92.GetUserUseCase>(
      () => _i92.GetUserUseCase(gh<_i776.UserRepository>()),
    );
    gh.factory<_i680.UserBloc>(() => _i680.UserBloc(gh<_i92.GetUserUseCase>()));
    return this;
  }
}

class _$RegisterModule extends _i379.RegisterModule {}
