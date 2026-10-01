import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';
import 'package:seeker_workroom/data/direct_activity.dart';
import 'package:seeker_workroom/data/remote.dart';
import 'package:seeker_workroom/data/repository.dart';
import 'package:seeker_workroom/domain/controller.dart';
import 'package:seeker_workroom/platform/native.dart';
import 'package:seeker_workroom/ui/app.dart';
import 'fixtures/trade_activity.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'current room: parsed fixture, reason, revisit, lesson, SQLite restart and export',
    (tester) async {
      final dir = await Directory.systemTemp.createTemp('record-replay-demo-');
      final dbPath = '${dir.path}/replay.sqlite';
      var repository = await LocalRepository.open(databasePath: dbPath);
      final native = NativePlatform();
      var wall = DateTime.utc(2026, 10, 1, 8);
      var c = WorkroomController(repository, native, wallClock: () => wall);
      await c.load();
      // Continuous room animations are covered separately. Freeze them here so
      // pumpAndSettle can deterministically verify the actual persistence flow.
      await c.setting('reduceMotion', true);
      final methods = <String>[];
      RemoteService fixtureRemote(WorkroomController controller) {
        final client = DirectActivityClient(
          client: MockClient((request) async {
            final rpc = jsonDecode(request.body) as Map;
            methods.add(rpc['method'] as String);
            final result = switch (rpc['method']) {
              'getSignaturesForAddress' => [fixtureSignatureInfo()],
              'getTransaction' => fixtureTransaction(),
              _ => throw StateError('Unexpected RPC method'),
            };
            // Transport fixture only. The actual production RPC reader and parser run.
            return http.Response(
              jsonEncode({'jsonrpc': '2.0', 'id': 1, 'result': result}),
              200,
            );
          }),
        );
        return RemoteService(native, controller, activityClient: client)
          ..initialized = true
          ..wallet = fixtureWallet;
      }

      var remote = fixtureRemote(c);
      final label = ValueNotifier(
        'SYNTHETIC RPC FIXTURE · EMULATOR · NOT A LIVE TRADE',
      );
      Widget app() => ValueListenableBuilder<String>(
        valueListenable: label,
        builder: (context, value, _) => Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              Container(
                color: const Color(0xFFFFE9A7),
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(8, 30, 8, 8),
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF191F28),
                  ),
                ),
              ),
              Expanded(
                child: WorkroomApp(controller: c, remote: remote),
              ),
            ],
          ),
        ),
      );
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await binding.convertFlutterSurfaceToImage();
      Future<void> shot(String name) async {
        await tester.pumpAndSettle();
        await binding.takeScreenshot('052-$name');
        await Future<void>.delayed(const Duration(seconds: 1));
      }

      Future<void> tap(String text) async {
        final target = find.text(text).first;
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      Future<void> back() async {
        await tester.pageBack();
        await tester.pumpAndSettle();
      }

      await shot('01-welcome');
      await tap('Skip');
      await shot('02-room');
      await tap('Leave a reason');
      await shot('03-parsed-swap');
      expect(remote.activities.single.input!.amount, '250');
      expect(remote.activities.single.output!.amount, '1.42');
      expect(methods, ['getSignaturesForAddress', 'getTransaction']);
      await tap('Write reflection');
      const reason =
          'I wanted to test a small position after checking the project.';
      await tester.enterText(find.byKey(const ValueKey(0)), reason);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tap('In 1 day');
      await shot('04-reason');
      await tap('Save reason');
      expect(c.journals.entries.single.originalReason, reason);
      await shot('05-saved');
      await tap('Recorded · Open journal');
      await shot('06-original-reason');
      await tap('Edit notes');
      await tester.enterText(
        find.byKey(const ValueKey(0)),
        'A later explanation, edited after saving.',
      );
      await tap('Save reason');
      expect(c.journals.entries.single.originalReason, reason);
      await shot('07-baseline-preserved');
      await back();
      await back();
      label.value = 'SYNTHETIC FIXTURE · CLOCK ADVANCED 1 DAY FOR REVISIT';
      wall = wall.add(const Duration(days: 1, seconds: 1));
      await c.refresh();
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('decision-replay-open')),
      );
      await shot('08-due-at-home');
      await tap('Revisit my reason');
      await shot('09-compare');
      await tester.enterText(
        find.byKey(const ValueKey('review')),
        'The project was interesting, but I had not checked my exit assumption.',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tap('Choose a question myself');
      await tap(
        'What is one small thing you will check before your next choice?',
      );
      const lesson = 'Write an exit assumption before choosing a position.';
      await tester.ensureVisible(find.byKey(const ValueKey('decision-rule')));
      await tester.enterText(
        find.byKey(const ValueKey('decision-rule')),
        lesson,
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await shot('10-reflection-and-lesson');
      await tap('Save on this device');
      expect(c.journals.entries.single.reviewedAt, isNotNull);
      expect(c.journals.entries.single.decisionRule, lesson);
      await tap('Time to reflect');
      await tap('Saved lessons (1)');
      await tester.ensureVisible(find.text(lesson));
      await shot('11-saved-lesson');
      final exported = jsonDecode(c.exportJson()) as Map;
      expect(exported['tradeJournals'][0]['originalReason'], reason);
      expect(exported['tradeJournals'][0]['decisionRule'], lesson);
      expect(
        exported['tradeJournals'][0]['assistantSelection']['source'],
        'manual',
      );

      await tester.pumpWidget(const SizedBox());
      remote.dispose();
      c.dispose();
      await repository.database.close();
      repository = await LocalRepository.open(databasePath: dbPath);
      c = WorkroomController(repository, native, wallClock: () => wall);
      await c.load();
      remote = fixtureRemote(c);
      expect(c.journals.entries.single.originalReason, reason);
      expect(c.journals.entries.single.decisionRule, lesson);
      expect(c.state.settings['roomWelcome'], 1);
      label.value = 'SYNTHETIC FIXTURE · REAL SQLITE CLOSE AND REOPEN';
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tap('Time to reflect');
      await tap('Saved lessons (1)');
      await tester.ensureVisible(find.text(lesson));
      await shot('12-restart-preserves-lesson');
      final sourceRecord = find.textContaining('Open source record');
      await tester.ensureVisible(sourceRecord);
      await tester.tap(sourceRecord);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Export this record'));
      await shot('13-export-control');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      remote.dispose();
      c.dispose();
      label.dispose();
      await repository.database.close();
      await dir.delete(recursive: true);
    },
  );
}
