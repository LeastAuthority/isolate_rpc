library isolate_rpc;
import 'package:event/event.dart';
import 'package:isolate_rpc/utils/AsyncOperation.dart';
import 'classes/Message.dart';
import 'dart:core';
import 'dart:async';
import 'classes/Transaction.dart';
import 'classes/ValueEventArgs.dart';
import 'constants/strings.dart';
import 'interfaces/RpcProviderInterface.dart';

typedef Dispatcher (MessageClass message, List<dynamic>? transfer);

class RpcProvider  {
  Dispatcher _dispatch;
  int? _rpcTimeout;
  int value = 0;

  static final error = Event();

  RpcProvider(dispatch, rpcTimeout)
      : _dispatch = dispatch,
        _rpcTimeout = rpcTimeout;

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
            default:
              this._raiseError("$INVALID_MESSAGE_TYPE ${message.type}");
          }
        }

         _handleSignal(MessageClass message) {
          if (this._signalHandlers[message.getId()] == null) {
            return this._raiseError('$INVALID_SIGNAL ${message.getId()}');
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
            timer = Timer(Duration(milliseconds:  _rpcTimeout!), () => this._transactionTimeout(transaction));
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

        unRegisterRpcHandler (String id, RpcHandler handler)  {
          if (this._rpcHandlers[id] != null) {
             this._rpcHandlers.remove(id);
            }
            return this;
        }

        _transactionTimeout(Transaction transaction)  {
          if(transaction.isCompleted() == false) {
            transaction.reject('$TRANSACTION_TIME_OUT');
          }

          this._raiseError("$TRANSACTION ${transaction.getTransactionId()} $TIME_OUT");
          this._pendingTransactions.remove(transaction.getTransactionId());

          return;
        }

        _raiseError(String myError) {
          ValueEventArgs errorMessage = new ValueEventArgs(myError);
          MessageClass msg = new MessageClass(MSG_ERROR, myError, MessageType.internal, null);
          error.broadcast(errorMessage);
          this._dispatch(msg, null);
        }

        _handleRpc (MessageClass message) {
          if (_rpcHandlers[message.getId()] == null) {
              return this._raiseError("$INVALID_RPC ${message.getId()}");
            }
            Future.value(_rpcHandlers[message.getId()]!(message.getPayload())).then((value){
              MessageClass msg = new MessageClass(
                  MSG_RESOLVE_TRANSACTION,
                  value,
                  MessageType.internal,
                  message.getTransactionId()
              );
              this._dispatch(msg, null);
          }).catchError((error) {
              MessageClass msg = new MessageClass(
                  MSG_REJECT_TRANSACTION,
                  error,
                  MessageType.internal,
                  message.getTransactionId()
              );
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
          if (transaction == null || message.getTransactionId() == null) {
            return this._raiseError("$NO_PENDING_TRANSACTION_WITH_ID ${message.getTransactionId()}");
          }

          transaction.resolve(message.getPayload());
          this._clearTransaction(this._pendingTransactions[message.getTransactionId()]);
          break;

          case MSG_REJECT_TRANSACTION:
            if (transaction == null || message.getTransactionId() == null) {
              return this._raiseError("$NO_PENDING_TRANSACTION_WITH_ID ${message.getTransactionId()}");
            }
            this._pendingTransactions[message.getTransactionId()]?.reject(message.getPayload());
            this._clearTransaction(this._pendingTransactions[message.getTransactionId()]);
            break;

          case MSG_ERROR:
            ValueEventArgs errorMessage = new ValueEventArgs("$REMOTE_ERROR ${message.getPayload()}");
            error.broadcast(errorMessage);
            break;

          default:
           this._raiseError("$UNHANDLED_INTERNAL ${message.id}");
          break;
          }
        }
}
