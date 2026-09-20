import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seeker_workroom/data/remote.dart';
import 'package:seeker_workroom/data/repository.dart';
import 'package:seeker_workroom/domain/controller.dart';
import 'package:seeker_workroom/platform/native.dart';
import 'package:seeker_workroom/ui/app.dart';
import 'controller_test.dart' show FakeClock;

void main() {
  Future<void> fonts() async {
    for (final family in ['NotoSansKR', 'Lora']) {
      final loader = FontLoader(family)
        ..addFont(rootBundle.load('assets/fonts/$family.ttf'));
      await loader.load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  }

  testWidgets('wallet-free create, focus, outcome, revisit; visual snapshots', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await fonts();
    final clock = FakeClock(),
        c = WorkroomController(
          MemoryRepository(),
          clock,
          wallClock: () => DateTime(2026, 9, 15),
        );
    await c.load();
    await c.setting('language', 'ko');
    final remote = RemoteService(NativePlatform(), c);
    await tester.pumpWidget(WorkroomApp(controller: c, remote: remote));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/01-empty-workroom.png'),
    );
    await tester.ensureVisible(find.text('내 프로젝트 만들기'));
    await tester.tap(find.text('내 프로젝트 만들기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '나의 작은 앱');
    await tester.enterText(find.byType(TextField).at(1), '친구에게 첫 버전 보여주기');
    await tester.tap(find.text('책 만들기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '로그인 오류의 원인 찾기');
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/02-prepare.png'),
    );
    await tester.ensureVisible(find.text('혼자 집중 시작'));
    await tester.tap(find.text('혼자 집중 시작'));
    await tester.pumpAndSettle();
    expect(c.state.active, isNotNull);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/03-focus.png'),
    );
    await tester.ensureVisible(find.text('여기서 마무리'));
    await tester.tap(find.text('여기서 마무리'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).at(0),
      '만료된 토큰이 원인이라는 것을 찾았다.',
    );
    await tester.enterText(find.byType(TextField).at(1), '토큰 갱신 흐름을 수정하기');
    await tester.ensureVisible(find.text('내 프로젝트 책에 남기기'));
    await tester.tap(find.text('내 프로젝트 책에 남기기'));
    await tester.pumpAndSettle();
    expect(c.state.saved.single.outcome, '만료된 토큰이 원인이라는 것을 찾았다.');
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/04-returning-workroom.png'),
    );
    await tester.tap(find.text('기록'));
    await tester.pumpAndSettle();
    expect(find.text('만료된 토큰이 원인이라는 것을 찾았다.'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/05-library.png'),
    );
    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    expect(find.text('공동 작업실 전시 팩'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('지갑과 Seeker'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('지갑과 Seeker'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/06-free-wallet.png'),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    remote.dispose();
    c.dispose();
    expect(clock.boot, '1');
  });
  testWidgets('large text preserves a scrollable wallet-free entry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final c = WorkroomController(MemoryRepository(), FakeClock());
    await c.load();
    await c.setting('language', 'ko');
    final remote = RemoteService(NativePlatform(), c);
    await tester.pumpWidget(WorkroomApp(controller: c, remote: remote));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('내 프로젝트 만들기'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('내 프로젝트 만들기'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    remote.dispose();
    c.dispose();
  });
}
