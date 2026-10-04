import 'package:flutter/services.dart';
import '../domain/trade_journal.dart';
import 'reflection_assistant.dart';

/// Quotes come from local storage, never from a generated model response.
class RelatedRecord {
  const RelatedRecord(this.entry, this.score);
  final TradeJournalEntry entry;
  final double score;
}

class RelatedRecords {
  const RelatedRecords();
  // Conservative product heuristics, not calibrated probabilities. Abstain
  // when the best candidate is weak or nearly tied; manual browsing remains.
  static List<int> choose(List<double> scores) {
    if (scores.isEmpty ||
        scores.any((s) => !s.isFinite || s < -1.001 || s > 1.001)) {
      return [];
    }
    final order = List<int>.generate(scores.length, (i) => i)
      ..sort((a, b) {
        final value = scores[b].compareTo(scores[a]);
        return value == 0 ? a.compareTo(b) : value;
      });
    final best = scores[order.first];
    if (best < .82 || (order.length > 1 && best - scores[order[1]] < .018)) {
      return [];
    }
    // Nearby scores do not establish that additional records are relevant.
    // Offer one original source; the user can browse all records separately.
    return [order.first];
  }

  static String clip(String s) =>
      String.fromCharCodes(s.trim().runes.take(480));
  static String evidence(TradeJournalEntry e) => [
    String.fromCharCodes((e.originalReason ?? e.reason).trim().runes.take(160)),
    String.fromCharCodes(e.review.trim().runes.take(160)),
    String.fromCharCodes(e.decisionRule.trim().runes.take(160)),
  ].where((s) => s.isNotEmpty).join('\n');

  static List<TradeJournalEntry> candidates(
    Iterable<TradeJournalEntry> entries,
    String wallet,
    String? currentId,
  ) {
    final seen = <String>{};
    final selected =
        entries
            .where(
              (e) =>
                  e.wallet == wallet &&
                  e.id != currentId &&
                  evidence(e).isNotEmpty &&
                  seen.add(e.id),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return selected.take(32).toList();
  }

  Future<List<RelatedRecord>> search(
    String query,
    List<TradeJournalEntry> records,
  ) async {
    final text = clip(query);
    if (text.isEmpty || records.isEmpty) return [];
    if (records.length > 32) throw ArgumentError('At most 32 records');
    final result = await ReflectionAssistant.channel
        .invokeMapMethod<String, dynamic>('rank', {
          'query': text,
          'records': records.map(evidence).toList(),
        });
    final values = result?['scores'];
    if (values is! List ||
        values.length != records.length ||
        values.any(
          (v) => v is! num || !v.toDouble().isFinite || v < -1.001 || v > 1.001,
        )) {
      throw PlatformException(code: 'invalid-answer');
    }
    final scores = values.map((v) => (v as num).toDouble()).toList();
    return [
      for (final i in choose(scores)) RelatedRecord(records[i], scores[i]),
    ];
  }
}
