import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
  test('wallet cancellation describes a cancelled request, never an order', () {
    final message = errorText('wallet-declined');
    expect(message, '지갑 요청을 취소했어요. 필요할 때 다시 시도할 수 있어요.');
    expect(message, isNot(contains('주문')));
    expect(message, isNot(contains('전송')));
    for (final language in translationLanguages) {
      expect(
        translateEnglish(
          language,
          'Wallet request cancelled. You can try again when you are ready.',
        ),
        isNot(
          'Wallet request cancelled. You can try again when you are ready.',
        ),
      );
      expect(
        translateEnglish(language, 'Choose 1–180 minutes for this session.'),
        isNot('Choose 1–180 minutes for this session.'),
      );
    }
  });

  for (final language in ['ko', 'en', 'fr']) {
    for (final scale in [1.0, 1.6]) {
      testWidgets(
        '$language $scale blank title feedback and readable time hints',
        (tester) async {
          tester.view.physicalSize = const Size(360, 900);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final c = WorkroomController(MemoryRepository(), FakeClock());
          await c.load();
          await c.setting('roomWelcome', 1);
          await c.setting('reduceMotion', true);
          await c.setting('language', language);
          final r = RemoteService(NativePlatform(), c);
          await tester.pumpWidget(WorkroomApp(controller: c, remote: r));
          await tester.pumpAndSettle();
          final context = tester.element(find.byType(Scaffold).first);
          String text(String ko, String en) => tr(context, ko, en);
          await tester.ensureVisible(find.text(text('집중', 'Focus')));
          await tester.tap(find.text(text('집중', 'Focus')));
          await tester.pumpAndSettle();
          final create = find.text(text('책 만들기', 'Create book'));
          await tester.ensureVisible(create);
          await tester.tap(create);
          await tester.pumpAndSettle();
          expect(
            find.text(text('프로젝트 이름을 입력해 주세요.', 'Enter a project name.')),
            findsOneWidget,
          );
          expect(c.state.projects, isEmpty);
          await tester.enterText(find.byType(TextField).first, '   ');
          await tester.ensureVisible(create);
          await tester.tap(create);
          await tester.pumpAndSettle();
          expect(c.state.projects, isEmpty);
          expect(
            find.text(text('프로젝트 이름을 입력해 주세요.', 'Enter a project name.')),
            findsOneWidget,
          );
          await tester.enterText(
            find.byType(TextField).first,
            'DEMO final check',
          );
          await tester.pump();
          expect(
            find.text(text('프로젝트 이름을 입력해 주세요.', 'Enter a project name.')),
            findsNothing,
          );
          await tester.ensureVisible(create);
          await tester.tap(create);
          await tester.pumpAndSettle();
          expect(c.state.projects, hasLength(1));
          final custom = find.byType(ChoiceChip).last;
          await tester.ensureVisible(custom);
          await tester.tap(custom);
          await tester.pumpAndSettle();
          final helper = find.text(
            text(
              '집중 시간을 1~180분으로 정해 주세요.',
              'Choose 1–180 minutes for this session.',
            ),
          );
          expect(helper, findsOneWidget);
          expect(
            tester.renderObject<RenderParagraph>(helper).didExceedMaxLines,
            isFalse,
          );
          await tester.enterText(
            find.descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(TextField),
            ),
            '0',
          );
          await tester.tap(
            find.descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(FilledButton),
            ),
          );
          await tester.pumpAndSettle();
          final error = find.text(
            text(
              '1부터 180까지의 분을 입력해 주세요.',
              'Enter a number of minutes from 1 to 180.',
            ),
          );
          expect(error, findsOneWidget);
          expect(
            tester.renderObject<RenderParagraph>(error).didExceedMaxLines,
            isFalse,
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          r.dispose();
          c.dispose();
        },
      );
    }
  }
}
