import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seeker_workroom/data/reflection_assistant.dart';
import 'package:seeker_workroom/data/related_records.dart';
import 'retrieval_eval_cases.dart';

// Manually install the .integration debug package only. No wallet/database import.
void main() => runApp(const MaterialApp(home: RetrievalEvaluation()));

class RetrievalEvaluation extends StatefulWidget {
  const RetrievalEvaluation({super.key});
  @override
  State<RetrievalEvaluation> createState() => _State();
}

class _State extends State<RetrievalEvaluation> {
  final assistant = const ReflectionAssistant();
  String message = 'Synthetic diagnostic only. No personal records.';
  bool busy = false;
  void report(String kind, Map<String, dynamic> data) =>
      debugPrintSynchronously(
        'FTR_RETRIEVAL ${jsonEncode({'kind': kind, ...data})}',
      );
  Future<void> idle() async {
    for (var i = 0; i < 500; i++) {
      if ((await assistant.status())['busy'] != true) return;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    throw StateError('Worker busy');
  }

  Future<Map<String, dynamic>> rank(String query, List<String> records) async {
    await idle();
    return Map<String, dynamic>.from(
      await ReflectionAssistant.channel.invokeMapMethod('rank', {
            'query': query,
            'records': records,
          }) ??
          {},
    );
  }

  Future<void> run() async {
    setState(() => busy = true);
    try {
      final status = await assistant.status();
      report('start', {
        'sourceVersion': '0.5.6',
        'utc': DateTime.now().toUtc().toIso8601String(),
        'status': status,
        'synthetic': true,
        'independentLabels': false,
        'network': 'available-or-unknown',
      });
      if (status['ready'] != true) {
        report('blocked', {'reason': 'model-missing'});
        setState(
          () => message = 'Model missing. Prepare the isolated harness first.',
        );
        return;
      }
      var top1 = 0, covered = 0;
      for (var pass = 0; pass < 2; pass++) {
        for (var i = 0; i < retrievalQueries.length; i++) {
          final q = retrievalQueries[i];
          final timer = Stopwatch()..start();
          final result = await rank(q.$3, retrievalRecords);
          final scores = (result['scores'] as List).cast<num>();
          final order = List<int>.generate(scores.length, (i) => i)
            ..sort((a, b) => scores[b].compareTo(scores[a]));
          final shown = RelatedRecords.choose(
            scores.map((s) => s.toDouble()).toList(),
          );
          if (order.first == q.$2) top1++;
          if (shown.contains(q.$2)) covered++;
          report('row', {
            'pass': pass,
            'case': i,
            'language': q.$1,
            'expected': q.$2,
            'selected': order.first,
            'shown': shown,
            'scores': scores,
            'nativeMs': result['durationMs'],
            'cold': result['cold'],
            'wallMs': timer.elapsedMilliseconds,
          });
          setState(
            () => message = 'Completed ${pass * 16 + i + 1} / 32 requests',
          );
        }
      }
      for (final q in ['How long should I bake this bread?', '🙂한글日本語' * 200]) {
        final result = await rank(
          String.fromCharCodes(q.runes.take(480)),
          retrievalRecords,
        );
        report('probe', {'query': q.runes.take(40).toList(), 'result': result});
      }
      for (final args in [
        <String, dynamic>{'query': '', 'records': retrievalRecords},
        <String, dynamic>{
          'query': 'reason',
          'records': List.filled(33, 'record'),
        },
      ]) {
        await idle();
        try {
          await ReflectionAssistant.channel.invokeMethod('rank', args);
          report('invalid', {'result': 'unexpected-success'});
        } on PlatformException catch (e) {
          report('invalid', {'result': e.code});
        }
      }
      await idle();
      final pending = rank(
        'I need to verify sources',
        List.filled(32, retrievalRecords.first),
      ).then<Object?>((r) => r, onError: (Object e) => e);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await assistant.cancel();
      final cancelled = await pending;
      report('cancel', {
        'result': cancelled is PlatformException
            ? cancelled.code
            : 'completed-before-cancel',
      });
      report(
        'recovery',
        await rank(retrievalQueries.first.$3, retrievalRecords),
      );
      report('done', {
        'requests': 32,
        'uniqueQueries': 16,
        'top1': top1,
        'top3AboveHeuristic': covered,
        'records': 8,
      });
      setState(
        () => message =
            'Complete: $top1 / 32 top choice\n$covered / 32 top-three coverage\n16 authored queries, repeated twice.\nNot general accuracy or human research.',
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
    appBar: AppBar(title: const Text('0.5.6 · related records diagnostic')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ISOLATED DEBUG · SYNTHETIC NOTES\n8 records · 16 queries · 8 languages\nNo wallet. No personal database.',
          ),
          const SizedBox(height: 24),
          Text(message),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: busy ? null : run,
            child: const Text('Start evaluation'),
          ),
        ],
      ),
    ),
  );
}
