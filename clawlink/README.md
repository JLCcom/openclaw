# ClawLink Integration — llm/zai-glm

이 브랜치는 **ClawLink Brain Node**와 **Z.AI GLM** 연동을 위한 전용 브랜치입니다.

## 브랜치 목적

ClawLink의 Brain Docker 이미지(`docker-compose.brain.yml`)가 이 브랜치를 설치하여
컨테이너 기동 시 Z.AI GLM-4.7-Flash와 즉시 연동되는 상태를 만듭니다.

## 포함 파일

| 파일 | 설명 |
|------|------|
| `openclaw.template.json` | Brain 컨테이너 기본 설정 템플릿 |

## 설정 값

- **LLM Provider:** Z.AI (zai)
- **Primary Model:** `zai/glm-4.7`
- **Fallback Model:** `zai/glm-5`
- **Gateway Port:** `18789`
- **API Key:** `ZAI_API_KEY` 환경변수 참조

## Brain Docker 이미지 빌드

```bash
# clawlink 레포에서
docker compose -f docker-compose.brain.yml up -d --build
```

`brain/Dockerfile`에서 이 브랜치를 설치하고 템플릿을 이미지에 내장합니다:

```dockerfile
ARG OPENCLAW_BRANCH=llm/zai-glm
RUN npm install -g JLCcom/openclaw#${OPENCLAW_BRANCH}
COPY --from=openclaw /clawlink/openclaw.template.json /root/.openclaw-template/openclaw.json
```

## LLM 브랜치 전략

| 브랜치 | LLM | Phase |
|--------|-----|-------|
| `llm/zai-glm` | Z.AI GLM-4.7 | **1 (현재)** |
| `llm/openai` | OpenAI GPT-4o | 3+ |
| `llm/claude` | Anthropic Claude | 3+ |
| `llm/ollama` | Local Ollama | 4 |
