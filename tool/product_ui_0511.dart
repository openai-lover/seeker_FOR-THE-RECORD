import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:seeker_workroom/data/direct_activity.dart';
import 'package:seeker_workroom/data/remote.dart';
import 'package:seeker_workroom/data/repository.dart';
import 'package:seeker_workroom/domain/controller.dart';
import 'package:seeker_workroom/domain/trade_journal.dart';
import 'package:seeker_workroom/platform/native.dart';
import 'package:seeker_workroom/ui/app.dart';
import 'public_flow_fixtures_0510.dart';
import 'fresh_eval_0510.dart';

// Manually install only as .integration. Public fixtures plus authored notes;
// never loads production data, connects a wallet, or changes the wall clock.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: PublicReplayMenu()));
}

List<Map<String, dynamic>> fixtures() =>
    (jsonDecode(publicFlowFixtureJson) as List).cast<Map<String, dynamic>>();

class PublicReplayMenu extends StatelessWidget {
  const PublicReplayMenu({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('0.5.11 · public mainnet replay')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'PHYSICAL SEEKER · ISOLATED DEBUG\nActual product UI, parser, SQLite and native AI\nPublic finalized responses captured October 4\nAuthored notes · no wallet connection or new trade',
        ),
        FilledButton(
          onPressed: launchProductSettings,
          child: const Text('Product settings · empty local state'),
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const FreshEvaluation0510(),
            ),
          ),
          child: const Text('Fresh AI diagnostic · 48 queries'),
        ),
        for (final row in fixtures()) ...[
          FilledButton(
            onPressed: () => launchPublicReplay(row),
            child: Text(switch (row['index']) {
              8 => 'Supported Jupiter swap · case 8',
              0 => 'Successful Other · case 0',
              _ => 'Failed activity · case 2',
            }),
          ),
          const SizedBox(height: 12),
        ],
        const Text(
          'The wallet shown belongs to this public transaction perspective. Ownership is not asserted. Notes are demonstration text, not the trader’s reasons. This is an offline replay, not a live personal account flow.',
        ),
      ],
    ),
  );
}

class PublicReplayRemote extends RemoteService {
  PublicReplayRemote(super.native, super.local, this.row, String address)
    : super(directWalletEnabled: false) {
    initialized = true;
    wallet = address;
  }
  final Map<String, dynamic> row;
  @override
  bool get directMode => false;
  @override
  bool get onlineAvailable => true;
  @override
  String? get uid => 'PUBLIC-FIXTURE-${row['index']}';
  @override
  Future<void> currentRoom() async {}
  @override
  Future<void> connect() async =>
      throw StateError('Replay has no wallet connection');
  @override
  Future<Map<String, dynamic>> call(
    String action, [
    Map<String, dynamic> body = const {},
    bool authenticated = true,
  ]) async {
    if (action != 'wallet-activity') throw StateError('Read-only replay');
    final tx = Map<String, dynamic>.from((row['rpc'] as Map)['result'] as Map);
    final activity = normalizeDirectActivity(
      wallet!,
      Map<String, dynamic>.from(row['signatureInfo'] as Map),
      tx,
    );
    debugPrintSynchronously(
      'FTR_PUBLIC_FLOW ${jsonEncode({'kind': 'parser', 'case': row['index'], 'type': activity.type, 'status': activity.status, 'input': activity.input?.toJson(), 'output': activity.output?.toJson(), 'rawSha256': row['rawSha256']})}',
    );
    return {
      'wallet': wallet,
      'items': [activity.toJson()],
      'nextCursor': null,
    };
  }
}

Future<void> launchPublicReplay(Map<String, dynamic> row) async {
  final tx = (row['rpc'] as Map)['result'] as Map;
  final keys =
      ((tx['transaction'] as Map)['message'] as Map)['accountKeys'] as List;
  final address =
      (keys.cast<Map>().firstWhere((k) => k['signer'] == true))['pubkey']
          as String;
  final repository = await LocalRepository.open(
    databasePath: path.join(
      await getDatabasesPath(),
      'public-mainnet-flow-0510.sqlite',
    ),
  );
  final c = WorkroomController(repository, NativePlatform());
  await c.load();
  await c.setting('roomWelcome', 1);
  await c.setting('language', 'en');
  // Seeded comparison records are explicitly authored, not historical user data.
  final notes = [
    (
      'Demo: I copied a popular claim before reading the original announcement.',
      'The claim had no primary source.',
      'Read the original announcement before following a recommendation.',
    ),
    (
      'Demo: I booked a train ticket before checking the departure station.',
      'I went to the wrong station.',
      'Check the exact departure station before booking.',
    ),
    (
      'Demo: I added salt before tasting the vegetable soup.',
      'The soup tasted too salty.',
      'Taste the soup before adding salt.',
    ),
  ];
  for (var i = 0; i < notes.length; i++) {
    final signature = 'SYNTHETIC-PUBLIC-REPLAY-NOTE-$i';
    if (c.journals.find(address, signature) != null) continue;
    final created = DateTime(2026, 10, 3, 10 + i).millisecondsSinceEpoch;
    await c.journals.save(
      TradeJournalEntry(
        id: 'public-demo-${row['index']}-$i',
        wallet: address,
        activity: WalletActivity(
          id: signature,
          signature: signature,
          status: 'success',
          type: 'other',
          issue: 'unsupported-activity',
        ),
        createdAt: created,
        updatedAt: created,
        reason: notes[i].$1,
        review: notes[i].$2,
        decisionRule: notes[i].$3,
      ),
    );
  }
  runApp(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: [
          const ColoredBox(
            color: Color(0xff263c34),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  child: Text(
                    '0.5.11 UI · PUBLIC REPLAY · AUTHORED NOTES',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: WorkroomApp(
              controller: c,
              remote: PublicReplayRemote(NativePlatform(), c, row, address),
            ),
          ),
        ],
      ),
    ),
  );
}

// Empty authored state for checking Settings without opening personal records.
Future<void> launchProductSettings() async {
  final c = WorkroomController(MemoryRepository(), NativePlatform());
  await c.load();
  await c.setting('roomWelcome', 1);
  await c.setting('language', 'en');
  runApp(
    WorkroomApp(controller: c, remote: RemoteService(NativePlatform(), c)),
  );
}
