import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:isolate_rpc/classes/Message.dart';

import 'package:isolate_rpc/isolate_rpc.dart';
import 'package:isolate_rpc/utils/AsyncOperation.dart';
import 'package:isolate_rpc/utils/AsyncOperationWithTimer.dart';
import 'package:isolate_rpc/utils/compareArrays.dart';
typedef T SignalHandler<T>(T payload);
typedef Future<U> RpcHandler<T, U> (T payload);

void main() {
  group('RPC Provider', () {
    RpcProvider? local;
    RpcProvider? remote;
    dynamic transferLocalToRemote;
    dynamic transferRemoteToLocal;
    Message localMessage;
    String? errorLocal;
    String? errorRemote;

    setUp(() {
      local = new RpcProvider((MessageClass message, List<dynamic>? transfer) {
         transferLocalToRemote = transfer;
         remote?.dispatch(message);
        }, 29);

      // local?.error.subscribe((args) {print('local_event_fired');});
      RpcProvider.error.subscribe((args) {
        errorLocal = (args as ValueEventArgs).get();
        print('local_event_fired');
        print(errorLocal);
      });
      remote = new RpcProvider((MessageClass message, List<dynamic>? transfer)  {
        transferRemoteToLocal = transfer;
        local?.dispatch(message);
        }, 29);

      RpcProvider.error.subscribe((args) {
        errorRemote = (args as ValueEventArgs).get();
        print('remote_event_fired');
        print(errorRemote);
      });
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
        assert(errorLocal != null);
        assert(errorRemote != null);
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
        assert(compareArrays(transferLocalToRemote, transfer));
        assert(transferRemoteToLocal == null);
      });
    });

    group('RPC', () {
      test('RPC handlers can return values', () async {
        remote?.registerRpcHandler('action', (x) => 10);
        int result = await local?.rpc('action');
        assert(result==10);
        assert(errorLocal == null);
        assert(errorRemote == null);
      });

      test('RPC handlers can return futures', () async {
        AsyncOperationWithTimer asyncOperation = new AsyncOperationWithTimer(timer: 10);
        remote?.registerRpcHandler('action', (x) {
          return asyncOperation.doOperation(()=> asyncOperation.finishOperation(10));
        });
        int result = await local?.rpc('action');
        assert(result==10);
        assert(errorLocal == null);
        assert(errorRemote == null);
      });

      // TODO: check terminology (originally "promise rejection")
      test('Future rejection is transferred', () async {
        AsyncOperationWithTimer asyncOperation = new AsyncOperationWithTimer(timer: 10);
        remote?.registerRpcHandler('action', (x) {
          return asyncOperation.doOperation(()=> asyncOperation.errorHappened(10));
        });

        try {
           await local?.rpc('action');
           throw('should have been rejected');
        } catch (e) {
          assert(e==10);
          assert(errorLocal == null);
          assert(errorRemote  == null);
        }

      });

      test('Invalid RPC calls are rejected', () async {

        try {
          await local?.rpc('action');
          throw('should have been rejected');
        } catch (e) {

        }

      });

      test('Invalid RPC calls throw on both ends', ()async {

        try {
          await local?.rpc('action');
          throw('should have been rejected');
        } catch (e) {
           assert(errorLocal != null);
           assert(errorRemote != null);
        }


      });

      test('RPC calls time out', ()async {
        // AsyncOperationWithTimer asyncOperation = new AsyncOperationWithTimer(timer: 100);
        // //AsyncOperationWithTimer asyncOperation2 = new AsyncOperationWithTimer(timer: 100);
        //
        // remote?.registerRpcHandler('action', (x) {
        //   return asyncOperation.doOperation(()=> asyncOperation.errorHappened(10));
        // });
        //
        // local?.rpc('action').then(()=> {
        //   throw('should have been rejected')
        // }
        // // ,onError:(e)=> asyncOperation2.doOperation(()=> asyncOperation.finishOperation(10))
        // )
        // .then((e)=> {
        //     print(e)
        // });

        // try {
        //   await local?.rpc('action');
        //
        // } catch (e) {
        // // assert(e==10);
        // assert(errorLocal == null);
        // // assert(errorRemote  == null);
        // }
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
