import 'dart:async';

class TxTimeout {
  Duration duration;
  void Function(Transaction) callback;

  TxTimeout(this.duration, this.callback);
}

class Transaction {
  late final Completer _completer;
  late final int _id;
  late final Timer _timer;

  Transaction(this._id, TxTimeout timeoutOpts) {
    _completer = new Completer();
    _timer = Timer(timeoutOpts.duration, () => timeoutOpts.callback(this));
  }

  void resolve(dynamic payload) {
    _timer.cancel();
    _completer.complete(payload);
  }

  void reject(error) {
    _timer.cancel();
    _completer.completeError(error);
  }

  dynamic getTransactionId() {
    return _id;
  }

  bool get isCompleted {
    return _completer.isCompleted;
  }

  Future<dynamic> get future {
    return _completer.future;
  }
}
