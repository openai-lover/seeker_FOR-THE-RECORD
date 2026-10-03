import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seeker_workroom/data/reflection_assistant.dart';
import 'reflection_eval_cases.dart';

// Manually install ONLY the .integration debug APK. Never use flutter drive/test
// against a device with personal records. This target imports no database/wallet.
void main() => runApp(const MaterialApp(home: EvaluationScreen()));

class EvaluationScreen extends StatefulWidget {
  const EvaluationScreen({super.key});
  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
  final assistant = const ReflectionAssistant();
  String message = 'Preparing the isolated model…';
  bool ready = false;
  bool running = false;

  void report(String kind, Map<String, dynamic> data) {
    debugPrintSynchronously('FTR_EVAL ${jsonEncode({'kind': kind, ...data})}');
  }

  @override
  void initState() {
    super.initState();
    prepare();
  }

  Future<void> idle() async {
    for (var i = 0; i < 300; i++) {
      if ((await assistant.status())['busy'] != true) return;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    throw StateError('Worker did not become idle');
  }

  Future<void> prepare() async {
    try {
      final initial = await assistant.status();
      report('initial', {
        'status': initial,
        'sourceVersion': '0.5.5',
        'mode': 'isolated-debug',
      });
      if (initial['ready'] != true) {
        try {
          await assistant.suggest(
            ReflectionAssistant.contextFor('Why did I agree?', '', ''),
          );
          report('missingModel', {'result': 'unexpected-success'});
        } on PlatformException catch (e) {
          report('missingModel', {'result': e.code});
        }
        await idle();
        final timer = Stopwatch()..start();
        await assistant.download();
        await idle();
        report('download', {
          'milliseconds': timer.elapsedMilliseconds,
          'bytes': ReflectionAssistant.modelBytes,
        });
      }
      setState(() {
        ready = true;
        message = 'Model ready. Start a synthetic diagnostic run.';
      });
    } catch (e) {
      report('fatal', {'stage': 'prepare', 'error': e.toString()});
      setState(() => message = 'Preparation failed: $e');
    }
  }

  Future<void> run() async {
    setState(() {
      running = true;
      message = 'Running synthetic notes…';
    });
    var count = 0;
    var matches = 0;
    var covered = 0;
    try {
      report('start', {
        'utc': DateTime.now().toUtc().toIso8601String(),
        'cases': 40,
        'passes': 3,
        'model': ReflectionAssistant.model,
      });
      for (var pass = 0; pass < 3; pass++) {
        for (final language in evaluationNotes.entries) {
          for (var topic = 0; topic < language.value.length; topic++) {
            await idle();
            final timer = Stopwatch()..start();
            final result = await assistant.suggest(
              ReflectionAssistant.contextFor('', '', language.value[topic]),
            );
            final expected = topic + 1;
            final candidates =
                (result['candidates'] as List?) ?? [result['questionId']];
            final matched = result['questionId'] == expected;
            if (matched) matches++;
            if (candidates.contains(expected)) covered++;
            count++;
            report('row', {
              'pass': pass,
              'case': '${language.key}-$expected',
              'language': language.key,
              'expected': expected,
              'selected': result['questionId'],
              'candidates': candidates,
              'nativeMs': result['durationMs'],
              'wallMs': timer.elapsedMilliseconds,
              'cold': result['cold'],
            });
            setState(() => message = 'Measured $count / 120 requests');
            await Future<void>.delayed(const Duration(milliseconds: 25));
          }
        }
      }
      await idle();
      try {
        await assistant.suggest(ReflectionAssistant.contextFor('', '', ''));
        report('empty', {'result': 'unexpected-success'});
      } on PlatformException catch (e) {
        report('empty', {'result': e.code});
      }
      await idle();
      final unicode = await assistant.suggest(
        ReflectionAssistant.contextFor(
          '🙂한글' * 200,
          '',
          'I want a practical check before I decide again.',
        ),
      );
      report('unicode', {
        'selected': unicode['questionId'],
        'nativeMs': unicode['durationMs'],
      });
      await idle();
      final pending = assistant
          .suggest(
            ReflectionAssistant.contextFor(
              'A longer context. ' * 30,
              '',
              '次の判断の前に確認したいこと。' * 20,
            ),
          )
          .then<Object?>((v) => v, onError: (Object e) => e);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await assistant.cancel();
      final outcome = await pending;
      report('cancel', {
        'result': outcome is PlatformException
            ? outcome.code
            : 'completed-before-cancel',
      });
      await idle();
      final recovered = await assistant.suggest(
        ReflectionAssistant.contextFor('', '', evaluationNotes['en']![4]),
      );
      report('recovery', {
        'selected': recovered['questionId'],
        'nativeMs': recovered['durationMs'],
        'cold': recovered['cold'],
      });
      report('done', {
        'requests': count,
        'top1Matches': matches,
        'candidateCoverage': covered,
        'synthetic': true,
        'independentLabels': false,
      });
      setState(
        () => message =
            'Complete: $count synthetic requests\nTop choice matched authored labels: $matches\nCandidate coverage: $covered\nNot general accuracy or user research.',
      );
    } catch (e) {
      report('fatal', {'stage': 'run', 'count': count, 'error': e.toString()});
      setState(() => message = 'Run failed after $count: $e');
    } finally {
      setState(() => running = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('FOR THE RECORD · AI check')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ISOLATED DEBUG HARNESS',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            '0.5.5 engine · synthetic notes only\n40 cases · 8 languages · 3 passes\nNo wallet access. No personal database.\nNetwork may be available. Not an offline benchmark.',
          ),
          const SizedBox(height: 24),
          Text(message),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: ready && !running ? run : null,
            child: const Text('Start evaluation'),
          ),
        ],
      ),
    ),
  );
}
