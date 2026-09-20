import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:seeker_workroom/data/repository.dart';
import 'package:seeker_workroom/domain/controller.dart';
import 'package:seeker_workroom/platform/native.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'no-wallet error is explicit; seed a real timer for process-death checks',
    (tester) async {
      final db = await LocalRepository.open();
      final c = WorkroomController(db, NativePlatform());
      await c.load();
      expect(
        c.state.projects,
        isEmpty,
        reason: 'Use a fresh, isolated emulator installation.',
      );
      await c.addProject('Android 통합 테스트', '프로세스 복구 진단', 0);
      await expectLater(
        NativePlatform.channel.invokeMethod('walletConnect', {
          'identityUri': 'https://workroom.invalid',
          'identityName': 'Workroom integration test',
        }),
        throwsA(
          isA<PlatformException>().having((e) => e.code, 'code', 'no-wallet'),
        ),
      );
      await c.start(c.state.projects.single.id, '프로세스 종료와 잠금 후 타이머 복구', 25);
      await Future<void>.delayed(const Duration(seconds: 2));
      expect(c.state.active, isNotNull);
      await db.database.close();
    },
  );
}
