import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/repository.dart';
import '../platform/native.dart';
import 'models.dart';
import 'trade_journal_controller.dart';

class WorkroomController extends ChangeNotifier {
  WorkroomController(
    this.repository,
    this.platform, {
    DateTime Function()? wallClock,
  }) : wallClock = wallClock ?? DateTime.now;
  final DateTime Function() wallClock;
  late final journals = TradeJournalController(repository);
  final Repository repository;
  final WorkroomPlatform platform;
  WorkroomState state = WorkroomState();
  ClockSample? now;
  bool busy = false;
  Future<void> _writes = Future.value();
  @override
  void dispose() {
    journals.dispose();
    super.dispose();
  }

  Future<void> load() async {
    state = await repository.read();
    await journals.load();
    await refresh();
    notifyListeners();
  }

  Future<void> mutate(void Function(WorkroomState) action) {
    final write = _writes.then((_) async {
      busy = true;
      try {
        final next = state.copy();
        action(next);
        await repository.write(next);
        state = next;
      } finally {
        busy = false;
      }
      notifyListeners();
    });
    _writes = write.catchError((_) {});
    return write;
  }

  Future<void> refresh() async {
    now = await platform.clock();
    final a = state.active;
    if (a != null && !busy) {
      if (a.rebooted(now!) && !a.needsRecovery) {
        await mutate((s) {
          if (s.active?.id != a.id) return;
          final active = s.active!;
          if (active.status == SessionStatus.running) {
            active
              ..needsRecovery = true
              ..status = SessionStatus.paused;
          } else {
            // A paused timer or an outcome draft already has an exact duration.
            // Only running time can be unknown across a device restart.
            active
              ..anchorMs = now!.elapsedMs
              ..boot = now!.boot;
          }
        });
      } else if (!a.needsRecovery &&
          a.status == SessionStatus.running &&
          a.elapsedAt(now!) >= a.plannedSec * 1000) {
        await mutate((s) {
          if (s.active?.id != a.id ||
              s.active?.status != SessionStatus.running) {
            return;
          }
          s.active!
            ..accumulatedMs = a.plannedSec * 1000
            ..status = SessionStatus.awaitingOutcome;
        });
      }
    }
    notifyListeners();
  }

  Future<String> addProject(String title, String definition, int color) async {
    if (title.trim().isEmpty) throw ArgumentError('프로젝트 이름을 입력해 주세요.');
    final id = const Uuid().v4();
    await mutate((s) {
      s.projects.add(
        Project(
          id: id,
          title: title.trim(),
          definition: definition.trim(),
          color: color,
          createdAt: wallClock().millisecondsSinceEpoch,
        ),
      );
    });
    return id;
  }

  Future<void> start(
    String projectId,
    String intent,
    int minutes, {
    String? resumedFrom,
    String? roomId,
    int elapsedMs = 0,
  }) async {
    if (intent.trim().isEmpty || minutes < 1 || minutes > 180) {
      throw ArgumentError('의도와 1~180분의 시간을 확인해 주세요.');
    }
    final c = await platform.clock();
    await mutate((s) {
      if (s.active != null) throw StateError('진행 중인 집중을 먼저 마무리해 주세요.');
      if (s.project(projectId)?.status != ProjectStatus.active) {
        throw StateError('진행 중인 프로젝트를 선택해 주세요.');
      }
      s.sessions.add(
        WorkSession(
          id: const Uuid().v4(),
          projectId: projectId,
          intent: intent.trim(),
          plannedSec: minutes * 60,
          startedAt: c.utcMs - elapsedMs,
          anchorMs: c.elapsedMs,
          boot: c.boot,
          accumulatedMs: elapsedMs.clamp(0, minutes * 60000),
          resumedFrom: resumedFrom,
          roomId: roomId,
        ),
      );
    });
    now = c;
    await _alarm();
  }

  Future<void> _alarm() async {
    try {
      final a = state.active;
      if (a != null &&
          a.status == SessionStatus.running &&
          state.settings['notifications'] == true) {
        await platform.alarm(
          a.plannedSec * 1000 - a.elapsedAt(await platform.clock()),
        );
      } else {
        await platform.cancelAlarm();
      }
    } catch (_) {
      /* Reminder failure never rolls back a committed session. */
    }
  }

  Future<void> pause() async {
    final c = await platform.clock();
    await mutate((s) {
      final a = s.active!;
      if (a.needsRecovery) throw StateError('복구 시간을 먼저 확인해 주세요.');
      if (a.status == SessionStatus.running) {
        a.accumulatedMs = a.elapsedAt(c);
        a.status = SessionStatus.paused;
      } else if (a.status == SessionStatus.paused) {
        a.anchorMs = c.elapsedMs;
        a.boot = c.boot;
        a.status = SessionStatus.running;
      }
    });
    await _alarm();
  }

