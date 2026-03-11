const { Queue, Worker, QueueScheduler } = require('bullmq');
const Redis = require('ioredis');
const connection = new Redis(process.env.REDIS_URL || 'redis://127.0.0.1:6379');

const inferenceQueue = new Queue('inference', { connection });
new QueueScheduler('inference', { connection });

module.exports = { inferenceQueue, connection };
