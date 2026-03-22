# ClawLink Integration — llm/ollama

이 브랜치는 **ClawLink Brain Node**와 **Local LLM (Ollama)** 연동을 위한 전용 브랜치입니다.
Phase 4 — Mac Studio M4/M5 완전 로컬 운용 대상.

## 설정 값
- **LLM Provider:** Ollama (Local)
- **Primary Model:** `ollama/qwen2.5-coder`
- **Fallback Model:** `ollama/llama3.2`
- **Gateway Port:** `18789`
- **Ollama Endpoint:** `http://localhost:11434`
- **API Key 불필요**

## 빌드
```bash
OPENCLAW_BRANCH=llm/ollama docker compose -f docker-compose.brain.yml up -d --build
```
