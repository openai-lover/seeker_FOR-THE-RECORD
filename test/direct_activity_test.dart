import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:bs58/bs58.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:seeker_workroom/data/direct_activity.dart';

const wallet = '11111111111111111111111111111111';
const source = 'SysvarRent111111111111111111111111111111111';
const destination = 'SysvarC1ock11111111111111111111111111111111';
const token = 'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA';
const jupiter = 'JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4';
const usdc = 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v';
const wsol = 'So11111111111111111111111111111111111111112';
String signature([int value = 7]) =>
    base58.encode(Uint8List(64)..fillRange(0, 64, value));
Map<String, dynamic> info([int value = 7]) => {
  'signature': signature(value),
  'blockTime': 1700000000,
  'err': null,
  'confirmationStatus': 'finalized',
};

Map<String, dynamic> fixture({String? signatureValue}) {
  Map<String, dynamic> balance(
    int index,
    String mint,
    String amount,
    int decimals,
  ) => {
    'accountIndex': index,
    'mint': mint,
    'owner': wallet,
    'programId': token,
    'uiTokenAmount': {'amount': amount, 'decimals': decimals},
  };
  return {
    'blockTime': 1700000000,
    'transaction': {
      'signatures': [signatureValue ?? signature()],
      'message': {
        'accountKeys': [wallet, source, destination].indexed
            .map(
              (entry) => {
                'pubkey': entry.$2,
                'signer': entry.$1 == 0,
                'writable': true,
              },
            )
            .toList(),
        'instructions': [
          {
            'programId': jupiter,
            'accounts': [token, wallet, source, destination],
            'data': base58.encode(
              Uint8List.fromList([
                229,
                23,
                203,
                151,
                122,
                227,
                173,
                42,
                0,
                0,
                0,
                0,
              ]),
            ),
          },
        ],
      },
    },
    'meta': {
      'err': null,
      'fee': 5000,
      'preTokenBalances': [
        balance(1, usdc, '300000000', 6),
        balance(2, wsol, '0', 9),
      ],
      'postTokenBalances': [
        balance(1, usdc, '50000000', 6),
        balance(2, wsol, '1420000000', 9),
      ],
    },
  };
}

http.Response result(Object? value) => http.Response(
  jsonEncode({'jsonrpc': '2.0', 'id': 1, 'result': value}),
  200,
);
Matcher error(String code) =>
    isA<DirectActivityError>().having((e) => e.code, 'code', code);

