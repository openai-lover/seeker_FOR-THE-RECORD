part of 'app.dart';

String _reflectionQuestion(BuildContext context, int id) => switch (id) {
  1 => tr(
    context,
    '이 선택으로 무엇을 확인하고 싶었나요?',
    'What did you want to find out by making this choice?',
  ),
  2 => tr(
    context,
    '예상과 실제 경험은 어디에서 달랐나요?',
    'Where did the experience differ from what you expected?',
  ),
  3 => tr(
    context,
    '주변의 기대를 빼면, 나에게 중요한 이유는 무엇인가요?',
    'Without other people’s expectations, what reason matters to you?',
  ),
  4 => tr(
    context,
    '다음 선택 전에 확인할 작은 기준 하나는 무엇인가요?',
    'What is one small thing you will check before your next choice?',
  ),
  _ => tr(
    context,
    '이번에 도움이 됐던 행동 중 다시 해볼 것은 무엇인가요?',
    'What helped this time that you would try again?',
  ),
};

class _DecisionReplayCard extends StatelessWidget {
  const _DecisionReplayCard({required this.c, required this.r});
  final WorkroomController c;
  final RemoteService r;
  @override
  Widget build(BuildContext context) {
    final entries = c.journals.entries;
    final now = c.wallClock().millisecondsSinceEpoch;
    final due = entries.where((e) => e.isDue(now)).toList()
      ..sort((a, b) => a.reviewDueAt!.compareTo(b.reviewDueAt!));
    final upcoming =
        entries
            .where((e) => e.reviewDueAt != null && e.reviewedAt == null)
            .toList()
          ..sort((a, b) => a.reviewDueAt!.compareTo(b.reviewDueAt!));
    final rules = entries
        .where((e) => e.decisionRule.trim().isNotEmpty)
        .toList();
    final entry = due.firstOrNull;
    return PaperCard(
      color: const Color(0xFFE1F4EF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Eyebrow('DECISION REPLAY'),
          const SizedBox(height: 12),
          Text(
            entry != null
                ? tr(context, '오늘 돌아볼 선택', 'A choice to revisit today')
                : tr(
                    context,
                    '선택은 지나가도, 이유는 남아요.',
                    'Keep the reason. Carry the lesson.',
                  ),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          Text(
            entry != null
                ? (entry.originalReason ?? entry.reason)
                : tr(
                    context,
                    '거래 내역에는 왜 했는지가 없죠. 이유 한 줄을 남기고, 나중에 돌아와 다음 기준으로 만들어 보세요.',
                    'Your wallet history misses the why. Save one reason, revisit it later, and keep a lesson for your next choice.',
                  ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          if (entry == null && upcoming.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '${tr(context, '다음 돌아보기', 'Next revisit')} · ${dateLabel(context, upcoming.first.reviewDueAt!)}',
              style: const TextStyle(color: green, fontSize: 12),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            key: const ValueKey('decision-replay-open'),
            icon: Icon(
              entry == null
                  ? Icons.edit_note_rounded
                  : Icons.history_edu_rounded,
            ),
            label: Text(
              entry != null
                  ? tr(context, '당시 생각 다시 보기', 'Revisit my reason')
                  : tr(context, '매매 일지 열기', 'Open trade journal'),
            ),
            onPressed: () => openPage(
              context,
              entry != null
                  ? _JournalEditor(
                      c: c,
                      wallet: entry.wallet,
                      activity: entry.activity,
                      entry: entry,
                      reviewOnly: true,
                    )
                  : Scaffold(
                      appBar: AppBar(
                        title: Text(tr(context, '매매 일지', 'Trade journal')),
                      ),
                      body: _TradeJournal(c: c, r: r),
                    ),
            ),
          ),
          if (rules.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.bookmark_added_outlined, size: 18),
              label: Text(
                tr(
                  context,
                  '내가 남긴 기준 ${rules.length}개',
                  'Saved lessons (${rules.length})',
                ),
              ),
              onPressed: () => openPage(
                context,
                Scaffold(
                  appBar: AppBar(
                    title: Text(
                      tr(
                        context,
                        '다음 선택을 위한 나의 기준',
                        'Lessons for my next choice',
                      ),
                    ),
                  ),
                  body: PageBody(
                    children: [
                      for (final e in rules)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: PaperCard(
                            onTap: () => openPage(
                              context,
                              _JournalDetail(c: c, r: r, id: e.id),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.decisionRule,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_activityLabel(context, e.activity)} · ${tr(context, '출처 기록 열기', 'Open source record')}',
                                  style: const TextStyle(
                                    color: muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SavedReason extends StatelessWidget {
  const _SavedReason(this.entry);
  final TradeJournalEntry entry;
  @override
  Widget build(BuildContext context) => PaperCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, '그때 남긴 생각', 'The thought you saved'),
          style: const TextStyle(fontWeight: FontWeight.w700, color: green),
        ),
        const SizedBox(height: 8),
        Text(
          (entry.originalReason ?? entry.reason).isEmpty
              ? '—'
              : (entry.originalReason ?? entry.reason),
        ),
        if ((entry.originalPlan ?? entry.plan).isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(entry.originalPlan ?? entry.plan),
        ],
        const SizedBox(height: 10),
        Text(
          '${tr(context, '메모 저장', 'Note saved')} · ${dateLabel(context, entry.baselineSavedAt ?? entry.updatedAt)}',
          style: const TextStyle(fontSize: 12, color: muted),
        ),
        Text(
          tr(
            context,
            '거래 후 작성한 기록이며, 온체인으로 증명된 동기는 아닙니다.',
            'Written after the transaction; the chain does not prove your intention.',
          ),
          style: const TextStyle(fontSize: 11, color: muted),
        ),
      ],
    ),
  );
}

class _ReflectionAssistantPanel extends StatefulWidget {
  const _ReflectionAssistantPanel({
    required this.contextText,
    required this.onSelected,
    this.selection,
    this.manageOnly = false,
  });
  final String Function() contextText;
  final ValueChanged<Map<String, dynamic>> onSelected;
  final Map<String, dynamic>? selection;
  final bool manageOnly;
  @override
  State<_ReflectionAssistantPanel> createState() =>
      _ReflectionAssistantPanelState();
}

class _ReflectionAssistantPanelState extends State<_ReflectionAssistantPanel> {
  final assistant = const ReflectionAssistant();
  bool ready = false, busy = false, downloading = false, supported = true;
  double? progress;
  String? error;
  Timer? poll;
  int generation = 0;
  Map<String, dynamic>? pending;
  @override
  void initState() {
    super.initState();
    unawaited(_status());
  }

  @override
  void didUpdateWidget(covariant _ReflectionAssistantPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (pending != null && pending!['context'] != widget.contextText()) {
      pending = null;
      error = 'changed';
    }
  }

  Future<void> _status() async {
    try {
      final s = await assistant.status();
      if (mounted) {
        setState(() {
          ready = s['ready'] == true;
          supported = s['supported'] == true;
          progress =
              (s['downloaded'] as num? ?? 0) / ReflectionAssistant.modelBytes;
        });
      }
    } catch (_) {
      if (mounted) setState(() => supported = false);
    }
  }

  Future<void> _run(bool download) async {
    final token = ++generation;
    setState(() {
      busy = true;
      downloading = download;
      error = null;
      pending = null;
    });
    if (download) {
      poll = Timer.periodic(
        const Duration(seconds: 1),
        (_) => unawaited(_status()),
      );
    }
    try {
      if (download) {
        await assistant.download();
        await _status();
      } else {
        final context = widget.contextText();
        final selected = await assistant.suggest(context);
        if (mounted && generation == token) {
          if (widget.contextText() == context) {
            if (selected['candidates'] is List) {
              setState(() => pending = selected);
            } else {
              widget.onSelected(selected);
            }
          } else {
            setState(() => error = 'changed');
          }
        }
      }
    } on PlatformException catch (e) {
      if (mounted && generation == token) setState(() => error = e.code);
    } catch (_) {
      if (mounted && generation == token) setState(() => error = 'unavailable');
    } finally {
      if (generation == token) poll?.cancel();
      if (mounted && generation == token) {
        setState(() {
          busy = false;
          downloading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    generation++;
    poll?.cancel();
    if (busy) unawaited(assistant.cancel().catchError((_) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chosen = widget.selection;
    final valid = chosen != null;
    return PaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_outlined, size: 20, color: green),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tr(
                    context,
                    '기기 안의 AI 회고 도우미',
                    'On-device reflection assistant',
                  ),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tr(
              context,
              '내 글에 맞는 질문 하나를 골라줘요. 기록은 서버로 전송되지 않습니다.',
              'Chooses one question for your writing. Your notes are not sent to a server.',
            ),
            style: const TextStyle(fontSize: 12, color: muted),
          ),
          if (valid) ...[
            const SizedBox(height: 16),
            Text(
              _reflectionQuestion(context, chosen['questionId'] as int),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              chosen['source'] == 'manual'
                  ? tr(context, '내가 고른 질문', 'Question selected by you')
                  : chosen['userChosen'] == true
                  ? tr(
                      context,
                      'AI 제안 중 내가 고른 질문',
                      'Your choice from AI suggestions',
                    )
                  : tr(
                      context,
                      'AI가 고른 질문 · 답과 기준은 직접 작성해요.',
                      'Question selected by AI. The answer and lesson are yours.',
                    ),
              style: const TextStyle(fontSize: 11, color: green),
            ),
          ],
          if (pending != null) ...[
            const SizedBox(height: 16),
            Text(
              tr(
                context,
                '두 방향이 어울려요. 지금 더 돌아보고 싶은 질문을 골라주세요.',
                'Two directions may fit. Choose what you want to explore.',
              ),
            ),
            const SizedBox(height: 8),
            for (final id in pending!['candidates'] as List)
              OutlinedButton(
                onPressed: busy
                    ? null
                    : () {
                        final proposal = pending!;
                        if (proposal['context'] != widget.contextText()) {
                          setState(() {
                            pending = null;
                            error = 'changed';
                          });
                          return;
                        }
                        widget.onSelected({
                          ...proposal,
                          'questionId': id,
                          'userChosen': true,
                        });
                        setState(() => pending = null);
                      },
                child: Text(_reflectionQuestion(context, id as int)),
              ),
          ],
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error == 'empty-note'
                  ? tr(
                      context,
                      '먼저 내 생각을 한 줄 적어주세요.',
                      'Write a little about your choice first.',
                    )
                  : error == 'changed'
                  ? tr(
                      context,
                      '글이 바뀌었어요. 다시 질문을 골라주세요.',
                      'Your writing changed. Choose a question again.',
                    )
                  : error == 'busy'
                  ? tr(
                      context,
                      '이전 요청을 마무리하는 중이에요. 잠시 후 다시 시도해 주세요.',
                      'The previous request is finishing. Try again shortly.',
                    )
                  : tr(
                      context,
                      'AI 질문을 준비하지 못했어요. 직접 회고를 쓰거나 다시 시도할 수 있습니다.',
                      'The AI question is unavailable. You can write your own reflection or retry.',
                    ),
              style: const TextStyle(color: brass, fontSize: 12),
            ),
          ],
          const SizedBox(height: 14),
          if (busy) ...[
            LinearProgressIndicator(
              value: downloading ? progress?.clamp(0, 1) : null,
            ),
            const SizedBox(height: 8),
            Text(
              downloading
                  ? tr(context, 'AI 모델 내려받는 중…', 'Downloading the AI model…')
                  : tr(
                      context,
                      '기기에서 질문을 고르는 중…',
                      'Choosing a question on your device…',
                    ),
            ),
            TextButton(
              onPressed: () async {
                generation++;
                await assistant.cancel();
                poll?.cancel();
                if (mounted) {
                  setState(() {
                    busy = false;
                    downloading = false;
                  });
                }
              },
              child: Text(tr(context, '취소', 'Cancel')),
            ),
          ] else if (!supported)
            Text(
              tr(
                context,
                '이 기능은 ARM64 Android 기기에서 사용할 수 있어요.',
                'Available on ARM64 Android devices.',
              ),
              style: const TextStyle(fontSize: 12, color: muted),
            )
          else if (!ready) ...[
            Text(
              tr(
                context,
                '처음 한 번 약 133MB를 Hugging Face에서 내려받습니다. Wi-Fi를 권장해요. 이후에는 오프라인으로 사용할 수 있어요.',
                'One 133 MB model download from Hugging Face. Wi-Fi recommended. Then it works offline.',
              ),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => _run(true),
              child: Text(
                tr(context, '무료 AI 모델 내려받기', 'Download free AI model'),
              ),
            ),
          ] else ...[
            if (!widget.manageOnly)
              FilledButton.tonalIcon(
                onPressed: () => _run(false),
                icon: const Icon(Icons.auto_awesome_outlined),
                label: Text(
                  tr(
                    context,
                    '내 기록에 맞는 질문 고르기',
                    'Choose a question for my note',
                  ),
                ),
              ),
            if (widget.manageOnly)
              TextButton(
                onPressed: () async {
                  await perform(context, assistant.remove);
                  await _status();
                },
                child: Text(
                  tr(
                    context,
                    'AI 모델 삭제 · 기록은 유지',
                    'Remove AI model · keep my notes',
                  ),
                ),
              ),
          ],
          if (!widget.manageOnly)
            TextButton(
              onPressed: busy
                  ? null
                  : () async {
                      final id = await showModalBottomSheet<int>(
                        context: context,
                        isScrollControlled: true,
                        builder: (sheetContext) => SafeArea(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (var id = 1; id <= 5; id++)
                                  ListTile(
                                    title: Text(
                                      _reflectionQuestion(sheetContext, id),
                                    ),
                                    onTap: () =>
                                        Navigator.pop(sheetContext, id),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                      if (id != null && mounted) {
                        widget.onSelected({
                          'questionId': id,
                          'source': 'manual',
                          'generatedAt': DateTime.now().millisecondsSinceEpoch,
                          'context': widget.contextText(),
                        });
                      }
                    },
              child: Text(tr(context, '질문 직접 고르기', 'Choose a question myself')),
            ),
          if (widget.manageOnly) const SizedBox(height: 4),
          if (widget.manageOnly)
            const Text(
              'multilingual-e5-small Q8 · MIT',
              style: TextStyle(fontSize: 10, color: muted),
            ),
        ],
      ),
    );
  }
}
