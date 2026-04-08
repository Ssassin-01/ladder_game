# GEMINI.md - 사다리 게임 마스터 (Ladder Game Master)

## 1. Project Overview

- **Name:** `ladder_game` (앱 표시 이름: 사다리 게임 마스터)
- **Type:** Flutter Application
- **Purpose:** 모임이나 술자리에서 벌칙/내기/순서를 빠르고 공정하게 정할 수 있는 **'프리미엄 힐링 & 위트'** 사다리 타기 앱.
- **Core Modes:** 벌칙, 당첨, 쏘기, 순서, 팀 나누기, 직접 입력 (현재 6가지 모드 완벽 지원)

## 2. UI/UX Design System (Current: Kawaii Forest)

- **Main Theme (Forest & Cream)**:
  - **Base Background**: `Pale Cream (#FEFCF4)` - 따뜻하고 눈이 편안한 오프화이트 배경.
  - **Key Accent**: `Olive Green (#5F6A00)` & `Light Lime (#DBEC6D)`.
  - **Stroke & Outline**: `Dark Chocolate Brown (#5D4037)` - 모든 카드와 버튼에 **2.0 두께의 고정 테두리**를 적용하여 카툰풍의 선명한 느낌 강조.
- **Aesthetics**:
  - **3D Design**: `BoxShadow`를 활용한 입체감 있는 버튼(Neon3DButton) 및 레이어링.
  - **Typography**: Google Fonts의 **`Plus Jakarta Sans`**를 사용하여 모던하면서도 귀여운 감성 유지.
  - **Dynamic Elements**: 사다리가 내려갈 때의 가림막(Curtain) 효과, 결과 발표 시의 팝업 애니메이션.

## 3. Development Conventions

- **Language:** Dart (Null Safety strict)
- **State Management:** `Provider`를 이용한 MVVM 구조.
- **Structure:** `lib/core/` (공통 테마 및 위젯), `lib/features/` (기능별 스크린 및 뷰모델).
- **Code Style:** 복잡한 캔버스 로직이나 애니메이션 구간에는 한국어로 상세 주석 작성 필수.

## 4. Project Evolution TODOs

- [x] 1단계: 사다리 캔버스 렌더링 및 하단 겹침 방지 로직 구현.
- [x] 2단계: 멀티 애니메이션 동기화 및 논리적 결과 100% 일치 확인.
- [x] 3단계: 가림막(Fog of War) 커튼 연출 및 테마 시스템(NeonColors) 정립.
- [x] **4단계: 메인 홈 화면 개발**: 6가지 모드 선택을 위한 그리드 레이아웃 및 진입점 구현.
- [x] **5단계: 결과 화면 폴리싱**:
  - [x] 모드별 강조 배경색(그라데이션) 및 입체적인 카드 디자인 적용.
  - [x] 팀 나누기 결과 시 팀장을 리스트 맨 앞으로 정렬하는 로직 개선.
- [x] **6단계: 추가 기능 구현**:
  - [x] **사운드 효과**: `audioplayers` 연동 (팝업, 사다리 이동, 결과 발표 사운드).
  - [x] **결과 공유**: `screenshot` 및 `share_plus`를 이용한 이미지 공유 기능.
  - [x] **명단 관리**: `shared_preferences`를 이용한 참가자 프리셋 저장.

- [ ] **7단계: 프리미엄 인터랙션 강화 (Visual & Physical Juice)**:
  - [ ] **네온 플리커(Neon Flicker)**: 주요 타이틀이나 버튼에 미세한 깜빡임 효과 추가.
  - [ ] **햅틱 피드백(Haptics)**: 사다리 꺾임 및 결과 도출 시 진동 패턴 탑재.
  - [ ] **스크린 쉐이크(Shake)**: 결과 발표 시의 강력한 시각적 타격감 구현.

- [ ] **8단계: 게임 기록 보관소 (History & Data)**:
  - [ ] **최근 결과 저장**: 이전 게임들의 결과를 로컬에 자동 기록.
  - [ ] **역대 결과 화면**: 홈 화면에서 진입 가능한 히스토리 페이지 구축.

- [ ] **9단계: 유틸리티 및 커스터마이징 확장**:
  - [ ] **BGM 시스템**: 게임 진행 중 긴장감을 높이는 배경음악 추가.
  - [ ] **벌칙 프리셋**: 자주 사용하는 벌칙 목록을 관리하고 즉시 로드하는 기능.
  - [ ] **캐릭터 색상 선택**: 참가자별로 고유한 테마 색상을 직접 지정하는 기능.
