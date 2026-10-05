import 'dart:convert';
import 'dart:io';
import 'package:bs58/bs58.dart';
import 'package:seeker_workroom/data/direct_activity.dart';

// Evidence-only offline replay. No RPC client, wallet, app database or model.
const jupiterProtocolProgram = 'JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4';
const protocolTokenProgram = 'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA';
const protocolSystemProgram = '11111111111111111111111111111111';
const protocolComputeProgram = 'ComputeBudget111111111111111111111111111111';
const protocolRoutes = <String, (int, int, int)>{
  'e517cb977ae3ad2a': (1, 2, 3),
  'd033ef977b2bed5c': (1, 2, 3),
  'c1209b3341d69c81': (2, 3, 6),
  'b0d169a89a7d453e': (2, 3, 6),
};

Map<String, Object?> inspectClassifiedProof(
  Map tx,
  String signer,
  Map activity,
) {
  final message = (tx['transaction'] as Map)['message'] as Map;
  final keys = (message['accountKeys'] as List).cast<Map>();
  final meta = tx['meta'] as Map;
  final instructions = (message['instructions'] as List).cast<Map>();
  final pre = (meta['preTokenBalances'] as List).cast<Map>();
  final post = (meta['postTokenBalances'] as List).cast<Map>();
  Map? balance(List<Map> list, String address) {
    final found = list
        .where((b) => keys[b['accountIndex'] as int]['pubkey'] == address)
        .toList();
    return found.length == 1 ? found.single : null;
  }

  BigInt atomic(Map b) =>
      BigInt.parse((b['uiTokenAmount'] as Map)['amount'] as String);
  String exact(BigInt amount, int decimals) {
    final s = amount.toString().padLeft(decimals + 1, '0');
    if (decimals == 0) return s;
    return '${s.substring(0, s.length - decimals)}.${s.substring(s.length - decimals)}'
        .replaceFirst(RegExp(r'\.?0+$'), '');
  }

  if (activity['type'] == 'swap') {
    final routes = instructions
        .where((i) => i['programId'] == jupiterProtocolProgram)
        .toList();
    final route = routes.single;
    final tag = base58
        .decode(route['data'] as String)
        .take(8)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    final positions = protocolRoutes[tag]!;
    final accounts = (route['accounts'] as List).cast<String>();
    final sb = balance(pre, accounts[positions.$2])!,
        sa = balance(post, accounts[positions.$2]);
    final da = balance(post, accounts[positions.$3])!,
        db = balance(pre, accounts[positions.$3]);
    final input = atomic(sb) - (sa == null ? BigInt.zero : atomic(sa));
    final output = atomic(da) - (db == null ? BigInt.zero : atomic(db));
    final inputDecimals = (sb['uiTokenAmount'] as Map)['decimals'] as int;
    final outputDecimals = (da['uiTokenAmount'] as Map)['decimals'] as int;
    final tokenRows = [sb, ?sa, da, ?db];
    final checks = <String, bool>{
      'oneTopLevelJupiterRoute': routes.length == 1,
      'knownDiscriminator': protocolRoutes.containsKey(tag),
      'routeAuthorityIsFirstSigner': accounts[positions.$1] == signer,
      'ownedEndpoints': tokenRows.every((b) => b['owner'] == signer),
      'classicTokenEndpoints': tokenRows.every(
        (b) => b['programId'] == protocolTokenProgram,
      ),
      'positiveInputAndOutput': input > BigInt.zero && output > BigInt.zero,
      'inputMintMatches': (activity['input'] as Map)['mint'] == sb['mint'],
      'outputMintMatches': (activity['output'] as Map)['mint'] == da['mint'],
      'inputExactEndpointDeltaMatches':
          (activity['input'] as Map)['amount'] == exact(input, inputDecimals),
      'outputExactEndpointDeltaMatches':
          (activity['output'] as Map)['amount'] ==
          exact(output, outputDecimals),
    };
    return {
      'kind': 'exact-route-endpoint-balance-inspection',
      'checks': checks,
      'allChecksPass': checks.values.every((v) => v),
      'routeTag': tag,
      'authority': accounts[positions.$1],
      'sourceAccount': accounts[positions.$2],
      'destinationAccount': accounts[positions.$3],
      'inputMint': sb['mint'],
      'outputMint': da['mint'],
      'inputAtomic': input.toString(),
      'outputAtomic': output.toString(),
      'inputDecimals': inputDecimals,
      'outputDecimals': outputDecimals,
      'scope':
          'Agent mechanical inspection from retained public raw response, not independent accuracy.',
    };
  }
  final actionable = instructions
      .where((i) => i['programId'] != protocolComputeProgram)
      .toList();
  final instruction = actionable.single,
      parsed = instruction['parsed'] as Map,
      info = parsed['info'] as Map;
  final source = info['source'] as String,
      destination = info['destination'] as String;
  final si = keys.indexWhere((k) => k['pubkey'] == source),
      di = keys.indexWhere((k) => k['pubkey'] == destination);
  final checks = <String, bool>{
    'oneTopLevelAction': actionable.length == 1,
    'noInnerInstructions': (meta['innerInstructions'] as List? ?? []).isEmpty,
    'successfulMeta': meta['err'] == null,
  };
  if (instruction['programId'] == protocolSystemProgram) {
    final before = (meta['preBalances'] as List).cast<int>(),
        after = (meta['postBalances'] as List).cast<int>();
    final amount = BigInt.from(info['lamports'] as int),
        fee = BigInt.from(meta['fee'] as int);
    final deltas = [
      for (var i = 0; i < keys.length; i++)
        BigInt.from(after[i]) - BigInt.from(before[i]),
    ];
    checks['sourceSigner'] = keys[si]['signer'] == true;
    checks['sourceOrDestinationIsContext'] =
        source == signer || destination == signer;
    checks['allNativeDeltasMatchExactTransferAndFee'] = [
      for (var i = 0; i < keys.length; i++)
        deltas[i] ==
            (i == si ? -amount : BigInt.zero) +
                (i == di ? amount : BigInt.zero) -
                (i == 0 ? fee : BigInt.zero),
    ].every((v) => v);
    final asset = (activity['input'] ?? activity['output']) as Map;
    checks['amountMatches'] = asset['amount'] == exact(amount, 9);
    return {
      'kind': 'exact-system-transfer-balance-inspection',
      'checks': checks,
      'allChecksPass': checks.values.every((v) => v),
      'sourceAccount': source,
      'destinationAccount': destination,
      'amountAtomic': amount.toString(),
      'nativeDeltas': deltas.map((d) => d.toString()).toList(),
      'feeAtomic': fee.toString(),
      'scope':
          'Agent mechanical inspection from retained public raw response, not independent accuracy.',
    };
  }
  final sb = balance(pre, source)!,
      sa = balance(post, source)!,
      db = balance(pre, destination)!,
      da = balance(post, destination)!;
  final ta = info['tokenAmount'] as Map,
      amount = BigInt.parse(ta['amount'] as String),
      decimals = ta['decimals'] as int;
  checks.addAll({
    'classicTransferChecked':
        instruction['programId'] == protocolTokenProgram &&
        parsed['type'] == 'transferChecked',
    'sourceAuthorityMatches': sb['owner'] == info['authority'],
    'authorityIsSigner': keys.any(
      (k) => k['pubkey'] == info['authority'] && k['signer'] == true,
    ),
    'stableOwners': sb['owner'] == sa['owner'] && db['owner'] == da['owner'],
    'ownersDifferent': sb['owner'] != db['owner'],
    'exactSourceDelta': atomic(sb) - atomic(sa) == amount,
    'exactDestinationDelta': atomic(da) - atomic(db) == amount,
    'allMintAndProgramMatch': [sb, sa, db, da].every(
      (b) =>
          b['mint'] == info['mint'] && b['programId'] == protocolTokenProgram,
    ),
    'amountMatches':
        ((activity['input'] ?? activity['output']) as Map)['amount'] ==
        exact(amount, decimals),
  });
  return {
    'kind': 'exact-classic-transferChecked-balance-inspection',
    'checks': checks,
    'allChecksPass': checks.values.every((v) => v),
    'sourceAccount': source,
    'destinationAccount': destination,
    'sourceOwner': sb['owner'],
    'destinationOwner': db['owner'],
    'authority': info['authority'],
    'mint': info['mint'],
    'amountAtomic': amount.toString(),
    'decimals': decimals,
    'scope':
        'Agent mechanical inspection from retained public raw response, not independent accuracy.',
  };
}

