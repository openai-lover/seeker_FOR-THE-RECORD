import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io' show HttpDate;
import 'package:bs58/bs58.dart';
import 'package:http/http.dart' as http;
import '../domain/trade_journal.dart';

class DirectActivityError implements Exception {
  const DirectActivityError(this.code);
  final String code;
  @override
  String toString() => code;
}

const _system = '11111111111111111111111111111111';
const _jupiter = 'JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4';
const _token = 'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA';
const _compute = 'ComputeBudget111111111111111111111111111111';
const _associated = 'ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL';
const _symbols = {
  'So11111111111111111111111111111111111111112': 'wSOL',
  'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v': 'USDC',
  'SKRbvo6Gf7GondiT3BbTfuRDPqLWei4j2Qy2NPGZhW3': 'SKR',
};

// First 8 bytes of SHA-256("global:<instruction name>"), in hex.
// Same Jupiter v6 IDL discriminators and endpoint positions as activity.ts:
// route, exact_out_route, shared_accounts_route, shared_accounts_exact_out_route.
const _routes = <String, (int, int, int)>{
  'e517cb977ae3ad2a': (1, 2, 3),
  'd033ef977b2bed5c': (1, 2, 3),
  'c1209b3341d69c81': (2, 3, 6),
  'b0d169a89a7d453e': (2, 3, 6),
};

bool _base58Size(Object? value, int size) {
  if (value is! String || value.length > 90) return false;
  try {
    return base58.decode(value).length == size;
  } catch (_) {
    return false;
  }
}

bool _safeInt(Object? value) =>
    value is int && value >= 0 && value <= 9007199254740991;

// RPC ceiling 1 includes legacy and v0. Validate envelopes before attributing
// balances; transaction config never estimates or replaces the total meta fee.
bool _supportedTransactionEnvelope(Map tx, Map message) {
  final version = tx['version'];
  if (version == 'legacy' || (version is int && version == 0)) {
    return !message.containsKey('transactionConfig');
  }
  if (version is! int || version != 1) return false;
  final config = message['transactionConfig'];
  const fields = {
    'computeUnitLimit',
    'heapSize',
    'loadedAccountsDataSizeLimit',
    'priorityFee',
  };
  if (config is! Map ||
      config.length != fields.length ||
      fields.any((field) => !config.containsKey(field)) ||
      config.keys.any((key) => !fields.contains(key))) {
    return false;
  }
  for (final field in [
    'computeUnitLimit',
    'heapSize',
    'loadedAccountsDataSizeLimit',
  ]) {
    final value = config[field];
    if (value != null && (!_safeInt(value) || value > 0xffffffff)) {
      return false;
    }
  }
  final priority = config['priorityFee'];
  return priority == null || _safeInt(priority);
}

String _decimal(BigInt amount, int places) {
  final digits = amount.toString().padLeft(places + 1, '0');
  if (places == 0) return digits;
  final split = digits.length - places;
  return '${digits.substring(0, split)}.${digits.substring(split)}'
      .replaceFirst(RegExp(r'\.?0+$'), '');
}

