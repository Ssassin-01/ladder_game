# GEMINI.md - 사다리 게임 마스터 (Ladder Game Master)

## 1. Project Overview

- **Name:** `ladder_game` (앱 표시 이름: 사다리 게임 마스터)
- **Type:** Flutter Application
- **Purpose:** 모임이나 술자리에서 벌칙/내기/순서를 빠르고 공정하게 정할 수 있는 '프리미엄 사다리 타기' 전용 앱.
- **Core Modes (5대 사다리 모드):** 1. 벌칙 모드 (누가 벌칙을 받을 것인가!) 2. 당첨 모드 (누가 선물을 받을 것인가!) 3. 쏘기 모드 (오늘 결제는 누가 쏘나!) 4. 순서 모드 (발표나 게임 순서 정하기) 5. 직접 입력 (유저가 결과를 자유롭게 커스텀)

## 2. UI/UX Design System (프론트엔드 핵심 지침)

- **다크 모드 (Neon Retro)**: 완전한 블랙(`#000000`) 베이스에 핫 핑크(`#FF007F`), 사이버 시안(`#00FFFF`), 일렉트릭 옐로우(`#FFFF00`) 등의 네온 컬러 및 발광 효과(Glow) 적용.
- **라이트 모드 (High-end White)**: 오프화이트/그레이(`#F8F9FA` 또는 `Colors.grey[50]`) 베이스. 버튼은 딥 네이비(`Color(0xFF1A237E)`)나 차콜에 은은한 섀도우 적용. 텍스트는 짙은 그레이(`shade800`)로 고급스러움 강조.
- **애니메이션**: 밋밋한 화면 전환 금지. 승패 결과창이나 버튼 터치 시 화면 흔들림(Shake), 스케일 펌핑 등 타격감 있는 짧고 경쾌한 애니메이션 필수. 게임 시작 시 가림막(Curtain)이 걷히는 시각적 카타르시스 연출.

## 3. Development Conventions

- **Language:** Dart (Null Safety strict)
- **State Management:** `Provider` 사용 권장 (모드 상태 및 데이터 관리용).
- **Architecture:** MVVM (Model-View-ViewModel) 패턴 지향. UI 위젯과 비즈니스 로직 철저히 분리.
- **Project Structure (Feature-first):**
  - `lib/core/`: 공통 위젯, 테마, 유틸리티 함수.
  - `lib/features/`: `home`(모드 선택), `ladder_settings`(설정), `ladder_game`(메인 캔버스), `ladder_result`(결과 화면) 단위로 분리.
- **Code Style & Comments:**
  - 복잡한 로직이나 애니메이션(특히 캔버스 경로 및 다중 궤도 동기화 부분)에는 **반드시 한국어로 상세한 주석**을 작성할 것.

## 4. Agent Skills & Execution

- **File System**: 텍스트로 코드만 주지 말고, 직접 에이전트 스킬을 발동하여 `lib/` 내부에 폴더와 `.dart` 파일을 생성 및 수정할 것.
- **Terminal**: `provider` 등의 외부 패키지가 필요하면 터미널 스킬을 사용해 직접 `flutter pub add`를 실행할 것.

## 5. Project Evolution TODOs

- [x] 1단계: 사다리 캔버스 렌더링, 하단 겹침 방지 및 대각선 궤도 동기화 로직 구현.
- [x] 2단계: 멀티 애니메이션 동기화 및 논리적 결과 100% 일치 매핑 확보.
- [x] 3단계: 가림막(Fog of War) 커튼 연출, 승자 독식 레이아웃, 하이엔드 화이트 모드 적용.
- [ ] **4단계: 메인 홈 화면(Home Screen) 개발**: 5가지 사다리 모드(벌칙, 당첨, 쏘기, 순서, 직접 입력)를 선택할 수 있는 깔끔한 UI 진입점 생성.
- [ ] **5단계: - [ ] **(POLISH) 벌칙 모드 UI 디테일 및 예외 처리\*\*:
  - [ ] **참가자 수 직접 입력**: 참가자 수를 보여주는 텍스트를 `TextField`로 변경하여 유저가 숫자를 직접 타이핑할 수 있게 UX 개선. (유효성 검사: 2~20명 제한 안내 문구 추가).
  - [ ] **벌칙 리스트 직관성**: 벌칙 입력 폼 좌측에 인덱스 번호(1., 2. ...)를 표기하고, 내부 `hintText`에 "벌칙을 입력해주세요"를 명시.
  - [ ] **게임 하단 뱃지(Badge) UI**: 사다리 하단 결과 칸의 모양을 완벽한 원형(`BoxShape.circle`)에서 글자 길이에 따라 유연하게 대응하는 알약 형태(`BorderRadius.circular`)로 변경. 내부 텍스트에는 `maxLines: 2`, `TextOverflow.ellipsis` 또는 `FittedBox`를 적용하여 긴 텍스트 렌더링 오류(Overflow) 완벽 방지.
