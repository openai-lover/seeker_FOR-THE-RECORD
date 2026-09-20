part of 'app.dart';

class _Library extends StatefulWidget {
  const _Library({required this.c, required this.r});
  final WorkroomController c;
  final RemoteService r;
  @override
  State<_Library> createState() => _LibraryState();
}

class _LibraryState extends State<_Library> {
  String? projectId;
  DateTimeRange? range;
  @override
  Widget build(BuildContext context) {
    final s = widget.c.state;
    final pages = s.saved
        .where(
          (p) =>
              (projectId == null || p.projectId == projectId) &&
              (range == null ||
                  (p.savedAt! >= range!.start.millisecondsSinceEpoch &&
                      p.savedAt! <
                          range!.end
                              .add(const Duration(days: 1))
                              .millisecondsSinceEpoch)),
        )
        .toList();
    return PageBody(
      children: [
        const Eyebrow('YOUR PERSONAL LIBRARY'),
        const SizedBox(height: 10),
        LocalizedText(
          '내가 남긴 페이지',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 9),
        Text(
          tr(
            context,
            '${s.saved.length}번의 진전, ${minutesLabel(context, s.saved.fold<int>(0, (sum, p) => sum + p.confirmedSec))}의 기록',
            '${s.saved.length} moments of progress · ${minutesLabel(context, s.saved.fold<int>(0, (sum, p) => sum + p.confirmedSec))}',
          ),
          style: const TextStyle(color: muted, fontSize: 13),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: projectId,
                decoration: InputDecoration(labelText: uiText(context, '프로젝트')),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: LocalizedText('모든 프로젝트'),
                  ),
                  for (final p in s.projects)
                    DropdownMenuItem(
                      value: p.id,
                      child: Text(p.title, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setState(() => projectId = v),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: uiText(context, '날짜 범위 선택'),
              onPressed: () async {
                final dates = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                  initialDateRange: range,
                );
                if (dates != null) setState(() => range = dates);
              },
              icon: const Icon(Icons.calendar_month_outlined),
            ),
          ],
        ),
        if (range != null)
          Align(
            alignment: Alignment.centerLeft,
            child: InputChip(
              label: Text(
                '${dateLabel(context, range!.start.millisecondsSinceEpoch)} — ${dateLabel(context, range!.end.millisecondsSinceEpoch)}',
              ),
              onDeleted: () => setState(() => range = null),
            ),
          ),
        const SizedBox(height: 22),
        if (pages.isEmpty)
          const PaperCard(
            child: Column(
              children: [
                Icon(Icons.menu_book_outlined, size: 38, color: green),
                SizedBox(height: 16),
                LocalizedText(
                  '아직 펼쳐진 페이지가 없어요.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                LocalizedText(
                  '집중을 마치고 결과를 한 줄 남겨 보세요.\n막힌 지점도 다음 시작을 위한 기록입니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted),
                ),
              ],
            ),
          ),
        for (final p in pages)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PageCard(
              page: p,
              project: s.project(p.projectId),
              onTap: () => openPage(
                context,
                _Book(c: widget.c, r: widget.r, projectId: p.projectId),
              ),
            ),
          ),
        const SizedBox(height: 18),
        TextButton.icon(
          onPressed: () =>
              openPage(context, _Achievements(c: widget.c, r: widget.r)),
          icon: const Icon(Icons.workspace_premium_outlined),
          label: const LocalizedText('기록에서 태어난 성취'),
        ),
        const SizedBox(height: 20),
        if (s.projects.any((p) => p.status == ProjectStatus.archived)) ...[
          const Divider(),
          const LocalizedText(
            '보관한 프로젝트',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          for (final p in s.projects.where(
            (p) => p.status == ProjectStatus.archived,
          ))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.inventory_2_outlined),
              title: Text(p.title),
              subtitle: const LocalizedText('기록은 그대로 보관됩니다.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => openPage(
                context,
                _Book(c: widget.c, r: widget.r, projectId: p.id),
              ),
            ),
        ],
      ],
    );
  }
}

