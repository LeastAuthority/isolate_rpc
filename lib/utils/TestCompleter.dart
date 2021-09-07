import 'dart:async';

class TestCompleter {
  final Completer _completer = new Completer();
  int timer = 0;
  TestCompleter({int timer = 0}) {
    this.timer = timer;
  }
  Future doOperation(Function callback) {
    Future.delayed(Duration(milliseconds: timer), () => callback());
    return _completer.future;
  }

  void finishOperation(result) {
    _completer.complete(result);
  }

  void errorHappened(error) {
    _completer.completeError(error);
  }
}