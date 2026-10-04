part of 'app.dart';

class _RelatedRecordsPanel extends StatefulWidget {
  const _RelatedRecordsPanel({
    required this.journals,
    required this.wallet,
    required this.currentId,
    required this.query,
  });
  final TradeJournalController journals;
  final String wallet;
  final String? currentId;
  final String Function() query;
  @override
  State<_RelatedRecordsPanel> createState() => _RelatedRecordsPanelState();
}

class _RelatedRecordsPanelState extends State<_RelatedRecordsPanel> {
  List<RelatedRecord>? matches;
  bool busy = false;
  String? error, searched;
  int generation = 0;
  @override
  void initState() {
    super.initState();
    widget.journals.addListener(_recordsChanged);
  }

  void _recordsChanged() {
    generation++;
    if (mounted) {
      setState(() {
        matches = null;
        searched = null;
      });
    }
  }

  @override
  void didUpdateWidget(covariant _RelatedRecordsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.journals != widget.journals) {
      oldWidget.journals.removeListener(_recordsChanged);
      widget.journals.addListener(_recordsChanged);
    }
    if (oldWidget.journals != widget.journals ||
        oldWidget.wallet != widget.wallet ||
        oldWidget.currentId != widget.currentId ||
        (searched != null && searched != RelatedRecords.clip(widget.query()))) {
      generation++;
      matches = null;
      searched = null;
      error = null;
    }
  }

  @override
  void dispose() {
    generation++;
    widget.journals.removeListener(_recordsChanged);
    if (busy) {
      unawaited(const ReflectionAssistant().cancel().catchError((_) {}));
    }
    super.dispose();
  }

  Future<void> search() async {
    final query = RelatedRecords.clip(widget.query());
    if (query.isEmpty) {
      setState(
        () =>
            error = tr(context, '먼저 이유를 한 줄 적어 주세요.', 'Write a reason first.'),
      );
      return;
    }
    final records = RelatedRecords.candidates(
      widget.journals.entries,
      widget.wallet,
      widget.currentId,
    );
    final token = ++generation;
    setState(() {
      busy = true;
      error = null;
      matches = null;
      searched = query;
    });
    try {
      final result = await const RelatedRecords().search(query, records);
      if (!mounted ||
          token != generation ||
          query != RelatedRecords.clip(widget.query())) {
        return;
      }
      setState(() => matches = result);
    } on PlatformException catch (e) {
      if (mounted && token == generation) {
        setState(
          () => error = e.code == 'model-missing'
              ? tr(
                  context,
                  '설정에서 로컬 AI 모델을 먼저 내려받아 주세요. 기록은 아래에서 직접 볼 수 있어요.',
                  'Download the local AI model in Settings first. You can still browse your records below.',
                )
              : tr(
                  context,
                  '지금은 찾지 못했어요. 잠시 후 다시 시도하거나 직접 기록을 열어 주세요.',
                  'Search could not finish. Retry shortly or browse your records.',
                ),
        );
      }
    } catch (_) {
      if (mounted && token == generation) {
        setState(
          () => error = tr(
            context,
            '기록을 찾지 못했어요. 다시 시도해 주세요.',
            'Could not search records. Please retry.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void openSource(TradeJournalEntry e) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .7,
      maxChildSize: .92,
      builder: (_, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            tr(ctx, '내가 남긴 원문', 'Your original record'),
            style: Theme.of(ctx).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            dateLabel(ctx, e.baselineSavedAt ?? e.createdAt),
            style: const TextStyle(color: muted),
          ),
          const SizedBox(height: 20),
          for (final pair in [
            (tr(ctx, '당시 이유', 'Reason then'), e.originalReason ?? e.reason),
            (tr(ctx, '돌아본 내용', 'Later reflection'), e.review),
            (tr(ctx, '남긴 기준', 'Saved lesson'), e.decisionRule),
          ])
            if (pair.$2.trim().isNotEmpty) ...[
              Text(
                pair.$1,
                style: const TextStyle(
                  color: green,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(pair.$2),
              const SizedBox(height: 20),
            ],
          _ActivityContext(e.activity),
          const SizedBox(height: 20),
          Text(
            tr(
              ctx,
              'AI가 새로 쓴 내용이 아닌, 이 기기에 저장된 기록입니다.',
              'These are saved words from this device, not AI-generated text.',
            ),
          ),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final records = RelatedRecords.candidates(
      widget.journals.entries,
      widget.wallet,
      widget.currentId,
    );
    if (records.isEmpty) return const SizedBox.shrink();
    return PaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tr(context, '비슷했던 나의 선택', 'A similar choice from your past'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            records.isEmpty
                ? tr(
                    context,
                    '같은 지갑에 기록을 더 남기면, 다음에는 당시의 이유와 교훈을 함께 찾을 수 있어요.',
                    'As you save more records for this wallet, find earlier reasons and lessons here.',
                  )
                : tr(
                    context,
                    '같은 지갑의 최근 기록 32개 안에서 찾습니다. 내용은 기기 밖으로 보내지 않아요.',
                    'Search up to 32 recent records for this wallet. Your writing stays on this device.',
                  ),
            style: const TextStyle(color: muted, fontSize: 13),
          ),
          if (records.isNotEmpty) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const ValueKey('related-records-search'),
              onPressed: busy ? null : search,
              icon: const Icon(Icons.manage_search),
              label: Text(
                busy
                    ? tr(context, '찾는 중…', 'Searching…')
                    : tr(context, '비슷한 기록 찾기', 'Find related records'),
              ),
            ),
            if (busy) ...[
              const LinearProgressIndicator(),
              TextButton(
                onPressed: () async {
                  generation++;
                  await const ReflectionAssistant().cancel();
                },
                child: Text(tr(context, '취소', 'Cancel')),
              ),
            ],
            if (error != null)
              Text(error!, style: const TextStyle(color: muted)),
            if (matches != null) ...[
              Text(
                matches!.isEmpty
                    ? tr(
                        context,
                        '가까운 기록을 찾지 못했어요. 직접 기록을 살펴보세요.',
                        'No close record found. You can browse your records instead.',
                      )
                    : tr(
                        context,
                        '관련이 없을 수도 있어요. 원문을 읽고 직접 비교해 보세요.',
                        'Suggestions may be unrelated. Read the originals and compare for yourself.',
                      ),
                style: const TextStyle(fontSize: 12, color: muted),
              ),
              for (final m in matches!)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    m.entry.originalReason ?? m.entry.reason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    m.entry.decisionRule.isEmpty
                        ? dateLabel(context, m.entry.createdAt)
                        : m.entry.decisionRule,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => openSource(m.entry),
                ),
            ],
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(tr(context, '직접 기록 보기', 'Browse saved records')),
              children: [
                for (final e in records)
                  ListTile(
                    title: Text(
                      e.originalReason ?? e.reason,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(dateLabel(context, e.createdAt)),
                    onTap: () => openSource(e),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
