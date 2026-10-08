import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seeker_workroom/data/reflection_assistant.dart';
import 'package:seeker_workroom/data/repository.dart';
import 'package:seeker_workroom/domain/controller.dart';
import 'package:seeker_workroom/domain/trade_journal.dart';
import 'package:seeker_workroom/platform/native.dart';
import 'package:seeker_workroom/ui/app.dart';
import 'controller_test.dart' show FakeClock;
import 'trade_journal_test.dart' show entry, activity;
import 'trade_journal_widget_test.dart' show FakeRemote;

class OfflineRecallRemote extends FakeRemote {
  OfflineRecallRemote(super.native, super.local);
  int calls = 0;
  @override
  Future<void> connect() async {
    calls++;
    throw StateError('Recall must not connect a wallet');
  }

  @override
  Future<Map<String, dynamic>> call(
    String action, [
    Map<String, dynamic> body = const {},
    bool authenticated = true,
  ]) async {
    calls++;
    throw StateError('Recall must not fetch activity');
  }
}

class RetryRecallRepository extends MemoryRepository {
  bool fail = true;
  Completer<void>? gate;
  @override
  Future<List<TradeJournalEntry>> readJournals() async {
    if (fail) throw StateError('Local read failed');
    await gate?.future;
    return super.readJournals();
  }
}

