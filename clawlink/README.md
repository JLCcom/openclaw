# ClawLink Integration — llm/claude

이 브랜치는 **ClawLink Brain Node**와 **Anthropic Claude** 연동을 위한 전용 브랜치입니다.

## 설정 값
- **LLM Provider:** Anthropic
- **Primary Model:** `anthropic/claude-sonnet-4-6`
- **Fallback Model:** `anthropic/claude-haiku-4-5`
- **Gateway Port:** `18789`
- **API Key:** `ANTHROPIC_API_KEY` 환경변수 참조

## 빌드
```bash
OPENCLAW_BRANCH=llm/claude docker compose -f docker-compose.brain.yml up -d --build
```
