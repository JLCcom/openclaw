# ClawLink Brain 빌드 및 릴리스

OpenClaw를 ClawLink Brain 노드용 tarball로 빌드하고 GitHub Release에 업로드하는 절차.

## 개요

```
openclaw repo                          clawlink repo
┌─────────────────────┐                ┌──────────────────────┐
│ Dockerfile.brain-pack│                │ brain/Dockerfile     │
│         ↓            │                │       ↓              │
│  Docker 빌드 (node:24-bookworm)      │  curl tarball URL    │
│         ↓            │                │       ↓              │
│  pnpm pack → .tgz   │                │  npm install -g .tgz │
│         ↓            │  GitHub        │       ↓              │
│  gh release upload ──┼──Release──→────│  openclaw gateway run│
└─────────────────────┘                └──────────────────────┘
```

## 전제조건

- Docker (buildx 지원)
- `gh` CLI 설치 + 인증 (`gh auth login`)
- GitHub repo: `https://github.com/JLCcom/openclaw`

## 사용법

### 전체 릴리스 (빌드 + 업로드)

```bash
# package.json 버전으로 자동 태그
./scripts/brain-release.sh

# 태그 직접 지정
./scripts/brain-release.sh v2026.3.14
```

### 빌드만 (업로드 없이 로컬 확인)

```bash
./scripts/brain-release.sh --build-only
# 결과물: dist/brain/openclaw-<version>.tgz
```

### Dockerfile만으로 빌드

```bash
docker build -f Dockerfile.brain-pack -o dist/brain .
```

## 스크립트 동작 흐름

1. `Dockerfile.brain-pack`으로 Docker 빌드 (node:24-bookworm 환경)
   - `pnpm install --frozen-lockfile` (의존성 설치)
   - `pnpm canvas:a2ui:bundle` (실패 시 stub 생성, non-fatal)
   - `pnpm build:docker` (tsdown 빌드 + 후처리)
   - `npm pack --ignore-scripts` (tarball 생성)
2. `dist/brain/`에 tarball 추출
3. `gh release create` 또는 기존 릴리스에 tarball 교체
4. 다운로드 URL 출력

## 공식 빌드와의 차이점 (Brain 전용 옵션)

Brain tarball은 openclaw 공식 Dockerfile(`Dockerfile`)의 빌드와 다음 항목이 다르다.
이 차이점은 Brain 노드가 **gateway 전용**으로 동작하기 때문에 의도적으로 적용된 것이다.

| 항목 | 공식 빌드 (`Dockerfile`) | Brain 빌드 (`Dockerfile.brain-pack`) | 사유 |
|------|--------------------------|--------------------------------------|------|
| UI 빌드 | `pnpm ui:build` 실행 | **생략** | Brain은 gateway만 실행, Web UI 불필요 |
| A2UI 번들 실패 | 빌드 중단 가능 | **stub 생성 후 계속** (non-fatal) | 크로스 컴파일 환경 대응 |
| tarball 생성 | `pnpm pack` (prepack 훅 포함) | `npm pack --ignore-scripts` | prepack 훅이 build+ui:build를 재실행하여 실패 방지 |
| dev 의존성 prune | pack 전에 prune | **pack 후에 prune** | prune 후 pack하면 prepack 훅에서 빌드 도구 없어 실패 |
| extensions 처리 | `OPENCLAW_EXTENSIONS` ARG로 선택적 포함 | **전체 포함** | Brain은 모든 extension 접근 가능해야 함 |
| 빌드 명령 | `pnpm build` (full) | `pnpm build:docker` (UI 제외) | canvas:a2ui:bundle은 별도 실행, ui:build 생략 |

### 변경 이력

