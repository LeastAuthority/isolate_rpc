import 'dart:async';

class AsyncOperation {
  final Completer _completer = new Completer();

  Future doOperation() {
    return _completer.future;
  }

  void finishOperation(result) {
    _completer.complete(result);
  }

  void errorHappened(error) {
    _completer.completeError(error);
  }
  bool isCompleted () {
    return _completer.isCompleted;
  }
}