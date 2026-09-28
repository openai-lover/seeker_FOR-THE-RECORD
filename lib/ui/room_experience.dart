part of 'app.dart';

/// The introduction is versioned independently from the app and never interrupts
/// an active session. Completing or skipping it persists through the repository.
class _RoomEntry extends StatelessWidget {
  const _RoomEntry({required this.c, required this.r});
  final WorkroomController c;
  final RemoteService r;
  @override
  Widget build(BuildContext context) {
    if (c.state.active == null && c.state.settings['roomWelcome'] != 1) {
      return _RoomWelcome(onDone: () => c.setting('roomWelcome', 1));
    }
    return _Shell(c: c, r: r);
  }
}

class _RoomWelcome extends StatefulWidget {
  const _RoomWelcome({required this.onDone});
  final Future<void> Function() onDone;
  @override
  State<_RoomWelcome> createState() => _RoomWelcomeState();
}

class _RoomWelcomeState extends State<_RoomWelcome> {
  final pages = PageController();
  int page = 0;
  bool busy = false;
  @override
  void dispose() {
    pages.dispose();
    super.dispose();
  }

  Future<void> finish() async {
    if (busy) return;
    setState(() => busy = true);
    await perform(context, widget.onDone);
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final titles = [
      tr(context, '생각이 머무는,\n나만의 방.', 'A little room.\nAll your own.'),
      tr(context, '지나간 선택에,\n이유를 남겨요.', 'Every choice\nhas a story.'),
      tr(context, '잠시 멈추면,\n다음이 보여요.', 'A quiet pause.\nA clearer next step.'),
    ];
    final descriptions = [
      tr(
        context,
        '집중하고, 기록하고, 다시 돌아오는 곳.\n당신의 작은 작업실에 오신 걸 환영해요.',
        'A place to focus, leave a note, and come back.\nWelcome to your personal workroom.',
      ),
      tr(
        context,
        '집중한 일도, 지갑에서 한 선택도.\n무엇을 했는지보다 왜 했는지를 기록해요.',
        'From focused work to wallet decisions.\nKeep the reason behind what you did.',
      ),
      tr(
        context,
        '기록을 다시 펼쳐 나만의 기준을 만들어요.\n원하면 기기 안의 AI가 질문을 골라줘요.',
        'Revisit a note. Find a lesson to carry forward.\nOptional on-device AI helps choose a question.',
      ),
    ];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 16, 0),
              child: Row(
                children: [
                  const Expanded(child: _RoomWordmark()),
                  TextButton(
                    onPressed: busy ? null : finish,
                    child: Text(tr(context, '건너뛰기', 'Skip')),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: pages,
                itemCount: 3,
                onPageChanged: (value) => setState(() => page = value),
                itemBuilder: (context, index) => LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 28, 28, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '0${index + 1} / 03',
                              style: const TextStyle(
                                color: brass,
                                fontSize: 11,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(titles[index], style: _roomTitle(context, 39)),
                            SizedBox(
                              height: (constraints.maxHeight * .49).clamp(
                                200.0,
                                360.0,
                              ),
                              width: double.infinity,
                              child: _RoomObject(
                                asset: ['study', 'journal', 'lamp'][index],
                                moving: page == index,
                              ),
                            ),
                            Text(
                              descriptions[index],
                              style: const TextStyle(
                                color: muted,
                                fontSize: 14,
                                height: 1.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
              child: Row(
                children: [
                  Semantics(
                    label: '${page + 1} / 3',
                    child: Row(
                      children: List.generate(
                        3,
                        (index) => AnimatedContainer(
                          duration: Duration(milliseconds: reduced ? 0 : 250),
                          width: page == index ? 26 : 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 7),
                          decoration: BoxDecoration(
                            color: page == index ? green : line,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: busy
                        ? null
                        : () {
                            if (page == 2) {
                              finish();
                            } else if (reduced) {
                              pages.jumpToPage(page + 1);
                            } else {
                              pages.nextPage(
                                duration: const Duration(milliseconds: 480),
                                curve: Curves.easeInOutCubic,
                              );
                            }
                          },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          page == 2
                              ? tr(context, '내 방으로', 'Enter my room')
                              : tr(context, '다음', 'Next'),
                        ),
                        const SizedBox(width: 14),
                        Icon(
                          page == 2
                              ? Icons.door_front_door_outlined
                              : Icons.arrow_forward_rounded,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

TextStyle _roomTitle(BuildContext context, double size) => TextStyle(
  fontFamily: Localizations.localeOf(context).languageCode == 'en'
      ? 'Lora'
      : 'NotoSansKR',
  fontSize: size,
  fontWeight: FontWeight.w500,
  height: 1.16,
  letterSpacing: -1.3,
  color: ink,
);

class _RoomWordmark extends StatelessWidget {
  const _RoomWordmark();
  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      RecordMark(size: 25),
      SizedBox(width: 9),
      Flexible(
        child: Text(
          'FOR THE RECORD',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
      ),
    ],
  );
}

/// Entrance, a very small breathing movement, and a warm pool of light are
/// composed at runtime, so the room stays crisp without a video download.
class _RoomObject extends StatefulWidget {
  const _RoomObject({required this.asset, this.moving = true, this.child});
  final String asset;
  final bool moving;
  final Widget? child;
  @override
  State<_RoomObject> createState() => _RoomObjectState();
}

class _RoomObjectState extends State<_RoomObject>
    with TickerProviderStateMixin {
  late final entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final breathe = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  );
  bool reduced = false;
  void updateMotion() {
    if (reduced || !widget.moving) {
      breathe.stop();
      entrance.value = 1;
    } else {
      entrance.forward();
      if (!breathe.isAnimating) breathe.repeat(reverse: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    reduced = MediaQuery.disableAnimationsOf(context);
    updateMotion();
  }

  @override
  void didUpdateWidget(_RoomObject oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.moving != widget.moving) updateMotion();
  }

  @override
  void dispose() {
    entrance.dispose();
    breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([entrance, breathe]),
    child: Image.asset(
      'assets/room/${widget.asset}.png',
      fit: BoxFit.contain,
      excludeFromSemantics: true,
      cacheWidth: 1200,
    ),
    builder: (context, image) {
      final reveal = Curves.easeOutCubic.transform(entrance.value);
      final drift = reduced ? 0.0 : math.sin(breathe.value * math.pi) * 3;
      return Stack(
        alignment: Alignment.center,
        children: [
          FractionallySizedBox(
            widthFactor: .83,
            heightFactor: .83,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(
                      0xFFE9D5A9,
                    ).withValues(alpha: .34 + drift * .025),
                    cream.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Opacity(
            opacity: reveal,
            child: Transform.translate(
              offset: Offset(0, 24 * (1 - reveal) - drift),
              child: Transform.scale(scale: .94 + .06 * reveal, child: image),
            ),
          ),
          if (widget.child != null) widget.child!,
        ],
      );
    },
  );
}

class _RoomMotion extends StatelessWidget {
  const _RoomMotion(this.name, {this.size = 28});
  final String name;
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Lottie.asset(
      'assets/motion/$name.json',
      width: size,
      height: size,
      animate: !MediaQuery.disableAnimationsOf(context),
      repeat: false,
      delegates: LottieDelegates(
        values: [
          ValueDelegate.color(const ['**'], value: green),
        ],
      ),
      errorBuilder: (context, error, stack) =>
          Icon(Icons.bookmark_outline, size: size, color: green),
    ),
  );
}

class _RoomSpot extends StatelessWidget {
  const _RoomSpot({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => FilledButton.tonalIcon(
    onPressed: onTap,
    icon: Icon(icon, size: 15),
    label: Text(label, style: const TextStyle(fontSize: 11)),
    style: FilledButton.styleFrom(
      backgroundColor: paper.withValues(alpha: .96),
      foregroundColor: ink,
      elevation: 2,
      shadowColor: ink.withValues(alpha: .12),
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      shape: const StadiumBorder(),
    ),
  );
}
