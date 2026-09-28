part of 'app.dart';

class _Home extends StatelessWidget {
  const _Home({required this.c, required this.r, required this.onBooks});
  final WorkroomController c;
  final RemoteService r;
  final VoidCallback onBooks;

  @override
  Widget build(BuildContext context) {
    final projects = c.state.projects
        .where((p) => p.status == ProjectStatus.active)
        .toList();
    final active = c.state.active;
    final recentId = c.state.saved
        .where((s) => projects.any((p) => p.id == s.projectId))
        .firstOrNull
        ?.projectId;
    final current =
        projects.where((p) => p.id == recentId).firstOrNull ??
        projects.firstOrNull;
    final last = current == null ? null : c.state.pages(current.id).firstOrNull;
    final due = c.journals.entries
        .where((e) => e.isDue(c.wallClock().millisecondsSinceEpoch))
        .length;
    void journal() => openPage(
      context,
      Scaffold(
        appBar: AppBar(title: Text(tr(context, '선택의 기록', 'My decisions'))),
        body: _TradeJournal(c: c, r: r),
      ),
    );
    Future<void> focus() async {
      if (active != null) {
        openPage(context, _Focus(c: c, r: r));
        return;
      }
      final id = current?.id ?? await _newProject(context, c);
      if (id != null && context.mounted) {
        openPage(context, _Prepare(c: c, r: r, projectId: id));
      }
    }

    return PageBody(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      children: [
        Row(
          children: [
            const Expanded(child: _RoomWordmark()),
            IconButton(
              tooltip: tr(context, '작업실 안내', 'Room guide'),
              onPressed: () => openPage(
                context,
                _RoomWelcome(
                  onDone: () async {
                    Navigator.pop(context);
                  },
                ),
              ),
              icon: const Icon(
                Icons.help_outline_rounded,
                size: 20,
                color: muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                tr(context, '오늘도,\n나의 작은 방.', 'Your quiet\ncorner.'),
                style: _roomTitle(context, 37),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  tr(context, '기록을 위한 공간', 'SPACE TO REFLECT'),
                  style: const TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.1,
                    color: muted,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 1.06,
          child: _RoomObject(
            asset: 'study',
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 102,
                  child: _RoomSpot(
                    label: tr(context, '집중', 'Focus'),
                    icon: Icons.light_outlined,
                    onTap: focus,
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 70,
                  child: _RoomSpot(
                    label: tr(context, '책장', 'Shelf'),
                    icon: Icons.auto_stories_outlined,
                    onTap: onBooks,
                  ),
                ),
                Positioned(
                  left: 74,
                  bottom: 22,
                  child: _RoomSpot(
                    label: tr(context, '기록', 'Journal'),
                    icon: Icons.edit_outlined,
                    onTap: journal,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          tr(
            context,
            '잠깐의 기록이, 다음 선택의 기준이 되도록.',
            'A small note today. A little clarity tomorrow.',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(color: muted, fontSize: 12, height: 1.7),
        ),
        const SizedBox(height: 22),
        FilledButton(
          key: const ValueKey('decision-replay-open'),
          onPressed: journal,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(58),
            shape: const StadiumBorder(),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.edit_note_rounded, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tr(context, '선택의 이유 남기기', 'Leave a reason'),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 18),
              const Icon(Icons.arrow_forward_rounded, size: 18),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _RoomAction(
                motion: 'activity',
                title: active != null
                    ? tr(context, '집중 이어가기', 'Resume focus')
                    : tr(context, '집중 시작', 'Make some space'),
                subtitle: tr(context, '램프를 켜고 한 가지에', 'One thing at a time'),
                onTap: focus,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RoomAction(
                motion: 'bookmark',
                title: tr(context, '나의 책장', 'My bookshelf'),
                subtitle: tr(context, '차곡차곡 쌓인 기록', 'Notes to come back to'),
                onTap: onBooks,
              ),
            ),
          ],
        ),
        if (active != null || last != null) ...[
          const SizedBox(height: 24),
          PaperCard(
            onTap: focus,
            child: Row(
              children: [
                const _RoomMotion('checkmark'),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        active != null
                            ? tr(
                                context,
                                '켜둔 램프가 기다려요',
                                'Your lamp is still on',
                              )
                            : tr(context, '지난번의 책갈피', 'Where you left off'),
                        style: const TextStyle(color: muted, fontSize: 11),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        active?.intent ??
                            (last!.nextAction.isNotEmpty
                                ? last.nextAction
                                : last.outcome),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ],
        if (c.journals.entries.isNotEmpty) ...[
          const SizedBox(height: 24),
          _RoomAction(
            motion: 'bookmark',
            title: due > 0
                ? tr(context, '다시 펼쳐볼 기록 $due개', '$due notes to revisit')
                : tr(context, '선택을 돌아보는 시간', 'Time to reflect'),
            subtitle: tr(
              context,
              '당시의 이유와 내가 남긴 기준',
              'Your reasons and saved lessons',
            ),
            onTap: () => openPage(
              context,
              Scaffold(
                appBar: AppBar(title: Text(tr(context, '돌아보기', 'Reflect'))),
                body: AnimatedBuilder(
                  animation: c.journals,
                  builder: (context, _) => PageBody(
                    children: [_DecisionReplayCard(c: c, r: r)],
                  ),
                ),
              ),
            ),
          ),
        ],
        if (r.room != null &&
            ['waiting', 'ready', 'running'].contains(r.room!['status'])) ...[
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const LocalizedText('동료와의 작업실'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => openPage(context, _Shared(c: c, r: r)),
          ),
        ],
        if (c.state.projects.any(
          (p) => p.status != ProjectStatus.archived,
        )) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  tr(context, '나의 프로젝트', 'My projects'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Flexible(
                child: TextButton.icon(
                  onPressed: () async {
                    final id = await _newProject(context, c);
                    if (id != null && context.mounted) {
                      openPage(context, _Book(c: c, r: r, projectId: id));
                    }
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const LocalizedText('새 책'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final p in c.state.projects.where(
                  (p) => p.status != ProjectStatus.archived,
                ))
                  Padding(
                    padding: const EdgeInsets.only(right: 12, bottom: 10),
                    child: _BookCover(
                      project: p,
                      pages: c.state.pages(p.id).length,
                      onTap: () =>
                          openPage(context, _Book(c: c, r: r, projectId: p.id)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _RoomAction extends StatelessWidget {
  const _RoomAction({
    required this.motion,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final String motion, title, subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: paper,
    borderRadius: BorderRadius.circular(20),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _RoomMotion(motion, size: 28),
                const Spacer(),
                const Icon(Icons.north_east_rounded, size: 15, color: muted),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: muted, height: 1.5),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BookCover extends StatelessWidget {
  const _BookCover({
    required this.project,
    required this.pages,
    required this.onTap,
  });
  final Project project;
  final int pages;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${project.title}, ${tr(context, '$pages페이지', '$pages pages')}',
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        width: 136,
        constraints: const BoxConstraints(minHeight: 166),
        padding: const EdgeInsets.fromLTRB(20, 18, 13, 15),
        decoration: BoxDecoration(
          color: bookColors[project.color],
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(9),
            bottomRight: Radius.circular(9),
            topLeft: Radius.circular(3),
            bottomLeft: Radius.circular(3),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18000000),
              offset: Offset(3, 5),
              blurRadius: 8,
            ),
          ],
          border: Border(
            left: BorderSide(
              color: Colors.white.withValues(alpha: .2),
              width: 7,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              uiText(
                context,
                project.completedAt != null ? 'COMPLETED' : 'IN PROGRESS',
              ),
              style: const TextStyle(
                fontSize: 8,
                letterSpacing: 1.2,
                color: Color(0xFFE7E1CF),
              ),
            ),
            const SizedBox(height: 17),
            Text(
              project.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: paper,
                fontWeight: FontWeight.w500,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Container(height: .8, color: Colors.white.withValues(alpha: .35)),
            const SizedBox(height: 10),
            Text(
              tr(context, '$pages페이지', '$pages pages'),
              style: const TextStyle(
                fontFamily: 'Lora',
                fontSize: 12,
                color: Color(0xFFF5EBD5),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<String?> _newProject(BuildContext context, WorkroomController c) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: cream,
      builder: (context) => _ProjectForm(c: c),
    );

class _ProjectForm extends StatefulWidget {
  const _ProjectForm({required this.c});
  final WorkroomController c;
  @override
  State<_ProjectForm> createState() => _ProjectFormState();
}

class _ProjectFormState extends State<_ProjectForm> {
  final title = TextEditingController(), definition = TextEditingController();
  int color = 0;
  @override
  void dispose() {
    title.dispose();
    definition.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: LocalizedText(
                  '새 프로젝트 책',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              IconButton(
                tooltip: uiText(context, '닫기'),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: title,
            maxLength: 60,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: uiText(context, '프로젝트 이름'),
              hintText: uiText(context, '예: 나의 첫 Android 앱'),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: definition,
            maxLength: 180,
            decoration: InputDecoration(
              labelText: uiText(context, '언제 이 책을 덮을까요? (선택)'),
              hintText: uiText(context, '예: 친구에게 첫 버전을 보여주면'),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            children: List.generate(
              6,
              (i) => Semantics(
                label: tr(context, '책 색상 ${i + 1}', 'Book color ${i + 1}'),
                selected: color == i,
                child: IconButton(
                  onPressed: () => setState(() => color = i),
                  style: IconButton.styleFrom(
                    backgroundColor: bookColors[i],
                    foregroundColor: paper,
                  ),
                  icon: Icon(color == i ? Icons.check : Icons.circle, size: 22),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          ActionButton(
            label: uiText(context, '책 만들기'),
            icon: Icons.auto_stories_rounded,
            action: () async {
              final id = await widget.c.addProject(
                title.text,
                definition.text,
                color,
              );
              if (context.mounted) Navigator.pop(context, id);
            },
          ),
          const SizedBox(height: 8),
          const LocalizedText(
            '프로젝트 이름과 기록은 상대에게 공유되지 않습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: muted),
          ),
        ],
      ),
    ),
  );
}
