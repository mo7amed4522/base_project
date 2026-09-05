/// Abstraction for all remote (network) data operations.
///
/// Replaces the former [BxSystemRemoteDataSource] which was tied to the
/// Dio HTTP client. Every method now calls a gRPC service instead and
/// returns strongly-typed result objects.
///
/// File: lib/data/data_source/remote/bx_system_remote_data_source.dart
library;

import 'package:base_project/core/network/services/bx_auth_service.dart';

/// Contract for all remote API calls.
///
/// Each method returns a typed result; errors are propagated as
/// [BxGrpcException] instances thrown by the underlying service.
abstract class BxSystemRemoteDataSource {
  /// Authenticates the user with [phone] and [otp].
  ///
  /// Returns a [LoginResult] on success.
  Future<LoginResult> login({required String phone, required String otp});
}

/// Concrete implementation that delegates to [BxAuthService].
class BxSystemRemoteDataSourceImpl implements BxSystemRemoteDataSource {
  final BxAuthService authService;

  BxSystemRemoteDataSourceImpl({required this.authService});

  @override
  Future<LoginResult> login({required String phone, required String otp}) {
    return authService.login(phone: phone, otp: otp);
  }
}
