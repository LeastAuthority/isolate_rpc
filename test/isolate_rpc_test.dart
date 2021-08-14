import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:isolate_rpc/classes/Message.dart';

import 'package:isolate_rpc/isolate_rpc.dart';
typedef T SignalHandler<T>(T payload);
typedef Future<U> RpcHandler<T, U> (T payload);

void main() {
  group('RPC Provider', () {
    RpcProvider? local;
    RpcProvider? remote;
    dynamic transferLocalToRemote;
    dynamic transferRemoteToLocal;
    Message localMessage;
    Error? errorLocal;
    Error? errorRemote;

    setUp(() {
      local = new RpcProvider((MessageClass message, List<dynamic>? transfer) {
         transferLocalToRemote = transfer;
         remote?.dispatch(message);
        }, 50);

      //Warning: this line is finished, needs more work
      local?.error.subscribe((args) {print('local_event_fired');});

      remote = new RpcProvider((MessageClass message, List<dynamic>? transfer)  {
        transferRemoteToLocal = transfer;
        local?.dispatch(message);
        }, 50);

      //Warning: this line is finished, needs more work
      remote?.error.subscribe((args) {print('remote_event_fired');});
      transferLocalToRemote = transferRemoteToLocal = null;
      errorRemote = errorLocal = null;
    });

    group('signals', () {
      test('Signals are propogated', () {
        int x = -1;
        remote?.registerSignalHandler('action', (value) => x = value);
        local?.signal('action', 5);
        assert(errorLocal == null);
        assert(errorRemote == null);
        assert(x == 5);
      });

      test('Unregistered signals raise an error', () {
        local?.signal('action', 10);

        assert(errorLocal == null);
        assert(errorRemote == null);
      });

      test('Multiple signals do not interfere', () {
        int x = -1, y = -1;

        remote?.registerSignalHandler('setx', (value) => x = value);
        remote?.registerSignalHandler('sety', (value) => y = value);
        local?.signal('setx', 5);
        local?.signal('sety', 6);
        assert(errorLocal == null);
        assert(errorRemote == null);
        assert(x==5);
        assert(y==6);
      });

      test('Multiple handlers can be bound to one signal', () {
        int x = -1;

        remote?.registerSignalHandler('action', (value) => x = value);

        local?.signal('action', 1);
        local?.signal('action', 2);

        assert(errorLocal == null);
        assert(errorRemote == null);
        assert(x==2);
      });

      test('Handlers can be deregistered', () {
        int x = -1;
        SignalHandler handler = (value) => x = value;
        remote?.registerSignalHandler('action', handler);
        remote?.unregisterSignalHandler('action', handler);
        local?.signal('action', 5);

        assert(errorLocal == null);
        assert(errorRemote == null);
        assert(x==-1);
      });

      test('Transfer is honored', () {
        int x = -1;
        const transfer = [1, 2, 3];

        remote?.registerSignalHandler('action', (value) => x = value);

        local?.signal('action', 2, transfer);

        assert(errorLocal == null);
        assert(errorRemote == null);
        assert(x==2);
        assert(transferLocalToRemote == transfer);
         assert(transferRemoteToLocal == null);
      });
    });

    group('RPC', () {
      test('RPC handlers can return values', () async {
        remote?.registerRpcHandler('action', (x) => 10); //the original code () => 10. Changed to make linter shut up.
        int result = await local?.rpc('action');
        assert(result==10);
        // assert(errorLocal == null);
        // assert(errorRemote == null);
      });

      test('RPC handlers can return futures', () async {
        // remote?.registerRpcHandler('action', (x) {
        //   return Future.delayed(Duration(seconds: 5), (){
        //       print('registerRpcHandlerddddd');
        //     });
        // });
        // int result = await local?.rpc('action');
        //  assert(result==10);
        // assert(errorLocal == null);
        // assert(errorRemote == null);
      });

      // TODO: check terminology (originally "promise rejection")
      test('Future rejection is transferred', () async {
        //   remote?.registerRpcHandler('action', (x) {
        //       // return Future.delayed(Duration(seconds: 5), () {
        //       //  throw(10);
        //     // });
        //     return MSG_REJECT_TRANSACTION;
        //   });
        //
        // // try {
        //   local?.rpc('action')
        //       .then(expectAsync((e) {
        //     print(e);
        //   })).catchError((error){
        //     print("eeee");
        //     print(error);
        //     assert(error==10);
        //     assert(errorLocal == null);
        //     assert(errorRemote  == null);
        //   });

      });

      test('Invalid RPC calls are rejected', () {
        // local?.rpc('action').then((result){
        //
        // }).catchError((e) {
        //   Future.error('should have been rejected');
        // });

      });

      test('Invalid RPC calls throw on both ends', ()async {

        // local?.rpc('action').then((result){
        //
        // }).catchError((e) {
        //   Future.error('should have been rejected');
        // });
        //
        // assert(errorLocal == null);
        // assert(errorRemote == null);

      });

      test('RPC calls time out', () {
        // remote?.registerRpcHandler('action', (x) {
        //   return Future.delayed(Duration(seconds: 100), (){
        //
        //   });
        // });

      });

      test('Multiple RPC handlers do not interfere', () {

      });

      // TODO: "deregister" is the original name but I think "unregister" is more conventional.
      test('RPC handler can be deregistered', () {

      });

      test('Transfer is honored', () {

      });
    });
  });
}
