library isolate_rpc;

// import 'dart:html';

typedef Future<U> RpcHandler<T, U> (T payload);
typedef T SignalHandler<T>(T payload);

typedef Dispatcher =  Function(Message message, List<dynamic>? transfer);

enum MessageType {
  signal,
  rpc,
  internal,
}

abstract class Message {
  MessageType? type;
  String? id;

  int? transactionId;

  dynamic payload;
}


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
// Eventinterface<Error> error
}

class RpcProvider  {
  Dispatcher _dispatch;
  int _rpcTimeout;
  // ErrorEvent error = new ErrorEvent('');

  RpcProvider(dispatch, rpcTimeout)
      : _dispatch = dispatch,
        _rpcTimeout = rpcTimeout;

        dispatch (Message payload) {
          Message message = payload;

          switch (message.type) {
          case MessageType.signal:
          return this._handleSignal(message);

          // case MessageType.rpc:
          // return this._handeRpc(message);
          //
          // case MessageType.internal:
          // return this._handleInternal(message);
          //
          // default:
          // this._raiseError(`invalid message type ${message.type}`);
        }
      }
      void _handleSignal(Message message) {
            // if (!this._signalHandlers[message.id]) {
            // return this._raiseError(`invalid signal ${message.id}`);
            // }
            //
            // this._signalHandlers[message.id].forEach(handler => handler(message.payload));
        }
        registerSignalHandler<T, U>(String id, SignalHandler handler) {
        // if (!this._signalHandlers[id]) {
        // this._signalHandlers[id] = [];
        // }
        //
        // this._signalHandlers[id].push(handler);
        //
        // return this;
        }
       void signal (String id, [payload, transfer]) {
        // this._dispatch({
        // type: RpcProvider.MessageType.signal,
        // id,
        // payload,
        // }, transfer ? transfer : undefined);
        //
        // return this;
        }
        Future<U> rpc<T, U>(String id, [T? payload, List<dynamic>? transfer]) {
            return Future.error('test future error!');

        }
        void unregisterSignalHandler (String id, SignalHandler handler) {
          // if (this._signalHandlers[id]) {
          // this._signalHandlers[id] = this._signalHandlers[id].filter(h => handler !== h);
       // }

        // return this;
        }
        void registerRpcHandler(String id, RpcHandler handler) {
        // if (this._rpcHandlers[id]) {
        // throw new Error(`rpc handler for ${id} already registered`);
        // }
        //
        // this._rpcHandlers[id] = handler;
        //
        // return this;
        }

       var _signalHandlers = {};//    return
//  }
}
