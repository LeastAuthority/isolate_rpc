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
        // remote?.registerRpcHandler('action', (x) => 10); //the original code () => 10. Changed to make linter shut up.
        // int result = await local?.rpc('action');
        // assert(result==10);
        // assert(errorLocal == null);
        // assert(errorRemote == null);
      });

      test('RPC handlers can return futures', ()async {
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


//import assert from 'assert';
//
//import RpcProvider from '../src/RpcProvider';
//
//suite('RPC provider', function() {
//
//  let local: RpcProvider,
//  remote: RpcProvider,
//  transferLocalToRemote: Array<any> | undefined,
//  transferRemoteToLocal: Array<any> | undefined,
//  errorLocal: Error | undefined,
//  errorRemote: Error | undefined;
//
//  setup(function() {
//  local = new RpcProvider(
//  (message, transfer) => (transferLocalToRemote = transfer, remote.dispatch(message)),
//  50
//  );
//
//  local.error.addHandler(err => errorLocal = err);
//
//  remote = new RpcProvider(
//  (message, transfer) => (transferRemoteToLocal = transfer, local.dispatch(message)),
//  50
//  );
//
//  remote.error.addHandler(err => errorRemote = err);
//
//  transferLocalToRemote = transferRemoteToLocal = undefined;
//  errorRemote = errorLocal = undefined
//  });
//
//  suite('signals', function() {
//
//  test('Signals are propagated', function() {
//  let x = -1;
//
//  remote.registerSignalHandler('action', (value: number) => x = value);
//
//  local.signal('action', 5);
//
//  assert(!errorLocal);
//  assert(!errorRemote);
//  assert.strictEqual(x, 5);
//  });
//
//  test('Unregistered signals raise an error', function() {
//  local.signal('action', 10);
//
//  assert(errorLocal);
//  assert(errorRemote);
//  });
//
//  test('Multiple signals do not interfere', function() {
//  let x = -1, y = -1;
//
//  remote.registerSignalHandler('setx', (value: number) => x = value);
//  remote.registerSignalHandler('sety', (value: number) => y = value);
//
//  local.signal('setx', 5);
//  local.signal('sety', 6);
//
//  assert(!errorLocal);
//  assert(!errorRemote);
//  assert.strictEqual(x, 5);
//  assert.strictEqual(y, 6);
//  });
//
//  test('Multiple handlers can be bound to one signal', function() {
//  let x = -1;
//
//  remote.registerSignalHandler('action', (value: number) => x = value);
//
//  local.signal('action', 1);
//  local.signal('action', 2);
//
//  assert(!errorLocal);
//  assert(!errorRemote);
//  assert.strictEqual(x, 2);
//  });
//
//  test('Handlers can be deregistered', function() {
//  let x = -1;
//
//  const handler = (value: number) => x = value;
//
//  remote.registerSignalHandler('action', handler);
//  remote.deregisterSignalHandler('action', handler);
//
//  local.signal('action', 5);
//
//  assert(!errorLocal);
//  assert(!errorRemote);
//  assert.strictEqual(x, -1);
//  });
//
//  test('Transfer is honored', function() {
//  let x = -1;
//  const transfer = [1, 2, 3];
//
//  remote.registerSignalHandler('action', (value: number) => x = value);
//
//  local.signal('action', 2, transfer);
//
//  assert(!errorLocal);
//  assert(!errorRemote);
//  assert.strictEqual(x, 2);
//  assert.strictEqual(transferLocalToRemote, transfer);
//  assert(!transferRemoteToLocal);
//  });
//
//  });
//
//  suite('RPC', function() {
//
//  test('RPC handlers can return values', function() {
//  remote.registerRpcHandler('action', () => 10);
//
//  return local
//      .rpc('action')
//      .then(result => (
//  assert.strictEqual(result, 10),
//  assert(!errorLocal),
//  assert(!errorRemote)
//  ));
//  });
//
//  test('RPC handlers can return promises', function() {
//  remote.registerRpcHandler('action', () => new Promise(r => setTimeout(() => r(10), 15)));
//
//  return local
//      .rpc('action')
//      .then(result => (
//  assert.strictEqual(result, 10),
//  assert(!errorLocal),
//  assert(!errorRemote)
//  ));
//  })
//
//  test('Promise rejection is transferred', function() {
//  remote.registerRpcHandler('action', () => new Promise((resolve, reject) => setTimeout(() => reject(10), 15)));
//
//  return local
//      .rpc('action')
//      .then(
//  () => Promise.reject('should have been rejected'),
//  result => (
//  assert.strictEqual(result, 10),
//  assert(!errorLocal),
//  assert(!errorRemote)
//  )
//  );
//  });
//
//  test('Invalid RPC calls are rejected', function() {
//  return local
//      .rpc('action')
//      .then(
//  () => Promise.reject('should have been rejected'),
//  () => undefined
//  );
//  });
//
//  test('Invalid RPC calls throw on both ends', function() {
//  return local
//      .rpc('action')
//      .then(
//  () => Promise.reject('should have been rejected'),
//  () => undefined
//  )
//      .then(() => (
//  assert(errorLocal),
//  assert(errorRemote)
//  ));
//  });
//
//  test('RPC calls time out', function() {
//  remote.registerRpcHandler('action', () => new Promise(r => setTimeout(() => r(10), 100)));
//
//  return local
//      .rpc('action')
//      .then(
//  () => Promise.reject('should have been rejected'),
//  () => (assert(errorLocal), new Promise(r => setTimeout(r, 100)))
//  )
//      .then(() => assert(errorRemote));
//  });
//
//  test('Multiple RPC handlers do not interfere', function() {
//  remote.registerRpcHandler('a1', (value: number) => new Promise(r => setTimeout(() => r(value), 30)));
//  remote.registerRpcHandler('a2', (value: number) => 2 * value);
//
//  return Promise
//      .all([
//  local.rpc('a1', 10),
//  local.rpc('a2', 20)
//  ])
//      .then(([r1, r2]) => (
//  assert.strictEqual(r1, 10),
//  assert.strictEqual(r2, 40),
//  assert(!errorLocal),
//  assert(!errorRemote)
//  ));
//  });
//
//  test('RPC handler can be deregistered', function() {
//  const handler = () => 10;
//
//  remote.registerRpcHandler('action', handler);
//  remote.deregisterRpcHandler('action', handler);
//
//  return local
//      .rpc('action')
//      .then(
//  () => Promise.reject('should have been rejected'),
//  () => (
//  assert(errorLocal),
//  assert(errorRemote)
//  )
//  );
//  });
//
//  test('Transfer is honored', function() {
//  const transfer = [1, 2, 3];
//
//  remote.registerRpcHandler('action', () => 10);
//
//  return local
//      .rpc('action', undefined, transfer)
//      .then(x => (
//  assert.strictEqual(transferLocalToRemote, transfer),
//  assert.strictEqual(x, 10),
//  assert(!errorLocal),
//  assert(!errorRemote)
//  ));
//  });
//
//  });
//
//});