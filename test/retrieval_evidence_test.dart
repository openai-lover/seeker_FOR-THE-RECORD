import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:seeker_workroom/data/related_records.dart';

void main() {
  test(
    'post-hoc policy replay reports abstentions, never claims held-out accuracy',
    () {
      final data =
          jsonDecode(
                File(
                  'docs/evidence/retrieval-eval-056.json',
                ).readAsStringSync().replaceFirst('\ufeff', ''),
              )
              as Map;
      final events = (data['events'] as List).cast<Map>();
      var shown = 0, abstained = 0;
      for (final row in events.where((e) => e['kind'] == 'row')) {
        final scores = (row['scores'] as List)
            .map((n) => (n as num).toDouble())
            .toList();
        final selected = RelatedRecords.choose(scores);
        if (selected.isEmpty) {
          abstained++;
        } else {
          shown++;
          expect(selected.first, row['expected']);
        }
      }
      expect(shown, 18);
      expect(abstained, 14);
      for (final probe in events.where((e) => e['kind'] == 'probe')) {
        final scores = (probe['result']['scores'] as List)
            .map((n) => (n as num).toDouble())
            .toList();
        expect(RelatedRecords.choose(scores), isEmpty);
      }
    },
  );
}
