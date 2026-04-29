# CLAUDE.md — Velona Flutter (모바일 앱)

## 프로젝트 개요
YouTube Shorts 자동 생성 + 오목 게임 모바일 앱 (Android 타겟).
Firebase 인증 후 Crown API 백엔드와 통신.

## 기술 스택
- **Flutter** 3.7.2 / **Dart**
- **상태관리**: Riverpod
- **라우팅**: GoRouter
- **HTTP**: Dio
- **인증**: Firebase Auth + FCM
- **영상**: video_player, chewie
- **오디오**: just_audio

## 디렉토리 구조
```
lib/
├── core/           # 공통 인프라 (상수, 네트워크, 알림, 에러 처리, 유틸)
├── features/       # 기능 모듈 (8개)
│   ├── auth/       # Firebase 인증, Google 로그인
│   ├── generate/   # 영상 생성 요청
│   ├── subtitle/   # 자막 생성/편집
│   ├── voice/      # 목소리 선택/복제
│   ├── projects/   # 프로젝트 목록/관리
│   ├── ranking/    # ELO 랭킹
│   ├── admin/      # 관리자 기능
│   ├── inquiry/    # 문의/피드백
│   └── settings/   # 설정
├── shared/         # 공통 테마, 재사용 위젯
└── router/         # GoRouter 네비게이션 설정
```

## 레이어 구조
각 feature 모듈은 클린 아키텍처 패턴:
```
presentation/ (UI, ViewModel)
  → domain/ (UseCase, Entity)
    → data/ (Repository, DataSource, DTO)
```

## 백엔드 연동
- **API 베이스**: `http://10.0.2.2:8080` (에뮬레이터) / 환경변수 오버라이드
- **인증**: Firebase ID 토큰 → `Authorization: Bearer <token>`
- **WebSocket**: STOMP (오목 게임 실시간 통신)

## 연관 프로젝트
| 프로젝트 | 경로 | 설명 |
|---------|------|------|
| Crown API | `../Crown_API/` | 백엔드 API (포트 8080) |
| Python Worker | `../python-worker/` | 영상 생성 워커 (포트 8003) |
| velonaAi-react | `../velonaAi-react/` | 웹 프론트엔드 (포트 3000) |

## 개발
```bash
flutter pub get
flutter run
```
