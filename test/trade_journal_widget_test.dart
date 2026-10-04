import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seeker_workroom/data/remote.dart';
import 'package:seeker_workroom/data/repository.dart';
import 'package:seeker_workroom/domain/controller.dart';
import 'package:seeker_workroom/platform/native.dart';
import 'package:seeker_workroom/ui/app.dart';
import 'package:seeker_workroom/data/reflection_assistant.dart';
import 'package:seeker_workroom/domain/trade_journal.dart';
import 'controller_test.dart' show FakeClock;
import 'trade_journal_test.dart' show activity, entry;

class FakeRemote extends RemoteService {
  FakeRemote(super.native, super.local, {this.connected = false}) {
    initialized = true;
    if (connected) wallet = 'wallet-1';
  }
  @override
  bool get onlineAvailable => true;
  bool connected;
  String? failure;
  List<Map<String, dynamic>> rows = [];
  @override
  bool get signedIn => connected;
  @override
  String? get uid => connected ? 'user-1' : null;
  @override
  Future<void> connect() async {
    connected = true;
    wallet = 'wallet-1';
    notifyListeners();
  }

  @override
  Future<Map<String, dynamic>> call(
    String action, [
    Map<String, dynamic> body = const {},
    bool authenticated = true,
  ]) async {
    if (failure != null) throw ServiceError(failure!);
    return {'wallet': wallet, 'items': rows, 'nextCursor': null};
  }

  @override
  Future<void> currentRoom() async {}
}

