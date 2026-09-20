# 수행한 검증과 남은 항목

> 2026-09-17 Trade Journal 확장: [구현 및 현재 배포 상태](TRADE_JOURNAL.md), [이번 검증 결과](TRADE_VALIDATION.md), [Seeker 실기기 체크리스트](SEEKER_CHECKLIST.md). 아래 기존 검증/미설정 빌드 설명은 9월 14~15일 이력입니다. 현재 공개 Firebase 설정과 Hosting은 준비됐으며 Functions/TTL은 Blaze 승인 대기입니다.

검증일: 2026-09-14~15 KST. 실제 Seeker 연결은 없었습니다. 아래 에뮬레이터와 자동 테스트를 실기기·실사용자 결과로 해석하면 안 됩니다.

## 산출물

- `artifacts/workroom-arm64-preview.apk`: Seeker 설치용, release 최적화, 개발 서명.
- `artifacts/workroom-x64-preview.apk`: Android 에뮬레이터용. 이 파일을 직접 설치해 화면과 복구를 확인했습니다.
- `artifacts/SHA256SUMS.txt`: 최종 APK SHA-256.
- `lib/`, `android/`: 실제 앱과 Kotlin MWA/clock/alarm/SAF bridge.
- `functions/src/`, `firestore.rules`, `firestore.indexes.json`: 서버와 클라이언트 접근 규칙.

기본 APK에는 Firebase·RPC·identity 설정과 예시 실적이 없습니다. 개인 기능은 오프라인으로 작동하며 공동 방·인증·구매는 연결 설정이 필요합니다. 상품 표현 미리보기와 실제 소유권을 구분합니다. 출시 서명·Store 제출·서버 배포는 수행하지 않았습니다.

## 자동 테스트: 54개 통과

| 범위 | 통과 | 수행한 내용 | 한계 |
|---|---:|---|---|
| Flutter controller | 8 | 상태 전이, 단일 active, 일시정지, wall clock 변경, reboot 확인, 시간 상한, 중복 저장, 저장 실패, 알림 실패, 프로젝트/기록 관리, schema 거절 | MemoryRepository와 주입한 clock 사용 |
| Flutter 거래 검증 | 9 | 정상 견적 형태, wallet/mint/ATA/reference/blockhash/수량 변조, 추가 바이트 거절 | 합성한 서명 전 거래; 자금 이동 없음 |
| Flutter widget | 2 | 지갑 없는 생성→집중→결과→재방문→책→팩 미리보기, 360px/글자 2배 진입 화면 | 실제 TalkBack·모든 화면 확대 검증 아님 |
| 서버 domain | 29 | 정확한 SIWS 메시지·서명·만료·재사용, SGT 공식 필드 및 잔고, 공동 방 상태, 거래/서명 변조 거절 | live RPC 및 배포 함수 전체 경로 아님 |
| Firestore Emulator | 4 | 실제 보안 규칙, 동시 입장 2명 경합, nonce 소비 경합, receipt signature 재사용 경합 | 테스트가 서버의 핵심 transaction 패턴을 실행; HTTP 엔드포인트 E2E 아님 |
| Android integration | 2 | Kotlin monotonic clock 실제 3초, SQLite close/reopen·저장·중복 저장, 공식 MWA 지갑 없음 오류 | 격리된 x64 Android; 실제 지갑 승인 없음 |

`flutter analyze`: 문제 없음. TypeScript 컴파일 성공. 원본 테스트 출력은 `docs/validation/`에 보존했습니다. Firestore 로그의 PERMISSION_DENIED는 거절을 기대한 규칙 테스트의 결과입니다.

Node 22.23.2에서도 Firestore Emulator 4개 테스트가 통과했습니다(`firestore-tests-node22.txt`). 재실행한 테스트를 중복 집계하지 않았습니다.

수행 환경: Flutter 3.47.4, Dart 3.13.3, Java 17.0.20.1, Android API 36 x86_64 Google APIs, WHPX/SwiftShader. 최초 서버 테스트는 Node 24.19.0에서 수행했고, 공식 체크섬을 검증한 **Node 22.23.2**를 추가 설치하여 TypeScript 컴파일과 서버 29개 테스트를 다시 통과했습니다. 배포 설정도 Node 22입니다. 다운로드 버전·URL·SHA-256은 `docs/validation/node-runtime.json`에 있습니다. 실제 Functions 운영 배포는 아직 하지 않았습니다.

## 최종 APK에서 수행한 수동 진단

진단용 프로젝트 이름은 `APK recovery test`, 의도는 `Process death and reboot diagnostic`입니다. 앱 UI에서 직접 만들었으며 실제 사용자 실적이 아닙니다. 시계나 데이터베이스 시간을 조작하지 않았습니다.

