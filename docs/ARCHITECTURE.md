# 구현 구조와 결정

> 2026-09-17 Trade Journal 확장: [구현 및 현재 배포 상태](TRADE_JOURNAL.md), [이번 검증 결과](TRADE_VALIDATION.md), [Seeker 실기기 체크리스트](SEEKER_CHECKLIST.md). 아래 기존 검증/미설정 빌드 설명은 9월 14~15일 이력입니다. 현재 공개 Firebase 설정과 Hosting은 준비됐으며 Functions/TTL은 Blaze 승인 대기입니다.

## 경계

```
Flutter UI → WorkroomController → SQLite (개인 원문)
    │             └→ Kotlin SystemClock + BOOT_COUNT + AlarmManager
    └→ HTTPS Functions / Firebase Auth / room snapshot
                    ├→ SIWS nonce·Ed25519 검증
                    ├→ Token-2022 SGT 확인
                    ├→ 두 자리 room state / 초대
                    └→ SKR 주문·체인 영수증·권한
Flutter MethodChannel → 공식 Kotlin MWA 2.0.3 → 사용자의 지갑
```

`lib/domain`은 프로젝트·세션·시간·성취 규칙, `lib/data`는 SQLite·서버·거래 검사, `lib/platform`은 네이티브 경계, `lib/ui`는 작업실·집중·기록·설정·공동 화면입니다. `functions/src/domain.ts`의 순수 검증 규칙과 `chain.ts`의 실제 RPC 접근을 분리했습니다.

개인 데이터는 version 1 JSON aggregate를 SQLite의 단일 row에 atomic transaction으로 저장합니다. 한 번의 저장에서 프로젝트/세션/설정 일관성을 지키며 매초 DB에 쓰지 않습니다. 모든 로컬 쓰기는 큐로 직렬화합니다. 실패한 복사본은 현재 화면 상태에 반영하지 않습니다. 추후 대용량 이력이나 동기화가 필요하면 정규화 migration을 추가해야 합니다. 알 수 없는 schema version은 초기화하지 않고 오류 및 원본 내보내기로 처리합니다.

## 시간과 복구

- `running ↔ paused → awaitingOutcome → saved`, 명시적인 `cancelled`.
- 같은 부팅: `SystemClock.elapsedRealtime` 차이 + pause 이전 누적값, 예정 범위로 clamp.
- process death: 시작 anchor·boot marker·상태가 SQLite에 남습니다. 앱 재개 시 재계산합니다.
- BOOT_COUNT 변경 또는 elapsed 감소: `needsRecovery=true`, paused로 전환. 사용자가 0~계획 시간 사이의 시간을 확인해야 재개/마무리할 수 있습니다. 해당 시간은 직접 확인 표시를 남깁니다.
- wall clock은 기록 날짜 표시에만 사용합니다. 저장 당시의 로컬 날짜도 보관하므로 나중에 시간대가 달라져도 3일 성취 근거가 바뀌지 않습니다.
- 알림은 inexact `setAndAllowWhileIdle`이며 OS 상태에 따라 늦을 수 있습니다. exact-alarm 권한이나 foreground service를 요구하지 않습니다. 알림 거절·실패는 세션 저장을 롤백하지 않습니다.
- 배경에서는 Flutter 화면 ticker를 중단합니다. 일정 종료가 결과나 실제 집중의 증거는 아닙니다.

## 인증과 공동 작업

MWA authorization token은 adapter 메모리에만 있습니다. 개인키·복구 구문은 받거나 저장하지 않습니다. 서버가 발급한 SIWS 전체 canonical message와 바이트가 일치해야 하며, domain·URI·wallet·시간·서명·nonce를 검사합니다. nonce 소비와 계정 생성은 원자적입니다. Firebase custom token은 지갑 소유 증명 후에만 발급합니다.

SGT는 표준 `getParsedTokenAccountsByOwner`(Token-2022 program)의 비영 잔고 후보와 mint authority·metadata pointer authority/address·token group member group을 검사합니다. 표준 RPC의 전체 응답을 사용하며, Helius V2 pagination을 표준 API로 오인하지 않습니다. RPC 실패는 미보유와 다른 `sgt-check-unavailable`입니다. 신규 room create/join마다 체인을 다시 읽습니다. 모델명·client boolean·fixture로 입장시키는 경로는 없습니다.

서버 room은 host, 두 seat, category, ready/finished/left, startAt, 만료, pack만 보관합니다. 프로젝트명·의도·결과·다음 행동은 포함하지 않습니다. 초대 코드는 40비트 무작위 값·15분 만료이며 사용자별 입장 시도를 제한합니다. Firestore transaction이 두 번째 입장 경합과 같은 SGT 입장을 막습니다. 공개 방 조회는 없습니다.

서버가 양쪽 준비를 검사하고 호스트 시작을 3초 뒤로 지정합니다. 클라이언트는 응답 시각과 Android monotonic anchor를 연결해 로컬 타이머로 이동합니다. 초 단위 서버 쓰기는 없습니다. 네트워크 왕복 편차와 실제 두 기기 시작 오차는 실기기 측정이 남아 있습니다. 개인 완료는 먼저 로컬 저장하고 서버 상태는 outbox를 통해 재시도합니다.

## 주문과 권한

거래는 단일 SPL `transferChecked`와 주문 reference만 허용합니다. 클라이언트도 Solana legacy message를 독립적으로 해석해 불필요한 instruction·추가 서명자·다른 mint/수취 ATA/수량을 거부합니다. 서명된 거래는 로컬에 보관한 후 서버로 전송합니다. 지갑 응답을 받기 전에 앱이 종료되면 아직 서버 전송을 요청하지 않았으므로 앱이 자산을 보낸 상태로 간주하지 않습니다.

서버는 받은 signature만 신뢰하지 않고 finalized 체인 거래의 exact message 및 transfer 내용을 확인합니다. 주문·사용한 signature·구매 권한을 원자적으로 저장합니다. 진행 중인 주문은 서버 사용자에 연결되어 재설치 후 같은 지갑으로 복원됩니다. 다른 지갑의 주문은 결제 버튼에 넘기지 않습니다. 호스트가 소유하면 room의 pack이 변경되어 두 클라이언트에 전달되며, 게스트 계정에는 소유권을 부여하지 않습니다.

## 참고한 공식 계약 (2026-09-14~15 확인)

- [Kotlin MWA 설치](https://docs.solanamobile.com/get-started/kotlin/installation), [API 사용](https://docs.solanamobile.com/get-started/kotlin/quickstart)
- [MWA specification — SIWS message-signing 경로](https://github.com/solana-mobile/mobile-wallet-adapter/blob/main/spec/spec.md)
- [SGT 공식 주소와 확장 조건](https://docs.solanamobile.com/solana-mobile-stack/seeker-genesis-token)
- [공식 SKR mint](https://docs.solanamobile.com/solana-mobile-stack/skr)
- [Android SystemClock](https://developer.android.com/reference/android/os/SystemClock)

SGT는 소유 지갑을 확인하는 도구이며 집중 사실·업무 품질·한 사람당 하나의 계정을 인증하지 않습니다. 이 한계는 앱에도 표시합니다.