class _PageCard extends StatelessWidget {
  const _PageCard({
    required this.page,
    required this.project,
    this.onTap,
    this.onEdit,
  });
  final WorkSession page;
  final Project? project;
  final VoidCallback? onTap, onEdit;
  @override
  Widget build(BuildContext context) => PaperCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${dateLabel(context, page.savedAt!)} · ${minutesLabel(context, page.confirmedSec)}',
                style: const TextStyle(fontSize: 11, color: muted),
              ),
            ),
            if (page.roomId != null)
              const Icon(Icons.people_outline_rounded, size: 16, color: green),
            if (onEdit != null)
              IconButton(
                tooltip: uiText(context, '페이지 수정'),
                onPressed: onEdit,
                icon: const Icon(Icons.more_horiz, size: 20),
              ),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          project?.title ?? uiText(context, '프로젝트'),
          style: const TextStyle(
            fontSize: 12,
            color: green,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          page.outcome,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.65,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${uiText(context, resultLabel(page.result.index))}${page.edited ? tr(context, ' · 수정됨', ' · Edited') : ''}${page.timeAdjusted ? tr(context, ' · 시간 직접 확인', ' · Time confirmed') : ''}',
          style: const TextStyle(fontSize: 11, color: muted),
        ),
        const Divider(height: 24),
        Text(
          tr(
            context,
            '시작할 때  ${page.intent}',
            'Starting intention  ${page.intent}',
          ),
          style: const TextStyle(fontSize: 12, color: muted, height: 1.7),
        ),
        if (page.nextAction.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.bookmark_outline, size: 17, color: brass),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  page.nextAction,
                  style: const TextStyle(
                    fontSize: 13,
                    color: green,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

class _Book extends StatelessWidget {
  const _Book({required this.c, required this.r, required this.projectId});
  final WorkroomController c;
  final RemoteService r;
  final String projectId;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([c, c.journals]),
    builder: (context, _) {
      final p = c.state.project(projectId);
      if (p == null) {
        return Scaffold(
          appBar: AppBar(),
          body: const Center(child: LocalizedText('프로젝트가 삭제되었습니다.')),
        );
      }
      final pages = c.state.pages(p.id);
      final history = <(int, Object)>[
        for (final page in pages) (page.savedAt ?? 0, page),
        for (final entry in c.journals.entries.where(
          (e) => e.projectId == p.id,
        ))
          (entry.createdAt, entry),
      ]..sort((a, b) => b.$1.compareTo(a.$1));
      return Scaffold(
        appBar: AppBar(
          title: const LocalizedText('프로젝트 책'),
          actions: [
            PopupMenuButton<String>(
              tooltip: uiText(context, '프로젝트 관리'),
              onSelected: (value) async {
                if (value == 'rename') {
                  final name = TextEditingController(text: p.title);
                  final title = await showDialog<String>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const LocalizedText('책 이름 바꾸기'),
                      content: TextField(controller: name, maxLength: 60),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const LocalizedText('취소'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, name.text),
                          child: const LocalizedText('저장'),
                        ),
                      ],
                    ),
                  );
                  name.dispose();
                  if (title != null && context.mounted) {
                    await perform(
                      context,
                      () => c.updateProject(p.id, title: title),
                    );
                  }
                } else if (value == 'delete') {
                  if (await confirm(
                    context,
                    '프로젝트와 페이지를 삭제할까요?',
                    tr(
                      context,
                      '이 책에 담긴 ${pages.length}개 결과와 다음 행동이 기기에서 삭제됩니다. 내보내지 않은 기록은 복구할 수 없습니다.',
                      '${pages.length} outcomes and next actions will be deleted from this device. Unexported records cannot be recovered.',
                    ),
                  )) {
                    if (context.mounted) {
                      await perform(context, () async {
                        await c.mutate((s) {
                          if (s.active?.projectId == p.id) {
                            throw StateError('진행 중인 집중을 먼저 마무리해 주세요.');
                          }
                          s.sessions.removeWhere((e) => e.projectId == p.id);
                          s.projects.removeWhere((e) => e.id == p.id);
                        });
                      });
                    }
                  }
                } else {
                  await perform(
                    context,
                    () => c.updateProject(
                      p.id,
                      status: value == 'archive'
                          ? ProjectStatus.archived
                          : ProjectStatus.active,
                    ),
                  );
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'rename',
                  child: LocalizedText('이름 바꾸기'),
                ),
                PopupMenuItem(
                  value: p.status == ProjectStatus.active
                      ? 'archive'
                      : 'reopen',
                  child: Text(
                    p.status == ProjectStatus.active
                        ? uiText(context, '보관하기')
                        : uiText(context, '다시 펼치기'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: LocalizedText('프로젝트 삭제'),
                ),
              ],
            ),
          ],
        ),
        body: PageBody(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BookCover(project: p, pages: pages.length, onTap: () {}),
                const SizedBox(width: 22),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Eyebrow(
                        p.status == ProjectStatus.completed
                            ? 'A FINISHED VOLUME'
                            : 'YOUR PROJECT',
                      ),
                      const SizedBox(height: 14),
                      Text(
                        p.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        tr(
                          context,
                          '${pages.length}페이지\n${minutesLabel(context, pages.fold<int>(0, (sum, p) => sum + p.confirmedSec))}',
                          '${pages.length} pages\n${minutesLabel(context, pages.fold<int>(0, (sum, p) => sum + p.confirmedSec))}',
                        ),
                        style: const TextStyle(color: muted, fontSize: 13),
                      ),
                      if (p.completedAt != null)
                        Text(
                          tr(
                            context,
                            '완료 ${dateLabel(context, p.completedAt!)}',
                            'Completed ${dateLabel(context, p.completedAt!)}',
                          ),
                          style: const TextStyle(fontSize: 11, color: green),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (p.definition.isNotEmpty) ...[
              const SizedBox(height: 24),
              PaperCard(
                child: Text(
                  tr(
                    context,
                    '완료의 기준\n${p.definition}',
                    'Definition of done\n${p.definition}',
                  ),
                  style: const TextStyle(fontSize: 14, height: 1.8),
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (p.status == ProjectStatus.active) ...[
              ActionButton(
                label: uiText(context, '이 프로젝트 이어가기'),
                icon: Icons.play_arrow_rounded,
                action: () async {
                  openPage(
                    context,
                    c.state.active != null
                        ? _Focus(c: c, r: r)
                        : _Prepare(c: c, r: r, projectId: p.id),
                  );
                },
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () async {
                  if (await confirm(
                        context,
                        '이 책을 완료본으로 남길까요?',
                        '결과 페이지를 그대로 보관하고 책장에 완료본을 표시합니다. 나중에 다시 펼칠 수 있어요.',
                        action: uiText(context, '완료본으로 남기기'),
                      ) &&
                      context.mounted) {
                    await perform(
                      context,
                      () => c.updateProject(
                        p.id,
                        status: ProjectStatus.completed,
                      ),
                    );
                  }
                },
                child: const LocalizedText('프로젝트 마무리'),
              ),
            ],
            const SizedBox(height: 14),
            const LocalizedText(
              '페이지를 거슬러',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 15),
            if (history.isEmpty)
              const LocalizedText(
                '첫 집중 뒤 이곳에 오늘의 페이지가 생깁니다.',
                style: TextStyle(color: muted),
              ),
            for (final item in history)
              if (item.$2 case final TradeJournalEntry entry)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _ActivityCard(
                    activity: entry.activity,
                    entry: entry,
                    onOpen: () => _openJournal(
                      context,
                      c,
                      r,
                      entry.wallet,
                      entry.activity,
                    ),
                  ),
                )
              else if (item.$2 case final WorkSession page)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _PageCard(
                    page: page,
                    project: p,
                    onEdit: () async {
                      final selection = await showModalBottomSheet<String>(
                        context: context,
                        builder: (context) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.edit_outlined),
                                title: const LocalizedText('결과·다음 행동 수정'),
                                onTap: () => Navigator.pop(context, 'edit'),
                              ),
                              ListTile(
                                leading: const Icon(Icons.delete_outline),
                                title: const LocalizedText('이 페이지 삭제'),
                                onTap: () => Navigator.pop(context, 'delete'),
                              ),
                            ],
                          ),
                        ),
                      );
                      if (!context.mounted) return;
                      if (selection == 'edit') {
                        openPage(
                          context,
                          _Outcome(c: c, r: r, sessionId: page.id, edit: true),
                        );
                      }
                      if (selection == 'delete' &&
                          await confirm(
                            context,
                            '이 페이지를 삭제할까요?',
                            '이 결과와 다음 행동이 삭제되고 시간·성취가 다시 계산됩니다.',
                          ) &&
                          context.mounted) {
                        await perform(context, () => c.removePage(page.id));
                      }
                    },
                  ),
                ),
          ],
        ),
      );
    },
  );
}

