import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seeker_workroom/data/related_records.dart';
import 'package:seeker_workroom/data/reflection_assistant.dart';
import 'package:seeker_workroom/domain/trade_journal.dart';
import 'trade_journal_test.dart' show entry;

TradeJournalEntry record(
  String id, {
  String wallet = 'wallet-1',
  int created = 2,
  String reason = 'My original reason',
}) => TradeJournalEntry.fromJson({
  ...entry.toJson(),
  'id': id,
  'wallet': wallet,
  'createdAt': created,
  'originalReason': reason,
  'reason': 'Later edit',
  'review': 'What happened',
  'decisionRule': 'Check source first',
});
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(
    () => messenger.setMockMethodCallHandler(ReflectionAssistant.channel, null),
  );
  test('candidate isolation, exclude self, cap, stable source and unicode', () {
    final candidates = RelatedRecords.candidates(
      [
        record('self'),
        record('foreign', wallet: 'other'),
        for (var i = 0; i < 40; i++) record('r$i', created: i),
        record('r3'),
      ],
      'wallet-1',
      'self',
    );
    expect(candidates.length, 32);
    expect(candidates.first.id, 'r39');
    expect(
      candidates.any((e) => e.id == 'self' || e.wallet != 'wallet-1'),
      false,
    );
    expect(
      RelatedRecords.evidence(candidates.first),
      contains('My original reason'),
    );
    expect(
      RelatedRecords.evidence(candidates.first),
      isNot(contains('Later edit')),
    );
    expect(RelatedRecords.clip('😀' * 600).runes.length, 480);
  });
  test(
    'local ranking preserves exact source and suppresses weak matches',
    () async {
      messenger.setMockMethodCallHandler(ReflectionAssistant.channel, (
        call,
      ) async {
        expect(call.method, 'rank');
        final args = Map.of(call.arguments as Map);
        expect(args.keys.toSet(), {'query', 'records'});
        expect(args.toString(), isNot(contains('wallet-1')));
        return {
          'scores': [.88, .91, .50],
        };
      });
      final records = [record('a'), record('b'), record('c')];
      final matches = await const RelatedRecords().search(
        'Check my source',
        records,
      );
      expect(matches.map((e) => e.entry.id), ['b']);
      expect(identical(matches.first.entry, records[1]), true);
    },
  );
  test('empty query skips model and invalid native scores rejected', () async {
    expect(await const RelatedRecords().search('  ', [record('a')]), isEmpty);
    for (final scores in [
      [.9, .8],
      [double.nan],
      [2.0],
      ['fake'],
    ]) {
      messenger.setMockMethodCallHandler(
        ReflectionAssistant.channel,
        (_) async => {'scores': scores},
      );
      await expectLater(
        const RelatedRecords().search('Reason', [record('a')]),
        throwsA(isA<PlatformException>()),
      );
    }
  });
  test('weak or ambiguous scores abstain instead of claiming a match', () {
    expect(RelatedRecords.choose([.81, .79]), isEmpty);
    expect(RelatedRecords.choose([.88, .875]), isEmpty);
    expect(RelatedRecords.choose([.91, .88, .84]), [0]);
    expect(RelatedRecords.choose([double.nan]), isEmpty);
    expect(RelatedRecords.choose([]), isEmpty);
  });
  test(
    'native failure is surfaced, never converted to invented quotes',
    () async {
      messenger.setMockMethodCallHandler(
        ReflectionAssistant.channel,
        (_) async => throw PlatformException(code: 'model-missing'),
      );
      await expectLater(
        const RelatedRecords().search('Reason', [record('a')]),
        throwsA(isA<PlatformException>()),
      );
    },
  );
}
