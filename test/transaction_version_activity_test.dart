import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:seeker_workroom/data/direct_activity.dart';
import 'direct_activity_test.dart'
    show fixture, info, signature, wallet, source, token;
import 'transfer_activity_test.dart' show transfer;

Map<String, dynamic> config() => {
  'computeUnitLimit': 30000,
  'heapSize': null,
  'loadedAccountsDataSizeLimit': 200000,
  'priorityFee': 2500,
};
Map<String, dynamic> v1(Map<String, dynamic> tx) {
  tx['version'] = 1;
  final transaction = Map<String, dynamic>.from(tx['transaction'] as Map);
  final message = Map<String, dynamic>.from(transaction['message'] as Map);
  message['transactionConfig'] = config();
  transaction['message'] = message;
  tx['transaction'] = transaction;
  return tx;
}

void main() {
  for (final version in ['legacy', 0, 1]) {
    test(
      'known transaction version $version preserves strict swap evidence',
      () {
        final tx = fixture();
        if (version == 1) {
          v1(tx);
        } else {
          tx['version'] = version;
        }
        tx['meta']['fee'] = 7500;
        final a = normalizeDirectActivity(wallet, info(), tx);
        expect(a.type, 'swap');
        expect(a.input!.amount, '250');
        expect(a.output!.amount, '1.42');
        expect(a.fee, '0.0000075');
        expect(a.canJournal, isTrue);
      },
    );
  }
  for (final entry in <String, Object?>{
    'future': 2,
    'negative': -1,
    'string': '1',
    'null': null,
    'boolean': true,
    'floating': 1.5,
    'object': <String, dynamic>{},
    'array': <Object?>[],
  }.entries) {
    test(
      '${entry.key} version stays unavailable without assets or editing',
      () {
        final tx = v1(fixture())..['version'] = entry.value;
        final a = normalizeDirectActivity(wallet, info(), tx);
        expect(a.status, 'unavailable');
        expect(a.type, 'other');
        expect(a.issue, 'parse-unavailable');
        expect(a.fee, isNull);
        expect(a.input, isNull);
        expect(a.output, isNull);
        expect(a.canRecordReason, isFalse);
      },
    );
  }
  test('missing response version is rejected', () {
    final tx = fixture()..remove('version');
    expect(
      normalizeDirectActivity(wallet, info(), tx).canRecordReason,
      isFalse,
    );
  });
  for (final entry in <String, Object?>{
    'null': null,
    'array': <Object?>[],
    'string': 'config',
    'missing field': {...config()}..remove('heapSize'),
    'unknown field': {...config(), 'futureBudget': 1},
    'negative resource': {...config(), 'computeUnitLimit': -1},
    'floating resource': {...config(), 'computeUnitLimit': 1.5},
    'resource above u32': {
      ...config(),
      'loadedAccountsDataSizeLimit': 4294967296,
    },
    'boolean heap': {...config(), 'heapSize': true},
    'string priority': {...config(), 'priorityFee': '2500'},
    'negative priority': {...config(), 'priorityFee': -1},
    'floating priority': {...config(), 'priorityFee': 1.5},
    'unsafe priority': {...config(), 'priorityFee': 9007199254740992},
  }.entries) {
    test('v1 ${entry.key} config is not classified', () {
      final tx = v1(fixture());
      tx['transaction']['message']['transactionConfig'] = entry.value;
      final a = normalizeDirectActivity(wallet, info(), tx);
      expect(a.status, 'unavailable');
      expect(a.type, 'other');
      expect(a.canRecordReason, isFalse);
    });
  }
  test('absent v1 config and legacy/v0 config mismatch are rejected', () {
    final tx = v1(fixture());
    (tx['transaction']['message'] as Map).remove('transactionConfig');
    expect(normalizeDirectActivity(wallet, info(), tx).status, 'unavailable');
    for (final version in ['legacy', 0]) {
      tx['version'] = version;
      tx['transaction']['message']['transactionConfig'] = null;
      expect(normalizeDirectActivity(wallet, info(), tx).status, 'unavailable');
    }
  });
  test('bounded nullable config never determines displayed fee', () {
    final tx = v1(fixture());
    tx['transaction']['message']['transactionConfig'] = {
      'computeUnitLimit': 4294967295,
      'heapSize': null,
      'loadedAccountsDataSizeLimit': 0,
      'priorityFee': null,
    };
    expect(normalizeDirectActivity(wallet, info(), tx).fee, '0.000005');
  });
  test('v1 does not loosen signer, route, balance or compound checks', () {
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (t) => t['transaction']['message']['accountKeys'][0]['signer'] = false,
      (t) => t['transaction']['message']['instructions'][0]['accounts'][1] =
          source,
      (t) => t['meta']['preTokenBalances'][0]['owner'] = source,
      (t) => t['meta']['postTokenBalances'][1]['programId'] = source,
      (t) =>
          t['transaction']['message']['instructions'].add({'programId': token}),
    ]) {
      final tx = v1(fixture());
      mutate(tx);
      expect(normalizeDirectActivity(wallet, info(), tx).canJournal, isFalse);
    }
  });
  test('v1 SOL and SPL retain exact balance evidence and total meta fee', () {
    final sol = v1(transfer());
    sol['meta']['fee'] = 5500;
    sol['meta']['postBalances'][0] = 99994500;
    sol['transaction']['message']['transactionConfig']['priorityFee'] = 500;
    final sent = normalizeDirectActivity(wallet, info(), sol);
    expect(sent.type, 'transfer-out');
    expect(sent.input!.amount, '0.1');
    expect(sent.fee, '0.0000055');
    sol['meta']['postBalances'][0] = 99994501;
    expect(normalizeDirectActivity(wallet, info(), sol).isTransfer, isFalse);
    final spl = v1(transfer(spl: true));
    expect(normalizeDirectActivity(wallet, info(), spl).type, 'transfer-out');
    spl['meta']['postTokenBalances'][0]['uiTokenAmount']['amount'] = '2500001';
    expect(normalizeDirectActivity(wallet, info(), spl).isTransfer, isFalse);
  });
  test(
    'future RPC version preserves neighbors and skips failed detail lookups',
    () async {
      final methods = <String>[];
      final client = DirectActivityClient(
        client: MockClient((request) async {
          final body = jsonDecode(request.body) as Map;
          methods.add(body['method'] as String);
          if (body['method'] == 'getSignaturesForAddress') {
            return http.Response(
              jsonEncode({
                'result': [
                  info(7),
                  info(8),
                  {
                    ...info(9),
                    'err': {'failed': true},
                  },
                ],
              }),
              200,
            );
          }
          expect(body['params'][1]['maxSupportedTransactionVersion'], 1);
          expect(
            body['params'][1]['maxSupportedTransactionVersion'],
            isA<int>(),
          );
          if (body['params'][0] == signature(7)) {
            return http.Response(
              jsonEncode({
                'error': {'code': -32015},
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({'result': v1(fixture(signatureValue: signature(8)))}),
            200,
          );
        }),
      );
      final items = (await client.load(wallet))['items'] as List;
      expect(items[0]['status'], 'unavailable');
      expect(items[0]['type'], 'other');
      expect(items[1]['type'], 'swap');
      expect(items[2]['status'], 'failed');
      expect(methods, [
        'getSignaturesForAddress',
        'getTransaction',
        'getTransaction',
      ]);
      client.close();
    },
  );
}
