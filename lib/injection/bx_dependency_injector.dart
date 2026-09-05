/// Central dependency injection container based on [GetIt].
///
/// This singleton initialises and wires together all core services,
/// data sources, repositories and use cases. The [setup] method must
/// be called once during app startup (e.g. in `main()`) before any
/// other part of the application attempts to retrieve dependencies.
///
/// File: lib/injection/bx_dependency_injector.dart
library;

import 'package:base_project/core/network/bx_grpc_channel.dart';
import 'package:base_project/core/network/services/bx_auth_service.dart';
import 'package:base_project/data/data_source/local/bx_shared_preferences_datasource.dart';
import 'package:base_project/data/data_source/remote/bx_system_remote_data_source.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Registers all application dependencies.
///
/// Must be called once before the first [get] call. It initialises:
/// - Core: [BxGrpcChannel] (singleton gRPC channel, replaces BxDioClient)
/// - SharedPreferences (singleton, obtained asynchronously)
/// - gRPC services ([BxAuthService])
/// - Remote data sources ([BxSystemRemoteDataSource])
/// - Local data sources ([BxSharedPreferencesDataSource])
/// - All domain repositories and use cases as they are added
class BxDependencyInjector {
  static final BxDependencyInjector _singleton = BxDependencyInjector._internal();
  static final GetIt _getIt = GetIt.instance;

  factory BxDependencyInjector() => _singleton;

  BxDependencyInjector._internal();

  /// Returns the singleton instance.
  static BxDependencyInjector get instance => _singleton;

  /// Registers all application dependencies.
  Future<void> setup() async {
    // Core – gRPC channel (replaces BxDioClient)
    _getIt.registerLazySingleton<BxGrpcChannel>(() => BxGrpcChannel.instance);

    // gRPC services
    _getIt.registerLazySingleton<BxAuthService>(
      () => BxAuthService(
        _getIt<BxGrpcChannel>().channel,
        _getIt<BxGrpcChannel>().defaultInterceptors,
      ),
    );

    // SharedPreferences
    final sharedPreferences = await SharedPreferences.getInstance();
    _getIt.registerSingleton<SharedPreferences>(sharedPreferences);

    // Data Sources
    _getIt.registerLazySingleton<BxSystemRemoteDataSource>(
      () => BxSystemRemoteDataSourceImpl(authService: _getIt()),
    );
    _getIt.registerLazySingleton<BxSharedPreferencesDataSource>(
      () => BxSharedPreferencesDataSourceImpl(_getIt()),
    );

    // Repositories — register here as they are created
    // UseCases — register here as they are created
  }

  /// Retrieves a previously registered dependency of type [T].
  T get<T extends Object>() => _getIt.get<T>();
}
