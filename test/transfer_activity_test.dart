import 'package:flutter_test/flutter_test.dart';
import 'package:seeker_workroom/data/direct_activity.dart';
import 'package:seeker_workroom/domain/trade_journal.dart';
import 'direct_activity_test.dart'
    show info, signature, wallet, source, destination, token, usdc;

Map<String, dynamic> transfer({bool spl = false}) {
  Map<String, dynamic> balance(int index, String owner, String amount) => {
    'accountIndex': index,
    'mint': usdc,
    'owner': owner,
    'programId': token,
    'uiTokenAmount': {'amount': amount, 'decimals': 6},
  };
  return {
    'transaction': {
      'signatures': [signature()],
      'message': {
        'accountKeys': [wallet, source, destination].indexed
            .map((e) => {'pubkey': e.$2, 'signer': e.$1 == 0, 'writable': true})
            .toList(),
        'instructions': [
          {
            'programId': spl ? token : wallet,
            'parsed': {
              'type': spl ? 'transferChecked' : 'transfer',
              'info': spl
                  ? {
                      'source': source,
                      'destination': destination,
                      'authority': wallet,
                      'mint': usdc,
                      'tokenAmount': {'amount': '2500000', 'decimals': 6},
                    }
                  : {
                      'source': wallet,
                      'destination': destination,
                      'lamports': 100000000,
                    },
            },
          },
        ],
      },
    },
    'meta': {
      'err': null,
      'fee': 5000,
      'innerInstructions': [],
      'preBalances': [200000000, 0, 0],
      'postBalances': [99995000, 0, 100000000],
      'preTokenBalances': spl
          ? [balance(1, wallet, '5000000'), balance(2, source, '0')]
          : [],
      'postTokenBalances': spl
          ? [balance(1, wallet, '2500000'), balance(2, source, '2500000')]
          : [],
    },
  };
}

void main() {
  test(
    'SOL sent and received require instruction and exact fee-adjusted balances',
    () {
      final tx = transfer();
      final sent = normalizeDirectActivity(wallet, info(), tx);
      expect(sent.type, 'transfer-out');
      expect(sent.input!.amount, '0.1');
      expect(sent.canJournal, false);
      expect(sent.canRecordReason, true);
      expect(WalletActivity.fromJson(sent.toJson()).isTransfer, true);
      final received = normalizeDirectActivity(destination, info(), tx);
      expect(received.type, 'transfer-in');
      expect(received.output!.amount, '0.1');
      tx['meta']['postBalances'][2] = 99999999;
      expect(normalizeDirectActivity(wallet, info(), tx).isTransfer, false);
    },
  );
  test(
    'classic SPL checked transfer validates owner, exact atomic amount, decimals',
    () {
      final tx = transfer(spl: true);
      final sent = normalizeDirectActivity(wallet, info(), tx);
      expect(sent.type, 'transfer-out');
      expect(sent.input!.symbol, 'USDC');
      expect(sent.input!.amount, '2.5');
      expect(normalizeDirectActivity(source, info(), tx).type, 'transfer-in');
      tx['meta']['postTokenBalances'][0]['uiTokenAmount']['amount'] = '2500001';
      expect(normalizeDirectActivity(wallet, info(), tx).isTransfer, false);
    },
  );
  test(
    'compound, inner, unsigned, self, failed and spoofed transfers stay unclassified',
    () {
      for (final mutate in <void Function(Map<String, dynamic>)>[
        (t) => t['transaction']['message']['instructions'].add({
          'programId': token,
        }),
        (t) => t['meta']['innerInstructions'].add({
          'index': 0,
          'instructions': [],
        }),
        (t) => t['transaction']['message']['accountKeys'][0]['signer'] = false,
        (t) =>
            t['transaction']['message']['instructions'][0]['parsed']['info']['destination'] =
                wallet,
        (t) => t['meta']['err'] = {'error': 1},
        (t) =>
            t['transaction']['message']['instructions'][0]['programId'] = token,
        (t) => t['meta']['preBalances'][0] = 9007199254740992,
      ]) {
        final tx = transfer();
        mutate(tx);
        expect(normalizeDirectActivity(wallet, info(), tx).isTransfer, false);
      }
    },
  );
  test('SPL mismatched owner, amount, mint, extension, duplicates rejected', () {
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (t) => t['meta']['postTokenBalances'][0]['owner'] = source,
      (t) =>
          t['transaction']['message']['instructions'][0]['parsed']['info']['tokenAmount']['amount'] =
              '3',
      (t) =>
          t['transaction']['message']['instructions'][0]['parsed']['info']['mint'] =
              source,
      (t) => t['transaction']['message']['instructions'][0]['programId'] =
          destination,
      (t) =>
          t['meta']['preTokenBalances'].add(t['meta']['preTokenBalances'][0]),
      (t) =>
          t['transaction']['message']['instructions'][0]['parsed']['info']['authority'] =
              source,
    ]) {
      final tx = transfer(spl: true);
      mutate(tx);
      expect(normalizeDirectActivity(wallet, info(), tx).isTransfer, false);
    }
  });
}
