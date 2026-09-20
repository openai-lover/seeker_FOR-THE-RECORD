part of 'app.dart';

class _Records extends StatefulWidget {
  const _Records({required this.c, required this.r, this.initialTrade = false});
  final WorkroomController c;
  final RemoteService r;
  final bool initialTrade;
  @override
  State<_Records> createState() => _RecordsState();
}

class _RecordsState extends State<_Records> {
  late bool trade = widget.initialTrade;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: SegmentedButton<bool>(
          segments: [
            ButtonSegment(
              value: false,
              icon: const Icon(Icons.auto_stories_outlined),
              label: Text(tr(context, '작업 기록', 'Work journal')),
            ),
            ButtonSegment(
              value: true,
              icon: const Icon(Icons.edit_note_rounded),
              label: Text(tr(context, '매매 일지', 'Trade journal')),
            ),
          ],
          selected: {trade},
          onSelectionChanged: (v) => setState(() => trade = v.single),
        ),
      ),
      Expanded(
        child: trade
            ? _TradeJournal(c: widget.c, r: widget.r)
            : _Library(c: widget.c, r: widget.r),
      ),
    ],
  );
}

class _TradeJournal extends StatefulWidget {
  const _TradeJournal({required this.c, required this.r});
  final WorkroomController c;
  final RemoteService r;
  @override
  State<_TradeJournal> createState() => _TradeJournalState();
}

