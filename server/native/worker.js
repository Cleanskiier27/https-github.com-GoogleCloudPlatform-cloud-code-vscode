const { Worker } = require('bullmq');
const { connection } = require('../queue');
const { batchProcess } = require('./processor');

const worker = new Worker('inference', async job => {
  return await batchProcess(job);
}, { connection, concurrency: 4 });

worker.on('failed', (job, err) => {
  console.error('Job failed', job.id, err);
});

console.log('Worker started');
