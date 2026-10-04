import 'dart:typed_data';
import 'package:bs58/bs58.dart';
import 'package:flutter/material.dart';
import 'package:seeker_workroom/data/direct_activity.dart';
import 'package:seeker_workroom/data/remote.dart';
import 'package:seeker_workroom/data/repository.dart';
import 'package:seeker_workroom/domain/controller.dart';
import 'package:seeker_workroom/domain/trade_journal.dart';
import 'package:seeker_workroom/platform/native.dart';
import 'package:seeker_workroom/ui/app.dart';

// Isolated .integration package only. Memory repository, synthetic RPC responses.
// Real product UI, local parser and native encoder; no wallet or RPC call is made.
const demoWallet = '11111111111111111111111111111111';
const demoDestination = 'SysvarC1ock11111111111111111111111111111111';
const demoSource = 'SysvarRent111111111111111111111111111111111';
const demoToken = 'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA';
const demoUsdc = 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v';
WalletActivity demoTransfer(int id, {bool spl = false}) {
  final sig = base58.encode(Uint8List.fromList(List.filled(64, id)));
  Map<String, dynamic> balance(int i, String owner, String amount) => {
    'accountIndex': i,
    'mint': demoUsdc,
    'owner': owner,
    'programId': demoToken,
    'uiTokenAmount': {'amount': amount, 'decimals': 6},
  };
  return normalizeDirectActivity(
    demoWallet,
    {'signature': sig, 'err': null, 'blockTime': 1791082800},
    {
      'transaction': {
        'signatures': [sig],
        'message': {
          'accountKeys': [demoWallet, demoSource, demoDestination].indexed
              .map(
                (e) => {'pubkey': e.$2, 'signer': e.$1 == 0, 'writable': true},
              )
              .toList(),
          'instructions': [
            {
              'programId': spl ? demoToken : demoWallet,
              'parsed': {
                'type': spl ? 'transferChecked' : 'transfer',
                'info': spl
                    ? {
                        'source': demoSource,
                        'destination': demoDestination,
                        'authority': demoWallet,
                        'mint': demoUsdc,
                        'tokenAmount': {'amount': '2500000', 'decimals': 6},
                      }
                    : {
                        'source': demoWallet,
                        'destination': demoDestination,
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
        'postBalances': spl ? [199995000, 0, 0] : [99995000, 0, 100000000],
        'preTokenBalances': spl
            ? [balance(1, demoWallet, '5000000'), balance(2, demoSource, '0')]
            : [],
        'postTokenBalances': spl
            ? [
                balance(1, demoWallet, '2500000'),
                balance(2, demoSource, '2500000'),
              ]
            : [],
      },
    },
  );
}

class SyntheticRemote extends RemoteService {
  SyntheticRemote(super.native, super.local)
    : super(directWalletEnabled: false) {
    initialized = true;
    wallet = demoWallet;
  }
  @override
  bool get directMode => false;
  @override
  bool get onlineAvailable => true;
  @override
  bool get signedIn => true;
  @override
  String? get uid => 'SYNTHETIC-DEMO';
  @override
  Future<void> currentRoom() async {}
  @override
  Future<void> connect() async {
    throw StateError('Synthetic preview: wallet connections disabled');
  }

  @override
  Future<Map<String, dynamic>> call(
    String action, [
    Map<String, dynamic> body = const {},
    bool authenticated = true,
  ]) async => {
    'wallet': demoWallet,
    'items': [demoTransfer(1).toJson(), demoTransfer(2, spl: true).toJson()],
    'nextCursor': null,
  };
}

Future<void> launchEvidenceDemo({Repository? repository}) async {
  final c = WorkroomController(
    repository ?? MemoryRepository(),
    NativePlatform(),
  );
  await c.load();
  await c.setting('roomWelcome', 1);
  await c.setting('language', 'en');
  await c.setting('reduceMotion', false);
  final reasons = [
    (
      'Synthetic demo: I trusted a social media claim without checking its original announcement.',
      'The recommendation had no reliable source.',
      'Read the primary source before relying on a popular recommendation.',
    ),
    (
      'Synthetic demo: I cooked vegetable soup for lunch.',
      'I added too much salt.',
      'Taste the soup before adding salt.',
    ),
    (
      'Synthetic demo: I watered my basil plant.',
      'The soil was still wet.',
      'Check the soil before watering.',
    ),
  ];
  for (var i = 0; i < reasons.length; i++) {
    final a = WalletActivity(
      id: 'synthetic-past-$i',
      signature: 'SYNTHETIC-NOT-A-CHAIN-TRANSACTION-$i',
      status: 'success',
      type: 'other',
      issue: 'unsupported-activity',
    );
    final now = DateTime(2026, 10, 3, 10 + i).millisecondsSinceEpoch;
    if (c.journals.find(demoWallet, a.signature) != null) continue;
    await c.journals.save(
      TradeJournalEntry(
        id: 'synthetic-note-$i',
        wallet: demoWallet,
        activity: a,
        createdAt: now,
        updatedAt: now,
        reason: reasons[i].$1,
        review: reasons[i].$2,
        decisionRule: reasons[i].$3,
      ),
    );
  }
  runApp(
    WorkroomApp(controller: c, remote: SyntheticRemote(NativePlatform(), c)),
  );
}