class _TradeJournalState extends State<_TradeJournal> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.r.signedIn && !widget.r.activityLoaded) {
        unawaited(widget.r.loadActivity());
      }
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([widget.r, widget.c.journals]),
    builder: (context, _) {
      final r = widget.r, j = widget.c.journals;
      return PageBody(
        children: [
          const Eyebrow('THE THOUGHT BEHIND THE TRADE'),
          const SizedBox(height: 10),
          Text(
            tr(context, '판단을 남기는 일지', 'Remember your why.'),
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 10),
          Text(
            tr(
              context,
              '지갑은 무엇을 거래했는지,\nWorkroom은 왜 그랬는지 기억합니다.',
              'Your wallet remembers what you traded.\nFOR THE RECORD remembers why.',
            ),
            style: const TextStyle(color: muted),
          ),
          const SizedBox(height: 22),
          PaperCard(
            color: const Color(0xFFEAF0E8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const QuietTag('READ ONLY', icon: Icons.visibility_outlined),
                const SizedBox(height: 10),
                Text(
                  tr(
                    context,
                    '지갑 활동을 읽어와 기록만 합니다.\nWorkroom에서 자산을 거래하거나 이동하지 않습니다.',
                    'Read your wallet history and reflect.\nNo trades or asset transfers happen here.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (!r.signedIn)
            PaperCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(
                      context,
                      r.onlineAvailable
                          ? '지갑에서 시작한 일, 여기서 돌아보기'
                          : '이 미리보기에서는 지갑에 연결할 수 없습니다.',
                      r.onlineAvailable
                          ? 'Bring your decisions into focus'
                          : 'Wallet connection is not available in this preview.',
                    ),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tr(
                      context,
                      r.onlineAvailable
                          ? 'Seed Vault Wallet 또는 MWA 호환 지갑을 연결하세요. 메모는 이 기기에만 저장됩니다.'
                          : '작업 기록은 오프라인에서 사용할 수 있습니다. 지갑 활동을 불러오려면 온라인 서비스 설정이 필요합니다.',
                      r.onlineAvailable
                          ? 'Connect Seed Vault Wallet or an MWA compatible wallet. Notes stay on this device.'
                          : 'Your work journal is ready to use offline. Online services must be configured before you can load wallet activity.',
                    ),
                  ),
                  if (r.directMode) ...[
                    const SizedBox(height: 12),
                    Text(
                      tr(
                        context,
                        '공개 지갑 주소와 거래 ID를 Solana 공개 RPC로 직접 전송합니다. 메모는 이 기기에 남습니다.',
                        'Your public wallet address and transaction IDs go directly to Solana public RPC. Your notes stay here.',
                      ),
                      style: const TextStyle(fontSize: 12, color: muted),
                    ),
                  ],
                  const SizedBox(height: 20),
                  ActionButton(
                    label: tr(context, 'Seeker 지갑 연결', 'Connect Seeker wallet'),
                    icon: Icons.account_balance_wallet_outlined,
                    action: !r.onlineAvailable
                        ? null
                        : () async {
                            await r.connect();
                            await r.loadActivity();
                          },
                  ),
                ],
              ),
            )
          else ...[
            Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined, color: green),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(context, '연결된 지갑', 'Wallet connected'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _shortAddress(r.wallet ?? ''),
                        style: const TextStyle(color: muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: r.activityLoading ? null : () => r.loadActivity(),
                  tooltip: tr(context, '새로고침', 'Refresh'),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            if (r.seeker)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: QuietTag(
                  tr(context, 'Seeker 보유 확인됨', 'Seeker Verified'),
                  icon: Icons.verified_outlined,
                ),
              ),
            const SizedBox(height: 24),
            Text(
              tr(context, '최근 지갑 활동', 'Recent wallet activity'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (r.activityLoading && r.activities.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (r.activityError != null)
              _JournalNotice(
                message: activityErrorText(context, r.activityError!),
                action: () => r.loadActivity(
                  more: r.activities.isNotEmpty && r.activityCursor != null,
                ),
              ),
            if (r.activityLoaded &&
                r.activities.isEmpty &&
                r.activityError == null)
              _JournalNotice(
                message: tr(
                  context,
                  '아직 조회된 거래가 없어요. 나중에 다시 확인해 주세요.',
                  'No activity found yet. Check back later.',
                ),
              ),
            for (final a in r.activities)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ActivityCard(
                  activity: a,
                  entry: j.find(r.wallet!, a.signature),
                  onOpen: a.canJournal
                      ? () => _openJournal(
                          context,
                          widget.c,
                          widget.r,
                          r.wallet!,
                          a,
                        )
                      : null,
                ),
              ),
            if (r.activityCursor != null)
              ActionButton(
                label: tr(context, '이전 거래 불러오기', 'Load earlier activity'),
                outlined: true,
                icon: Icons.expand_more,
                action: r.activityLoading
                    ? null
                    : () => r.loadActivity(more: true),
              ),
            if (r.activityLoading && r.activities.isNotEmpty)
              const LinearProgressIndicator(),
          ],
          const SizedBox(height: 30),
          Text(
            tr(context, '이 기기에 남긴 일지', 'Saved on this device'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (j.loading) const LinearProgressIndicator(),
          if (j.error != null)
            _JournalNotice(
              message: activityErrorText(context, j.error!),
              action: j.load,
            ),
          if (!j.loading && j.entries.isEmpty && j.error == null)
            Text(
              tr(
                context,
                '거래에서 일지를 작성하면 여기에 보관됩니다.',
                'Write a reflection on a supported swap to keep it here.',
              ),
              style: const TextStyle(color: muted),
            ),
          for (final entry in j.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ActivityCard(
                activity: entry.activity,
                entry: entry,
                onOpen: () => _openJournal(
                  context,
                  widget.c,
                  widget.r,
                  entry.wallet,
                  entry.activity,
                ),
              ),
            ),
        ],
      );
    },
  );
}

String _shortAddress(String value) => value.length < 14
    ? value
    : '${value.substring(0, 5)}…${value.substring(value.length - 5)}';
void _openJournal(
  BuildContext context,
  WorkroomController c,
  RemoteService r,
  String wallet,
  WalletActivity activity,
) {
  final entry = c.journals.find(wallet, activity.signature);
  openPage(
    context,
    entry == null
        ? _JournalEditor(c: c, wallet: wallet, activity: activity)
        : _JournalDetail(c: c, r: r, id: entry.id),
  );
}

class _JournalNotice extends StatelessWidget {
  const _JournalNotice({required this.message, this.action});
  final String message;
  final Future<void> Function()? action;
  @override
  Widget build(BuildContext context) => PaperCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message),
        if (action != null) ...[
          const SizedBox(height: 12),
          ActionButton(
            label: tr(context, '다시 시도', 'Try again'),
            outlined: true,
            icon: Icons.refresh,
            action: action,
          ),
        ],
      ],
    ),
  );
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity, this.entry, this.onOpen});
  final WalletActivity activity;
  final TradeJournalEntry? entry;
  final VoidCallback? onOpen;
  @override
  Widget build(BuildContext context) {
    final a = activity;
    return PaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            a.blockTime == null
                ? tr(context, '시간 정보 없음', 'Time unavailable')
                : dateLabel(context, a.blockTime! * 1000),
            style: const TextStyle(fontSize: 12, color: muted),
          ),
          const SizedBox(height: 12),
          if (a.canJournal) ...[
            Text(
              '${a.input!.amount} ${a.input!.symbol}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Icon(Icons.south_rounded, size: 18, color: brass),
            ),
            Text(
              '${a.output!.amount} ${a.output!.symbol}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: green),
            ),
          ] else
            Text(
              a.status == 'failed'
                  ? tr(context, '실패한 거래', 'Failed transaction')
                  : tr(context, '기타 지갑 활동', 'Other wallet activity'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              if (a.source != null) QuietTag(a.source!, localize: false),
              Text(
                _shortAddress(a.signature),
                style: const TextStyle(fontSize: 12, color: muted),
              ),
            ],
          ),
          if (!a.canJournal)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                a.issue == 'parse-unavailable'
                    ? activityErrorText(context, 'parse-unavailable')
                    : tr(
                        context,
                        '확실히 확인된 스왑만 일지로 기록할 수 있어요.',
                        'Only confidently identified swaps can become trade journals.',
                      ),
                style: const TextStyle(fontSize: 12, color: muted),
              ),
            ),
          if (entry != null && entry!.reason.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                entry!.reason,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (onOpen != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onOpen,
              icon: Icon(
                entry == null
                    ? Icons.edit_outlined
                    : Icons.check_circle_outline,
                size: 18,
              ),
              label: Text(
                entry == null
                    ? tr(context, '매매일지 작성', 'Write reflection')
                    : tr(context, '기록 완료 · 일지 열기', 'Recorded · Open journal'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _JournalEditor extends StatefulWidget {
  const _JournalEditor({
    required this.c,
    required this.wallet,
    required this.activity,
    this.entry,
    this.reviewOnly = false,
  });
  final WorkroomController c;
  final String wallet;
  final WalletActivity activity;
  final TradeJournalEntry? entry;
  final bool reviewOnly;
  @override
  State<_JournalEditor> createState() => _JournalEditorState();
}

class _JournalEditorState extends State<_JournalEditor> {
  late final reason = TextEditingController(text: widget.entry?.reason),
      plan = TextEditingController(text: widget.entry?.plan),
      next = TextEditingController(text: widget.entry?.nextAction),
      review = TextEditingController(text: widget.entry?.review);
  late String emotion = widget.entry?.emotion ?? '';
  late String? project = widget.c.state
      .project(widget.entry?.projectId ?? '')
      ?.id;
  int step = 0;
  bool saved = false, dirty = false;
  @override
  void dispose() {
    reason.dispose();
    plan.dispose();
    next.dispose();
    review.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questions = [
      tr(context, '왜 이 거래를 했나요?', 'Why did you make this trade?'),
      tr(context, '거래 전에 어떤 계획이 있었나요?', 'What was your plan beforehand?'),
      tr(context, '당시 감정은 어땠나요?', 'How did you feel at the time?'),
      tr(context, '다음에 확인할 것은?', 'What will you check next?'),
    ];
    return PopScope(
      canPop: !dirty || saved,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final leave = await confirm(
          context,
          tr(context, '작성을 나갈까요?', 'Leave this entry?'),
          tr(
            context,
            '아직 저장하지 않은 내용은 남지 않습니다.',
            'Your unsaved changes will be lost.',
          ),
          action: tr(context, '나가기', 'Leave'),
        );
        if (leave && mounted) {
          setState(() => saved = true);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.pop(context);
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.reviewOnly
                ? tr(context, '판단 복기', 'Reflect on your decision')
                : tr(context, '매매 일지', 'Trade journal'),
          ),
        ),
        body: PageBody(
          children: [
            Text(
              '${widget.activity.input!.symbol} → ${widget.activity.output!.symbol}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              tr(
                context,
                '온체인 거래 사실은 수정되지 않습니다.',
                'The on-chain facts stay unchanged.',
              ),
              style: const TextStyle(fontSize: 12, color: muted),
            ),
            const SizedBox(height: 24),
            if (!widget.reviewOnly) ...[
              LinearProgressIndicator(value: (step + 1) / 4, minHeight: 3),
              const SizedBox(height: 12),
              Eyebrow('${step + 1} / 4'),
              const SizedBox(height: 20),
            ],
            Text(
              widget.reviewOnly
                  ? tr(context, '무엇을 배웠나요?', 'What did you learn?')
                  : questions[step],
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              widget.reviewOnly
                  ? tr(
                      context,
                      '잘한 점과 다음에 바꾸고 싶은 점을 남겨 보세요.',
                      'Reflect on what went well and what you would change.',
                    )
                  : tr(
                      context,
                      '짧은 한 문장이면 충분해요. 비워 두어도 괜찮습니다.',
                      'A short sentence is enough. You can leave this blank.',
                    ),
              style: const TextStyle(color: muted),
            ),
            const SizedBox(height: 24),
            if (widget.reviewOnly || step != 2)
              TextField(
                key: ValueKey(widget.reviewOnly ? 'review' : step),
                controller: widget.reviewOnly
                    ? review
                    : step == 0
                    ? reason
                    : step == 1
                    ? plan
                    : next,
                minLines: 5,
                maxLines: 10,
                maxLength: 4000,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() => dirty = true),
                decoration: InputDecoration(
                  hintText: tr(
                    context,
                    '생각을 적어 보세요…',
                    'Put your thoughts into words…',
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final e in {
                    'calm': tr(context, '차분함', 'Calm'),
                    'confident': tr(context, '확신', 'Confident'),
                    'fomo': 'FOMO',
                    'anxious': tr(context, '불안', 'Anxious'),
                    'impulsive': tr(context, '충동', 'Impulsive'),
                    'other': tr(context, '기타', 'Other'),
                  }.entries)
                    ChoiceChip(
                      label: Text(e.value),
                      selected: emotion == e.key,
                      onSelected: (v) => setState(() {
                        emotion = v ? e.key : '';
                        dirty = true;
                      }),
                    ),
                ],
              ),
            const SizedBox(height: 24),
            if (!widget.reviewOnly && step == 3) ...[
              DropdownButtonFormField<String>(
                initialValue: project,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: tr(
                    context,
                    '프로젝트 연결 (선택)',
                    'Link a project (optional)',
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(tr(context, '연결하지 않음', 'No project')),
                  ),
                  for (final p in widget.c.state.projects)
                    DropdownMenuItem(
                      value: p.id,
                      child: Text(p.title, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setState(() {
                  project = v;
                  dirty = true;
                }),
              ),
              const SizedBox(height: 24),
            ],
            if (widget.reviewOnly || step == 3)
              ActionButton(
                label: tr(context, '이 기기에 저장', 'Save on this device'),
                icon: Icons.bookmark_added_outlined,
                action: () async {
                  final now = DateTime.now().millisecondsSinceEpoch;
                  final old =
                      widget.entry ??
                      widget.c.journals.find(
                        widget.wallet,
                        widget.activity.signature,
                      );
                  final entry =
                      (old ??
                              TradeJournalEntry(
                                id: const Uuid().v4(),
                                wallet: widget.wallet,
                                activity: widget.activity,
                                createdAt: now,
                                updatedAt: now,
                              ))
                          .edit(
                            projectId: project,
                            reason: reason.text.trim(),
                            plan: plan.text.trim(),
                            emotion: emotion,
                            review: review.text.trim(),
                            nextAction: next.text.trim(),
                            updatedAt: now,
                          );
                  await widget.c.journals.save(entry);
                  if (context.mounted) {
                    setState(() => saved = true);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (context.mounted) Navigator.pop(context);
                    });
                  }
                },
              )
            else
              FilledButton(
                onPressed: () => setState(() => step++),
                child: Text(tr(context, '다음', 'Next')),
              ),
            if (!widget.reviewOnly && step > 0)
              TextButton(
                onPressed: () => setState(() => step--),
                child: Text(tr(context, '이전 질문', 'Previous question')),
              ),
            const SizedBox(height: 20),
            Text(
              tr(
                context,
                '개인 메모는 Firebase에 업로드되지 않습니다.',
                'Personal notes are never uploaded to Firebase.',
              ),
              style: const TextStyle(fontSize: 12, color: muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _JournalDetail extends StatelessWidget {
  const _JournalDetail({required this.c, required this.r, required this.id});
  final WorkroomController c;
  final RemoteService r;
  final String id;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c.journals,
    builder: (context, _) {
      final e = c.journals.entries.where((e) => e.id == id).firstOrNull;
      if (e == null) {
        return Scaffold(
          appBar: AppBar(),
          body: Center(
            child: Text(
              tr(context, '일지가 삭제되었습니다.', 'This journal was deleted.'),
            ),
          ),
        );
      }
      return Scaffold(
        appBar: AppBar(
          title: Text(tr(context, '판단의 기록', 'A record of your decision')),
        ),
        body: PageBody(
          children: [
            _ActivityCard(activity: e.activity),
            const SizedBox(height: 20),
            Text(
              tr(context, '지갑', 'Wallet'),
              style: const TextStyle(color: muted),
            ),
            SelectableText(e.wallet),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(tr(context, '온체인 사실', 'On-chain facts')),
              children: [
                for (final fact in {
                  tr(context, '서명', 'Signature'): e.signature,
                  tr(context, '입력 토큰 주소', 'Input mint'):
                      e.activity.input?.mint ?? '—',
                  tr(context, '출력 토큰 주소', 'Output mint'):
                      e.activity.output?.mint ?? '—',
                  tr(context, '네트워크 수수료', 'Network fee'):
                      '${e.activity.fee ?? "—"} SOL',
                }.entries)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(fact.key),
                    subtitle: SelectableText(fact.value),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (e.projectId != null && c.state.project(e.projectId!) != null)
              TextButton.icon(
                onPressed: () => openPage(
                  context,
                  _Book(c: c, r: r, projectId: e.projectId!),
                ),
                icon: const Icon(Icons.book_outlined),
                label: Text(c.state.project(e.projectId!)!.title),
              ),
            for (final field in {
              tr(context, '이유', 'Reason'): e.reason,
              tr(context, '계획', 'Plan'): e.plan,
              tr(context, '감정', 'Emotion'): _emotionLabel(context, e.emotion),
              tr(context, '다음 행동', 'Next action'): e.nextAction,
              tr(context, '복기', 'Reflection'): e.review,
            }.entries) ...[
              Text(
                field.key,
                style: const TextStyle(fontSize: 12, color: muted),
              ),
              const SizedBox(height: 6),
              Text(
                field.value.isEmpty ? '—' : field.value,
                style: const TextStyle(fontSize: 17, height: 1.6),
              ),
              const SizedBox(height: 24),
            ],
            ActionButton(
              label: tr(context, '복기하기', 'Reflect'),
              icon: Icons.history_edu_outlined,
              action: () async => openPage(
                context,
                _JournalEditor(
                  c: c,
                  wallet: e.wallet,
                  activity: e.activity,
                  entry: e,
                  reviewOnly: true,
                ),
              ),
            ),
            OutlinedButton(
              onPressed: () => openPage(
                context,
                _JournalEditor(
                  c: c,
                  wallet: e.wallet,
                  activity: e.activity,
                  entry: e,
                ),
              ),
              child: Text(tr(context, '메모 수정', 'Edit notes')),
            ),
            TextButton(
              onPressed: () => Clipboard.setData(
                ClipboardData(text: e.activity.explorerUrl),
              ),
              child: Text(tr(context, 'Explorer 링크 복사', 'Copy explorer link')),
            ),
            TextButton(
              onPressed: () async {
                if (await confirm(
                  context,
                  tr(context, '이 일지를 삭제할까요?', 'Delete this journal?'),
                  tr(
                    context,
                    '이 기기의 메모만 삭제됩니다. 온체인 거래는 변하지 않습니다.',
                    'Only this local journal is deleted. The on-chain transaction stays unchanged.',
                  ),
                  action: tr(context, '삭제', 'Delete'),
                )) {
                  await c.journals.delete(id);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: Text(tr(context, '일지 삭제', 'Delete journal')),
            ),
          ],
        ),
      );
    },
  );
}

String _emotionLabel(BuildContext context, String value) => switch (value) {
  'calm' => tr(context, '차분함', 'Calm'),
  'confident' => tr(context, '확신', 'Confident'),
  'fomo' => 'FOMO',
  'anxious' => tr(context, '불안', 'Anxious'),
  'impulsive' => tr(context, '충동', 'Impulsive'),
  'other' => tr(context, '기타', 'Other'),
  _ => value,
};
