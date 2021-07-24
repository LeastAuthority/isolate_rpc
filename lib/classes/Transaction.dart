import 'dart:async';

abstract class AbTransaction {
  int? _transactionId;
}

 class Transaction extends AbTransaction{
  // Function _resolve;
  int? _transactionId;
  Timer? timeoutHandle;
  Transaction(int? transactionId)
      :_transactionId = transactionId;

  // dynamic resolve() {
  //   return _resolve;
  // }
  // dynamic reject() {
  //   return _resolve;
  // }
  dynamic getTransactionId() {
    return _transactionId;
  }

}
