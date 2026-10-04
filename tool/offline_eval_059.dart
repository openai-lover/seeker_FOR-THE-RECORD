import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:seeker_workroom/data/repository.dart';
import 'package:seeker_workroom/data/reflection_assistant.dart';
import 'package:seeker_workroom/data/related_records.dart';
import 'confirm_eval_cases.dart';
import 'evidence_demo_056.dart';

// Reuses the 0.5.7 authored fixtures to test a new execution condition.
// Not fresh/held-out labels, human research, production UI timing or a new model.
void main() => runApp(const MaterialApp(home: OfflineEvaluation()));

class OfflineEvaluation extends StatefulWidget {
  const OfflineEvaluation({super.key});
  @override
  State<OfflineEvaluation> createState() => _State();
}

class _State extends State<OfflineEvaluation> {
  final assistant = const ReflectionAssistant();
  String message =
      'Prepared model required. The isolated APK has no INTERNET permission.';
  bool busy = false;
  void report(String kind, Map<String, dynamic> row) => debugPrintSynchronously(
    'FTR_OFFLINE ${jsonEncode({'kind': kind, ...row})}',
  );
  Future<void> idle() async {
    for (var i = 0; i < 500; i++) {
      if ((await assistant.status())['busy'] != true) return;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    throw StateError('Worker busy');
  }

  Future<void> run() async {
    setState(() => busy = true);
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 5);
      try {
        await client.getUrl(Uri.parse('https://api.mainnet-beta.solana.com'));
        throw StateError('Network probe unexpectedly connected');
      } on SocketException catch (e) {
        report('networkDenied', {
          'osErrorCode': e.osError?.errorCode,
          'message': e.message,
        });
      } finally {
        client.close(force: true);
      }
      final status = await assistant.status();
      report('start', {
        'version': '0.5.9',
        'utc': DateTime.now().toUtc().toIso8601String(),
        'status': status,
        'fixtures': 'reused authored057confirmation',
        'cases': broadCases.length,
        'passes': 2,
        'network': 'APK INTERNET permission absent; external probe failed',
      });
      if (status['ready'] != true) {
        throw StateError('Prepared model missing; no download attempted');
      }
      for (var pass = 0; pass < 2; pass++) {
        for (final c in broadCases) {
          await idle();
          final watch = Stopwatch()..start();
          final r =
              await ReflectionAssistant.channel
                  .invokeMapMethod<String, dynamic>('rank', {
                    'query': RelatedRecords.clip(c.$4),
                    'records': broadRecords.map(RelatedRecords.clip).toList(),
                  }) ??
              {};
          final scores = (r['scores'] as List)
              .map((v) => (v as num).toDouble())
              .toList();
          final selected = RelatedRecords.choose(scores);
          final bridgeMs = watch.elapsedMilliseconds;
          setState(
            () => message =
                'Pass ${pass + 1}/2 · ${c.$1}\n${selected.isEmpty ? 'No source offered' : 'Original record ${selected.single + 1}'}',
          );
          await WidgetsBinding.instance.endOfFrame;
          report('row', {
            'pass': pass,
            'id': c.$1,
            'category': c.$2,
            'language': c.$3,
            'acceptable': c.$5,
            'shown': selected,
            'scores': scores,
            'nativeMs': r['durationMs'],
            'bridgeMs': bridgeMs,
            'diagnosticFrameMs': watch.elapsedMilliseconds,
            'cold': r['cold'],
          });
        }
      }
      await idle();
      final question = await assistant.suggest(
        ReflectionAssistant.contextFor(
          'I followed an unverified recommendation.',
          '',
          'Before my next choice I will check the original announcement.',
        ),
      );
      report('reflectionQuestion', {
        'questionId': question['questionId'],
        'candidates': question['candidates'],
        'nativeMs': question['durationMs'],
        'cold': question['cold'],
      });
      report('done', {
        'calls': broadCases.length * 2,
        'weightsChanged': false,
        'independentLabels': false,
      });
      setState(
        () => message =
            'Completed 32 retrieval calls without app network permission.\nReused authored labels; no independent accuracy claim.',
      );
    } catch (e) {
      report('fatal', {'error': e.toString()});
      setState(() => message = 'Diagnostic failed: $e');
    } finally {
      setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('0.5.9 · offline diagnostic')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PHYSICAL SEEKER · ISOLATED DEBUG\nSynthetic records only\nNo INTERNET permission in this diagnostic APK',
          ),
          const SizedBox(height: 24),
          Text(message),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: busy ? null : run,
            child: const Text('Run offline diagnostic'),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: busy
                ? null
                : () async {
                    final repository = await LocalRepository.open(
                      databasePath: path.join(
                        await getDatabasesPath(),
                        'public-fixtures-059.sqlite',
                      ),
                    );
                    await launchEvidenceDemo(repository: repository);
                  },
            child: const Text('Open synthetic SQLite product UI'),
          ),
        ],
      ),
    ),
  );
}