void main() {
  test(
    'Retry-After is honored up to two seconds and longer cooldowns return promptly',
    () async {
      for (final header in [
        '1',
        '2',
        '20',
        'Sun, 20 Sep 2026 00:00:01 GMT',
        'Sun, 20 Sep 2026 00:00:20 GMT',
      ]) {
        var calls = 0;
        final delays = <Duration>[];
        final client = DirectActivityClient(
          now: () => DateTime.utc(2026, 9, 20),
          delay: (duration) async => delays.add(duration),
          client: MockClient((request) async {
            calls++;
            return calls == 1
                ? http.Response('', 429, headers: {'Retry-After': header})
                : result([]);
          }),
        );
        final long = header == '20' || header.contains('00:00:20');
        if (long) {
          await expectLater(
            client.load(wallet),
            throwsA(error('too-many-requests')),
          );
          expect(calls, 1);
          expect(delays, isEmpty);
        } else {
          await client.load(wallet);
          expect(calls, 2);
          expect(delays, [Duration(seconds: header == '2' ? 2 : 1)]);
        }
        client.close();
      }
    },
  );
  test(
    'local parser proves a Jupiter route and preserves exact asset amounts',
    () {
      final activity = normalizeDirectActivity(wallet, info(), fixture());
      expect(activity.canJournal, isTrue);
      expect(activity.input!.toJson(), {
        'mint': usdc,
        'symbol': 'USDC',
        'amount': '250',
      });
      expect(activity.output!.toJson(), {
        'mint': wsol,
        'symbol': 'wSOL',
        'amount': '1.42',
      });
      expect(activity.fee, '0.000005');
      final large = fixture();
      large['meta']['preTokenBalances'][0]['uiTokenAmount']['amount'] =
          '900719925474099300000001';
      large['meta']['postTokenBalances'][0]['uiTokenAmount']['amount'] = '0';
      expect(
        normalizeDirectActivity(wallet, info(), large).input!.amount,
        '900719925474099300.000001',
      );
    },
  );

  test(
    'supported exact-out and shared route discriminators use their own endpoints',
    () {
      for (final (hex, shared) in [
        ('d033ef977b2bed5c', false),
        ('c1209b3341d69c81', true),
        ('b0d169a89a7d453e', true),
      ]) {
        final tx = fixture();
        final ix = tx['transaction']['message']['instructions'][0];
        ix['data'] = base58.encode(
          Uint8List.fromList([
            for (var i = 0; i < hex.length; i += 2)
              int.parse(hex.substring(i, i + 2), radix: 16),
          ]),
        );
        if (shared) {
          ix['accounts'] = [
            token,
            token,
            wallet,
            source,
            token,
            token,
            destination,
          ];
        }
        expect(
          normalizeDirectActivity(wallet, info(), tx).canJournal,
          isTrue,
          reason: hex,
        );
      }
    },
  );

  test(
    'failed, unsupported, missing and mismatched transactions cannot be journaled',
    () {
      expect(
        normalizeDirectActivity(wallet, {
          ...info(),
          'err': {'failed': true},
        }, fixture()).status,
        'failed',
      );
      expect(
        normalizeDirectActivity(wallet, info(), null).status,
        'unavailable',
      );
      expect(
        normalizeDirectActivity(wallet, info(), {}).issue,
        'parse-unavailable',
      );
      expect(
        normalizeDirectActivity(
          wallet,
          info(),
          fixture(signatureValue: signature(8)),
        ).canJournal,
        isFalse,
      );
      for (final change in <void Function(Map<String, dynamic>)>[
        (tx) => tx['meta']['err'] = {'failed': true},
        (tx) =>
            tx['transaction']['message']['accountKeys'][0]['signer'] = false,
        (tx) => tx['transaction']['message']['instructions'][0]['accounts'][1] =
            source,
        (tx) => tx['transaction']['message']['instructions'][0]['data'] =
            '11111111',
        (tx) => tx['transaction']['message']['instructions'].add({
          'programId': wallet,
          'accounts': [],
        }),
        (tx) => tx['meta']['preTokenBalances'][0]['owner'] = source,
        (tx) => tx['meta']['postTokenBalances'][1]['programId'] =
            'TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb',
        (tx) => tx['meta']['postTokenBalances'][1]['accountIndex'] = 1,
        (tx) =>
            tx['meta']['postTokenBalances'][1]['uiTokenAmount']['decimals'] = 8,
        (tx) => tx['meta']['postTokenBalances'] =
            [], // Native SOL is never inferred.
      ]) {
        final tx = fixture();
        change(tx);
        expect(normalizeDirectActivity(wallet, info(), tx).canJournal, isFalse);
      }
    },
  );

  test(
    'public read-only requests contain only the selected address and signatures',
    () async {
      final requests = <Map<String, dynamic>>[];
      final client = DirectActivityClient(
        client: MockClient((request) async {
          expect(request.url.toString(), 'https://api.mainnet.solana.com');
          expect(request.headers.containsKey('authorization'), isFalse);
          final body = Map<String, dynamic>.from(jsonDecode(request.body));
          requests.add(body);
          if (body['method'] == 'getSignaturesForAddress') {
            return result([info()]);
          }
          return result(fixture());
        }),
      );
      final page = await client.load(wallet);
      expect(page['wallet'], wallet);
      expect(page['nextCursor'], isNull);
      expect((page['items'] as List).single['type'], 'swap');
      expect(requests.map((r) => r['method']), [
        'getSignaturesForAddress',
        'getTransaction',
      ]);
      expect(requests.first['params'], [
        wallet,
        {'commitment': 'finalized', 'limit': 8},
      ]);
      expect(requests.last['params'], [
        signature(),
        {
          'commitment': 'finalized',
          'encoding': 'jsonParsed',
          'maxSupportedTransactionVersion': 0,
        },
      ]);
      expect(
        requests.every(
          (r) => r.keys.toSet().difference({
            'jsonrpc',
            'id',
            'method',
            'params',
          }).isEmpty,
        ),
        isTrue,
      );
      client.close();
    },
  );

  test(
    'cache is wallet/cursor scoped, expires after 60 seconds and cannot be mutated by callers',
    () async {
      var calls = 0;
      var now = DateTime(2026, 9, 20);
      final client = DirectActivityClient(
        now: () => now,
        client: MockClient((request) async {
          calls++;
          return result([]);
        }),
      );
      final first = await client.load(wallet);
      (first['items'] as List).add({'private': 'local mutation'});
      expect((await client.load(wallet))['items'], isEmpty);
      expect(calls, 1);
      await client.load(source);
      await client.load(wallet, before: signature());
      expect(calls, 3);
      now = now.add(const Duration(seconds: 60));
      await client.load(wallet);
      expect(calls, 4);
      client.clearCache();
      await client.load(wallet);
      expect(calls, 5);
      client.close();
      await expectLater(client.load(wallet), throwsA(error('rpc-unavailable')));
    },
  );

  test(
    '429 retries once with backoff, then reports rate limiting without caching failure',
    () async {
      var calls = 0;
      final delays = <Duration>[];
      final client = DirectActivityClient(
        delay: (duration) async => delays.add(duration),
        client: MockClient((request) async {
          calls++;
          return calls <= 2 ? http.Response('', 429) : result([]);
        }),
      );
      await expectLater(
        client.load(wallet),
        throwsA(error('too-many-requests')),
      );
      expect(calls, 2);
      expect(delays, [const Duration(milliseconds: 400)]);
      expect((await client.load(wallet))['items'], isEmpty);
      expect(calls, 3);
      client.close();
    },
  );

  test(
    'pages contain at most eight signatures and transaction workers never exceed two',
    () async {
      var active = 0, maximum = 0;
      final client = DirectActivityClient(
        client: MockClient((request) async {
          final body = jsonDecode(request.body);
          if (body['method'] == 'getSignaturesForAddress') {
            return result([for (var i = 1; i <= 8; i++) info(i)]);
          }
          active++;
          if (active > maximum) maximum = active;
          await Future<void>.delayed(const Duration(milliseconds: 1));
          active--;
          return result(fixture(signatureValue: body['params'][0] as String));
        }),
      );
      final page = await client.load(wallet);
      expect(page['items'], hasLength(8));
      expect(page['nextCursor'], signature(8));
      expect(maximum, 2);
      client.close();
    },
  );

  test(
    'invalid keys, cursor, response size and unfinalized status fail closed',
    () async {
      var calls = 0;
      Object? response = [for (var i = 1; i <= 9; i++) info(i)];
      final client = DirectActivityClient(
        client: MockClient((request) async {
          calls++;
          return result(response);
        }),
      );
      await expectLater(
        client.load('not a key'),
        throwsA(error('invalid-input')),
      );
      await expectLater(
        client.load(wallet, before: 'bad'),
        throwsA(error('invalid-input')),
      );
      expect(calls, 0);
      await expectLater(
        client.load(wallet),
        throwsA(error('parse-unavailable')),
      );
      response = [
        {...info(), 'confirmationStatus': 'processed'},
      ];
      await expectLater(
        client.load(wallet),
        throwsA(error('parse-unavailable')),
      );
      response = [
        {
          ...info(),
          'err': {'failed': true},
        },
      ];
      final page = await client.load(wallet);
      expect((page['items'] as List).single['status'], 'failed');
      expect(
        calls,
        3,
      ); // Failed chain transactions never trigger a detail request.
      client.close();
    },
  );

  test(
    'clearing during a request prevents that response from repopulating the cache',
    () async {
      var calls = 0;
      final pending = Completer<http.Response>();
      final client = DirectActivityClient(
        client: MockClient((request) async {
          calls++;
          return calls == 1 ? pending.future : result([]);
        }),
      );
      final loading = client.load(wallet);
      client.clearCache();
      pending.complete(result([]));
      await loading;
      await client.load(wallet);
      expect(calls, 2);
      client.close();
    },
  );
}
