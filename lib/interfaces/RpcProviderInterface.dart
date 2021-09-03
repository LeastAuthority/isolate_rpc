import '../isolate_rpc.dart';

typedef dynamic RpcHandler<T, U> (T payload);
typedef T SignalHandler<T>(T payload);

abstract class RpcProviderInterface {
  void dispatch(dynamic message);

  Future<U> rpc<T, U>({String id, T? payload, List<dynamic>? transfer});

  RpcProviderInterface signal<T, U>(
      {String? id, T? payload, List<dynamic>? transfer});

  RpcProviderInterface registerRpcHandler<T, U>(
      {String id, RpcHandler<T, U> handler});

  RpcProviderInterface registerSignalHandler<T>(
      {String id, SignalHandler<T> handler});

  RpcProviderInterface deregisterRpcHandler<T, U>(
      {String id, RpcHandler<T, U> handler});

  RpcProviderInterface deregisterSignalHandler<T>(
      {String id, SignalHandler<T> handler});
}