| 날짜 | 변경 | 사유 |
|------|------|------|
| 2026-03-23 | `pnpm ui:build` 제거 | UI 빌드 중 TypeScript 타입 에러 발생 (`channelContentConfig.ts` readonly 배열 불일치). Brain은 gateway 전용이므로 UI 불필요하여 제거 |
| 2026-03-23 | `pnpm pack` → `npm pack --ignore-scripts` | `pnpm pack`은 `--ignore-scripts` 미지원. `prepack` 훅(`pnpm build && pnpm ui:build`)이 재실행되어 실패. `npm pack --ignore-scripts`로 훅 우회 |
| 2026-03-23 | prune 순서 변경 (pack 후 prune) | `pnpm prune --prod` 후 `pnpm pack` 실행 시 dev 의존성(빌드 도구) 없어서 prepack 훅 실패. 순서 역전으로 해결 |
| 2026-03-23 | `npm pack` 전 `mkdir -p /out` 추가 | 출력 디렉토리 미생성으로 ENOENT 에러 발생 |

### 주의사항

- `Dockerfile.brain-pack`을 수정할 때는 반드시 `./scripts/brain-release.sh --build-only`로 로컬 검증 후 릴리스할 것
- openclaw upstream에서 `prepack` 훅이 변경되면 `npm pack --ignore-scripts`로 생성된 tarball의 무결성을 재검증할 것
- `pnpm build:docker`와 `pnpm build`의 차이: `build:docker`는 `canvas:a2ui:bundle`을 포함하지 않음 (Dockerfile에서 별도 실행)

## clawlink Brain Dockerfile 사용

릴리스 완료 후 출력되는 URL을 clawlink에 적용:

```bash
# 기본값 (Dockerfile에 하드코딩된 latest)
docker compose -f docker-compose.brain.yml build

# 특정 버전 지정
docker compose -f docker-compose.brain.yml build \
  --build-arg OPENCLAW_TARBALL_URL=https://github.com/JLCcom/openclaw/releases/download/v2026.3.14/openclaw-2026.3.14.tgz
```

## 파일 구조

| 파일 | 위치 | 역할 |
|------|------|------|
| `Dockerfile.brain-pack` | openclaw repo 루트 | Docker 빌드 환경 정의 |
| `scripts/brain-release.sh` | openclaw repo | 빌드 + GitHub Release 자동화 |
| `brain/Dockerfile` | clawlink repo | tarball URL로 OpenClaw 설치 |

## 버전 체계

### 버전 소스

- **단일 소스:** `package.json`의 `version` 필드 (예: `2026.3.14`)
- tarball 파일명과 GitHub Release 태그 모두 이 버전에서 파생

### 버전 → 산출물 매핑

| 항목 | 형식 | 예시 |
|------|------|------|
| `package.json` version | `YYYY.M.D` | `2026.3.14` |
| GitHub Release 태그 | `v{version}` | `v2026.3.14` |
| tarball 파일명 | `openclaw-{version}.tgz` | `openclaw-2026.3.14.tgz` |
| 다운로드 URL | `releases/download/{tag}/{tarball}` | `.../v2026.3.14/openclaw-2026.3.14.tgz` |

### 태그 직접 지정 시 주의

`./scripts/brain-release.sh v2026.3.15`처럼 태그를 수동 지정하면
태그(`v2026.3.15`)와 tarball 파일명(`openclaw-2026.3.14.tgz`)이 불일치할 수 있다.
태그는 항상 `package.json` version과 맞추는 것을 권장.

### 동일 버전 재빌드

같은 버전으로 다시 실행하면 기존 Release의 tarball을 교체한다 (덮어쓰기).
코드만 변경하고 version을 올리지 않은 경우 이 방식으로 핫픽스 적용 가능.

## 버전 업데이트 절차

1. openclaw 코드 변경 + 커밋
2. 필요 시 `package.json`의 `version` 업데이트
3. `./scripts/brain-release.sh` 실행
4. 출력된 다운로드 URL 확인
5. clawlink `brain/Dockerfile`의 `OPENCLAW_TARBALL_URL` 기본값 업데이트 (선택)
6. clawlink Brain 이미지 재빌드
