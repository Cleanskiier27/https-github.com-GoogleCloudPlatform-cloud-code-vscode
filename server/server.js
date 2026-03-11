const express = require('express');
const cors = require('cors');
const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');
const pino = require('pino');

const logger = pino({ level: process.env.LOG_LEVEL || 'info' });
const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;
const ROOT = path.resolve(__dirname, '..');
const STATIC_DIR = path.join(__dirname, '..', 'cuda-binaries', 'web-app');
const PUBLIC = path.join(__dirname, 'public');

// Serve server UI
app.use(express.static(PUBLIC));

// If the repo contains a web-app build, serve it under /app
if (fs.existsSync(STATIC_DIR)) {
    app.use('/app', express.static(STATIC_DIR));
}

app.get('/api/status', (req, res) => {
    res.json({ status: 'ok', uptime: process.uptime(), app: fs.existsSync(STATIC_DIR) });
});

// Native binding test
try {
    const native = require(path.join(__dirname, 'native'));
    app.post('/api/cuda/add', (req, res) => {
        const n = parseInt(req.query.size || '1024');
        const a = new Float32Array(n);
        const b = new Float32Array(n);
        for (let i = 0; i < n; i++) { a[i] = Math.random(); b[i] = Math.random(); }
        const out = native.addVectors(a, b);
        // Return checksum and sample
        let sum = 0;
        for (let i = 0; i < out.length; i++) sum += out[i];
        res.json({ n: out.length, sum });
    });
} catch (e) {
    logger.warn('Native binding helper not available; /api/cuda/add will fallback to CPU via loader');
}

function spawnBackground(cmd, args, logPrefix) {
    const p = spawn(cmd, args, { stdio: ['ignore', 'pipe', 'pipe'], shell: true });
    p.stdout.on('data', d => logger.info(`${logPrefix}: ${d.toString()}`));
    p.stderr.on('data', d => logger.error(`${logPrefix}-err: ${d.toString()}`));
    p.on('close', code => logger.info(`${logPrefix} exited ${code}`));
    return p.pid;
}

app.post('/api/prep-sample', (req, res) => {
    // run Python data_prep on a small sample
    const pid = spawnBackground('python', ['ml/data_prep.py', '--src', 'cuda-binaries', '--out', 'ml/data/processed', '--limit', '32'], 'prep');
    res.json({ started: true, pid });
});

app.post('/api/train', (req, res) => {
    // start lightweight training for validation
    const pid = spawnBackground('python', ['ml/train.py', '--data', 'ml/data/processed', '--epochs', '1', '--max-samples', '32'], 'train');
    res.json({ started: true, pid });
});

app.get('/api/list-files', (req, res) => {
    const dir = path.join(__dirname, '..', 'cuda-binaries');
    if (!fs.existsSync(dir)) return res.json({ files: [] });
    const items = fs.readdirSync(dir).slice(0, 200);
    res.json({ files: items });
});

// Metrics endpoint
const { client } = require('./metrics');
app.get('/metrics', async (req, res) => {
    res.set('Content-Type', client.register.contentType);
    res.send(await client.register.metrics());
});

// Enqueue inference job
app.post('/api/infer', express.json(), async (req, res) => {
    const { input } = req.body || {};
    if (!input) return res.status(400).json({ error: 'input required' });
    const { inferenceQueue } = require('./queue');
    const job = await inferenceQueue.add('infer', { input });
    res.status(202).json({ jobId: job.id, status: 'queued' });
});

// Poll for result
app.get('/api/infer/:id', async (req, res) => {
    const Redis = require('ioredis');
    const redis = new Redis(process.env.REDIS_URL || 'redis://127.0.0.1:6379');
    const key = `infer:result:${req.params.id}`;
    const v = await redis.get(key);
    if (!v) return res.status(202).json({ status: 'pending' });
    res.json({ status: 'done', result: JSON.parse(v) });
});

// SSE streaming endpoint
const sseHandler = require('./native/sse');
app.get('/api/stream/:jobId', sseHandler);

app.listen(PORT, () => {
    logger.info(`Server started on ${PORT}`);
});

module.exports = app;
