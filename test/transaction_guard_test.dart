import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:seeker_workroom/data/transaction_guard.dart';

void main() {
  final fixture =
      jsonDecode(File('test/fixtures/skr_order.json').readAsStringSync())
          as Map<String, dynamic>;
  test('accepts the server-shaped one-instruction SKR quote', () {
    expect(() => validateOrderTransaction(fixture), returnsNormally);
  });
  for (final field in [
    'wallet',
    'mint',
    'recipientAta',
    'sourceAta',
    'reference',
    'blockhash',
    'amountAtomic',
  ]) {
    test('refuses a changed $field before wallet approval', () {
      expect(
        () => validateOrderTransaction({...fixture, field: 'changed'}),
        throwsFormatException,
      );
    });
  }
  test('refuses appended instructions or trailing bytes', () {
    final bytes = base64Decode(fixture['transactionBase64']);
    expect(
      () => validateOrderTransaction({
        ...fixture,
        'transactionBase64': base64Encode([...bytes, 1, 2, 3]),
      }),
      throwsFormatException,
    );
  });
}
