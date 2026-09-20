# 서버와 실제 Seeker 연결

> 2026-09-17 Trade Journal 확장: [구현 및 현재 배포 상태](TRADE_JOURNAL.md), [이번 검증 결과](TRADE_VALIDATION.md), [Seeker 실기기 체크리스트](SEEKER_CHECKLIST.md). 아래 기존 검증/미설정 빌드 설명은 9월 14~15일 이력입니다. 현재 공개 Firebase 설정과 Hosting은 준비됐으며 Functions/TTL은 Blaze 승인 대기입니다.

## 먼저 준비할 값

| 값 | 저장 위치 | 용도 |
|---|---|---|
| Firebase 프로젝트 ID·Android app ID·공개 API key·sender ID | `config/local.json` | 앱 초기화 |
| HTTPS 앱 도메인·URI·favicon | 서버 환경 및 앱 설정 | MWA identity, SIWS 도메인 바인딩 |
| mainnet RPC URL | Secret Manager `SOLANA_RPC_URL` | SGT 및 거래 조회·전송 |
| 판매 수취 공개 지갑 | `MERCHANT_WALLET` | 서버가 ATA를 계산 |
| 확정 SKR 정수 base-unit 수량 | `SKR_AMOUNT_ATOMIC` | 주문마다 고정 |
| 판매 개시 여부 | `PAYMENTS_ENABLED` 기본 false | 준비 전 자금 이동 방지 |

개인키는 서버에도 필요하지 않습니다. 전송할 트랜잭션은 사용자의 MWA 지갑만 서명합니다. 현재 프로젝트에 실제 Firebase 자격 증명이나 RPC API key를 넣지 않았습니다.

## Firebase

1. 별도의 Firebase 프로젝트를 만들고 Firestore Native mode, Authentication, Functions를 준비합니다. 이 저장소는 기존 DROP 설정을 사용하지 않습니다.
2. Android 앱 ID `app.workroom.seeker_workroom`을 등록합니다. 앱은 `FirebaseOptions`를 명시적으로 전달하므로 기본 로컬 빌드에 `google-services.json`은 필요하지 않습니다.
3. Functions용 Node 22, Java 17 이상, pnpm을 설치합니다. `pnpm --dir functions install --ignore-scripts`로 lockfile 의존성을 설치합니다. 로컬 테스트에서 선택적 native bigint 모듈은 pure JS로 대체됩니다.
4. `functions/.env.example`을 `functions/.env.<project-id>`로 복사하여 비밀이 아닌 운영 값을 입력합니다. 예제 도메인은 실제 인증에 사용할 수 없습니다.
5. 배포를 결정한 뒤 아래 명령을 실행합니다. 이 작업에서는 실제 배포하지 않았습니다.

```powershell
node functions/node_modules/firebase-tools/lib/bin/firebase.js login
node functions/node_modules/firebase-tools/lib/bin/firebase.js functions:secrets:set SOLANA_RPC_URL --project <project-id>
node functions/node_modules/typescript/bin/tsc -p functions/tsconfig.json
node functions/node_modules/firebase-tools/lib/bin/firebase.js deploy --only functions,firestore --project <project-id>
```

`firebase.json`의 predeploy는 `pnpm --dir functions build`를 실행합니다. CLI Node 환경이 pnpm 자동 검증과 충돌한다면 `functions/.npmrc`를 유지하고 Node 22에서 실행하세요. Functions service account에는 Firebase custom token 발급을 위한 Service Account Token Creator 권한이 필요할 수 있습니다. 최소 권한을 프로젝트별로 설정하고 오류를 실제 배포 로그에서 확인하세요.

Firestore client는 자신의 user 문서 및 자신이 속한 room의 단일 문서 읽기만 허용합니다. 목록 조회와 모든 쓰기는 거부합니다. 관리자 함수가 인증·입력·nonce·room state·order receipt를 검증한 뒤 씁니다. 방 코드 조회는 서버에만 있습니다. 최대 인스턴스 5, 사용자/지갑/IP 단위 요청 한도를 적용했습니다. 실제 부하·비용 검증은 아직 없습니다.

운영 전 TTL(`challenges.ttl`, `rateLimits.ttl`) 활성화를 확인하고, room/invite 보관 기간과 주문·영수증 보관 기간을 운영 정책에 확정하세요. 지원 이메일, 운영자 정보, 환불·분쟁 처리 문구를 출시 전에 실제 값으로 제공해야 합니다.

## 앱 설정

`config/example.json`의 공개 앱 설정을 `config/local.json`에 넣습니다. API URL은 끝에 `/api`까지, 뒤에 `/`는 붙이지 않습니다. 함수 위치는 `asia-northeast3`입니다. 클라이언트와 서버 모두 HTTPS만 허용합니다.

```powershell
./tools/build.ps1 -Config config/local.json
```

기본 APK에는 위 설정이 없으므로 개인 작업과 팩 미리보기만 활성화됩니다. 이 상태를 인증 성공으로 표시하지 않습니다. 실제 Seeker에서 MWA 계정 선택 → canonical SIWS 메시지 서명 → 서버 검증 → Firebase custom token 로그인 → SGT 재확인 순서로 시험하세요. MWA 2.0.3의 공식 `signMessagesDetached`로 전체 SIWS 메시지를 서명하는 경로이며, 지갑 연결과 서명은 두 단계입니다.

## SKR 결제 준비

1. 서버가 mainnet genesis hash를 확인합니다. devnet endpoint/테스트 토큰을 운영 SKR로 사용할 수 없습니다.
2. 수취 공개 지갑에 공식 SKR mint의 associated token account를 먼저 준비합니다. 본 앱은 사용자 몰래 ATA rent를 추가하지 않습니다.
3. 실제 mint decimals를 서버에서 읽습니다. 가격은 정수 문자열로 설정합니다. 예제 가격을 제공하지 않았으며 $6.99 가설을 SKR로 변환하지 않았습니다.
4. `PAYMENTS_ENABLED=true`로 설정한 빌드 환경에서 주문이 SKU·mint·정수 수량·수취 ATA·source ATA·reference·blockhash·만료를 고정하는지 확인합니다.
5. 사용자가 구체적으로 승인한 소액 mainnet 테스트만 진행하세요. 이 작업에서는 송금하지 않았습니다.

서버는 지갑의 서명된 바이트를 전송하기 전에 signature를 주문에 저장합니다. 동일 바이트 재전송은 같은 signature이며 새로운 결제를 만들지 않습니다. finalized 거래의 정확한 메시지·서명자·program·mint·수량·계정·reference·blockTime을 검증하고 주문/영수증/구매 권한을 Firestore transaction으로 확정합니다. 확인이 끊기면 기존 주문부터 조회합니다. blockhash가 finalized 높이 기준으로 만료된 후에만 미전송/실패 주문을 종료합니다.

## 출시 서명

`android/key.properties.example`은 형식만 제공합니다. 실제 `key.properties`와 keystore는 Git에서 제외합니다. 파일이 없으면 최적화 APK도 개발 서명이므로 Store 제출용이 아닙니다. dApp Store 패키지·서명·개인정보·지원 정책과 현재 제출 요구 사항을 배포 직전에 공식 문서로 다시 확인하세요.
