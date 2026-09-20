import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seeker_workroom/data/remote.dart';
import 'package:seeker_workroom/data/repository.dart';
import 'package:seeker_workroom/domain/controller.dart';
import 'package:seeker_workroom/platform/native.dart';
import 'package:seeker_workroom/ui/app.dart';
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
    final c = WorkroomController(MemoryRepository(), FakeClock());
    await c.load();
    await c.setting('language', 'en');
    final r = FakeRemote(NativePlatform(), c, connected: connected)
      ..rows = rows ?? []
      ..failure = failure;
    await tester.pumpWidget(WorkroomApp(controller: c, remote: r));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Journal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trade journal'));
    await tester.pumpAndSettle();
    return (c, r);
  }

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
      await tester.ensureVisible(find.text('Next'));
      await tester.tap(find.text('Next'));
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
    await tester.ensureVisible(find.text('다음'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    r.dispose();
    c.dispose();
  });
}
