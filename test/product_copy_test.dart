import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seeker_workroom/data/remote.dart';
import 'package:seeker_workroom/data/repository.dart';
import 'package:seeker_workroom/domain/controller.dart';
import 'package:seeker_workroom/l10n/locale_catalog.dart';
import 'package:seeker_workroom/l10n/strings.dart';
import 'package:seeker_workroom/platform/native.dart';
import 'package:seeker_workroom/ui/app.dart';
import 'controller_test.dart' show FakeClock;

void main() {
  for (final language in WorkroomStrings.supportedLanguageCodes) {
    testWidgets('$language settings preserve controls without developer copy', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(500, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = WorkroomController(MemoryRepository(), FakeClock());
      await c.load();
      await c.setting('roomWelcome', 1);
      await c.setting('reduceMotion', true);
      await c.setting('language', language);
      final r = RemoteService(NativePlatform(), c);
      await tester.pumpWidget(WorkroomApp(controller: c, remote: r));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(NavigationDestination).last);
      await tester.pumpAndSettle();
      final text = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join('\n');
      expect(text, isNot(contains('0.2.0')));
      expect(text, isNot(contains('0.3.1')));
      expect(text.toLowerCase(), isNot(contains('development preview')));
      expect(text, isNot(contains('개발 검증')));
      expect(text, isNot(contains('Firebase')));
      expect(find.byType(SwitchListTile), findsNWidgets(3));
      // The export action still exists; only the developer-oriented JSON label changed.
      final export = find.byType(ExportButton);
      expect(export, findsOneWidget);
      final context = tester.element(export);
      expect(
        find.text(tr(context, '기록 내보내기', 'Export records')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      r.dispose();
      c.dispose();
    });
  }

  testWidgets(
    'unexpected errors never expose internal paths or service codes',
    (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (c) {
              context = c;
              return const Scaffold(body: Text('Journal'));
            },
          ),
        ),
      );
      await perform(
        context,
        () async => throw StateError('SqliteException /private/journal.db'),
      );
      await tester.pump();
      expect(
        find.text('Unable to complete this action. Please try again.'),
        findsOneWidget,
      );
      expect(find.textContaining('journal.db'), findsNothing);
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      await perform(
        context,
        () async => throw PlatformException(code: 'unmapped-internal-code'),
      );
      await tester.pump();
      expect(find.textContaining('unmapped-internal-code'), findsNothing);
    },
  );

  test(
    'product copy ships translations for every supported non-English locale',
    () {
      for (final en in [
        'Export records',
        'Transaction details',
        'Open-source licenses',
        'Set up AI · 133 MB',
      ]) {
        for (final lang in translationLanguages) {
          expect(translateEnglish(lang, en), isNot(en));
        }
      }
    },
  );
}
