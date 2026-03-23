#!/usr/bin/env bash
set -euo pipefail

#
# ClawLink Brain용 OpenClaw tarball 빌드 및 GitHub Release 업로드
#
# 사용법:
#   ./scripts/brain-release.sh                    # package.json 버전으로 릴리스
#   ./scripts/brain-release.sh v2026.3.14         # 태그 지정
#   ./scripts/brain-release.sh --build-only       # 빌드만 (업로드 안 함)
#
# 전제조건:
#   - Docker (buildx)
#   - gh CLI (인증 완료)
#

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUT_DIR="$REPO_ROOT/dist/brain"

cd "$REPO_ROOT"

# 버전 추출
VERSION=$(node -p "require('./package.json').version")
BUILD_ONLY=false
TAG=""

# 인자 파싱
for arg in "$@"; do
  case "$arg" in
    --build-only)
      BUILD_ONLY=true
      ;;
    v*)
      TAG="$arg"
      ;;
    *)
      echo "알 수 없는 인자: $arg"
      echo "사용법: $0 [--build-only] [v<version>]"
      exit 1
      ;;
  esac
done

TAG="${TAG:-v${VERSION}}"
TARBALL_NAME="openclaw-${VERSION}.tgz"

# 태그와 package.json version 불일치 경고
EXPECTED_TAG="v${VERSION}"
if [ "$TAG" != "$EXPECTED_TAG" ]; then
  echo "⚠ 경고: 태그(${TAG})와 package.json version(${VERSION})이 불일치합니다"
  echo "  tarball 파일명: ${TARBALL_NAME}"
  echo "  권장 태그: ${EXPECTED_TAG}"
  read -p "  계속 진행하시겠습니까? (y/N) " confirm
  if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "중단됨"
    exit 1
  fi
fi

echo "═══════════════════════════════════════════"
echo "  ClawLink Brain 빌드"
echo "  버전: ${VERSION}"
echo "  태그: ${TAG}"
echo "═══════════════════════════════════════════"

# ── 1. Docker 빌드 → tarball 추출 ──
echo ""
echo "▶ Docker 빌드 시작..."
mkdir -p "$OUT_DIR"

docker build \
  -f Dockerfile.brain-pack \
  -o "$OUT_DIR" \
  .

# 결과 확인
TARBALL=$(find "$OUT_DIR" -name 'openclaw-*.tgz' -type f | head -1)
if [ -z "$TARBALL" ]; then
  echo "✗ tarball 생성 실패"
  exit 1
fi

TARBALL_SIZE=$(du -h "$TARBALL" | cut -f1)
echo "✓ 빌드 완료: $TARBALL ($TARBALL_SIZE)"

if [ "$BUILD_ONLY" = true ]; then
  echo ""
  echo "결과물: $TARBALL"
  echo "(--build-only: GitHub Release 업로드 생략)"
  exit 0
fi

# ── 2. gh CLI 확인 ──
if ! command -v gh &>/dev/null; then
  echo "✗ gh CLI가 설치되어 있지 않습니다"
  exit 1
fi

if ! gh auth status &>/dev/null; then
  echo "✗ gh CLI 인증이 필요합니다: gh auth login"
  exit 1
fi

# ── 3. GitHub Release 생성 + 업로드 ──
echo ""
echo "▶ GitHub Release 업로드..."

# 기존 릴리스가 있으면 tarball만 교체
if gh release view "$TAG" &>/dev/null; then
  echo "  기존 릴리스 ${TAG} 발견 → tarball 교체"
  # 기존 asset 삭제 후 재업로드
  gh release delete-asset "$TAG" "$TARBALL_NAME" --yes 2>/dev/null || true
  gh release upload "$TAG" "$TARBALL" --clobber
else
  echo "  새 릴리스 ${TAG} 생성"
  gh release create "$TAG" "$TARBALL" \
    --title "ClawLink Brain ${TAG}" \
    --notes "ClawLink Brain용 OpenClaw tarball (${VERSION})"
fi

# ── 4. 결과 출력 ──
DOWNLOAD_URL="https://github.com/JLCcom/openclaw/releases/download/${TAG}/${TARBALL_NAME}"

echo ""
echo "═══════════════════════════════════════════"
echo "  ✓ 릴리스 완료"
echo ""
echo "  다운로드 URL:"
echo "  ${DOWNLOAD_URL}"
echo ""
echo "  clawlink Brain Dockerfile에서:"
echo "  ARG OPENCLAW_TARBALL_URL=${DOWNLOAD_URL}"
echo "═══════════════════════════════════════════"
