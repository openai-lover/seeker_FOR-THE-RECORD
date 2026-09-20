part of 'app.dart';

class _Home extends StatelessWidget {
  const _Home({required this.c, required this.r, required this.onBooks});
  final WorkroomController c;
  final RemoteService r;
  final VoidCallback onBooks;
  @override
  Widget build(BuildContext context) {
    final state = c.state;
    final projects = state.projects
        .where((p) => p.status != ProjectStatus.archived)
        .toList();
    final activeProjects = projects
        .where((p) => p.status == ProjectStatus.active)
        .toList();
    final recentProject = state.saved
        .where((s) => activeProjects.any((p) => p.id == s.projectId))
        .firstOrNull
        ?.projectId;
    final current =
        activeProjects.where((p) => p.id == recentProject).firstOrNull ??
        activeProjects.firstOrNull;
    final last = current == null ? null : state.pages(current.id).firstOrNull;
    final active = state.active;
    return PageBody(
      children: [
        const RecordHero(compact: true),
        const SizedBox(height: 24),
        Text(
          tr(context, '다음 한 걸음', 'Your next step'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        if (active != null) ...[
          PaperCard(
            color: const Color(0xFFE1F4EF),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow(
                  active.needsRecovery
                      ? 'RECOVER YOUR SESSION'
                      : active.status == SessionStatus.awaitingOutcome
                      ? 'ONE LAST LINE'
                      : 'YOUR QUIET TIME',
                ),
                const SizedBox(height: 12),
                Text(
                  active.intent,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  active.needsRecovery
                      ? uiText(context, '시간을 확인하고 이어가 주세요.')
                      : active.status == SessionStatus.awaitingOutcome
                      ? uiText(context, '예정 시간이 끝났어요. 어떤 진전이 있었나요?')
                      : tr(
                          context,
                          '${minutesLabel(context, (active.plannedSec * 1000 - active.elapsedAt(c.now!)) ~/ 1000)} 남음',
                          '${minutesLabel(context, (active.plannedSec * 1000 - active.elapsedAt(c.now!)) ~/ 1000)} remaining',
                        ),
                  style: const TextStyle(color: muted),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => openPage(context, _Focus(c: c, r: r)),
                    child: Text(
                      active.status == SessionStatus.awaitingOutcome
                          ? uiText(context, '결과 한 줄 남기기')
                          : uiText(context, '집중으로 돌아가기'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else if (current != null) ...[
          PaperCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 28,
                      decoration: BoxDecoration(
                        color: bookColors[current.color],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        current.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const Icon(
                      Icons.bookmark_outline_rounded,
                      color: brass,
                      size: 22,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  last?.nextAction.isNotEmpty == true
                      ? uiText(context, '지난번에 남긴 다음 행동')
                      : uiText(context, '오늘 이어갈 작은 일'),
                  style: const TextStyle(fontSize: 12, color: muted),
                ),
                const SizedBox(height: 6),
                Text(
                  last?.nextAction.isNotEmpty == true
                      ? last!.nextAction
                      : last?.outcome ??
                            uiText(context, '한 번의 집중으로 어디까지 가볼까요?'),
                  style: const TextStyle(fontSize: 17, height: 1.6),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => openPage(
                      context,
                      _Prepare(c: c, r: r, projectId: current.id),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: const LocalizedText('책갈피에서 이어가기'),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          PaperCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  tr(context, '한 가지부터 시작해요.', 'Start with one thing.'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  tr(
                    context,
                    '프로젝트를 고르고, 해볼 일을 정하고, 배운 것을 남겨요.',
                    'Pick a project. Set an intention. Save what you learned.',
                  ),
                  style: TextStyle(color: muted),
                ),
                const SizedBox(height: 20),
                ActionButton(
                  label: uiText(context, '내 프로젝트 만들기'),
                  icon: Icons.add_rounded,
                  action: () async {
                    final id = await _newProject(context, c);
                    if (id != null && context.mounted) {
                      openPage(context, _Prepare(c: c, r: r, projectId: id));
                    }
                  },
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        if (r.signedIn &&
            r.activities.any(
              (a) =>
                  a.canJournal &&
                  c.journals.find(r.wallet!, a.signature) == null,
            )) ...[
          PaperCard(
            onTap: () => openPage(
              context,
              Scaffold(
                appBar: AppBar(title: Text(tr(context, '기록', 'Journal'))),
                body: _Records(c: c, r: r, initialTrade: true),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.edit_note_rounded, color: brass),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr(
                      context,
                      '돌아볼 거래가 남아 있어요. 짧게 기록해 보세요.',
                      'A recent trade is waiting for reflection.',
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
        PaperCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE1F4EF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: green,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(context, '매매 일지', 'Trade journal'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          tr(
                            context,
                            '거래에 담긴 나의 이유를 남겨요.',
                            'Your trades show what. Add the why.',
                          ),
                          style: const TextStyle(color: muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(tr(context, '매매 일지 열기', 'Open trade journal')),
                onPressed: () => openPage(
                  context,
                  Scaffold(
                    appBar: AppBar(
                      title: Text(tr(context, '매매 일지', 'Trade journal')),
                    ),
                    body: _TradeJournal(c: c, r: r),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (r.room != null &&
            ['waiting', 'ready', 'running'].contains(r.room!['status'])) ...[
          PaperCard(
            onTap: () => openPage(context, _Shared(c: c, r: r)),
            child: Row(
              children: [
                const Icon(Icons.people_outline_rounded, color: green),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const LocalizedText(
                        '동료와의 작업실',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        r.offline
                            ? uiText(context, '연결 확인 중 · 내 기록은 계속')
                            : uiText(context, '진행 중인 초대와 두 자리 보기'),
                        style: const TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded, size: 19),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (projects.isNotEmpty)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              const LocalizedText(
                '나의 프로젝트',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              TextButton.icon(
                onPressed: () async {
                  final id = await _newProject(context, c);
                  if (id != null && context.mounted) {
                    openPage(context, _Book(c: c, r: r, projectId: id));
                  }
                },
                icon: const Icon(Icons.add, size: 18),
                label: const LocalizedText('새 책'),
              ),
            ],
          ),
        if (projects.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: projects
                  .map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _BookCover(
                        project: p,
                        pages: state.pages(p.id).length,
                        onTap: () => openPage(
                          context,
                          _Book(c: c, r: r, projectId: p.id),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            tr(context, '기록은 이 기기에 저장됩니다.', 'Your notes stay on this device.'),
            style: TextStyle(fontSize: 12, color: muted.withValues(alpha: .8)),
          ),
        ),
      ],
    );
  }
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
