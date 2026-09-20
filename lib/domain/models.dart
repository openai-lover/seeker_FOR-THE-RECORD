import 'dart:convert';

enum SessionStatus { running, paused, awaitingOutcome, saved, cancelled }

enum ProjectStatus { active, completed, archived }

enum ResultState { done, partial, blocked }

class Project {
  Project({
    required this.id,
    required this.title,
    required this.createdAt,
    this.color = 0,
    this.definition = '',
    this.status = ProjectStatus.active,
    this.completedAt,
  });
  String id, title, definition;
  int color, createdAt;
  int? completedAt;
  ProjectStatus status;
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'color': color,
    'definition': definition,
    'status': status.name,
    'createdAt': createdAt,
    'completedAt': completedAt,
  };
  factory Project.fromJson(Map<String, dynamic> j) => Project(
    id: j['id'],
    title: j['title'],
    createdAt: j['createdAt'],
    color: j['color'],
    definition: j['definition'],
    status: ProjectStatus.values.byName(j['status']),
    completedAt: j['completedAt'],
  );
}

class ClockSample {
  const ClockSample(this.elapsedMs, this.boot, this.utcMs);
  final int elapsedMs, utcMs;
  final String boot;
}

class WorkSession {
  WorkSession({
    required this.id,
    required this.projectId,
    required this.intent,
    required this.plannedSec,
    required this.startedAt,
    required this.anchorMs,
    required this.boot,
    this.accumulatedMs = 0,
    this.status = SessionStatus.running,
    this.outcome = '',
    this.nextAction = '',
    this.result = ResultState.done,
    this.confirmedSec = 0,
    this.savedAt,
    this.edited = false,
    this.timeAdjusted = false,
    this.resumedFrom,
    this.roomId,
    this.needsRecovery = false,
    this.localDay = '',
  });
  String id, projectId, intent, boot, outcome, nextAction, localDay;
  String? resumedFrom, roomId;
  int plannedSec, startedAt, anchorMs, accumulatedMs, confirmedSec;
  int? savedAt;
  bool edited, timeAdjusted, needsRecovery;
  SessionStatus status;
  ResultState result;
  bool get isActive =>
      status != SessionStatus.saved && status != SessionStatus.cancelled;
  bool rebooted(ClockSample c) => boot != c.boot || c.elapsedMs < anchorMs;
  int elapsedAt(ClockSample c) {
    final delta =
        status == SessionStatus.running && !rebooted(c) && !needsRecovery
        ? (c.elapsedMs - anchorMs).clamp(0, plannedSec * 1000)
        : 0;
    return (accumulatedMs + delta).clamp(0, plannedSec * 1000);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'projectId': projectId,
    'intent': intent,
    'plannedSec': plannedSec,
    'startedAt': startedAt,
    'anchorMs': anchorMs,
    'boot': boot,
    'accumulatedMs': accumulatedMs,
    'status': status.name,
    'outcome': outcome,
    'nextAction': nextAction,
    'result': result.name,
    'confirmedSec': confirmedSec,
    'savedAt': savedAt,
    'edited': edited,
    'timeAdjusted': timeAdjusted,
    'resumedFrom': resumedFrom,
    'roomId': roomId,
    'needsRecovery': needsRecovery,
    'localDay': localDay,
    'version': 1,
  };
  factory WorkSession.fromJson(Map<String, dynamic> j) => WorkSession(
    id: j['id'],
    projectId: j['projectId'],
    intent: j['intent'],
    plannedSec: j['plannedSec'],
    startedAt: j['startedAt'],
    anchorMs: j['anchorMs'],
    boot: j['boot'],
    accumulatedMs: j['accumulatedMs'],
    status: SessionStatus.values.byName(j['status']),
    outcome: j['outcome'],
    nextAction: j['nextAction'],
    result: ResultState.values.byName(j['result']),
    confirmedSec: j['confirmedSec'],
    savedAt: j['savedAt'],
    edited: j['edited'],
    timeAdjusted: j['timeAdjusted'],
    resumedFrom: j['resumedFrom'],
    roomId: j['roomId'],
    needsRecovery: j['needsRecovery'] ?? false,
    localDay: j['localDay'] ?? '',
  );
}