class _Achievements extends StatelessWidget {
  const _Achievements({required this.c, required this.r});
  final WorkroomController c;
  final RemoteService r;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([c, r]),
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const LocalizedText('성취 진열장')),
      body: PageBody(
        children: [
          const Eyebrow('SMALL THINGS, REMEMBERED'),
          const SizedBox(height: 12),
          LocalizedText(
            '기록이 남긴 흔적',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 10),
          const LocalizedText(
            '내가 남긴 행동의 요약입니다.\n집중의 진실성이나 업무 품질을 인증하지 않습니다.',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 24),
          for (final a in achievements(c.state, seeker: r.seeker))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PaperCard(
                onTap: () {
                  if (a.title == 'Seeker 소유자') {
                    openPage(context, _Wallet(c: c, r: r));
                  } else if (a.evidence.isNotEmpty) {
                    final page = c.state.sessions
                        .where((s) => s.id == a.evidence.first)
                        .firstOrNull;
                    final p = page?.projectId ?? a.evidence.first;
                    openPage(context, _Book(c: c, r: r, projectId: p));
                  }
                },
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: a.earned ? const Color(0xFFE9E4D3) : cream,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        a.earned
                            ? Icons.workspace_premium_outlined
                            : Icons.lock_outline,
                        color: a.earned ? brass : muted,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            uiText(context, a.title),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            a.description,
                            style: const TextStyle(fontSize: 12, color: muted),
                          ),
                          if (a.earned)
                            const LocalizedText(
                              '획득 근거 보기 →',
                              style: TextStyle(fontSize: 11, color: green),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
