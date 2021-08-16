library isolate_rpc;
import 'package:event/event.dart';
import 'package:isolate_rpc/utils/AsyncOperation.dart';
import 'classes/Message.dart';
import 'dart:core';
import 'dart:async';
import 'classes/Transaction.dart';
typedef dynamic RpcHandler<T, U> (T payload);
typedef T SignalHandler<T>(T payload);

typedef Dispatcher (MessageClass message, List<dynamic>? transfer);

abstract class TransactionType {
    int? id;
    var timeoutHandle;
    void resolve(result);
    void reject(error);
}

class Message {
  MessageType? type;
  String? id;
  int? transactionId;
  dynamic payload;
}
const MSG_RESOLVE_TRANSACTION = "resolve_transaction",
    MSG_REJECT_TRANSACTION = "reject_transaction",
    MSG_ERROR = "error";

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

class ValueEventArgs extends EventArgs {
  String error;
  ValueEventArgs(this.error);
  String get() {
    return error;
  }
}
class RpcProvider  {
  Dispatcher _dispatch;
  int? _rpcTimeout;
  int value = 0;

  static final error = Event();

  RpcProvider(dispatch, rpcTimeout)
      : _dispatch = dispatch,
        _rpcTimeout = rpcTimeout;

        void _handleSignal(MessageClass message) {
            if (this._signalHandlers[message.getId()] == null) {
               return this._raiseError('invalid signal ${message.getId()}');
            }
            this._signalHandlers[message.getId()]?.forEach((handler) => handler(message.getPayload()));
        }


        signal (String id, [payload, transfer]) {
          MessageClass message = new MessageClass(id, payload, MessageType.signal, null);
          this._dispatch(message, transfer != null ? transfer : null);
          return this;
        }

        rpc<T, U>(String id, [int? payload, List<dynamic>? transfer]) {
               AsyncOperation asyncOperation = new AsyncOperation();
               final future = asyncOperation.doOperation();
               var timer;
               int transactionId = this._nextTransactionId;
               MessageClass message = new MessageClass(id, payload, MessageType.rpc, transactionId);
               this._dispatch(message, transfer != null ? transfer : null);
               Transaction transaction = new Transaction(transactionId, asyncOperation);
               this._pendingTransactions[transactionId] = transaction;
               if (_rpcTimeout! > 0) {
                 timer = Timer(Duration(seconds:  _rpcTimeout!), () => this._transactionTimeout(transaction));
                 this._pendingTransactions[transactionId]?.timeoutHandle = timer;
               }
               return future;
        }
        registerSignalHandler<T, U>(String id, SignalHandler handler) {
          if (this._signalHandlers[id] == null) {
            this._signalHandlers[id] = [];
          }
          this._signalHandlers[id]?.add(handler);
          return this;
        }

        unregisterSignalHandler (String id, SignalHandler handler) {
          if (this._signalHandlers[id] != null) {
            this._signalHandlers[id] = [];
          }
         return this;
        }
        registerRpcHandler(String id, RpcHandler handler) {
            if (this._rpcHandlers[id] != null) {
               Future.error("rpc handler for ${id} already registered");
            }
            this._rpcHandlers[id] = handler;
            return this;
        }

        void _transactionTimeout(Transaction transaction)  {

             if(transaction.isCompleted() == false) {
               transaction.reject('transaction timed out');
             }

                this._raiseError("transaction ${transaction.getTransactionId()} timed out");
                this._pendingTransactions.remove(transaction.getTransactionId());

              return;
        }

        void _raiseError(String myError) {
              //Warning this function is not finished, still needs a lot of work.
             // this.error.dispatch(new Error(error));
              ValueEventArgs errorMessage = new ValueEventArgs(myError);
              MessageClass msg = new MessageClass(MSG_ERROR, 0, MessageType.internal, 0);
              error.broadcast(errorMessage);
              this._dispatch(msg, null);
        }

        void _handleRpc (MessageClass message) {
          if (_rpcHandlers[message.getId()] == null) {
              return this._raiseError("invalid rpc ${message.getId()}");
            }
            Future.value(_rpcHandlers[message.getId()]!(message.getPayload())).then((value){
              MessageClass msg = new MessageClass(MSG_RESOLVE_TRANSACTION, value as int, MessageType.internal, message.getTransactionId());
              this._dispatch(msg, null);
          }).catchError((error) {
              MessageClass msg = new MessageClass(MSG_REJECT_TRANSACTION, error, MessageType.internal, message.getTransactionId());
              this._dispatch(msg, null);
          });
        }

        _clearTransaction(Transaction? transaction) {
          if (transaction != null) {
            transaction.timeoutHandle = null;
          }
          this._pendingTransactions.remove(transaction?.getTransactionId());
        }
        _handleInternal(MessageClass message) {
          var transaction;
          if(message.getTransactionId() != null) {
            transaction = this._pendingTransactions[message.getTransactionId()];
          } else {
            transaction = null;
          }

          switch (message.getId()) {
          case MSG_RESOLVE_TRANSACTION:
          if (transaction == null || message.getTransactionId() == 'undefined') {
            return this._raiseError("no pending transaction with id ${message.getTransactionId()}");
          }

          transaction.resolve(message.getPayload());
          this._clearTransaction(this._pendingTransactions[message.getTransactionId()]);
          break;

          case MSG_REJECT_TRANSACTION:
          // if (transaction == null || message.getTransactionId() == 'undefined') {
          // return this._raiseError("no pending transaction with id ${message.getTransactionId()}");
          // }
            transaction.reject(message.getPayload());
           //message.getPayload()
         // this._pendingTransactions[message.getTransactionId()]?.reject('');
          // this._clearTransaction(this._pendingTransactions[message.getTransactionId()]);

          break;

          case MSG_ERROR:
            print('MSG_ERROR');
          // this.error.dispatch(new Error("remote error: ${message.getPayload()}"));
          break;

          default:
          this._raiseError("unhandled internal message ${message.id}");
          break;
          }
        }

          var _signalHandlers = new Map<String, List>();
          var _rpcHandlers = new Map<String, RpcHandler>();
          int _nextTransactionId = 0;
          var _pendingTransactions = new Map<int, Transaction>();

        dispatch (MessageClass payload) {
          MessageClass message = payload;
            switch (message.getMesageType()) {
              case MessageType.signal:
                return _handleSignal(message);
              case MessageType.rpc:
               return this._handleRpc(message);
              case MessageType.internal:
                return this._handleInternal(message);
        //
        // case MessageType.internal:
        // return this._handleInternal(message);
        //
        // default:
        // this._raiseError(`invalid message type ${message.type}`);
        }
      }
//  }
}