/// Conservative local parser. Unknown or ambiguous activity never becomes a swap.
/// Transfers require parsed instructions and matching balance evidence. No signing.
WalletActivity normalizeDirectActivity(
  String wallet,
  Map<String, dynamic> info,
  Object? raw,
) {
  final signature = info['signature'] as String;
  var status = info['err'] != null ? 'failed' : 'unavailable';
  String? fee;
  WalletActivity result({
    String? issue,
    ActivityAsset? input,
    ActivityAsset? output,
  }) => WalletActivity(
    id: signature,
    signature: signature,
    blockTime: info['blockTime'] as int?,
    status: status,
    type: input != null && output != null ? 'swap' : 'other',
    source: input == null ? null : 'Jupiter',
    fee: fee,
    issue: issue,
    input: input,
    output: output,
  );
  if (status == 'failed') return result();
  if (raw == null) return result(issue: 'transaction-unavailable');
  try {
    final tx = Map<String, dynamic>.from(raw as Map);
    final transaction = tx['transaction'] as Map;
    final meta = tx['meta'] as Map;
    final message = transaction['message'] as Map;
    if (!_supportedTransactionEnvelope(tx, message)) {
      return result(issue: 'parse-unavailable');
    }
    final keys = (message['accountKeys'] as List).cast<Map>();
    final instructions = (message['instructions'] as List).cast<Map>();
    final pre = (meta['preTokenBalances'] as List).cast<Map>();
    final post = (meta['postTokenBalances'] as List).cast<Map>();
    if ((transaction['signatures'] as List).first != signature ||
        !meta.containsKey('err') ||
        !_safeInt(meta['fee']) ||
        (tx['blockTime'] != null && !_safeInt(tx['blockTime'])) ||
        keys.isEmpty ||
        keys.map((k) => k['pubkey']).toSet().length != keys.length ||
        keys.any(
          (k) =>
              !_base58Size(k['pubkey'], 32) ||
              k['signer'] is! bool ||
              k['writable'] is! bool,
        ) ||
        instructions.any((i) => !_base58Size(i['programId'], 32))) {
      return result(issue: 'parse-unavailable');
    }
    fee = _decimal(BigInt.from(meta['fee'] as int), 9);
    if (meta['err'] != null) {
      status = 'failed';
      return result();
    }
    status = 'success';
    final transfer = _verifiedTransfer(
      wallet,
      signature,
      info['blockTime'] as int?,
      fee,
      keys,
      instructions,
      meta,
      pre,
      post,
    );
    if (transfer != null) return transfer;
    if (!keys.any((k) => k['pubkey'] == wallet && k['signer'] == true)) {
      return result(issue: 'unsupported-activity');
    }
    final matches = instructions
        .where((i) => i['programId'] == _jupiter)
        .toList();
    if (matches.length != 1) return result(issue: 'unsupported-activity');
    final instruction = matches.single;
    final data = base58.decode(instruction['data'] as String);
    if (data.length < 8) return result(issue: 'parse-unavailable');
    final tag = data
        .take(8)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    final route = _routes[tag];
    if (route == null) return result(issue: 'unsupported-activity');
    final accounts = (instruction['accounts'] as List).cast<String>();
    if (accounts.length <= route.$3 || accounts[route.$1] != wallet) {
      return result(issue: 'unsupported-activity');
    }
    for (final other in instructions) {
      if (identical(other, instruction) || other['programId'] == _compute) {
        continue;
      }
      if (other['programId'] == _associated &&
          other['parsed'] is Map &&
          other['parsed']['type'] == 'createIdempotent') {
        continue;
      }
      return result(issue: 'unsupported-activity');
    }
    final deltas = <String, (BigInt, int)>{};
    for (final (balances, sign) in [(pre, -1), (post, 1)]) {
      final seen = <int>{};
      for (final b in balances) {
        final amount = b['uiTokenAmount'] as Map;
        final atomic = amount['amount'];
        final decimals = amount['decimals'];
        final index = b['accountIndex'];
        if (!_safeInt(index) ||
            index >= keys.length ||
            !seen.add(index as int) ||
            !_base58Size(b['mint'], 32) ||
            (b['owner'] != null && !_base58Size(b['owner'], 32)) ||
            atomic is! String ||
            !RegExp(r'^\d{1,40}$').hasMatch(atomic) ||
            decimals is! int ||
            decimals < 0 ||
            decimals > 18) {
          return result(issue: 'parse-unavailable');
        }
        if (b['owner'] != wallet) continue;
        if (b['programId'] != null && b['programId'] != _token) {
          return result(issue: 'unsupported-activity');
        }
        final mint = b['mint'] as String;
        final old = deltas[mint];
        if (old != null && old.$2 != decimals) {
          return result(issue: 'parse-unavailable');
        }
        deltas[mint] = (
          (old?.$1 ?? BigInt.zero) + BigInt.parse(atomic) * BigInt.from(sign),
          decimals,
        );
      }
    }
    final input = deltas.entries.where((e) => e.value.$1.isNegative).toList();
    final output = deltas.entries
        .where((e) => e.value.$1 > BigInt.zero)
        .toList();
    if (input.length != 1 || output.length != 1) {
      return result(issue: 'unsupported-activity');
    }
    bool endpoint(String address, String mint, List<Map> balances) =>
        balances.any(
          (b) =>
              keys[b['accountIndex'] as int]['pubkey'] == address &&
              b['owner'] == wallet &&
              b['mint'] == mint,
        );
    if (!endpoint(accounts[route.$2], input.single.key, pre) ||
        !endpoint(accounts[route.$3], output.single.key, post)) {
      return result(issue: 'unsupported-activity');
    }
    ActivityAsset asset(MapEntry<String, (BigInt, int)> entry) => ActivityAsset(
      mint: entry.key,
      symbol:
          _symbols[entry.key] ??
          '${entry.key.substring(0, 4)}…${entry.key.substring(entry.key.length - 4)}',
      amount: _decimal(entry.value.$1.abs(), entry.value.$2),
    );
    return result(input: asset(input.single), output: asset(output.single));
  } catch (_) {
    return result(issue: 'parse-unavailable');
  }
}

