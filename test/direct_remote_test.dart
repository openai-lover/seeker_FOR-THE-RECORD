import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:bs58/bs58.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seeker_workroom/data/direct_activity.dart';
import 'package:seeker_workroom/data/remote.dart';
import 'package:seeker_workroom/data/repository.dart';
import 'package:seeker_workroom/domain/controller.dart';
import 'package:seeker_workroom/domain/models.dart';
import 'package:seeker_workroom/domain/trade_journal.dart';
import 'package:seeker_workroom/platform/native.dart';

String address(int value) =>
    base58.encode(Uint8List(32)..fillRange(0, 32, value));
Map<String, dynamic> account(int value) => {
  'publicKey': base64Encode(Uint8List(32)..fillRange(0, 32, value)),
};

class _Wallet extends NativePlatform {
  final methods = <String>[];
  final connections = Queue<Future<Map<String, dynamic>> Function()>();
  Future<Map<String, dynamic>>? disconnectResponse;
  @override
  Future<ClockSample> clock() async =>
      const ClockSample(10000, 'boot', 1700000000000);
  @override
  Future<void> alarm(int remainingMs) async {}
  @override
  Future<void> cancelAlarm() async {}
  @override
  Future<Map<String, dynamic>> wallet(
    String method, [
    Map<String, dynamic> args = const {},
  ]) async {
    methods.add(method);
    if (method == 'walletConnect') return connections.removeFirst()();
    if (method == 'walletDisconnect') {
      return disconnectResponse ?? Future.value({});
    }
    throw StateError('Unexpected signing or wallet method: $method');
  }
}

class _Activity extends DirectActivityClient {
  final loads = <String>[];
  final responses = Queue<Future<Map<String, dynamic>> Function()>();
  var clearCount = 0;
  @override
  Future<Map<String, dynamic>> load(String wallet, {String? before}) {
    loads.add(wallet);
    return responses.removeFirst()();
  }

  @override
  void clearCache() {
    clearCount++;
    super.clearCache();
  }
}

void main() {
  late _Wallet native;
  late _Activity activity;
  late WorkroomController local;
  late RemoteService remote;
  setUp(() async {
    native = _Wallet();
    activity = _Activity();
    local = WorkroomController(MemoryRepository(), native);
    await local.load();
    remote = RemoteService(
      native,
      local,
      directWalletEnabled: true,
      activityClient: activity,
    );
    await remote.initialize();
  });
  tearDown(() {
    remote.dispose();
    local.dispose();
  });

  test(
    'MWA address authorization connects without Firebase or message/transaction signing',
    () async {
      native.connections.add(() async => account(1));
      await remote.connect();
      expect(remote.directMode, isTrue);
      expect(remote.signedIn, isTrue);
      expect(remote.wallet, address(1));
      expect(remote.uid, address(1));
      expect(native.methods, ['walletConnect']);
      expect(activity.loads, isEmpty);
      expect(remote.seeker, isFalse);
      expect(remote.paymentsEnabled, isFalse);
      await expectLater(
        remote.call('order-create'),
        throwsA(
          isA<ServiceError>().having((e) => e.code, 'code', 'not-configured'),
        ),
      );
      await remote.currentRoom();
      await remote.profile();
      expect(native.methods, ['walletConnect']);
    },
  );

  test(
    'disconnect clears remote state and retains projects and private journal notes',
    () async {
      await local.addProject('My private project', 'My private goal', 0);
      const snapshot = WalletActivity(
        id: 'tx',
        signature: 'tx',
        status: 'success',
        type: 'swap',
        input: ActivityAsset(mint: 'a', symbol: 'A', amount: '1'),
        output: ActivityAsset(mint: 'b', symbol: 'B', amount: '2'),
      );
      await local.journals.save(
        TradeJournalEntry(
          id: 'note',
          wallet: address(1),
          activity: snapshot,
          createdAt: 1,
          updatedAt: 1,
          reason: 'My private reason',
        ),
      );
      native.connections.add(() async => account(1));
      await remote.connect();
      await remote.disconnect();
      expect(remote.wallet, isNull);
      expect(remote.signedIn, isFalse);
      expect(remote.activities, isEmpty);
      expect(local.state.projects.single.title, 'My private project');
      expect(local.journals.entries.single.reason, 'My private reason');
      expect(
        (await local.repository.readJournals()).single.reason,
        'My private reason',
      );
      expect(native.methods, ['walletConnect', 'walletDisconnect']);
      expect(activity.clearCount, greaterThanOrEqualTo(2));
    },
  );

  test(
    'switching accounts discards old in-flight activity and loads the new wallet',
    () async {
      native.connections.add(() async => account(1));
      await remote.connect();
      final old = Completer<Map<String, dynamic>>();
      activity.responses.add(() => old.future);
      final loading = remote.loadActivity();
      native.connections.add(() async => account(2));
      await remote.connect();
      old.complete({'wallet': address(1), 'items': [], 'nextCursor': null});
      await loading;
      expect(remote.wallet, address(2));
      expect(remote.activityLoaded, isFalse);
      expect(remote.activityLoading, isFalse);
      activity.responses.add(
        () async => {'wallet': address(2), 'items': [], 'nextCursor': null},
      );
      await remote.loadActivity();
      expect(activity.loads, [address(1), address(2)]);
      expect(remote.activityLoaded, isTrue);
      expect(remote.activityError, isNull);
    },
  );

  test(
    'an old disconnect completion cannot clear a newly connected account',
    () async {
      native.connections.add(() async => account(1));
      await remote.connect();
      final disconnect = Completer<Map<String, dynamic>>();
      native.disconnectResponse = disconnect.future;
      final leaving = remote.disconnect();
      await Future<void>.delayed(Duration.zero);
      native.connections.add(() async => account(2));
      await remote.connect();
      disconnect.complete({});
      await leaving;
      expect(remote.wallet, address(2));
      expect(remote.signedIn, isTrue);
    },
  );

  test(
    'disconnect invalidates an older wallet authorization before it can reconnect',
    () async {
      final authorization = Completer<Map<String, dynamic>>();
      native.connections.add(() => authorization.future);
      final connecting = remote.connect();
      final expectation = expectLater(
        connecting,
        throwsA(
          isA<ServiceError>().having((e) => e.code, 'code', 'account-changed'),
        ),
      );
      await remote.disconnect();
      authorization.complete(account(1));
      await expectation;
      expect(remote.wallet, isNull);
      expect(remote.signedIn, isFalse);
      expect(native.methods, ['walletConnect', 'walletDisconnect']);
    },
  );

  for (final code in ['no-wallet', 'wallet-declined']) {
    test(
      '$code exits cleanly without pretending a wallet is connected',
      () async {
        native.connections.add(() async => throw PlatformException(code: code));
        await expectLater(
          remote.connect(),
          throwsA(isA<PlatformException>().having((e) => e.code, 'code', code)),
        );
        expect(remote.signedIn, isFalse);
        expect(remote.wallet, isNull);
        expect(remote.activityLoading, isFalse);
        expect(native.methods, ['walletConnect']);
      },
    );
  }

  test(
    'a declined account switch preserves the previously authorized wallet',
    () async {
      native.connections.add(() async => account(1));
      await remote.connect();
      native.connections.add(
        () async => throw PlatformException(code: 'wallet-declined'),
      );
      await expectLater(remote.connect(), throwsA(isA<PlatformException>()));
      expect(remote.wallet, address(1));
      expect(remote.signedIn, isTrue);
    },
  );
}
