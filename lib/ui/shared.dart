part of 'app.dart';

class _Shared extends StatefulWidget {
  const _Shared({required this.c, required this.r});
  final WorkroomController c;
  final RemoteService r;
  @override
  State<_Shared> createState() => _SharedState();
}

class _SharedState extends State<_Shared> {
  final code = TextEditingController();
  String category = 'build';
  bool joining = false, starting = false;
  Timer? countdown;
  static const categories = {
    'build': '개발',
    'design': '디자인',
    'write': '글쓰기',
    'learn': '학습',
    'other': '기타',
  };
  @override
  void initState() {
    super.initState();
    widget.r.addListener(changed);
    changed();
  }

  void changed() {
    if (!mounted) return;
    if (widget.r.room?['status'] == 'running' &&
        widget.c.state.active == null &&
        !starting) {
      final roomId = widget.r.room!['roomId'];
      if (widget.c.state.sessions.any((s) => s.roomId == roomId)) return;
      countdown?.cancel();
      countdown = Timer(
        const Duration(milliseconds: 200),
        () => unawaited(beginLocal()),
      );
    }
  }

  Future<void> beginLocal() async {
    if (starting || !mounted) return;
    final draft = widget.c.state.settings['sharedDraft'] as Map?;
    if (draft == null) return;
    starting = true;
    try {
      final elapsed = await widget.r.roomElapsed();
      if (elapsed < 0) {
        countdown = Timer(Duration(milliseconds: -elapsed), () {
          starting = false;
          unawaited(beginLocal());
        });
        return;
      }
      if (elapsed > 1500000) return;
      await widget.c.start(
        draft['projectId'],
        draft['intent'],
        25,
        resumedFrom: draft['resumedFrom'],
        roomId: widget.r.room!['roomId'],
        elapsedMs: elapsed,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (_) => _Focus(c: widget.c, r: widget.r),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: LocalizedText(
              e
                  .toString()
                  .replaceFirst('Bad state: ', '')
                  .replaceFirst('Invalid argument(s): ', ''),
            ),
          ),
        );
      }
    } finally {
      starting = false;
    }
  }

  @override
  void dispose() {
    countdown?.cancel();
    widget.r.removeListener(changed);
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([widget.r, widget.c]),
    builder: (context, _) {
      final r = widget.r, room = r.room;
      final seats = (room?['seats'] as List?) ?? [];
      final draft = widget.c.state.settings['sharedDraft'] as Map?;
      final mine = seats.where((s) => s['uid'] == r.uid).firstOrNull;
      return Scaffold(
        appBar: AppBar(title: const LocalizedText('동료와 함께')),
        body: PageBody(
          children: [
            const Eyebrow('TWO BUILDERS. ONE QUIET START.'),
            const SizedBox(height: 12),
            LocalizedText(
              '시작은 함께,\n기록은 각자의 책에.',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 14),
            const LocalizedText(
              '초대한 두 사람만 · 25분 · 기본 공동 작업은 무료',
              style: TextStyle(color: muted, fontSize: 12),
            ),
            const SizedBox(height: 24),
            RoomScene(
              projects: widget.c.state.projects,
              pages: widget.c.state.saved.length,
              shared: true,
              pack: room?['pack'] == true,
            ),
            const SizedBox(height: 22),
            if (!r.cloudAvailable) ...[
              Text(
                tr(
                  context,
                  '공동 작업실은 이 버전에서 제공하지 않습니다.',
                  'Shared rooms are not available in this edition.',
                ),
              ),
            ] else if (!r.signedIn) ...[
              const PaperCard(
                child: LocalizedText(
                  '각 자리에는 서로 다른 SGT 보유 확인이 필요해요. 업무 원문은 상대에게 공유하지 않습니다.',
                  style: TextStyle(color: muted),
                ),
              ),
              const SizedBox(height: 16),
              ActionButton(
                label: '지갑과 Seeker 연결',
                icon: Icons.account_balance_wallet_outlined,
                action: () async {
                  openPage(context, _Wallet(c: widget.c, r: r));
                },
              ),
            ] else if (room == null ||
                [
                  'finished',
                  'cancelled',
                  'expired',
                ].contains(room['status'])) ...[
              const LocalizedText(
                '상대에게 보여줄 작업 분류',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: categories.entries
                    .map(
                      (e) => ChoiceChip(
                        label: LocalizedText(e.value),
                        selected: category == e.key,
                        onSelected: (_) => setState(() => category = e.key),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              ActionButton(
                label: '초대 코드 만들기',
                icon: Icons.add_rounded,
                action: () async {
                  if (draft == null) {
                    throw StateError('먼저 프로젝트에서 함께할 작업을 준비해 주세요.');
                  }
                  await r.createRoom(category);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: code,
                maxLength: 10,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: uiText(context, '받은 초대 코드'),
                  hintText: uiText(context, '10자리 코드'),
                ),
              ),
              ActionButton(
                label: '코드로 입장',
                icon: Icons.login_rounded,
                outlined: true,
                action: () async {
                  if (draft == null) {
                    throw StateError('먼저 프로젝트에서 함께할 작업을 준비해 주세요.');
                  }
                  await r.join(code.text, category);
                },
              ),
            ] else ...[
              if (r.offline)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: LocalizedText(
                    '연결 확인 중 · 이미 시작한 개인 타이머는 계속됩니다.',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ),
              PaperCard(
                child: Column(
                  children: [
                    const Eyebrow('YOUR INVITATION'),
                    const SizedBox(height: 10),
                    SelectableText(
                      room['code'] ?? '',
                      style: const TextStyle(
                        fontFamily: 'Lora',
                        fontSize: 27,
                        letterSpacing: 3,
                        color: green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LocalizedText(
                      '입장 만료 ${DateTime.fromMillisecondsSinceEpoch(room['expiresAt']).toLocal().toString().substring(11, 16)} · 두 자리 한정',
                      style: const TextStyle(fontSize: 12, color: muted),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: room['code'] ?? ''),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: LocalizedText('초대 코드를 복사했습니다.'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const LocalizedText('초대 코드 복사'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              for (int i = 0; i < 2; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: PaperCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          i < seats.length ? Icons.chair : Icons.chair_outlined,
                          color: i < seats.length ? green : muted,
                          size: 30,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LocalizedText(
                                i < seats.length
                                    ? seats[i]['uid'] == r.uid
                                          ? '나의 자리'
                                          : '동료의 자리'
                                    : '동료를 기다리는 자리',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (i < seats.length)
                                LocalizedText(
                                  categories[seats[i]['category']] ?? '기타',
                                  style: const TextStyle(
                                    color: muted,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        LocalizedText(
                          i >= seats.length
                              ? '초대 중'
                              : seats[i]['left'] == true
                              ? '나감'
                              : seats[i]['finished'] == true
                              ? '마무리'
                              : seats[i]['ready'] == true
                              ? '준비됨'
                              : '준비 중',
                          style: const TextStyle(color: green, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              if (room['status'] == 'running')
                ActionButton(
                  label: widget.c.state.active == null
                      ? '내 타이머 연결'
                      : '집중으로 돌아가기',
                  icon: Icons.play_arrow_rounded,
                  action: () async {
                    if (widget.c.state.active != null) {
                      openPage(context, _Focus(c: widget.c, r: r));
                    } else {
                      await beginLocal();
                    }
                  },
                )
              else ...[
                ActionButton(
                  label: mine?['ready'] == true ? '준비 취소' : '준비됐어요',
                  icon: Icons.check_rounded,
                  outlined: true,
                  action: () async {
                    if (draft == null) {
                      throw StateError('함께할 개인 작업을 먼저 준비해 주세요.');
                    }
                    await r.roomAction('ready');
                  },
                ),
                const SizedBox(height: 10),
                if (room['host'] == r.uid)
                  ActionButton(
                    label: '함께 25분 시작',
                    icon: Icons.play_arrow_rounded,
                    action: room['status'] == 'ready'
                        ? () async {
                            await r.roomAction('start');
                          }
                        : null,
                  )
                else
                  const Center(
                    child: LocalizedText(
                      '둘 다 준비되면 호스트가 시작합니다.',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ),
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => perform(context, () async {
                  await r.roomAction('leave');
                }),
                child: const LocalizedText('공동 방 나가기'),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => openPage(context, _Pack(c: widget.c, r: r)),
                child: LocalizedText(
                  room['pack'] == true ? '함께 쓰는 전시 팩 적용됨' : '공동 작업실 전시 팩 보기',
                ),
              ),
            ],
            const SizedBox(height: 20),
            const LocalizedText(
              '상대의 완료를 기다리지 않아도 내 결과를 저장할 수 있어요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ],
        ),
      );
    },
  );
}

class _Pack extends StatefulWidget {
  const _Pack({required this.c, required this.r});
  final WorkroomController c;
  final RemoteService r;
  @override
  State<_Pack> createState() => _PackState();
}

class _PackState extends State<_Pack> {
  bool preview = true;
  Timer? confirmationTimer;
  bool checking = false;
  @override
  void initState() {
    super.initState();
    confirmationTimer = Timer.periodic(const Duration(seconds: 8), (_) async {
      if (!mounted ||
          checking ||
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      final order = widget.c.state.pendingOrder;
      if (!widget.r.cloudAvailable ||
          !widget.r.signedIn ||
          order == null ||
          (order['signature'] == null && order['signedTransaction'] == null)) {
        return;
      }
      checking = true;
      try {
        await widget.r.checkOrder();
      } catch (_) {
        /* Existing order and manual retry remain visible. */
      } finally {
        checking = false;
      }
    });
  }

  @override
  void dispose() {
    confirmationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([widget.c, widget.r]),
    builder: (context, _) {
      final r = widget.r, order = widget.c.state.pendingOrder;
      return Scaffold(
        appBar: AppBar(title: const LocalizedText('공동 작업실 전시 팩')),
        body: PageBody(
          children: [
            const Eyebrow('THE SHARED EDITION'),
            const SizedBox(height: 12),
            LocalizedText(
              '다시 만나고 싶은\n두 사람의 작업실.',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 20),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: LocalizedText('기본 작업실')),
                ButtonSegment(value: true, label: LocalizedText('전시 팩 미리보기')),
              ],
              selected: {preview},
              onSelectionChanged: (v) => setState(() => preview = v.first),
            ),
            const SizedBox(height: 16),
            RoomScene(
              projects: widget.c.state.projects,
              pages: widget.c.state.saved.length,
              shared: true,
              pack: preview,
            ),
            const SizedBox(height: 10),
            LocalizedText(
              widget.c.state.saved.isEmpty
                  ? '미리보기 · 아직 내 기록이 없는 빈 작업실입니다.'
                  : '미리보기 · 내 ${widget.c.state.saved.length}개 기록으로 보는 공간입니다.',
              style: const TextStyle(color: muted, fontSize: 11),
            ),
            const SizedBox(height: 24),
            const LocalizedText(
              '한 사람의 구매로, 함께 쓰는 공간',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            const LocalizedText(
              '따뜻한 목재 책상과 두 개의 작업등, 마무리 전시를 위한 작은 액자. 호스트가 열면 초대한 동료도 그 방에서 같은 표현을 경험합니다.',
              style: TextStyle(color: muted),
            ),
            const SizedBox(height: 16),
            const PaperCard(
              child: LocalizedText(
                '기본 개인·공동 작업과 기록은 무료입니다.\n호스트는 같은 지갑으로 재사용·복원할 수 있습니다.\n게스트에게 영구 소유권이 생기지는 않습니다.',
                style: TextStyle(fontSize: 12, color: muted, height: 1.9),
              ),
            ),
            const SizedBox(height: 22),
            if (!r.cloudAvailable) ...[
              Text(
                tr(
                  context,
                  '구매는 이 버전에서 제공하지 않습니다.',
                  'Purchases are not available in this edition.',
                ),
              ),
            ] else if (r.owned) ...[
              const QuietTag('보유한 전시 팩', icon: Icons.check_circle_outline),
              const SizedBox(height: 12),
              const LocalizedText(
                '내가 호스트인 방에 자동으로 적용됩니다. 동료에게 추가 결제를 요구하지 않습니다.',
                style: TextStyle(color: green),
              ),
            ] else if (order != null) ...[
              PaperCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LocalizedText(
                      '고정된 주문',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    LocalizedText(
                      '${_skrAmount(order)} SKR',
                      style: const TextStyle(
                        fontFamily: 'Lora',
                        fontSize: 30,
                        color: green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const LocalizedText(
                      'SOL 네트워크 수수료 별도 · 실제 자산 전송',
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                    const SizedBox(height: 12),
                    const LocalizedText(
                      '수취 지갑',
                      style: TextStyle(fontSize: 11, color: muted),
                    ),
                    SelectableText(
                      order['recipient'],
                      style: const TextStyle(fontSize: 11),
                    ),
                    const SizedBox(height: 6),
                    LocalizedText(
                      '주문 만료 ${DateTime.fromMillisecondsSinceEpoch(order['expiresAt']).toLocal().toString().substring(11, 19)}',
                      style: const TextStyle(fontSize: 11, color: muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              if (order['signature'] != null ||
                  order['signedTransaction'] != null) ...[
                const LocalizedText(
                  '서명된 주문이 있습니다. 기존 거래를 먼저 확인합니다. 확인 전에는 소유권을 부여하지 않습니다.',
                  style: TextStyle(color: green, fontSize: 13),
                ),
                const SizedBox(height: 10),
                ActionButton(
                  label: '기존 거래 확인',
                  icon: Icons.refresh_rounded,
                  action: () async {
                    await r.checkOrder();
                    if (context.mounted && !r.owned) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: LocalizedText(
                            '아직 finalized 확인 중입니다. 다시 결제하지 마세요.',
                          ),
                        ),
                      );
                    }
                  },
                ),
                if (order['signedTransaction'] != null)
                  TextButton(
                    onPressed: () => perform(context, r.submitOrder),
                    child: const LocalizedText('보관된 동일 거래 다시 전송'),
                  ),
              ] else ...[
                ActionButton(
                  label: '지갑에서 SKR 전송 승인',
                  icon: Icons.account_balance_wallet_outlined,
                  action:
                      DateTime.now().millisecondsSinceEpoch < order['expiresAt']
                      ? r.signOrder
                      : null,
                ),
                const SizedBox(height: 8),
                ActionButton(
                  label: '주문 상태 확인',
                  outlined: true,
                  icon: Icons.refresh_rounded,
                  action: r.checkOrder,
                ),
              ],
            ] else if (!r.signedIn)
              ActionButton(
                label: '지갑 연결 / 구매 복원',
                icon: Icons.account_balance_wallet_outlined,
                action: () async {
                  openPage(context, _Wallet(c: widget.c, r: r));
                },
              )
            else if (!r.paymentsEnabled)
              const PaperCard(
                color: Color(0xFFE8ECDD),
                child: LocalizedText(
                  '현재는 미리보기입니다.\n판매 가격과 수취 지갑을 설정하기 전까지 결제는 열리지 않습니다.',
                  style: TextStyle(color: green),
                ),
              )
            else
              ActionButton(
                label: 'SKR 수량과 주문 확인',
                icon: Icons.receipt_long_outlined,
                action: () async {
                  await r.quote();
                },
              ),
            const SizedBox(height: 14),
            if (r.signedIn && r.cloudAvailable)
              TextButton(
                onPressed: () => perform(
                  context,
                  r.restore,
                  success: '이 지갑의 구매 상태를 다시 확인했습니다.',
                ),
                child: const LocalizedText('같은 지갑의 구매 복원'),
              ),
            const SizedBox(height: 20),
            const LocalizedText(
              '결제는 Solana mainnet에서 검증합니다.\n체인 확인 전에 구매 성공으로 표시하지 않습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 11),
            ),
          ],
        ),
      );
    },
  );
}

String _skrAmount(Map<String, dynamic> order) {
  final amount = order['amountAtomic'] as String;
  final decimals = order['decimals'] as int;
  if (decimals == 0) return amount;
  final padded = amount.padLeft(decimals + 1, '0');
  return '${padded.substring(0, padded.length - decimals)}.${padded.substring(padded.length - decimals)}'
      .replaceFirst(RegExp(r'\.?0+$'), '');
}