/// Deliberately narrow: one top-level transfer plus compute-budget instructions.
/// No CPI, ATA creation, multisig/delegate, Token-2022 extensions or inferred swaps.
WalletActivity? _verifiedTransfer(
  String wallet,
  String signature,
  int? blockTime,
  String? fee,
  List<Map> keys,
  List<Map> instructions,
  Map meta,
  List<Map> pre,
  List<Map> post,
) {
  final actionable = instructions
      .where((i) => i['programId'] != _compute)
      .toList();
  if (actionable.length != 1) return null;
  final inner = meta['innerInstructions'];
  if (inner != null && (inner is! List || inner.isNotEmpty)) return null;
  final i = actionable.single;
  if (i['parsed'] is! Map) return null;
  final parsed = i['parsed'] as Map;
  if (parsed['info'] is! Map) return null;
  final v = parsed['info'] as Map;
  final source = v['source'], destination = v['destination'];
  if (!_base58Size(source, 32) ||
      !_base58Size(destination, 32) ||
      source == destination) {
    return null;
  }
  int index(Object? address) => keys.indexWhere((k) => k['pubkey'] == address);
  final si = index(source), di = index(destination);
  if (si < 0 ||
      di < 0 ||
      keys[si]['writable'] != true ||
      keys[di]['writable'] != true) {
    return null;
  }
  WalletActivity make(bool outgoing, ActivityAsset asset, String program) =>
      WalletActivity(
        id: signature,
        signature: signature,
        blockTime: blockTime,
        status: 'success',
        type: outgoing ? 'transfer-out' : 'transfer-in',
        source: program,
        fee: fee,
        input: outgoing ? asset : null,
        output: outgoing ? null : asset,
      );
  if (i['programId'] == _system && parsed['type'] == 'transfer') {
    final amount = v['lamports'];
    if (!_safeInt(amount) ||
        amount == 0 ||
        keys[si]['signer'] != true ||
        (source != wallet && destination != wallet) ||
        pre.isNotEmpty ||
        post.isNotEmpty) {
      return null;
    }
    final before = meta['preBalances'], after = meta['postBalances'];
    if (before is! List ||
        after is! List ||
        before.length != keys.length ||
        after.length != keys.length ||
        before.any((n) => !_safeInt(n)) ||
        after.any((n) => !_safeInt(n))) {
      return null;
    }
    for (var k = 0; k < keys.length; k++) {
      final delta =
          BigInt.from(after[k] as int) - BigInt.from(before[k] as int);
      var expected = BigInt.zero;
      if (k == si) expected -= BigInt.from(amount as int);
      if (k == di) expected += BigInt.from(amount as int);
      if (k == 0) expected -= BigInt.from(meta['fee'] as int);
      if (delta != expected) return null;
    }
    return make(
      source == wallet,
      ActivityAsset(
        mint: _system,
        symbol: 'SOL',
        amount: _decimal(BigInt.from(amount as int), 9),
      ),
      'Solana System',
    );
  }
  if (i['programId'] != _token || parsed['type'] != 'transferChecked') {
    return null;
  }
  if (!_base58Size(v['mint'], 32) ||
      !_base58Size(v['authority'], 32) ||
      !keys.any((k) => k['pubkey'] == v['authority'] && k['signer'] == true) ||
      v['tokenAmount'] is! Map) {
    return null;
  }
  final ta = v['tokenAmount'] as Map;
  final raw = ta['amount'], decimals = ta['decimals'];
  if (raw is! String ||
      !RegExp(r'^\d{1,20}$').hasMatch(raw) ||
      decimals is! int ||
      decimals < 0 ||
      decimals > 18) {
    return null;
  }
  final amount = BigInt.parse(raw);
  if (amount <= BigInt.zero || amount > (BigInt.one << 64) - BigInt.one) {
    return null;
  }
  // A single classic transfer changes exactly these two token accounts.
  // Additional balance entries could conceal unsupported compound activity.
  if (pre.length != 2 || post.length != 2) return null;
  Map? balance(List<Map> balances, int at) {
    final found = balances.where((b) => b['accountIndex'] == at).toList();
    return found.length == 1 ? found.single : null;
  }

  final sb = balance(pre, si),
      sa = balance(post, si),
      db = balance(pre, di),
      da = balance(post, di);
  if ([sb, sa, db, da].any((b) => b == null)) return null;
  BigInt? quantity(Map b) {
    if (b['mint'] != v['mint'] ||
        b['programId'] != _token ||
        !_base58Size(b['owner'], 32) ||
        b['uiTokenAmount'] is! Map) {
      return null;
    }
    final n = b['uiTokenAmount'] as Map;
    if (n['decimals'] != decimals ||
        n['amount'] is! String ||
        !RegExp(r'^\d{1,20}$').hasMatch(n['amount'] as String)) {
      return null;
    }
    final q = BigInt.parse(n['amount'] as String);
    return q <= (BigInt.one << 64) - BigInt.one ? q : null;
  }

  final quantities = [
    for (final b in [sb!, sa!, db!, da!]) quantity(b),
  ];
  if (quantities.any((q) => q == null) ||
      sb['owner'] != sa['owner'] ||
      db['owner'] != da['owner'] ||
      sb['owner'] != v['authority'] ||
      sb['owner'] == db['owner'] ||
      (sb['owner'] != wallet && db['owner'] != wallet) ||
      quantities[0]! - quantities[1]! != amount ||
      quantities[3]! - quantities[2]! != amount) {
    return null;
  }
  final mint = v['mint'] as String;
  return make(
    sb['owner'] == wallet,
    ActivityAsset(
      mint: mint,
      symbol:
          _symbols[mint] ??
          '${mint.substring(0, 4)}…${mint.substring(mint.length - 4)}',
      amount: _decimal(amount, decimals),
    ),
    'SPL Token',
  );
}

