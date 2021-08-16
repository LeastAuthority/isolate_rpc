import 'dart:async';

import 'package:isolate_rpc/utils/AsyncOperation.dart';

abstract class AbTransaction {
  int? _transactionId;
}

 class Transaction extends AbTransaction{
   AsyncOperation? _asyncOperation;
  int? _transactionId;
  Timer? timeoutHandle;
  Transaction(int? transactionId, AsyncOperation? asyncOperation) {
    this._asyncOperation = asyncOperation;
    _transactionId = transactionId;
  }

  void resolve(int payload) {

    _asyncOperation!.finishOperation(payload);
   // return _resolve!();
  }
   void reject(error) {
     _asyncOperation!.errorHappened(error);
  }
  dynamic getTransactionId() {
    return _transactionId;
  }
  bool isCompleted () {
    return _asyncOperation!.isCompleted();
  }
}