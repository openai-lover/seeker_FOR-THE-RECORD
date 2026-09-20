import 'package:flutter/foundation.dart';
import '../data/repository.dart';
import 'trade_journal.dart';

class TradeJournalController extends ChangeNotifier {
  TradeJournalController(this.repository);
  final Repository repository;
  List<TradeJournalEntry> entries = [];
  String? error;
  bool loading = false;
  Future<void> _writes = Future.value();
  TradeJournalEntry? find(String wallet, String signature) => entries
      .where((e) => e.wallet == wallet && e.signature == signature)
      .firstOrNull;
  Future<void> load() async {
    loading = true;
    notifyListeners();
    try {
      entries = await repository.readJournals();
      error = null;
    } catch (_) {
      error = 'journal-read-failed';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _write(Future<void> Function() action) {
    final result = _writes.then((_) async {
      await action();
      entries = await repository.readJournals();
      error = null;
      notifyListeners();
    });
    _writes = result.catchError((_) {});
    return result;
  }

  Future<void> save(TradeJournalEntry entry) =>
      _write(() => repository.saveJournal(entry));
  Future<void> delete(String id) => _write(() => repository.deleteJournal(id));
  Future<void> clear() => _write(repository.clearJournals);
}
