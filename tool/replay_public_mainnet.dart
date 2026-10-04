import 'dart:convert';
import 'dart:io';
import 'package:seeker_workroom/data/direct_activity.dart';

// Offline replay only. Inputs were selected from a public program, never a
// connected personal wallet. This runner makes no RPC or wallet requests.
void main(List<String> args) {
  if (args.length != 2) {
    throw ArgumentError(
      'Usage: dart run tool/replay_public_mainnet.dart inputDir output.json',
    );
  }
  final folder = Directory(args[0]);
  final infos =
      (jsonDecode(
                File(
                  '${folder.path}/public-jupiter-signatures.json',
                ).readAsStringSync().replaceFirst('\uFEFF', ''),
              )
              as Map)['result']
          as List;
  final rows = <Map<String, Object?>>[];
  for (var i = 0; i < infos.length; i++) {
    final info = Map<String, dynamic>.from(infos[i] as Map);
    final envelope =
        jsonDecode(
              File('${folder.path}/public-mainnet-$i.json').readAsStringSync(),
            )
            as Map;
    final tx = envelope['result'] as Map<String, dynamic>;
    final message = (tx['transaction'] as Map)['message'] as Map;
    final keys = (message['accountKeys'] as List).cast<Map>();
    final signer =
        keys.firstWhere((k) => k['signer'] == true)['pubkey'] as String;
    final activity = normalizeDirectActivity(signer, info, tx);
    rows.add({
      'case': i,
      'slot': tx['slot'],
      'signature': info['signature'],
      'rpcFailed': (tx['meta'] as Map)['err'] != null,
      'perspective':
          'first transaction signer; public fixture, not user wallet',
      'status': activity.status,
      'type': activity.type,
      'issue': activity.issue,
      'canJournal': activity.canJournal,
      'input': activity.input?.toJson(),
      'output': activity.output?.toJson(),
    });
  }
  File(args[1]).writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'scope':
          'Unmodified finalized public mainnet RPC responses replayed offline through current Dart parser',
      'selection':
          '${infos.length} consecutive signatures from the public Jupiter program (initial five, then ten older); no personal wallet queried',
      'rows': rows,
    }),
  );
  stdout.writeln(
    jsonEncode({
      'cases': rows.length,
      'types': rows.map((r) => '${r['status']}/${r['type']}').toList(),
    }),
  );
}