Map<String, Object?> evaluateCapturedRow(Map row, Directory folder) {
  final answer = <String, Object?>{
    ...row,
    'perspective':
        'First transaction signer; public fixture, not personal-wallet ownership',
    'parserInvoked': false,
  };
  final info = row['selectionInfo'];
  answer['listingFailed'] = info is Map && info['err'] != null;
  answer['productionFetchNote'] = info is Map && info['err'] != null
      ? 'Production client skips getTransaction and preserves failed listing; this evidence protocol deliberately fetched all selected rows.'
      : 'A successful listing still requires supported available transaction/context before parser replay.';
  if (row['transactionFile'] is String &&
      row['fetchState'] != 'transaction-available') {
    try {
      final rawError = jsonDecode(
        File('${folder.path}/${row['transactionFile']}').readAsStringSync(),
      );
      if (rawError is Map && rawError['error'] is Map) {
        answer['captureRpcError'] = rawError['error'];
      }
    } catch (_) {
      /* Capture failures stay unreplayed; never infer a transaction. */
    }
  }
  if (info is! Map || row['fetchState'] != 'transaction-available') {
    answer['evaluationState'] =
        'not-replayed-unavailable-selection-or-response';
    return answer;
  }
  final name = row['transactionFile'];
  if (name is! String) {
    answer['evaluationState'] = 'not-replayed-missing-response-path';
    return answer;
  }
  try {
    final env = jsonDecode(File('${folder.path}/$name').readAsStringSync());
    if (env is! Map || env['error'] != null || env['result'] is! Map) {
      answer['evaluationState'] = 'not-replayed-null-or-error-response';
      return answer;
    }
    final tx = env['result'] as Map;
    final keys =
        (((tx['transaction'] as Map)['message'] as Map)['accountKeys'] as List)
            .cast<Map>();
    final signers = keys.where((k) => k['signer'] == true).toList();
    if (signers.isEmpty || signers.first['pubkey'] is! String) {
      answer['evaluationState'] = 'not-replayed-missing-first-signer';
      return answer;
    }
    final signer = signers.first['pubkey'] as String;
    final activity = normalizeDirectActivity(
      signer,
      Map<String, dynamic>.from(info),
      tx,
    ).toJson();
    answer.addAll({
      'parserInvoked': true,
      'evaluationState': 'replayed',
      'context': signer,
      'signerCount': signers.length,
      'transactionSlot': tx['slot'],
      'listingSlotMatches': info['slot'] == tx['slot'],
      'listingConfirmationStatus': info['confirmationStatus'],
      'rpcFailed': (tx['meta'] as Map?)?['err'] != null,
      'activity': activity,
    });
    if (activity['type'] != 'other') {
      try {
        answer['classifiedProof'] = inspectClassifiedProof(
          tx,
          signer,
          activity,
        );
      } catch (e) {
        answer['classifiedProof'] = {
          'allChecksPass': false,
          'inspectionError': e.runtimeType.toString(),
        };
      }
    }
    final ins =
        (((tx['transaction'] as Map)['message'] as Map)['instructions'] as List)
            .cast<Map>();
    answer['topLevelPrograms'] = ins.map((i) => i['programId']).toList();
    answer['topLevelJupiterCount'] = ins
        .where((i) => i['programId'] == jupiterProtocolProgram)
        .length;
  } catch (e) {
    answer['evaluationState'] = 'not-replayed-malformed-response';
    answer['evaluationError'] = e.runtimeType.toString();
  }
  return answer;
}

