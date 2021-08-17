import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:isolate_rpc/classes/Message.dart';
import 'package:isolate_rpc/classes/ValueEventArgs.dart';

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
        }, 50);

      // local?.error.subscribe((args) {print('local_event_fired');});
      RpcProvider.error.subscribe((args) {
        errorLocal = (args as ValueEventArgs).get();
      });
      remote = new RpcProvider((MessageClass message, List<dynamic>? transfer)  {
        transferRemoteToLocal = transfer;
        local?.dispatch(message);
        }, 50);

      RpcProvider.error.subscribe((args) {
        errorRemote = (args as ValueEventArgs).get();
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
        AsyncOperationWithTimer asyncOperation = new AsyncOperationWithTimer(timer: 15);
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
        AsyncOperationWithTimer asyncOperation = new AsyncOperationWithTimer(timer: 15);
        remote?.registerRpcHandler('action', (x) {
          return asyncOperation.doOperation(()=> asyncOperation.errorHappened(10));
        });

        try {
           await local?.rpc('action');
           Future.error('should have been rejected');
        } catch (e) {
          assert(e==10);
          assert(errorLocal == null);
          assert(errorRemote  == null);
        }

      });

      test('Invalid RPC calls are rejected', () async {

        try {
          await local?.rpc('action');
          Future.error('should have been rejected');
        } catch (e) {

        }

      });

      test('Invalid RPC calls throw on both ends', ()async {
        try {
          await local?.rpc('action');
          Future.error('should have been rejected');
        } catch (e) {
           assert(errorLocal != null);
           assert(errorRemote != null);
        }
      });

      test('RPC calls time out', ()async {
        AsyncOperationWithTimer asyncOperation = new AsyncOperationWithTimer(timer: 100);
        AsyncOperationWithTimer asyncOperation2 = new AsyncOperationWithTimer(timer: 100);

        remote?.registerRpcHandler('action', (x) {
          return asyncOperation.doOperation(()=> asyncOperation.finishOperation(10));
        });

        try {
          await local?.rpc('action');
          Future.error('should have been rejected');
        } catch (e) {
            assert(errorLocal != null);
            await asyncOperation2.doOperation(()=> asyncOperation2.finishOperation(0));
            assert(errorRemote  != null);
        }

      });

      test('Multiple RPC handlers do not interfere', ()async {
        AsyncOperationWithTimer asyncOperation = new AsyncOperationWithTimer(timer: 30);
        remote?.registerRpcHandler('a1', (value) {
          return asyncOperation.doOperation(()=> asyncOperation.finishOperation(value));
        });
        remote?.registerRpcHandler('a2', (value) => 2 * 20);

        int a1 = await local?.rpc('a1',10);
        int a2 = await local?.rpc('a2',20);

        assert(a1 == 10);
        assert(a2 == 40);
        assert(errorLocal == null);
        assert(errorRemote == null);
      });

      test('RPC handler can be unregister', ()async {
        var handler = (x) => 10;
        remote?.registerRpcHandler('action', handler);
        remote?.unRegisterRpcHandler('action', handler);

          try {
            await local?.rpc('action');
            Future.error('should have been rejected');
          } catch (e) {
            assert(errorLocal != null);
            assert(errorRemote  != null);
          }
      });

      test('Transfer is honored', ()async {
        const transfer = [1, 2, 3];

        remote?.registerRpcHandler('action', (x) => 10);

        int x = await local?.rpc('action', null, transfer);
        assert(compareArrays(transferLocalToRemote, transfer));
        assert(x  == 10);
        assert(errorLocal == null);
        assert(errorRemote == null);
      });
    });
  });
}
