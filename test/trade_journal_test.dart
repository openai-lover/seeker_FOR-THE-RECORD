import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:seeker_workroom/data/repository.dart';
import 'package:seeker_workroom/domain/trade_journal.dart';
import 'package:seeker_workroom/domain/trade_journal_controller.dart';

const activity = WalletActivity(
  id: 'activity-1',
  signature: 'signature-1',
  blockTime: 1700000000,
  status: 'success',
  type: 'swap',
  source: 'Jupiter',
  fee: '0.000005',
  input: ActivityAsset(mint: 'usdc', symbol: 'USDC', amount: '250'),
  output: ActivityAsset(mint: 'wsol', symbol: 'wSOL', amount: '1.42'),
);
const entry = TradeJournalEntry(
  id: 'journal-1',
  wallet: 'wallet-1',
  activity: activity,
  createdAt: 1,
  updatedAt: 1,
  reason: 'My reason',
  plan: 'My plan',
  emotion: 'calm',
  nextAction: 'Check assumptions',
);
void main() {
  test(
    'serialization retains exact amounts, immutable facts and personal thoughts',
    () {
      final result = TradeJournalEntry.fromJson(
        jsonDecode(jsonEncode(entry.toJson())),
      );
      expect(result.toJson(), entry.toJson());
      final edited = result.edit(
        reason: 'Updated',
        projectId: 'p1',
        updatedAt: 2,
      );
      expect(edited.activity, same(result.activity));
      expect(edited.createdAt, 1);
      expect(edited.wallet, result.wallet);
      expect(edited.plan, result.plan);
      expect(edited.emotion, result.emotion);
      expect(edited.nextAction, result.nextAction);
    },
  );
  test(
    'review edits preserve notes and can explicitly clear a project or note',
    () {
      final linked = entry.edit(projectId: 'project-1', updatedAt: 2);
      final reflected = linked.edit(review: 'A new lesson', updatedAt: 3);
      expect(reflected.projectId, 'project-1');
      expect(reflected.reason, entry.reason);
      expect(reflected.plan, entry.plan);
      expect(reflected.emotion, entry.emotion);
      expect(reflected.nextAction, entry.nextAction);
      final cleared = reflected.edit(projectId: null, plan: '', updatedAt: 4);
      expect(cleared.projectId, isNull);
      expect(cleared.plan, isEmpty);
      expect(cleared.review, 'A new lesson');
      expect(cleared.reason, entry.reason);
    },
  );
  test(
    'create/edit/delete and wallet/signature uniqueness in local repository',
    () async {
      final store = MemoryRepository(),
          controller = TradeJournalController(MemoryRepository());
      await store.saveJournal(entry);
      await expectLater(
        store.saveJournal(
          TradeJournalEntry(
            id: 'duplicate',
            wallet: entry.wallet,
            activity: activity,
            createdAt: 2,
            updatedAt: 2,
          ),
        ),
        throwsStateError,
      );
      await store.saveJournal(
        entry.edit(reason: 'Reconsidered', review: 'Learned', updatedAt: 3),
      );
      expect((await store.readJournals()).single.review, 'Learned');
      await controller.load();
      await controller.save(entry);
      expect(controller.find('wallet-1', 'signature-1'), isNotNull);
      await controller.delete(entry.id);
      expect(controller.entries, isEmpty);
      controller.dispose();
    },
  );
  test(
    'real SQLite v1 to v2 migration preserves original JSON bytes and journals survive reopen',
    () async {
      sqfliteFfiInit();
      final dir = await Directory.systemTemp.createTemp('workroom-migration-');
      final path = '${dir.path}/workroom.sqlite';
      final original =
          ' {"schemaVersion":1,"projects":[],"sessions":[],"settings":{"notifications":true,"sentinel":"preserve me"},"pendingOrder":null} ';
      final old = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute(
              'CREATE TABLE workroom (id INTEGER PRIMARY KEY CHECK(id = 1), body TEXT NOT NULL)',
            );
            await db.insert('workroom', {'id': 1, 'body': original});
          },
        ),
      );
      await old.close();
      var repository = await LocalRepository.open(
        databasePath: path,
        factory: databaseFactoryFfi,
      );
      expect(
        (await repository.database.query('workroom')).single['body'],
        original,
      );
      expect((await repository.read()).settings['sentinel'], 'preserve me');
      await repository.saveJournal(entry);
      await expectLater(
        repository.saveJournal(
          TradeJournalEntry(
            id: 'duplicate',
            wallet: entry.wallet,
            activity: activity,
            createdAt: 1,
            updatedAt: 1,
          ),
        ),
        throwsStateError,
      );
      await repository.saveJournal(
        entry.edit(review: 'After reflection', updatedAt: 2),
      );
      await repository.database.close();
      repository = await LocalRepository.open(
        databasePath: path,
        factory: databaseFactoryFfi,
      );
      expect(
        (await repository.readJournals()).single.review,
        'After reflection',
      );
      expect(
        (await repository.database.query('workroom')).single['body'],
        original,
      );
      await repository.deleteJournal(entry.id);
      expect(await repository.readJournals(), isEmpty);
      expect(
        (await repository.database.query('workroom')).single['body'],
        original,
      );
      await repository.database.close();
      // Only the test's private temporary directory is removed.
      await dir.delete(recursive: true);
    },
  );
}
