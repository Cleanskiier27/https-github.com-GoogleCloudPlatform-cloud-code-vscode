Async inference job API (Quickstart)

1. Start Redis (locally or via docker):
   docker run -p 6379:6379 redis:7

2. Install deps:
   npm ci

3. Start worker:
   npm run start:queue

4. Start server:
   npm start

5. Enqueue a job (example):
   curl -X POST -H "Content-Type: application/json" -d '{"input":"hello"}' http://localhost:3000/api/infer

6. Poll result:
   curl http://localhost:3000/api/infer/<jobId>

7. Stream result:
   Open http://localhost:3000/stream.html and enter jobId