void main() {
  Future<(WorkroomController, FakeRemote)> show(
    WidgetTester tester, {
    bool connected = false,
    List<Map<String, dynamic>>? rows,
    String? failure,
  }) async {
    tester.view.physicalSize = const Size(500, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = WorkroomController(
      MemoryRepository(),
      FakeClock(),
      wallClock: () => DateTime(2026, 9, 28, 10),
    );
    await c.load();
    await c.setting('roomWelcome', 1);
    await c.setting('reduceMotion', true);
    await c.setting('language', 'en');
    final r = FakeRemote(NativePlatform(), c, connected: connected)
      ..rows = rows ?? []
      ..failure = failure;
    await tester.pumpWidget(WorkroomApp(controller: c, remote: r));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(NavigationDestination).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trade journal'));
    await tester.pumpAndSettle();
    return (c, r);
  }

  testWidgets('home new-reason action opens activity even with saved notes', (
    tester,
  ) async {
    final (c, _) = await show(
      tester,
      connected: true,
      rows: [activity.toJson()],
    );
    await c.journals.save(entry);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(NavigationDestination).first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('decision-replay-open')),
    );
    await tester.tap(find.byKey(const ValueKey('decision-replay-open')));
    await tester.pumpAndSettle();
    expect(find.text('Recent wallet activity'), findsOneWidget);
    expect(find.text('Saved on this device'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'returning readers see original reason and a reachable revisit action',
    (tester) async {
      final (c, _) = await show(
        tester,
        connected: true,
        rows: [activity.toJson()],
      );
      await c.journals.save(
        TradeJournalEntry.fromJson({
          ...entry.toJson(),
          'originalReason': 'Original reason worth remembering',
          'reason': 'A later edit',
          'decisionRule': 'Check one original source',
        }),
      );
      await tester.pumpAndSettle();
      expect(find.text('Original reason worth remembering'), findsOneWidget);
      expect(find.text('A later edit'), findsNothing);
      expect(find.text('Recent wallet activity'), findsNothing);
      await tester.ensureVisible(find.text('Recorded · Open journal'));
      await tester.tap(find.text('Recorded · Open journal'));
      await tester.pumpAndSettle();
      final action = tester.getRect(find.text('Reflect'));
      expect(action.bottom, lessThan(1100));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'unclassified activity opens a labeled note and completes reflection',
    (tester) async {
      final other = {
        ...activity.toJson(),
        'type': 'other',
        'source': null,
        'input': null,
        'output': null,
        'issue': 'unsupported-activity',
      };
      final (c, r) = await show(tester, connected: true, rows: [other]);
      expect(find.text('Other wallet activity'), findsOneWidget);
      expect(find.text('Write reflection'), findsNothing);
      await tester.ensureVisible(find.text('Add a personal note'));
      await tester.tap(find.text('Add a personal note'));
      await tester.pumpAndSettle();
      expect(find.text('Wallet activity note'), findsOneWidget);
      expect(find.text('1 / 4'), findsNothing);
      expect(find.text('Add details'), findsOneWidget);
      expect(find.text('Why did you make this trade?'), findsNothing);
      expect(
        find.text('What would you like to remember about this activity?'),
        findsOneWidget,
      );
      expect(find.textContaining('its type is unclassified'), findsNothing);
      await tester.tap(find.text('Transaction details'));
      await tester.pumpAndSettle();
      expect(find.textContaining('its type is unclassified'), findsOneWidget);
      await tester.tap(find.text('Transaction details'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey(0)),
        'A demonstration reason.',
      );
      await tester.ensureVisible(find.text('Save reason'));
      await tester.tap(find.text('Save reason'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Recorded · Open journal').first);
      await tester.tap(find.text('Recorded · Open journal').first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Reflect'));
      await tester.tap(find.text('Reflect'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('decision-rule')));
      await tester.enterText(
        find.byKey(const ValueKey('decision-rule')),
        'Check the source before the next choice.',
      );
      await tester.ensureVisible(find.text('Save on this device'));
      await tester.tap(find.text('Save on this device'));
      await tester.pumpAndSettle();
      expect(
        c.journals.entries.single.originalReason,
        'A demonstration reason.',
      );
      expect(c.journals.entries.single.activity.toJson(), other);
      expect(c.journals.entries.single.reviewedAt, isNotNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      r.dispose();
      c.dispose();
    },
  );
  testWidgets('save stays above the keyboard and source details are opt-in', (
    tester,
  ) async {
    final (c, r) = await show(
      tester,
      connected: true,
      rows: [activity.toJson()],
    );
    tester.view.physicalSize = const Size(360, 800);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Write reflection'));
    await tester.tap(find.text('Write reflection'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey(0)),
      'A reason worth keeping.',
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(find.text('Save reason').hitTestable(), findsOneWidget);
    expect(tester.getBottomRight(find.text('Save reason')).dy, lessThan(500));
    await tester.tap(find.text('Save reason'));
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Recorded · Open journal').first);
    await tester.tap(find.text('Recorded · Open journal').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('wallet-1'), findsNothing);
    await tester.tap(find.text('Transaction details'));
    await tester.pumpAndSettle();
    expect(find.textContaining('wallet-1'), findsOneWidget);
    expect(c.journals.entries.single.originalReason, 'A reason worth keeping.');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    r.dispose();
    c.dispose();
  });
  testWidgets('disconnected state explains read-only and opens connection', (
    tester,
  ) async {
    await show(tester);
    expect(
      find.text('Read only. No transfers. Notes stay here.'),
      findsOneWidget,
    );
    expect(find.text('Connect Seeker wallet'), findsOneWidget);
    expect(find.textContaining('Notes stay on this device'), findsOneWidget);
  });
  testWidgets('connected empty history does not claim Seeker verification', (
    tester,
  ) async {
    await show(tester, connected: true);
    expect(find.text('Wallet connected'), findsOneWidget);
    expect(find.text('Seeker Verified'), findsNothing);
    expect(find.textContaining('No activity found yet'), findsOneWidget);
  });
  for (final error in ['rpc-timeout', 'parse-unavailable']) {
    testWidgets('$error gives a retryable visible state', (tester) async {
      await show(tester, connected: true, failure: error);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  }
  testWidgets('optional plan and emotion cannot bypass the first reason', (
    tester,
  ) async {
    final (c, _) = await show(
      tester,
      connected: true,
      rows: [activity.toJson()],
    );
    await tester.ensureVisible(find.text('Write reflection'));
    await tester.tap(find.text('Write reflection'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Add details'));
    await tester.tap(find.text('Add details'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).first,
      'An optional plan alone',
    );
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calm'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save on this device'));
    await tester.tap(find.text('Save on this device'));
    await tester.pumpAndSettle();
    expect(find.text('Add one reason before saving.'), findsOneWidget);
    expect(c.journals.entries, isEmpty);
  });
  testWidgets('export one record includes its source and preserved reason', (
    tester,
  ) async {
    final (c, _) = await show(
      tester,
      connected: true,
      rows: [activity.toJson()],
    );
    await c.journals.save(entry);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Recorded · Open journal').first);
    await tester.tap(find.text('Recorded · Open journal').first);
    await tester.pumpAndSettle();
    String? contents;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(NativePlatform.channel, (call) async {
          if (call.method == 'export') {
            contents = (call.arguments as Map)['content'] as String;
            return true;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(NativePlatform.channel, null),
    );
    await tester.ensureVisible(find.text('Export this record'));
    await tester.tap(find.text('Export this record'));
    await tester.pumpAndSettle();
    expect(contents, contains(entry.reason));
    expect(contents, contains(entry.signature));
    expect(contents, contains('originalReason'));
    expect(contents, contains('schemaVersion'));
    expect(
      find.text('File saved. Your records remain in the app.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('scheduling another date reopens a completed revisit', (
    tester,
  ) async {
    final (c, _) = await show(
      tester,
      connected: true,
      rows: [activity.toJson()],
    );
    await c.journals.save(
      entry.edit(reviewDueAt: 1, reviewedAt: 2, updatedAt: 3),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Recorded · Open journal').first);
    await tester.tap(find.text('Recorded · Open journal').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Edit notes'));
    await tester.tap(find.text('Edit notes'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('In 1 day'));
    await tester.tap(find.text('In 1 day'));
    await tester.ensureVisible(find.text('Save reason'));
    await tester.tap(find.text('Save reason'));
    await tester.pumpAndSettle();
    expect(c.journals.entries.single.reviewedAt, isNull);
    expect(c.journals.entries.single.reviewDueAt, greaterThan(3));
    expect(c.journals.entries.single.originalReason, entry.reason);
  });
  testWidgets(
    'supported swap guided form saves, survives controller reload, edits and deletes',
    (tester) async {
      final (c, r) = await show(
        tester,
        connected: true,
        rows: [activity.toJson()],
      );
      await tester.ensureVisible(find.text('Write reflection'));
      await tester.tap(find.text('Write reflection'));
      await tester.pumpAndSettle();
      expect(find.text('Why did you make this trade?'), findsOneWidget);
      await tester.enterText(
        find.byType(TextField).first,
        'Testing my original thesis',
      );
      await tester.ensureVisible(find.text('Add details'));
      await tester.tap(find.text('Add details'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).first,
        'Check liquidity first',
      );
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Calm'));
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).first,
        'Revisit assumptions',
      );
      await tester.ensureVisible(find.text('Save on this device'));
      await tester.tap(find.text('Save on this device'));
      await tester.pumpAndSettle();
      expect(c.journals.entries.single.reason, 'Testing my original thesis');
      final reopened = WorkroomController(c.repository, FakeClock());
      await reopened.load();
      expect(
        reopened.journals.entries.single.nextAction,
        'Revisit assumptions',
      );
      await tester.ensureVisible(find.text('Recorded · Open journal').first);
      await tester.tap(find.text('Recorded · Open journal').first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Reflect'));
      await tester.tap(find.text('Reflect'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).first,
        'I should have waited',
      );
      await tester.ensureVisible(find.text('Save on this device'));
      await tester.tap(find.text('Save on this device'));
      await tester.pumpAndSettle();
      expect(c.journals.entries.single.review, 'I should have waited');
      await tester.ensureVisible(find.text('Delete journal'));
      await tester.tap(find.text('Delete journal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(c.journals.entries, isEmpty);
      expect(r.activities.single.signature, activity.signature);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'saved local notes remain visible without wallet and failed activity cannot be journaled',
    (tester) async {
      final (c, r) = await show(
        tester,
        connected: true,
        rows: [
          {
            ...activity.toJson(),
            'status': 'failed',
            'type': 'other',
            'input': null,
            'output': null,
          },
        ],
      );
      expect(find.text('Failed transaction'), findsOneWidget);
      expect(find.text('Write reflection'), findsNothing);
      await c.journals.save(entry);
      r.connected = false;
      r.wallet = null;
      r.clearActivity();
      await tester.pumpAndSettle();
      expect(find.text('Recorded · Open journal'), findsOneWidget);
    },
  );
  testWidgets(
    'related records preserve quotes, isolate wallets and clear stale results',
    (tester) async {
      final (c, _) = await show(
        tester,
        connected: true,
        rows: [activity.toJson()],
      );
      for (final wallet in ['wallet-1', 'foreign-wallet']) {
        await c.journals.save(
          TradeJournalEntry.fromJson({
            ...entry.toJson(),
            'id': 'past-$wallet',
            'wallet': wallet,
            'activity': {
              ...activity.toJson(),
              'id': 'past-$wallet',
              'signature': 'past-$wallet',
            },
            'originalReason': wallet == 'wallet-1'
                ? 'Original source words'
                : 'Foreign private words',
            'review': 'A later observation',
            'decisionRule': 'Read the primary source',
          }),
        );
      }
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('journal-activity-tab')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Write reflection'));
      await tester.tap(find.text('Write reflection'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Check my evidence');
      expect(
        find.byKey(const ValueKey('related-records-search')),
        findsNothing,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('related-records-expand')),
      );
      await tester.tap(find.text('A similar choice from your past'));
      await tester.pumpAndSettle();
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(ReflectionAssistant.channel, (
        call,
      ) async {
        expect(call.method, 'rank');
        expect((call.arguments as Map)['records'], hasLength(1));
        expect(
          call.arguments.toString(),
          isNot(contains('Foreign private words')),
        );
        return {
          'scores': [.91],
        };
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(
          ReflectionAssistant.channel,
          null,
        ),
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('related-records-search')),
      );
      await tester.tap(find.byKey(const ValueKey('related-records-search')));
      await tester.pumpAndSettle();
      expect(find.text('Original source words'), findsOneWidget);
      expect(find.text('Foreign private words'), findsNothing);
      await tester.ensureVisible(find.text('Original source words'));
      await tester.tap(find.text('Original source words'));
      await tester.pumpAndSettle();
      expect(find.text('Your original record'), findsOneWidget);
      expect(find.text('A later observation'), findsOneWidget);
      Navigator.of(tester.element(find.text('Your original record'))).pop();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextField).first);
      await tester.enterText(
        find.byType(TextField).first,
        'A different choice',
      );
      await tester.pumpAndSettle();
      expect(find.text('Original source words'), findsNothing);
      messenger.setMockMethodCallHandler(
        ReflectionAssistant.channel,
        (_) async => throw PlatformException(code: 'model-missing'),
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('related-records-search')),
      );
      await tester.tap(find.byKey(const ValueKey('related-records-search')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Set up AI in Settings'), findsOneWidget);
      await tester.ensureVisible(find.text('Browse saved records'));
      await tester.tap(find.text('Browse saved records'));
      await tester.pumpAndSettle();
      expect(find.text('Original source words'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('English journal visual and Korean large text remain usable', (
    tester,
  ) async {
    for (final family in ['NotoSansKR', 'Lora']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    final (c, r) = await show(
      tester,
      connected: true,
      rows: [activity.toJson()],
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/07-trade-journal-en.png'),
    );
    await tester.ensureVisible(find.text('Write reflection'));
    await tester.tap(find.text('Write reflection'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/08-trade-prompt-en.png'),
    );
    await c.setting('language', 'ko');
    tester.view.physicalSize = const Size(360, 800);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('내용 더하기'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    r.dispose();
    c.dispose();
  });
}
