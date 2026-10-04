import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:seeker_workroom/data/reflection_assistant.dart';
import 'package:seeker_workroom/data/related_records.dart';
import 'fresh_eval_cases_0510.dart';

class FreshEvaluation0510 extends StatefulWidget {
  const FreshEvaluation0510({super.key});
  @override
  State<FreshEvaluation0510> createState() => _FreshState();
}

class _FreshState extends State<FreshEvaluation0510> {
  String status =
      '48 fresh authored queries · 24 new records · 3 corpora\nLabels frozen before execution; not independent human evaluation.';
  bool busy = false;
  void report(String kind, Map<String, dynamic> row) => debugPrintSynchronously(
    'FTR_FRESH ${jsonEncode({'kind': kind, ...row})}',
  );
  Future<void> run() async {
    setState(() => busy = true);
    try {
      final engine = await const ReflectionAssistant().status();
      if (engine['ready'] != true) throw StateError('Prepared model missing');
      final data = jsonDecode(freshEvaluationJson) as Map;
      final corpora = (data['corpora'] as List)
          .map((r) => (r as List).cast<String>())
          .toList();
      final cases = (data['cases'] as List).cast<Map>();
      report('start', {
        'utc': DateTime.now().toUtc().toIso8601String(),
        'cases': cases.length,
        'records': 24,
        'passes': 2,
        'engine': engine,
        'policyChanged': false,
        'independentHumanLabels': false,
      });
      for (var pass = 0; pass < 2; pass++) {
        for (final row in cases) {
          final watch = Stopwatch()..start();
          final result = await ReflectionAssistant.channel
              .invokeMapMethod<String, dynamic>('rank', {
                'query': RelatedRecords.clip(row['query'] as String),
                'records': corpora[row['corpus'] as int]
                    .map(RelatedRecords.clip)
                    .toList(),
              });
          final scores = (result!['scores'] as List)
              .map((v) => (v as num).toDouble())
              .toList();
          final shown = RelatedRecords.choose(scores);
          final bridge = watch.elapsedMilliseconds;
          setState(
            () => status =
                'Pass ${pass + 1}/2 · ${row['id']}\n${shown.isEmpty ? 'No source offered' : 'Original record ${shown.single + 1}'}',
          );
          await WidgetsBinding.instance.endOfFrame;
          report('row', {
            'pass': pass,
            'id': row['id'],
            'corpus': row['corpus'],
            'category': row['category'],
            'language': row['language'],
            'acceptable': row['acceptable'],
            'shown': shown,
            'scores': scores,
            'nativeMs': result['durationMs'],
            'cold': result['cold'],
            'bridgeMs': bridge,
            'diagnosticFrameMs': watch.elapsedMilliseconds,
          });
        }
      }
      final all = corpora.expand((r) => r).toList();
      for (final row
          in cases
              .where((r) => r['category'] == 'related')
              .where((r) => (r['id'] as String).endsWith('-0'))) {
        final result = await ReflectionAssistant.channel
            .invokeMapMethod<String, dynamic>('rank', {
              'query': row['query'],
              'records': all,
            });
        final scores = (result!['scores'] as List)
            .map((v) => (v as num).toDouble())
            .toList();
        report('mixedCorpusProbe', {
          'id': row['id'],
          'records': 24,
          'acceptable': (row['acceptable'] as List)
              .map((n) => (row['corpus'] as int) * 8 + (n as int))
              .toList(),
          'shown': RelatedRecords.choose(scores),
          'scores': scores,
          'nativeMs': result['durationMs'],
        });
      }
      report('done', {
        'mainCalls': 96,
        'extraMixedCorpusCalls': 3,
        'weightsChanged': false,
        'policyChanged': false,
      });
      setState(
        () => status =
            'Completed 96 calls + 3 mixed-corpus probes.\nEvery failure and abstention retained.\nAuthored labels; not an independent accuracy estimate.',
      );
    } catch (e) {
      report('fatal', {'error': e.toString()});
      setState(() => status = 'Failed: $e');
    } finally {
      setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('0.5.10 engine · fresh diagnostic')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ISOLATED DEBUG · AUTHORED DATA\nEight languages plus mixed-language queries\nNo personal wallet or database',
          ),
          const SizedBox(height: 24),
          Text(status),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: busy ? null : run,
            child: const Text('Run frozen fresh evaluation'),
          ),
        ],
      ),
    ),
  );
}
