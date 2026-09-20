# Workroom · Seeker 작업실

> 2026-09-17 Trade Journal 확장: [구현 및 현재 배포 상태](docs/TRADE_JOURNAL.md), [이번 검증 결과](docs/TRADE_VALIDATION.md), [Seeker 실기기 체크리스트](docs/SEEKER_CHECKLIST.md). 아래 기존 검증/미설정 빌드 설명은 9월 14~15일 이력입니다. 현재 공개 Firebase 설정과 Hosting은 준비됐으며 Functions/TTL은 Blaze 승인 대기입니다.

Flutter Android 앱, 공식 Kotlin MWA bridge, Firebase 서버를 구현했습니다. 기존 DROP과 무관한 별도 프로젝트입니다.

개인 사용은 지갑·계정·네트워크 없이 가능합니다. 공동 작업은 초대 기반 두 자리·25분이며, 서버에서 서로 다른 SGT를 확인합니다. 상품은 공동 작업실 전시 팩 한 개입니다. 인증·결제 성공을 흉내 내는 운영 우회 경로는 없습니다.

## 바로 설치

최종 APK와 검증 결과는 `artifacts/` 및 [검증 기록](docs/VALIDATION.md)을 확인하세요. Seeker는 ARM64 APK를 사용합니다.
앱·서버·문서 전체 소스는 `artifacts/workroom-source.zip`에도 묶었습니다. 개발 도구와 node_modules는 ZIP에 포함하지 않았습니다.

```powershell
adb install -r artifacts/workroom-arm64-preview.apk
```

이 APK는 **개발 서명한 검증용 빌드**입니다. 기본 빌드는 로컬 기능과 전시 팩 미리보기가 작동합니다. Firebase 설정을 넣지 않은 빌드에서는 지갑·공동 방·구매 화면이 연결 준비 상태를 명시합니다. Store 출시 서명·서버 배포·실제 SGT·mainnet 구매 검증은 별도 단계입니다.

처음 실행 → 프로젝트 만들기 → 이번 의도 → 혼자 집중 → 마무리 → 결과·다음 행동 → 프로젝트 책. 예정 시간이 지나도 결과는 자동 저장되지 않습니다. 막힌 지점도 기록할 수 있습니다. 진행 중인 집중은 하나만 허용합니다.

## 포함한 기능

- SQLite 로컬 기록, 프로젝트 생성·이름 변경·완료본·보관·삭제, 기록 수정·삭제, JSON 파일 내보내기
- 10/25/45분 및 1~180분, 일시정지·조기 마무리·결과 초안, Android monotonic clock·부팅 번호 기반 복구
- 실제 페이지와 프로젝트가 반영되는 2D 작업실·책장·다음 행동 책갈피, 기록 기반 성취 5종과 서버 SGT 명패 1종
- 한국어 UI, 오프라인 내장 한글·영문 서체, 큰 글자, 명시적 터치 영역, 선택 알림·햅틱·모션 설정
- MWA 지갑 연결·메시지 서명·거래 서명, 서버 SIWS nonce·정확한 메시지·Ed25519 서명 검증
- Token-2022 SGT 검증, 서버 트랜잭션 기반 초대·준비·공동 시작·개별 마무리
- SKR 단일 상품 견적·클라이언트 거래 검사·MWA 서명·서버 전송·finalized 확인·권한 복원·호스트/동료 반영

토큰 보상·벌금·공개 매칭·채팅·NFT 발행·AI·앱 차단·자유 가구 배치는 포함하지 않았습니다. QR, 주간 대표 장면, 백업은 추가하지 않았습니다.

## 도구와 빌드

검증 조합: Flutter 3.47.4 / Dart 3.13.3, JDK 17.0.20.1, Android API 36, NDK 28.2.13676358, Gradle 8.14.3, AGP 8.11.1, Kotlin 2.2.20, 공식 MWA clientlib-ktx 2.0.3. Dart와 Node 패키지 버전은 lockfile에 고정했습니다.

Flutter 최신 템플릿의 Gradle 9.3.1 조합에서 Flutter Gradle 플러그인 자체의 Kotlin DSL 컴파일 오류가 발생해 위 조합으로 검증했습니다. Flutter는 이 조합의 향후 지원 종료 경고를 냅니다. 현재 APK 빌드 결과와 구분해 기록합니다.

이 PC에는 `.tools/` 아래에 SDK를 설치했습니다. Git에는 포함하지 않습니다. Windows 한글 경로에서 Gradle/셰이더 도구 오류가 발생하므로 빌드 스크립트가 `%TEMP%/seeker-workroom-build`에 원본을 가리키는 영문 junction을 만듭니다. 소스를 복사하거나 이동하지 않습니다. 해당 별칭이 다른 폴더를 가리키면 중단합니다.

