# OpenClaw - User Project Rules

## Downstream: ClawLink Brain Node

이 repo(openclaw)는 ClawLink 프로젝트(`/home/bk/JLCcom/clawlink`)의 **Brain 노드 타겟 repo**이다.

- ClawLink Brain은 GitHub Release의 tarball을 다운로드하여 `npm install -g`로 설치
- `openclaw gateway run --bind lan --port 18789`으로 WebSocket Gateway 실행
- `openclaw.template.json` → `~/.openclaw/openclaw.json` config 주입

### Brain용 빌드 및 릴리스

- **빌드:** `Dockerfile.brain-pack` (node:24-bookworm 환경, clawlink Docker 런타임 호환)
- **스크립트:** `./scripts/brain-release.sh` (Docker 빌드 → tarball 생성 → GitHub Release 업로드)
- **빌드만:** `./scripts/brain-release.sh --build-only` (결과물: `dist/brain/openclaw-*.tgz`)
- **빌드 환경 규칙:** Brain tarball은 반드시 `Dockerfile.brain-pack`으로 Docker 내에서 빌드할 것. 호스트 로컬 빌드 금지 (런타임 호환성 보장)
- **공식 빌드와의 차이:** UI 빌드 생략, `npm pack --ignore-scripts`로 prepack 훅 우회, A2UI 번들 실패 시 stub 허용. 상세 사유와 변경 이력은 `docs/brain-release.md` 참조
- **문서:** `docs/brain-release.md`

### 버전 체계

- **버전 소스:** `package.json`의 `version` 필드 (단일 소스, 예: `2026.3.14`)
- **GitHub Release 태그:** `v{version}` (예: `v2026.3.14`)
- **tarball 파일명:** `openclaw-{version}.tgz` (`pnpm pack` 자동 생성)
- **다운로드 URL:** `https://github.com/JLCcom/openclaw/releases/download/v{version}/openclaw-{version}.tgz`
- **동일 버전 재빌드:** 기존 Release tarball을 덮어씀 (핫픽스용)
- **태그와 version 불일치 금지:** 태그를 수동 지정할 때도 반드시 `package.json` version과 맞출 것

### 변경 시 하류 영향 체크 필수 항목

| 변경 영역 | ClawLink 영향 |
|---|---|
| `gateway run` CLI args/flags | `brain/entrypoint.sh` 인자 깨짐 |
| `openclaw.json` config 스키마 | `openclaw.template.json` 형식 불일치 |
| WebSocket RPC v3 프로토콜 | Edge Python 클라이언트 연결 실패 |
| Gateway token 생성/검증 | E2E 테스트 토큰 추출 실패 |
| Ed25519 identity (`device.json`) | 키페어 인증 실패 |
| npm 패키지 배포/버전 | Brain Docker 빌드 실패 |
| `OPENCLAW_ALLOW_INSECURE_PRIVATE_WS` 동작 | Tailscale ws:// 연결 차단 |

위 영역 변경 시 사용자에게 clawlink 호환성 확인 알림.

## User Preferences

- **소통:** 한국어, 간결하게
- **개발자:** bk.jeon (bk.jeon@newratek.com), Newratek
- **환경:** WSL2, `/home/bk/JLCcom/` 하위에 openclaw + clawlink 병행