/// Read-only public RPC. Only wallet address, pagination cursor and transaction
/// signatures leave the device; this API cannot accept notes or sign/send assets.
class DirectActivityClient {
  DirectActivityClient({
    http.Client? client,
    Uri? endpoint,
    DateTime Function()? now,
    Future<void> Function(Duration)? delay,
  }) : _client = client ?? http.Client(),
       endpoint = endpoint ?? Uri.parse('https://api.mainnet.solana.com'),
       _now = now ?? DateTime.now,
       _delay = delay ?? Future<void>.delayed {
    if (this.endpoint.scheme != 'https' ||
        this.endpoint.host.isEmpty ||
        this.endpoint.userInfo.isNotEmpty) {
      throw const DirectActivityError('rpc-not-configured');
    }
  }
  final http.Client _client;
  final Uri endpoint;
  final DateTime Function() _now;
  final Future<void> Function(Duration) _delay;
  final _cache = <String, (DateTime, Map<String, dynamic>)>{};
  final _pending = <String, Future<Map<String, dynamic>>>{};
  final _queue = Queue<Completer<void>>();
  int _active = 0, _generation = 0;
  bool _closed = false;

  void clearCache() {
    _generation++;
    _cache.clear();
    _pending.clear();
  }

  void close() {
    _closed = true;
    clearCache();
    _client.close();
  }

  Map<String, dynamic> _copy(Map<String, dynamic> page) =>
      Map<String, dynamic>.from(jsonDecode(jsonEncode(page)) as Map);

  Future<Map<String, dynamic>> load(String wallet, {String? before}) async {
    if (_closed) throw const DirectActivityError('rpc-unavailable');
    if (!_base58Size(wallet, 32) ||
        (before != null && !_base58Size(before, 64))) {
      throw const DirectActivityError('invalid-input');
    }
    final key = '$wallet:${before ?? ''}';
    final cached = _cache[key];
    if (cached != null && _now().isBefore(cached.$1)) return _copy(cached.$2);
    final existing = _pending[key];
    if (existing != null) return _copy(await existing);
    final generation = _generation;
    final request = _load(wallet, before);
    _pending[key] = request;
    try {
      final page = await request;
      if (!_closed && generation == _generation) {
        if (_cache.length >= 20) _cache.remove(_cache.keys.first);
        _cache[key] = (_now().add(const Duration(seconds: 60)), _copy(page));
      }
      return page;
    } finally {
      if (identical(_pending[key], request)) _pending.remove(key);
    }
  }

