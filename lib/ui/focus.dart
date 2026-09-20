part of 'app.dart';

class _Prepare extends StatefulWidget {
  const _Prepare({required this.c, required this.r, required this.projectId});
  final WorkroomController c;
  final RemoteService r;
  final String projectId;
  @override
  State<_Prepare> createState() => _PrepareState();
}

class _PrepareState extends State<_Prepare> {
  late TextEditingController intent;
  final custom = TextEditingController();
  int minutes = 25;
  WorkSession? last;
  @override
  void initState() {
    super.initState();
    last = widget.c.state.pages(widget.projectId).firstOrNull;
    intent = TextEditingController(text: last?.nextAction ?? '');
  }

  @override
  void dispose() {
    intent.dispose();
    custom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.c.state.project(widget.projectId)!;
    return Scaffold(
      appBar: AppBar(title: const LocalizedText('집중 준비')),
      body: PageBody(
        children: [
          const Eyebrow('SET A SMALL INTENTION'),
          const SizedBox(height: 12),
          LocalizedText(
            '이번 페이지에는\n무엇을 남길까요?',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 24),
          QuietTag(p.title, icon: Icons.menu_book_rounded, localize: false),
          const SizedBox(height: 18),
          TextField(
            controller: intent,
            maxLength: 240,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: uiText(context, '이번에 해볼 일'),
              hintText: uiText(context, '예: 로그인 오류를 재현하고 원인 찾기'),
              helperText: last?.nextAction.isNotEmpty == true
                  ? uiText(context, '지난번의 다음 행동을 불러왔어요.')
                  : null,
            ),
          ),
          const SizedBox(height: 18),
          const LocalizedText(
            '나에게 필요한 시간',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              for (final value in [10, 25, 45])
                ChoiceChip(
                  label: Text(tr(context, '$value분', '$value min')),
                  selected: minutes == value,
                  onSelected: (_) => setState(() => minutes = value),
                ),
              ChoiceChip(
                label: Text(
                  [10, 25, 45].contains(minutes)
                      ? uiText(context, '직접 선택')
                      : tr(context, '$minutes분', '$minutes min'),
                ),
                selected: ![10, 25, 45].contains(minutes),
                onSelected: (_) async {
                  String? validation;
                  final selected = await showDialog<int>(
                    context: context,
                    builder: (context) => StatefulBuilder(
                      builder: (context, updateDialog) => AlertDialog(
                        title: const LocalizedText('집중 시간'),
                        content: TextField(
                          controller: custom,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            errorText: validation,
                            labelText: uiText(context, '1~180분'),
                            helperText: uiText(
                              context,
                              '1분으로 알림과 복구를 먼저 확인할 수 있어요.',
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const LocalizedText('취소'),
                          ),
                          FilledButton(
                            onPressed: () {
                              final v = int.tryParse(custom.text);
                              if (v != null && v >= 1 && v <= 180) {
                                Navigator.pop(context, v);
                              } else {
                                updateDialog(
                                  () => validation = tr(
                                    context,
                                    '1부터 180까지의 분을 입력해 주세요.',
                                    'Enter a number of minutes from 1 to 180.',
                                  ),
                                );
                              }
                            },
                            child: const LocalizedText('선택'),
                          ),
                        ],
                      ),
                    ),
                  );
                  if (selected != null) setState(() => minutes = selected);
                },
              ),
            ],
          ),
          const SizedBox(height: 28),
          PaperCard(
            color: const Color(0xFFE1F4EF),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.spa_outlined, color: green, size: 21),
                const SizedBox(width: 12),
                const Expanded(
                  child: LocalizedText(
                    '휴대폰을 내려놓아도 괜찮아요.\n돌아오면 오늘의 일을 이어갑니다.',
                    style: TextStyle(color: green, fontSize: 13, height: 1.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ActionButton(
            label: uiText(context, '혼자 집중 시작'),
            icon: Icons.play_arrow_rounded,
            action: () async {
              final resumed =
                  last?.nextAction.trim() == intent.text.trim() &&
                      intent.text.trim().isNotEmpty
                  ? last?.id
                  : null;
              await widget.c.start(
                p.id,
                intent.text,
                minutes,
                resumedFrom: resumed,
              );
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => _Focus(c: widget.c, r: widget.r),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 10),
          if (widget.r.cloudAvailable)
            ActionButton(
              label: uiText(context, '동료와 25분 함께하기'),
              icon: Icons.people_outline_rounded,
              outlined: true,
              action: () async {
                if (intent.text.trim().isEmpty) {
                  throw ArgumentError('함께할 시간에 해볼 일을 먼저 적어 주세요.');
                }
                await widget.c.setting('sharedDraft', {
                  'projectId': p.id,
                  'intent': intent.text.trim(),
                  'resumedFrom': last?.nextAction.trim() == intent.text.trim()
                      ? last?.id
                      : null,
                });
                if (context.mounted) {
                  openPage(context, _Shared(c: widget.c, r: widget.r));
                }
              },
            ),
          const SizedBox(height: 15),
          if (widget.r.cloudAvailable)
            const LocalizedText(
              '혼자 쓰기는 지갑 없이 · 공동 작업은 Seeker 보유 확인 후',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 11),
            ),
        ],
      ),
    );
  }
}

class _Focus extends StatelessWidget {
  const _Focus({required this.c, required this.r});
  final WorkroomController c;
  final RemoteService r;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([c, r]),
    builder: (context, _) {
      final a = c.state.active;
      if (a == null) {
        return Scaffold(
          appBar: AppBar(),
          body: const Center(child: LocalizedText('페이지가 책에 남았습니다.')),
        );
      }
      final remaining = (a.plannedSec * 1000 - a.elapsedAt(c.now!)).clamp(
        0,
        a.plannedSec * 1000,
      );
      final seconds = (remaining / 1000).ceil();
      final done = a.status == SessionStatus.awaitingOutcome;
      return Scaffold(
        appBar: AppBar(
          title: Text(
            a.roomId != null
                ? uiText(context, '함께하는 집중')
                : uiText(context, '나의 집중'),
          ),
          actions: [
            IconButton(
              tooltip: uiText(context, '작업실로'),
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              icon: const Icon(Icons.home_outlined),
            ),
          ],
        ),
        body: PageBody(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Eyebrow(
                a.needsRecovery
                    ? 'A MOMENT TO CHECK'
                    : done
                    ? 'TIME TO REFLECT'
                    : a.status == SessionStatus.paused
                    ? 'TAKE YOUR TIME'
                    : 'MAKE ROOM FOR ONE THING',
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                    fontSize: 68,
                    color: green,
                    letterSpacing: -3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                a.needsRecovery
                    ? uiText(context, '재부팅 이후 시간 확인이 필요합니다.')
                    : done
                    ? uiText(context, '예정 시간이 끝났어요.')
                    : a.status == SessionStatus.paused
                    ? uiText(context, '잠시 쉬어가도 괜찮아요.')
                    : uiText(context, '지금은 이 한 가지에만.'),
                style: const TextStyle(color: muted),
              ),
            ),
            const SizedBox(height: 28),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: 1 - remaining / (a.plannedSec * 1000),
                minHeight: 8,
                backgroundColor: line,
                color: green,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              c.state.project(a.projectId)?.title ?? '',
              style: const TextStyle(color: muted, fontSize: 12),
            ),
            const SizedBox(height: 7),
            Text(a.intent, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 22),
            if (a.roomId != null) ...[
              PaperCard(
                padding: const EdgeInsets.all(16),
                child: Text(
                  r.offline
                      ? uiText(context, '연결이 끊겨도 내 집중과 기록은 계속됩니다.')
                      : uiText(context, _partnerMessage(r)),
                  style: const TextStyle(fontSize: 13, color: muted),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (a.needsRecovery)
              ActionButton(
                label: uiText(context, '시간 확인하고 복구'),
                icon: Icons.history_rounded,
                action: () async {
                  final value = TextEditingController(
                    text: (a.accumulatedMs ~/ 60000).toString(),
                  );
                  final result = await showDialog<int>(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => AlertDialog(
                      title: const LocalizedText('얼마나 집중했나요?'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const LocalizedText(
                            '기기가 재시작되어 남은 시간을 정확하게 알 수 없습니다. 확인한 시간만 기록하며 자동으로 완료하지 않습니다.',
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: value,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: tr(
                                context,
                                tr(
                                  context,
                                  '확인한 분 (0~${a.plannedSec ~/ 60})',
                                  'Confirmed minutes (0–${a.plannedSec ~/ 60})',
                                ),
                                'Confirmed minutes (0–${a.plannedSec ~/ 60})',
                              ),
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        FilledButton(
                          onPressed: () {
                            final v = int.tryParse(value.text);
                            if (v != null && v >= 0 && v * 60 <= a.plannedSec) {
                              Navigator.pop(context, v * 60);
                            }
                          },
                          child: const LocalizedText('이 시간으로 복구'),
                        ),
                      ],
                    ),
                  );
                  value.dispose();
                  if (result != null) await c.recover(result);
                },
              )
            else if (done)
              ActionButton(
                label: uiText(context, '결과 한 줄 남기기'),
                icon: Icons.edit_note_rounded,
                action: () async {
                  openPage(context, _Outcome(c: c, r: r, sessionId: a.id));
                },
              )
            else ...[
              ActionButton(
                label: a.status == SessionStatus.paused
                    ? uiText(context, '다시 집중')
                    : uiText(context, '잠시 멈춤'),
                icon: a.status == SessionStatus.paused
                    ? Icons.play_arrow_rounded
                    : Icons.pause_rounded,
                outlined: true,
                action: c.pause,
              ),
              const SizedBox(height: 10),
              ActionButton(
                label: uiText(context, '여기서 마무리'),
                icon: Icons.check_rounded,
                action: () async {
                  await c.finish();
                  if (context.mounted) {
                    openPage(context, _Outcome(c: c, r: r, sessionId: a.id));
                  }
                },
              ),
            ],
            const SizedBox(height: 12),
            TextButton(
              onPressed: () async {
                if (await confirm(
                  context,
                  '이번 집중을 취소할까요?',
                  '이번 집중은 결과 페이지나 성취에 포함되지 않습니다. 이미 저장한 기록은 그대로 남습니다.',
                  action: uiText(context, '집중 취소'),
                )) {
                  if (!context.mounted) return;
                  final success = await perform(context, c.cancel);
                  if (success && context.mounted) {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  }
                }
              },
              child: const LocalizedText(
                '이 집중 취소',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    },
  );
}

String _partnerMessage(RemoteService r) {
  final seats = (r.room?['seats'] as List?) ?? [];
  final partner = seats.where((s) => s['uid'] != r.uid).firstOrNull;
  if (partner == null) return '내 결과는 내 책에만 남습니다.';
  return partner['left'] == true
      ? '동료가 나갔어요. 내 시간은 계속할 수 있어요.'
      : partner['finished'] == true
      ? '동료가 자신의 페이지를 마무리했어요.'
      : '동료도 자신의 페이지를 쓰고 있어요.';
}

class _Outcome extends StatefulWidget {
  const _Outcome({
    required this.c,
    required this.r,
    required this.sessionId,
    this.edit = false,
  });
  final WorkroomController c;
  final RemoteService r;
  final String sessionId;
  final bool edit;
  @override
  State<_Outcome> createState() => _OutcomeState();
}

class _OutcomeState extends State<_Outcome> with WidgetsBindingObserver {
  late TextEditingController outcome, next, seconds;
  late ResultState result;
  late WorkSession initial;
  bool saved = false, allowLeave = false, leaving = false;
  Timer? draftTimer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initial = widget.c.state.sessions.firstWhere(
      (s) => s.id == widget.sessionId,
    );
    outcome = TextEditingController(text: initial.outcome);
    next = TextEditingController(text: initial.nextAction);
    seconds = TextEditingController(
      text: (widget.edit ? initial.confirmedSec : initial.accumulatedMs ~/ 1000)
          .toString(),
    );
    result = initial.result;
    if (!widget.edit) {
      outcome.addListener(scheduleDraft);
      next.addListener(scheduleDraft);
    }
  }

  void scheduleDraft() {
    draftTimer?.cancel();
    draftTimer = Timer(
      const Duration(milliseconds: 500),
      () => unawaited(_draft()),
    );
  }

  Future<void> _draft() async {
    if (saved || widget.edit || widget.c.state.active?.id != initial.id) return;
    try {
      await widget.c.saveDraft(outcome.text, next.text, result);
    } catch (_) {
      /* Visible save retains current field values for retry. */
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(_draft());
  }

  @override
  void dispose() {
    draftTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    outcome.dispose();
    next.dispose();
    seconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: saved || allowLeave,
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop || leaving) return;
      leaving = true;
      final changed =
          outcome.text != initial.outcome ||
          next.text != initial.nextAction ||
          this.result != initial.result;
      bool leave = true;
      if (widget.edit && changed) {
        leave = await confirm(
          context,
          tr(context, '작성을 나갈까요?', 'Leave this entry?'),
          tr(
            context,
            '아직 저장하지 않은 내용은 남지 않습니다.',
            'Your unsaved changes will be lost.',
          ),
          action: tr(context, '나가기', 'Leave'),
        );
      } else if (!widget.edit && widget.c.state.active?.id == initial.id) {
        draftTimer?.cancel();
        leave = await perform(
          context,
          () => widget.c.saveDraft(outcome.text, next.text, this.result),
        );
      }
      leaving = false;
      if (leave && mounted) {
        setState(() => allowLeave = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pop(context);
        });
      }
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.edit ? uiText(context, '페이지 수정') : uiText(context, '오늘의 페이지'),
        ),
      ),
      body: PageBody(
        children: [
          const Eyebrow('PROGRESS, IN YOUR OWN WORDS'),
          const SizedBox(height: 12),
          LocalizedText(
            '어디까지 왔나요?',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 10),
          Text(initial.intent, style: const TextStyle(color: muted)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: ResultState.values
                .map(
                  (v) => ChoiceChip(
                    label: Text(uiText(context, resultLabel(v.index))),
                    selected: result == v,
                    onSelected: (_) {
                      setState(() => result = v);
                      scheduleDraft();
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: outcome,
            maxLength: 600,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: uiText(context, '해낸 일 또는 막힌 지점'),
              hintText: uiText(context, '작은 발견도 한 페이지가 됩니다.'),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: next,
            maxLength: 300,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: uiText(context, '다음에는 여기서 시작해요 (선택)'),
              hintText: uiText(context, '다음의 나에게 남기는 작은 책갈피'),
            ),
          ),
          const SizedBox(height: 16),
          if (!widget.edit)
            TextField(
              controller: seconds,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: uiText(context, '확인한 집중 시간 (초)'),
                helperText: tr(
                  context,
                  '측정 ${minutesLabel(context, initial.accumulatedMs ~/ 1000)} 이내 · 자기 기록${initial.timeAdjusted ? ' · 복구 후 직접 확인' : ''}',
                  'Up to ${minutesLabel(context, initial.accumulatedMs ~/ 1000)} measured · Self-reported${initial.timeAdjusted ? ' · Confirmed after recovery' : ''}',
                ),
              ),
            ),
          const SizedBox(height: 24),
          ActionButton(
            label: widget.edit
                ? uiText(context, '수정한 페이지 저장')
                : uiText(context, '내 프로젝트 책에 남기기'),
            icon: Icons.bookmark_added_outlined,
            action: () async {
              draftTimer?.cancel();
              final first = widget.c.state.saved.isEmpty;
              if (widget.edit) {
                await widget.c.editPage(
                  initial.id,
                  outcome.text,
                  next.text,
                  result,
                );
              } else {
                await widget.c.save(
                  initial.id,
                  outcome.text,
                  next.text,
                  result,
                  int.tryParse(seconds.text) ?? -1,
                );
              }
              setState(() => saved = true);
              if (!widget.edit &&
                  initial.roomId != null &&
                  widget.r.room?['roomId'] == initial.roomId) {
                await widget.c.setting('pendingRoomFinish', initial.roomId);
                unawaited(widget.r.syncPendingFinish());
              }
              if (widget.c.state.settings['haptics'] != false) {
                unawaited(HapticFeedback.lightImpact());
              }
              if (!context.mounted) return;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  Navigator.popUntil(context, (route) => route.isFirst);
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    first
                        ? uiText(context, '첫 페이지가 생겼어요. 오늘의 진전을 책에 남겼습니다.')
                        : uiText(context, '페이지를 저장했어요. 다음의 내가 여기서 이어갈 거예요.'),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          if (!widget.edit)
            TextButton(
              onPressed: () async {
                final ok = await perform(
                  context,
                  () => widget.c.saveDraft(outcome.text, next.text, result),
                );
                if (ok && context.mounted) {
                  setState(() => allowLeave = true);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    }
                  });
                }
              },
              child: const LocalizedText('초안을 두고 나중에 마무리'),
            ),
          const SizedBox(height: 10),
          const LocalizedText(
            '이 문장은 동료에게 공유되지 않습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}
