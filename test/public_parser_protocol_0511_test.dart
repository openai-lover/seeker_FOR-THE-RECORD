import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import '../tool/public_parser_protocol_0511.dart';

// Evidence replay regressions, not independent classification accuracy labels.
const capturedProtocolFolder = 'test/fixtures/public_mainnet_0511_protocol';
Map<String, dynamic> protocolJson(String name) =>
    jsonDecode(File('$capturedProtocolFolder/$name').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  group('unavailable selections remain honest', () {
    late Directory temp;
    setUp(() {
      temp = Directory.systemTemp.createTempSync('ftr-public-protocol-test-');
    });
    tearDown(() {
      temp.deleteSync(recursive: true);
    });
    final info = <String, Object?>{
      'signature': 'no-chain-signature-was-invented',
      'err': null,
      'blockTime': null,
    };
    test('listing error cannot become a transaction', () {
      final r = evaluateCapturedRow({
        'fetchState': 'listing-unavailable',
        'selectionInfo': null,
      }, temp);
      expect(r['parserInvoked'], false);
      expect(r.containsKey('activity'), false);
    });
    test('transaction transport/RPC error cannot become a transaction', () {
      final r = evaluateCapturedRow({
        'fetchState': 'transaction-request-error',
        'selectionInfo': info,
      }, temp);
      expect(r['parserInvoked'], false);
      expect(r.containsKey('activity'), false);
    });
    test('transaction-null fetchState stays unreplayed', () {
      final r = evaluateCapturedRow({
        'fetchState': 'transaction-null',
        'selectionInfo': info,
      }, temp);
      expect(r['parserInvoked'], false);
      expect(r.containsKey('activity'), false);
    });
    for (final envelope in <String, Map>{
      'null': {'result': null},
      'rpc-error': {
        'error': {'code': -32015},
      },
      'missing-first-signer': {
        'result': {
          'transaction': {
            'message': {
              'accountKeys': [
                {'pubkey': '11111111111111111111111111111111', 'signer': false},
              ],
            },
          },
        },
      },
    }.entries) {
      test('raw ${envelope.key} cannot invent a signer perspective', () {
        File(
          '${temp.path}/raw.json',
        ).writeAsStringSync(jsonEncode(envelope.value));
        final r = evaluateCapturedRow({
          'fetchState': 'transaction-available',
          'selectionInfo': info,
          'transactionFile': 'raw.json',
        }, temp);
        expect(r['parserInvoked'], false);
        expect(r.containsKey('activity'), false);
      });
    }
  });

  final folder = Directory(capturedProtocolFolder);
  final receipt = protocolJson('fetch-receipt.json');
  final saved = protocolJson('replay-results.json');
  final rows = (receipt['rows'] as List).cast<Map>();
  final expected = (saved['rows'] as List).cast<Map>();
  test(
    'all36 fixed selection positions remain, including errors and duplicates',
    () {
      expect(rows.length, 36);
      expect(expected.length, 36);
      expect(rows.map((r) => r['caseId']).toSet().length, 36);
      for (var epoch = 0; epoch < 3; epoch++) {
        for (final program in ['jupiter', 'system', 'classic-token']) {
          expect(
            rows
                .where((r) => r['epoch'] == epoch && r['program'] == program)
                .length,
            4,
          );
        }
      }
    },
  );
  test('protocol frozen before first fetch and hash retained', () {
    final bytes = File(
      '$capturedProtocolFolder/protocol.json',
    ).readAsBytesSync();
    final protocol = protocolJson('protocol.json');
    expect(sha256.convert(bytes).toString(), receipt['protocolSha256']);
    expect(
      DateTime.parse(
        protocol['frozenAtUtc'] as String,
      ).isBefore(DateTime.parse(receipt['startedAtUtc'] as String)),
      true,
    );
    expect(protocol['epochOffsetsSeconds'], [0, 300, 600]);
  });
  test('raw request-attempt bytes and every failure hash reproduce', () {
    for (final request in (receipt['requests'] as List).cast<Map>()) {
      final attempts = (request['attempts'] as List).cast<Map>();
      expect(attempts.length, inInclusiveRange(1, 2));
      for (final attempt in attempts) {
        final bytes = File(
          '$capturedProtocolFolder/${attempt['responseFile']}',
        ).readAsBytesSync();
        expect(bytes.length, attempt['responseBytes']);
        expect(sha256.convert(bytes).toString(), attempt['responseSha256']);
      }
    }
  });
  test('classified mechanical proofs all pass; not independent accuracy', () {
    expect(saved['classifiedProofFailures'], 0);
    for (final r in expected.where((r) => r['classifiedProof'] is Map)) {
      expect((r['classifiedProof'] as Map)['allChecksPass'], true);
    }
  });
  for (var i = 0; i < rows.length; i++) {
    final row = rows[i], prior = expected[i];
    test(
      'retained ${row['caseId']} replays its saved current-parser outcome',
      () {
        final result = evaluateCapturedRow(row, folder);
        expect(result['parserInvoked'], prior['parserInvoked']);
        expect(result['evaluationState'], prior['evaluationState']);
        expect(result['activity'], prior['activity']);
        expect(result['classifiedProof'], prior['classifiedProof']);
        if (result['parserInvoked'] == true) {
          final activity = result['activity'] as Map;
          expect(
            activity['signature'],
            (row['selectionInfo'] as Map)['signature'],
          );
          if (result['rpcFailed'] == true) {
            expect(activity['status'], 'failed');
            expect(activity['type'], 'other');
          }
        } else {
          expect(result.containsKey('activity'), false);
        }
      },
    );
  }
}
