# ClawLink Integration — llm/openai

이 브랜치는 **ClawLink Brain Node**와 **OpenAI GPT** 연동을 위한 전용 브랜치입니다.

## 설정 값
- **LLM Provider:** OpenAI
- **Primary Model:** `openai/gpt-4o`
- **Fallback Model:** `openai/gpt-4o-mini`
- **Gateway Port:** `18789`
- **API Key:** `OPENAI_API_KEY` 환경변수 참조

## 빌드
```bash
OPENCLAW_BRANCH=llm/openai docker compose -f docker-compose.brain.yml up -d --build
```