class WorkroomState {
  WorkroomState({
    List<Project>? projects,
    List<WorkSession>? sessions,
    Map<String, dynamic>? settings,
    this.pendingOrder,
  }) : projects = projects ?? [],
       sessions = sessions ?? [],
       settings = settings ?? {};
  final List<Project> projects;
  final List<WorkSession> sessions;
  final Map<String, dynamic> settings;
  Map<String, dynamic>? pendingOrder;
  WorkSession? get active => sessions.where((s) => s.isActive).firstOrNull;
  List<WorkSession> get saved =>
      sessions.where((s) => s.status == SessionStatus.saved).toList()
        ..sort((a, b) => (b.savedAt ?? 0).compareTo(a.savedAt ?? 0));
  Project? project(String id) => projects.where((p) => p.id == id).firstOrNull;
  List<WorkSession> pages(String id) =>
      saved.where((s) => s.projectId == id).toList();
  Map<String, dynamic> toJson({bool export = false}) => {
    'schemaVersion': 1,
    'projects': projects.map((p) => p.toJson()).toList(),
    'sessions': sessions.map((s) => s.toJson()).toList(),
    'settings': settings,
    if (!export) 'pendingOrder': pendingOrder,
  };
  factory WorkroomState.fromJson(Map<String, dynamic> j) {
    if (j['schemaVersion'] != 1) {
      throw const FormatException('지원되지 않는 기록 버전입니다. 원본은 그대로 보존됩니다.');
    }
    return WorkroomState(
      projects: (j['projects'] as List)
          .map((p) => Project.fromJson(Map<String, dynamic>.from(p)))
          .toList(),
      sessions: (j['sessions'] as List)
          .map((s) => WorkSession.fromJson(Map<String, dynamic>.from(s)))
          .toList(),
      settings: Map<String, dynamic>.from(j['settings']),
      pendingOrder: j['pendingOrder'] == null
          ? null
          : Map<String, dynamic>.from(j['pendingOrder']),
    );
  }
  WorkroomState copy() =>
      WorkroomState.fromJson(jsonDecode(jsonEncode(toJson())));
}

class Achievement {
  const Achievement(this.title, this.description, this.earned, this.evidence);
  final String title, description;
  final bool earned;
  final List<String> evidence;
}

List<Achievement> achievements(WorkroomState s, {bool seeker = false}) {
  final saved = s.saved;
  final resumed = saved.where((p) => p.resumedFrom != null).toList();
  final three = s.projects
      .where((p) => s.pages(p.id).map((e) => e.localDay).toSet().length >= 3)
      .toList();
  final complete = s.projects.where((p) => p.completedAt != null).toList();
  return [
    Achievement(
      '첫 페이지',
      '결과를 직접 기록한 첫 집중',
      saved.isNotEmpty,
      saved.take(1).map((e) => e.id).toList(),
    ),
    Achievement(
      '다시 펼친 책',
      '지난 다음 행동을 이어서 기록',
      resumed.isNotEmpty,
      resumed.map((e) => e.id).toList(),
    ),
    Achievement(
      '쌓여가는 이야기',
      '한 프로젝트에 서로 다른 3일의 기록',
      three.isNotEmpty,
      three.expand((p) => s.pages(p.id).map((e) => e.id)).toList(),
    ),
    Achievement(
      '첫 번째 완료본',
      '직접 완료한 프로젝트 한 권',
      complete.isNotEmpty,
      complete.map((e) => e.id).toList(),
    ),
    Achievement(
      '기록된 10시간',
      '직접 확인한 집중 시간 10시간',
      saved.fold<int>(0, (a, b) => a + b.confirmedSec) >= 36000,
      saved.map((e) => e.id).toList(),
    ),
    Achievement('Seeker 소유자', '지갑 서명과 서버 SGT 확인 · 앱 발행', seeker, const []),
  ];
}
