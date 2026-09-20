import 'package:flutter/material.dart';
import 'strings.dart';
import 'locale_catalog.dart';

const englishCatalog = <String, String>{
  '나만의 기록': 'Private journal',
  '작업실': 'Workroom',
  '기록': 'Journal',
  '설정': 'Settings',
  '삭제': 'Delete',
  '돌아가기': 'Go back',
  '취소': 'Cancel',
  '저장': 'Save',
  '선택': 'Select',
  '닫기': 'Close',
  '프로젝트': 'Project',
  '모든 프로젝트': 'All projects',
  '내가 남긴 페이지': 'Pages of progress',
  '날짜 범위 선택': 'Choose date range',
  '아직 펼쳐진 페이지가 없어요.': 'Your first page is still ahead.',
  '집중을 마치고 결과를 한 줄 남겨 보세요.\n막힌 지점도 다음 시작을 위한 기록입니다.':
      'Finish a focus session and leave a line.\nEven a sticking point can be a new beginning.',
  '기록에서 태어난 성취': 'Achievements from your work',
  '보관한 프로젝트': 'Archived projects',
  '기록은 그대로 보관됩니다.': 'Your records are preserved.',
  '페이지 수정': 'Edit page',
  '프로젝트가 삭제되었습니다.': 'This project was deleted.',
  '프로젝트 책': 'Project book',
  '프로젝트 관리': 'Manage project',
  '책 이름 바꾸기': 'Rename this book',
  '프로젝트와 페이지를 삭제할까요?': 'Delete this project and its pages?',
  '이름 바꾸기': 'Rename',
  '보관하기': 'Archive',
  '다시 펼치기': 'Reopen',
  '프로젝트 삭제': 'Delete project',
  '이 프로젝트 이어가기': 'Continue this project',
  '이 책을 완료본으로 남길까요?': 'Mark this book complete?',
  '결과 페이지를 그대로 보관하고 책장에 완료본을 표시합니다. 나중에 다시 펼칠 수 있어요.':
      'Keep every page and mark the book complete. You can reopen it later.',
  '완료본으로 남기기': 'Mark complete',
  '프로젝트 마무리': 'Finish project',
  '페이지를 거슬러': 'Your project history',
  '첫 집중 뒤 이곳에 오늘의 페이지가 생깁니다.':
      'Your first focus session will become a page here.',
  '결과·다음 행동 수정': 'Edit outcome and next action',
  '이 페이지 삭제': 'Delete this page',
  '이 페이지를 삭제할까요?': 'Delete this page?',
  '이 결과와 다음 행동이 삭제되고 시간·성취가 다시 계산됩니다.':
      'This outcome and next action will be deleted. Time and achievements will be recalculated.',
  '성취 진열장': 'Achievements',
  '기록이 남긴 흔적': 'The marks you have made',
  '내가 남긴 행동의 요약입니다.\n집중의 진실성이나 업무 품질을 인증하지 않습니다.':
      'A summary of your recorded actions.\nThese do not certify attention or quality of work.',
  '획득 근거 보기 →': 'View supporting records →',
  '집중 준비': 'Prepare to focus',
  '이번 페이지에는\n무엇을 남길까요?': 'What will you leave\non this page?',
  '이번에 해볼 일': 'Your intention',
  '예: 로그인 오류를 재현하고 원인 찾기':
      'For example: reproduce the login issue and find its cause',
  '지난번의 다음 행동을 불러왔어요.': 'Your previous next action is ready.',
  '나에게 필요한 시간': 'Make time for this',
  '직접 선택': 'Choose duration',
  '집중 시간': 'Focus duration',
  '1~180분': '1–180 minutes',
  '1분으로 알림과 복구를 먼저 확인할 수 있어요.':
      'Try one minute to check notifications and recovery.',
  '휴대폰을 내려놓아도 괜찮아요.\n돌아오면 오늘의 일을 이어갑니다.':
      'You can put your phone down.\nYour work will be here when you return.',
  '혼자 집중 시작': 'Start focusing',
  '동료와 25분 함께하기': 'Focus together for 25 minutes',
  '함께할 시간에 해볼 일을 먼저 적어 주세요.':
      'Write your intention for the shared session first.',
  '혼자 쓰기는 지갑 없이 · 공동 작업은 Seeker 보유 확인 후':
      'No wallet needed to focus alone · Seeker verification for shared sessions',
  '페이지가 책에 남았습니다.': 'Your page is saved in the book.',
  '함께하는 집중': 'Shared focus',
  '나의 집중': 'Your focus',
  '작업실로': 'Back to Workroom',
  '재부팅 이후 시간 확인이 필요합니다.': 'Confirm your time after the device restart.',
  '예정 시간이 끝났어요.': 'Your planned time has ended.',
  '잠시 쉬어가도 괜찮아요.': 'It is okay to take a pause.',
  '지금은 이 한 가지에만.': 'Just this one thing, for now.',
  '연결이 끊겨도 내 집중과 기록은 계속됩니다.': 'Your focus and records continue offline.',
  '시간 확인하고 복구': 'Confirm time and recover',
  '얼마나 집중했나요?': 'How long did you focus?',
  '기기가 재시작되어 남은 시간을 정확하게 알 수 없습니다.':
      'The device restarted, so the remaining time cannot be confirmed.',
  '집중한 시간 (분)': 'Time focused (minutes)',
  '복구': 'Recover',
  '이어서 집중': 'Resume focus',
  '잠시 멈추기': 'Pause',
  '집중 마무리': 'Finish focus',
  '결과 남기기': 'Record outcome',
  '집중 취소': 'Cancel focus',
  '오늘의 페이지': 'Your page today',
  '어디까지 왔나요?': 'What moved forward?',
  '해냈어요': 'Done',
  '조금 나아갔어요': 'Made progress',
  '막힌 곳을 찾았어요': 'Found a sticking point',
  '해낸 일 또는 막힌 지점': 'What you did or where you got stuck',
  '작은 발견도 한 페이지가 됩니다.': 'Even a small discovery deserves a page.',
  '다음에는 여기서 시작해요 (선택)': 'Next time, start here (optional)',
  '다음의 나에게 남기는 작은 책갈피': 'A bookmark for your future self',
  '확인한 집중 시간 (초)': 'Confirmed focus time (seconds)',
  '수정한 페이지 저장': 'Save edited page',
  '내 프로젝트 책에 남기기': 'Save in my project book',
  '페이지를 저장했어요. 다음의 내가 여기서 이어갈 거예요.':
      'Page saved. Your next session can begin here.',
  '초안을 두고 나중에 마무리': 'Keep draft and finish later',
  '이 문장은 동료에게 공유되지 않습니다.': 'These words are not shared with your partner.',
  '내 결과는 내 책에만 남습니다.': 'Your outcome stays in your own book.',
  '동료가 나갔어요. 내 시간은 계속할 수 있어요.': 'Your partner left. You can keep focusing.',
  '동료가 자신의 페이지를 마무리했어요.': 'Your partner finished their page.',
  '동료도 자신의 페이지를 쓰고 있어요.': 'Your partner is working on their own page.',
  '시간을 확인하고 이어가 주세요.': 'Confirm your time and continue.',
  '예정 시간이 끝났어요. 어떤 진전이 있었나요?': 'Your planned time ended. What moved forward?',
  '결과 한 줄 남기기': 'Leave an outcome',
  '집중으로 돌아가기': 'Return to focus',
  '지난번에 남긴 다음 행동': 'Continue where you left off',
  '오늘 이어갈 작은 일': 'One small thing to continue',
  '한 번의 집중으로 어디까지 가볼까요?': 'What could one focused session move forward?',
  '책갈피에서 이어가기': 'Continue from your bookmark',
  '첫 번째 책은 무슨 이야기인가요?': 'What will your first book be about?',
  '만들고 싶은 것 하나면 충분해요.\n로그인 없이, 이 기기에 안전하게 저장합니다.':
      'Start with one thing you want to make.\nSaved on this device, without signing in.',
  '내 프로젝트 만들기': 'Create my project',
  '동료와의 작업실': 'Your shared workroom',
  '연결 확인 중 · 내 기록은 계속': 'Reconnecting · Your records continue',
  '진행 중인 초대와 두 자리 보기': 'Open your invitation and shared seats',
  '나의 프로젝트': 'Your projects',
  '새 책': 'New book',
  '서두르지 않아도, 한 페이지씩.': 'No rush. One page at a time.',
  '새 프로젝트 책': 'A new project book',
  '프로젝트 이름': 'Project name',
  '예: 나의 첫 Android 앱': 'For example: My first Android app',
  '언제 이 책을 덮을까요? (선택)': 'When will this book be complete? (optional)',
  '예: 친구에게 첫 버전을 보여주면': 'For example: When I show a friend the first version',
  '책 만들기': 'Create book',
  '프로젝트 이름과 기록은 상대에게 공유되지 않습니다.':
      'Project names and notes are not shared with your partner.',
  '작업실 설정': 'Make yourself at home',
  '내 기록은 이 기기에': 'Your records stay here',
  '프로젝트·의도·결과·다음 행동은 로컬에 저장됩니다. 앱 삭제 전에 기록을 내보내 주세요.':
      'Projects, intentions, outcomes, next actions and trade journals stay on this device. Export them before uninstalling.',
  'JSON 파일로 내보내기': 'Export as JSON',
  '집중 환경': 'Your focus environment',
  '마무리 알림': 'End-of-session reminder',
  '선택한 경우에만 권한 요청 · 절전 중 늦을 수 있어요.':
      'Permission is requested only when enabled. Battery saving may delay delivery.',
  '짧은 햅틱': 'Subtle haptics',
  '모션 줄이기': 'Reduce motion',
  '시스템의 모션 감소 설정도 따릅니다.': 'Also respects the system reduced-motion setting.',
  '기기 시간대 사용': 'Use device time zone',
  '집중 경과 시간은 벽시계 변경의 영향을 받지 않습니다.':
      'Changing the wall clock does not change elapsed focus time.',
  '지갑과 Seeker': 'Wallet and Seeker',
  '연결됨 · 기록은 비공개': 'Connected · Notes stay private',
  '동료와 작업할 때만 연결': 'Connect for shared focus or wallet activity',
  '공동 작업실 전시 팩': 'Shared Workroom Pack',
  '호스트 한 명의 구매, 두 사람의 공간': 'One host purchase, a shared space',
  '개인정보와 데이터 안내': 'Privacy and data',
  '개인정보와 데이터': 'Privacy and data',
  '모든 개인 기록 삭제': 'Delete all personal records',
  '지갑 연결': 'Connect wallet',
  'Seeker 보유 확인': 'Verify Seeker ownership',
  '구매 복원': 'Restore purchases',
  '연결 해제': 'Disconnect',
  '지갑 연결 해제': 'Disconnect wallet',
  'Seeker 확인': 'Verify Seeker',
  '지갑 연결 및 서명': 'Connect and sign',
  '서버에서 확인하지 못했어요. 잠시 후 다시 시도해 주세요. 개인 기록은 안전합니다.':
      'Verification is unavailable. Try again shortly. Your personal records are safe.',
  'MWA 호환 지갑을 찾지 못했어요. Seeker의 Seed Vault Wallet을 설정해 주세요.':
      'No MWA compatible wallet was found. Set up Seed Vault Wallet on your Seeker.',
  '지갑 승인이 취소되었습니다. 전송하지 않은 주문은 다시 확인할 수 있어요.':
      'Wallet approval was cancelled. You can try again when ready.',
  '선택한 지갑 계정이 바뀌었습니다. 다시 연결해 주세요.':
      'The selected wallet account changed. Please reconnect.',
  '연결 시간이 만료되었어요. 지갑을 다시 연결해 주세요.':
      'Your sign-in expired. Please reconnect your wallet.',
  '연결이 끊겼어요. 개인 작업은 계속할 수 있습니다.':
      'Connection lost. Your personal work can continue.',
  '이 지갑에서 Seeker Genesis Token을 찾지 못했어요. 기본 계정을 확인해 주세요.':
      'No Seeker Genesis Token was found in this wallet. Check the selected account.',
  '공동 작업 연결을 준비 중입니다. 개인 작업실은 지금 사용할 수 있어요.':
      'Online services are not configured yet. Your personal workroom is available.',
  '아직 판매를 시작하지 않았습니다. 전시 팩을 미리 볼 수 있어요.':
      'Sales are not enabled yet. You can preview the Workroom Pack.',
  '프로젝트 이름을 입력해 주세요.': 'Enter a project name.',
  '의도와 1~180분의 시간을 확인해 주세요.':
      'Enter an intention and a duration of 1–180 minutes.',
  '진행 중인 집중을 먼저 마무리해 주세요.': 'Finish the current focus session first.',
  '진행 중인 프로젝트를 선택해 주세요.': 'Choose an active project.',
  '복구 시간을 먼저 확인해 주세요.': 'Confirm the recovery time first.',
  '복구 시간을 확인해 주세요.': 'Check the recovery time.',
  '해낸 일이나 막힌 지점을 한 줄 남겨 주세요.':
      'Leave one line about your progress or sticking point.',
  '먼저 집중을 마무리해 주세요.': 'Finish your focus session first.',
  '확인 시간은 측정된 시간을 넘을 수 없습니다.': 'Confirmed time cannot exceed measured time.',
  '결과는 비울 수 없습니다.': 'The outcome cannot be empty.',
  '이름은 비울 수 없습니다.': 'The name cannot be empty.',
  '기기가 재시작되어 남은 시간을 정확하게 알 수 없습니다. 확인한 시간만 기록하며 자동으로 완료하지 않습니다.':
      'The device restarted. Confirm only the time you actually focused; the session will not finish automatically.',
  '이 시간으로 복구': 'Recover with this time',
  '다시 집중': 'Resume focus',
  '잠시 멈춤': 'Pause',
  '여기서 마무리': 'Finish here',
  '이번 집중을 취소할까요?': 'Cancel this focus session?',
  '이번 집중은 결과 페이지나 성취에 포함되지 않습니다. 이미 저장한 기록은 그대로 남습니다.':
      'This session will not count as a page or achievement. Previously saved records stay unchanged.',
  '이 집중 취소': 'Cancel this session',
  '함께할 때,\n나의 Seeker로.': 'Your wallet.\nYour workroom.',
  'Seeker 보유 확인과 구매 복원에 사용합니다.\n집중 기록은 자동으로 공개되지 않습니다.':
      'Connect for wallet activity, Seeker verification and purchase restoration.\nYour focus records and personal notes stay private.',
  '연결 서명은 송금이 아닙니다.': 'Signing in does not transfer assets.',
  '서버가 발급한 일회용 로그인 메시지에 서명합니다. 실제 SKR 전송은 전시 팩 주문에서 따로 승인합니다.':
      'Sign a single-use login message from the server. SKR purchases require a separate approval in the Workroom Pack.',
  'SGT 보유 확인됨 · 앱 발행 명패': 'SGT ownership verified · Workroom badge',
  'Seeker 보유 확인 전 또는 확인 만료':
      'Seeker ownership not verified or verification expired',
  '연결 서비스 설정이 필요한 빌드입니다.\nFirebase 프로젝트와 앱 도메인 설정 후 지갑 연결을 사용할 수 있습니다.\n\n개인 작업실은 지갑 없이 완성되어 있습니다.':
      'Online services need configuration in this build.\nWallet connection becomes available after Firebase and identity setup.\n\nYour personal workroom works without a wallet.',
  '지갑 다시 연결 / 계정 변경': 'Reconnect / change account',
  '지갑 연결하고 서명': 'Connect wallet and sign in',
  'Seeker 보유 다시 확인': 'Verify Seeker ownership',
  '전시 팩 소유권을 복원했습니다.': 'Your Workroom Pack has been restored.',
  '이 지갑에 확인된 구매가 없습니다.': 'No verified purchase was found for this wallet.',
  '서버 계정을 삭제할까요?': 'Delete the server account?',
  '공동 방과 계정의 구매 복원 권한이 삭제됩니다. 공개 거래·재사용 방지 정보는 남습니다. 기기의 개인 기록은 유지됩니다.':
      'Shared rooms and this account\'s purchase restoration are removed. Public-chain and replay-prevention records remain. Personal records on this device are preserved.',
  '서버 계정 삭제': 'Delete server account',
  'SGT는 소유 지갑 확인에만 사용합니다.\n실제 집중·업무 품질·기기 사용을 인증하지 않습니다.':
      'SGT verifies wallet ownership only.\nIt does not certify focus, quality of work, or device usage.',
  '확인': 'OK',
  '이 기기의 기록 삭제': 'Delete records on this device',
  '지갑 구매 권한과는 별개입니다.': 'This is separate from wallet purchase rights.',
  '모든 개인 기록을 삭제할까요?': 'Delete all personal records?',
  '프로젝트·진행 중인 집중·저장한 결과·매매일지·설정이 삭제됩니다. 진행 중인 결제의 확인 정보는 보존합니다. 내보내지 않은 기록은 복구할 수 없습니다.':
      'Projects, focus sessions, outcomes, trade journals and settings will be deleted. Pending payment verification is preserved. Records that have not been exported cannot be recovered.',
  'Workroom 0.2.0 · 개발 검증 빌드\n지갑 없는 개인 사용은 지금 가능합니다.':
      'FOR THE RECORD 0.3.1 · Development preview\nPersonal work works without a wallet.',
  '개인 작업 기록과 매매일지는 SQLite로 이 기기에만 저장됩니다. 클라우드 백업은 제공하지 않습니다.\n\n공동 작업을 선택하면 지갑 주소, SGT 확인 정보, 방의 준비·마무리 상태와 선택한 작업 분류만 서버에 저장됩니다. 프로젝트명과 결과 원문은 전송하지 않습니다.\n\n구매는 공개 Solana 거래입니다. 거래 기록과 재사용 방지 정보는 서버 계정 삭제 후에도 보존됩니다. 연결 해제는 구매 취소나 로컬 기록 삭제가 아닙니다. 서버 계정 삭제는 앱 내 구매 복원 권한을 제거합니다.\n\n알림은 선택이며 정확 알람·연락처·위치 권한을 요구하지 않습니다. 광고·분석 SDK는 포함하지 않습니다.\n\n이 빌드는 개발 검증용입니다. 지원 주소·운영자·보관 기간 정책은 출시 전 설정해야 합니다.':
      'Personal work records and trade journals are stored only on this device. There is no automatic cloud backup. Export before uninstalling.\n\nWallet activity is read by the server from the authenticated wallet. Personal notes are never uploaded. Shared sessions store wallet and Seeker verification, room state and the selected work category; project titles and outcomes stay private.\n\nPurchases are public Solana transactions. Receipts and replay-prevention records remain after server account deletion. Disconnecting does not delete local records or cancel purchases.\n\nNotifications are optional. No contacts, location, exact alarm, advertising or analytics SDK is used.\n\nThis is a development preview. Support contact and the final operator and retention policy will be published before release.',
  '첫 페이지': 'The first page',
  '결과를 직접 기록한 첫 집중': 'Your first focus session with a recorded outcome',
  '다시 펼친 책': 'A book reopened',
  '지난 다음 행동을 이어서 기록': 'Continued a previous next action',
  '쌓여가는 이야기': 'A growing story',
  '한 프로젝트에 서로 다른 3일의 기록': 'Recorded one project on three different days',
  '첫 번째 완료본': 'The first finished book',
  '직접 완료한 프로젝트 한 권': 'Completed a project',
  '기록된 10시간': 'Ten recorded hours',
  '직접 확인한 집중 시간 10시간': 'Ten hours of confirmed focus',
  '지갑 서명과 서버 SGT 확인 · 앱 발행':
      'Wallet signature and server SGT verification · Issued by the app',
};
String uiText(BuildContext context, String value) =>
    WorkroomStrings.of(context).locale.languageCode == 'ko'
    ? (koreanCatalog[value] ?? value)
    : translateEnglish(
        WorkroomStrings.of(context).locale.languageCode,
        additionalEnglishCatalog[value] ??
            englishCatalog[value] ??
            normalizeLegacyTemplate(value),
      );

class LocalizedText extends StatelessWidget {
  const LocalizedText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
  });
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final String? semanticsLabel;
  @override
  Widget build(BuildContext context) => Text(
    uiText(context, data),
    style: style,
    textAlign: textAlign,
    maxLines: maxLines,
    overflow: overflow,
    softWrap: softWrap,
    semanticsLabel: semanticsLabel,
  );
}
