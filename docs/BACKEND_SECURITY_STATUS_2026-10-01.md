# 선택형 백엔드 보안 상태 — 2026-10-01

이 기록은 공개 `main`의 `414acebb41d0b23169ff15e16456ec175b1ac67c`
(`0.5.2+9`)에서 시작한, **선택형** Firebase Functions 경로의 좁은 후속 조치다.
기본 APK에는 Firebase 설정·SGT room·결제 기능이 없고, 이 문서는 APK의 보안
인증이나 경쟁 심사의 통과를 주장하지 않는다. 결제는 계속 `PAYMENTS_ENABLED=false`가
기본값이다.

## 이번에 확인·수정한 ID 경계

서버가 발급하는 UID는 `uidFor(wallet)`의 SHA-256, 즉 소문자 64자리 hex이다.
`userFor`는 Firebase ID token 검증 직후 이 형식을 먼저 확인하고,
`db.collection('users').doc(uid)`로 한 컬렉션 안에서만 문서를 읽는다. 따라서 token의
UID에 `/`나 중첩 경로를 넣어 다른 Firestore 경로를 가리키게 할 수 없다. 읽은
`users/{uid}.wallet`은 canonical 32-byte base58 Solana 공개키인지 확인하고, 다시
계산한 `uidFor(wallet)`가 token UID와 같은지도 확인한다. 유효한 지갑을 다른 UID 아래에
저장한 경우도 인증되지 않는다. 이 검증은 SIWS로 만든 정상 wallet/custom-token 흐름은
유지한다.

`functions/test/identity.test.ts`는 정상 바인딩, path injection 형태 UID, UID/지갑
불일치, malformed/non-canonical 저장 지갑을 회귀 검사한다. Firestore 규칙이나 UID
체계는 변경하지 않았다.

## 10월 1일 경쟁 감사의 낮은 신뢰도 패턴

감사의 `functions/src/index.ts:87 SQL injection` 표시는 SQL을 실행하는 코드가 아니라
Firestore Admin SDK의 document API를 SQL 패턴으로 오인한 것이다. 위의 collection-scoped
lookup과 UID 형태 검증은 경로 경계를 실제로 강화하지만, 이 사실이 별도의 전체 보안
감사 통과를 의미하지는 않는다.

`android/app/src/main/AndroidManifest.xml`의 exported launcher activity는 Android launcher
구조상 앱 시작에 필요하다. 이를 끄거나 권한을 추가하지 않았고, Android/native source도
변경하지 않았다. `functions/src/chain.ts`와 `functions/src/index.ts`의
`@solana/web3.js` v1 import는 실제 선택형 체인 기능의 도달 가능한 의존성이다. 유지보수
상태 패턴 경고를 취약점 해결로 오인하거나 단순 import 제거로 숨기지 않았다.

## 생산 의존성 감사: 패치와 미해결 항목

2026-10-01 production audit에서 처음에는 7개 advisory(2 high, 4 moderate, 1 low)가
나왔다. Cloud 환경에서는 registry가 HTTP 403을 반환해 패키지를 갱신하지 못했다.
이후 로컬의 지정된 Node 22.23.2 / pnpm 12.8.1 환경에서 공식 registry를 통해
`qs`를 6.16.0, `@grpc/grpc-js`를 1.14.5로 갱신했다. `pnpm-workspace.yaml`의
overrides는 기존 주요 버전의 취약 범위에만 적용하며, lockfile은 pnpm으로 생성했다.
다른 주요 버전으로 강제 교체하거나 audit ignore를 추가하지 않았다.

새 lockfile을 별도 폴더에서 `pnpm install --frozen-lockfile`로 설치한 뒤 빌드와
테스트 44개가 통과했다. `pnpm audit --prod --json` 재실행 결과는 **3개 advisory
(1 high, 2 moderate, 0 low, 0 critical)**이다. `qs`와 `@grpc/grpc-js` 관련 4개
advisory는 이 production audit 결과에서 사라졌으며, 다음 3개는 계속 미해결이다.

| advisory | 현재 production 경로 | 상태 |
| --- | --- | --- |
| GHSA-3gc7-fjrx-p6mg (`bigint-buffer <=1.1.5`) | `@solana/spl-token → @solana/buffer-layout-utils` | published patch 없음으로 보고됨 |
| GHSA-w5hq-g745-h8pq (`uuid <11.1.1`) | `@solana/web3.js → jayson → uuid@8.3.2` | v1 호환 교체 미검증 |
| GHSA-528h-pc64-c93x (`stream-json <=3.4.0`) | `@solana/web3.js → jayson → stream-json@1.9.1` | v1 의존성 교체 미검증 |

공식 patch 범위는 [qs arrayLimit advisory](https://github.com/advisories/GHSA-x5fp-wj9c-mxmx),
[qs DoS advisory](https://github.com/advisories/GHSA-4mjr-xmp4-gh2g),
[gRPC TLS advisory](https://github.com/advisories/GHSA-m9gg-hp2v-232j),
[gRPC memory advisory](https://github.com/advisories/GHSA-f596-whhp-79r4)로 확인했다.
재현 명령은 `functions`에서 `corepack pnpm install --frozen-lockfile`,
`corepack pnpm run build`, `corepack pnpm run test`, `corepack pnpm audit --prod --json`이다.
남은 경고가 있어서 audit 명령은 exit 1을 반환하는 것이 예상 결과다.
Solana v1 전환은 `@solana/spl-token` API를 포함한 별도 migration으로 검토해야 한다.

기본 APK가 이 선택형 Node backend를 포함하지 않는다는 점은 노출 범위를 제한할 뿐,
위 production dependency 항목을 "cleared"로 만들지는 않는다. 실제 배포, 실기기,
emulator 규칙, live transaction은 이 작업에서 수행하지 않았다.
