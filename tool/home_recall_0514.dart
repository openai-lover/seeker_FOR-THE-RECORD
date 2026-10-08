import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:seeker_workroom/data/remote.dart';
import 'package:seeker_workroom/data/repository.dart';
import 'package:seeker_workroom/domain/controller.dart';
import 'package:seeker_workroom/domain/trade_journal.dart';
import 'package:seeker_workroom/platform/native.dart';
import 'package:seeker_workroom/ui/app.dart';

// Manual, isolated synthetic evidence. Does not open any SQLite database.
class NoRemote extends RemoteService {
  NoRemote(super.native, super.local) : super(directWalletEnabled: false) {
    initialized = true;
  }
  @override
  Future<void> currentRoom() async {}
  @override
  Future<void> connect() async => throw StateError('No wallet in this fixture');
  @override
  Future<Map<String, dynamic>> call(
    String action, [
    Map<String, dynamic> body = const {},
    bool authenticated = true,
  ]) async => throw StateError('No RPC in this fixture');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kDebugMode || !const bool.fromEnvironment('FTR_RECALL_0514')) {
    throw StateError('Isolated debug build required');
  }
  final root = await getDatabasesPath();
  if (!path.split(root).contains('app.workroom.seeker_workroom.integration')) {
    throw StateError('Wrong package');
  }
  final c = WorkroomController(MemoryRepository(), NativePlatform());
  await c.load();
  await c.setting('roomWelcome', 1);
  await c.setting('language', 'en');
  await c.setting('reduceMotion', true);
  const walletA = '11111111111111111111111111111111';
  const walletB = 'SysvarC1ock11111111111111111111111111111111';
  const rows = [
    (
      walletA,
      'DEMO: I trusted a social media recommendation without reading its original announcement.',
      'The claim had no primary source.',
      'Read the primary source before trusting a recommendation.',
    ),
    (
      walletA,
      'DEMO: I cooked vegetable soup for lunch.',
      'I added too much salt.',
      'Taste before adding more salt.',
    ),
    (
      walletA,
      'DEMO: I watered the basil plant.',
      'The soil was still wet.',
      'Check the soil before watering.',
    ),
    (
      walletB,
      'DEMO wallet B: I compared train departure times.',
      'I chose a later departure.',
      'Keep enough time for the connection.',
    ),
  ];
  for (var i = 0; i < rows.length; i++) {
    final r = rows[i];
    final time = DateTime(2026, 10, 7, 10 + i).millisecondsSinceEpoch;
    await c.journals.save(
      TradeJournalEntry(
        id: 'recall-demo-$i',
        wallet: r.$1,
        activity: WalletActivity(
          id: 'demo-$i',
          signature: 'SYNTHETIC-NOT-ON-CHAIN-$i',
          status: 'success',
          type: 'other',
          issue: 'unsupported-activity',
        ),
        createdAt: time,
        updatedAt: time,
        reason: r.$2,
        review: r.$3,
        decisionRule: r.$4,
      ),
    );
  }
  runApp(WorkroomApp(controller: c, remote: NoRemote(NativePlatform(), c)));
}