| 시험 | 관찰 결과 |
|---|---|
| release x64 설치 및 실행 | 성공. 첫 실행 빈 작업실·로컬 프로젝트 생성·25분 시작 |
| HOME 후 재진입 | 진행 중 집중 복귀 가능 |
| `am kill` | 명령을 실행했지만 PID 5538이 유지됨. **프로세스 종료 성공으로 인정하지 않음** |
| `am force-stop` | PID가 사라진 뒤 재실행 PID 5924. 프로젝트 1권·기록 0페이지·남은 시간 복구 |
| 화면 잠금 | 2026-09-15 00:33:51~00:34:27 KST, 약 36초. 23:42 → 23:06. 별도 복구 확인 없이 이어짐 |
| `adb install -r` | 같은 개발 서명 release APK 덮어쓰기 후 프로젝트·의도·22분 44초 남음 보존. 미래 schema 업그레이드 검증과 구분 |
| 실제 에뮬레이터 재부팅 | BOOT_COUNT 1 → 2. `RECOVER YOUR SESSION` 및 시간 확인 화면. 기록은 0페이지 유지; 자동 성취 없음. 직접 0분으로 확인 후 paused 상태로 복구 |
| 결과·다음 행동·수정·재사용 | 복구 진단 결과를 0초 자기 기록으로 저장. 1페이지 생성, 수정 표시, 다음 행동 `Physical Seeker validation`을 다음 집중 의도로 불러옴 |
| Android 파일 내보내기 | 실제 SAF의 Downloads 저장창에서 JSON 저장. 1,191바이트 파일의 프로젝트·의도·결과·다음 행동·confirmedSec 0·timeAdjusted true 확인 |
| ARM64 APK 무결성 | Android apksigner verify 성공, v2 서명, 서명자 1명. 개발 서명이며 SourceStamp/출시 서명 아님 |

`docs/screenshots/`는 최종 APK 직접 캡처입니다. `test/goldens/`의 6개 이미지는 Flutter 렌더링 회귀 기준이며 테스트용 예시 기록입니다. 두 종류 모두 실제 Seeker 스크린샷은 아닙니다.

`docs/validation/diagnostic-export.json`은 수정 전 첫 SAF 내보내기 원본입니다. 자동 입력으로 생긴 다음 행동 오타는 이후 앱의 페이지 수정 기능에서 바로잡았습니다. 기기 시간대가 UTC이므로 이 파일의 localDay는 9월 14일이며 검증일의 KST 9월 15일과 다릅니다.

## 빌드에서 해결한 문제

- 최신 Flutter 템플릿의 Gradle 9.3.1/AGP 9.1.0 조합에서 Flutter Gradle 플러그인 자체 Kotlin DSL 컴파일 실패. Gradle 8.14.3/AGP 8.11.1/Kotlin 2.2.20으로 debug 및 release 빌드 성공. 향후 지원 종료 경고는 남아 있습니다.
- Windows 한글 경로에서 Gradle 경로·셰이더 도구 오류. `tools/build.ps1`의 원본을 가리키는 영문 junction으로 해결했습니다.
- integration test 후 `--no-pub` release 빌드는 테스트 플러그인 등록을 재생성하지 않아 Java 컴파일 실패. 정상 `flutter build apk --release`로 재생성하여 해결했습니다. 생성 파일을 수동으로 고치지 않았습니다.
- 처음 큰 글자/폰트 회귀 검증에서 발견한 레이아웃·폰트·아이콘 로딩 문제를 수정한 후 모든 Flutter 테스트를 다시 통과했습니다.

SDK와 의존성을 이 PC에 새로 설치해 빌드했습니다. 완전히 다른 PC의 깨끗한 clone 재현 시험은 아직 하지 않았습니다. 설치 스크립트·버전·lockfile을 제공했습니다.

## 구현했지만 외부 확인이 필요한 항목

1. 실제 Seeker의 Seed Vault Wallet 연결·취소·계정 변경·인증 만료. 지갑 없음만 에뮬레이터에서 확인했습니다.
2. mainnet RPC로 실제 SGT 보유·미보유·이동 후 잔고·RPC 장애. 자동 필드 검증 테스트를 실제 소유 검증으로 표시하지 않았습니다.
3. Firebase 배포, HTTPS identity, Auth custom token, 두 **실제 Seeker**의 초대/동시 시작/이탈/오프라인/재방문. 시작 표시의 기기 간 지연 오차는 측정하지 않았습니다.
4. 사용자 승인 하의 실제 SKR 주문·잔액·지갑 거절·blockhash 만료·finalized·통신 끊김 복구·같은 지갑 재설치 복원·호스트/게스트 공간 변화. **실제 송금 0건**입니다.
5. 실제 25분 전체 화면 잠금, Doze·절전·전화 수신·최근 앱 제거, 실제 알림 전달 시각, 실제 TalkBack·모든 화면 큰 글자. 짧은 에뮬레이터 잠금 시험이 이를 대체하지 않습니다.
6. production Node 22 런타임, 서버 전체 HTTP E2E/부하·비용, 다른 PC에서의 clean build, 출시 서명·지원 주소·개인정보 보관 기간·Store 제출.

QR·주간 대표 장면·클라우드 백업/복원은 구현하지 않았습니다. JSON 내보내기는 제공하며 가져오기는 범위에 없습니다. 토큰 보상·벌금·공개 매칭·채팅·NFT 발행은 의도적으로 제외했습니다.

계정별 값과 실기기 시험 명령은 [SETUP](SETUP.md), [DEVICE_AND_DEMO](DEVICE_AND_DEMO.md)를 참고하세요. 서버 설정과 두 기기 검증이 완료되기 전에는 공동 작업 전체를 심사 제출용으로 검증 완료했다고 말할 수 없습니다.
