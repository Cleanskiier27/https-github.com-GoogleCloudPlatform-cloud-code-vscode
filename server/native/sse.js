const express = require('express');
const Redis = require('ioredis');
const redis = new Redis(process.env.REDIS_URL || 'redis://127.0.0.1:6379');

// Simple SSE helper: client connects to /api/stream/:jobId
function sseHandler(req, res) {
  const jobId = req.params.jobId;
  res.set({ 'Content-Type': 'text/event-stream', 'Cache-Control': 'no-cache', Connection: 'keep-alive' });
  res.flushHeaders();
  const interval = setInterval(async () => {
    const v = await redis.get(`infer:stream:${jobId}`) || await redis.get(`infer:result:${jobId}`);
    if (v) {
      res.write(`data: ${v}\n\n`);
      // if we got final result, close connection
      if (v && v.startsWith('{')) {
        clearInterval(interval);
        res.end();
      }
    }
  }, 500);
  req.on('close', () => clearInterval(interval));
}

module.exports = sseHandler;