  Future<void> finish() async {
    final c = await platform.clock();
    await mutate((s) {
      final a = s.active!;
      if (a.needsRecovery) throw StateError('복구 시간을 먼저 확인해 주세요.');
      a.accumulatedMs = a.elapsedAt(c);
      a.status = SessionStatus.awaitingOutcome;
    });
    await _alarm();
  }

  Future<void> recover(int confirmedSec) async {
    final c = await platform.clock();
    await mutate((s) {
      final a = s.active!;
      if (!a.needsRecovery || confirmedSec < 0 || confirmedSec > a.plannedSec) {
        throw ArgumentError('복구 시간을 확인해 주세요.');
      }
      a
        ..accumulatedMs = confirmedSec * 1000
        ..anchorMs = c.elapsedMs
        ..boot = c.boot
        ..needsRecovery = false
        ..timeAdjusted = true
        ..status = SessionStatus.paused;
    });
  }

  Future<void> save(
    String id,
    String outcome,
    String next,
    ResultState result,
    int seconds,
  ) async {
    if (outcome.trim().isEmpty) {
      throw ArgumentError('해낸 일이나 막힌 지점을 한 줄 남겨 주세요.');
    }
    await mutate((s) {
      final a = s.sessions.firstWhere((p) => p.id == id);
      if (a.status == SessionStatus.saved) return;
      if (a.status != SessionStatus.awaitingOutcome || a.needsRecovery) {
        throw StateError('먼저 집중을 마무리해 주세요.');
      }
      if (seconds < 0 || seconds > a.accumulatedMs ~/ 1000) {
        throw ArgumentError('확인 시간은 측정된 시간을 넘을 수 없습니다.');
      }
      final local = wallClock();
      if (seconds != a.accumulatedMs ~/ 1000) a.timeAdjusted = true;
      a
        ..outcome = outcome.trim()
        ..nextAction = next.trim()
        ..result = result
        ..confirmedSec = seconds
        ..savedAt = local.toUtc().millisecondsSinceEpoch
        ..localDay =
            '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}'
        ..status = SessionStatus.saved;
    });
    await _alarm();
  }

  Future<void> saveDraft(
    String outcome,
    String next,
    ResultState result,
  ) async {
    await mutate((s) {
      final a = s.active!;
      a
        ..outcome = outcome
        ..nextAction = next
        ..result = result;
    });
  }

  Future<void> cancel() async {
    await mutate((s) {
      s.active?.status = SessionStatus.cancelled;
    });
    await _alarm();
  }

  Future<void> editPage(
    String id,
    String outcome,
    String next,
    ResultState result,
  ) async {
    if (outcome.trim().isEmpty) throw ArgumentError('결과는 비울 수 없습니다.');
    await mutate((s) {
      final a = s.sessions.firstWhere((p) => p.id == id);
      a
        ..outcome = outcome.trim()
        ..nextAction = next.trim()
        ..result = result
        ..edited = true;
    });
  }

  Future<void> removePage(String id) async {
    await mutate((s) {
      s.sessions.removeWhere(
        (p) => p.id == id && p.status == SessionStatus.saved,
      );
    });
  }

  Future<void> updateProject(
    String id, {
    String? title,
    ProjectStatus? status,
  }) async {
    await mutate((s) {
      final p = s.project(id)!;
      if (title != null) {
        if (title.trim().isEmpty) throw ArgumentError('이름은 비울 수 없습니다.');
        p.title = title.trim();
      }
      if (status != null) {
        if (s.active?.projectId == id) {
          throw StateError('진행 중인 집중을 먼저 마무리해 주세요.');
        }
        p.status = status;
        if (status == ProjectStatus.completed) {
          p.completedAt = wallClock().millisecondsSinceEpoch;
        }
      }
    });
  }

  Future<void> setting(String key, dynamic value) async {
    await mutate((s) {
      s.settings[key] = value;
    });
  }

  Future<void> configureNotifications(bool enabled) async {
    await setting('notifications', enabled);
    await _alarm();
  }

  Future<void> deleteAll() async {
    await journals.clear();
    await mutate((s) {
      s.projects.clear();
      s.sessions.clear();
      s.settings.clear();
    });
    await _alarm();
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert({
    'exportedAt': DateTime.now().toUtc().toIso8601String(),
    'app': 'FOR THE RECORD',
    'data': state.toJson(export: true),
    'tradeJournals': journals.entries.map((e) => e.toJson()).toList(),
  });
}