  Future<Map<String, dynamic>> _load(String wallet, String? before) async {
    final result = await _rpc('getSignaturesForAddress', [
      wallet,
      {'commitment': 'finalized', 'limit': 8, 'before': ?before},
    ]);
    if (result is! List || result.length > 8) {
      throw const DirectActivityError('parse-unavailable');
    }
    final signatures = <Map<String, dynamic>>[];
    for (final row in result) {
      if (row is! Map ||
          !_base58Size(row['signature'], 64) ||
          !row.containsKey('err') ||
          !row.containsKey('blockTime') ||
          (row['blockTime'] != null && !_safeInt(row['blockTime'])) ||
          (row['confirmationStatus'] != null &&
              row['confirmationStatus'] != 'finalized')) {
        throw const DirectActivityError('parse-unavailable');
      }
      signatures.add(Map<String, dynamic>.from(row));
    }
    final items = <Map<String, dynamic>>[];
    for (var start = 0; start < signatures.length; start += 2) {
      items.addAll(
        await Future.wait(
          signatures.skip(start).take(2).map((info) async {
            final raw = info['err'] != null
                ? null
                : await _rpc('getTransaction', [
                    info['signature'],
                    {
                      'commitment': 'finalized',
                      'encoding': 'jsonParsed',
                      'maxSupportedTransactionVersion': 1,
                    },
                  ]);
            return normalizeDirectActivity(wallet, info, raw).toJson();
          }),
        ),
      );
    }
    return {
      'wallet': wallet,
      'items': items,
      'nextCursor': signatures.length == 8
          ? signatures.last['signature']
          : null,
    };
  }

  Future<http.Response> _send(String method, List<Object?> params) async {
    if (_active >= 2) {
      final permit = Completer<void>();
      _queue.add(permit);
      await permit.future;
    } else {
      _active++;
    }
    try {
      if (_closed) throw const DirectActivityError('rpc-unavailable');
      return await _client
          .post(
            endpoint,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'jsonrpc': '2.0',
              'id': 1,
              'method': method,
              'params': params,
            }),
          )
          .timeout(const Duration(seconds: 8));
    } finally {
      if (_queue.isNotEmpty) {
        _queue.removeFirst().complete();
      } else {
        _active--;
      }
    }
  }

  Duration _retryDelay(String? header) {
    if (header != null) {
      final seconds = int.tryParse(header.trim());
      if (seconds != null && seconds >= 0) {
        // A longer server cooldown is surfaced immediately, never shortened.
        return Duration(seconds: seconds > 2 ? 3 : seconds);
      }
      try {
        final until = HttpDate.parse(header).difference(_now().toUtc());
        return until.isNegative ? Duration.zero : until;
      } catch (_) {
        // Malformed Retry-After falls back to a small bounded backoff.
      }
    }
    return const Duration(milliseconds: 400);
  }

  Future<Object?> _rpc(String method, List<Object?> params) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await _send(method, params);
        if (response.statusCode == 429 || response.statusCode >= 500) {
          final retry = response.statusCode == 429
              ? _retryDelay(
                  response.headers.entries
                      .where(
                        (entry) => entry.key.toLowerCase() == 'retry-after',
                      )
                      .map((entry) => entry.value)
                      .firstOrNull,
                )
              : const Duration(milliseconds: 400);
          if (attempt == 0 && retry <= const Duration(seconds: 2)) {
            await _delay(retry);
            continue;
          }
          throw DirectActivityError(
            response.statusCode == 429
                ? 'too-many-requests'
                : 'rpc-unavailable',
          );
        }
        if (response.statusCode != 200) {
          throw const DirectActivityError('rpc-unavailable');
        }
        final body = jsonDecode(response.body);
        if (body is! Map) throw const DirectActivityError('parse-unavailable');
        if (body['error'] is Map && body['error']['code'] == -32015) {
          return null;
        }
        if (body['error'] != null || !body.containsKey('result')) {
          throw const DirectActivityError('rpc-unavailable');
        }
        return body['result'];
      } on DirectActivityError {
        rethrow;
      } on FormatException {
        throw const DirectActivityError('parse-unavailable');
      } catch (_) {
        if (attempt == 1 || _closed) {
          throw const DirectActivityError('rpc-timeout');
        }
        await _delay(const Duration(milliseconds: 400));
      }
    }
    throw const DirectActivityError('rpc-unavailable');
  }
}
