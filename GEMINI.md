# GEMINI.md - 친구랑 내기 한판 ㄱ? (Casual Mini Games App)

## 1. Project Overview

- **Name:** `betting_app` (앱 표시 이름: 친구랑 내기 한판 ㄱ?)
- **Type:** Flutter Application
- **Purpose:** 친구들과 모임이나 술자리에서 벌칙/내기를 빠르고 재미있게 정할 수 있는 캐주얼 미니게임 모음 앱. (실제 도박이나 API 통신 기반 앱이 아님)
- **Core Games:** 사다리게임, 홀짝, 달팽이 경주, 핀볼

## 2. UI/UX Design System (프론트엔드 핵심 지침)

- **전체 테마 (Background)**: 완전한 블랙(`#000000`) 또는 아주 어두운 차콜(`#121212`)을 베이스로 사용하여 네온 컬러가 돋보이게 할 것.
- **포인트 네온 컬러 (Hex Codes)**:
  - 💗 핫 핑크: `#FF007F` (경고, 벌칙 당첨 등 강렬한 결과)
  - 💙 사이버 시안: `#00FFFF` (기본 버튼, 진행률 게이지)
  - 💚 라임 그린: `#39FF14` (성공, 통과 등 긍정적인 결과)
  - 💛 일렉트릭 옐로우: `#FFFF00` (타이틀, 강조 텍스트)
- **타이포그래피**: 레트로 오락실 느낌이 나는 굵고 강렬한 고딕 계열을 사용하며, 텍스트에 네온 발광 효과(Shadow/Glow)를 기본 적용할 것.
- **애니메이션**: 밋밋한 화면 전환은 금지. 승패 결과창이나 버튼 터치 시 화면 흔들림(Shake), 스케일 펌핑(Scale bounce) 등 타격감 있는 300ms~500ms의 짧고 경쾌한 애니메이션 필수.

## 3. Development Conventions

- **Language:** Dart (Null Safety strict)
- **State Management:** `Provider` 사용 권장.
- **Architecture:** MVVM (Model-View-ViewModel) 패턴 지향. UI 위젯과 비즈니스 로직 철저히 분리.
- **Project Structure (Feature-first):**
  - `lib/core/`: 공통 위젯(네온 버튼 등), 테마, 유틸리티 함수.
  - `lib/features/`: 각 게임별 독립적인 폴더 (예: `ladder_game`, `odd_even`, `snail_race`, `pinball`).
- **Code Style & Comments:**
  - 복잡한 로직이나 애니메이션, 확률 계산 부분에는 **반드시 한국어로 상세한 주석**을 작성할 것.
  - 코드를 제안할 때 전체 파일을 덮어쓰지 말고, 핵심 변경 사항 위주로 간결하게 출력할 것.

## 4. Agent Skills & Execution

- **File System**: 텍스트로 코드만 주지 말고, 직접 에이전트 스킬을 발동하여 `lib/` 내부에 폴더와 `.dart` 파일을 생성 및 수정할 것.
- **Terminal**: `provider` 등의 외부 패키지가 필요하면 터미널 스킬을 사용해 직접 `flutter pub add`를 실행할 것.

## 5. Testing (테스트 자동화 지침)

- **TDD 지향**: 새로운 핵심 로직이나 공통 위젯(예: `NeonButton`)을 생성할 때는 반드시 `test/` 폴더 하위에 매칭되는 테스트 코드(`_test.dart`)를 함께 작성할 것.
- **자동 검증**: 코드를 작성한 후에는 에이전트 스킬을 발동하여 터미널에서 `flutter test`를 직접 실행하고, 모두 Pass 하는지 확인할 것. 실패할 경우 스스로 코드를 고치고 재실행할 것.

## 6. Project Evolution TODOs

- [x] 1단계: lib/ 하위에 core 및 features (4가지 미니게임) 기본 폴더 구조 생성하기.
- [x] 2단계: lib/core/에 앱 전체에서 쓸 '커스텀 네온 텍스트 버튼 위젯' 만들기.
- [x] 3단계: 메인 화면(`main.dart` 및 `home_screen`) 구축. 네온 텍스트 타이틀과 4가지 게임으로 이동하는 네온 버튼 메뉴 배치하기.
- [x] 4단계: '홀짝(Odd/Even)' 게임의 빠른 템포 UI 및 랜덤 결과 로직 구현하기.
- [ ] **5단계 (REVISED): 사다리 게임 극한의 디테일 및 대각선 로직 추가**
  - [ ] **애니메이션 극강의 부드러움**: `CustomPainter`가 `setState` 대신 `Animation` 객체를 직접 리스닝(repaint)하게 하여 60fps의 부드러운 `CurvedAnimation(Curves.easeInOut)`을 구현.
  - [ ] **UI 오버플로우(잘림) 해결**: `Expanded`와 `SafeArea`를 활용해 사다리 영역과 하단 결과 칸, 버튼 영역의 레이아웃 공간을 완벽히 분리하여 겹치거나 잘리지 않게 수정.
  - [ ] **당첨 위치 랜덤화**: 게임 세팅 시 '당첨!' 칸이 항상 왼쪽이 아니라, N개의 결과 칸 중 랜덤한 위치(`Random().nextInt()`)에 배치되도록 로직 수정.
  - [ ] **(NEW) 대각선 사다리 로직**: 사다리 가로선을 생성할 때, 일정 확률로 시작점과 끝점의 Y좌표가 다른 **대각선**을 생성. (단, 선들이 서로 X자로 교차하지 않도록 간격 제한 로직 필수). 애니메이션 경로 계산(`Path`)도 이 대각선을 정확히 따라가도록 알고리즘 고도화.
- [ ] **6단계: 사다리 게임 전용 결과 화면(`ladder_result_screen.dart`)**
- [ ] **6단계: 사다리 게임 전용 결과 화면(`ladder_result_screen.dart`)**
  - [ ] 5단계의 애니메이션이 끝난 직후 전체 화면으로 결과창 띄우기.
- [ ] 7단계: '달팽이 경주' 레이싱 로직 구현.
- [ ] 8단계: '핀볼' 물리 기반 당첨 로직 구현.
