import 'dart:io';
import 'package:seeker_workroom/domain/trade_journal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:seeker_workroom/data/repository.dart';
import 'package:seeker_workroom/domain/controller.dart';
import 'package:seeker_workroom/domain/models.dart';
import 'package:seeker_workroom/platform/native.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android monotonic channel and SQLite reopen preserve a real local session',
    (tester) async {
      final native = NativePlatform();
      final directory = await Directory.systemTemp.createTemp(
        'workroom-integration-',
      );
      final databasePath = '${directory.path}/isolated.sqlite';
      final db = await LocalRepository.open(databasePath: databasePath);
      // Isolated temporary database: never modifies the installed personal workroom.
      final original = await db.read();
      expect(
        original.projects,
        isEmpty,
        reason:
            'Use a fresh test installation; this test does not erase user data.',
      );
      final c = WorkroomController(db, native);
      await c.load();
      final project = await c.addProject('Android 통합 테스트', '진단용 기록', 0);
      final first = await native.clock();
      await c.start(project, '기기 저장·시계 검증', 1);
      await Future<void>.delayed(const Duration(seconds: 3));
      final second = await native.clock();
      expect(second.boot, first.boot);
      expect(second.elapsedMs - first.elapsedMs, greaterThanOrEqualTo(2900));
      await db.database.close();
      final reopened = await LocalRepository.open(databasePath: databasePath);
      final recovered = WorkroomController(reopened, native);
      await recovered.load();
      expect(recovered.state.active!.intent, '기기 저장·시계 검증');
      expect(
        recovered.state.active!.elapsedAt(recovered.now!),
        greaterThanOrEqualTo(2900),
      );
      await recovered.finish();
      final session = recovered.state.active!;
      await recovered.save(
        session.id,
        'SQLite 재연결 후 결과 저장 확인',
        '재시작 확인',
        ResultState.done,
        session.accumulatedMs ~/ 1000,
      );
      await recovered.save(
        session.id,
        'SQLite 재연결 후 결과 저장 확인',
        '재시작 확인',
        ResultState.done,
        session.accumulatedMs ~/ 1000,
      );
      expect((await reopened.read()).saved.length, 1);
      const trade = TradeJournalEntry(
        id: 'integration-only',
        wallet: 'synthetic-wallet',
        activity: WalletActivity(
          id: 'synthetic-activity',
          signature: 'synthetic-signature',
          status: 'success',
          type: 'swap',
          input: ActivityAsset(
            mint: 'test-input',
            symbol: 'TEST A',
            amount: '1',
          ),
          output: ActivityAsset(
            mint: 'test-output',
            symbol: 'TEST B',
            amount: '2',
          ),
        ),
        createdAt: 1,
        updatedAt: 1,
        reason: 'Isolated integration fixture',
      );
      await reopened.saveJournal(trade);
      await reopened.database.close();
      final third = await LocalRepository.open(databasePath: databasePath);
      expect((await third.readJournals()).single.reason, trade.reason);
      expect((await third.read()).saved.length, 1);
      await third.database.close();
      await native.cancelAlarm();
      await directory.delete(recursive: true);
    },
  );
}
