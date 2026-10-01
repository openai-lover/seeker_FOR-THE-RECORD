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

## 생산 의존성 감사: 미해결 항목

코디네이터가 2026-10-01에 현재 `functions/pnpm-lock.yaml`로 기록한 production audit의
7개 advisory(2 high, 4 moderate, 1 low)는 **해결되었다고 주장하지 않는다**:

| advisory | 현재 production 경로 | 상태 |
| --- | --- | --- |
| GHSA-3gc7-fjrx-p6mg (`bigint-buffer <=1.1.5`) | `@solana/spl-token → @solana/buffer-layout-utils` | published patch 없음으로 보고됨 |
| GHSA-w5hq-g745-h8pq (`uuid <11.1.1`) | `@solana/web3.js → jayson → uuid@8.3.2` | v1 호환 교체 미검증 |
| GHSA-x5fp-wj9c-mxmx, GHSA-4mjr-xmp4-gh2g (`qs <6.16.0`) | `firebase-functions → express → qs@6.15.3` | patch 후보, registry 접근 차단으로 lock 갱신 미수행 |
| GHSA-528h-pc64-c93x (`stream-json <=3.4.0`) | `@solana/web3.js → jayson → stream-json@1.9.1` | v1 의존성 교체 미검증 |
| GHSA-m9gg-hp2v-232j, GHSA-f596-whhp-79r4 (`@grpc/grpc-js 1.14.0..<1.14.5`) | `firebase-admin → Firestore → google-gax → @grpc/grpc-js@1.14.4` | patch 후보, registry 접근 차단으로 lock 갱신 미수행 |

이 환경에서 다시 실행한 `pnpm audit --prod --json`은 npm audit endpoint의 HTTP 403으로
`ERR_PNPM_AUDIT_BAD_RESPONSE`가 되어, 현재 registry 결과를 독립적으로 재확인하지
못했다. GitHub Advisory의 각 GHSA URL과 `pnpm view`도 이 실행 환경의 403 정책으로
접근하지 못했으며, patch 업데이트도 같은 이유로 수행할 수 없었다. 그래서 ignore
목록, 거짓 zero-count, major override, 수동 lockfile 조작은 사용하지 않았다. 다음 허용된
환경에서 공식 npm/GitHub advisory와 해당 package release notes를 다시 확인한 뒤,
호환되는 `qs`/`@grpc/grpc-js` patch를 lockfile에 정상 설치·테스트하고, Solana v1 전환은
`@solana/spl-token` API를 포함한 별도 migration으로 검토해야 한다.

기본 APK가 이 선택형 Node backend를 포함하지 않는다는 점은 노출 범위를 제한할 뿐,
위 production dependency 항목을 "cleared"로 만들지는 않는다. 실제 배포, 실기기,
emulator 규칙, live transaction은 이 작업에서 수행하지 않았다.
