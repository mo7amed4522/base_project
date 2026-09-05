/// Centralised definition of the application's server host, port and all
/// gRPC service endpoint paths.
///
/// Replaces [BxApiEndpoints] which previously held HTTP URL paths.
///
/// File: lib/core/network/bx_api_endpoints.dart
library;

/// Host and port configuration for the gRPC server.
///
/// In production replace [grpcHost] and [grpcPort] with the real server
/// address. For local development use `localhost` / `50051`.
class BxAppConfig {
  /// gRPC server host (default: localhost for local development).
  static const String grpcHost = 'sys.optilinksys.com';

  /// gRPC server port (default: 50051).
  static const int grpcPort = 50051;
}

/// gRPC service name constants.
///
/// All service RPCs are discovered from the generated `.pbgrpc.dart` files.
/// This class exists only to hold human-readable service identifiers.
class BxApiEndpoints {
  BxApiEndpoints._();

  /// The gRPC host address.
  static String get grpcHost => BxAppConfig.grpcHost;

  /// The gRPC port number.
  static int get grpcPort => BxAppConfig.grpcPort;

  // -----------------------------------------------------------------------
  // AuthService
  // -----------------------------------------------------------------------

  /// Full gRPC method path for [AuthService.login].
  static const String authLogin = '/bx.AuthService/Login';
}