```powershell
# 새 Windows PC: Git과 인터넷 필요. SDK 약관은 화면에서 검토합니다.
./tools/bootstrap.ps1 -WithServer
# 이 PC는 도구 설치 완료
./tools/build.ps1
# 선택: publisher 키가 없으면 개발 서명으로 최적화 빌드
./tools/build.ps1 -Release
```

직접 실행할 때도 영문 경로에서 실행하세요.

Flutter 테스트·실행·빌드는 한 번에 하나씩 실행하세요. 같은 폴더에서 병렬 실행하면 생성된 Android 플러그인 등록 파일이 서로 덮어써질 수 있습니다.
테스트 이후 release 빌드에는 `--no-pub`를 붙이지 마세요. Flutter의 release용 플러그인 등록 재생성이 생략되어 `integration_test` 참조가 남을 수 있습니다.

```powershell
Set-Location "$env:TEMP/seeker-workroom-build"
. ./tools/env.ps1
flutter pub get
flutter run -d <device-id>
flutter build apk --release --split-per-abi --target lib/main.dart
```

`android/key.properties.example`을 참고해 출시 서명을 별도로 구성할 수 있습니다. 개인키·복구 구문·keystore·비밀번호는 저장소나 채팅에 넣지 마세요. 앱 표시 이름은 `lib/config.dart`의 `AppConfig.name`에서 바꾸며 Android launcher label도 이 값을 읽습니다.

## Firebase와 지갑 설정

자세한 내용은 [서버 설정](docs/SETUP.md)을 따르세요. 앱의 로컬 기능에는 다음 설정이 필요하지 않습니다.

1. Firebase 프로젝트: Firestore, Authentication, Functions(Node 22), Secret Manager와 결제 플랜 설정.
2. 앱 Android 등록: `app.workroom.seeker_workroom`. 공개 Firebase 옵션을 `config/local.json`에 입력.
3. 본인 소유 HTTPS 도메인과 favicon. 서버의 `APP_DOMAIN`, `APP_URI` 및 앱 `IDENTITY_URI`를 일치시킴.
4. mainnet RPC URL은 Functions secret으로만 등록. 실제 SGT 검증은 RPC가 Token-2022 계정·mint 정보를 제공해야 함.
5. SKR 판매는 기본 꺼짐. 수취 공개 지갑·기존 SKR ATA·고정 정수 수량을 설정해야 켜짐. USD 가설을 임의 환산하지 않았음.

```powershell
Copy-Item config/example.json config/local.json
./tools/build.ps1 -Config config/local.json
```

## 테스트

```powershell
# 이 PC의 Node 22.23.2는 .tools에 설치됨. pnpm 필요
. ./tools/env.ps1
pnpm --dir functions install --ignore-scripts
# pnpm 환경 차이를 피하는 직접 실행 명령
node functions/node_modules/typescript/bin/tsc -p functions/tsconfig.json
node functions/node_modules/tsx/dist/cli.mjs --test functions/test/domain.test.ts
# Flutter + 서버 테스트
./tools/check.ps1
# Firestore 규칙·동시성: 운영 프로젝트를 사용하지 않음
node functions/node_modules/firebase-tools/lib/bin/firebase.js emulators:exec --only firestore --project demo-workroom "node functions/node_modules/tsx/dist/cli.mjs --test functions/test/rules.integration.ts"
# 격리된 Android 테스트 설치에서만 실행
flutter test integration_test/local_android_test.dart -d emulator-5554
```

정확한 수행 환경·통과 결과·미검증 항목은 [VALIDATION](docs/VALIDATION.md)에 있습니다. `test/goldens/`는 실제 Flutter 렌더링이지만 자동 테스트의 예시 기록입니다. 사용자 실적이나 실제 Seeker 테스트 증거가 아닙니다.

## 데이터와 기술 경계

[구조·복구·보안](docs/ARCHITECTURE.md), [실기기 검증과 데모](docs/DEVICE_AND_DEMO.md)를 참고하세요. 로컬 기록 원문은 서버·동료·체인에 보내지 않습니다. 타이머 종료 알림은 정확 알람 권한 없이 제공하므로 지연될 수 있으며 force-stop 이후 알림을 보장하지 않습니다. 시간 계산과 알림 성공 여부는 분리되어 있습니다.

원본 기획 문서는 `reference/seeker-workroom-handoff/`에 그대로 보존했습니다. 요청받은 순서인 README → CODEX_PROMPT → IMPLEMENTATION_BRIEF → ACCEPTANCE_CHECKLIST로 읽고 상세 전략을 참고했습니다. 첨부 문서의 미래 일정·테스트 계획을 이미 수행한 결과로 취급하지 않았습니다.
