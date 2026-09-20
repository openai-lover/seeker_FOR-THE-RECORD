import 'dart:convert';
import 'dart:typed_data';
import 'package:bs58/bs58.dart';
import '../config.dart';

// Strict legacy transaction decoder: one SPL transferChecked, exact quote, no extra instructions.
// The app rejects SOL transfers, unknown programs, additional signers and changed recipients.
void validateOrderTransaction(Map<String, dynamic> quote) {
  final bytes = base64Decode(quote['transactionBase64']);
  int offset = 0;
  int byte() {
    if (offset >= bytes.length) throw const FormatException('잘못된 거래');
    return bytes[offset++];
  }

  int short() {
    int value = 0, shift = 0;
    for (int i = 0; i < 3; i++) {
      final b = byte();
      value |= (b & 127) << shift;
      if (b < 128) return value;
      shift += 7;
    }
    throw const FormatException('잘못된 거래 길이');
  }

  Uint8List take(int n) {
    if (offset + n > bytes.length) throw const FormatException('잘못된 거래');
    final v = bytes.sublist(offset, offset + n);
    offset += n;
    return v;
  }

  void check(bool v) {
    if (!v) throw const FormatException('주문과 거래가 일치하지 않습니다. 서명하지 않았어요.');
  }

  final sigCount = short();
  check(sigCount == 1);
  take(64);
  check(byte() == 1);
  check(byte() == 0);
  final readonly = byte();
  final keyCount = short();
  check(keyCount == 6);
  final keys = List.generate(keyCount, (_) => base58.encode(take(32)));
  check(keys[0] == quote['wallet']);
  check(base58.encode(take(32)) == quote['blockhash']);
  check(short() == 1);
  final program = byte();
  check(
    program < keys.length &&
        keys[program] == 'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA',
  );
  final count = short();
  check(count == 5);
  final indices = List.generate(count, (_) => byte());
  check(indices.every((i) => i < keys.length));
  check(keys[indices[0]] == quote['sourceAta']);
  check(
    keys[indices[1]] == AppConfig.skrMint && quote['mint'] == AppConfig.skrMint,
  );
  check(keys[indices[2]] == quote['recipientAta']);
  check(keys[indices[3]] == quote['wallet']);
  check(keys[indices[4]] == quote['reference']);
  check(readonly == 3);
  check(short() == 10);
  check(byte() == 12);
  final amountBytes = take(8);
  BigInt value = BigInt.zero;
  for (int i = 7; i >= 0; i--) {
    value = (value << 8) | BigInt.from(amountBytes[i]);
  }
  check(value.toString() == quote['amountAtomic']);
  check(byte() == quote['decimals']);
  check(offset == bytes.length);
}
