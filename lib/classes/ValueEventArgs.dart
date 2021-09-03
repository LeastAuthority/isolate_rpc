import 'package:event/event.dart';

class ValueEventArgs extends EventArgs {
  String error;
  ValueEventArgs(this.error);
  String get() {
    return error;
  }
}