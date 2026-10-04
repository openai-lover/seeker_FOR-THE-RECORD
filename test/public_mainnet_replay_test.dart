import 'dart:convert';
import 'dart:io';
import 'package:bs58/bs58.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seeker_workroom/data/direct_activity.dart';

// Unmodified public-program RPC fixtures; not the owner's connected wallet.
const folder = 'test/fixtures/public_mainnet_058';
const jupiter = 'JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4';
const token = 'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA';
Map<String, dynamic> read(String name) =>
    jsonDecode(File('$folder/$name').readAsStringSync())
        as Map<String, dynamic>;
Map<String, dynamic> transaction(int index) =>
    read('public-mainnet-$index.json')['result'] as Map<String, dynamic>;
Map<String, dynamic> info(int index) => Map<String, dynamic>.from(
  (read('public-jupiter-signatures.json')['result'] as List)[index] as Map,
);
Map message(Map tx) => (tx['transaction'] as Map)['message'] as Map;
String signer(Map tx) =>
    ((message(tx)['accountKeys'] as List).cast<Map>()).firstWhere(
          (key) => key['signer'] == true,
        )['pubkey']
        as String;
Map route(Map tx) => (message(tx)['instructions'] as List)
    .cast<Map>()
    .singleWhere((instruction) => instruction['programId'] == jupiter);

void main() {
  const failed = {2, 3, 5, 9, 12};
  for (var i = 0; i < 15; i++) {
    test('public mainnet response $i preserves classification and failure', () {
      final tx = transaction(i);
      final result = normalizeDirectActivity(signer(tx), info(i), tx);
      expect(result.status, failed.contains(i) ? 'failed' : 'success');
      expect(result.type, i == 8 ? 'swap' : 'other');
      expect(result.canJournal, i == 8);
    });
  }

  test('case 8 route authority, endpoints and atomic deltas agree', () {
    final tx = transaction(8);
    final owner = signer(tx);
    final instruction = route(tx);
    expect(base58.decode(instruction['data'] as String).take(8).toList(), [
      0xe5,
      0x17,
      0xcb,
      0x97,
      0x7a,
      0xe3,
      0xad,
      0x2a,
    ]);
    final accounts = instruction['accounts'] as List;
    expect(accounts[1], owner);
    final keys = (message(tx)['accountKeys'] as List).cast<Map>();
    final meta = tx['meta'] as Map;
    final pre = (meta['preTokenBalances'] as List).cast<Map>();
    final post = (meta['postTokenBalances'] as List).cast<Map>();
    Map balance(List<Map> balances, String address) => balances.singleWhere(
      (b) => keys[b['accountIndex'] as int]['pubkey'] == address,
    );
    BigInt atomic(Map balance) =>
        BigInt.parse((balance['uiTokenAmount'] as Map)['amount'] as String);
    final sourcePre = balance(pre, accounts[2] as String);
    final sourcePost = balance(post, accounts[2] as String);
    final destinationPre = balance(pre, accounts[3] as String);
    final destinationPost = balance(post, accounts[3] as String);
    for (final b in [sourcePre, sourcePost, destinationPre, destinationPost]) {
      expect(b['owner'], owner);
      expect(b['programId'], token);
    }
    expect(atomic(sourcePre) - atomic(sourcePost), BigInt.from(278854695534));
    expect(
      atomic(destinationPost) - atomic(destinationPre),
      BigInt.from(348720450),
    );
    final result = normalizeDirectActivity(owner, info(8), tx);
    expect(result.input!.amount, '278.854695534');
    expect(result.output!.amount, '348.72045');
  });

  // Deliberately mutated copies are synthetic rejection controls, not RPC data.
  final controls = <String, void Function(Map<String, dynamic>)>{
    'wrong route authority': (tx) {
      (route(tx)['accounts'] as List)[1] = '11111111111111111111111111111111';
    },
    'unowned destination': (tx) {
      final keys = (message(tx)['accountKeys'] as List).cast<Map>();
      final endpoint = (route(tx)['accounts'] as List)[3];
      for (final b
          in ((tx['meta'] as Map)['postTokenBalances'] as List).cast<Map>()) {
        if (keys[b['accountIndex'] as int]['pubkey'] == endpoint) {
          b['owner'] = '11111111111111111111111111111111';
        }
      }
    },
    'duplicate route': (tx) {
      (message(tx)['instructions'] as List).add(
        jsonDecode(jsonEncode(route(tx))),
      );
    },
    'unsupported route discriminator': (tx) {
      route(tx)['data'] = '11111111';
    },
    'inconsistent decimals': (tx) {
      final owner = signer(tx);
      final b = ((tx['meta'] as Map)['postTokenBalances'] as List)
          .cast<Map>()
          .firstWhere((b) => b['owner'] == owner);
      (b['uiTokenAmount'] as Map)['decimals'] = 3;
    },
  };
  for (final control in controls.entries) {
    test('synthetic mutation rejects ${control.key}', () {
      final tx = transaction(8);
      control.value(tx);
      final result = normalizeDirectActivity(signer(tx), info(8), tx);
      expect(result.type, 'other');
      expect(result.canJournal, isFalse);
    });
  }
}
