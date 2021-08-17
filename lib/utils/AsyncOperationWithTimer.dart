import 'dart:async';

class AsyncOperationWithTimer {
  final Completer _completer = new Completer();
  int timer = 0;
  AsyncOperationWithTimer({int timer = 0}) {
    this.timer = timer;
  }
  Future doOperation(Function callback) {
    Future.delayed(Duration(milliseconds: timer), () => callback());
    return _completer.future; // Send future object back to client.
  }

  // Something calls this when the value is ready.
  void finishOperation(result) {
    _completer.complete(result);
  }

  // If something goes wrong, call this.
  void errorHappened(error) {
    _completer.completeError(error);
  }
}