import 'package:flutter_test/flutter_test.dart';
import 'package:seeker_workroom/domain/models.dart';
import 'package:seeker_workroom/domain/controller.dart';
import 'package:seeker_workroom/data/repository.dart';
import 'package:seeker_workroom/platform/native.dart';

class FakeClock implements WorkroomPlatform {
  int elapsed = 100000, wall = 1700000000000;
  String boot = '1';
  bool alarmFails = false;
  @override
  Future<ClockSample> clock() async => ClockSample(elapsed, boot, wall);
  @override
  Future<void> alarm(int ms) async {
    if (alarmFails) throw Exception('denied');
  }

  @override
  Future<void> cancelAlarm() async {}
}

class FailingRepository extends MemoryRepository {
  bool fail = false;
  @override
  Future<void> write(WorkroomState state) async {
    if (fail) throw Exception('disk full');
    await super.write(state);
  }
}

void main() {
  late FakeClock clock;
  late FailingRepository db;
  late WorkroomController c;
  late String p;
  setUp(() async {
    clock = FakeClock();
    db = FailingRepository();
    c = WorkroomController(db, clock);
    await c.load();
    p = await c.addProject('테스트 프로젝트', '친구에게 보여주기', 0);
  });
  test(
    'offline core loop survives reopening, saves once, reuses bookmark',
    () async {
      await c.start(p, '원인 찾기', 25);
      final id = c.state.active!.id;
      clock.elapsed += 90000;
      c = WorkroomController(db, clock);
      await c.load();
      expect(c.state.active!.elapsedAt(c.now!), 90000);
      await c.finish();
      await c.save(id, '원인을 찾음', '오류 수정', ResultState.done, 90);
      await c.save(id, '원인을 찾음', '오류 수정', ResultState.done, 90);
      expect(c.state.saved.length, 1);
      expect(achievements(c.state).first.earned, true);
      await c.start(p, '오류 수정', 10, resumedFrom: id);
      clock.elapsed += 60000;
      await c.finish();
      await c.save(c.state.active!.id, '수정 완료', '', ResultState.done, 60);
      expect(achievements(c.state)[1].earned, true);
    },
  );
  test(
    'wall clock changes never change focus time; pause excludes downtime',
    () async {
      await c.start(p, '의도', 25);
      clock.elapsed += 30000;
      clock.wall -= 86400000;
      await c.refresh();
      expect(c.state.active!.elapsedAt(c.now!), 30000);
      await c.pause();
      clock.elapsed += 600000;
      await c.refresh();
      expect(c.state.active!.elapsedAt(c.now!), 30000);
      await c.pause();
      clock.elapsed += 10000;
      await c.refresh();
      expect(c.state.active!.elapsedAt(c.now!), 40000);
    },
  );
  test(
    'reboot requires explicit recovery and never auto-awards a page',
    () async {
      await c.start(p, '의도', 25);
      clock.elapsed = 1;
      clock.boot = '2';
      clock.wall += 86400000;
      await c.refresh();
      expect(c.state.active!.needsRecovery, true);
      expect(c.state.saved, isEmpty);
      expect(achievements(c.state).first.earned, false);
      await expectLater(c.finish(), throwsStateError);
      await expectLater(c.recover(1501), throwsArgumentError);
      await c.recover(120);
      expect(c.state.active!.timeAdjusted, true);
      expect(c.state.active!.status, SessionStatus.paused);
    },
  );
  test(
    'deadline only awaits outcome; elapsed is capped and active is unique',
    () async {
      await c.start(p, '의도', 1);
      await expectLater(c.start(p, '다른 작업', 1), throwsStateError);
      clock.elapsed += 86400000;
      await c.refresh();
      expect(c.state.active!.status, SessionStatus.awaitingOutcome);
      expect(c.state.active!.accumulatedMs, 60000);
      expect(c.state.saved, isEmpty);
      await expectLater(
        c.save(c.state.active!.id, '', '', ResultState.done, 60),
        throwsArgumentError,
      );
      await expectLater(
        c.save(c.state.active!.id, '결과', '', ResultState.done, 61),
        throwsArgumentError,
      );
    },
  );
  test(
    'a paused timer survives reboot without inventing recovery work',
    () async {
      await c.start(p, 'Pause before restarting', 25);
      clock.elapsed += 42000;
      await c.pause();
      clock.boot = '2';
      clock.elapsed = 100;
      await c.refresh();
      expect(c.state.active!.needsRecovery, isFalse);
      expect(c.state.active!.status, SessionStatus.paused);
      expect(c.state.active!.accumulatedMs, 42000);
      await c.pause();
      clock.elapsed += 8000;
      await c.refresh();
      expect(c.state.active!.elapsedAt(c.now!), 50000);
    },
  );
  test('reboot preserves outcome drafts and their measured duration', () async {
    await c.start(p, 'Finish before restarting', 1);
    clock.elapsed += 30000;
    await c.finish();
    await c.saveDraft('Result draft', 'Next draft', ResultState.partial);
    clock.boot = '2';
    clock.elapsed = 100;
    await c.refresh();
    expect(c.state.active!.needsRecovery, isFalse);
    expect(c.state.active!.status, SessionStatus.awaitingOutcome);
    expect(c.state.active!.outcome, 'Result draft');
    await c.save(
      c.state.active!.id,
      'Result draft',
      'Next draft',
      ResultState.partial,
      30,
    );
    expect(c.state.saved.single.confirmedSec, 30);
  });
  test(
    'failed DB commit preserves draft and cannot create phantom saved state',
    () async {
      await c.start(p, '의도', 1);
      clock.elapsed += 30000;
      await c.finish();
      db.fail = true;
      await expectLater(
        c.save(c.state.active!.id, '결과', '다음', ResultState.done, 30),
        throwsException,
      );
      expect(c.state.saved, isEmpty);
      expect(c.state.active!.status, SessionStatus.awaitingOutcome);
      db.fail = false;
      await c.save(c.state.active!.id, '결과', '다음', ResultState.done, 30);
      expect(c.state.saved.length, 1);
    },
  );
  test(
    'notification denial is independent of durable session accuracy',
    () async {
      clock.alarmFails = true;
      await c.setting('notifications', true);
      await c.start(p, '의도', 25);
      expect((await db.read()).active, isNotNull);
    },
  );
  test(
    'rename and archive preserve original intent; deletion recomputes achievements',
    () async {
      await c.start(p, '원래 의도', 1);
      clock.elapsed += 30000;
      await c.finish();
      await c.save(c.state.active!.id, '기존 결과', '다음', ResultState.blocked, 30);
      await c.updateProject(p, title: '새 이름', status: ProjectStatus.archived);
      expect(c.state.saved.single.intent, '원래 의도');
      expect(c.state.saved.single.outcome, '기존 결과');
      await c.removePage(c.state.saved.single.id);
      expect(achievements(c.state).first.earned, false);
    },
  );
  test('unsupported schema fails without destructive reset', () {
    expect(
      () => WorkroomState.fromJson({'schemaVersion': 999}),
      throwsFormatException,
    );
  });
}
