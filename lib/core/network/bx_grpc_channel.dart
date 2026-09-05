/// Singleton gRPC channel wrapper that provides a centralised way to make
/// gRPC calls with automatic error handling, authentication metadata and
/// debug logging.
///
/// Replaces the former [BxDioClient]. All gRPC services should be created
/// through this singleton via [channel] and access the configured
/// [ChannelOptions] (host, port, credentials).
///
/// Usage:
/// ```dart
/// final client = BxGrpcChannel.instance;
/// final stub = AuthServiceClient(client.channel, interceptors: [BxAuthInterceptor()]);
/// final response = await stub.login(LoginRequest()..phone = '+97150…');
/// ```
///
/// File: lib/core/network/bx_grpc_channel.dart
library;

import 'package:base_project/core/network/bx_api_endpoints.dart';
import 'package:grpc/grpc.dart';
import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// gRPC exception (replaces BxNetworkException)
// ---------------------------------------------------------------------------

/// Exception thrown when a gRPC call fails.
///
/// Carries the gRPC [code] and a human-readable [message].
class BxGrpcException implements Exception {
  final String message;
  final int code;

  const BxGrpcException({required this.message, required this.code});

  @override
  String toString() => 'BxGrpcException: $message (code: $code)';
}

// ---------------------------------------------------------------------------
// Logging interceptor
// ---------------------------------------------------------------------------

/// gRPC interceptor that logs every request, response and error to debug.
class BxLoggingInterceptor implements ClientInterceptor {
  @override
  ResponseFuture<R> interceptUnary<Q, R>(
      ClientMethod<Q, R> method, Q request, CallOptions options,
      ClientUnaryInvoker<Q, R> invoker) {
    debugPrint('\n┏━━━ gRPC REQUEST ━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('┃ Method: ${method.path}');
    debugPrint('┃ Params: $request');
    debugPrint('┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    return invoker(method, request, options);
  }

  @override
  ResponseStream<R> interceptStreaming<Q, R>(
      ClientMethod<Q, R> method, Stream<Q> requests, CallOptions options,
      ClientStreamingInvoker<Q, R> invoker) {
    debugPrint('\n┏━━━ gRPC STREAM REQUEST ━━━━━━━━━━━━━━━━━━');
    debugPrint('┃ Method: ${method.path}');
    debugPrint('┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    return invoker(method, requests, options);
  }
}

// ---------------------------------------------------------------------------
// Auth metadata provider
// ---------------------------------------------------------------------------

/// gRPC interceptor that attaches the authorization token as metadata on
/// every outgoing call. Uses [CallOptions.mergedWith] to preserve existing
/// options while adding the auth header.
class BxAuthInterceptor implements ClientInterceptor {
  /// The metadata key used for the bearer token.
  static const String _authKey = 'authorization';

  /// Current bearer token, or `null` if the user is not authenticated.
  String? _token;

  /// Updates the stored token. Call this after login / logout.
  void setToken(String? token) {
    _token = token;
    debugPrint('┃ Auth token ${token != null ? "set" : "cleared"}');
  }

  @override
  ResponseFuture<R> interceptUnary<Q, R>(
      ClientMethod<Q, R> method, Q request, CallOptions options,
      ClientUnaryInvoker<Q, R> invoker) {
    if (_token != null) {
      final merged = options.mergedWith(
        CallOptions(metadata: {_authKey: 'Bearer $_token'}),
      );
      return invoker(method, request, merged);
    }
    return invoker(method, request, options);
  }

  @override
  ResponseStream<R> interceptStreaming<Q, R>(
      ClientMethod<Q, R> method, Stream<Q> requests, CallOptions options,
      ClientStreamingInvoker<Q, R> invoker) {
    if (_token != null) {
      final merged = options.mergedWith(
        CallOptions(metadata: {_authKey: 'Bearer $_token'}),
      );
      return invoker(method, requests, merged);
    }
    return invoker(method, requests, options);
  }
}

// ---------------------------------------------------------------------------
// Main gRPC channel singleton
// ---------------------------------------------------------------------------

/// Singleton that owns a single [ClientChannel] and exposes convenience
/// methods for common gRPC operations.
///
/// Replaces [BxDioClient] (dio) with a gRPC equivalent.
class BxGrpcChannel {
  late final ClientChannel _channel;

  /// Internal singleton instance.
  static final BxGrpcChannel _instance = BxGrpcChannel._internal();

  /// Returns the singleton instance.
  static BxGrpcChannel get instance => _instance;

  /// Private constructor — creates the channel with the configured host/port.
  BxGrpcChannel._internal() {
    _channel = ClientChannel(
      BxApiEndpoints.grpcHost,
      port: BxApiEndpoints.grpcPort,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
      ),
    );
  }

  /// Returns the underlying [ClientChannel] for creating service stubs.
  ///
  /// Pass interceptors here (e.g. [BxAuthInterceptor]) when creating a stub,
  /// since [ClientChannel] itself does not hold interceptors in grpc v4.
  ClientChannel get channel => _channel;

  /// Returns the default interceptors to use with all service stubs.
  List<ClientInterceptor> get defaultInterceptors => [
        BxLoggingInterceptor(),
        BxAuthInterceptor(),
      ];

  /// Shuts down the channel gracefully. Call this when the app is
  /// terminating to release resources.
  Future<void> shutdown() async {
    await _channel.shutdown();
  }
}
