import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:seeker_workroom/data/direct_activity.dart';

// Offline check of one freshly fetched historical public response. No RPC/DB.
void main(List<String> args) {
  if (args.length != 2) {
    throw ArgumentError(
      'Usage: check_refreshed_case8_0512.dart workDir receipt.json',
    );
  }
  final directory = Directory(args[0]);
  final protocolFile = File('${directory.path}/frozen-protocol.json');
  final protocol = jsonDecode(protocolFile.readAsStringSync()) as Map;
  final fetched =
      jsonDecode(
            File('${directory.path}/fetch-receipt.json').readAsStringSync(),
          )
          as Map;
  final attempts = (fetched['attempts'] as List).cast<Map>();
  final available = fetched['available'] == true;
  final output = <String, Object?>{
    'appSource': protocol['sourceAppTag'],
    'parserSha256': sha256
        .convert(File('lib/data/direct_activity.dart').readAsBytesSync())
        .toString(),
    'protocolSha256': sha256.convert(protocolFile.readAsBytesSync()).toString(),
    'responseAvailable': available,
    'sameKnownHistoricalCase': true,
    'notHeldOutOrOwnerFlow': true,
    'deviceExecuted': false,
    'scope':
        'Current production parser, executed offline against one freshly retrieved known historical public RPC response.',
  };
  if (available) {
    final file = File('${directory.path}/${attempts.last['responseFile']}');
    final response = jsonDecode(file.readAsStringSync()) as Map;
    final tx = Map<String, dynamic>.from(response['result'] as Map);
    final keys =
        (((tx['transaction'] as Map)['message'] as Map)['accountKeys'] as List)
            .cast<Map>();
    final signer =
        keys.firstWhere((key) => key['signer'] == true)['pubkey'] as String;
    final info = Map<String, dynamic>.from(
      protocol['historicalSignatureInfo'] as Map,
    );
    final activity = normalizeDirectActivity(signer, info, tx);
    output.addAll({
      'responseSha256': sha256.convert(file.readAsBytesSync()).toString(),
      'resultEqualsHistoricalFixture': fetched['resultEqualsHistoricalFixture'],
      'perspective':
          'First signer from the public response; ownership not asserted.',
      'version': tx['version'],
      'slot': tx['slot'],
      'status': activity.status,
      'type': activity.type,
      'issue': activity.issue,
      'canJournal': activity.canJournal,
      'canRecordReason': activity.canRecordReason,
      'input': activity.input?.toJson(),
      'output': activity.output?.toJson(),
      'activity': activity.toJson(),
    });
  } else {
    output['outcome'] =
        'No successful parser classification claimed: result null or retained error.';
  }
  File(
    args[1],
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(output));
  stdout.writeln(
    jsonEncode({
      'available': output['responseAvailable'],
      'status': output['status'],
      'type': output['type'],
      'canJournal': output['canJournal'],
      'canRecordReason': output['canRecordReason'],
      'parserSha256': output['parserSha256'],
    }),
  );
}
