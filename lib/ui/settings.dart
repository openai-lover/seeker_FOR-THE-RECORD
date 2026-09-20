part of 'app.dart';

class _Settings extends StatelessWidget {
  const _Settings({required this.c, required this.r});
  final WorkroomController c;
  final RemoteService r;
  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      const Eyebrow('MAKE YOURSELF AT HOME'),
      DropdownButtonFormField<String>(
        initialValue:
            WorkroomStrings.supportedLanguageCodes.contains(
              c.state.settings['language'],
            )
            ? c.state.settings['language'] as String
            : 'en',
        decoration: InputDecoration(labelText: tr(context, '언어', 'Language')),
        isExpanded: true,
        itemHeight: null,
        items: const [
          DropdownMenuItem(value: 'en', child: Text('English')),
          DropdownMenuItem(value: 'ko', child: Text('한국어')),
          DropdownMenuItem(value: 'ja', child: Text('日本語')),
          DropdownMenuItem(value: 'zh', child: Text('简体中文')),
          DropdownMenuItem(value: 'hi', child: Text('हिन्दी')),
          DropdownMenuItem(value: 'es', child: Text('Español')),
          DropdownMenuItem(value: 'pt', child: Text('Português')),
          DropdownMenuItem(value: 'fr', child: Text('Français')),
        ],
        onChanged: (value) => perform(context, () async {
          await c.setting('language', value);
          await r.native.syncLanguage(value ?? 'en');
        }),
      ),
      const SizedBox(height: 20),
      const SizedBox(height: 10),
      LocalizedText('작업실 설정', style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 26),
      PaperCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lock_outline, color: green, size: 21),
                SizedBox(width: 10),
                Expanded(
                  child: LocalizedText(
                    '내 기록은 이 기기에',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const LocalizedText(
              '프로젝트·의도·결과·다음 행동은 로컬에 저장됩니다. 앱 삭제 전에 기록을 내보내 주세요.',
              style: TextStyle(color: muted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ActionButton(
              label: uiText(context, 'JSON 파일로 내보내기'),
              icon: Icons.ios_share_rounded,
              outlined: true,
              action: () async {
                await r.native.export(c.exportJson());
              },
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      const LocalizedText(
        '집중 환경',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
      ),
      const SizedBox(height: 10),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const LocalizedText('마무리 알림'),
        subtitle: const LocalizedText(
          '선택한 경우에만 권한 요청 · 절전 중 늦을 수 있어요.',
          style: TextStyle(fontSize: 12),
        ),
        value: c.state.settings['notifications'] == true,
        onChanged: (v) => perform(context, () async {
          final granted = v ? await r.native.notifications() : false;
          await c.configureNotifications(granted);
          if (!granted) await c.platform.cancelAlarm();
        }),
      ),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const LocalizedText('짧은 햅틱'),
        value: c.state.settings['haptics'] != false,
        onChanged: (v) => perform(context, () => c.setting('haptics', v)),
      ),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const LocalizedText('모션 줄이기'),
        subtitle: const LocalizedText(
          '시스템의 모션 감소 설정도 따릅니다.',
          style: TextStyle(fontSize: 12),
        ),
        value: c.state.settings['reduceMotion'] == true,
        onChanged: (v) => perform(context, () => c.setting('reduceMotion', v)),
      ),
      const ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.schedule_outlined),
        title: LocalizedText('기기 시간대 사용'),
        subtitle: LocalizedText(
          '집중 경과 시간은 벽시계 변경의 영향을 받지 않습니다.',
          style: TextStyle(fontSize: 12),
        ),
      ),
      const Divider(),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(
          Icons.account_balance_wallet_outlined,
          color: green,
        ),
        title: const LocalizedText('지갑과 Seeker'),
        subtitle: Text(
          r.signedIn
              ? uiText(context, '연결됨 · 기록은 비공개')
              : tr(
                  context,
                  '거래를 돌아볼 때만 연결',
                  'Connect when you want to reflect on a trade',
                ),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => openPage(context, _Wallet(c: c, r: r)),
      ),
      if (r.cloudAvailable)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.filter_frames_outlined, color: green),
          title: const LocalizedText('공동 작업실 전시 팩'),
          subtitle: const LocalizedText(
            '호스트 한 명의 구매, 두 사람의 공간',
            style: TextStyle(fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => openPage(context, _Pack(c: c, r: r)),
        ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.workspace_premium_outlined, color: green),
        title: const LocalizedText('성취 진열장'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => openPage(context, _Achievements(c: c, r: r)),
      ),
      const Divider(),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.policy_outlined),
        title: const LocalizedText('개인정보와 데이터 안내'),
        onTap: () => showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const LocalizedText('개인정보와 데이터'),
            content: SingleChildScrollView(
              child: r.directMode
                  ? Text(
                      tr(
                        context,
                        '개인 작업 기록과 매매일지는 이 기기에만 저장됩니다. 앱 삭제 전에 JSON 파일로 내보내 주세요. 자동 백업과 가져오기는 제공하지 않습니다.\n\n지갑을 연결하면 공개 지갑 주소와 거래 ID를 Solana 공개 RPC로 직접 전송하여 거래를 조회합니다. 메모와 프로젝트명은 전송하지 않습니다. 연결은 읽기 전용이며 메시지 서명, 거래 서명, 송금을 요청하지 않습니다. 연결 해제 후에도 저장한 기록은 남습니다.\n\n공개 RPC는 호출 제한과 장애가 있을 수 있습니다. 공동 작업실과 구매는 이 버전에서 제공하지 않습니다.\n\n알림은 선택입니다. 광고·분석 SDK는 포함하지 않습니다.',
                        'Your work notes and trade journal stay on this device. Export a JSON file before uninstalling. Automatic backup and import are not provided.\n\nWhen you connect a wallet, your public address and transaction IDs go directly to Solana public RPC to read activity. Notes and project names are not sent. Connection is read-only: no message signing, transaction signing or transfers are requested. Saved records remain after disconnecting.\n\nPublic RPC may be rate-limited or unavailable. Shared rooms and purchases are not available in this edition.\n\nNotifications are optional. No advertising or analytics SDKs are included.',
                      ),
                    )
                  : const LocalizedText(
                      '개인 작업 기록과 매매일지는 SQLite로 이 기기에만 저장됩니다. 클라우드 백업은 제공하지 않습니다.\n\n공동 작업을 선택하면 지갑 주소, SGT 확인 정보, 방의 준비·마무리 상태와 선택한 작업 분류만 서버에 저장됩니다. 프로젝트명과 결과 원문은 전송하지 않습니다.\n\n구매는 공개 Solana 거래입니다. 거래 기록과 재사용 방지 정보는 서버 계정 삭제 후에도 보존됩니다. 연결 해제는 구매 취소나 로컬 기록 삭제가 아닙니다. 서버 계정 삭제는 앱 내 구매 복원 권한을 제거합니다.\n\n알림은 선택이며 정확 알람·연락처·위치 권한을 요구하지 않습니다. 광고·분석 SDK는 포함하지 않습니다.\n\n이 빌드는 개발 검증용입니다. 지원 주소·운영자·보관 기간 정책은 출시 전 설정해야 합니다.',
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const LocalizedText('확인'),
              ),
            ],
          ),
        ),
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.delete_outline, color: Color(0xFF965442)),
        title: const LocalizedText('이 기기의 기록 삭제'),
        subtitle: const LocalizedText(
          '지갑 구매 권한과는 별개입니다.',
          style: TextStyle(fontSize: 12),
        ),
        onTap: () async {
          if (await confirm(
                context,
                '모든 개인 기록을 삭제할까요?',
                '프로젝트·진행 중인 집중·저장한 결과·매매일지·설정이 삭제됩니다. 진행 중인 결제의 확인 정보는 보존합니다. 내보내지 않은 기록은 복구할 수 없습니다.',
              ) &&
              context.mounted) {
            await perform(context, c.deleteAll);
          }
        },
      ),
      const SizedBox(height: 24),
      const LocalizedText(
        'Workroom 0.2.0 · 개발 검증 빌드\n지갑 없는 개인 사용은 지금 가능합니다.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: muted),
      ),
    ],
  );
}

