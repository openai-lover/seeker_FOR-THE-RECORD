import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seeker_workroom/data/remote.dart';
import 'package:seeker_workroom/data/repository.dart';
import 'package:seeker_workroom/domain/controller.dart';
import 'package:seeker_workroom/domain/models.dart';
import 'package:seeker_workroom/l10n/locale_catalog.dart';
import 'package:seeker_workroom/platform/native.dart';
import 'package:seeker_workroom/ui/app.dart';
import 'package:seeker_workroom/ui/design.dart';

class _Clock implements WorkroomPlatform {
  int elapsed = 100000;

  @override
  Future<ClockSample> clock() async =>
      ClockSample(elapsed, 'test-boot', 1700000000000 + elapsed);

  @override
  Future<void> alarm(int remainingMs) async {}

  @override
  Future<void> cancelAlarm() async {}
}

class _Repository extends MemoryRepository {
  bool failWrites = false;

  @override
  Future<void> write(WorkroomState state) async {
    if (failWrites) throw StateError('Storage is temporarily unavailable.');
    await super.write(state);
  }
}

class _Harness {
  _Harness({this.directWalletEnabled = true});
  final bool directWalletEnabled;
  final repository = _Repository();
  final clock = _Clock();
  late final controller = WorkroomController(repository, clock);
  late final remote = RemoteService(
    NativePlatform(),
    controller,
    directWalletEnabled: directWalletEnabled,
  );

  Future<void> initialize() => controller.load();

  Future<void> prepareOutcome({bool saved = false}) async {
    final project = await controller.addProject('A thoughtful project', '', 0);
    await controller.start(project, 'Test one assumption', 1);
    clock.elapsed += 30000;
    await controller.finish();
    if (saved) {
      await controller.save(
        controller.state.active!.id,
        'The original outcome',
        'The original next step',
        ResultState.done,
        30,
      );
    }
  }

  Future<void> show(
    WidgetTester tester, {
    Size size = const Size(500, 1100),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      WorkroomApp(controller: controller, remote: remote),
    );
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      remote.dispose();
      controller.dispose();
    });
  }
}

Future<void> _tap(WidgetTester tester, String label) async {
  final target = find.text(label);
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _openOutcome(WidgetTester tester) async {
  // The home card opens the focus screen, which then opens the outcome editor.
  await _tap(tester, 'Leave an outcome');
  await _tap(tester, 'Leave an outcome');
  expect(find.text('Your page today'), findsOneWidget);
}

Future<void> _checkScrollablePage(WidgetTester tester, String page) async {
  expect(tester.takeException(), isNull, reason: '$page initial layout');
  final scrollable = tester.state<ScrollableState>(
    find.byType(Scrollable).first,
  );
  scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: '$page at end of scroll');
  scrollable.position.jumpTo(0);
  await tester.pumpAndSettle();
}