void main(List<String> args) {
  if (args.length != 2) {
    throw ArgumentError(
      'Usage: dart --packages=.dart_tool/package_config.json tool/public_parser_protocol_0511.dart captureFolder output.json',
    );
  }
  final folder = Directory(args[0]);
  final receipt =
      jsonDecode(File('${folder.path}/fetch-receipt.json').readAsStringSync())
          as Map;
  final rows = [
    for (final row in receipt['rows'] as List)
      evaluateCapturedRow(row as Map, folder),
  ];
  final groups = <String, Map<String, int>>{};
  for (final row in rows) {
    final key = 'epoch${row['epoch']}/${row['program']}';
    final activity = row['activity'] as Map?;
    final rpcError = row['captureRpcError'] as Map?;
    final outcome = activity == null
        ? (rpcError?['code'] == -32015
              ? 'unavailable/unsupported-transaction-version'
              : '${row['fetchState']}/${row['evaluationState']}')
        : '${activity['status']}/${activity['type']}';
    final g = groups.putIfAbsent(key, () => {});
    g[outcome] = (g[outcome] ?? 0) + 1;
  }
  final result = {
    'scope':
        'Public RPC fixture replay at current0.5.11 parser, not current owner live app flow. No signatures/trades/assets/model/app/DB changes.',
    'appSource': '0c5dfd70243940d6598804e9ff3d111ae920051d',
    'protocolSha256': receipt['protocolSha256'],
    'completedFetchAtUtc': receipt['completedAtUtc'],
    'rows': rows,
    'perEpochProgramOutcomes': groups,
    'selectionPositions': rows.length,
    'uniqueSignatures': receipt['uniqueSignatures'],
    'duplicateSelectionPositions': receipt['duplicateSelectionPositions'],
    'parserInvoked': rows.where((r) => r['parserInvoked'] == true).length,
    'listingFailedPositions': rows
        .where((r) => r['listingFailed'] == true)
        .length,
    'unreplayedWithSuccessfulListingPositions': rows
        .where(
          (r) =>
              r['selectionInfo'] is Map &&
              r['listingFailed'] == false &&
              r['parserInvoked'] == false,
        )
        .length,

    'classifiedProofFailures': rows
        .where(
          (r) =>
              r['classifiedProof'] is Map &&
              (r['classifiedProof'] as Map)['allChecksPass'] != true,
        )
        .length,
  };
  File(args[1]).writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(result)}\n',
  );
  stdout.writeln(
    jsonEncode({
      'positions': rows.length,
      'parserInvoked': result['parserInvoked'],
      'groups': groups,
      'proofFailures': result['classifiedProofFailures'],
    }),
  );
}
