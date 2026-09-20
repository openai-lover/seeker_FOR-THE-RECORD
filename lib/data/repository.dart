import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import '../domain/models.dart';
import '../domain/trade_journal.dart';

abstract class Repository {
  Future<WorkroomState> read();
  Future<void> write(WorkroomState state);
  Future<String> rawExport();
  Future<List<TradeJournalEntry>> readJournals();
  Future<void> saveJournal(TradeJournalEntry entry);
  Future<void> deleteJournal(String id);
  Future<void> clearJournals();
}

class LocalRepository implements Repository {
  LocalRepository(this.database);
  final Database database;
  static Future<void> createJournalTable(DatabaseExecutor db) async {
    await db.execute(
      'CREATE TABLE trade_journals (id TEXT PRIMARY KEY, wallet TEXT NOT NULL, signature TEXT NOT NULL, snapshot TEXT NOT NULL, notes TEXT NOT NULL, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, UNIQUE(wallet, signature))',
    );
    await db.execute(
      'CREATE INDEX trade_journals_updated ON trade_journals(updated_at DESC)',
    );
  }

  static Future<LocalRepository> open({
    String? databasePath,
    DatabaseFactory? factory,
  }) async {
    final db = await (factory ?? databaseFactory).openDatabase(
      databasePath ?? path.join(await getDatabasesPath(), 'workroom.sqlite'),
      options: OpenDatabaseOptions(
        version: 2,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
          await db.rawQuery('PRAGMA journal_mode = WAL');
        },
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE workroom (id INTEGER PRIMARY KEY CHECK(id = 1), body TEXT NOT NULL)',
          );
          await createJournalTable(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          // Additive migration only. Never read, rewrite, or remove the existing workroom row.
          if (oldVersion < 2) await createJournalTable(db);
        },
      ),
    );
    return LocalRepository(db);
  }

  @override
  Future<WorkroomState> read() async {
    final rows = await database.query('workroom', where: 'id = 1');
    if (rows.isEmpty) return WorkroomState();
    return WorkroomState.fromJson(jsonDecode(rows.single['body'] as String));
  }

  @override
  Future<void> write(WorkroomState state) async {
    final encoded = jsonEncode(state.toJson());
    await database.transaction((tx) async {
      await tx.insert('workroom', {
        'id': 1,
        'body': encoded,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  @override
  Future<List<TradeJournalEntry>> readJournals() async =>
      (await database.query('trade_journals', orderBy: 'updated_at DESC'))
          .map(
            (r) => TradeJournalEntry.fromJson({
              'id': r['id'],
              'wallet': r['wallet'],
              'activity': jsonDecode(r['snapshot'] as String),
              'createdAt': r['created_at'],
              'updatedAt': r['updated_at'],
              ...jsonDecode(r['notes'] as String) as Map<String, dynamic>,
            }),
          )
          .toList();
  @override
  Future<void> saveJournal(TradeJournalEntry entry) async {
    if (!entry.activity.canJournal) throw StateError('unsupported-activity');
    await database.transaction((tx) async {
      final old = await tx.query(
        'trade_journals',
        where: 'wallet = ? AND signature = ?',
        whereArgs: [entry.wallet, entry.signature],
      );
      if (old.isEmpty) {
        await tx.insert('trade_journals', {
          'id': entry.id,
          'wallet': entry.wallet,
          'signature': entry.signature,
          'snapshot': jsonEncode(entry.activity.toJson()),
          'notes': jsonEncode(entry.notes),
          'created_at': entry.createdAt,
          'updated_at': entry.updatedAt,
        });
      } else {
        if (old.single['id'] != entry.id) throw StateError('journal-exists');
        if (old.single['snapshot'] != jsonEncode(entry.activity.toJson()) ||
            old.single['created_at'] != entry.createdAt) {
          throw StateError('immutable-activity');
        }
        await tx.update(
          'trade_journals',
          {'notes': jsonEncode(entry.notes), 'updated_at': entry.updatedAt},
          where: 'id = ?',
          whereArgs: [entry.id],
        );
      }
    });
  }

  @override
  Future<void> deleteJournal(String id) async {
    await database.delete('trade_journals', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> clearJournals() async {
    await database.delete('trade_journals');
  }

  @override
  Future<String> rawExport() async => jsonEncode({
    'workroom': await database.query('workroom'),
    'tradeJournals': await database.query('trade_journals'),
  });
}

class MemoryRepository implements Repository {
  WorkroomState state = WorkroomState();
  final Map<String, TradeJournalEntry> _journals = {};
  @override
  Future<WorkroomState> read() async => state.copy();
  @override
  Future<void> write(WorkroomState state) async {
    this.state = state.copy();
  }

  @override
  Future<List<TradeJournalEntry>> readJournals() async =>
      _journals.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  @override
  Future<void> saveJournal(TradeJournalEntry entry) async {
    if (!entry.activity.canJournal) throw StateError('unsupported-activity');
    final old = _journals.values
        .where(
          (e) => e.wallet == entry.wallet && e.signature == entry.signature,
        )
        .firstOrNull;
    if (old != null && old.id != entry.id) throw StateError('journal-exists');
    if (old != null &&
        (jsonEncode(old.activity.toJson()) !=
                jsonEncode(entry.activity.toJson()) ||
            old.createdAt != entry.createdAt)) {
      throw StateError('immutable-activity');
    }
    if (old == null && _journals.containsKey(entry.id)) {
      throw StateError('immutable-activity');
    }
    _journals[entry.id] = entry;
  }

  @override
  Future<void> deleteJournal(String id) async {
    _journals.remove(id);
  }

  @override
  Future<void> clearJournals() async {
    _journals.clear();
  }

  @override
  Future<String> rawExport() async => jsonEncode({
    'workroom': state.toJson(),
    'tradeJournals': _journals.values.map((e) => e.toJson()).toList(),
  });
}
