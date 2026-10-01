import 'dart:typed_data';
import 'package:bs58/bs58.dart';

/// Synthetic RPC response for a deterministic, explicitly labeled walkthrough.
/// None of these accounts, amounts or signature are evidence of a live swap.
const fixtureWallet = '11111111111111111111111111111111';
String get fixtureSignature =>
    base58.encode(Uint8List(64)..fillRange(0, 64, 7));

Map<String, dynamic> fixtureSignatureInfo() => {
  'signature': fixtureSignature,
  'blockTime': 1700000000,
  'err': null,
  'confirmationStatus': 'finalized',
};

Map<String, dynamic> fixtureTransaction() {
  const source = 'SysvarRent111111111111111111111111111111111';
  const destination = 'SysvarC1ock11111111111111111111111111111111';
  const token = 'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA';
  const usdc = 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v';
  const wsol = 'So11111111111111111111111111111111111111112';
  Map<String, dynamic> balance(
    int index,
    String mint,
    String amount,
    int decimals,
  ) => {
    'accountIndex': index,
    'mint': mint,
    'owner': fixtureWallet,
    'programId': token,
    'uiTokenAmount': {'amount': amount, 'decimals': decimals},
  };
  return {
    'blockTime': 1700000000,
    'transaction': {
      'signatures': [fixtureSignature],
      'message': {
        'accountKeys': [fixtureWallet, source, destination].indexed
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
            'programId': 'JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4',
            'accounts': [token, fixtureWallet, source, destination],
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
