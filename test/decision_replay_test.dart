import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:seeker_workroom/data/reflection_assistant.dart';
import 'package:seeker_workroom/data/repository.dart';
import 'package:seeker_workroom/data/remote.dart';
import 'package:seeker_workroom/domain/controller.dart';
import 'package:seeker_workroom/domain/trade_journal.dart';
import 'package:seeker_workroom/platform/native.dart';
import 'package:seeker_workroom/ui/app.dart';
import 'controller_test.dart' show FakeClock;
import 'trade_journal_test.dart' show entry;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'SQLite upgrade preserves legacy reason before edit and replay survives restart',
    () async {
      sqfliteFfiInit();
      final dir = await Directory.systemTemp.createTemp('record-replay-');
      final dbPath = '${dir.path}/record.sqlite';
      var repo = await LocalRepository.open(
        databasePath: dbPath,
        factory: databaseFactoryFfi,
      );
      final legacyNotes = Map<String, dynamic>.from(entry.notes)
        ..removeWhere(
          (key, _) => ![
            'projectId',
            'reason',
            'plan',
            'emotion',
            'review',
            'nextAction',
          ].contains(key),
        );
      await repo.database.insert('trade_journals', {
        'id': entry.id,
        'wallet': entry.wallet,
        'signature': entry.signature,
        'snapshot': jsonEncode(entry.activity.toJson()),
        'notes': jsonEncode(legacyNotes),
        'created_at': entry.createdAt,
        'updated_at': entry.updatedAt,
      });
      final legacy = (await repo.readJournals()).single;
      await repo.saveJournal(
        legacy.edit(
          reason: 'I changed my explanation',
          reviewDueAt: 100,
          updatedAt: 2,
        ),
      );
      final edited = (await repo.readJournals()).single;
      expect(edited.originalReason, entry.reason);
      expect(edited.baselineSavedAt, entry.updatedAt);
      expect(edited.isDue(99), isFalse);
      expect(edited.isDue(100), isTrue);
      await repo.saveJournal(
        edited.edit(
          review: 'The experience differed',
          decisionRule: 'Check the feature first',
          reviewedAt: 101,
          ruleSavedAt: 101,
          updatedAt: 101,
        ),
      );
      await repo.database.close();
      repo = await LocalRepository.open(
        databasePath: dbPath,
        factory: databaseFactoryFfi,
      );
      final reopened = (await repo.readJournals()).single;
      expect(reopened.originalReason, entry.reason);
      expect(reopened.reason, 'I changed my explanation');
      expect(reopened.decisionRule, 'Check the feature first');
      expect(reopened.isDue(1000), isFalse);
      expect(reopened.activity.toJson(), entry.activity.toJson());
      // An incoming replacement cannot tamper with the already stored baseline.
      await repo.saveJournal(
        TradeJournalEntry.fromJson({
          ...reopened.toJson(),
          'originalReason': 'forged',
        }),
      );
      expect((await repo.readJournals()).single.originalReason, entry.reason);
      expect(await repo.rawExport(), contains('Check the feature first'));
      await repo.database.close();
      await dir.delete(recursive: true);
    },
  );

  test(
    'new records preserve first saved words and explicit null clears revisit date',
    () async {
      final repo = MemoryRepository();
      await repo.saveJournal(entry.edit(reviewDueAt: 42, updatedAt: 2));
      var saved = (await repo.readJournals()).single;
      expect(saved.originalReason, entry.reason);
      await repo.saveJournal(
        saved.edit(reason: 'New wording', reviewDueAt: null, updatedAt: 3),
      );
      saved = (await repo.readJournals()).single;
      expect(saved.originalReason, entry.reason);
      expect(saved.reviewDueAt, isNull);
    },
  );

  test(
    'a lesson completes a revisit and later edits keep its first completion',
    () {
      final completed = entry.reflect(
        reflection: '',
        lesson: '  Check the assumption first.  ',
        assistant: null,
        now: 100,
      );
      expect(completed.reviewedAt, 100);
      expect(completed.ruleSavedAt, 100);
      expect(completed.decisionRule, 'Check the assumption first.');
      expect(
        completed.edit(reviewDueAt: 1, updatedAt: 100).isDue(101),
        isFalse,
      );
      final edited = completed.reflect(
        reflection: 'A clearer reason helped.',
        lesson: 'Check the assumption first.',
        assistant: null,
        now: 200,
      );
      expect(edited.reviewedAt, 100);
      expect(edited.ruleSavedAt, 100);
      final changed = edited.reflect(
        reflection: edited.review,
        lesson: 'Check two assumptions.',
        assistant: null,
        now: 300,
      );
      expect(changed.reviewedAt, 100);
      expect(changed.ruleSavedAt, 300);
    },
  );

  testWidgets(
    'home opens the oldest due reason directly and saves a lesson alone',
    (tester) async {
      tester.view.physicalSize = const Size(430, 960);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = MemoryRepository();
      await repo.saveJournal(entry.edit(reviewDueAt: 1, updatedAt: 2));
      final c = WorkroomController(repo, FakeClock());
      await c.load();
      await c.setting('roomWelcome', 1);
      await c.setting('reduceMotion', true);
      final remote = RemoteService(NativePlatform(), c);
      await tester.pumpWidget(WorkroomApp(controller: c, remote: remote));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('decision-replay-open')),
      );
      await tester.tap(find.byKey(const ValueKey('decision-replay-open')));
      await tester.pumpAndSettle();
      expect(find.text('Reflect on your decision'), findsOneWidget);
      expect(find.text(entry.reason), findsOneWidget);
      await tester.ensureVisible(find.text('Save on this device'));
      await tester.tap(find.text('Save on this device'));
      await tester.pumpAndSettle();
      expect(
        find.text('Add a reflection or a lesson before saving.'),
        findsOneWidget,
      );
      expect(c.journals.entries.single.reviewedAt, isNull);
      await tester.ensureVisible(find.byKey(const ValueKey('decision-rule')));
      await tester.enterText(
        find.byKey(const ValueKey('decision-rule')),
        'Check one assumption.',
      );
      await tester.ensureVisible(find.text('Save on this device'));
      await tester.tap(find.text('Save on this device'));
      await tester.pumpAndSettle();
      expect(c.journals.entries.single.reviewedAt, isNotNull);
      expect(c.journals.entries.single.originalReason, entry.reason);
      expect(find.text('Revisit my reason'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      remote.dispose();
      c.dispose();
    },
  );

  testWidgets('a due date updates an open home without a focus session', (
    tester,
  ) async {
    var wall = DateTime.utc(2026, 10, 1);
    final repo = MemoryRepository();
    await repo.saveJournal(
      entry.edit(
        reviewDueAt: wall
            .add(const Duration(seconds: 2))
            .millisecondsSinceEpoch,
        updatedAt: 2,
      ),
    );
    final c = WorkroomController(repo, FakeClock(), wallClock: () => wall);
    await c.load();
    await c.setting('roomWelcome', 1);
    await c.setting('reduceMotion', true);
    final remote = RemoteService(NativePlatform(), c);
    await tester.pumpWidget(WorkroomApp(controller: c, remote: remote));
    await tester.pumpAndSettle();
    expect(find.text('Revisit my reason'), findsNothing);
    wall = wall.add(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Revisit my reason'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    remote.dispose();
    c.dispose();
  });

  test(
    'assistant sends bounded writing only and rejects invalid model output',
    () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      Map<dynamic, dynamic>? args;
      var question = 3;
      messenger.setMockMethodCallHandler(ReflectionAssistant.channel, (
        call,
      ) async {
        args = call.arguments as Map<dynamic, dynamic>;
        return {'questionId': question, 'durationMs': 500};
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(
          ReflectionAssistant.channel,
          null,
        ),
      );
      final context = ReflectionAssistant.contextFor(
        '한글🙂' * 300,
        'my plan',
        'peer pressure',
      );
      final decoded = jsonDecode(context) as Map;
      expect((decoded['reason'] as String).runes.length, 140);
      final selection = await const ReflectionAssistant().suggest(context);
      expect(selection['questionId'], 3);
      expect(args!.keys, ['context']);
      expect(selection['context'], context);
      question = 9;
      await expectLater(
        const ReflectionAssistant().suggest(context),
        throwsA(isA<PlatformException>()),
      );
    },
  );

  testWidgets(
    'due choice opens comparison and saves a personal lesson without a wallet',
    (tester) async {
      tester.view.physicalSize = const Size(430, 960);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = MemoryRepository();
      await repo.saveJournal(entry.edit(reviewDueAt: 1, updatedAt: 2));
      final c = WorkroomController(repo, FakeClock());
      await c.load();
      await c.setting('roomWelcome', 1);
      await c.setting('reduceMotion', true);
      final remote = RemoteService(NativePlatform(), c);
      await tester.pumpWidget(WorkroomApp(controller: c, remote: remote));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('1 notes to revisit'));
      await tester.tap(find.text('1 notes to revisit'));
      await tester.pumpAndSettle();
      expect(find.text('A choice to revisit today'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('decision-replay-open')));
      await tester.pumpAndSettle();
      expect(find.text(entry.reason), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('review')),
        'I learned what I needed.',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('decision-rule')));
      await tester.enterText(
        find.byKey(const ValueKey('decision-rule')),
        'Check one feature before choosing.',
      );
      await tester.ensureVisible(find.text('Save on this device'));
      await tester.tap(find.text('Save on this device'));
      await tester.pumpAndSettle();
      expect(
        c.journals.entries.single.decisionRule,
        'Check one feature before choosing.',
      );
      expect(c.journals.entries.single.originalReason, entry.reason);
      expect(c.journals.entries.single.reviewedAt, isNotNull);
      expect(find.text('A choice to revisit today'), findsNothing);
      expect(find.text('Saved lessons (1)'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      remote.dispose();
      c.dispose();
    },
  );

  testWidgets('ambiguous AI requires a choice and rejects a stale suggestion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(ReflectionAssistant.channel, (
      call,
    ) async {
      if (call.method == 'status') return {'supported': true, 'ready': true};
      if (call.method == 'suggest') {
        return {
          'questionId': 3,
          'alternativeId': 1,
          'uncertain': true,
          'durationMs': 80,
        };
      }
      return null;
    });
    addTearDown(
      () =>
          messenger.setMockMethodCallHandler(ReflectionAssistant.channel, null),
    );
    final repo = MemoryRepository();
    await repo.saveJournal(entry.edit(reviewDueAt: 1, updatedAt: 2));
    final c = WorkroomController(repo, FakeClock());
    await c.load();
    await c.setting('roomWelcome', 1);
    await c.setting('reduceMotion', true);
    final remote = RemoteService(NativePlatform(), c);
    await tester.pumpWidget(WorkroomApp(controller: c, remote: remote));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('1 notes to revisit'));
    await tester.tap(find.text('1 notes to revisit'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('decision-replay-open')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('review')),
      'Other people influenced me.',
    );
    Future<void> suggest() async {
      await tester.ensureVisible(find.text('Choose a question for my note'));
      await tester.tap(find.text('Choose a question for my note'));
      await tester.pumpAndSettle();
    }

    await suggest();
    expect(
      find.text('Two directions may fit. Choose what you want to explore.'),
      findsOneWidget,
    );
    expect(find.text('Your choice from AI suggestions'), findsNothing);
    await tester.ensureVisible(find.byKey(const ValueKey('review')));
    await tester.enterText(
      find.byKey(const ValueKey('review')),
      'My motive was unclear.',
    );
    await tester.pumpAndSettle();
    final motive = find.text(
      'What did you want to find out by making this choice?',
    );
    expect(motive, findsNothing);
    expect(
      find.text('Your writing changed. Choose a question again.'),
      findsOneWidget,
    );
    await suggest();
    await tester.ensureVisible(motive);
    await tester.tap(motive);
    await tester.pumpAndSettle();
    expect(find.text('Your choice from AI suggestions'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('review')));
    await tester.enterText(
      find.byKey(const ValueKey('review')),
      'A different reason now.',
    );
    await tester.pumpAndSettle();
    expect(find.text('Your choice from AI suggestions'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    remote.dispose();
    c.dispose();
  });
}
