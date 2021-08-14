import 'dart:async';

class AsyncOperation {
  final Completer _completer = new Completer();

  Future doOperation() {
  //  _startOperation();
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