TradeJournalEntry note(String wallet) => TradeJournalEntry.fromJson({
  ...entry.toJson(),
  'id': wallet,
  'wallet': wallet,
  'activity': {...activity.toJson(), 'signature': 'source-$wallet'},
  'reason': 'Original $wallet',
  'originalReason': 'Original $wallet',
  'review': 'Reflection $wallet',
  'decisionRule': 'Lesson $wallet',
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(
    () => messenger.setMockMethodCallHandler(ReflectionAssistant.channel, null),
  );

  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<(WorkroomController, OfflineRecallRemote)> show(
    WidgetTester tester, {
    bool empty = false,
    Repository? repository,
  }) async {
    tester.view.physicalSize = const Size(500, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = WorkroomController(repository ?? MemoryRepository(), FakeClock());
    await c.load();
    await c.setting('roomWelcome', 1);
    await c.setting('reduceMotion', true);
    await c.setting('language', 'en');
    if (!empty) {
      await c.journals.save(note('wallet-a'));
      await c.journals.save(note('wallet-b'));
    }
    final r = OfflineRecallRemote(NativePlatform(), c);
    await tester.pumpWidget(WorkroomApp(controller: c, remote: r));
    await tester.pumpAndSettle();
    await tap(tester, find.byKey(const ValueKey('home-recall-open')));
    return (c, r);
  }

  Future<void> select(WidgetTester tester, String wallet) async {
    await tap(tester, find.byKey(const ValueKey('recall-wallet')));
    await tap(tester, find.text(wallet).last);
  }

  Future<void> query(WidgetTester tester, String value) async {
    final field = find.byKey(const ValueKey('recall-query'));
    await tester.ensureVisible(field);
    await tester.enterText(field, value);
    await tester.pumpAndSettle();
  }

  testWidgets('home recall is available before any saved activity', (
    tester,
  ) async {
    final (_, r) = await show(tester, empty: true);
    expect(find.text('No saved records on this device yet.'), findsOneWidget);
    expect(find.byKey(const ValueKey('recall-query')), findsNothing);
    expect(r.calls, 0);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-recall-open')), findsOneWidget);
  });

  testWidgets('local read errors are not empty states and retry recovers', (
    tester,
  ) async {
    final repository = RetryRecallRepository();
    await repository.saveJournal(note('wallet-a'));
    final (_, r) = await show(tester, empty: true, repository: repository);
    expect(
      find.textContaining('Your journals could not be read'),
      findsOneWidget,
    );
    expect(find.text('No saved records on this device yet.'), findsNothing);
    expect(find.byKey(const ValueKey('recall-wallet')), findsNothing);
    repository.fail = false;
    repository.gate = Completer<void>();
    await tester.tap(find.byKey(const ValueKey('recall-retry')));
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    repository.gate!.complete();
    await tester.pumpAndSettle();
    await select(tester, 'wallet-a');
    await tap(tester, find.text('Browse saved records'));
    expect(find.text('Original wallet-a'), findsOneWidget);
    expect(
      find.textContaining('Your journals could not be read'),
      findsNothing,
    );
    expect(r.calls, 0);
  });

  testWidgets(
    'explicit wallet scope and exact originals work without AI or RPC',
    (tester) async {
      final (_, r) = await show(tester);
      expect(find.byKey(const ValueKey('recall-query')), findsNothing);
      expect(find.text('Original wallet-a'), findsNothing);
      await select(tester, 'wallet-a');
      await tap(tester, find.text('Browse saved records'));
      expect(find.text('Original wallet-a'), findsOneWidget);
      expect(find.text('Original wallet-b'), findsNothing);
      await tap(tester, find.text('Original wallet-a'));
      expect(find.text('Your original record'), findsOneWidget);
      expect(find.text('Reflection wallet-a'), findsOneWidget);
      expect(find.text('Lesson wallet-a'), findsOneWidget);
      expect(find.text('Original wallet-b'), findsNothing);
      await tap(tester, find.byTooltip('Close'));
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const ValueKey('home-recall-open')));
      expect(find.byKey(const ValueKey('recall-query')), findsNothing);
      expect(r.calls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('missing model and no match both retain manual browsing', (
    tester,
  ) async {
    final (_, r) = await show(tester);
    await select(tester, 'wallet-a');
    await query(tester, 'What did I learn?');
    messenger.setMockMethodCallHandler(ReflectionAssistant.channel, (_) async {
      throw PlatformException(code: 'model-missing');
    });
    await tap(tester, find.byKey(const ValueKey('related-records-search')));
    expect(find.textContaining('Set up AI in Settings'), findsOneWidget);
    messenger.setMockMethodCallHandler(ReflectionAssistant.channel, (
      call,
    ) async {
      expect(call.method, 'rank');
      return {
        'scores': [.5],
      };
    });
    await tap(tester, find.byKey(const ValueKey('related-records-search')));
    expect(find.textContaining('No close record found'), findsOneWidget);
    await tap(tester, find.text('Browse saved records'));
    expect(find.text('Original wallet-a'), findsOneWidget);
    expect(r.calls, 0);
  });

  testWidgets(
    'wallet switch clears query and blocks a late old-wallet result',
    (tester) async {
      final (_, r) = await show(tester);
      await select(tester, 'wallet-a');
      final pending = Completer<Map<String, dynamic>>();
      var cancels = 0;
      final payloads = <Map<dynamic, dynamic>>[];
      messenger.setMockMethodCallHandler(ReflectionAssistant.channel, (
        call,
      ) async {
        if (call.method == 'cancel') {
          cancels++;
          return null;
        }
        payloads.add(Map.of(call.arguments as Map));
        return payloads.length == 1
            ? pending.future
            : {
                'scores': [.91],
              };
      });
      await query(tester, 'Private query for wallet A');
      await tester.tap(find.byKey(const ValueKey('related-records-search')));
      await tester.pump();
      // No pumpAndSettle until cancellation: progress is intentionally active.
      await tester.ensureVisible(find.byKey(const ValueKey('recall-wallet')));
      await tester.tap(find.byKey(const ValueKey('recall-wallet')));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('wallet-b').last);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('recall-query')))
            .controller!
            .text,
        isEmpty,
      );
      expect(cancels, greaterThan(0));
      pending.complete({
        'scores': [.99],
      });
      await tester.pumpAndSettle();
      expect(find.text('Original wallet-a'), findsNothing);
      await query(tester, 'Private query for wallet B');
      await tap(tester, find.byKey(const ValueKey('related-records-search')));
      expect(payloads.last['query'], 'Private query for wallet B');
      expect(
        payloads.last['records'].toString(),
        contains('Original wallet-b'),
      );
      expect(payloads.last.toString(), isNot(contains('wallet-a')));
      expect(find.text('Original wallet-b'), findsOneWidget);
      expect(r.calls, 0);
    },
  );

  testWidgets(
    'changed query, cancel, record deletion and close reject stale work',
    (tester) async {
      final (c, _) = await show(tester);
      await select(tester, 'wallet-a');
      final pending = <Completer<Map<String, dynamic>>>[];
      messenger.setMockMethodCallHandler(ReflectionAssistant.channel, (
        call,
      ) async {
        if (call.method == 'cancel') return null;
        final request = Completer<Map<String, dynamic>>();
        pending.add(request);
        return request.future;
      });
      Future<void> start(String value) async {
        await query(tester, value);
        await tester.ensureVisible(
          find.byKey(const ValueKey('related-records-search')),
        );
        await tester.tap(find.byKey(const ValueKey('related-records-search')));
        await tester.pump();
      }

      await start('First query');
      await tester.tap(find.byKey(const ValueKey('related-records-search')));
      await tester.pump();
      expect(pending, hasLength(1));
      await query(tester, 'Changed query');
      pending.last.complete({
        'scores': [.99],
      });
      await tester.pumpAndSettle();
      expect(find.text('Original wallet-a'), findsNothing);
      await start('Second query');
      await tap(tester, find.text('Cancel'));
      pending.last.completeError(PlatformException(code: 'model-missing'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Set up AI in Settings'), findsNothing);
      await start('Third query');
      await c.journals.delete('wallet-a');
      await tester.pumpAndSettle();
      pending.last.complete({
        'scores': [.99],
      });
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('recall-query')), findsNothing);
      await select(tester, 'wallet-b');
      await start('Fourth query');
      await tester.pageBack();
      await tester.pumpAndSettle();
      pending.last.complete({
        'scores': [.99],
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
