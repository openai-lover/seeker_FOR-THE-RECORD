# 2026-09-17 Trade Journal 검증 결과

## 자동 검증

| 검증 | 결과 |
|---|---|
| `flutter analyze --no-pub` | No issues found |
| `flutter test --no-pub` | 31/31 통과 |
| Functions TypeScript build | 통과 |
| Functions tests | 38/38 통과 (기존 29 + 신규 9) |
| Firestore emulator rules tests | 4/4 통과 |
| Android SQLite/monotonic integration | 1/1 통과, 임시 DB에서 집중/일지 재연결 검증 |
| KO core / EN journal golden | 8개 화면 확인; 한국어 2배 글씨 확인 |
| APK 서명 검증 | Android Debug 인증서, SHA-256이 Hosting assetlinks와 일치 |
| 공개 Hosting / assetlinks | HTTP 200, assetlinks application/json |

작업 전 Flutter 18/19 통과에서 날짜가 매번 달라지는 기존 golden 실패를 확인했다. 주입 가능한 wall clock으로 날짜를 고정했고 tolerance를 높이지 않았다. 변경한 UI 스냅샷은 화면을 직접 확인했다.

Android API 36 x86_64 에뮬레이터에서 최종 앱 0.2.0 / versionCode 4002를 실행했고, 영문 홈의 실제 화면과 AndroidRuntime/flutter 오류 로그를 확인했다. 첫 `adb install -r`은 기존 0.1.0 / 4001 위에 성공했다. 이후 통합 테스트 실행 시 Flutter 도구가 debug versionCode 2의 downgrade를 처리하며 빈 테스트 설치를 제거하고 재설치한 사실을 로그에서 확인했다. 최종 0.2.0 APK를 복원했다. 반복 방지를 위해 `WORKROOM_ISOLATED_TEST=1`일 때 debug 앱은 별도 `app.workroom.seeker_workroom.integration` 패키지를 사용하도록 변경했다. 통합 테스트는 실제 개인 DB 대신 자체 임시 DB를 사용한다. `recovery_seed_test.dart`는 이번에 재실행하지 않았으며, 이전 날짜의 복구 실험과 이번 자동 회귀 결과는 별개다.

## APK

- `artifacts/workroom-arm64-preview.apk`: Seeker, 26,645,203 bytes, versionCode 2002.
- `artifacts/workroom-x64-preview.apk`: 에뮬레이터, 28,145,362 bytes, versionCode 4002.
- versionName 0.2.0, minSdk 26, targetSdk 36.
- release 최적화 + 개발 서명. production signing key를 만들거나 사용하지 않았다.
- arm64 SHA-256: `708b310594dbdcaeb584acbb4044d547d2969343151cc162bd5e7e341dfb5fbb`
- x64 SHA-256: `7093a8a254c8d1e96b19129c29c6a89ced3bded61b110fbc56655219c2740f66`
- Signing certificate SHA-256: `CE:81:7D:42:39:0E:20:47:98:79:97:A6:8F:AF:B7:D6:CC:90:B4:C3:0B:DA:B2:1C:1F:D3:59:B7:79:92:82:F2`.

실제 Firebase 공개 설정이 들어 있으나 Functions는 아직 배포되지 않았다. 이를 정상 동작하는 실지갑 통합 또는 Store 제출본으로 해석하면 안 된다. RPC secret과 개인 메모는 APK/서버 소스에 넣지 않았다.

## 실제로 미검증 / 남은 단계

- Blaze 결제 승인, RPC Secret Manager 설정, Workroom API 및 TTL indexes 배포.
- 실제 Seeker MWA 승인 → Firebase custom-token 로그인 → SGT 서버 검증.
- 실제 지갑의 지원되는 Jupiter swap과 Explorer 수량/주소 대조.
- 실제 두 Seeker의 공동 집중 및 실제 SKR 결제. 결제는 비활성화 상태이며 자산 전송은 수행하지 않았다.
- Seeker에서 강제 종료/재부팅/잠금과 복구의 이번 버전 회귀 확인.
- 미지원 Jupiter V2, native SOL wrapping, Token-2022 및 다른 DEX는 의도적으로 swap이라고 표시하지 않는다.

검증 자료: `docs/validation/trade-*` 로그와 `artifacts/workroom-emulator-0.2.0.png`. Golden의 거래는 synthetic fixture이며 실제 거래 데모가 아니다. 실기기 절차는 [SEEKER_CHECKLIST.md](SEEKER_CHECKLIST.md), 구조/범위는 [TRADE_JOURNAL.md](TRADE_JOURNAL.md).

별도 패키지 통합 테스트 재실행: 1/1 통과. 사용자용 package 0.2.0/4002와 .integration 테스트 package가 동시에 설치된 것을 확인했다. 로그: docs/validation/trade-android-isolated.log.

통합 테스트 주의: suffix를 사용해도 이 PC의 Flutter runner가 기본 앱 설치를 건드린 것을 확인했다. 두 패키지 공존은 테스트 종료 후 최종 APK를 명시적으로 재설치한 다음 확인한 결과다. 향후 `tools/test-android.ps1`은 기본 앱이 있는 기기의 실행을 거부한다. 반드시 전용 빈 에뮬레이터를 사용한다.