Future<void> _navigate(WidgetTester tester, int destination) async {
  await tester.tap(find.byType(NavigationDestination).at(destination));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('default English is independent of a Korean device locale', (
    tester,
  ) async {
    tester.platformDispatcher.localeTestValue = const Locale('ko', 'KR');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    final app = _Harness();
    await app.initialize();
    await app.show(tester);

    expect(app.controller.state.settings['language'], isNull);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
      const Locale('en'),
    );
    expect(find.text('Create my project'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('내 프로젝트 만들기'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('back before the draft debounce durably preserves typed text', (
    tester,
  ) async {
    final app = _Harness();
    await app.initialize();
    await app.prepareOutcome();
    await app.show(tester);
    await _openOutcome(tester);

    await tester.enterText(
      find.byType(TextField).at(0),
      'A discovery worth keeping',
    );
    await tester.enterText(
      find.byType(TextField).at(1),
      'Check the next assumption',
    );
    // No 500 ms pump: this specifically exercises the immediate back path.
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 1));
    final persisted = await app.repository.read();
    expect(persisted.active!.outcome, 'A discovery worth keeping');
    expect(persisted.active!.nextAction, 'Check the next assumption');
    expect(persisted.active!.status, SessionStatus.awaitingOutcome);
    expect(persisted.saved, isEmpty);

    await tester.pumpAndSettle();
    await _tap(tester, 'Leave an outcome');
    expect(
      tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text,
      'A discovery worth keeping',
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text,
      'Check the next assumption',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed draft persistence keeps the editor and typed text open', (
    tester,
  ) async {
    final app = _Harness();
    await app.initialize();
    await app.prepareOutcome();
    await app.show(tester);
    await _openOutcome(tester);

    await tester.enterText(
      find.byType(TextField).first,
      'Do not lose this draft',
    );
    app.repository.failWrites = true;
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Your page today'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      'Do not lose this draft',
    );
    expect(find.text('Storage is temporarily unavailable.'), findsOneWidget);
    expect((await app.repository.read()).active!.outcome, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keep draft returns home and restores the draft when reopened', (
    tester,
  ) async {
    final app = _Harness();
    await app.initialize();
    await app.prepareOutcome();
    await app.show(tester);
    await _openOutcome(tester);
    await tester.enterText(
      find.byType(TextField).at(0),
      'An unfinished discovery',
    );
    await tester.enterText(
      find.byType(TextField).at(1),
      'Return to this tomorrow',
    );
    await _tap(tester, 'Keep draft and finish later');

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Your page today'), findsNothing);
    final persisted = await app.repository.read();
    expect(persisted.active!.outcome, 'An unfinished discovery');
    expect(persisted.active!.nextAction, 'Return to this tomorrow');
    expect(persisted.saved, isEmpty);
    await _openOutcome(tester);
    expect(
      tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text,
      'An unfinished discovery',
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text,
      'Return to this tomorrow',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving an edited saved outcome requires a discard decision', (
    tester,
  ) async {
    final app = _Harness();
    await app.initialize();
    await app.prepareOutcome(saved: true);
    await app.show(tester);
    await _tap(tester, 'Journal');
    await _tap(tester, 'The original outcome');
    await tester.ensureVisible(find.byTooltip('Edit page'));
    await tester.tap(find.byTooltip('Edit page'));
    await tester.pumpAndSettle();
    await _tap(tester, 'Edit outcome and next action');
    await tester.enterText(find.byType(TextField).first, 'An unsaved revision');

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Leave this entry?'), findsOneWidget);
    expect(find.text('Your unsaved changes will be lost.'), findsOneWidget);
    await _tap(tester, 'Go back');
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      'An unsaved revision',
    );
    expect(app.controller.state.saved.single.outcome, 'The original outcome');

    await tester.pageBack();
    await tester.pumpAndSettle();
    await _tap(tester, 'Leave');
    expect(find.byType(TextField), findsNothing);
    expect(
      (await app.repository.read()).saved.single.outcome,
      'The original outcome',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'invalid custom duration has visible validation and can be corrected',
    (tester) async {
      final app = _Harness();
      await app.initialize();
      await app.controller.addProject('Choose a duration', '', 0);
      await app.show(tester);
      await _tap(tester, 'Continue from your bookmark');
      await _tap(tester, 'Choose duration');
      final input = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(input, '181');
      await _tap(tester, 'Select');
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.text('Enter a number of minutes from 1 to 180.'),
        findsOneWidget,
      );
      expect(app.controller.state.active, isNull);

      await tester.enterText(input, '5');
      await _tap(tester, 'Select');
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('5 min'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('unconfigured preview explains and disables wallet connection', (
    tester,
  ) async {
    final app = _Harness(directWalletEnabled: false);
    await app.initialize();
    await app.show(tester);
    expect(app.remote.onlineAvailable, isFalse);
    await _tap(tester, 'Journal');
    await _tap(tester, 'Trade journal');

    expect(
      find.text('Wallet connection is not available in this preview.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Your work journal is ready to use offline.'),
      findsOneWidget,
    );
    final connection = find.ancestor(
      of: find.text('Connect Seeker wallet'),
      matching: find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
    );
    expect(tester.widget<ButtonStyleButton>(connection).onPressed, isNull);
    expect(app.remote.signedIn, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a user project title matching an interface label stays unchanged',
    (tester) async {
      final app = _Harness();
      await app.initialize();
      await app.controller.setting('language', 'fr');
      await app.controller.addProject('Settings', '', 0);
      await app.show(tester);
      await _tap(tester, translateEnglish('fr', 'Continue from your bookmark'));

      final projectTag = find.byType(QuietTag);
      expect(projectTag, findsOneWidget);
      expect(
        find.descendant(of: projectTag, matching: find.text('Settings')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: projectTag,
          matching: find.text(translateEnglish('fr', 'Settings')),
        ),
        findsNothing,
      );
      expect(app.controller.state.projects.single.title, 'Settings');
      expect(tester.takeException(), isNull);
    },
  );

  for (final locale in ['en', 'ko', 'ja', 'zh', 'hi', 'es', 'pt', 'fr']) {
    testWidgets('$locale app screens fit 360px with text at 200 percent', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final app = _Harness();
      await app.initialize();
      await app.controller.setting('language', locale);
      await app.controller.setting('reduceMotion', true);
      await app.show(tester, size: const Size(360, 800));
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
        Locale(locale),
      );
      await _checkScrollablePage(tester, '$locale empty home');

      await app.prepareOutcome(saved: true);
      await tester.pumpAndSettle();
      await _checkScrollablePage(tester, '$locale home with a saved project');
      await _navigate(tester, 2);
      await _checkScrollablePage(tester, '$locale settings');
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);

      await _navigate(tester, 1);
      await _checkScrollablePage(tester, '$locale work journal');
      expect(find.text('The original outcome'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.edit_note_rounded));
      await tester.pumpAndSettle();
      await _checkScrollablePage(tester, '$locale trade journal preview');

      await _navigate(tester, 0);
      expect(app.controller.state.saved.single.outcome, 'The original outcome');
      expect(tester.takeException(), isNull);
    });
  }
}
