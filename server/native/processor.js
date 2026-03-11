const fetch = require('node-fetch');
const { connection } = require('../queue');
const Redis = require('ioredis');
const redis = new Redis(process.env.REDIS_URL || 'redis://127.0.0.1:6379');

// Simple batching strategy: accept job.data as single request; in real system gather multiple pending jobs
async function batchProcess(job) {
  const input = job.data.input;
  // Fallback local model call (echo) - replace with real model call or Triton/ONNX client
  const result = { output: `echo:${input}`, ts: Date.now() };

  // store result in Redis for retrieval
  await redis.set(`infer:result:${job.id}`, JSON.stringify(result), 'EX', 3600);
  return result;
}

module.exports = { batchProcess };
