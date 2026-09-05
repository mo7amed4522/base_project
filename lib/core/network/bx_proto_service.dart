/// Base class for all gRPC service wrappers in the application.
///
/// Subclasses receive a [channel] (typically [BxGrpcChannel.instance.channel])
/// and a list of [interceptors] (typically [BxGrpcChannel.instance.defaultInterceptors]).
/// Exposes typed methods that wrap generated stub calls. Error handling
/// is centralised: any [GrpcError] from the gRPC layer is caught and
/// re-thrown as a [BxGrpcException] so that callers always see a consistent
/// exception type.
///
/// File: lib/core/network/bx_proto_service.dart
library;

import 'package:base_project/core/network/bx_grpc_channel.dart';
import 'package:grpc/grpc.dart';
import 'package:flutter/foundation.dart';

/// Abstract base that every gRPC service wrapper extends.
///
/// Usage pattern:
/// ```dart
/// class MyService extends BxProtoService {
///   MyService(super.channel, super.interceptors);
///
///   Future<MyResponse> doSomething(MyRequest request) async {
///     return call<MyResponse>(
///       () => _stub.doSomething(request),
///       method: 'MyService/DoSomething',
///     );
///   }
/// }
/// ```
abstract class BxProtoService {
  /// The gRPC channel used to create service stubs.
  final ClientChannel channel;

  /// Interceptors to pass to the service stub constructor.
  final List<ClientInterceptor> interceptors;

  BxProtoService(this.channel, this.interceptors);

  /// Executes [fn] and wraps any [GrpcError] into a [BxGrpcException].
  ///
  /// [method] is only used for debug logging.
  Future<T> call<T>(Future<T> Function() fn, {String method = ''}) async {
    try {
      return await fn();
    } on GrpcError catch (e) {
      debugPrint('❌ gRPC error [$method]: ${e.code} – ${e.message}');
      throw BxGrpcException(
        message: e.message ?? 'gRPC error',
        code: e.code,
      );
    } catch (e) {
      debugPrint('❌ Unexpected gRPC error [$method]: $e');
      rethrow;
    }
  }

  /// Executes a streaming call and wraps errors.
  Stream<T> callStream<T>(Stream<T> Function() fn, {String method = ''}) {
    try {
      return fn();
    } catch (e) {
      debugPrint('❌ gRPC stream error [$method]: $e');
      return Stream.error(e);
    }
  }
}