class _Wallet extends StatelessWidget {
  const _Wallet({required this.c, required this.r});
  final WorkroomController c;
  final RemoteService r;
  @override
  Widget build(BuildContext context) => r.directMode
      ? _DirectWallet(r: r)
      : ListenableBuilder(
          listenable: r,
          builder: (context, _) => Scaffold(
            appBar: AppBar(title: const LocalizedText('지갑과 Seeker')),
            body: PageBody(
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.key_outlined, size: 48, color: green),
                const SizedBox(height: 24),
                LocalizedText(
                  '함께할 때,\n나의 Seeker로.',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 16),
                const LocalizedText(
                  'Seeker 보유 확인과 구매 복원에 사용합니다.\n집중 기록은 자동으로 공개되지 않습니다.',
                  style: TextStyle(color: muted),
                ),
                const SizedBox(height: 24),
                PaperCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const LocalizedText(
                        '연결 서명은 송금이 아닙니다.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      const LocalizedText(
                        '서버가 발급한 일회용 로그인 메시지에 서명합니다. 실제 SKR 전송은 전시 팩 주문에서 따로 승인합니다.',
                        style: TextStyle(fontSize: 13, color: muted),
                      ),
                      if (r.wallet != null) ...[
                        const Divider(),
                        SelectableText(
                          r.wallet!,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          r.seeker
                              ? uiText(context, 'SGT 보유 확인됨 · 앱 발행 명패')
                              : uiText(context, 'Seeker 보유 확인 전 또는 확인 만료'),
                          style: const TextStyle(fontSize: 12, color: green),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                if (!r.onlineAvailable)
                  const PaperCard(
                    color: Color(0xFFE8ECDD),
                    child: LocalizedText(
                      '연결 서비스 설정이 필요한 빌드입니다.\nFirebase 프로젝트와 앱 도메인 설정 후 지갑 연결을 사용할 수 있습니다.\n\n개인 작업실은 지갑 없이 완성되어 있습니다.',
                      style: TextStyle(fontSize: 13, color: green),
                    ),
                  ),
                if (r.onlineAvailable) ...[
                  ActionButton(
                    label: r.signedIn
                        ? uiText(context, '지갑 다시 연결 / 계정 변경')
                        : uiText(context, '지갑 연결하고 서명'),
                    icon: Icons.account_balance_wallet_outlined,
                    action: r.connect,
                  ),
                  if (r.signedIn) ...[
                    const SizedBox(height: 10),
                    ActionButton(
                      label: uiText(context, 'Seeker 보유 다시 확인'),
                      icon: Icons.verified_user_outlined,
                      outlined: true,
                      action: r.verifySeeker,
                    ),
                    const SizedBox(height: 10),
                    ActionButton(
                      label: uiText(context, '구매 복원'),
                      icon: Icons.restore_rounded,
                      outlined: true,
                      action: () async {
                        await r.restore();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                r.owned
                                    ? uiText(context, '전시 팩 소유권을 복원했습니다.')
                                    : uiText(context, '이 지갑에 확인된 구매가 없습니다.'),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => perform(context, r.disconnect),
                      child: const LocalizedText('연결 해제'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () async {
                        if (await confirm(
                              context,
                              '서버 계정을 삭제할까요?',
                              '공동 방과 계정의 구매 복원 권한이 삭제됩니다. 공개 거래·재사용 방지 정보는 남습니다. 기기의 개인 기록은 유지됩니다.',
                              action: uiText(context, '서버 계정 삭제'),
                            ) &&
                            context.mounted) {
                          await perform(context, r.deleteAccount);
                        }
                      },
                      child: const LocalizedText(
                        '서버 계정 삭제',
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 20),
                const LocalizedText(
                  'SGT는 소유 지갑 확인에만 사용합니다.\n실제 집중·업무 품질·기기 사용을 인증하지 않습니다.',
                  style: TextStyle(color: muted, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
}

class _DirectWallet extends StatelessWidget {
  const _DirectWallet({required this.r});
  final RemoteService r;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: r,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: Text(tr(context, '지갑', 'Wallet'))),
      body: PageBody(
        children: [
          const SizedBox(height: 20),
          const Icon(
            Icons.account_balance_wallet_outlined,
            size: 48,
            color: green,
          ),
          const SizedBox(height: 24),
          Text(
            tr(context, '읽기 전용 지갑 연결', 'Read-only wallet connection'),
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 16),
          Text(
            tr(
              context,
              '계정이나 결제 없이 지갑을 연결해 거래를 돌아보세요.',
              'Connect your wallet to reflect on trades. No account or payment is required.',
            ),
            style: const TextStyle(color: muted),
          ),
          const SizedBox(height: 24),
          PaperCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(
                    context,
                    '거래나 메시지 서명을 요청하지 않습니다.',
                    'No transactions or messages to sign.',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Text(
                  tr(
                    context,
                    '공개 지갑 주소와 거래 ID를 Solana 공개 RPC로 직접 전송합니다. 메모는 이 기기에 남습니다.',
                    'Your public wallet address and transaction IDs go directly to Solana public RPC. Your notes stay here.',
                  ),
                  style: const TextStyle(color: muted),
                ),
                if (r.wallet != null) ...[
                  const Divider(),
                  SelectableText(
                    r.wallet!,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          ActionButton(
            label: r.signedIn
                ? uiText(context, '지갑 다시 연결 / 계정 변경')
                : tr(context, 'Seeker 지갑 연결', 'Connect Seeker wallet'),
            icon: Icons.account_balance_wallet_outlined,
            action: r.connect,
          ),
          if (r.signedIn) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => perform(context, r.disconnect),
              child: const LocalizedText('연결 해제'),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            tr(
              context,
              '공개 RPC가 혼잡하면 잠시 후 다시 시도해 주세요. 개인 기록은 계속 사용할 수 있습니다.',
              'If public RPC is busy, try again shortly. Your personal records remain available.',
            ),
            style: const TextStyle(color: muted, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}
