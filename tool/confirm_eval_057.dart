import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seeker_workroom/data/reflection_assistant.dart';
import 'package:seeker_workroom/data/related_records.dart';
import 'confirm_eval_cases.dart';
import 'evidence_demo_056.dart';

void main() => runApp(const MaterialApp(home: BroadEvaluation()));

class BroadEvaluation extends StatefulWidget {
  const BroadEvaluation({super.key});
  @override
  State<BroadEvaluation> createState() => _State();
}

class _State extends State<BroadEvaluation> {
  final assistant = const ReflectionAssistant();
  bool busy = false;
  String message =
      'Frozen 0.5.7 display policy. Authored synthetic cases, not independent human ratings.';
  void report(String kind, Map<String, dynamic> data) =>
      debugPrintSynchronously(
        'FTR_CONFIRM ${jsonEncode({'kind': kind, ...data})}',
      );
  Future<void> idle() async {
    for (var i = 0; i < 500; i++) {
      if ((await assistant.status())['busy'] != true) return;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    throw StateError('Worker busy');
  }

  Future<Map<String, dynamic>> rank(String q, List<String> records) async {
    await idle();
    return Map<String, dynamic>.from(
      await ReflectionAssistant.channel.invokeMapMethod('rank', {
            'query': RelatedRecords.clip(q),
            'records': records.map(RelatedRecords.clip).toList(),
          }) ??
          {},
    );
  }

  Future<void> run() async {
    setState(() => busy = true);
    try {
      final status = await assistant.status();
      report('start', {
        'version': '0.5.7',
        'utc': DateTime.now().toUtc().toIso8601String(),
        'status': status,
        'uniqueCases': broadCases.length,
        'records': broadRecords.length,
        'passes': 2,
        'independentLabels': false,
        'network': 'available-or-unknown',
        'policy': 'fixed .82/.018; single source',
      });
      if (status['ready'] != true) {
        throw StateError('Prepare model in isolated package first');
      }
      for (var pass = 0; pass < 2; pass++) {
        for (final c in broadCases) {
          final watch = Stopwatch()..start();
          final r = await rank(c.$4, broadRecords);
          final scores = (r['scores'] as List)
              .map((n) => (n as num).toDouble())
              .toList();
          final shown = RelatedRecords.choose(scores);
          final order = List<int>.generate(scores.length, (i) => i)
            ..sort((a, b) => scores[b].compareTo(scores[a]));
          report('row', {
            'pass': pass,
            'id': c.$1,
            'category': c.$2,
            'language': c.$3,
            'acceptable': c.$5,
            'top1': order.first,
            'shown': shown,
            'scores': scores,
            'nativeMs': r['durationMs'],
            'wallMs': watch.elapsedMilliseconds,
            'cold': r['cold'],
          });
          setState(() => message = 'Pass ${pass + 1}/2 · ${c.$1}');
        }
      }
      for (final size in [1, 8, 32]) {
        final records = List<String>.generate(
          size,
          (i) => broadRecords[i % broadRecords.length],
        );
        report('scale', {
          'records': size,
          ...await rank(broadCases.first.$4, records),
        });
      }
      report('long-unicode', await rank('🙂漢字한글' * 600, broadRecords));
      for (final args in [
        {'query': '', 'records': broadRecords},
        {'query': 'reason', 'records': List.filled(33, 'record')},
      ]) {
        await idle();
        try {
          await ReflectionAssistant.channel.invokeMethod('rank', args);
          report('invalid', {'result': 'unexpected-success'});
        } on PlatformException catch (e) {
          report('invalid', {'result': e.code});
        }
      }
      final pending = rank(
        broadCases.first.$4,
        List.filled(32, broadRecords.first),
      ).then<Object?>((r) => r, onError: (Object e) => e);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await assistant.cancel();
      final result = await pending;
      report('cancel', {
        'result': result is PlatformException
            ? result.code
            : 'completed-before-cancel',
      });
      report('recovery', await rank(broadCases.first.$4, broadRecords));
      report('done', {
        'requests': broadCases.length * 2,
        'unique': broadCases.length,
        'weightsChanged': false,
        'policyChanged': false,
      });
      setState(
        () => message =
            'Completed ${broadCases.length * 2} calls.\nFailures and abstentions saved in diagnostic log.\nNo claim of general accuracy or user research.',
      );
    } catch (e) {
      report('fatal', {'error': e.toString()});
      setState(() => message = 'Failed: $e');
    } finally {
      setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('0.5.7 · broader AI evaluation')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ISOLATED DEBUG · SYNTHETIC DATA\n16 new confirmation cases · 8 languages\nRelated / unrelated / ambiguous / edge cases\nNo personal database or wallet access',
          ),
          const SizedBox(height: 24),
          Text(message),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: busy ? null : run,
            child: const Text('Start broad evaluation'),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: busy ? null : launchEvidenceDemo,
            child: const Text('Open synthetic product demo'),
          ),
        ],
      ),
    ),
  );
}
