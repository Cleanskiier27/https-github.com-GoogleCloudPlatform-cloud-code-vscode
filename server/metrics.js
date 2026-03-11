const client = require('prom-client');
const collectDefaultMetrics = client.collectDefaultMetrics;
collectDefaultMetrics({ prefix: 'attachments_' });

const inferenceCounter = new client.Counter({ name: 'inference_jobs_total', help: 'Total inference jobs' });
const inferenceLatency = new client.Histogram({ name: 'inference_latency_seconds', help: 'Inference latency seconds', buckets: [0.01,0.05,0.1,0.5,1,2,5]});

module.exports = { client, inferenceCounter, inferenceLatency };
