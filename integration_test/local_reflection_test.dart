import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:seeker_workroom/data/reflection_assistant.dart';
import 'fixtures/reflection_cases.dart';

// Run only with WORKROOM_ISOLATED_TEST=1. This target does not open a personal
// database, connect a wallet, or present synthetic data as live activity.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('physical E5 download, semantic retrieval, cancellation and reuse', (
    tester,
  ) async {
    const assistant = ReflectionAssistant();
    final progress = ValueNotifier<String>('Checking local model…');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('FOR THE RECORD · DEVICE CHECK')),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SYNTHETIC NOTES · AI CHECK ONLY'),
                const SizedBox(height: 20),
                const Text(
                  'No wallet access. No personal records.\n133 MB model, stored privately on this phone.',
                ),
                const SizedBox(height: 30),
                ValueListenableBuilder<String>(
                  valueListenable: progress,
                  builder: (_, value, child) => Text(value),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final rows = <Map<String, dynamic>>[];
    binding.reportData = {
      'model': ReflectionAssistant.model,
      'synthetic': true,
      'modelBytes': ReflectionAssistant.modelBytes,
      'results': rows,
    };
    expect((await assistant.status())['supported'], isTrue);
    await expectLater(
      assistant.suggest(ReflectionAssistant.contextFor('', '', '')),
      throwsA(
        isA<PlatformException>().having((e) => e.code, 'code', 'empty-note'),
      ),
    );
    if ((await assistant.status())['ready'] != true) {
      await expectLater(
        assistant.suggest(
          ReflectionAssistant.contextFor('My motive is unclear.', '', ''),
        ),
        throwsA(
          isA<PlatformException>().having(
            (e) => e.code,
            'code',
            'model-missing',
          ),
        ),
      );
      progress.value = 'Downloading and checking SHA-256…';
      await tester.pump();
      final timer = Stopwatch()..start();
      await assistant.download();
      binding.reportData!['downloadMs'] = timer.elapsedMilliseconds;
    }
    expect((await assistant.status())['ready'], isTrue);
    for (final item in jsonDecode(reflectionCasesJson) as List) {
      progress.value = 'Local inference: ${item['id']}';
      await tester.pump();
      final note = item['note'] as Map;
      final wall = Stopwatch()..start();
      final selected = await assistant.suggest(
        ReflectionAssistant.contextFor(
          note['reason'],
          note['plan'],
          note['reflection'],
        ),
      );
      final candidates = selected['candidates'] as List?;
      rows.add({
        'case': item['id'],
        'group': item['group'] ?? 'held-out',
        'questionId': selected['questionId'],
        'expectedQuestionId': item['expected'],
        'candidates': candidates,
        'cold': selected['cold'],
        'nativeMs': selected['durationMs'],
        'wallMs': wall.elapsedMilliseconds,
      });
      expect(selected['questionId'], inInclusiveRange(1, 5));
      expect(
        candidates?.contains(item['expected']) ??
            (selected['questionId'] == item['expected']),
        isTrue,
        reason:
            'Expected topic must be the suggestion or one of the explicitly ambiguous choices: ${item['id']}',
      );
    }
    binding.reportData!['firstChoiceMatches'] = rows
        .where((r) => r['questionId'] == r['expectedQuestionId'])
        .length;
    binding.reportData!['ambiguousChoices'] = rows
        .where((r) => r['candidates'] != null)
        .length;
    expect(
      binding.reportData!['firstChoiceMatches'] as int,
      greaterThanOrEqualTo(60),
    );
    expect((await assistant.status())['warm'], isTrue);

    // Supplementary-plane emoji remain valid UTF-8 through JNI; long input is bounded.
    final unicode = await assistant.suggest(
      ReflectionAssistant.contextFor(
        '한글🙂' * 200,
        '',
        '다음번 선택 전에 확인할 기준을 정하고 싶다.',
      ),
    );
    expect(unicode['questionId'], inInclusiveRange(1, 5));
    binding.reportData!['unicodeInput'] = 'passed';

    // Attach an error handler before cancellation to avoid an unhandled future.
    final future = assistant
        .suggest(
          ReflectionAssistant.contextFor(
            'A long note. ' * 30,
            '',
            '다음 결정을 하기 전 무엇을 확인할까?' * 10,
          ),
        )
        .then<Object?>((value) => value, onError: (Object error) => error);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await assistant.cancel();
    final cancelled = await future;
    expect(
      cancelled,
      isA<PlatformException>().having((e) => e.code, 'code', 'cancelled'),
    );
    for (
      var i = 0;
      i < 100 && (await assistant.status())['busy'] == true;
      i++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect((await assistant.status())['busy'], isFalse);
    final after = await assistant.suggest(
      ReflectionAssistant.contextFor(
        '',
        '',
        'This useful habit worked well. I want to repeat it.',
      ),
    );
    expect(after['questionId'], 5);
    binding.reportData!['cancellationAndRecovery'] = 'passed';
    progress.value =
        'Completed ${rows.length} synthetic cases.\nFirst-choice matches: ${binding.reportData!['firstChoiceMatches']}\nAmbiguous choices: ${binding.reportData!['ambiguousChoices']}\nCancellation and Unicode checks passed.';
    await tester.pump();
  }, timeout: const Timeout(Duration(minutes: 15)));
}
