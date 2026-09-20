import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:seeker_workroom/data/remote.dart';
import 'package:seeker_workroom/data/repository.dart';
import 'package:seeker_workroom/domain/controller.dart';
import 'package:seeker_workroom/platform/native.dart';
import 'controller_test.dart' show FakeClock;
import 'trade_journal_test.dart' show activity;

class ControlledRemote extends RemoteService {
  ControlledRemote(super.native, super.local) : super(directWalletEnabled: false) {
    wallet = 'alice';
  }
  Completer<Map<String, dynamic>> pending = Completer();
  @override
  bool get signedIn => wallet != null;
  @override
  String? get uid => wallet;
  @override
  Future<Map<String, dynamic>> call(
    String action, [
    Map<String, dynamic> body = const {},
    bool authenticated = true,
  ]) => pending.future;
}

void main() {
  test(
    'a stale profile cannot expose the previous wallet after an account change',
    () async {
      final c = WorkroomController(MemoryRepository(), FakeClock());
      final r = ControlledRemote(NativePlatform(), c);
      final request = r.profile();
      r.wallet = 'bob';
      r.pending.complete({'wallet': 'alice', 'entitlement': true});
      await request;
      expect(r.wallet, 'bob');
      expect(r.owned, isFalse);
      r.dispose();
      c.dispose();
    },
  );
  test(
    'a stale purchase response does not erase a newer pending order',
    () async {
      final c = WorkroomController(MemoryRepository(), FakeClock());
      final r = ControlledRemote(NativePlatform(), c);
      await c.mutate(
        (s) => s.pendingOrder = {'orderId': 'old', 'wallet': 'alice'},
      );
      final request = r.checkOrder();
      await c.mutate(
        (s) => s.pendingOrder = {'orderId': 'new', 'wallet': 'alice'},
      );
      r.pending.complete({'status': 'expired'});
      await request;
      expect(c.state.pendingOrder?['orderId'], 'new');
      r.dispose();
      c.dispose();
    },
  );
  test(
    'disposed activity requests can finish without notifying a dead screen',
    () async {
      final c = WorkroomController(MemoryRepository(), FakeClock());
      final r = ControlledRemote(NativePlatform(), c);
      final request = r.loadActivity();
      r.dispose();
      r.pending.complete({'wallet': 'alice', 'items': [], 'nextCursor': null});
      await request;
      c.dispose();
    },
  );
  test(
    'account changes discard in-flight activity without leaving loading stuck',
    () async {
      final c = WorkroomController(MemoryRepository(), FakeClock());
      final r = ControlledRemote(NativePlatform(), c);
      final old = r.loadActivity();
      r.wallet = 'bob';
      r.clearActivity();
      r.pending.complete({
        'wallet': 'alice',
        'items': [activity.toJson()],
        'nextCursor': null,
      });
      await old;
      expect(r.activities, isEmpty);
      expect(r.activityLoading, isFalse);
      r.pending = Completer();
      final fresh = r.loadActivity();
      r.pending.complete({'wallet': 'bob', 'items': [], 'nextCursor': null});
      await fresh;
      expect(r.activityLoaded, isTrue);
      expect(r.activityError, isNull);
      r.dispose();
      c.dispose();
    },
  );
  test(
    'pagination failure preserves existing rows and cursor for retry',
    () async {
      final c = WorkroomController(MemoryRepository(), FakeClock());
      final r = ControlledRemote(NativePlatform(), c);
      final first = r.loadActivity();
      r.pending.complete({
        'wallet': 'alice',
        'items': [activity.toJson()],
        'nextCursor': 'older',
      });
      await first;
      r.pending = Completer();
      final more = r.loadActivity(more: true);
      r.pending.completeError(ServiceError('rpc-timeout'));
      await more;
      expect(r.activities.single.signature, activity.signature);
      expect(r.activityCursor, 'older');
      expect(r.activityError, 'rpc-timeout');
      expect(r.activityLoading, isFalse);
      r.pending = Completer();
      final retry = r.loadActivity(more: true);
      r.pending.complete({
        'wallet': 'alice',
        'items': [activity.toJson()],
        'nextCursor': null,
      });
      await retry;
      expect(r.activities, hasLength(1));
      expect(r.activityError, isNull);
      r.dispose();
      c.dispose();
    },
  );
}
