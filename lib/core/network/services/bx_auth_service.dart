/// Service wrapper for the gRPC [AuthService].
///
/// Wraps the generated [AuthServiceClient] stub and exposes strongly-typed
/// methods. The generated stub lives in [generated/auth.pbgrpc.dart].
///
/// To regenerate stubs after editing `protos/auth.proto`, run:
/// ```bash
/// make proto
/// ```
///
/// File: lib/core/network/services/bx_auth_service.dart
library;

import 'package:base_project/core/network/bx_grpc_channel.dart';
import 'package:base_project/core/network/bx_proto_service.dart';
import '../generated/auth.pbgrpc.dart';

/// High-level wrapper around the generated [AuthServiceClient].
///
/// All methods forward to the generated stub and convert gRPC errors to
/// [BxGrpcException] via [BxProtoService.call].
class BxAuthService extends BxProtoService {
  late final AuthServiceClient _stub;

  BxAuthService(super.channel, super.interceptors) {
    _stub = AuthServiceClient(channel, interceptors: interceptors);
  }

  /// Authenticates a user with [phone] and [otp].
  ///
  /// Returns a [LoginResult] on success.
  /// Throws [BxGrpcException] on failure.
  Future<LoginResult> login({required String phone, required String otp}) async {
    return call<LoginResult>(
      () async {
        final response = await _stub.login(
          LoginRequest()..phone = phone..otp = otp,
        );
        return LoginResult.fromProto(response);
      },
      method: 'AuthService/Login',
    );
  }
}

/// Container for the data returned by [BxAuthService.login].
///
/// Wraps the generated [LoginResponse] into a plain Dart class so that
/// the domain layer stays decoupled from the generated protobuf code.
class LoginResult {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String name;
  final String email;

  const LoginResult({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.name,
    required this.email,
  });

  /// Creates a [LoginResult] from the generated [LoginResponse].
  factory LoginResult.fromProto(LoginResponse proto) {
    return LoginResult(
      accessToken: proto.accessToken,
      refreshToken: proto.refreshToken,
      userId: proto.userId,
      name: proto.name,
      email: proto.email,
    );
  }
}
