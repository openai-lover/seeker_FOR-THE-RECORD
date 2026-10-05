import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import '../tool/public_parser_protocol_0511.dart' show evaluateCapturedRow;

// Post-fix same-sample confirmation. Not held-out labels or general accuracy.
const compatFixture = 'test/fixtures/public_mainnet_0512_compatibility';
const baselineFixture = 'test/fixtures/public_mainnet_0511_protocol';
Map<String, dynamic> compatRead(String folder, String name) =>
    jsonDecode(File('$folder/$name').readAsStringSync())
        as Map<String, dynamic>;
void main() {
  final receipt = compatRead(compatFixture, 'fetch-receipt.json');
  final protocol = compatRead(compatFixture, 'protocol.json');
  final results = compatRead(compatFixture, 'replay-results.json');
  final baseline = compatRead(baselineFixture, 'fetch-receipt.json');
  final rows = (receipt['rows'] as List).cast<Map>();
  final prior = (baseline['rows'] as List).cast<Map>();
  final saved = (results['rows'] as List).cast<Map>();
  test('exact same36 signatures and contexts; no new selection', () {
    expect(rows.length, 36);
    expect(prior.length, 36);
    expect(saved.length, 36);
    for (var i = 0; i < 36; i++) {
      expect(rows[i]['caseId'], prior[i]['caseId']);
      expect(rows[i]['selectionInfo'], prior[i]['selectionInfo']);
    }
  });
  test(
    'separate max1 protocol frozen before requests and links immutable baseline',
    () {
      expect(
        sha256
            .convert(File('$compatFixture/protocol.json').readAsBytesSync())
            .toString(),
        receipt['protocolSha256'],
      );
      expect(
        sha256
            .convert(
              File('$baselineFixture/fetch-receipt.json').readAsBytesSync(),
            )
            .toString(),
        protocol['baselineFetchReceiptSha256'],
      );
      expect((protocol['params'] as Map)['maxSupportedTransactionVersion'], 1);
      expect(
        DateTime.parse(
          protocol['frozenAtUtc'] as String,
        ).isBefore(DateTime.parse(receipt['startedAtUtc'] as String)),
        true,
      );
    },
  );
  test(
    'all36 raw attempts retain exact hashes and only same-signature getTransaction',
    () {
      final requests = (receipt['requests'] as List).cast<Map>();
      expect(requests.length, 36);
      for (var i = 0; i < requests.length; i++) {
        final req = requests[i];
        expect(req['method'], 'getTransaction');
        expect(
          (req['params'] as List)[0],
          (rows[i]['selectionInfo'] as Map)['signature'],
        );
        expect(
          ((req['params'] as List)[1] as Map)['maxSupportedTransactionVersion'],
          1,
        );
        for (final attempt in (req['attempts'] as List).cast<Map>()) {
          final bytes = File(
            '$compatFixture/${attempt['responseFile']}',
          ).readAsBytesSync();
          expect(bytes.length, attempt['responseBytes']);
          expect(sha256.convert(bytes).toString(), attempt['responseSha256']);
        }
      }
    },
  );
  test('actual captured response versions are10v1 plus21v0 plus5legacy', () {
    expect(results['responseVersions'], {'1': 10, '0': 21, 'legacy': 5});
  });
  test('same26 previously available parser activities stay unchanged', () {
    expect(results['previouslyAvailableActivityChanged'], 0);
    expect(
      saved
          .where((r) => r['previouslyAvailableActivityUnchanged'] == true)
          .length,
      26,
    );
  });
  test(
    'all15 failed listing flags preserved, not mistaken for successful unavailability',
    () {
      expect(results['listingFailedPositions'], 15);
      for (final row in saved.where((r) => r['listingFailed'] == true)) {
        expect(row['parserInvoked'], true);
        expect((row['activity'] as Map)['status'], 'failed');
        expect((row['activity'] as Map)['type'], 'other');
      }
    },
  );
  test('classified proof accounting recorded separately from accuracy', () {
    expect(results['classifiedProofFailures'], 0);
    for (final row in saved.where((r) => r['classifiedProof'] is Map)) {
      expect((row['classifiedProof'] as Map)['allChecksPass'], true);
    }
  });
  for (var i = 0; i < rows.length; i++) {
    final row = rows[i], expected = saved[i];
    test(
      'same sample ${row['caseId']} reproduces candidate parser outcome',
      () {
        final current = evaluateCapturedRow(row, Directory(compatFixture));
        expect(current['parserInvoked'], expected['parserInvoked']);
        expect(current['evaluationState'], expected['evaluationState']);
        expect(current['activity'], expected['activity']);
        expect(current['classifiedProof'], expected['classifiedProof']);
      },
    );
  }
}
